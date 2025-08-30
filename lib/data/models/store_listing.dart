import 'book.dart';

class StoreListing {
  final String id;
  final String storeId;
  final String bookId;
  final Book book;
  final double price;
  final String currency;
  final int stock;
  final bool active;

  const StoreListing({
    required this.id,
    required this.storeId,
    required this.bookId,
    required this.book,
    required this.price,
    required this.currency,
    required this.stock,
    required this.active,
  });

  factory StoreListing.fromMap(Map<String, dynamic> map) {
    final bookMap = Map<String, dynamic>.from(map['book'] as Map);
    return StoreListing(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      bookId: map['book_id'] as String,
      book: Book.fromMap(bookMap),
      price: (map['price'] as num).toDouble(),
      currency: (map['currency'] as String?) ?? 'BOB',
      stock: (map['stock'] as int?) ?? 0,
      active: (map['active'] as bool?) ?? true,
    );
  }
}
