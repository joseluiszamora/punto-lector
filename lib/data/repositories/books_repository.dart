import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';
import '../models/author.dart';
import '../models/category.dart';

abstract class IBooksRepository {
  Future<List<Book>> search({String? title, String? author, int limit = 20});
  Future<List<Book>> listAll({int limit = 500});
  Future<Book> create(Book book);
  Future<Book> getById(String id);
  Future<Book> update(String id, Book book);
  Future<void> delete(String id);
  // Nuevo: populares
  Future<List<Book>> popularBooks({
    String window,
    String mode,
    int limit,
    int offset,
  });
}

class BooksRepository implements IBooksRepository {
  final SupabaseClient _client;
  BooksRepository(this._client);

  String _selectWithRelations() =>
      '*, books_authors(authors(*)), book_categories(categories(*))';

  String _selectWithFullRelations() =>
      'id, title, cover_url, summary, review, isbn, language, published_at, books_authors(authors(*)), book_categories(categories(*))';

  @override
  Future<List<Book>> search({
    String? title,
    String? author,
    int limit = 20,
  }) async {
    final res = await _client
        .from('books')
        .select(_selectWithFullRelations())
        .limit(500);
    final List raw = (res as List);
    var books =
        raw.map((e) => Book.fromMap(Map<String, dynamic>.from(e))).toList();

    if (title != null && title.trim().isNotEmpty) {
      final t = title.trim().toLowerCase();
      books = books.where((b) => b.title.toLowerCase().contains(t)).toList();
    }
    if (author != null && author.trim().isNotEmpty) {
      final a = author.trim().toLowerCase();
      books =
          books
              .where(
                (b) => b.authors.any((au) => au.name.toLowerCase().contains(a)),
              )
              .toList();
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
        .select(_selectWithFullRelations())
        .order('title')
        .limit(limit);
    final List raw = (res as List);
    return raw.map((e) => Book.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _setAuthors(String bookId, List<String> authorIds) async {
    await _client.from('books_authors').delete().eq('book_id', bookId);
    if (authorIds.isEmpty) return;
    final rows = authorIds.map((aid) => {'book_id': bookId, 'author_id': aid});
    await _client.from('books_authors').insert(rows.toList());
  }

  Future<void> _setCategories(String bookId, List<String> categoryIds) async {
    await _client.from('book_categories').delete().eq('book_id', bookId);
    if (categoryIds.isEmpty) return;
    final rows = categoryIds.map(
      (cid) => {'book_id': bookId, 'category_id': cid},
    );
    await _client.from('book_categories').insert(rows.toList());
  }

  @override
  Future<Book> create(Book book) async {
    final inserted =
        await _client.from('books').insert(book.toInsert()).select().single();
    final id = (inserted as Map)['id'] as String;
    await _setAuthors(id, book.authors.map((a) => a.id).toList());
    await _setCategories(id, book.categories.map((c) => c.id).toList());
    return getById(id);
  }

  @override
  Future<Book> getById(String id) async {
    final res =
        await _client
            .from('books')
            .select(_selectWithFullRelations())
            .eq('id', id)
            .single();
    return Book.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<Book> update(String id, Book book) async {
    await _client.from('books').update(book.toUpdate()).eq('id', id);
    await _setAuthors(id, book.authors.map((a) => a.id).toList());
    await _setCategories(id, book.categories.map((c) => c.id).toList());
    return getById(id);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('books').delete().eq('id', id);
  }

  // Nuevo: consulta de populares vía RPC
  @override
  Future<List<Book>> popularBooks({
    String window = '7d',
    String mode = 'trending',
    int limit = 20,
    int offset = 0,
  }) async {
    final res =
        await _client
            .rpc(
              'get_popular_books',
              params: {
                'p_window': window,
                'p_limit': limit,
                'p_offset': offset,
                'p_mode': mode,
              },
            )
            .select();
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map((m) {
      final authors =
          ((m['authors'] as List?) ?? const [])
              .map((n) => Author(id: '', name: n as String))
              .toList();
      final categories =
          ((m['categories'] as List?) ?? const [])
              .map((n) => Category(id: '', name: n as String))
              .toList();
      return Book(
        id: m['id'] as String,
        title: m['title'] as String,
        coverUrl: m['cover_url'] as String?,
        authors: authors,
        categories: categories,
      );
    }).toList();
  }
}
