import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';

abstract class IBooksRepository {
  Future<List<Book>> search({String? title, String? author, int limit = 20});
  Future<List<Book>> listAll({int limit = 500});
  Future<Book> create(Book book);
  Future<Book> getById(String id);
  Future<Book> update(String id, Book book);
  Future<void> delete(String id);
}

class BooksRepository implements IBooksRepository {
  final SupabaseClient _client;
  BooksRepository(this._client);

  @override
  Future<List<Book>> search({
    String? title,
    String? author,
    int limit = 20,
  }) async {
    final res = await _client.from('books').select().limit(200);
    final List raw = (res as List);
    var books =
        raw.map((e) => Book.fromMap(Map<String, dynamic>.from(e))).toList();
    if (title != null && title.trim().isNotEmpty) {
      final t = title.trim().toLowerCase();
      books = books.where((b) => b.title.toLowerCase().contains(t)).toList();
    }
    if (author != null && author.trim().isNotEmpty) {
      final a = author.trim().toLowerCase();
      books = books.where((b) => b.author.toLowerCase().contains(a)).toList();
    }
    if (books.length > limit) {
      books = books.sublist(0, limit);
    }
    return books;
  }

  @override
  Future<List<Book>> listAll({int limit = 500}) async {
    final res = await _client
        .from('books')
        .select()
        .order('title')
        .limit(limit);
    final List raw = (res as List);
    return raw.map((e) => Book.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<Book> create(Book book) async {
    final res =
        await _client.from('books').insert(book.toInsert()).select().single();
    return Book.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<Book> getById(String id) async {
    final res = await _client.from('books').select().eq('id', id).single();
    return Book.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<Book> update(String id, Book book) async {
    final res =
        await _client
            .from('books')
            .update(book.toUpdate())
            .eq('id', id)
            .select()
            .single();
    return Book.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('books').delete().eq('id', id);
  }
}
