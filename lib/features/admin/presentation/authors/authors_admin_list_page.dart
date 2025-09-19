import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../data/models/author.dart';
import '../../../../data/repositories/authors_repository.dart';

class AuthorsAdminListPage extends StatelessWidget {
  const AuthorsAdminListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => _AuthorsCubit(AuthorsRepository(SupabaseInit.client))..load(),
      child: const _AuthorsView(),
    );
  }
}

class _AuthorsCubit extends Cubit<_AuthorsState> {
  final IAuthorsRepository repo;
  List<Author> _itemsCache = [];
  List<Author> get items => _itemsCache;

  _AuthorsCubit(this.repo) : super(const _AuthorsState.loading());

  Future<void> load() async {
    emit(const _AuthorsState.loading());
    try {
      final items = await repo.listAll();
      _itemsCache = items;
      emit(_AuthorsState.loaded(items));
    } catch (e) {
      emit(_AuthorsState.error(e.toString()));
    }
  }

  Future<void> create({
    required String name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? nationalityId,
  }) async {
    emit(const _AuthorsState.operating());
    try {
      await repo.create(
        name: name,
        bio: bio,
        birthDate: birthDate,
        deathDate: deathDate,
        photoUrl: photoUrl,
        nationalityId: nationalityId,
      );
      emit(const _AuthorsState.operationSuccess());
      await load();
    } catch (e) {
      emit(_AuthorsState.error(e.toString()));
    }
  }

  Future<void> update(
    String id, {
    required String name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? nationalityId,
  }) async {
    emit(const _AuthorsState.operating());
    try {
      await repo.update(
        id,
        name: name,
        bio: bio,
        birthDate: birthDate,
        deathDate: deathDate,
        photoUrl: photoUrl,
        nationalityId: nationalityId,
      );
      emit(const _AuthorsState.operationSuccess());
      await load();
    } catch (e) {
      emit(_AuthorsState.error(e.toString()));
    }
  }

  Future<void> remove(String id) async {
    emit(const _AuthorsState.operating());
    try {
      await repo.delete(id);
      emit(const _AuthorsState.operationSuccess());
      await load();
    } catch (e) {
      emit(_AuthorsState.error(e.toString()));
    }
  }
}

sealed class _AuthorsState {
  const _AuthorsState();
  const factory _AuthorsState.loading() = _Loading;
  const factory _AuthorsState.loaded(List<Author> items) = _Loaded;
  const factory _AuthorsState.error(String message) = _Error;
  const factory _AuthorsState.operating() = _Operating;
  const factory _AuthorsState.operationSuccess() = _OperationSuccess;
}

class _Loading extends _AuthorsState {
  const _Loading();
}

class _Operating extends _AuthorsState {
  const _Operating();
}

class _OperationSuccess extends _AuthorsState {
  const _OperationSuccess();
}

class _Error extends _AuthorsState {
  final String message;
  const _Error(this.message);
}

class _Loaded extends _AuthorsState {
  final List<Author> items;
  const _Loaded(this.items);
}

class _AuthorsView extends StatelessWidget {
  const _AuthorsView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Autores'),
        actions: [
          IconButton(
            onPressed: () => context.read<_AuthorsCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: BlocConsumer<_AuthorsCubit, _AuthorsState>(
        listener: (context, state) {
          if (state is _Error) {
            final msg = state.message.replaceFirst('Exception: ', '');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $msg')));
          } else if (state is _OperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Operación exitosa')));
          }
        },
        builder: (context, state) {
          Widget buildList(List<Author> items) {
            if (items.isEmpty) return const Center(child: Text('Sin autores'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final a = items[i];
                final subtitle = [
                  if ((a.birthDate != null) || (a.deathDate != null))
                    _formatLifespan(a.birthDate, a.deathDate),
                ].where((e) => e.isNotEmpty).join(' • ');
                return ListTile(
                  leading:
                      (a.photoUrl != null && a.photoUrl!.isNotEmpty)
                          ? ClipOval(
                            child: Image.network(
                              a.photoUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.low,
                              cacheHeight: 80,
                              loadingBuilder:
                                  (c, child, p) =>
                                      p == null
                                          ? child
                                          : const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                              errorBuilder:
                                  (c, e, s) => const CircleAvatar(
                                    child: Icon(Icons.person_outline),
                                  ),
                            ),
                          )
                          : const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                  title: Text(a.name),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(ctx, author: a),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(ctx, a),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          if (state is _Loaded) return buildList(state.items);
          if (state is _Loading)
            return const Center(child: CircularProgressIndicator());
          if (state is _Operating || state is _OperationSuccess) {
            final cached = context.read<_AuthorsCubit>().items;
            return buildList(cached);
          }
          if (state is _Error) {
            final msg = state.message.replaceFirst('Exception: ', '');
            return Center(
              child: Text(msg, style: const TextStyle(color: Colors.red)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatLifespan(DateTime? birth, DateTime? death) {
    String fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
    final b = birth != null ? fmt(birth) : '';
    final d = death != null ? fmt(death) : '';
    if (b.isEmpty && d.isEmpty) return '';
    if (b.isNotEmpty && d.isNotEmpty) return '$b – $d';
    return b.isNotEmpty ? '$b –' : '– $d';
  }

  Future<void> _openForm(BuildContext context, {Author? author}) async {
    final result = await showDialog<_AuthorFormResult>(
      context: context,
      builder:
          (ctx) => _AuthorDialog(
            initialName: author?.name,
            initialBio: author?.bio,
            initialBirth: author?.birthDate,
            initialDeath: author?.deathDate,
            initialPhotoUrl: author?.photoUrl,
            initialNationalityId: author?.nationalityId,
          ),
    );
    if (result == null) return;
    final cubit = context.read<_AuthorsCubit>();
    if (author == null) {
      await cubit.create(
        name: result.name,
        bio: result.bio,
        birthDate: result.birthDate,
        deathDate: result.deathDate,
        photoUrl: result.photoUrl,
        nationalityId: result.nationalityId,
      );
    } else {
      await cubit.update(
        author.id,
        name: result.name,
        bio: result.bio,
        birthDate: result.birthDate,
        deathDate: result.deathDate,
        photoUrl: result.photoUrl,
        nationalityId: result.nationalityId,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Author a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar autor'),
            content: Text('¿Deseas eliminar "${a.name}"?'),
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
    if (ok == true) {
      await context.read<_AuthorsCubit>().remove(a.id);
    }
  }
}

class _AuthorFormResult {
  final String name;
  final String? bio;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? photoUrl;
  final String? nationalityId;
  _AuthorFormResult({
    required this.name,
    this.bio,
    this.birthDate,
    this.deathDate,
    this.photoUrl,
    this.nationalityId,
  });
}

class _AuthorDialog extends StatefulWidget {
  final String? initialName;
  final String? initialBio;
  final DateTime? initialBirth;
  final DateTime? initialDeath;
  final String? initialPhotoUrl;
  final String? initialNationalityId;
  const _AuthorDialog({
    this.initialName,
    this.initialBio,
    this.initialBirth,
    this.initialDeath,
    this.initialPhotoUrl,
    this.initialNationalityId,
  });
  @override
  State<_AuthorDialog> createState() => _AuthorDialogState();
}

class _AuthorDialogState extends State<_AuthorDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  String? _photoUrl;
  bool _uploading = false;
  String? _uploadError;
  DateTime? _birthDate;
  DateTime? _deathDate;

  // nacionalidades
  List<Map<String, dynamic>> _nationalities = [];
  String? _nationalityId;
  bool _loadingNats = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
    _bio = TextEditingController(text: widget.initialBio ?? '');
    _photoUrl = widget.initialPhotoUrl;
    _birthDate = widget.initialBirth;
    _deathDate = widget.initialDeath;
    _nationalityId = widget.initialNationalityId;
    _loadNationalities();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _loadNationalities() async {
    setState(() => _loadingNats = true);
    try {
      final res = await SupabaseInit.client
          .from('nationalities')
          .select('id, name')
          .order('name');
      final list =
          (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() {
        _nationalities = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nationalities = [];
      });
    } finally {
      if (mounted) setState(() => _loadingNats = false);
    }
  }

  String _rand(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // Nuevo: elegir origen (galería o cámara) y luego subir
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

  // Reemplaza al anterior _pickAndUpload, parametrizado por origen
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
            toolbarTitle: 'Recortar foto',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Recortar foto'),
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
          'photos/${DateTime.now().millisecondsSinceEpoch}_${_rand(6)}.$ext';

      final user = SupabaseInit.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión para subir archivos.');
      }

      await SupabaseInit.client.storage
          .from('author_photos')
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      String url;
      try {
        url = await SupabaseInit.client.storage
            .from('author_photos')
            .createSignedUrl(objectPath, 60 * 60 * 24 * 365);
      } catch (_) {
        url = SupabaseInit.client.storage
            .from('author_photos')
            .getPublicUrl(objectPath);
      }

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadError = e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir foto: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickDate({required bool isBirth}) async {
    final now = DateTime.now();
    final initial =
        (isBirth ? _birthDate : _deathDate) ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1800),
      lastDate: DateTime(now.year + 1),
      helpText: isBirth ? 'Fecha de nacimiento' : 'Fecha de fallecimiento',
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else {
          _deathDate = picked;
        }
      });
    }
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'Nuevo autor' : 'Editar autor'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator:
                    (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bio,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Nacimiento',
                        hintText: 'yyyy-mm-dd',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.date_range),
                          onPressed: () => _pickDate(isBirth: true),
                        ),
                      ),
                      controller: TextEditingController(
                        text: _fmtDate(_birthDate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Fallecimiento',
                        hintText: 'yyyy-mm-dd',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.date_range),
                          onPressed: () => _pickDate(isBirth: false),
                        ),
                      ),
                      controller: TextEditingController(
                        text: _fmtDate(_deathDate),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Nacionalidad',
                      ),
                      child:
                          _loadingNats
                              ? const LinearProgressIndicator(minHeight: 2)
                              : DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  isExpanded: true,
                                  value: _nationalityId,
                                  hint: const Text('Selecciona...'),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Sin especificar'),
                                    ),
                                    ..._nationalities.map(
                                      (n) => DropdownMenuItem(
                                        value: n['id'] as String,
                                        child: Text(n['name'] as String),
                                      ),
                                    ),
                                  ],
                                  onChanged:
                                      (v) => setState(() {
                                        _nationalityId = v;
                                      }),
                                ),
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PhotoThumb(url: _photoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _uploading ? null : _chooseSourceAndUpload,
                          icon:
                              _uploading
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            _uploading ? 'Subiendo...' : 'Subir foto',
                          ),
                        ),
                        if (_uploadError != null)
                          Text(
                            _uploadError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              _uploading
                  ? null
                  : () {
                    if (!_form.currentState!.validate()) return;
                    Navigator.pop(
                      context,
                      _AuthorFormResult(
                        name: _name.text.trim(),
                        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
                        birthDate: _birthDate,
                        deathDate: _deathDate,
                        photoUrl: _photoUrl,
                        nationalityId: _nationalityId,
                      ),
                    );
                  },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String? url;
  const _PhotoThumb({this.url});
  @override
  Widget build(BuildContext context) {
    final has = (url != null && url!.isNotEmpty);
    return ClipOval(
      child:
          has
              ? Image.network(
                url!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                cacheHeight: 112,
                filterQuality: FilterQuality.low,
                loadingBuilder:
                    (c, child, p) =>
                        p == null
                            ? child
                            : const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                errorBuilder:
                    (c, e, s) => const SizedBox(
                      width: 56,
                      height: 56,
                      child: CircleAvatar(child: Icon(Icons.person_outline)),
                    ),
              )
              : const SizedBox(
                width: 56,
                height: 56,
                child: CircleAvatar(child: Icon(Icons.person_outline)),
              ),
    );
  }
}
