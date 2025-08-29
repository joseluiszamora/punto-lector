import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/state/auth_bloc.dart';
import '../application/stores_bloc.dart';
import '../../../data/models/store.dart';

class StoreFormPage extends StatefulWidget {
  const StoreFormPage({super.key});

  @override
  State<StoreFormPage> createState() => _StoreFormPageState();
}

class _StoreFormPageState extends State<StoreFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _managerName = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'La Paz');
  final _phone = TextEditingController();
  final _description = TextEditingController();
  final _photoUrl = TextEditingController();
  final _openHourCtrl = TextEditingController();
  final _closeHourCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final Set<int> _openDays = {1, 2, 3, 4, 5}; // 1=Lun .. 7=Dom
  bool _active = true;

  @override
  void dispose() {
    _name.dispose();
    _managerName.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    _description.dispose();
    _photoUrl.dispose();
    _openHourCtrl.dispose();
    _closeHourCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      controller.text = '$hh:$mm';
    }
  }

  Widget _buildDayChips() {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = _openDays.contains(day);
        return FilterChip(
          label: Text(labels[i]),
          selected: selected,
          onSelected: (v) {
            setState(() {
              if (v) {
                _openDays.add(day);
              } else {
                _openDays.remove(day);
              }
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final ownerUid = auth is Authenticated ? auth.user.id : '';
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva tienda')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _managerName,
                decoration: const InputDecoration(labelText: 'Encargado'),
              ),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Ciudad'),
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              const Text('Días de apertura'),
              _buildDayChips(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openHourCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Hora apertura (HH:mm) ',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () => _pickTime(_openHourCtrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _closeHourCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Hora cierre (HH:mm) ',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () => _pickTime(_closeHourCtrl),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      decoration: const InputDecoration(labelText: 'Latitud'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngCtrl,
                      decoration: const InputDecoration(labelText: 'Longitud'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _photoUrl,
                decoration: const InputDecoration(labelText: 'Foto (URL)'),
                keyboardType: TextInputType.url,
              ),
              SwitchListTile(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Activa'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  if (ownerUid.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Debes iniciar sesión para crear una tienda',
                        ),
                      ),
                    );
                    return;
                  }

                  double? parseDouble(String s) {
                    if (s.trim().isEmpty) return null;
                    return double.tryParse(s.replaceAll(',', '.'));
                  }

                  final store = Store(
                    id: 'new',
                    ownerUid: ownerUid,
                    name: _name.text.trim(),
                    managerName:
                        _managerName.text.trim().isEmpty
                            ? null
                            : _managerName.text.trim(),
                    address:
                        _address.text.trim().isEmpty
                            ? null
                            : _address.text.trim(),
                    city: _city.text.trim().isEmpty ? null : _city.text.trim(),
                    openDays: _openDays.toList()..sort(),
                    openHour:
                        _openHourCtrl.text.trim().isEmpty
                            ? null
                            : _openHourCtrl.text.trim(),
                    closeHour:
                        _closeHourCtrl.text.trim().isEmpty
                            ? null
                            : _closeHourCtrl.text.trim(),
                    lat: parseDouble(_latCtrl.text),
                    lng: parseDouble(_lngCtrl.text),
                    phone:
                        _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                    description:
                        _description.text.trim().isEmpty
                            ? null
                            : _description.text.trim(),
                    photoUrl:
                        _photoUrl.text.trim().isEmpty
                            ? null
                            : _photoUrl.text.trim(),
                    active: _active,
                  );
                  context.read<StoresBloc>().add(StoreCreateRequested(store));
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
