import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/books_repository.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../data/models/book.dart';
import '../../../books/application/books_bloc.dart';
import '../../../books/presentation/new_book_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;
import 'package:image_cropper/image_cropper.dart';

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

  // Helper para miniatura de portada segura
  Widget _coverThumb(String? url) {
    final u = url?.trim();
    final valid =
        u != null &&
        u.isNotEmpty &&
        (u.startsWith('http://') || u.startsWith('https://'));
    if (!valid) return const Icon(Icons.menu_book_outlined);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        u,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stack) => const Icon(Icons.menu_book_outlined),
      ),
    );
  }

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
      MaterialPageRoute(
        builder:
            (_) => BlocProvider.value(
              value: context.read<BooksBloc>(),
              child: _EditBookPage(book: book),
            ),
      ),
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
                  key: ValueKey(b.id),
                  leading: _coverThumb(b.coverUrl),
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
  late final TextEditingController _summary;
  DateTime? _publishedAt;
  bool _saving = false;

  String? _previewUrl; // nueva portada subida
  bool _uploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.book.title);
    _author = TextEditingController(text: widget.book.author);
    _summary = TextEditingController(text: widget.book.summary ?? '');
    _publishedAt = widget.book.publishedAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
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

  String _rand(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> _pickAndUpload() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar portada',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Recortar portada'),
        ],
      );
      if (cropped == null) return;

      setState(() {
        _uploading = true;
        _uploadError = null;
      });

      final bytes = await XFile(cropped.path).readAsBytes();
      final detectedMime =
          mime.lookupMimeType(cropped.path, headerBytes: bytes) ?? 'image/jpeg';
      String ext;
      switch (detectedMime) {
        case 'image/png':
          ext = 'png';
          break;
        case 'image/webp':
          ext = 'webp';
          break;
        case 'image/jpeg':
        case 'image/jpg':
        default:
          final nameExt = p
              .extension(cropped.path)
              .toLowerCase()
              .replaceAll('.', '');
          ext =
              ['jpg', 'jpeg', 'png', 'webp'].contains(nameExt)
                  ? (nameExt == 'jpeg' ? 'jpg' : nameExt)
                  : 'jpg';
          break;
      }
      final contentType = detectedMime;
      final objectPath =
          'covers/${DateTime.now().millisecondsSinceEpoch}_${_rand(6)}.$ext';

      final user = SupabaseInit.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión para subir archivos.');
      }

      await SupabaseInit.client.storage
          .from('book_covers')
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      String signedUrl;
      try {
        signedUrl = await SupabaseInit.client.storage
            .from('book_covers')
            .createSignedUrl(objectPath, 60 * 60 * 24 * 365);
      } catch (_) {
        signedUrl = SupabaseInit.client.storage
            .from('book_covers')
            .getPublicUrl(objectPath);
      }

      setState(() {
        _previewUrl = signedUrl;
      });
    } catch (e) {
      setState(() => _uploadError = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir portada: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // Determinar portada efectiva: prioriza la nueva subida, si no, la existente válida
      String? effectiveCover;
      if (_previewUrl != null && _previewUrl!.trim().isNotEmpty) {
        effectiveCover = _previewUrl;
      } else {
        final existing = widget.book.coverUrl?.trim();
        effectiveCover =
            (existing == null || existing.isEmpty) ? null : existing;
      }

      final updated = widget.book.copyWith(
        title: _title.text.trim(),
        author: _author.text.trim(),
        coverUrl: effectiveCover,
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
                // Botón de subida de portada (sin campo URL)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickAndUpload,
                    icon:
                        _uploading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Subir portada'),
                  ),
                ),
                if ((_previewUrl ?? widget.book.coverUrl) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        (_previewUrl ?? widget.book.coverUrl)!,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (_uploadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _uploadError!,
                      style: const TextStyle(color: Colors.red),
                    ),
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
