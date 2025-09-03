import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../data/models/store.dart';
import '../../../admin/presentation/stores/store_location_picker_page.dart'
    show StorePickedLocation, StoreLocationPickerPage; // reuse picker

class StoreFormResult {
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
  const StoreFormResult({
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

class StoreForm extends StatefulWidget {
  final Store? initial;
  final void Function(StoreFormResult) onSubmit;
  final String submitLabel;
  final bool showCancel;
  const StoreForm({
    super.key,
    this.initial,
    required this.onSubmit,
    this.submitLabel = 'Guardar',
    this.showCancel = true,
  });

  @override
  State<StoreForm> createState() => _StoreFormState();
}

class _StoreFormState extends State<StoreForm> {
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

  String _ownerUid() => SupabaseInit.client.auth.currentUser?.id ?? '';
  String _rand(int len) {
    const c = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(len, (_) => c[r.nextInt(c.length)]).join();
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
      }
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
            fileOptions: FileOptions(contentType: detectedMime, upsert: true),
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
    return Form(
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
                    if (picked != null && mounted) {
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
                        label: Text(_uploading ? 'Subiendo...' : 'Subir foto'),
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
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.showCancel)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    final ownerUid = _ownerUid();
                    if (ownerUid.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debes iniciar sesión')),
                      );
                      return;
                    }
                    final res = StoreFormResult(
                      id: widget.initial?.id,
                      ownerUid: ownerUid,
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
                          _city.text.trim().isEmpty ? null : _city.text.trim(),
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
                    );
                    widget.onSubmit(res);
                  },
                  child: Text(widget.submitLabel),
                ),
              ],
            ),
          ],
        ),
      ),
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
