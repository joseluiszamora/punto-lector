-- Supabase schema for Punto Lector
-- Run via Supabase SQL editor or CLI

-- Extensiones necesarias para búsqueda avanzada
create extension if not exists pg_trgm;
create extension if not exists unaccent;

-- Users profile (external auth in auth.users)
create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text,
  avatar_url text,
  role text not null default 'user' check (role in ('user','store_manager','admin','super_admin')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Nationalities (tabla de países/nacionalidades)
create table if not exists public.nationalities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  country_code text not null unique,
  flag_url text not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists idx_nationalities_name on public.nationalities (name);

-- FK y columnas adicionales en user_profiles (idempotente)
alter table if exists public.user_profiles
  add column if not exists first_name text,
  add column if not exists last_name text,
  add column if not exists nationality_id uuid references public.nationalities(id) on delete set null;

create index if not exists idx_user_profiles_name on public.user_profiles (last_name, first_name);
create index if not exists idx_user_profiles_nationality on public.user_profiles (nationality_id);

-- Stores
create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_uid uuid not null references auth.users(id) on delete cascade,
  name text not null,
  manager_name text,
  address text,
  city text,
  open_days int[] default '{1,2,3,4,5}',
  open_hour text,
  close_hour text,
  lat double precision,
  lng double precision,
  phone text,
  description text,
  photo_url text,
  active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Authors (catálogo)
create table if not exists public.authors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  bio text,
  birth_date date,
  death_date date,
  photo_url text,
  website text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Books (catalog)
create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  cover_url text,
  summary text,
  review text,
  published_at date,
  genres text[] default '{}',
  isbn text,
  language text default 'es',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Relación M:N: books <-> authors
create table if not exists public.books_authors (
  book_id uuid not null references public.books(id) on delete cascade,
  author_id uuid not null references public.authors(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (book_id, author_id)
);

-- Categories
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  color text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Relación M:N: books <-> categories
create table if not exists public.book_categories (
  book_id uuid not null references public.books(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (book_id, category_id)
);

-- Listings: book for sale by store
create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  price numeric(12,2) not null,
  currency text not null default 'BOB',
  stock int default 0,
  active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (store_id, book_id)
);

-- Offers
create table if not exists public.offers (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  discount_pct numeric(5,2),
  price_after numeric(12,2),
  start_at timestamptz,
  end_at timestamptz,
  active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Favorites (libros favoritos por usuario)
create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  created_at timestamptz default now(),
  unique (user_id, book_id)
);

-- Tabla de sinónimos para búsqueda
create table if not exists public.synonyms (
  id uuid primary key default gen_random_uuid(),
  term text not null,
  synonyms text[] not null default '{}',
  language text not null default 'es',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(term, language)
);

-- Basic indexes
-- Eliminar índice legado y usar solo el GIN con configuración es_unaccent
drop index if exists idx_books_title;
create index if not exists idx_stores_location on public.stores (lat, lng);
create index if not exists idx_authors_name on public.authors (name);

-- Búsqueda avanzada: trigram + FTS
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

create index if not exists idx_books_title_trgm on public.books using gin (title gin_trgm_ops);
create index if not exists idx_books_summary_trgm on public.books using gin (summary gin_trgm_ops);
create index if not exists idx_authors_name_trgm on public.authors using gin (name gin_trgm_ops);
create index if not exists idx_categories_name_trgm on public.categories using gin (name gin_trgm_ops);
create index if not exists idx_books_tsv_es_unaccent on public.books using gin (
  to_tsvector('public.es_unaccent', coalesce(title,'') || ' ' || coalesce(summary,''))
);

-- Funciones RPC de búsqueda
create or replace function public.normalize_unaccent(txt text)
returns text language sql stable as $$
  select lower(unaccent(coalesce(txt, '')));
$$;

create or replace function public.books_suggestions(q text, lim int default 10)
returns table(
  suggestion text,
  source text,
  ref_id uuid,
  score real
) language sql stable as $$
  with norm as (select public.normalize_unaccent(q) as qn),
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
      q as q_raw,
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
      greatest(
        ts_rank_cd(to_tsvector('public.es_unaccent', coalesce(b.title,'') || ' ' || coalesce(b.summary,'')), (select tsq from params)),
        similarity(public.normalize_unaccent(b.title), public.normalize_unaccent((select q_raw from params)))
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
      (select q_raw is null or q_raw = '' from params)
      or (
        to_tsvector('public.es_unaccent', coalesce(title,'') || ' ' || coalesce(title,'')) @@ (select tsq from params)
        or similarity(public.normalize_unaccent(title), public.normalize_unaccent((select q_raw from params))) > 0.2
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
