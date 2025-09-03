import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:puntolector/core/config/mapbox_config.dart';

class MapboxService {
  static bool _isInitialized = false;

  /// Inicializa Mapbox con el token de acceso
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurar el token de acceso de Mapbox
      MapboxOptions.setAccessToken(MapboxConfig.accessToken);

      _isInitialized = true;
      print('Mapbox inicializado correctamente');
    } catch (e) {
      print('Error inicializando Mapbox: $e');
      throw Exception('Failed to initialize Mapbox: $e');
    }
  }

  /// Verifica si Mapbox está inicializado
  static bool get isInitialized => _isInitialized;

  /// Crea opciones de cámara con valores por defecto
  static CameraOptions createDefaultCameraOptions({
    double? lat,
    double? lng,
    double? zoom,
  }) {
    return CameraOptions(
      center: Point(
        coordinates: Position(
          lng ?? MapboxConfig.defaultLng,
          lat ?? MapboxConfig.defaultLat,
        ),
      ),
      zoom: zoom ?? MapboxConfig.defaultZoom,
    );
  }

  /// Crea configuración de gestos por defecto
  static GesturesSettings createDefaultGesturesSettings() {
    return GesturesSettings(
      rotateEnabled: MapboxConfig.enableRotation,
      pitchEnabled: MapboxConfig.enableTilt,
      scrollEnabled: MapboxConfig.enablePan,
    );
  }

  /// Lista de estilos de mapa disponibles
  static List<MapStyle> get availableStyles => [
    MapStyle(
      name: 'Estándar',
      uri: MapboxStyles.STANDARD,
      description: 'Mapa estándar con calles y puntos de interés',
    ),
    MapStyle(
      name: 'Satélite',
      uri: MapboxStyles.SATELLITE,
      description: 'Vista satelital de alta resolución',
    ),
    MapStyle(
      name: 'Satélite con Calles',
      uri: MapboxStyles.SATELLITE_STREETS,
      description: 'Vista satelital con nombres de calles',
    ),
    MapStyle(
      name: 'Oscuro',
      uri: MapboxStyles.DARK,
      description: 'Tema oscuro para uso nocturno',
    ),
  ];
}

/// Clase para representar un estilo de mapa
class MapStyle {
  final String name;
  final String uri;
  final String description;

  const MapStyle({
    required this.name,
    required this.uri,
    required this.description,
  });
}
