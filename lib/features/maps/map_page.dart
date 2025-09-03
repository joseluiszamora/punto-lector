import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:puntolector/core/config/mapbox_config.dart';
import 'package:puntolector/features/stores/services/mapbox_service.dart';
import '../../data/models/store.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.stores, this.onStoreTap});

  final List<Store> stores;
  final void Function(Store)? onStoreTap;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapboxMap? _map;
  final String _selectedMapStyle = MapboxStyles.STANDARD;

  PointAnnotationManager? _pointAnnotationManager;
  CircleAnnotationManager? _circleAnnotationManager;

  // Coordenadas de La Paz, Bolivia como centro por defecto
  static const double _defaultLat = MapboxConfig.defaultLat;
  static const double _defaultLng = MapboxConfig.defaultLng;

  @override
  void initState() {
    super.initState();
    _mapboxInitialization();
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stores != widget.stores) {
      _addStoresMarkers();
    }
  }

  void _mapboxInitialization() {
    MapboxService.initialize();
    if (!MapboxService.isInitialized) {
      print('Advertencia: Mapbox no está inicializado');
    }
  }

  void _onMapCreated(MapboxMap map) {
    _map = map;

    // Configurar el mapa
    _configureMap();

    // Agregar marcadores de tiendas
    _addStoresMarkers();
  }

  Future<void> _configureMap() async {
    if (_map == null) return;

    try {
      // Configurar límites de zoom
      await _map!.setCamera(CameraOptions(zoom: MapboxConfig.defaultZoom));

      // Habilitar gestos usando el servicio
      await _map!.gestures.updateSettings(
        MapboxService.createDefaultGesturesSettings(),
      );

      // Configurar listeners de eventos del mapa
      // _setupMapListeners();
    } catch (e) {
      print('Error configurando mapa: $e');
    }
  }

  Color _colorForStore(Store s) {
    final palette = <Color>[
      Colors.indigo,
      Colors.teal,
      Colors.deepOrange,
      Colors.pink,
      Colors.green,
      Colors.purple,
      Colors.blueGrey,
    ];
    final key = (s.id ?? s.name);
    final hash = key.runes.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return palette[hash % palette.length];
  }

  Future<void> _addStoresMarkers() async {
    if (_map == null) return;

    try {
      // Crear managers de anotaciones si no existen
      _pointAnnotationManager ??=
          await _map!.annotations.createPointAnnotationManager();
      _circleAnnotationManager ??=
          await _map!.annotations.createCircleAnnotationManager();

      // Limpiar marcadores existentes
      await _pointAnnotationManager!.deleteAll();
      await _circleAnnotationManager!.deleteAll();

      // Construir opciones para cada tienda activa con coordenadas válidas
      final valid =
          widget.stores
              .where((s) => (s.active) && s.lat != null && s.lng != null)
              .toList();

      final idToStore = <String, Store>{};
      for (final s in valid) {
        final position = Position(s.lng!, s.lat!);
        final color = _colorForStore(s);

        // Halo (sombra)
        final halo = CircleAnnotationOptions(
          geometry: Point(coordinates: position),
          circleRadius: 24.5, // 70% de 35
          circleColor: color.withOpacity(0.2).value,
          circleOpacity: 0.4,
          circleStrokeWidth: 0.0,
        );
        await _circleAnnotationManager!.create(halo);

        // Círculo principal
        final circle = CircleAnnotationOptions(
          geometry: Point(coordinates: position),
          circleRadius: 15.4, // 70% de 22
          circleColor: color.value,
          circleOpacity: 0.9,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 3.0,
          circleStrokeOpacity: 1.0,
        );
        await _circleAnnotationManager!.create(circle);

        // Icono de libro centrado (sprite de Mapbox)
        final bookIcon = PointAnnotationOptions(
          geometry: Point(coordinates: position),
          iconImage: 'library-15',
          iconSize: 1.2,
          iconAnchor: IconAnchor.CENTER,
        );
        final bookAnn = await _pointAnnotationManager!.create(bookIcon);
        idToStore[bookAnn.id] = s;

        // Nombre de la tienda arriba
        final label = PointAnnotationOptions(
          geometry: Point(coordinates: position),
          textField: s.name,
          textOffset: const [0.0, -3.2], // ajustado al nuevo tamaño
          textColor: color.value,
          textSize: 11.0,
          textHaloColor: Colors.white.value,
          textHaloWidth: 2.5,
        );
        final labelAnn = await _pointAnnotationManager!.create(label);
        idToStore[labelAnn.id] = s;
      }

      // Tap en marcador (emoji o etiqueta)
      if (widget.onStoreTap != null) {
        _pointAnnotationManager!.addOnPointAnnotationClickListener(
          _PointClickListener((ann) {
            final s = idToStore[ann.id];
            if (s != null) widget.onStoreTap!(s);
            return true;
          }),
        );
      }

      // Centrar cámara sobre el conjunto de tiendas
      if (valid.isNotEmpty) {
        _moveCameraToStores(valid);
      } else {
        // Si no hay tiendas válidas, centrar en default
        await _map!.setCamera(
          CameraOptions(
            center: Point(coordinates: Position(_defaultLng, _defaultLat)),
            zoom: MapboxConfig.defaultZoom,
          ),
        );
      }
    } catch (e) {
      print('Error agregando marcadores de tiendas: $e');
    }
  }

  Future<void> _moveCameraToStores(List<Store> stores) async {
    if (_map == null || stores.isEmpty) return;
    // Estrategia simple: centrar en el promedio de coordenadas
    double lat = 0, lng = 0;
    for (final s in stores) {
      lat += s.lat!;
      lng += s.lng!;
    }
    lat /= stores.length;
    lng /= stores.length;
    await _map!.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: MapboxConfig.defaultZoom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa principal
          MapWidget(
            key: ValueKey(_selectedMapStyle),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(_defaultLng, _defaultLat)),
              zoom: 12.0,
            ),
            styleUri: _selectedMapStyle,
            onMapCreated: _onMapCreated,
          ),
        ],
      ),
    );
  }
}

class _PointClickListener extends OnPointAnnotationClickListener {
  _PointClickListener(this.onTap);
  final bool Function(PointAnnotation) onTap;
  @override
  bool onPointAnnotationClick(PointAnnotation annotation) => onTap(annotation);
}
