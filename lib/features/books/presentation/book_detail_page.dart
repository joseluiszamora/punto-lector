import 'package:flutter/material.dart';
import '../../../data/models/book.dart';

class BookDetailPage extends StatelessWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // AppBar con la imagen de fondo
          SliverAppBar(
            expandedHeight: 300,
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
                    colors: [Colors.grey[300]!, Colors.grey[100]!],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'book-${book.id}',
                    child: Container(
                      margin: const EdgeInsets.only(top: 60),
                      child: _buildBookCover(),
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
                    // Título del libro
                    Text(
                      book.title,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Autores
                    if (book.authors.isNotEmpty) ...[
                      Text(
                        'Por ${book.authorsLabel}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Información adicional
                    _buildInfoRow(),

                    const SizedBox(height: 24),

                    // Resumen corto
                    if (book.summary?.isNotEmpty == true) ...[
                      _buildSectionTitle('Sinopsis'),
                      const SizedBox(height: 12),
                      Text(
                        book.summary!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Reseña completa
                    if (book.review?.isNotEmpty == true) ...[
                      _buildSectionTitle('Reseña completa'),
                      const SizedBox(height: 12),
                      Text(
                        book.review!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Detalles adicionales
                    _buildDetailsSection(context),

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

  Widget _buildBookCover() {
    return Container(
      width: 180,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child:
            book.coverUrl?.isNotEmpty == true
                ? Image.network(
                  book.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
                )
                : _buildPlaceholderCover(),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[300]!, Colors.blue[600]!],
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, size: 60, color: Colors.white),
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

  Widget _buildInfoRow() {
    final infoItems = <Widget>[];

    // Fecha de publicación
    if (book.publishedAt != null) {
      infoItems.add(
        _buildInfoChip(
          Icons.calendar_today_outlined,
          book.publishedAt!.year.toString(),
        ),
      );
    }

    // Categorías
    if (book.categories.isNotEmpty) {
      final categoriesText = book.categories
          .take(2)
          .map((c) => c.name)
          .join(', ');
      infoItems.add(_buildInfoChip(Icons.category_outlined, categoriesText));
    }

    // ISBN
    if (book.isbn?.isNotEmpty == true) {
      infoItems.add(_buildInfoChip(Icons.numbers_outlined, 'ISBN'));
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

  Widget _buildDetailsSection(BuildContext context) {
    final details = <Widget>[];

    // ISBN completo
    if (book.isbn?.isNotEmpty == true) {
      details.add(_buildDetailItem('ISBN', book.isbn!));
    }

    // Idioma
    if (book.language?.isNotEmpty == true) {
      details.add(_buildDetailItem('Idioma', book.language!));
    }

    // Autores (lista completa)
    if (book.authors.isNotEmpty) {
      final authorsText = book.authors.map((a) => a.name).join('\n');
      details.add(
        _buildDetailItem(
          book.authors.length > 1 ? 'Autores' : 'Autor',
          authorsText,
        ),
      );
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Detalles'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
