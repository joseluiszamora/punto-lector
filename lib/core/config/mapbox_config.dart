import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapboxConfig {
  static String get accessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  // Estilos de mapa predefinidos
  static const String standardStyle = 'mapbox://styles/mapbox/standard';
  static const String satelliteStyle = 'mapbox://styles/mapbox/satellite-v9';
  static const String streetStyle = 'mapbox://styles/mapbox/streets-v12';
  static const String darkStyle = 'mapbox://styles/mapbox/dark-v11';
  static const String lightStyle = 'mapbox://styles/mapbox/light-v11';
  static const String outdoorsStyle = 'mapbox://styles/mapbox/outdoors-v12';

  // Configuración por defecto del mapa
  static const double defaultZoom = 12.0;
  static const double defaultLat = -16.4953; // La Paz, Bolivia
  static const double defaultLng = -68.1700; // La Paz, Bolivia

  // Configuración de marcadores
  static const String defaultMarkerIcon = 'custom-marker';
  static const double markerSize = 1.0;

  // Configuración de animaciones
  static const int cameraAnimationDuration = 1000; // milisegundos

  // Límites de zoom
  static const double minZoom = 0.0;
  static const double maxZoom = 22.0;

  // Configuración de gestos
  static const bool enableRotation = true;
  static const bool enableTilt = true;
  static const bool enableZoom = true;
  static const bool enablePan = true;
}
