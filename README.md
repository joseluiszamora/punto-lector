# Punto Lector

App Flutter con Supabase, Bloc y Mapbox.

## Configuración

1. Copia `.env` y configura:

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SUPABASE_REDIRECT_SCHEME=puntolector
SUPABASE_REDIRECT_HOSTNAME=login-callback
MAPBOX_ACCESS_TOKEN=...
```

2. En Supabase, habilita Google OAuth y agrega el redirect URL:

- Android/iOS: `puntolector://login-callback`

3. Android: `AndroidManifest.xml` ya incluye el intent-filter con el esquema.
4. iOS: `Info.plist` incluye el URL scheme y permisos de localización.

## Ejecutar

- flutter pub get
- flutter run

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
