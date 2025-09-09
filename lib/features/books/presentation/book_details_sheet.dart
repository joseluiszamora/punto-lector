import 'package:flutter/material.dart';
import 'package:puntolector/core/supabase/supabase_client_provider.dart';

import '../../../data/models/book.dart';

Future<T?> showBookDetailsSheet<T>(BuildContext context, Book book) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => _BookDetailsSheet(book: book),
  );
}

class _BookDetailsSheet extends StatefulWidget {
  final Book book;
  const _BookDetailsSheet({required this.book});

  @override
  State<_BookDetailsSheet> createState() => _BookDetailsSheetState();
}

class _BookDetailsSheetState extends State<_BookDetailsSheet> {
  @override
  void initState() {
    super.initState();
    // Log de vista del libro (ignorar errores silenciosamente)
    // Se ejecuta una sola vez cuando se abre la hoja.
    Future.microtask(() async {
      try {
        await SupabaseInit.client.rpc(
          'log_book_view',
          params: {'p_book_id': widget.book.id},
        );
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final book = widget.book;
    final categories = book.categories.map((c) => c.name).join(', ');
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Cover(url: book.coverUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: textTheme.titleLarge,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 6),
                        Text(book.authorsLabel, style: textTheme.bodyMedium),
                        if (categories.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(categories, style: textTheme.bodySmall),
                        ],
                        if (book.publishedAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Publicado: ${book.publishedAt!.toLocal().toIso8601String().substring(0, 10)}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if ((book.summary ?? '').trim().isNotEmpty) ...[
                Text('Descripción', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(book.summary!.trim(), style: textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  final String? url;
  const _Cover({this.url});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final size = 110.0;
    if (url == null) {
      return Container(
        width: size,
        height: size * 1.4,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Icon(Icons.menu_book, size: 32),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: size,
        height: size * 1.4,
        fit: BoxFit.cover,
        cacheHeight: (size * 1.4 * dpr).round(),
        filterQuality: FilterQuality.low,
        errorBuilder:
            (_, __, ___) => Container(
              width: size,
              height: size * 1.4,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image),
            ),
      ),
    );
  }
}
