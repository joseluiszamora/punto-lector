import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puntolector/core/supabase/supabase_client_provider.dart';
import 'package:puntolector/data/models/author.dart';
import 'package:puntolector/data/models/book.dart';
import 'package:puntolector/data/repositories/authors_repository.dart';
import 'package:puntolector/data/repositories/books_repository.dart';
import 'package:puntolector/data/repositories/favorites_repository.dart';
import 'package:puntolector/features/auth/state/auth_bloc.dart';
import 'package:puntolector/features/authors/presentation/authors_list_page.dart';
import 'package:puntolector/features/authors/widgets/author_circle.dart';
import 'package:puntolector/features/books/presentation/book_card_small.dart';
import 'package:puntolector/features/books/presentation/favorites_books_page.dart';
import 'package:puntolector/features/books/presentation/popular_books_page.dart';
import 'package:puntolector/features/books/widgets/empty_favorites.dart';
import 'package:puntolector/features/categories/widgets/category_hierarchy_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Autores populares
  late final AuthorsRepository _authorsRepo;
  List<Author> _popularAuthors = const [];
  bool _loadingAuthors = true;
  // Libros populares
  late final BooksRepository _booksRepo;
  List<Book> _popularBooks = const [];
  bool _loadingPopularBooks = true;
  // Mis favoritos
  late final FavoritesRepository _favoritesRepo;
  List<Book> _allFavorites = const [];
  bool _loadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _favoritesRepo = FavoritesRepository(SupabaseInit.client);
    _authorsRepo = AuthorsRepository(SupabaseInit.client);
    _booksRepo = BooksRepository(SupabaseInit.client);
    _loadFavorites();
    _loadAuthors();
    _loadPopularBooks();
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

  Future<void> _loadFavorites() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! Authenticated) {
      setState(() {
        _allFavorites = const [];
        _loadingFavorites = false;
      });
      return;
    }
    try {
      final data = await _favoritesRepo.listUserFavoriteBooks(auth.user.id);
      if (mounted) setState(() => _allFavorites = data);
    } finally {
      if (mounted) setState(() => _loadingFavorites = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Punto Lector')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadFavorites();
          await _loadAuthors();
          await _loadPopularBooks();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            //* Sección: Autores populares
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Autores populares',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _popularAuthors.isEmpty
                            ? null
                            : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AuthorsListPage(),
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
                          ? const Center(
                            child: Text('Sin autores para mostrar'),
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final a = _popularAuthors[index];
                              return AuthorCircle(author: a);
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

            //* Sección: Categorias
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Categorías',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),

            //* Sección: Libros populares
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Libros populares',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
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
                                      (_) => PopularBooksPage(
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
                                    BookCardSmall(book: _popularBooks[i]),
                          )),
            ),
            const SizedBox(height: 16),

            //* Sección: Mis favoritos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mis favoritos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
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
                                      (_) => FavoritesBooksPage(
                                        initial: _allFavorites,
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
                  _loadingFavorites
                      ? const Center(child: CircularProgressIndicator())
                      : (_allFavorites.isEmpty
                          ? const EmptyFavorites()
                          : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final book = _allFavorites[index];
                              return BookCardSmall(book: book);
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
      ),
    );
  }
}
