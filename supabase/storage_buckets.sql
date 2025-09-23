-- Storage buckets
select storage.create_bucket('book_covers', public => true);
select storage.create_bucket('store_photos', public => true);
select storage.create_bucket('author_photos', public => true);

-- Storage policies (public read, public write for admin operations)
drop policy if exists book_covers_read on storage.objects;
create policy book_covers_read on storage.objects for select to public
  using (bucket_id = 'book_covers');
drop policy if exists store_photos_read on storage.objects;
create policy store_photos_read on storage.objects for select to public
  using (bucket_id = 'store_photos');
drop policy if exists author_photos_read on storage.objects;
create policy author_photos_read on storage.objects for select to public
  using (bucket_id = 'author_photos');

drop policy if exists book_covers_write on storage.objects;
create policy book_covers_write on storage.objects for all to public
  using (bucket_id = 'book_covers') with check (bucket_id = 'book_covers');
drop policy if exists store_photos_write on storage.objects;
create policy store_photos_write on storage.objects for all to public
  using (bucket_id = 'store_photos') with check (bucket_id = 'store_photos');
drop policy if exists author_photos_write on storage.objects;
create policy author_photos_write on storage.objects for all to public
  using (bucket_id = 'author_photos') with check (bucket_id = 'author_photos');
