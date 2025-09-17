-- RPC Functions for hierarchical categories management

-- 1. Get complete category tree with children count
CREATE OR REPLACE FUNCTION public.get_categories_tree()
RETURNS TABLE(
  id uuid,
  name text,
  description text,
  color text,
  parent_id uuid,
  level int,
  sort_order int,
  children_count bigint,
  book_count bigint,
  full_path text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  WITH RECURSIVE cat_tree AS (
    -- Root categories (level 0)
    SELECT 
      c.id, c.name, c.description, c.color, c.parent_id, c.level, c.sort_order,
      c.name::text as path
    FROM public.categories c
    WHERE c.parent_id IS NULL
    
    UNION ALL
    
    -- Child categories (level 1+)
    SELECT 
      c.id, c.name, c.description, c.color, c.parent_id, c.level, c.sort_order,
      (ct.path || ' > ' || c.name)::text
    FROM public.categories c
    INNER JOIN cat_tree ct ON c.parent_id = ct.id
  )
  SELECT 
    ct.id,
    ct.name,
    ct.description,
    ct.color,
    ct.parent_id,
    ct.level,
    ct.sort_order,
    (SELECT count(*) FROM public.categories cc WHERE cc.parent_id = ct.id) as children_count,
    (SELECT count(*) FROM public.book_categories bc WHERE bc.category_id = ct.id) as book_count,
    ct.path as full_path
  FROM cat_tree ct
  ORDER BY ct.level, ct.sort_order, ct.name;
$$;

-- 2. Get categories by level (0=main, 1=subcategories, etc.)
CREATE OR REPLACE FUNCTION public.get_categories_by_level(
  target_level int DEFAULT 0,
  parent_category_id uuid DEFAULT NULL
)
RETURNS TABLE(
  id uuid,
  name text,
  description text,
  color text,
  parent_id uuid,
  level int,
  sort_order int,
  children_count bigint,
  book_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT 
    c.id,
    c.name,
    c.description,
    c.color,
    c.parent_id,
    c.level,
    c.sort_order,
    (SELECT count(*) FROM public.categories cc WHERE cc.parent_id = c.id) as children_count,
    (SELECT count(*) FROM public.book_categories bc WHERE bc.category_id = c.id) as book_count
  FROM public.categories c
  WHERE 
    c.level = target_level
    AND (parent_category_id IS NULL OR c.parent_id = parent_category_id)
  ORDER BY c.sort_order, c.name;
$$;

-- 3. Get category path (breadcrumb)
CREATE OR REPLACE FUNCTION public.get_category_path(category_id uuid)
RETURNS TABLE(
  id uuid,
  name text,
  level int
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  WITH RECURSIVE path AS (
    SELECT c.id, c.name, c.parent_id, c.level
    FROM public.categories c
    WHERE c.id = category_id
    
    UNION ALL
    
    SELECT c.id, c.name, c.parent_id, c.level
    FROM public.categories c
    INNER JOIN path p ON c.id = p.parent_id
  )
  SELECT p.id, p.name, p.level
  FROM path p
  ORDER BY p.level;
$$;

-- 4. Search in hierarchical categories
CREATE OR REPLACE FUNCTION public.search_categories_hierarchy(
  search_term text,
  include_children boolean DEFAULT true
)
RETURNS TABLE(
  id uuid,
  name text,
  description text,
  color text,
  parent_id uuid,
  level int,
  full_path text,
  match_type text,
  book_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  WITH RECURSIVE cat_tree AS (
    -- Build full paths
    SELECT 
      c.id, c.name, c.description, c.color, c.parent_id, c.level, c.sort_order,
      c.name::text as path
    FROM public.categories c
    WHERE c.parent_id IS NULL
    
    UNION ALL
    
    SELECT 
      c.id, c.name, c.description, c.color, c.parent_id, c.level, c.sort_order,
      (ct.path || ' > ' || c.name)::text
    FROM public.categories c
    INNER JOIN cat_tree ct ON c.parent_id = ct.id
  ),
  matches AS (
    SELECT 
      ct.*,
      CASE
        WHEN lower(ct.name) LIKE lower(search_term || '%') THEN 'exact'
        WHEN lower(ct.name) LIKE lower('%' || search_term || '%') THEN 'partial'
        WHEN lower(ct.path) LIKE lower('%' || search_term || '%') THEN 'path'
        ELSE 'fuzzy'
      END as match_type
    FROM cat_tree ct
    WHERE 
      lower(ct.name) LIKE lower('%' || search_term || '%')
      OR lower(ct.path) LIKE lower('%' || search_term || '%')
      OR unaccent(lower(ct.name)) LIKE unaccent(lower('%' || search_term || '%'))
  )
  SELECT 
    m.id,
    m.name,
    m.description,
    m.color,
    m.parent_id,
    m.level,
    m.path as full_path,
    m.match_type,
    (SELECT count(*) FROM public.book_categories bc WHERE bc.category_id = m.id) as book_count
  FROM matches m
  ORDER BY
    CASE m.match_type
      WHEN 'exact' THEN 1
      WHEN 'partial' THEN 2  
      WHEN 'path' THEN 3
      WHEN 'fuzzy' THEN 4
    END,
    m.level,
    m.name;
$$;

-- 5. Get books by category (including subcategories if specified)
CREATE OR REPLACE FUNCTION public.get_books_by_category(
  category_id uuid,
  include_subcategories boolean DEFAULT true,
  limit_count int DEFAULT 50,
  offset_count int DEFAULT 0
)
RETURNS TABLE(
  id uuid,
  title text,
  cover_url text,
  summary text,
  authors_label text,
  category_names text[]
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  WITH RECURSIVE target_categories AS (
    -- Base case: the category itself
    SELECT category_id as id
    
    UNION ALL
    
    -- Recursive case: all subcategories if requested
    SELECT c.id 
    FROM public.categories c
    INNER JOIN target_categories tc ON c.parent_id = tc.id
    WHERE include_subcategories
  )
  SELECT DISTINCT
    b.id,
    b.title,
    b.cover_url,
    b.summary,
    COALESCE(
      (SELECT string_agg(a.name, ', ' ORDER BY a.name) 
       FROM public.authors a 
       INNER JOIN public.books_authors ba ON a.id = ba.author_id
       WHERE ba.book_id = b.id), 
      'Sin autor'
    ) as authors_label,
    (SELECT array_agg(c.name ORDER BY c.name) 
     FROM public.categories c 
     INNER JOIN public.book_categories bc ON c.id = bc.category_id
     WHERE bc.book_id = b.id) as category_names
  FROM public.books b
  INNER JOIN public.book_categories bc ON b.id = bc.book_id
  WHERE bc.category_id IN (SELECT id FROM target_categories)
  ORDER BY b.title
  LIMIT limit_count
  OFFSET offset_count;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_categories_tree() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_categories_by_level(int, uuid) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_category_path(uuid) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.search_categories_hierarchy(text, boolean) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_books_by_category(uuid, boolean, int, int) TO authenticated, anon;
