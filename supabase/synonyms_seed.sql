-- Seed de sinónimos básicos en español para dominios de libros
insert into public.synonyms (term, synonyms, language)
values
  ('libro', array['volumen','tomo','obra','texto'], 'es'),
  ('novela', array['ficción','relato largo'], 'es'),
  ('cuento', array['relato','narración breve'], 'es'),
  ('autor', array['escritor'], 'es'),
  ('literatura', array['letras'], 'es')
on conflict (term, language) do update set
  synonyms = excluded.synonyms,
  updated_at = now();
