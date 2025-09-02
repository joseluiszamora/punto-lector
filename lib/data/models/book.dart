import 'author.dart';
import 'category.dart';

class Book {
  final String id;
  final String title;
  final List<Author> authors; // M:N
  final List<Category> categories; // M:N
  final String? coverUrl;
  final String? summary;
  final DateTime? publishedAt;

  const Book({
    required this.id,
    required this.title,
    this.authors = const [],
    this.categories = const [],
    this.coverUrl,
    this.summary,
    this.publishedAt,
  });

  String get authorsLabel =>
      authors.isEmpty
          ? 'Sin autor disponible'
          : authors.map((a) => a.name).join(', ');

  factory Book.fromMap(Map<String, dynamic> map) {
    // Parse autores desde nested: books_authors -> [{ authors: { id, name } }]
    final List<Author> parsedAuthors = () {
      final rel = map['books_authors'] as List?;
      if (rel == null) return const <Author>[];
      return rel
          .map(
            (e) =>
                (e is Map && e['authors'] != null)
                    ? Author.fromMap(
                      Map<String, dynamic>.from(e['authors'] as Map),
                    )
                    : null,
          )
          .whereType<Author>()
          .toList(growable: false);
    }();

    // Parse categorías: book_categories -> [{ categories: { id, name } }]
    final List<Category> parsedCategories = () {
      final rel = map['book_categories'] as List?;
      if (rel == null) return const <Category>[];
      return rel
          .map(
            (e) =>
                (e is Map && e['categories'] != null)
                    ? Category.fromMap(
                      Map<String, dynamic>.from(e['categories'] as Map),
                    )
                    : null,
          )
          .whereType<Category>()
          .toList(growable: false);
    }();

    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      authors: parsedAuthors,
      categories: parsedCategories,
      coverUrl: map['cover_url'] as String?,
      summary: map['summary'] as String?,
      publishedAt:
          map['published_at'] != null
              ? DateTime.tryParse(map['published_at'].toString())
              : null,
    );
  }

  // Solo campos planos para inserción/actualización
  Map<String, dynamic> toInsert() => {
    'title': title,
    'cover_url': coverUrl,
    'summary': summary,
    'published_at': publishedAt?.toIso8601String(),
  }..removeWhere((k, v) => v == null);

  Map<String, dynamic> toUpdate() => toInsert();

  Book copyWith({
    String? id,
    String? title,
    List<Author>? authors,
    List<Category>? categories,
    String? coverUrl,
    String? summary,
    DateTime? publishedAt,
  }) => Book(
    id: id ?? this.id,
    title: title ?? this.title,
    authors: authors ?? this.authors,
    categories: categories ?? this.categories,
    coverUrl: coverUrl ?? this.coverUrl,
    summary: summary ?? this.summary,
    publishedAt: publishedAt ?? this.publishedAt,
  );
}
