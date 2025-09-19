-- Seed de datos para Punto Lector (actualizado sin columna author en books)
-- Ejecutar en el SQL Editor de Supabase (o CLI) después de aplicar schema.sql y policies.sql
-- Este script es idempotente

-- 0) Perfiles de usuario
insert into public.user_profiles (id, email, name, avatar_url, role)
select
  u.id,
  coalesce(u.email, concat('user+', left(u.id::text, 8), '@example.local')) as email,
  null,
  null,
  'user'
from auth.users u
where not exists (select 1 from public.user_profiles p where p.id = u.id);

update public.user_profiles p
set role = 'store_manager'
where p.id = (
  select p2.id from public.user_profiles p2 order by p2.created_at limit 1
) and p.role <> 'store_manager';

-- 1) Autores
insert into public.authors (name, bio)
select 'Gabriel García Márquez', 'Autor colombiano, Premio Nobel de Literatura.'
where not exists (select 1 from public.authors where name = 'Gabriel García Márquez');

insert into public.authors (name, bio)
select 'Julio Cortázar', 'Escritor argentino, figura clave del boom latinoamericano.'
where not exists (select 1 from public.authors where name = 'Julio Cortázar');

-- 1.1) Asignar nacionalidad a autores si existen
update public.authors a
set nationality_id = n.id
from public.nationalities n
where a.name = 'Gabriel García Márquez' and n.country_code = 'CO' and a.nationality_id is distinct from n.id;

update public.authors a
set nationality_id = n.id
from public.nationalities n
where a.name = 'Julio Cortázar' and n.country_code = 'AR' and a.nationality_id is distinct from n.id;

-- 2) Libros (sin columna author)
insert into public.books (title, cover_url, summary, published_at, isbn, language)
select
  'Cien años de soledad',
  'https://images.unsplash.com/photo-1544939279-3230f2050c83?w=640',
  'Saga de la familia Buendía en Macondo.',
  '1967-05-30',
  '9780307474728',
  'es'
where not exists (select 1 from public.books where title = 'Cien años de soledad');

insert into public.books (title, cover_url, summary, published_at, isbn, language)
select
  'Rayuela',
  'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=640',
  'Novela experimental con múltiples órdenes de lectura.',
  '1963-06-28',
  '9788437604947',
  'es'
where not exists (select 1 from public.books where title = 'Rayuela');

-- 2.1) Vincular libros con autores
insert into public.books_authors (book_id, author_id)
select b.id, a.id
from public.books b
join public.authors a on a.name = 'Gabriel García Márquez'
where b.title = 'Cien años de soledad'
  and not exists (select 1 from public.books_authors ba where ba.book_id = b.id and ba.author_id = a.id);

insert into public.books_authors (book_id, author_id)
select b.id, a.id
from public.books b
join public.authors a on a.name = 'Julio Cortázar'
where b.title = 'Rayuela'
  and not exists (select 1 from public.books_authors ba where ba.book_id = b.id and ba.author_id = a.id);

-- 3) Categorías
insert into public.categories (name, description, color)
select 'Novela', 'Ficción narrativa', '#6B7280'
where not exists (select 1 from public.categories where name = 'Novela');

insert into public.categories (name, description, color)
select 'Clásicos', 'Obras clásicas de literatura', '#F59E0B'
where not exists (select 1 from public.categories where name = 'Clásicos');

-- 3.1) Vincular libros con categorías
insert into public.book_categories (book_id, category_id)
select b.id, c.id
from public.books b, public.categories c
where b.title = 'Cien años de soledad' and c.name = 'Novela'
  and not exists (select 1 from public.book_categories bc where bc.book_id = b.id and bc.category_id = c.id);

insert into public.book_categories (book_id, category_id)
select b.id, c.id
from public.books b, public.categories c
where b.title = 'Rayuela' and c.name = 'Clásicos'
  and not exists (select 1 from public.book_categories bc where bc.book_id = b.id and bc.category_id = c.id);

-- 4) Tiendas
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
and not exists (select 1 from public.stores where name = 'Librería Central');

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
and not exists (select 1 from public.stores where name = 'Librería El Lector');

-- 5) Listings
insert into public.listings (store_id, book_id, price, currency, stock, active)
select s.id, b.id, 120.00, 'BOB', 10, true
from public.stores s, public.books b
where s.name = 'Librería Central' and b.title = 'Cien años de soledad'
and not exists (select 1 from public.listings l where l.store_id = s.id and l.book_id = b.id);

insert into public.listings (store_id, book_id, price, currency, stock, active)
select s.id, b.id, 150.00, 'BOB', 7, true
from public.stores s, public.books b
where s.name = 'Librería El Lector' and b.title = 'Rayuela'
and not exists (select 1 from public.listings l where l.store_id = s.id and l.book_id = b.id);

-- 6) Oferta de ejemplo
insert into public.offers (listing_id, discount_pct, price_after, start_at, end_at, active)
select l.id, 10.00, (l.price * 0.90), now(), now() + interval '30 days', true
from public.listings l
join public.books b on b.id = l.book_id
join public.stores s on s.id = l.store_id
where s.name = 'Librería Central' and b.title = 'Cien años de soledad'
and not exists (select 1 from public.offers o where o.listing_id = l.id);

-- 7) Favoritos de ejemplo
with u as (
  select id from public.user_profiles order by created_at limit 1
)
insert into public.favorites (user_id, book_id)
select u.id, b.id
from u, public.books b
where b.title in ('Cien años de soledad')
and not exists (select 1 from public.favorites f where f.user_id = u.id and f.book_id = b.id);

-- A) Nationalities (países hispanohablantes principales)
insert into public.nationalities (name, country_code, flag_url)
values
  ('Argentina', 'ar', 'https://flagcdn.com/48x36/ar.png'),
  ('Bolivia', 'bo', 'https://flagcdn.com/48x36/bo.png'),
  ('Chile', 'cl', 'https://flagcdn.com/48x36/cl.png'),
  ('Colombia', 'co', 'https://flagcdn.com/48x36/co.png'),
  ('Costa Rica', 'cr', 'https://flagcdn.com/48x36/cr.png'),
  ('Cuba', 'cu', 'https://flagcdn.com/48x36/cu.png'),
  ('Ecuador', 'ec', 'https://flagcdn.com/48x36/ec.png'),
  ('El Salvador', 'sv', 'https://flagcdn.com/48x36/sv.png'),
  ('España', 'es', 'https://flagcdn.com/48x36/es.png'),
  ('Guatemala', 'gt', 'https://flagcdn.com/48x36/gt.png'),
  ('Honduras', 'hn', 'https://flagcdn.com/48x36/hn.png'),
  ('México', 'mx', 'https://flagcdn.com/48x36/mx.png'),
  ('Nicaragua', 'ni', 'https://flagcdn.com/48x36/ni.png'),
  ('Panamá', 'pa', 'https://flagcdn.com/48x36/pa.png'),
  ('Paraguay', 'py', 'https://flagcdn.com/48x36/py.png'),
  ('Perú', 'pe', 'https://flagcdn.com/48x36/pe.png'),
  ('Puerto Rico', 'pr', 'https://flagcdn.com/48x36/pr.png'),
  ('República Dominicana', 'do', 'https://flagcdn.com/48x36/do.png'),
  ('Uruguay', 'uy', 'https://flagcdn.com/48x36/uy.png'),
  ('Venezuela', 've', 'https://flagcdn.com/48x36/ve.png')
on conflict (country_code) do update set
  name = excluded.name,
  flag_url = excluded.flag_url,
  updated_at = now();

-- Fin del seed
