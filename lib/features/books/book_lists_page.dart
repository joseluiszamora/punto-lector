import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/models/book.dart';
import '../auth/state/auth_bloc.dart';
import '../../data/models/author.dart';
import '../../data/repositories/authors_repository.dart';
import '../../data/repositories/books_repository.dart';
import 'presentation/book_detail_page.dart';

class BookListsPage extends StatefulWidget {
  const BookListsPage({super.key});

  @override
  State<BookListsPage> createState() => _BookListsPageState();
}

class _BookListsPageState extends State<BookListsPage> {
  late final FavoritesRepository _favoritesRepo;
  List<Book> _allFavorites = const [];
  bool _loading = true;
  // Autores populares
  late final AuthorsRepository _authorsRepo;
  List<Author> _popularAuthors = const [];
  bool _loadingAuthors = true;
  // Libros populares
  late final BooksRepository _booksRepo;
  List<Book> _popularBooks = const [];
  bool _loadingPopularBooks = true;

  @override
  void initState() {
    super.initState();
    _favoritesRepo = FavoritesRepository(SupabaseInit.client);
    _authorsRepo = AuthorsRepository(SupabaseInit.client);
    _booksRepo = BooksRepository(SupabaseInit.client);
    _load();
    _loadAuthors();
    _loadPopularBooks();
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

  Future<void> _loadAuthors() async {
    setState(() => _loadingAuthors = true);
    try {
      final data = await _authorsRepo.listAll(limit: 20);
      if (mounted) setState(() => _popularAuthors = data);
    } catch (_) {
      if (mounted) setState(() => _popularAuthors = const []);
    } finally {
      if (mounted) setState(() => _loadingAuthors = false);
    }
  }

  Future<void> _loadPopularBooks() async {
    setState(() => _loadingPopularBooks = true);
    try {
      final data = await _booksRepo.popularBooks(
        window: '7d',
        mode: 'trending',
        limit: 12,
      );
      if (mounted) setState(() => _popularBooks = data);
    } catch (_) {
      if (mounted) setState(() => _popularBooks = const []);
    } finally {
      if (mounted) setState(() => _loadingPopularBooks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _load();
        await _loadAuthors();
        await _loadPopularBooks();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Sección: Autores populares
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Autores populares',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed:
                      _popularAuthors.isEmpty
                          ? null
                          : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => AuthorsAllPage(
                                      initial: _popularAuthors,
                                      repo: _authorsRepo,
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
            height: 110,
            child:
                _loadingAuthors
                    ? const Center(child: CircularProgressIndicator())
                    : (_popularAuthors.isEmpty
                        ? const Center(child: Text('Sin autores para mostrar'))
                        : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final a = _popularAuthors[index];
                            return _AuthorCircle(author: a);
                          },
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemCount:
                              _popularAuthors.length > 12
                                  ? 12
                                  : _popularAuthors.length,
                        )),
          ),
          const SizedBox(height: 16),
          // Sección: Libros populares
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Libros populares',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed:
                      _popularBooks.isEmpty
                          ? null
                          : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => PopularBooksAllPage(
                                      initial: _popularBooks,
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
                _loadingPopularBooks
                    ? const Center(child: CircularProgressIndicator())
                    : (_popularBooks.isEmpty
                        ? const Center(child: Text('Sin datos todavía'))
                        : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              _popularBooks.length > 12
                                  ? 12
                                  : _popularBooks.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemBuilder:
                              (context, i) =>
                                  _BookCardSmall(book: _popularBooks[i]),
                        )),
          ),
          const SizedBox(height: 16),
          // Sección: Mis favoritos
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

class _AuthorCircle extends StatelessWidget {
  final Author author;
  const _AuthorCircle({required this.author});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(
              width: 56,
              height: 56,
              child:
                  (author.photoUrl != null && author.photoUrl!.isNotEmpty)
                      ? Image.network(
                        author.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.person_outline),
                            ),
                      )
                      : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.person_outline),
                      ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            author.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
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

class AuthorsAllPage extends StatefulWidget {
  final List<Author> initial;
  final AuthorsRepository repo;
  const AuthorsAllPage({super.key, required this.initial, required this.repo});

  @override
  State<AuthorsAllPage> createState() => _AuthorsAllPageState();
}

class _AuthorsAllPageState extends State<AuthorsAllPage> {
  List<Author> _authors = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _authors = widget.initial;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final res = await widget.repo.listAll(limit: 500);
      if (mounted) setState(() => _authors = res);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autores')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: _authors.length,
                  itemBuilder: (context, index) {
                    final a = _authors[index];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child:
                                (a.photoUrl != null && a.photoUrl!.isNotEmpty)
                                    ? Image.network(
                                      a.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.person_outline,
                                            ),
                                          ),
                                    )
                                    : Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.person_outline),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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

class PopularBooksAllPage extends StatefulWidget {
  final List<Book> initial;
  const PopularBooksAllPage({super.key, required this.initial});

  @override
  State<PopularBooksAllPage> createState() => _PopularBooksAllPageState();
}

class _PopularBooksAllPageState extends State<PopularBooksAllPage> {
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
