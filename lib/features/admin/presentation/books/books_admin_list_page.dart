import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/books_repository.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../data/models/book.dart';
import '../../../books/application/books_bloc.dart';
import '../../../books/presentation/new_book_page.dart';

class BooksAdminListPage extends StatelessWidget {
  const BooksAdminListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              BooksBloc(BooksRepository(SupabaseInit.client))
                ..add(const BooksAdminListRequested()),
      child: const _BooksAdminView(),
    );
  }
}

class _BooksAdminView extends StatelessWidget {
  const _BooksAdminView();

  void _openNew(BuildContext context) async {
    final created = await Navigator.push<Book>(
      context,
      MaterialPageRoute(builder: (_) => const NewBookPage()),
    );
    if (created != null && context.mounted) {
      context.read<BooksBloc>().add(const BooksAdminListRequested());
    }
  }

  void _openEdit(BuildContext context, Book book) async {
    final edited = await Navigator.push<Book>(
      context,
      MaterialPageRoute(builder: (_) => _EditBookPage(book: book)),
    );
    if (edited != null && context.mounted) {
      context.read<BooksBloc>().add(const BooksAdminListRequested());
    }
  }

  void _confirmDelete(BuildContext context, Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar libro'),
            content: Text('¿Seguro que deseas eliminar "${book.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (ok == true && context.mounted) {
      context.read<BooksBloc>().add(BookDeleteRequested(book.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Libros'),
        actions: [
          IconButton(
            onPressed:
                () => context.read<BooksBloc>().add(
                  const BooksAdminListRequested(),
                ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNew(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: BlocConsumer<BooksBloc, BooksState>(
        listener: (context, state) {
          if (state is BooksError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          } else if (state is BooksOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Operación exitosa')));
          }
        },
        builder: (context, state) {
          if (state is BooksLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BooksLoaded) {
            final books = state.books;
            if (books.isEmpty) {
              return const Center(child: Text('Sin libros'));
            }
            return ListView.separated(
              itemCount: books.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final b = books[i];
                return ListTile(
                  leading:
                      b.coverUrl != null
                          ? Image.network(
                            b.coverUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.menu_book_outlined),
                  title: Text(b.title),
                  subtitle: Text(b.author),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openEdit(context, b),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, b),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          if (state is BooksError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _EditBookPage extends StatefulWidget {
  final Book book;
  const _EditBookPage({required this.book});

  @override
  State<_EditBookPage> createState() => _EditBookPageState();
}

class _EditBookPageState extends State<_EditBookPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _coverUrl;
  late final TextEditingController _summary;
  DateTime? _publishedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.book.title);
    _author = TextEditingController(text: widget.book.author);
    _coverUrl = TextEditingController(text: widget.book.coverUrl ?? '');
    _summary = TextEditingController(text: widget.book.summary ?? '');
    _publishedAt = widget.book.publishedAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _coverUrl.dispose();
    _summary.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _publishedAt ?? now,
      firstDate: DateTime(1800),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _publishedAt = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = widget.book.copyWith(
        title: _title.text.trim(),
        author: _author.text.trim(),
        coverUrl: _coverUrl.text.trim().isEmpty ? null : _coverUrl.text.trim(),
        summary: _summary.text.trim().isEmpty ? null : _summary.text.trim(),
        publishedAt: _publishedAt,
      );
      context.read<BooksBloc>().add(
        BookUpdateRequested(widget.book.id, updated),
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar libro')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator:
                      (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _author,
                  decoration: const InputDecoration(labelText: 'Autor'),
                  validator:
                      (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _coverUrl,
                  decoration: const InputDecoration(labelText: 'Portada (URL)'),
                  keyboardType: TextInputType.url,
                ),
                TextFormField(
                  controller: _summary,
                  decoration: const InputDecoration(labelText: 'Resumen'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _publishedAt == null
                            ? 'Sin fecha'
                            : 'Publicado: ${_publishedAt!.toIso8601String().split('T').first}',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.date_range),
                      label: const Text('Fecha'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _save,
                  icon:
                      _saving
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.check),
                  label: const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
