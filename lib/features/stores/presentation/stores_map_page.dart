import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/stores_bloc.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../data/repositories/stores_repository.dart';
import '../../maps/map_page.dart';
import '../../../data/models/store.dart';
import 'widgets/store_info.dart';

class StoresMapPage extends StatefulWidget {
  const StoresMapPage({super.key});

  @override
  State<StoresMapPage> createState() => _StoresMapPageState();
}

class _StoresMapPageState extends State<StoresMapPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => StoresBloc(
            StoresRepository(SupabaseInit.client),
            ownerUid: '', // listar todas las tiendas activas
          )..add(const StoresRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Tiendas en el mapa')),
        body: BlocBuilder<StoresBloc, StoresState>(
          builder: (context, state) {
            if (state is StoresLoading || state is StoresInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is StoresError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error al cargar tiendas: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }
            final List<Store> stores =
                state is StoresLoaded ? state.stores : const <Store>[];
            return MapPage(
              stores: stores,
              onStoreTap: (s) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: false,
                  builder:
                      (_) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: BlocProvider.value(
                          value: context.read<StoresBloc>(),
                          child: StoreInfo(store: s),
                        ),
                      ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
