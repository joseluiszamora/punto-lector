-- Migration: Add hierarchical structure to categories table
-- Description: Adds parent_id, level, sort_order for subcategories support

-- Add new columns to categories table
ALTER TABLE IF EXISTS public.categories 
  ADD COLUMN IF NOT EXISTS parent_id uuid REFERENCES public.categories(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS level int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sort_order int NOT NULL DEFAULT 0;

-- Create indexes for optimized hierarchical queries
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON public.categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_level_order ON public.categories(level, sort_order);
CREATE INDEX IF NOT EXISTS idx_categories_hierarchy ON public.categories(parent_id, level, sort_order);

-- Add constraint to prevent circular references
CREATE OR REPLACE FUNCTION public.check_category_hierarchy() 
RETURNS TRIGGER AS $$
DECLARE
  circular_count INTEGER;
BEGIN
  -- Prevent self-reference
  IF NEW.parent_id = NEW.id THEN
    RAISE EXCEPTION 'Category cannot be its own parent';
  END IF;
  
  -- Check for circular reference (max depth 10)
  IF NEW.parent_id IS NOT NULL THEN
    WITH RECURSIVE hierarchy_check AS (
      SELECT id, parent_id, 1 AS depth
      FROM public.categories 
      WHERE id = NEW.parent_id
      
      UNION ALL
      
      SELECT c.id, c.parent_id, hc.depth + 1
      FROM public.categories c
      INNER JOIN hierarchy_check hc ON c.id = hc.parent_id
      WHERE hc.depth < 10
    )
    SELECT COUNT(*) INTO circular_count
    FROM hierarchy_check 
    WHERE id = NEW.id AND depth > 0;
    
    IF circular_count > 0 THEN
      RAISE EXCEPTION 'Circular reference detected in category hierarchy';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to check hierarchy integrity
DROP TRIGGER IF EXISTS trigger_check_category_hierarchy ON public.categories;
CREATE TRIGGER trigger_check_category_hierarchy
  BEFORE INSERT OR UPDATE ON public.categories
  FOR EACH ROW
  WHEN (NEW.parent_id IS NOT NULL)
  EXECUTE FUNCTION public.check_category_hierarchy();

-- Update existing categories to set proper level (all existing = level 0)
UPDATE public.categories SET level = 0 WHERE level IS NULL OR level != 0;

COMMENT ON COLUMN public.categories.parent_id IS 'Reference to parent category for hierarchical structure';
COMMENT ON COLUMN public.categories.level IS 'Hierarchy level: 0=main category, 1=subcategory, 2=sub-subcategory, etc.';
COMMENT ON COLUMN public.categories.sort_order IS 'Sort order within same parent and level';
