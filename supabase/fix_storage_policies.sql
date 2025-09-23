-- Script para permitir uploads públicos en buckets de storage
-- Ejecutar en Supabase SQL Editor

-- Actualizar política para author_photos (permitir escritura pública)
DROP POLICY IF EXISTS "author_photos_write" ON storage.objects;
CREATE POLICY "author_photos_write" ON storage.objects 
FOR ALL TO anon, authenticated 
USING (bucket_id = 'author_photos') 
WITH CHECK (bucket_id = 'author_photos');

-- Verificar que el bucket sea público
UPDATE storage.buckets 
SET public = true 
WHERE id = 'author_photos';

-- Opcional: También para los otros buckets
DROP POLICY IF EXISTS "book_covers_write" ON storage.objects;
CREATE POLICY "book_covers_write" ON storage.objects 
FOR ALL TO anon, authenticated 
USING (bucket_id = 'book_covers') 
WITH CHECK (bucket_id = 'book_covers');

DROP POLICY IF EXISTS "store_photos_write" ON storage.objects;
CREATE POLICY "store_photos_write" ON storage.objects 
FOR ALL TO anon, authenticated 
USING (bucket_id = 'store_photos') 
WITH CHECK (bucket_id = 'store_photos');

UPDATE storage.buckets 
SET public = true 
WHERE id IN ('book_covers', 'store_photos');
