import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/config/env.dart';

class StorePickedLocation {
  final double lat;
  final double lng;
  const StorePickedLocation(this.lat, this.lng);
}

class StoreLocationPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const StoreLocationPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<StoreLocationPickerPage> createState() =>
      _StoreLocationPickerPageState();
}

class _StoreLocationPickerPageState extends State<StoreLocationPickerPage> {
  MapboxMap? _map;
  static const _defaultLat = -16.4897; // La Paz
  static const _defaultLng = -68.1193;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(Env.mapboxAccessToken);
  }

  Future<void> _initMap(MapboxMap controller) async {
    _map = controller;
    await _map!.style.setStyleURI(MapboxStyles.MAPBOX_STREETS);
    final lat = widget.initialLat ?? _defaultLat;
    final lng = widget.initialLng ?? _defaultLng;
    await _map!.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 14.0),
      MapAnimationOptions(duration: 500),
    );
  }

  Future<void> _confirm() async {
    if (_map == null) return;
    final cam = await _map!.getCameraState();
    final pos = cam.center.coordinates;
    if (!mounted) return;
    Navigator.pop(
      context,
      StorePickedLocation(pos.lat.toDouble(), pos.lng.toDouble()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir ubicación')),
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapbox-picker'),
            onMapCreated: _initMap,
          ),
          // Retícula
          const IgnorePointer(
            ignoring: true,
            child: Center(
              child: Icon(Icons.place, size: 36, color: Colors.redAccent),
            ),
          ),
          // Fondo sutil para legibilidad de coordenadas
          Positioned(
            bottom: 90,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FutureBuilder<CameraState>(
                  future: _map?.getCameraState(),
                  builder: (context, snapshot) {
                    final lat = widget.initialLat ?? _defaultLat;
                    final lng = widget.initialLng ?? _defaultLng;
                    final pos = snapshot.data?.center.coordinates;
                    final dlat = pos?.lat ?? lat;
                    final dlng = pos?.lng ?? lng;
                    return Text(
                      'Lat: ${dlat.toStringAsFixed(6)}  Lng: ${dlng.toStringAsFixed(6)}',
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _confirm,
        icon: const Icon(Icons.check),
        label: const Text('Usar esta ubicación'),
      ),
    );
  }
}
