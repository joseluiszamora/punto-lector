import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puntolector/core/supabase/supabase_client_provider.dart';
import 'package:puntolector/data/repositories/favorites_repository.dart';
import '../application/books_bloc.dart';
import '../../../data/models/book.dart';
import 'book_details_sheet.dart';

class BookSearchSection extends StatefulWidget {
  const BookSearchSection({super.key});

  @override
  State<BookSearchSection> createState() => _BookSearchSectionState();
}

class _BookSearchSectionState extends State<BookSearchSection>
    with AutomaticKeepAliveClientMixin {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();

  Timer? _debounce;
  final _debounceDuration = const Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_onQueryChanged);
    _authorCtrl.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      context.read<BooksBloc>().add(
        BooksSearchRequested(title: _titleCtrl.text, author: _authorCtrl.text),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Título',
              suffixIcon:
                  _titleCtrl.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _titleCtrl.clear();
                          _onQueryChanged();
                        },
                      )
                      : null,
            ),
          ),
          TextField(
            controller: _authorCtrl,
            decoration: InputDecoration(
              labelText: 'Autor',
              suffixIcon:
                  _authorCtrl.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _authorCtrl.clear();
                          _onQueryChanged();
                        },
                      )
                      : null,
            ),
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
    final userId = SupabaseInit.client.auth.currentUser?.id;
    final favRepo = FavoritesRepository(SupabaseInit.client);
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
          onTap: () => showBookDetailsSheet(context, b),
          subtitle: Text(b.authorsLabel),
          trailing:
              userId == null
                  ? null
                  : _FavoriteButton(
                    bookId: b.id,
                    repository: favRepo,
                    userId: userId,
                  ),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final String userId;
  final String bookId;
  final FavoritesRepository repository;
  const _FavoriteButton({
    required this.userId,
    required this.bookId,
    required this.repository,
  });

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool? _isFav; // null = cargando
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await widget.repository.isFavorited(
        widget.userId,
        widget.bookId,
      );
      if (mounted) setState(() => _isFav = v);
    } catch (_) {
      if (mounted) setState(() => _isFav = false);
    }
  }

  Future<void> _toggle() async {
    if (_busy || _isFav == null) return;
    setState(() => _busy = true);
    try {
      if (_isFav == true) {
        await widget.repository.removeByBook(widget.userId, widget.bookId);
        if (mounted) setState(() => _isFav = false);
      } else {
        await widget.repository.add(widget.userId, widget.bookId);
        if (mounted) setState(() => _isFav = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar favorito: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFav == null) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return IconButton(
      icon: Icon(_isFav! ? Icons.favorite : Icons.favorite_border),
      color: _isFav! ? Colors.red : null,
      onPressed: _toggle,
      tooltip: _isFav! ? 'Quitar de favoritos' : 'Agregar a favoritos',
    );
  }
}
