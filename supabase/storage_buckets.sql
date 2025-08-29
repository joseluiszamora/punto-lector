-- Storage buckets
select storage.create_bucket('book_covers', public => true);
select storage.create_bucket('store_photos', public => true);

-- Storage policies (public read, owner write)
create policy if not exists book_covers_read on storage.objects for select to public
  using (bucket_id = 'book_covers');
create policy if not exists store_photos_read on storage.objects for select to public
  using (bucket_id = 'store_photos');

create policy if not exists book_covers_write on storage.objects for all to authenticated
  using (bucket_id = 'book_covers') with check (bucket_id = 'book_covers');
create policy if not exists store_photos_write on storage.objects for all to authenticated
  using (bucket_id = 'store_photos') with check (bucket_id = 'store_photos');
