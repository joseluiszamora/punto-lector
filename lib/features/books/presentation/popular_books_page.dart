import 'package:flutter/material.dart';
import 'package:puntolector/core/supabase/supabase_client_provider.dart';
import 'package:puntolector/data/models/book.dart';
import 'package:puntolector/data/repositories/books_repository.dart';
import 'package:puntolector/features/books/presentation/book_detail_page.dart';

class PopularBooksPage extends StatefulWidget {
  final List<Book> initial;
  const PopularBooksPage({super.key, required this.initial});

  @override
  State<PopularBooksPage> createState() => _PopularBooksPageState();
}

class _PopularBooksPageState extends State<PopularBooksPage> {
  List<Book> _books = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _books = widget.initial;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final repo = BooksRepository(SupabaseInit.client);
      final res = await repo.popularBooks(
        window: '30d',
        mode: 'trending',
        limit: 60,
      );
      if (mounted) setState(() => _books = res);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Libros populares')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3 / 5,
                  ),
                  itemCount: _books.length,
                  itemBuilder: (c, i) {
                    final b = _books[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BookDetailPage(book: b),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Hero(
                              tag: 'book-${b.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    (b.coverUrl != null &&
                                            b.coverUrl!.isNotEmpty)
                                        ? Image.network(
                                          b.coverUrl!,
                                          fit: BoxFit.cover,
                                        )
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
                          const SizedBox(height: 6),
                          Text(
                            b.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            b.authorsLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
