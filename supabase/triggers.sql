-- Auto-crear perfil en public.user_profiles al crear usuario en auth.users
-- Ejecutar una vez en el SQL Editor de Supabase

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profiles (id, email, role)
  values (new.id, coalesce(new.email, concat('user+', left(new.id::text, 8), '@example.local')), 'user')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
