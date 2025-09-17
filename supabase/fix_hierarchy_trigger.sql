-- Fix for the hierarchy check trigger function
-- This addresses the PostgreSQL error: query has no destination for result data

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS trigger_check_category_hierarchy ON public.categories;
DROP FUNCTION IF EXISTS public.check_category_hierarchy();

-- Create improved function with better error handling
CREATE OR REPLACE FUNCTION public.check_category_hierarchy() 
RETURNS TRIGGER AS $$
DECLARE
  circular_count INTEGER := 0;
BEGIN
  -- Prevent self-reference
  IF NEW.parent_id = NEW.id THEN
    RAISE EXCEPTION 'Category cannot be its own parent';
  END IF;
  
  -- Check for circular reference only if parent_id is not null
  IF NEW.parent_id IS NOT NULL THEN
    -- Use a more robust approach to detect circular references
    WITH RECURSIVE hierarchy_check AS (
      -- Start from the proposed parent
      SELECT id, parent_id, 1 AS depth
      FROM public.categories 
      WHERE id = NEW.parent_id
      
      UNION ALL
      
      -- Follow the parent chain upwards
      SELECT c.id, c.parent_id, hc.depth + 1
      FROM public.categories c
      INNER JOIN hierarchy_check hc ON c.id = hc.parent_id
      WHERE hc.depth < 10 -- Prevent infinite loops
    )
    SELECT COALESCE((
      SELECT COUNT(*)
      FROM hierarchy_check 
      WHERE id = NEW.id
    ), 0) INTO circular_count;
    
    -- If we find the current category ID in the parent chain, it's circular
    IF circular_count > 0 THEN
      RAISE EXCEPTION 'Circular reference detected: category cannot be a descendant of itself';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger again
CREATE TRIGGER trigger_check_category_hierarchy
  BEFORE INSERT OR UPDATE ON public.categories
  FOR EACH ROW
  WHEN (NEW.parent_id IS NOT NULL)
  EXECUTE FUNCTION public.check_category_hierarchy();
