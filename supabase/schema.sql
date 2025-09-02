-- Supabase schema for Punto Lector
-- Run via Supabase SQL editor or CLI

-- Users profile (external auth in auth.users)
create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text,
  avatar_url text,
  role text not null default 'user' check (role in ('user','store_manager','admin')),
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

-- Books (catalog)
create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text not null,
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

-- Basic indexes
create index if not exists idx_books_title on public.books using gin (to_tsvector('spanish', coalesce(title,'') || ' ' || coalesce(author,'')));
create index if not exists idx_stores_location on public.stores (lat, lng);
