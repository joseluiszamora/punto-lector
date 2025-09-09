-- RLS policies
alter table public.user_profiles enable row level security;
alter table public.stores enable row level security;
alter table public.books enable row level security;
alter table public.listings enable row level security;
alter table public.offers enable row level security;
alter table public.authors enable row level security;
alter table public.categories enable row level security;
alter table public.books_authors enable row level security;
alter table public.book_categories enable row level security;
alter table public.favorites enable row level security;
alter table public.synonyms enable row level security;
alter table public.nationalities enable row level security;
alter table if exists public.search_events enable row level security;
alter table if exists public.book_views enable row level security;
alter table if exists public.book_stats_daily enable row level security;

-- helper: role from user_profiles
create or replace function public.current_role() returns text language sql stable as $$
  select coalesce(role, 'user') from public.user_profiles where id = auth.uid();
$$;

-- user_profiles
drop policy if exists user_profiles_select on public.user_profiles;
create policy user_profiles_select on public.user_profiles
  for select using (auth.uid() is not null);

drop policy if exists user_profiles_insert on public.user_profiles;
create policy user_profiles_insert on public.user_profiles
  for insert with check (id = auth.uid());

drop policy if exists user_profiles_update on public.user_profiles;
create policy user_profiles_update on public.user_profiles
  for update using (id = auth.uid());

-- stores
drop policy if exists stores_select on public.stores;
create policy stores_select on public.stores
  for select using (true);

drop policy if exists stores_insert on public.stores;
create policy stores_insert on public.stores
for insert
with check (
  auth.uid() is not null
  and owner_uid = auth.uid()
  and public.current_role() in ('store_manager','admin','super_admin')
);

drop policy if exists stores_update on public.stores;
create policy stores_update on public.stores
for update
using (owner_uid = auth.uid() or public.current_role() in ('admin','super_admin'))
with check (owner_uid = auth.uid() or public.current_role() in ('admin','super_admin'));

drop policy if exists stores_delete on public.stores;
create policy stores_delete on public.stores
for delete
using (owner_uid = auth.uid() or public.current_role() in ('admin','super_admin'));

-- authors (lectura pública, escritura admin)
drop policy if exists authors_select on public.authors;
create policy authors_select on public.authors
  for select using (true);

drop policy if exists authors_write on public.authors;
create policy authors_write on public.authors
for all
using (public.current_role() in ('admin','super_admin'))
with check (public.current_role() in ('admin','super_admin'));

-- categories (lectura pública, escritura admin)
drop policy if exists categories_select on public.categories;
create policy categories_select on public.categories
  for select using (true);

drop policy if exists categories_write on public.categories;
create policy categories_write on public.categories
for all
using (public.current_role() in ('admin','super_admin'))
with check (public.current_role() in ('admin','super_admin'));

-- books (admin only write)
drop policy if exists books_select on public.books;
create policy books_select on public.books
  for select using (true);

drop policy if exists books_write on public.books;
create policy books_write on public.books
for all
using (public.current_role() in ('admin','super_admin'))
with check (public.current_role() in ('admin','super_admin'));


-- junctions: books_authors, book_categories (admin only write)
drop policy if exists books_authors_select on public.books_authors;
create policy books_authors_select on public.books_authors
  for select using (true);

drop policy if exists books_authors_write on public.books_authors;
create policy books_authors_write on public.books_authors
  for all using (public.current_role() in ('admin','super_admin'))
  with check (public.current_role() in ('admin','super_admin'));

drop policy if exists book_categories_select on public.book_categories;
create policy book_categories_select on public.book_categories
  for select using (true);

drop policy if exists book_categories_write on public.book_categories;
create policy book_categories_write on public.book_categories
  for all using (public.current_role() in ('admin','super_admin'))
  with check (public.current_role() in ('admin','super_admin'));

-- listings
drop policy if exists listings_select on public.listings;
create policy listings_select on public.listings
  for select using (true);

drop policy if exists listings_cud on public.listings;
create policy listings_cud on public.listings
  for all
  using (
    exists(select 1 from public.stores s where s.id = listings.store_id and (s.owner_uid = auth.uid() or public.current_role() in ('admin','super_admin')))
  )
  with check (
    exists(select 1 from public.stores s where s.id = listings.store_id and (s.owner_uid = auth.uid() or public.current_role() in ('admin','super_admin')))
  );

-- offers
drop policy if exists offers_select on public.offers;
create policy offers_select on public.offers
  for select using (true);

drop policy if exists offers_cud on public.offers;
create policy offers_cud on public.offers
  for all
  using (
    exists(
      select 1 from public.listings l
      join public.stores s on s.id = l.store_id
      where l.id = offers.listing_id and (s.owner_uid = auth.uid() or public.current_role() in ('admin','super_admin'))
    )
  )
  with check (
    exists(
      select 1 from public.listings l
      join public.stores s on s.id = l.store_id
      where l.id = offers.listing_id and (s.owner_uid = auth.uid() or public.current_role() in ('admin','super_admin'))
    )
  );

-- favorites (cada usuario gestiona sus favoritos)
drop policy if exists favorites_select on public.favorites;
create policy favorites_select on public.favorites
  for select using (auth.uid() is not null);

drop policy if exists favorites_insert on public.favorites;
create policy favorites_insert on public.favorites
  for insert with check (user_id = auth.uid());

drop policy if exists favorites_delete on public.favorites;
create policy favorites_delete on public.favorites
  for delete using (user_id = auth.uid());

-- synonyms (lectura pública, escritura admin)
drop policy if exists synonyms_select on public.synonyms;
create policy synonyms_select on public.synonyms
  for select using (true);

drop policy if exists synonyms_write on public.synonyms;
create policy synonyms_write on public.synonyms
for all
using (public.current_role() in ('admin','super_admin'))
with check (public.current_role() in ('admin','super_admin'));

-- nationalities (lectura pública, escritura admin)
drop policy if exists nationalities_select on public.nationalities;
create policy nationalities_select on public.nationalities
  for select using (true);

drop policy if exists nationalities_write on public.nationalities;
create policy nationalities_write on public.nationalities
for all
using (public.current_role() in ('admin','super_admin'))
with check (public.current_role() in ('admin','super_admin'));

-- 🔧 Fix de permisos de esquema
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;

alter default privileges in schema public
grant select, insert, update, delete on tables to anon, authenticated;

-- compatibilidad (libros)
grant select, insert, update, delete on public.books to anon, authenticated;

-- funciones RPC
grant execute on function public.books_suggestions(text, int) to anon, authenticated;
grant execute on function public.search_books(text, jsonb, int, int, text) to anon, authenticated;
grant execute on function public.log_search(text, uuid) to anon, authenticated;
grant execute on function public.log_book_view(uuid) to anon, authenticated;
grant execute on function public.get_popular_books(text, int, int, text) to anon, authenticated;
