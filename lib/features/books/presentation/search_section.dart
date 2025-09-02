import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/books_bloc.dart';
import '../../../data/models/book.dart';

class BookSearchSection extends StatefulWidget {
  const BookSearchSection({super.key});

  @override
  State<BookSearchSection> createState() => _BookSearchSectionState();
}

class _BookSearchSectionState extends State<BookSearchSection> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          TextField(
            controller: _authorCtrl,
            decoration: const InputDecoration(labelText: 'Autor'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed:
                () => context.read<BooksBloc>().add(
                  BooksSearchRequested(
                    title: _titleCtrl.text,
                    author: _authorCtrl.text,
                  ),
                ),
            child: const Text('Buscar'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<BooksBloc, BooksState>(
              builder: (context, state) {
                return switch (state) {
                  BooksLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  BooksLoaded(:final books) => _ResultsList(books: books),
                  BooksError(:final message) => Center(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<Book> books;
  const _ResultsList({required this.books});
  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const Text('Sin resultados');
    return ListView.separated(
      itemCount: books.length,
      itemBuilder: (_, i) {
        final b = books[i];
        return ListTile(
          leading:
              b.coverUrl != null
                  ? Builder(
                    builder: (context) {
                      final dpr = MediaQuery.of(context).devicePixelRatio;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          b.coverUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          cacheHeight: (48 * dpr).round(),
                          filterQuality: FilterQuality.low,
                          errorBuilder:
                              (_, __, ___) => const Icon(Icons.menu_book),
                        ),
                      );
                    },
                  )
                  : const Icon(Icons.menu_book),
          title: Text(b.title),
          subtitle: Text(b.authorsLabel),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }
}
