class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? summary;
  final DateTime? publishedAt;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.summary,
    this.publishedAt,
  });

  factory Book.fromMap(Map<String, dynamic> map) => Book(
    id: map['id'] as String,
    title: map['title'] as String,
    author: map['author'] as String,
    coverUrl: map['cover_url'] as String?,
    summary: map['summary'] as String?,
    publishedAt:
        map['published_at'] != null
            ? DateTime.tryParse(map['published_at'].toString())
            : null,
  );
}
