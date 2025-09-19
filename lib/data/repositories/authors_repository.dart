import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/author.dart';
import '../models/book.dart';

abstract class IAuthorsRepository {
  Future<List<Author>> listAll({int limit});
  Future<List<Book>> getBooksByAuthor(String authorId);
  Future<Author> create({
    required String name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? nationalityId,
  });
  Future<Author> update(
    String id, {
    required String name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? nationalityId,
  });
  Future<void> delete(String id);
}

class AuthorsRepository implements IAuthorsRepository {
  final SupabaseClient _client;
  AuthorsRepository(this._client);

  String? _toPgDate(DateTime? d) =>
      d == null ? null : d.toIso8601String().split('T').first;

  @override
  Future<List<Author>> listAll({int limit = 500}) async {
    final res = await _client
        .from('authors')
        .select(
          'id, name, bio, birth_date, death_date, photo_url, nationality_id, created_at, updated_at',
        )
        .order('name')
        .limit(limit);
    final List raw = (res as List);
    return raw
        .map((e) => Author.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Author> create({
    required String name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? nationalityId,
  }) async {
    final payload = {
      'name': name,
      'bio': bio,
      'birth_date': _toPgDate(birthDate),
      'death_date': _toPgDate(deathDate),
      'photo_url': photoUrl,
      if (nationalityId != null) 'nationality_id': nationalityId,
    };
    final res =
        await _client
            .from('authors')
            .insert(payload)
            .select(
              'id, name, bio, birth_date, death_date, photo_url, nationality_id, created_at, updated_at',
            )
            .single();
    return Author.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<Author> update(
    String id, {
    required String name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? nationalityId,
  }) async {
    final payload = {
      'name': name,
      'bio': bio,
      'birth_date': _toPgDate(birthDate),
      'death_date': _toPgDate(deathDate),
      'photo_url': photoUrl,
      'nationality_id': nationalityId,
    };
    final res =
        await _client
            .from('authors')
            .update(payload)
            .eq('id', id)
            .select(
              'id, name, bio, birth_date, death_date, photo_url, nationality_id, created_at, updated_at',
            )
            .single();
    return Author.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('authors').delete().eq('id', id);
  }

  @override
  Future<List<Book>> getBooksByAuthor(String authorId) async {
    final res = await _client
        .from('books')
        .select('''
          id, title, summary, review, isbn, language, published_at, cover_url, created_at, updated_at,
          books_authors!inner(author_id),
          book_categories(
            categories(id, name, color)
          )
        ''')
        .eq('books_authors.author_id', authorId)
        .order('published_at', ascending: false);

    final List raw = (res as List);
    return raw.map((bookData) {
      // Extraer las categorías de la estructura anidada
      final List<dynamic> bookCategories = bookData['book_categories'] ?? [];
      final categories =
          bookCategories
              .map((bc) => bc['categories'])
              .where((cat) => cat != null)
              .map((cat) => Map<String, dynamic>.from(cat))
              .toList();

      // Crear el mapa del libro con las categorías procesadas
      final bookMap = Map<String, dynamic>.from(bookData);
      bookMap['categories'] = categories;
      bookMap.remove(
        'book_categories',
      ); // Remover la estructura anidada original
      bookMap.remove('books_authors'); // Remover la tabla de unión

      return Book.fromMap(bookMap);
    }).toList();
  }
}
