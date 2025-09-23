import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey =>
      dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ?? '';
  static String get supabaseRedirectScheme =>
      dotenv.env['SUPABASE_REDIRECT_SCHEME'] ?? 'puntolector';
  static String get supabaseRedirectHostname =>
      dotenv.env['SUPABASE_REDIRECT_HOSTNAME'] ?? 'login-callback';
  static String get mapboxAccessToken =>
      dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  static String get appName => dotenv.env['APP_NAME'] ?? 'Punto Lector';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      mapboxAccessToken.isNotEmpty;
}
