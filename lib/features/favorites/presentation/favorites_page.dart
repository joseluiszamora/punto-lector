import 'package:flutter/material.dart';
import 'package:puntolector/core/supabase/supabase_client_provider.dart';
import 'package:puntolector/data/repositories/favorites_repository.dart';
import 'package:puntolector/data/models/book.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:puntolector/features/books/presentation/book_detail_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseInit.client.auth.currentUser?.id;
    final repo = FavoritesRepository(SupabaseInit.client);
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body:
          userId == null
              ? const Center(
                child: Text('Inicia sesión para ver tus favoritos'),
              )
              : _FavoritesList(userId: userId, repo: repo),
    );
  }
}

class _FavoritesList extends StatefulWidget {
  final String userId;
  final FavoritesRepository repo;
  const _FavoritesList({required this.userId, required this.repo});

  @override
  State<_FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<_FavoritesList> {
  late Future<List<Book>> _future;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.listUserFavoriteBooks(widget.userId);
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final client = SupabaseInit.client;
    _channel =
        client
            .channel('public:favorites:user_${widget.userId}')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'favorites',
              filter: PostgresChangeFilter(
                column: 'user_id',
                type: PostgresChangeFilterType.eq,
                value: widget.userId,
              ),
              callback: (payload) {
                _refresh();
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.delete,
              schema: 'public',
              table: 'favorites',
              filter: PostgresChangeFilter(
                column: 'user_id',
                type: PostgresChangeFilterType.eq,
                value: widget.userId,
              ),
              callback: (payload) {
                _refresh();
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'favorites',
              filter: PostgresChangeFilter(
                column: 'user_id',
                type: PostgresChangeFilterType.eq,
                value: widget.userId,
              ),
              callback: (payload) {
                _refresh();
              },
            )
            .subscribe();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repo.listUserFavoriteBooks(widget.userId);
    });
    await _future;
  }

  Future<void> _remove(String bookId) async {
    await widget.repo.removeByBook(widget.userId, bookId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Book>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error al cargar favoritos: ${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final items = snap.data ?? const <Book>[];
          if (items.isEmpty) {
            return const Center(child: Text('Aún no tienes libros favoritos'));
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final b = items[i];
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BookDetailPage(book: b),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.favorite),
                  color: Colors.red,
                  tooltip: 'Quitar de favoritos',
                  onPressed: () => _remove(b.id),
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
