-- Seed data for hierarchical categories
-- Ejecutar después de migration_categories_hierarchy.sql

-- Clear existing categories first (if needed)
-- DELETE FROM public.categories;

-- 1. Insert main categories (level 0)
INSERT INTO public.categories (id, name, description, color, level, sort_order) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'Historia', 'Libros de historia y eventos históricos', '#8B4513', 0, 1),
  ('550e8400-e29b-41d4-a716-446655440002', 'Literatura', 'Novelas, cuentos y obras literarias', '#4A90E2', 0, 2),
  ('550e8400-e29b-41d4-a716-446655440003', 'Ciencia', 'Libros científicos y técnicos', '#50C878', 0, 3),
  ('550e8400-e29b-41d4-a716-446655440004', 'Arte', 'Libros sobre arte y cultura', '#FF6B6B', 0, 4),
  ('550e8400-e29b-41d4-a716-446655440005', 'Filosofía', 'Libros de filosofía y pensamiento', '#9B59B6', 0, 5),
  ('550e8400-e29b-41d4-a716-446655440006', 'Educación', 'Libros educativos y manuales', '#F39C12', 0, 6),
  ('550e8400-e29b-41d4-a716-446655440007', 'Deportes', 'Libros sobre deportes y actividad física', '#E74C3C', 0, 7),
  ('550e8400-e29b-41d4-a716-446655440008', 'Cocina', 'Libros de recetas y gastronomía', '#D35400', 0, 8)
ON CONFLICT (id) DO NOTHING;

-- 2. Insert subcategories for Historia (level 1)
INSERT INTO public.categories (id, name, description, parent_id, level, sort_order) VALUES
  ('550e8400-e29b-41d4-a716-446655441001', 'Historia Boliviana', 'Historia de Bolivia', '550e8400-e29b-41d4-a716-446655440001', 1, 1),
  ('550e8400-e29b-41d4-a716-446655441002', 'Historia Latinoamericana', 'Historia de América Latina', '550e8400-e29b-41d4-a716-446655440001', 1, 2),
  ('550e8400-e29b-41d4-a716-446655441003', 'Historia Europea', 'Historia de Europa', '550e8400-e29b-41d4-a716-446655440001', 1, 3),
  ('550e8400-e29b-41d4-a716-446655441004', 'Historia Mundial', 'Historia universal', '550e8400-e29b-41d4-a716-446655440001', 1, 4),
  ('550e8400-e29b-41d4-a716-446655441005', 'Historia Antigua', 'Civilizaciones antiguas', '550e8400-e29b-41d4-a716-446655440001', 1, 5)
ON CONFLICT (id) DO NOTHING;

-- 3. Insert subcategories for Literatura (level 1)
INSERT INTO public.categories (id, name, description, parent_id, level, sort_order) VALUES
  ('550e8400-e29b-41d4-a716-446655442001', 'Novela Contemporánea', 'Novelas modernas y actuales', '550e8400-e29b-41d4-a716-446655440002', 1, 1),
  ('550e8400-e29b-41d4-a716-446655442002', 'Poesía', 'Libros de poesía y verso', '550e8400-e29b-41d4-a716-446655440002', 1, 2),
  ('550e8400-e29b-41d4-a716-446655442003', 'Literatura Boliviana', 'Autores y obras bolivianas', '550e8400-e29b-41d4-a716-446655440002', 1, 3),
  ('550e8400-e29b-41d4-a716-446655442004', 'Literatura Clásica', 'Obras literarias clásicas', '550e8400-e29b-41d4-a716-446655440002', 1, 4),
  ('550e8400-e29b-41d4-a716-446655442005', 'Cuentos', 'Colecciones de cuentos cortos', '550e8400-e29b-41d4-a716-446655440002', 1, 5),
  ('550e8400-e29b-41d4-a716-446655442006', 'Teatro', 'Obras teatrales y dramaturgia', '550e8400-e29b-41d4-a716-446655440002', 1, 6)
ON CONFLICT (id) DO NOTHING;

-- 4. Insert subcategories for Ciencia (level 1)
INSERT INTO public.categories (id, name, description, parent_id, level, sort_order) VALUES
  ('550e8400-e29b-41d4-a716-446655443001', 'Matemáticas', 'Libros de matemáticas', '550e8400-e29b-41d4-a716-446655440003', 1, 1),
  ('550e8400-e29b-41d4-a716-446655443002', 'Física', 'Libros de física', '550e8400-e29b-41d4-a716-446655440003', 1, 2),
  ('550e8400-e29b-41d4-a716-446655443003', 'Química', 'Libros de química', '550e8400-e29b-41d4-a716-446655440003', 1, 3),
  ('550e8400-e29b-41d4-a716-446655443004', 'Biología', 'Libros de biología y ciencias naturales', '550e8400-e29b-41d4-a716-446655440003', 1, 4),
  ('550e8400-e29b-41d4-a716-446655443005', 'Tecnología', 'Libros sobre tecnología e informática', '550e8400-e29b-41d4-a716-446655440003', 1, 5),
  ('550e8400-e29b-41d4-a716-446655443006', 'Medicina', 'Libros de medicina y salud', '550e8400-e29b-41d4-a716-446655440003', 1, 6)
ON CONFLICT (id) DO NOTHING;

-- 5. Insert subcategories for Arte (level 1)
INSERT INTO public.categories (id, name, description, parent_id, level, sort_order) VALUES
  ('550e8400-e29b-41d4-a716-446655444001', 'Pintura', 'Libros sobre pintura y artistas', '550e8400-e29b-41d4-a716-446655440004', 1, 1),
  ('550e8400-e29b-41d4-a716-446655444002', 'Escultura', 'Libros sobre escultura', '550e8400-e29b-41d4-a716-446655440004', 1, 2),
  ('550e8400-e29b-41d4-a716-446655444003', 'Arquitectura', 'Libros sobre arquitectura', '550e8400-e29b-41d4-a716-446655440004', 1, 3),
  ('550e8400-e29b-41d4-a716-446655444004', 'Fotografía', 'Libros sobre fotografía', '550e8400-e29b-41d4-a716-446655440004', 1, 4),
  ('550e8400-e29b-41d4-a716-446655444005', 'Música', 'Libros sobre música y compositores', '550e8400-e29b-41d4-a716-446655440004', 1, 5),
  ('550e8400-e29b-41d4-a716-446655444006', 'Cine', 'Libros sobre cine y directores', '550e8400-e29b-41d4-a716-446655440004', 1, 6)
ON CONFLICT (id) DO NOTHING;

-- 6. Insert subcategories for Educación (level 1)
INSERT INTO public.categories (id, name, description, parent_id, level, sort_order) VALUES
  ('550e8400-e29b-41d4-a716-446655446001', 'Primaria', 'Libros para educación primaria', '550e8400-e29b-41d4-a716-446655440006', 1, 1),
  ('550e8400-e29b-41d4-a716-446655446002', 'Secundaria', 'Libros para educación secundaria', '550e8400-e29b-41d4-a716-446655440006', 1, 2),
  ('550e8400-e29b-41d4-a716-446655446003', 'Universidad', 'Libros universitarios', '550e8400-e29b-41d4-a716-446655440006', 1, 3),
  ('550e8400-e29b-41d4-a716-446655446004', 'Idiomas', 'Libros para aprender idiomas', '550e8400-e29b-41d4-a716-446655440006', 1, 4),
  ('550e8400-e29b-41d4-a716-446655446005', 'Manuales Técnicos', 'Manuales y guías técnicas', '550e8400-e29b-41d4-a716-446655440006', 1, 5)
ON CONFLICT (id) DO NOTHING;

-- Update existing seed data to assign categories to books
-- This is just an example, adjust based on your existing books

-- Assign "Cien años de soledad" to Literatura > Literatura Latinoamericana
INSERT INTO public.books_categories (book_id, category_id)
SELECT b.id, '550e8400-e29b-41d4-a716-446655442002'
FROM public.books b
WHERE b.title = 'Cien años de soledad'
AND NOT EXISTS (
  SELECT 1 FROM public.books_categories bc 
  WHERE bc.book_id = b.id AND bc.category_id = '550e8400-e29b-41d4-a716-446655442002'
);

-- Assign "Rayuela" to Literatura > Novela Contemporánea
INSERT INTO public.books_categories (book_id, category_id)
SELECT b.id, '550e8400-e29b-41d4-a716-446655442001'
FROM public.books b
WHERE b.title = 'Rayuela'
AND NOT EXISTS (
  SELECT 1 FROM public.books_categories bc 
  WHERE bc.book_id = b.id AND bc.category_id = '550e8400-e29b-41d4-a716-446655442001'
);

-- Example: Add some level 2 subcategories (sub-subcategories)
INSERT INTO public.categories (id, name, description, parent_id, level, sort_order) VALUES
  ('550e8400-e29b-41d4-a716-446655451001', 'Guerra del Chaco', 'Historia de la Guerra del Chaco', '550e8400-e29b-41d4-a716-446655441001', 2, 1),
  ('550e8400-e29b-41d4-a716-446655451002', 'Revolución de 1952', 'Revolución Nacional Boliviana', '550e8400-e29b-41d4-a716-446655441001', 2, 2),
  ('550e8400-e29b-41d4-a716-446655451003', 'Época Colonial', 'Período colonial boliviano', '550e8400-e29b-41d4-a716-446655441001', 2, 3)
ON CONFLICT (id) DO NOTHING;

-- Verify the hierarchy
-- SELECT * FROM public.get_categories_tree();
