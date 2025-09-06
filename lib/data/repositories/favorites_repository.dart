import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/book.dart';

class FavoritesRepository {
  final SupabaseClient _client;
  FavoritesRepository(this._client);

  String _bookSelect() =>
      'book:books(*, books_authors(authors(*)), book_categories(categories(*)))';

  Future<void> add(String userId, String bookId) async {
    // Evita duplicados con upsert y onConflict
    await _client
        .from('favorites')
        .upsert(
          {'user_id': userId, 'book_id': bookId},
          onConflict: 'user_id,book_id',
          ignoreDuplicates: true,
        );
  }

  Future<void> removeByBook(String userId, String bookId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('book_id', bookId);
  }

  Future<bool> isFavorited(String userId, String bookId) async {
    final res =
        await _client
            .from('favorites')
            .select('id')
            .eq('user_id', userId)
            .eq('book_id', bookId)
            .maybeSingle();
    return res != null;
  }

  Future<Set<String>> listUserFavoriteBookIds(String userId) async {
    final res = await _client
        .from('favorites')
        .select('book_id')
        .eq('user_id', userId);
    final List data = res as List;
    return data
        .map((e) => (e as Map)['book_id']?.toString())
        .whereType<String>()
        .toSet();
  }

  Future<List<Book>> listUserFavoriteBooks(String userId) async {
    final res = await _client
        .from('favorites')
        .select(_bookSelect())
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final List data = res as List;
    return data
        .map((row) => (row as Map)['book'])
        .where((b) => b != null)
        .map((b) => Book.fromMap(Map<String, dynamic>.from(b as Map)))
        .toList(growable: false);
  }
}
