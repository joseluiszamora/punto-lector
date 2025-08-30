import 'package:flutter/material.dart';
import '../../../data/models/book.dart';
import '../../../data/repositories/books_repository.dart';
import '../../../core/supabase/supabase_client_provider.dart';

class NewBookPage extends StatefulWidget {
  final void Function(Book created)? onCreated;
  const NewBookPage({super.key, this.onCreated});

  @override
  State<NewBookPage> createState() => _NewBookPageState();
}

class _NewBookPageState extends State<NewBookPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _coverUrl = TextEditingController();
  final _summary = TextEditingController();
  DateTime? _publishedAt;
  bool _saving = false;

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
      initialDate: DateTime(now.year, now.month, now.day),
      firstDate: DateTime(1800),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _publishedAt = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = BooksRepository(SupabaseInit.client);
      final temp = Book(
        id: 'new',
        title: _title.text.trim(),
        author: _author.text.trim(),
        coverUrl: _coverUrl.text.trim().isEmpty ? null : _coverUrl.text.trim(),
        summary: _summary.text.trim().isEmpty ? null : _summary.text.trim(),
        publishedAt: _publishedAt,
      );
      final created = await repo.create(temp);
      widget.onCreated?.call(created);
      if (mounted) Navigator.pop(context, created);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo libro')),
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
                  label: const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
