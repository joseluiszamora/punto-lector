jecuta en este orden:
schema.sql →
policies.sql →
triggers.sql
seed.sql.

si se agrego antes algun policy

drop policy if exists user_profiles_select on public.user_profiles;
drop policy if exists user_profiles_insert on public.user_profiles;
drop policy if exists user_profiles_update on public.user_profiles;
drop policy if exists stores_select on public.stores;
drop policy if exists stores_insert on public.stores;
drop policy if exists stores_update on public.stores;
drop policy if exists stores_delete on public.stores;
drop policy if exists books_select on public.books;
drop policy if exists books_write on public.books;
drop policy if exists listings_select on public.listings;
drop policy if exists listings_cud on public.listings;
drop policy if exists offers_select on public.offers;
drop policy if exists offers_cud on public.offers;
