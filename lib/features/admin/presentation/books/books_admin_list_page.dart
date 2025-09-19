import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../data/models/book.dart';
import '../../../../data/models/author.dart';
import '../../../../data/models/category.dart';
import '../../../../data/repositories/books_repository.dart';
import '../../../../data/repositories/catalog_repository.dart';
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
        loadingBuilder: (context, child, loading) {
          if (loading == null) return child;
          return const SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
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
                  subtitle: Text(b.authorsLabel),
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
  late final TextEditingController _summary;
  DateTime? _publishedAt;
  bool _saving = false;

  // Selección M:N
  final List<Author> _selectedAuthors = [];
  final List<Category> _selectedCategories = [];

  String? _previewUrl; // nueva portada subida
  bool _uploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.book.title);
    _summary = TextEditingController(text: widget.book.summary ?? '');
    _publishedAt = widget.book.publishedAt;
    _selectedAuthors.addAll(widget.book.authors);
    _selectedCategories.addAll(widget.book.categories);
  }

  @override
  void dispose() {
    _title.dispose();
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

  // Nuevo: selector de origen (galería o cámara)
  Future<void> _chooseSourceAndUpload() async {
    if (_uploading) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Seleccionar de la galería'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tomar una foto'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ],
            ),
          ),
    );
    if (source != null && mounted) {
      await _pickAndUploadFrom(source);
    }
  }

  // Extraído: flujo de selección + recorte + subida parametrizado por origen
  Future<void> _pickAndUploadFrom(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
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

  Future<void> _pickAuthors() async {
    final repo = CatalogRepository(SupabaseInit.client);
    final result = await _openMultiPicker<Author>(
      context: context,
      title: 'Seleccionar autores',
      loader: (q) => repo.listAuthors(query: q),
      itemLabel: (a) => a.name,
      initiallySelected: _selectedAuthors.map((a) => a.id).toSet(),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedAuthors
          ..clear()
          ..addAll(result.items);
      });
    }
  }

  Future<void> _pickCategories() async {
    final repo = CatalogRepository(SupabaseInit.client);
    final result = await _openMultiPicker<Category>(
      context: context,
      title: 'Seleccionar categorías',
      loader: (q) => repo.listCategories(query: q),
      itemLabel: (c) => c.name,
      initiallySelected: _selectedCategories.map((c) => c.id).toSet(),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedCategories
          ..clear()
          ..addAll(result.items);
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
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
        authors: List.of(_selectedAuthors),
        categories: List.of(_selectedCategories),
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
                // Autores
                Wrap(
                  spacing: 8,
                  runSpacing: -8,
                  children:
                      _selectedAuthors.isEmpty
                          ? [const Chip(label: Text('Sin autor disponible'))]
                          : _selectedAuthors
                              .map((a) => Chip(label: Text(a.name)))
                              .toList(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickAuthors,
                    icon: const Icon(Icons.person_search_outlined),
                    label: const Text('Seleccionar autores'),
                  ),
                ),
                const SizedBox(height: 8),
                // Categorías
                Wrap(
                  spacing: 8,
                  runSpacing: -8,
                  children:
                      _selectedCategories.isEmpty
                          ? []
                          : _selectedCategories
                              .map((c) => Chip(label: Text(c.name)))
                              .toList(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickCategories,
                    icon: const Icon(Icons.category_outlined),
                    label: const Text('Seleccionar categorías'),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : _chooseSourceAndUpload,
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
                      child: Builder(
                        builder: (context) {
                          final dpr = MediaQuery.of(context).devicePixelRatio;
                          return Image.network(
                            (_previewUrl ?? widget.book.coverUrl)!,
                            height: 160,
                            fit: BoxFit.cover,
                            cacheHeight: (160 * dpr).round(),
                            filterQuality: FilterQuality.low,
                            loadingBuilder: (ctx, child, loading) {
                              if (loading == null) return child;
                              return SizedBox(
                                height: 160,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder:
                                (ctx, error, stack) => Container(
                                  height: 160,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                          );
                        },
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

class _MultiPickResult<T> {
  final List<T> items;
  _MultiPickResult(this.items);
}

Future<_MultiPickResult<T>?> _openMultiPicker<T>({
  required BuildContext context,
  required String title,
  required Future<List<T>> Function(String? query) loader,
  required String Function(T) itemLabel,
  required Set<String> initiallySelected,
}) async {
  return showModalBottomSheet<_MultiPickResult<T>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return _MultiPickerSheet<T>(
        title: title,
        loader: loader,
        itemLabel: itemLabel,
        initiallySelected: initiallySelected,
      );
    },
  );
}

class _MultiPickerSheet<T> extends StatefulWidget {
  final String title;
  final Future<List<T>> Function(String? query) loader;
  final String Function(T) itemLabel;
  final Set<String> initiallySelected;
  const _MultiPickerSheet({
    required this.title,
    required this.loader,
    required this.itemLabel,
    required this.initiallySelected,
  });

  @override
  State<_MultiPickerSheet<T>> createState() => _MultiPickerSheetState<T>();
}

class _MultiPickerSheetState<T> extends State<_MultiPickerSheet<T>> {
  final _queryCtrl = TextEditingController();
  List<T> _items = const [];
  final Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initiallySelected);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await widget.loader(
      _queryCtrl.text.isEmpty ? null : _queryCtrl.text,
    );
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _queryCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _load,
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    final id = (item as dynamic).id as String;
                    final label = widget.itemLabel(item);
                    final checked = _selected.contains(id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        });
                      },
                      title: Text(label),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final selectedItems =
                        _items
                            .where(
                              (e) => _selected.contains(
                                (e as dynamic).id as String,
                              ),
                            )
                            .toList();
                    Navigator.pop(context, _MultiPickResult<T>(selectedItems));
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
