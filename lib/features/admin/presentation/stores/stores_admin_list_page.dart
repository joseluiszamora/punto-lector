import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../data/models/store.dart';
import '../../../../data/repositories/stores_repository.dart';
import 'store_location_picker_page.dart';
// Nuevos imports para upload de imagen
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

class StoresAdminListPage extends StatelessWidget {
  const StoresAdminListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final user = SupabaseInit.client.auth.currentUser;
        final ownerUid = user?.id ?? '';
        return _StoresCubit(StoresRepository(SupabaseInit.client), ownerUid)
          ..load();
      },
      child: const _StoresView(),
    );
  }
}

class _StoresCubit extends Cubit<_StoresState> {
  final IStoresRepository repo;
  final String ownerUid;
  List<Store> _itemsCache = [];
  List<Store> get items => _itemsCache;

  _StoresCubit(this.repo, this.ownerUid) : super(const _StoresState.loading());

  Future<void> load() async {
    emit(const _StoresState.loading());
    try {
      final items = await repo.listMyStores(ownerUid);
      _itemsCache = items;
      emit(_StoresState.loaded(items));
    } catch (e) {
      emit(_StoresState.error(e.toString()));
    }
  }

  Future<void> create(Store store) async {
    emit(const _StoresState.operating());
    try {
      final created = await repo.create(store);
      _itemsCache = [created, ..._itemsCache];
      emit(const _StoresState.operationSuccess());
      emit(_StoresState.loaded(_itemsCache));
    } catch (e) {
      emit(_StoresState.error(e.toString()));
    }
  }

  Future<void> update(String id, Map<String, dynamic> patch) async {
    emit(const _StoresState.operating());
    try {
      final updated = await repo.update(id, patch);
      _itemsCache =
          _itemsCache.map((s) => s.id == updated.id ? updated : s).toList();
      emit(const _StoresState.operationSuccess());
      emit(_StoresState.loaded(_itemsCache));
    } catch (e) {
      emit(_StoresState.error(e.toString()));
    }
  }

  Future<void> remove(String id) async {
    emit(const _StoresState.operating());
    try {
      await repo.delete(id);
      _itemsCache = _itemsCache.where((s) => s.id != id).toList();
      emit(const _StoresState.operationSuccess());
      emit(_StoresState.loaded(_itemsCache));
    } catch (e) {
      emit(_StoresState.error(e.toString()));
    }
  }
}

sealed class _StoresState {
  const _StoresState();
  const factory _StoresState.loading() = _Loading;
  const factory _StoresState.loaded(List<Store> items) = _Loaded;
  const factory _StoresState.error(String message) = _Error;
  const factory _StoresState.operating() = _Operating;
  const factory _StoresState.operationSuccess() = _OperationSuccess;
}

class _Loading extends _StoresState {
  const _Loading();
}

class _Operating extends _StoresState {
  const _Operating();
}

class _OperationSuccess extends _StoresState {
  const _OperationSuccess();
}

class _Error extends _StoresState {
  final String message;
  const _Error(this.message);
}

class _Loaded extends _StoresState {
  final List<Store> items;
  const _Loaded(this.items);
}

class _StoresView extends StatelessWidget {
  const _StoresView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Tiendas'),
        actions: [
          IconButton(
            onPressed: () => context.read<_StoresCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nueva'),
      ),
      body: BlocConsumer<_StoresCubit, _StoresState>(
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
          Widget buildList(List<Store> items) {
            if (items.isEmpty) return const Center(child: Text('Sin tiendas'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final s = items[i];
                final subtitle = [
                  s.city,
                  s.address,
                ].where((e) => (e ?? '').isNotEmpty).join(' • ');
                return ListTile(
                  leading:
                      (s.photoUrl != null && s.photoUrl!.isNotEmpty)
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              s.photoUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              cacheHeight: 96,
                              filterQuality: FilterQuality.low,
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
                                  (c, e, s) => const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ColoredBox(
                                      color: Colors.black12,
                                      child: Icon(Icons.storefront_outlined),
                                    ),
                                  ),
                            ),
                          )
                          : const SizedBox(
                            width: 48,
                            height: 48,
                            child: ColoredBox(
                              color: Colors.black12,
                              child: Icon(Icons.storefront_outlined),
                            ),
                          ),
                  title: Text(s.name),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(ctx, store: s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(ctx, s),
                        tooltip: 'Eliminar',
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
            final cached = context.read<_StoresCubit>().items;
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

  Future<void> _openForm(BuildContext context, {Store? store}) async {
    final result = await showDialog<_StoreFormResult>(
      context: context,
      builder: (ctx) => _StoreDialog(initial: store),
    );
    if (result == null) return;
    final cubit = context.read<_StoresCubit>();
    if (store == null) {
      await cubit.create(result.toStore());
    } else {
      await cubit.update(store.id!, result.toPatch());
    }
  }

  Future<void> _confirmDelete(BuildContext context, Store s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar tienda'),
            content: Text('¿Deseas eliminar "${s.name}"?'),
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
      await context.read<_StoresCubit>().remove(s.id!);
    }
  }
}

class _StoreFormResult {
  final String? id;
  final String ownerUid;
  final String name;
  final String? managerName;
  final String? address;
  final String? city;
  final List<int> openDays;
  final String? openHour;
  final String? closeHour;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? description;
  final String? photoUrl;
  final bool active;
  const _StoreFormResult({
    this.id,
    required this.ownerUid,
    required this.name,
    this.managerName,
    this.address,
    this.city,
    this.openDays = const [1, 2, 3, 4, 5],
    this.openHour,
    this.closeHour,
    this.lat,
    this.lng,
    this.phone,
    this.description,
    this.photoUrl,
    this.active = true,
  });
  Store toStore() => Store(
    id: id,
    ownerUid: ownerUid,
    name: name,
    managerName: managerName,
    address: address,
    city: city,
    openDays: openDays,
    openHour: openHour,
    closeHour: closeHour,
    lat: lat,
    lng: lng,
    phone: phone,
    description: description,
    photoUrl: photoUrl,
    active: active,
  );
  Map<String, dynamic> toPatch() => {
    'name': name,
    'manager_name': managerName,
    'address': address,
    'city': city,
    'open_days': openDays,
    'open_hour': openHour,
    'close_hour': closeHour,
    'lat': lat,
    'lng': lng,
    'phone': phone,
    'description': description,
    'photo_url': photoUrl,
    'active': active,
  }..removeWhere((k, v) => v == null);
}

class _StoreDialog extends StatefulWidget {
  final Store? initial;
  const _StoreDialog({this.initial});
  @override
  State<_StoreDialog> createState() => _StoreDialogState();
}

class _StoreDialogState extends State<_StoreDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _manager;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _openHour;
  late final TextEditingController _closeHour;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _phone;
  late final TextEditingController _description;
  List<int> _openDays = const [1, 2, 3, 4, 5];
  bool _active = true;
  String? _photoUrl;
  bool _uploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s?.name ?? '');
    _manager = TextEditingController(text: s?.managerName ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _city = TextEditingController(text: s?.city ?? '');
    _openHour = TextEditingController(text: s?.openHour ?? '');
    _closeHour = TextEditingController(text: s?.closeHour ?? '');
    _lat = TextEditingController(text: s?.lat?.toString() ?? '');
    _lng = TextEditingController(text: s?.lng?.toString() ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _openDays = s?.openDays ?? const [1, 2, 3, 4, 5];
    _active = s?.active ?? true;
    _photoUrl = s?.photoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _manager.dispose();
    _address.dispose();
    _city.dispose();
    _openHour.dispose();
    _closeHour.dispose();
    _lat.dispose();
    _lng.dispose();
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  String _ownerUid() {
    final user = SupabaseInit.client.auth.currentUser;
    return user?.id ?? '';
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
            toolbarTitle: 'Recortar foto de tienda',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Recortar foto de tienda'),
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
          'stores/${DateTime.now().millisecondsSinceEpoch}_${_rand(6)}.$ext';

      final user = SupabaseInit.client.auth.currentUser;
      if (user == null) {
        throw Exception('Debes iniciar sesión para subir archivos.');
      }

      await SupabaseInit.client.storage
          .from('store_photos')
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      String url;
      try {
        url = await SupabaseInit.client.storage
            .from('store_photos')
            .createSignedUrl(objectPath, 60 * 60 * 24 * 365);
      } catch (_) {
        url = SupabaseInit.client.storage
            .from('store_photos')
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nueva tienda' : 'Editar tienda'),
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
                controller: _manager,
                decoration: const InputDecoration(labelText: 'Encargado'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Ciudad'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openHour,
                      decoration: const InputDecoration(
                        labelText: 'Apertura (HH:mm)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _closeHour,
                      decoration: const InputDecoration(
                        labelText: 'Cierre (HH:mm)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lat,
                      decoration: const InputDecoration(labelText: 'Lat'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lng,
                      decoration: const InputDecoration(labelText: 'Lng'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Elegir en mapa',
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () async {
                      final picked = await Navigator.push<StorePickedLocation>(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => StoreLocationPickerPage(
                                initialLat: double.tryParse(_lat.text.trim()),
                                initialLng: double.tryParse(_lng.text.trim()),
                              ),
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _lat.text = picked.lat.toStringAsFixed(6);
                          _lng.text = picked.lng.toStringAsFixed(6);
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              // Sección de foto
              Row(
                children: [
                  _StorePhotoThumb(url: _photoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _uploading ? null : _pickAndUpload,
                          icon: const Icon(Icons.photo_library_outlined),
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
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activa'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
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
                      _StoreFormResult(
                        id: widget.initial?.id,
                        ownerUid: _ownerUid(),
                        name: _name.text.trim(),
                        managerName:
                            _manager.text.trim().isEmpty
                                ? null
                                : _manager.text.trim(),
                        address:
                            _address.text.trim().isEmpty
                                ? null
                                : _address.text.trim(),
                        city:
                            _city.text.trim().isEmpty
                                ? null
                                : _city.text.trim(),
                        openDays: _openDays,
                        openHour:
                            _openHour.text.trim().isEmpty
                                ? null
                                : _openHour.text.trim(),
                        closeHour:
                            _closeHour.text.trim().isEmpty
                                ? null
                                : _closeHour.text.trim(),
                        lat: double.tryParse(_lat.text.trim()),
                        lng: double.tryParse(_lng.text.trim()),
                        phone:
                            _phone.text.trim().isEmpty
                                ? null
                                : _phone.text.trim(),
                        description:
                            _description.text.trim().isEmpty
                                ? null
                                : _description.text.trim(),
                        photoUrl: _photoUrl,
                        active: _active,
                      ),
                    );
                  },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _StorePhotoThumb extends StatelessWidget {
  final String? url;
  const _StorePhotoThumb({this.url});
  @override
  Widget build(BuildContext context) {
    final has = (url != null && url!.isNotEmpty);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
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
                      child: ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.storefront_outlined),
                      ),
                    ),
              )
              : const SizedBox(
                width: 56,
                height: 56,
                child: ColoredBox(
                  color: Colors.black12,
                  child: Icon(Icons.storefront_outlined),
                ),
              ),
    );
  }
}
