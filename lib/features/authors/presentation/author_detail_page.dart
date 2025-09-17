import 'package:flutter/material.dart';
import '../../../data/models/author.dart';
import '../../../data/models/book.dart';
import '../../../data/repositories/authors_repository.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../books/presentation/book_detail_page.dart';
import '../widgets/author_books_grid.dart';
import '../widgets/author_stats_card.dart';

class AuthorDetailPage extends StatefulWidget {
  final Author author;

  const AuthorDetailPage({super.key, required this.author});

  @override
  State<AuthorDetailPage> createState() => _AuthorDetailPageState();
}

class _AuthorDetailPageState extends State<AuthorDetailPage> {
  late final AuthorsRepository _authorsRepository;
  List<Book> _authorBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authorsRepository = AuthorsRepository(SupabaseInit.client);
    _loadAuthorBooks();
  }

  Future<void> _loadAuthorBooks() async {
    try {
      final books = await _authorsRepository.getBooksByAuthor(widget.author.id);
      if (mounted) {
        setState(() {
          _authorBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // AppBar con la imagen de fondo del autor
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'author-${widget.author.id}',
                    child: Container(
                      margin: const EdgeInsets.only(top: 60),
                      child: _buildAuthorAvatar(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Contenido principal
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del autor
                    Text(
                      widget.author.name,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Información adicional del autor
                    _buildAuthorInfo(),
                    const SizedBox(height: 24),

                    // Estadísticas del autor
                    AuthorStatsCard(
                      totalBooks: _authorBooks.length,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 24),

                    // Biografía
                    if (widget.author.bio?.isNotEmpty == true) ...[
                      _buildSectionTitle('Biografía'),
                      const SizedBox(height: 12),
                      Text(
                        widget.author.bio!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Libros del autor
                    if (_authorBooks.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Libros'),
                          Text(
                            '${_authorBooks.length} libro${_authorBooks.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AuthorBooksGrid(
                        books: _authorBooks,
                        onBookTap: (book) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookDetailPage(book: book),
                            ),
                          );
                        },
                      ),
                    ] else if (!_isLoading) ...[
                      _buildSectionTitle('Libros'),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay libros disponibles',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_isLoading) ...[
                      _buildSectionTitle('Libros'),
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],

                    // Espacio final
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorAvatar() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child:
            widget.author.photoUrl?.isNotEmpty == true
                ? Image.network(
                  widget.author.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                )
                : _buildPlaceholderAvatar(),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.author.name.isNotEmpty
              ? widget.author.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAuthorInfo() {
    final infoItems = <Widget>[];

    // Fecha de nacimiento
    if (widget.author.birthDate != null) {
      final age = DateTime.now().year - widget.author.birthDate!.year;
      infoItems.add(_buildInfoChip(Icons.cake_outlined, '$age años'));
    }

    // Nacionalidad - removido ya que no está en el modelo
    // Si quisiéramos agregarlo, necesitaríamos extender el modelo Author

    // Sitio web
    if (widget.author.website?.isNotEmpty == true) {
      infoItems.add(_buildInfoChip(Icons.language_outlined, 'Sitio web'));
    }

    // Cantidad de libros
    if (!_isLoading) {
      infoItems.add(
        _buildInfoChip(
          Icons.menu_book_outlined,
          '${_authorBooks.length} libro${_authorBooks.length != 1 ? 's' : ''}',
        ),
      );
    }

    if (infoItems.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 12, runSpacing: 8, children: infoItems);
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
