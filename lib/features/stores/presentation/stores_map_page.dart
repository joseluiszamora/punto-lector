import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/state/auth_bloc.dart';
import '../application/stores_bloc.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../data/repositories/stores_repository.dart';
import '../../../core/config/env.dart';
import '../../../data/models/store.dart';

class StoresMapPage extends StatefulWidget {
  const StoresMapPage({super.key});

  @override
  State<StoresMapPage> createState() => _StoresMapPageState();
}

class _StoresMapPageState extends State<StoresMapPage> {
  MapboxMap? _map;
  PointAnnotationManager? _pointMgr;

  static const _laPazLat = -16.4897;
  static const _laPazLng = -68.1193;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(Env.mapboxAccessToken);
  }

  Future<void> _initMap(MapboxMap controller) async {
    _map = controller;
    await _map!.style.setStyleURI(MapboxStyles.MAPBOX_STREETS);
    _pointMgr = await _map!.annotations.createPointAnnotationManager();
    await _map!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(_laPazLng, _laPazLat)),
        zoom: 12.0,
      ),
      MapAnimationOptions(duration: 500),
    );
  }

  Future<void> _renderStores(List<Store> stores) async {
    if (_pointMgr == null) return;
    await _pointMgr!.deleteAll();
    final options =
        stores
            .where((s) => s.lat != null && s.lng != null)
            .map(
              (s) => PointAnnotationOptions(
                geometry: Point(coordinates: Position(s.lng!, s.lat!)),
                iconImage: 'shop-15',
                textField: s.name,
                textOffset: [0.0, -1.2],
              ),
            )
            .toList();
    if (options.isNotEmpty) {
      await _pointMgr!.createMulti(options);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final ownerUid = auth is Authenticated ? auth.user.id : '';
    return BlocProvider(
      create:
          (_) => StoresBloc(
            StoresRepository(SupabaseInit.client),
            ownerUid: ownerUid,
          )..add(const StoresRequested()),
      child: Builder(
        builder:
            (innerCtx) => Scaffold(
              appBar: AppBar(title: const Text('Tiendas en el mapa')),
              body: BlocConsumer<StoresBloc, StoresState>(
                listener: (context, state) async {
                  if (state is StoresLoaded) {
                    await _renderStores(state.stores);
                  }
                },
                builder: (context, state) {
                  return Stack(
                    children: [
                      MapWidget(
                        key: const ValueKey('mapbox'),
                        onMapCreated: (controller) async {
                          await _initMap(controller);
                          final st = context.read<StoresBloc>().state;
                          if (st is StoresLoaded) {
                            await _renderStores(st.stores);
                          }
                        },
                      ),
                      if (state is StoresLoading)
                        const Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: LinearProgressIndicator(),
                            ),
                          ),
                        ),
                      if (state is StoresError)
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Error al cargar tiendas: ${state.message}',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
      ),
    );
  }
}
