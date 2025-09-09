-- Analítica de popularidad (eventos, acumulados y RPC)

-- Tablas de eventos
create table if not exists public.search_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid null,
  q text,
  book_id uuid null references public.books(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists idx_search_events_created_at on public.search_events(created_at);
create index if not exists idx_search_events_book_id on public.search_events(book_id);

create table if not exists public.book_views (
  id uuid primary key default gen_random_uuid(),
  user_id uuid null,
  book_id uuid not null references public.books(id) on delete cascade,
  created_at timestamptz not null default now()
);
create index if not exists idx_book_views_created_at on public.book_views(created_at);
create index if not exists idx_book_views_book_id on public.book_views(book_id);

-- Acumulado diario
create table if not exists public.book_stats_daily (
  day date not null,
  book_id uuid not null references public.books(id) on delete cascade,
  views int not null default 0,
  searches int not null default 0,
  favorites int not null default 0,
  primary key (day, book_id)
);
create index if not exists idx_book_stats_daily_book on public.book_stats_daily(book_id);
create index if not exists idx_book_stats_daily_day on public.book_stats_daily(day);

-- Upsert acumulado
create or replace function public.inc_book_stat(p_book_id uuid, p_day date, p_views int, p_searches int, p_favorites int)
returns void language plpgsql as $$
begin
  insert into public.book_stats_daily(day, book_id, views, searches, favorites)
  values (p_day, p_book_id, coalesce(p_views,0), coalesce(p_searches,0), coalesce(p_favorites,0))
  on conflict (day, book_id) do update set
    views = public.book_stats_daily.views + coalesce(excluded.views,0),
    searches = public.book_stats_daily.searches + coalesce(excluded.searches,0),
    favorites = public.book_stats_daily.favorites + coalesce(excluded.favorites,0);
end;$$;

-- Triggers eventos -> acumulado diario
create or replace function public.trg_search_events_agg() returns trigger language plpgsql as $$
begin
  if NEW.book_id is not null then
    perform public.inc_book_stat(NEW.book_id, (NEW.created_at at time zone 'UTC')::date, 0, 1, 0);
  end if;
  return NEW;
end;$$;
drop trigger if exists trg_search_events_agg on public.search_events;
create trigger trg_search_events_agg after insert on public.search_events
for each row execute function public.trg_search_events_agg();

create or replace function public.trg_book_views_agg() returns trigger language plpgsql as $$
begin
  perform public.inc_book_stat(NEW.book_id, (NEW.created_at at time zone 'UTC')::date, 1, 0, 0);
  return NEW;
end;$$;
drop trigger if exists trg_book_views_agg on public.book_views;
create trigger trg_book_views_agg after insert on public.book_views
for each row execute function public.trg_book_views_agg();

-- Favoritos (opcional): contar diario
create or replace function public.trg_favorites_agg_ins() returns trigger language plpgsql as $$
begin
  perform public.inc_book_stat(NEW.book_id, (NEW.created_at at time zone 'UTC')::date, 0, 0, 1);
  return NEW;
end;$$;
drop trigger if exists trg_favorites_agg_ins on public.favorites;
create trigger trg_favorites_agg_ins after insert on public.favorites
for each row execute function public.trg_favorites_agg_ins();

create or replace function public.trg_favorites_agg_del() returns trigger language plpgsql as $$
begin
  update public.book_stats_daily
     set favorites = greatest(favorites - 1, 0)
   where book_id = OLD.book_id
     and day = (OLD.created_at at time zone 'UTC')::date;
  return OLD;
end;$$;
drop trigger if exists trg_favorites_agg_del on public.favorites;
create trigger trg_favorites_agg_del after delete on public.favorites
for each row execute function public.trg_favorites_agg_del();

-- RPC logging (opcional)
create or replace function public.log_search(p_q text, p_book_id uuid default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.search_events(user_id, q, book_id) values (auth.uid(), p_q, p_book_id);
end;$$;

create or replace function public.log_book_view(p_book_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.book_views(user_id, book_id) values (auth.uid(), p_book_id);
end;$$;

-- RPC: ranking de libros populares
create or replace function public.get_popular_books(
  p_window text default '7d',
  p_limit int default 20,
  p_offset int default 0,
  p_mode text default 'trending'
) returns table (
  id uuid,
  title text,
  cover_url text,
  authors text[],
  categories text[],
  views int,
  searches int,
  favorites int,
  score numeric
) language sql stable security definer set search_path = public as $$
  with params as (
    select
      case
        when lower(p_window) = '7d'  then (now()::date - interval '7 days')::date
        when lower(p_window) = '30d' then (now()::date - interval '30 days')::date
        else null::date
      end as start_day,
      lower(p_mode) as mode
  ),
  agg as (
    select
      b.id,
      b.title,
      b.cover_url,
      (select array_agg(distinct a.name)
         from public.books_authors ba
         join public.authors a on a.id = ba.author_id
        where ba.book_id = b.id) as authors,
      (select array_agg(distinct c.name)
         from public.book_categories bc
         join public.categories c on c.id = bc.category_id
        where bc.book_id = b.id) as categories,
      coalesce(sum(sd.views),0)::int as views,
      coalesce(sum(sd.searches),0)::int as searches,
      coalesce(sum(sd.favorites),0)::int as favorites,
      coalesce(sum(sd.views),0) * 1.0
        + coalesce(sum(sd.searches),0) * 2.0
        + coalesce(sum(sd.favorites),0) * 3.0 as score
    from public.books b
    left join public.book_stats_daily sd
      on sd.book_id = b.id
     and (
       (select start_day from params) is null
       or sd.day >= (select start_day from params)
     )
    group by b.id, b.title, b.cover_url
  )
  select
    id, title, cover_url, authors, categories, views, searches, favorites,
    case
      when (select mode from params) = 'views' then views::numeric
      when (select mode from params) = 'searches' then searches::numeric
      when (select mode from params) = 'favorites' then favorites::numeric
      else score
    end as score
  from agg
  order by score desc, title asc
  limit p_limit offset p_offset;
$$;
