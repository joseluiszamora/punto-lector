-- RLS policies
alter table public.user_profiles enable row level security;
alter table public.stores enable row level security;
alter table public.books enable row level security;
alter table public.listings enable row level security;
alter table public.offers enable row level security;

-- helper: role from user_profiles
create or replace function public.current_role() returns text language sql stable as $$
  select coalesce(role, 'user') from public.user_profiles where id = auth.uid();
$$;

-- user_profiles
create policy user_profiles_select on public.user_profiles
  for select using (auth.uid() is not null);

create policy user_profiles_insert on public.user_profiles
  for insert with check (id = auth.uid());

create policy user_profiles_update on public.user_profiles
  for update using (id = auth.uid());

-- stores
create policy stores_select on public.stores
  for select using (true);

create policy stores_insert on public.stores
for insert
with check (
  auth.uid() is not null
  and owner_uid = auth.uid()
  and public.current_role() in ('store_manager','admin','super_admin')
);

create policy stores_update on public.stores
for update
using (owner_uid = auth.uid() or public.current_role() in ('admin','super_admin'))
with check (owner_uid = auth.uid() or public.current_role() in ('admin','super_admin'));

create policy stores_delete on public.stores
for delete
using (owner_uid = auth.uid() or public.current_role() in ('admin','super_admin'));

-- books (admin only write)
create policy books_select on public.books
  for select using (true);

create policy books_write on public.books
for all
using (public.current_role() in ('admin','super_admin'))
with check (public.current_role() in ('admin','super_admin'));


-- listings
create policy listings_select on public.listings
  for select using (true);

create policy listings_cud on public.listings
  for all
  using (
    exists(select 1 from public.stores s where s.id = listings.store_id and (s.owner_uid = auth.uid() or public.current_role() = 'admin'))
  )
  with check (
    exists(select 1 from public.stores s where s.id = listings.store_id and (s.owner_uid = auth.uid() or public.current_role() = 'admin'))
  );

-- offers
create policy offers_select on public.offers
  for select using (true);

create policy offers_cud on public.offers
  for all
  using (
    exists(select 1 from public.listings l join public.stores s on s.id = l.store_id where l.id = offers.listing_id and (s.owner_uid = auth.uid() or public.current_role() = 'admin'))
  )
  with check (
    exists(select 1 from public.listings l join public.stores s on s.id = l.store_id where l.id = offers.listing_id and (s.owner_uid = auth.uid() or public.current_role() = 'admin'))
  );

-- 🔧 Fix de permisos de esquema
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;

alter default privileges in schema public
grant select, insert, update, delete on tables to anon, authenticated;

-- solo para libros
grant select, insert, update, delete on public.books to anon, authenticated;
