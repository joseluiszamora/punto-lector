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
  final _city = TextEditingController(text: 'La Paz');

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final ownerUid = auth is Authenticated ? auth.user.id : '';
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva tienda')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Ciudad'),
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
                  final store = Store(
                    id: 'new',
                    ownerUid: ownerUid,
                    name: _name.text,
                    city: _city.text,
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
