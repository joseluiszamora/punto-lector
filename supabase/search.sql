-- Extensiones necesarias para búsqueda avanzada
create extension if not exists pg_trgm;
create extension if not exists unaccent;

-- Configuración de texto en español con unaccent
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_ts_config
    WHERE cfgname = 'es_unaccent' AND cfgnamespace = 'public'::regnamespace
  ) THEN
    CREATE TEXT SEARCH CONFIGURATION public.es_unaccent ( COPY = pg_catalog.spanish );
  END IF;
END$$;
alter text search configuration public.es_unaccent
  alter mapping for hword, hword_part, word
  with unaccent, spanish_stem;

-- Tabla de sinónimos
create table if not exists public.synonyms (
  id uuid primary key default gen_random_uuid(),
  term text not null,
  synonyms text[] not null default '{}',
  language text not null default 'es',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(term, language)
);

-- Normalización helper
create or replace function public.normalize_unaccent(txt text)
returns text
language sql
stable
as $$
  select lower(unaccent(coalesce(txt, '')));
$$;

-- Índices trigram para similitud
create index if not exists idx_books_title_trgm on public.books using gin (title gin_trgm_ops);
create index if not exists idx_books_summary_trgm on public.books using gin (summary gin_trgm_ops);
create index if not exists idx_authors_name_trgm on public.authors using gin (name gin_trgm_ops);
create index if not exists idx_categories_name_trgm on public.categories using gin (name gin_trgm_ops);

-- Índice GIN con unaccent para FTS (vía configuración de texto)
create index if not exists idx_books_tsv_es_unaccent on public.books using gin (
  to_tsvector('public.es_unaccent', coalesce(title,'') || ' ' || coalesce(summary,''))
);

-- Sugerencias de búsqueda (títulos, autores, categorías y sinónimos)
create or replace function public.books_suggestions(q text, lim int default 10)
returns table(
  suggestion text,
  source text,
  ref_id uuid,
  score real
) language sql stable as $$
  with norm as (
    select public.normalize_unaccent(q) as qn
  ),
  book_sug as (
    select b.title as suggestion, 'book'::text as source, b.id as ref_id,
      greatest(similarity(public.normalize_unaccent(b.title), (select qn from norm)), 0)::real as score
    from public.books b
    where b.title is not null
  ),
  author_sug as (
    select a.name as suggestion, 'author'::text as source, a.id as ref_id,
      similarity(public.normalize_unaccent(a.name), (select qn from norm))::real as score
    from public.authors a
  ),
  category_sug as (
    select c.name as suggestion, 'category'::text as source, c.id as ref_id,
      similarity(public.normalize_unaccent(c.name), (select qn from norm))::real as score
    from public.categories c
  ),
  syn_sug as (
    select s.term as suggestion, 'synonym'::text as source, s.id as ref_id,
      similarity(public.normalize_unaccent(s.term), (select qn from norm))::real as score
    from public.synonyms s
    where s.language = 'es'
    union all
    select syn.suggestion as suggestion, 'synonym'::text as source, s.id as ref_id,
      similarity(public.normalize_unaccent(syn.suggestion), (select qn from norm))::real as score
    from public.synonyms s
    cross join lateral unnest(s.synonyms) as syn(suggestion)
    where s.language = 'es'
  )
  select * from (
    select * from book_sug
    union all select * from author_sug
    union all select * from category_sug
    union all select * from syn_sug
  ) x
  where score > 0.2
  order by score desc, suggestion asc
  limit coalesce(lim, 10);
$$;

-- Búsqueda avanzada de libros con facetas básicas y ordenación
create or replace function public.search_books(
  q text,
  filters jsonb default '{}'::jsonb,
  page int default 1,
  page_size int default 20,
  sort text default 'relevance'
) returns table (
  book_id uuid,
  title text,
  cover_url text,
  authors text[],
  categories text[],
  published_at date,
  score real,
  listings_count int,
  min_price numeric,
  has_stock boolean
) language sql stable as $$
  with params as (
    select
      public.normalize_unaccent(q) as qn,
      plainto_tsquery('public.es_unaccent', coalesce(q, '')) as tsq,
      greatest(page, 1) as p,
      greatest(page_size, 1) as ps,
      coalesce((filters->>'has_stock')::boolean, null) as f_has_stock,
      (filters->>'store_city')::text as f_city,
      (filters->>'min_price')::numeric as f_min_price,
      (filters->>'max_price')::numeric as f_max_price,
      coalesce((filters->'category_ids')::jsonb, '[]'::jsonb) as f_cat_ids,
      coalesce((filters->'categories')::jsonb, '[]'::jsonb) as f_cat_names,
      coalesce(sort, 'relevance') as s
  ),
  base as (
    select
      b.id as book_id,
      b.title,
      b.cover_url,
      b.published_at,
      array_remove(array_agg(distinct a.name), null) as authors,
      array_remove(array_agg(distinct c.name), null) as categories,
      -- ranking: combina FTS + trigram
      greatest(
        ts_rank_cd(to_tsvector('public.es_unaccent', coalesce(b.title,'') || ' ' || coalesce(b.summary,'')), (select tsq from params)),
        similarity(public.normalize_unaccent(b.title), (select qn from params))
      )::real as score,
      count(distinct l.id) as listings_count,
      min(l.price) as min_price,
      bool_or(coalesce(l.stock,0) > 0) as has_stock,
      max(s.city) as any_city
    from public.books b
    left join public.books_authors ba on ba.book_id = b.id
    left join public.authors a on a.id = ba.author_id
    left join public.book_categories bc on bc.book_id = b.id
    left join public.categories c on c.id = bc.category_id
    left join public.listings l on l.book_id = b.id and l.active is true
    left join public.stores s on s.id = l.store_id
    group by b.id
  ),
  filtered as (
    select * from base
    where (
      (select q is null or q = '' from (select $1 as q) qv) -- si q vacío, no filtramos por texto
      or (
        to_tsvector('public.es_unaccent', coalesce(title,'') || ' ' || coalesce(title,'')) @@ (select tsq from params)
        or similarity(public.normalize_unaccent(title), (select qn from params)) > 0.2
      )
    )
    and (
      jsonb_array_length((select f_cat_names from params)) = 0
      or exists (
        select 1 from unnest(categories) cat
        where public.normalize_unaccent(cat) = any (
          select public.normalize_unaccent(value::text)
          from jsonb_array_elements_text((select f_cat_names from params))
        )
      )
    )
    and (
      jsonb_array_length((select f_cat_ids from params)) = 0
      or exists (
        select 1 from public.book_categories bc2
        where bc2.book_id = book_id
          and bc2.category_id = any(
            select (value)::uuid from jsonb_array_elements_text((select f_cat_ids from params))
          )
      )
    )
    and ((select f_has_stock is null from params) or has_stock = (select f_has_stock from params))
    and ((select f_city is null from params) or public.normalize_unaccent(any_city) = public.normalize_unaccent((select f_city from params)))
    and ((select f_min_price is null from params) or min_price >= (select f_min_price from params))
    and ((select f_max_price is null from params) or min_price <= (select f_max_price from params))
  ),
  ordered as (
    select * from filtered
    order by
      case when (select s from params) = 'newest' then published_at end desc nulls last,
      case when (select s from params) = 'price_asc' then min_price end asc nulls last,
      case when (select s from params) = 'price_desc' then min_price end desc nulls last,
      case when (select s from params) = 'relevance' then score end desc nulls last,
      title asc
  )
  select
    book_id, title, cover_url, authors, categories, published_at, score, listings_count, min_price,
    coalesce(has_stock, false) as has_stock
  from ordered
  offset (select (p - 1) * ps from params)
  limit (select ps from params);
$$;

-- Permisos de ejecución
grant execute on function public.books_suggestions(text, int) to anon, authenticated;
grant execute on function public.search_books(text, jsonb, int, int, text) to anon, authenticated;
