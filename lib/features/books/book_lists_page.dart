import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/models/book.dart';
import '../auth/state/auth_bloc.dart';

class BookListsPage extends StatefulWidget {
  const BookListsPage({super.key});

  @override
  State<BookListsPage> createState() => _BookListsPageState();
}

class _BookListsPageState extends State<BookListsPage> {
  late final FavoritesRepository _favoritesRepo;
  List<Book> _allFavorites = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _favoritesRepo = FavoritesRepository(SupabaseInit.client);
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! Authenticated) {
      setState(() {
        _allFavorites = const [];
        _loading = false;
      });
      return;
    }
    try {
      final data = await _favoritesRepo.listUserFavoriteBooks(auth.user.id);
      if (mounted) setState(() => _allFavorites = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mis favoritos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed:
                      _allFavorites.isEmpty
                          ? null
                          : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => FavoritesAllGridPage(
                                      initial: _allFavorites,
                                      repo: _favoritesRepo,
                                    ),
                              ),
                            );
                          },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 210,
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_allFavorites.isEmpty
                        ? const _EmptyFavorites()
                        : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final book = _allFavorites[index];
                            return _BookCardSmall(book: book);
                          },
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemCount:
                              _allFavorites.length > 5
                                  ? 5
                                  : _allFavorites.length,
                        )),
          ),
        ],
      ),
    );
  }
}

class _BookCardSmall extends StatelessWidget {
  final Book book;
  const _BookCardSmall({required this.book});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(book.coverUrl!, fit: BoxFit.cover)
                      : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.menu_book_outlined, size: 40),
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
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! Authenticated) {
      return const Center(child: Text('Inicia sesión para ver tus favoritos'));
    }
    return const Center(child: Text('Aún no tienes favoritos'));
  }
}

class FavoritesAllGridPage extends StatefulWidget {
  final List<Book> initial;
  final FavoritesRepository repo;
  const FavoritesAllGridPage({
    super.key,
    required this.initial,
    required this.repo,
  });

  @override
  State<FavoritesAllGridPage> createState() => _FavoritesAllGridPageState();
}

class _FavoritesAllGridPageState extends State<FavoritesAllGridPage> {
  List<Book> _books = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _books = widget.initial;
    _refresh();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! Authenticated) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await widget.repo.listUserFavoriteBooks(auth.user.id);
      if (mounted) setState(() => _books = res);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritos')),
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
                  itemBuilder: (context, index) {
                    final b = _books[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                b.coverUrl != null && b.coverUrl!.isNotEmpty
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
                    );
                  },
                ),
      ),
    );
  }
}
