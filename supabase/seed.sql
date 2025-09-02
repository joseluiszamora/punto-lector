-- Seed de datos para Punto Lector
-- Ejecutar en el SQL Editor de Supabase (o CLI) después de aplicar schema.sql y policies.sql
-- Este script es idempotente (usa WHERE NOT EXISTS)

-- 0) Perfiles de usuario (crear perfiles para usuarios existentes en auth.users)
insert into public.user_profiles (id, email, name, avatar_url, role)
select
  u.id,
  coalesce(u.email, concat('user+', left(u.id::text, 8), '@example.local')) as email,
  null as name,
  null as avatar_url,
  'user' as role
from auth.users u
where not exists (
  select 1 from public.user_profiles p where p.id = u.id
);

-- Promover uno a store_manager (si no hay ninguno aún)
update public.user_profiles p
set role = 'store_manager'
where p.id = (
  select p2.id
  from public.user_profiles p2
  order by p2.created_at
  limit 1
)
and p.role <> 'store_manager';

-- 1) Autores
insert into public.authors (name, bio, website)
select 'Gabriel García Márquez', 'Autor colombiano, Premio Nobel de Literatura.', 'https://es.wikipedia.org/wiki/Gabriel_Garc%C3%ADa_M%C3%A1rquez'
where not exists (
  select 1 from public.authors where name = 'Gabriel García Márquez'
);

insert into public.authors (name, bio, website)
select 'Julio Cortázar', 'Escritor argentino, figura clave del boom latinoamericano.', 'https://es.wikipedia.org/wiki/Julio_Cort%C3%A1zar'
where not exists (
  select 1 from public.authors where name = 'Julio Cortázar'
);

-- 2) Libros (enlazados a author_id cuando sea posible)
insert into public.books (title, author, cover_url, summary, published_at, genres, isbn, language, author_id)
select
  'Cien años de soledad',
  'Gabriel García Márquez',
  'https://images.unsplash.com/photo-1544939279-3230f2050c83?w=640',
  'Saga de la familia Buendía en Macondo.',
  '1967-05-30',
  array['novela','realismo mágico'],
  '9780307474728',
  'es',
  (select id from public.authors where name = 'Gabriel García Márquez' limit 1)
where not exists (
  select 1 from public.books where title = 'Cien años de soledad' and author = 'Gabriel García Márquez'
);

insert into public.books (title, author, cover_url, summary, published_at, genres, isbn, language, author_id)
select
  'Rayuela',
  'Julio Cortázar',
  'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=640',
  'Novela experimental con múltiples órdenes de lectura.',
  '1963-06-28',
  array['novela','vanguardista'],
  '9788437604947',
  'es',
  (select id from public.authors where name = 'Julio Cortázar' limit 1)
where not exists (
  select 1 from public.books where title = 'Rayuela' and author = 'Julio Cortázar'
);

-- 3) Tiendas
-- Elegimos un dueño existente (primer perfil). Si no hay usuarios, se omiten estas inserciones.
with owner as (
  select id from public.user_profiles order by created_at limit 1
)
insert into public.stores (
  owner_uid, name, manager_name, address, city, lat, lng, phone, description, open_days, open_hour, close_hour, photo_url, active
)
select
  owner.id,
  'Librería Central',
  'María López',
  'C. Comercio 123',
  'La Paz',
  -16.494, -68.135,
  '+591 2 1234567',
  'Especialistas en literatura latinoamericana.',
  array[1,2,3,4,5],
  '09:00', '18:00',
  'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=640',
  true
from owner
where exists (select 1 from owner)
and not exists (
  select 1 from public.stores where name = 'Librería Central'
);

with owner as (
  select id from public.user_profiles order by created_at limit 1
)
insert into public.stores (
  owner_uid, name, manager_name, address, city, lat, lng, phone, description, open_days, open_hour, close_hour, photo_url, active
)
select
  owner.id,
  'Librería El Lector',
  'Juan Pérez',
  'Av. Principal 456',
  'Santa Cruz',
  -17.783, -63.182,
  '+591 3 7654321',
  'Novedades y best-sellers.',
  array[1,2,3,4,5,6],
  '10:00', '19:00',
  'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?w=640',
  true
from owner
where exists (select 1 from owner)
and not exists (
  select 1 from public.stores where name = 'Librería El Lector'
);

-- 4) Listings (precios/stock) usando tienda y libro por nombre
insert into public.listings (store_id, book_id, price, currency, stock, active)
select s.id, b.id, 120.00, 'BOB', 10, true
from public.stores s, public.books b
where s.name = 'Librería Central' and b.title = 'Cien años de soledad'
and not exists (
  select 1 from public.listings l where l.store_id = s.id and l.book_id = b.id
);

insert into public.listings (store_id, book_id, price, currency, stock, active)
select s.id, b.id, 150.00, 'BOB', 7, true
from public.stores s, public.books b
where s.name = 'Librería El Lector' and b.title = 'Rayuela'
and not exists (
  select 1 from public.listings l where l.store_id = s.id and l.book_id = b.id
);

-- 5) Oferta de ejemplo
insert into public.offers (listing_id, discount_pct, price_after, start_at, end_at, active)
select l.id, 10.00, (l.price * 0.90), now(), now() + interval '30 days', true
from public.listings l
join public.books b on b.id = l.book_id
join public.stores s on s.id = l.store_id
where s.name = 'Librería Central' and b.title = 'Cien años de soledad'
and not exists (
  select 1 from public.offers o where o.listing_id = l.id
);

-- Fin del seed
