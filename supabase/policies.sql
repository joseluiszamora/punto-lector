-- RLS policies
alter table public.user_profiles enable row level security;
alter table public.stores enable row level security;
alter table public.books enable row level security;
alter table public.listings enable row level security;
alter table public.offers enable row level security;

-- helper: role from user_profiles
create or replace function public.current_role() returns text language sql stable as $$
  select role from public.user_profiles where id = auth.uid();
$$;

-- user_profiles
create policy if not exists user_profiles_select on public.user_profiles for select
  using (auth.uid() is not null);
create policy if not exists user_profiles_insert on public.user_profiles for insert
  with check (id = auth.uid());
create policy if not exists user_profiles_update on public.user_profiles for update
  using (id = auth.uid());

-- stores
create policy if not exists stores_select on public.stores for select using (true);
create policy if not exists stores_insert on public.stores for insert
  with check (auth.uid() is not null and (public.current_role() in ('store_manager','admin')));
create policy if not exists stores_update on public.stores for update
  using (owner_uid = auth.uid() or public.current_role() = 'admin');
create policy if not exists stores_delete on public.stores for delete
  using (owner_uid = auth.uid() or public.current_role() = 'admin');

-- books (admin only write)
create policy if not exists books_select on public.books for select using (true);
create policy if not exists books_write on public.books for all
  using (public.current_role() = 'admin') with check (public.current_role() = 'admin');

-- listings
create policy if not exists listings_select on public.listings for select using (true);
create policy if not exists listings_cud on public.listings for all
  using (
    exists(select 1 from public.stores s where s.id = listings.store_id and (s.owner_uid = auth.uid() or public.current_role() = 'admin'))
  )
  with check (
    exists(select 1 from public.stores s where s.id = listings.store_id and (s.owner_uid = auth.uid() or public.current_role() = 'admin'))
  );

-- offers
create policy if not exists offers_select on public.offers for select using (true);
create policy if not exists offers_cud on public.offers for all
  using (
    exists(select 1 from public.listings l join public.stores s on s.id = l.store_id where l.id = offers.listing_id and (s.owner_uid = auth.uid() or public.current_role() = 'admin'))
  )
  with check (
    exists(select 1 from public.listings l join public.stores s on s.id = l.store_id where l.id = offers.listing_id and (s.owner_uid = auth.uid() or public.current_role() = 'admin'))
  );
