-- Supabase schema for Punto Lector
-- Run via Supabase SQL editor or CLI

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

-- Basic indexes
create index if not exists idx_books_title on public.books using gin (to_tsvector('spanish', coalesce(title,'') || ' ' || coalesce(summary,'')));
create index if not exists idx_stores_location on public.stores (lat, lng);
create index if not exists idx_authors_name on public.authors (name);
