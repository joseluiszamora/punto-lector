import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/stores_bloc.dart';
import 'widgets/store_form.dart';

class StoreFormPage extends StatelessWidget {
  const StoreFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva tienda')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StoreForm(
          showCancel: false,
          onSubmit: (res) {
            // Crear Store y despachar evento
            final store = res.toStore();
            context.read<StoresBloc>().add(StoreCreateRequested(store));
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
