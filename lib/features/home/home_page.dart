import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puntolector/core/supabase/supabase_client_provider.dart';
import 'package:puntolector/data/models/author.dart';
import 'package:puntolector/data/models/book.dart';
import 'package:puntolector/data/models/category.dart';
import 'package:puntolector/data/repositories/authors_repository.dart';
import 'package:puntolector/data/repositories/books_repository.dart';
import 'package:puntolector/data/repositories/categories_repository.dart';
import 'package:puntolector/data/repositories/favorites_repository.dart';
import 'package:puntolector/features/auth/state/auth_bloc.dart';
import 'package:puntolector/features/authors/presentation/authors_list_page.dart';
import 'package:puntolector/features/authors/widgets/author_circle.dart';
import 'package:puntolector/features/books/presentation/book_card_small.dart';
import 'package:puntolector/features/books/presentation/favorites_books_page.dart';
import 'package:puntolector/features/books/presentation/popular_books_page.dart';
import 'package:puntolector/features/books/widgets/empty_favorites.dart';
import 'package:puntolector/features/categories/presentation/category_detail_page.dart';
import 'package:puntolector/features/categories/widgets/selectable_category_chip.dart';

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
  // Categorías principales
  late final CategoriesRepository _categoriesRepo;
  List<Category> _mainCategories = const [];
  bool _loadingCategories = true;
  // Libros por categoría
  Category? _selectedCategory;
  List<Book> _categoryBooks = const [];
  bool _loadingCategoryBooks = true;
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
    _categoriesRepo = CategoriesRepository(SupabaseInit.client);
    _loadFavorites();
    _loadAuthors();
    _loadPopularBooks();
    _loadMainCategories();
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

  Future<void> _loadMainCategories() async {
    setState(() => _loadingCategories = true);
    try {
      // Cargar solo las categorías de nivel 0 (principales)
      final data = await _categoriesRepo.getCategoriesByLevel(level: 0);
      if (mounted) {
        setState(() {
          _mainCategories = data;
          // Seleccionar la primera categoría por defecto
          if (data.isNotEmpty) {
            _selectedCategory = data.first;
          }
        });
        // Cargar libros de la primera categoría
        if (data.isNotEmpty) {
          _loadCategoryBooks(data.first);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _mainCategories = const []);
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadCategoryBooks(Category category) async {
    setState(() => _loadingCategoryBooks = true);
    try {
      // Buscar libros que tengan esta categoría usando una consulta con inner join
      final res = await SupabaseInit.client
          .from('books')
          .select('''
            *,
            books_authors(authors(*)),
            book_categories!inner(
              categories(*)
            )
          ''')
          .eq('book_categories.category_id', category.id)
          .limit(10);

      final List raw = (res as List);
      final data =
          raw.map((e) => Book.fromMap(Map<String, dynamic>.from(e))).toList();

      if (mounted) {
        setState(() {
          _categoryBooks = data;
          _selectedCategory = category;
        });
      }
    } catch (e) {
      print('Error loading category books: $e');
      if (mounted) setState(() => _categoryBooks = const []);
    } finally {
      if (mounted) setState(() => _loadingCategoryBooks = false);
    }
  }

  void _onCategorySelected(Category category) {
    if (_selectedCategory?.id != category.id) {
      _loadCategoryBooks(category);
    }
  }

  void _navigateToCategoryDetail(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailPage(category: category),
      ),
    );
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
          await _loadMainCategories();
          // Recargar libros de la categoría seleccionada si hay una
          if (_selectedCategory != null) {
            await _loadCategoryBooks(_selectedCategory!);
          }
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_selectedCategory != null)
                    TextButton(
                      onPressed:
                          () => _navigateToCategoryDetail(_selectedCategory!),
                      child: Text('Ver todos: ${_selectedCategory!.name}'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 45,
              child:
                  _loadingCategories
                      ? const Center(child: CircularProgressIndicator())
                      : (_mainCategories.isEmpty
                          ? const Center(
                            child: Text('Sin categorías para mostrar'),
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final category = _mainCategories[index];
                              return GestureDetector(
                                onTap: () => _onCategorySelected(category),
                                child: SelectableCategoryChip(
                                  category: category,
                                  isSelected:
                                      _selectedCategory?.id == category.id,
                                ),
                              );
                            },
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 8),
                            itemCount: _mainCategories.length,
                          )),
            ),
            const SizedBox(height: 8),
            // Libros de la categoría seleccionada
            SizedBox(
              height: 210,
              child:
                  _loadingCategoryBooks
                      ? const Center(child: CircularProgressIndicator())
                      : (_categoryBooks.isEmpty
                          ? Center(
                            child: Text(
                              _selectedCategory != null
                                  ? 'No hay libros en ${_selectedCategory!.name}'
                                  : 'Selecciona una categoría',
                            ),
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: _categoryBooks.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 12),
                            itemBuilder:
                                (context, i) => BookCardSmall(
                                  book: _categoryBooks[i],
                                  heroTagSuffix: 'category',
                                ),
                          )),
            ),
            const SizedBox(height: 16),

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
                                (context, i) => BookCardSmall(
                                  book: _popularBooks[i],
                                  heroTagSuffix: 'popular',
                                ),
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
                              return BookCardSmall(
                                book: book,
                                heroTagSuffix: 'favorites',
                              );
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
