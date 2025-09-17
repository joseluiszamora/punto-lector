# Supabase

## Orden de ejecución

Ejecuta en este orden:

1. `schema.sql`
2. `policies.sql`
3. `triggers.sql`
4. `seed.sql`
5. `synonyms_seed.sql` (opcional)

### Nuevas migraciones (categorías jerárquicas)

Para actualizar a la estructura jerárquica de categorías, ejecuta después del orden anterior:

6. `migration_categories_hierarchy.sql` - Migración para estructura jerárquica
7. `categories_hierarchy_rpc.sql` - Funciones RPC para categorías jerárquicas
8. `seed_categories_hierarchy.sql` - Datos de ejemplo con categorías jerárquicas

**Importante:** Si ya tienes datos en la tabla `categories`, la migración preservará los registros existentes y los marcará como categorías principales (level = 0).

Si se agregó antes algún policy, puedes limpiarlo con:

```
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
```

## Nuevas funciones RPC (categorías jerárquicas)

Después de ejecutar las migraciones de categorías, tendrás acceso a estas funciones:

### 1. `get_categories_tree()`

Devuelve el árbol completo de categorías con información jerárquica:

- `id`, `name`, `description`, `color`, `parent_id`, `level`, `sort_order`
- `children_count`: número de subcategorías
- `book_count`: número de libros en la categoría
- `full_path`: ruta completa (ej: "Historia > Historia Boliviana")

```sql
SELECT * FROM public.get_categories_tree();
```

### 2. `get_categories_by_level(target_level, parent_category_id)`

Obtiene categorías por nivel específico:

- `target_level`: 0 = principales, 1 = subcategorías, etc.
- `parent_category_id`: UUID del padre (opcional)

```sql
-- Obtener categorías principales
SELECT * FROM public.get_categories_by_level(0);

-- Obtener subcategorías de una categoría específica
SELECT * FROM public.get_categories_by_level(1, 'uuid-categoria-padre');
```

### 3. `get_category_path(category_id)`

Devuelve la ruta de breadcrumbs de una categoría:

```sql
SELECT * FROM public.get_category_path('uuid-categoria');
```

### 4. `search_categories_hierarchy(search_term, include_children)`

Búsqueda inteligente en categorías jerárquicas:

```sql
SELECT * FROM public.search_categories_hierarchy('historia', true);
```

### 5. `get_books_by_category(category_id, include_subcategories, limit_count, offset_count)`

Obtiene libros de una categoría, opcionalmente incluyendo subcategorías:

```sql
-- Libros de una categoría incluyendo subcategorías
SELECT * FROM public.get_books_by_category('uuid-categoria', true, 20, 0);
```

---

## Búsquedas: cómo funcionan

El proyecto implementa búsqueda avanzada combinando:

- FTS (Full Text Search) en español con unaccent, usando la configuración `public.es_unaccent`.
- Similitud trigram (`pg_trgm`) para coincidencias difusas.
- Tabla de sinónimos `public.synonyms` para ampliar sugerencias.

### Extensiones e índice FTS

- Extensiones: `pg_trgm` y `unaccent` (creadas en `schema.sql`).
- Configuración FTS: `public.es_unaccent` (copiada de `pg_catalog.spanish` + filtro `unaccent`).
- Índice GIN FTS sobre `books(title, summary)`:
  - `to_tsvector('public.es_unaccent', title || ' ' || summary)`.
- Índices trigram en `books.title`, `books.summary`, `authors.name`, `categories.name`.

### RPCs disponibles

**Búsquedas generales:**

1. `public.books_suggestions(q text, lim int default 10)`

   - Devuelve sugerencias de: títulos de libros, autores, categorías y sinónimos.
   - Campos: `suggestion`, `source` ('book'|'author'|'category'|'synonym'), `ref_id`, `score`.
   - Lógica: normaliza con `normalize_unaccent` y calcula similitud trigram.

2. `public.search_books(q text, filters jsonb, page int, page_size int, sort text)`
   - Devuelve resultados de libros con metainformación y score de relevancia.
   - Campos: `book_id, title, cover_url, authors[], categories[], published_at, score, listings_count, min_price, has_stock`.
   - Lógica: ranking = FTS (`to_tsvector('public.es_unaccent', ...)` vs `plainto_tsquery('public.es_unaccent', q)`) combinado con trigram sobre `title`.

**Categorías jerárquicas:** (ver sección anterior)

### Filtros soportados (filters jsonb)

- `has_stock`: boolean
- `store_city`: text (se compara normalizado/unaccent)
- `min_price`: numeric
- `max_price`: numeric
- `category_ids`: string[] (UUIDs de categorías)
- `categories`: string[] (nombres de categorías)

Ejemplo de `filters`:

```
{
  "has_stock": true,
  "store_city": "La Paz",
  "min_price": 50,
  "max_price": 200,
  "categories": ["Novela", "Clásicos"]
}
```

### Orden (`sort`)

- `relevance` (por defecto)
- `newest`
- `price_asc`
- `price_desc`

### Permisos y RLS

- RLS activo en tablas principales (stores, books, listings, etc.).
- `synonyms` tiene lectura pública y escritura solo para `admin/super_admin`.
- Grants de ejecución: `books_suggestions` y `search_books` para `anon, authenticated`.

### Semillas de sinónimos

- Script: `synonyms_seed.sql`.
- Puedes ampliar la lista de sinónimos insertando más filas o actualizando existentes.

---

### Consumo desde el cliente

**Búsquedas tradicionales:**

- Sugerencias (autocomplete): llamar a `rpc('books_suggestions', { q, lim })`.
- Resultados: `rpc('search_books', { q, filters, page, page_size, sort })`.

**Categorías jerárquicas (Flutter):**

- Árbol completo: `rpc('get_categories_tree')`
- Por nivel: `rpc('get_categories_by_level', { target_level, parent_category_id })`
- Búsqueda: `rpc('search_categories_hierarchy', { search_term, include_children })`
- Breadcrumbs: `rpc('get_category_path', { category_id })`
- Libros por categoría: `rpc('get_books_by_category', { category_id, include_subcategories, limit_count, offset_count })`

**Notas:**

- Para búsquedas acentuadas/diacríticas, la normalización elimina tildes.
- Si `q` es vacío, se devuelven resultados sin filtrar por texto (solo filtros/ordenación).
- Las categorías jerárquicas soportan hasta 10 niveles de profundidad.
- La integridad referencial está protegida contra referencias circulares.
