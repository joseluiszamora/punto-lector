import 'package:flutter/material.dart';
import 'package:puntolector/core/supabase/supabase_client_provider.dart';
import 'package:puntolector/data/models/book.dart';
import 'package:puntolector/data/models/category.dart';
import 'package:puntolector/data/repositories/categories_repository.dart';
import 'package:puntolector/features/books/presentation/book_card_small.dart';

class CategoryDetailPage extends StatefulWidget {
  final Category category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  late final CategoriesRepository _categoriesRepo;
  List<Category> _subcategories = [];
  List<Book> _categoryBooks = [];
  bool _loadingSubcategories = true;
  bool _loadingBooks = true;

  @override
  void initState() {
    super.initState();
    _categoriesRepo = CategoriesRepository(SupabaseInit.client);
    _loadSubcategories();
    _loadCategoryBooks();
  }

  Future<void> _loadSubcategories() async {
    setState(() => _loadingSubcategories = true);
    try {
      final data = await _categoriesRepo.getCategoriesByLevel(
        level: widget.category.level + 1,
        parentId: widget.category.id,
      );
      if (mounted) {
        setState(() {
          _subcategories = data;
        });
      }
    } catch (e) {
      print('Error loading subcategories: $e');
    } finally {
      if (mounted) setState(() => _loadingSubcategories = false);
    }
  }

  Future<void> _loadCategoryBooks() async {
    setState(() => _loadingBooks = true);
    try {
      // Buscar libros que pertenecen a esta categoría
      final res = await SupabaseInit.client
          .from('books')
          .select('''
            *,
            books_authors(authors(*)),
            book_categories!inner(
              categories(*)
            )
          ''')
          .eq('book_categories.category_id', widget.category.id)
          .limit(50);

      final List raw = (res as List);
      final data =
          raw.map((e) => Book.fromMap(Map<String, dynamic>.from(e))).toList();

      if (mounted) {
        setState(() {
          _categoryBooks = data;
        });
      }
    } catch (e) {
      print('Error loading category books: $e');
    } finally {
      if (mounted) setState(() => _loadingBooks = false);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadSubcategories(), _loadCategoryBooks()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // Header con información de la categoría
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            _getCategoryIcon(),
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.category.description?.isNotEmpty ==
                                  true)
                                Text(
                                  widget.category.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Subcategorías (si existen)
            if (_subcategories.isNotEmpty || _loadingSubcategories) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Subcategorías',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child:
                    _loadingSubcategories
                        ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : SizedBox(
                          height: 45,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: _subcategories.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final subcategory = _subcategories[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CategoryDetailPage(
                                            category: subcategory,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor().withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getCategoryColor(),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getCategoryIcon(),
                                        size: 16,
                                        color: _getCategoryColor(),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        subcategory.name,
                                        style: TextStyle(
                                          color: _getCategoryColor(),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ],

            // Libros de la categoría
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Libros (${_categoryBooks.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),

            _loadingBooks
                ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
                : _categoryBooks.isEmpty
                ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay libros en esta categoría',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final book = _categoryBooks[index];
                      return BookCardSmall(
                        book: book,
                        heroTagSuffix: 'category-detail-${widget.category.id}',
                      );
                    }, childCount: _categoryBooks.length),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    if (widget.category.color?.isNotEmpty == true) {
      try {
        String colorString = widget.category.color!.replaceAll('#', '');
        if (colorString.length == 6) {
          colorString = 'FF$colorString';
        }
        return Color(int.parse(colorString, radix: 16));
      } catch (_) {}
    }
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.red,
      Colors.amber,
    ];
    return colors[widget.category.name.hashCode % colors.length];
  }

  IconData _getCategoryIcon() {
    final name = widget.category.name.toLowerCase();
    if (name.contains('historia') || name.contains('históric')) {
      return Icons.history_edu;
    } else if (name.contains('ciencia') || name.contains('científic')) {
      return Icons.science;
    } else if (name.contains('arte') || name.contains('cultura')) {
      return Icons.palette;
    } else if (name.contains('educación') || name.contains('educativ')) {
      return Icons.school;
    } else if (name.contains('ficción') || name.contains('novela')) {
      return Icons.auto_stories;
    } else if (name.contains('biografía') || name.contains('biografic')) {
      return Icons.person;
    } else if (name.contains('cocina') || name.contains('receta')) {
      return Icons.restaurant;
    } else if (name.contains('salud') || name.contains('medicina')) {
      return Icons.favorite;
    } else if (name.contains('tecnología') || name.contains('técnic')) {
      return Icons.computer;
    } else if (name.contains('religion') || name.contains('espiritual')) {
      return Icons.auto_awesome;
    }
    return Icons.category;
  }
}
