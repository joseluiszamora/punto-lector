import 'package:flutter/material.dart';
import 'package:puntolector/data/models/book.dart';
import 'package:puntolector/features/books/presentation/book_detail_page.dart';

class BookCardSmall extends StatelessWidget {
  final Book book;
  const BookCardSmall({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => BookDetailPage(book: book)),
        );
      },
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'book-${book.id}',
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        book.coverUrl != null && book.coverUrl!.isNotEmpty
                            ? Image.network(book.coverUrl!, fit: BoxFit.cover)
                            : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.menu_book_outlined,
                                size: 40,
                              ),
                            ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              book.authorsLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
