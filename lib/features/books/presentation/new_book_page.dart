import 'package:flutter/material.dart';
import '../../../data/models/book.dart';
import '../../../data/repositories/books_repository.dart';
import '../../../core/supabase/supabase_client_provider.dart';
// Nuevos imports para subir imagen
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;

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
  final _summary = TextEditingController();
  DateTime? _publishedAt;
  bool _saving = false;
  // Estado de subida de imagen
  bool _uploading = false;
  String? _uploadError;
  String? _previewUrl;

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
      initialDate: DateTime(now.year, now.month, now.day),
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
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (x == null) return;
      setState(() {
        _uploading = true;
        _uploadError = null;
      });
      final bytes = await x.readAsBytes();
      // Detectar MIME confiable
      final detectedMime =
          mime.lookupMimeType(x.path, headerBytes: bytes) ??
          mime.lookupMimeType(x.name, headerBytes: bytes) ??
          'image/jpeg';
      // Determinar extensión por MIME o por nombre
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
          // Si el nombre tiene extensión conocida, úsala
          final nameExt = p.extension(x.name).toLowerCase().replaceAll('.', '');
          ext =
              ['jpg', 'jpeg', 'png', 'webp'].contains(nameExt)
                  ? (nameExt == 'jpeg' ? 'jpg' : nameExt)
                  : 'jpg';
          break;
      }
      final contentType = detectedMime;
      final objectPath =
          'covers/${DateTime.now().millisecondsSinceEpoch}_${_rand(6)}.$ext';

      // Verificar sesión (storage requiere auth para escribir)
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

      // Preferir URL firmada (funciona aunque el bucket no sea público)
      String signedUrl;
      try {
        signedUrl = await SupabaseInit.client.storage
            .from('book_covers')
            .createSignedUrl(objectPath, 60 * 60 * 24 * 365); // 1 año
      } catch (_) {
        // Fallback a URL pública si el bucket es público
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
      final repo = BooksRepository(SupabaseInit.client);
      final temp = Book(
        id: 'new',
        title: _title.text.trim(),
        author: _author.text.trim(),
        coverUrl: _previewUrl,
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
                if (_previewUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _previewUrl!,
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
