# Configuración del proyecto Punto Lector (Flutter + Supabase + Bloc + Mapbox)

Sigue estos pasos para dejar el proyecto listo en Android/iOS.

## 1) Variables de entorno (.env)

Copia `.env` y completa:

```
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_PUBLIC_KEY
SUPABASE_REDIRECT_SCHEME=puntolector
SUPABASE_REDIRECT_HOSTNAME=login-callback
MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_PUBLIC_TOKEN
APP_NAME=Punto Lector
```

## 2) Dependencias

- Requisitos:
  - Flutter 3.7+ (Dart 3.7 SDK)
- Instala paquetes:

```
flutter pub get
```

## 3) Supabase

1. Crea un proyecto en https://supabase.com
2. Habilita “Sign in with Google” en Authentication -> Providers.
3. Agrega redirect: `puntolector://login-callback`
4. Ejecuta los SQL en tu proyecto (SQL editor):
   - `supabase/schema.sql`
   - `supabase/policies.sql`
   - `supabase/storage_buckets.sql`
5. En Storage, verifica buckets `book_covers` y `store_photos`.

## 4) Android

- Archivo `android/app/src/main/AndroidManifest.xml` ya tiene:
  - `android.permission.INTERNET`, permisos de localización.
  - Intent-filter para deep link:
    - scheme: `puntolector`
    - host: `login-callback`

> Si cambias esquema/host, actualiza `.env` y el manifest.

## 5) iOS

- `ios/Runner/Info.plist` contiene:
  - `NSLocationWhenInUseUsageDescription`.
  - `CFBundleURLTypes` con esquema `puntolector`.
- En Xcode: configura el “Bundle Identifier” y firma.

## 6) Mapbox

- Crea un token en https://account.mapbox.com
- Pega el token en `.env` como `MAPBOX_ACCESS_TOKEN`.
- Inicialización
  - Ya se inyecta globalmente en `StoresMapPage` con `MapboxOptions.setAccessToken(...)`.
  - Opcional: Configúralo en `main.dart` apenas arranca la app.

## 7) Ejecutar

```
flutter run
```

## 8) Estructura clave

- core: env, router, supabase client
- data: models, repositories (auth, books, stores)
- features: auth (Bloc), books (Bloc búsqueda), stores (Bloc + mapa)

## 9) Flujo de Auth

- Login: botón “Continuar con Google” -> Supabase OAuth nativo.
- AuthBloc escucha `onAuthStateChange` y navega a Home.

## 10) Subida de imágenes a Supabase

- Usa buckets `book_covers` y `store_photos`.
- Ejemplo (pseudo):

```
final file = await ImagePicker().pickImage(source: ImageSource.gallery);
await Supabase.instance.client.storage.from('book_covers').upload('covers/${id}.jpg', File(file.path));
final publicUrl = Supabase.instance.client.storage.from('book_covers').getPublicUrl('covers/${id}.jpg');
```

## 11) Búsqueda

- Implementada de forma básica (filtro en memoria). Sugerido: crear índice `to_tsvector` y RPC para full-text.

## 12) Roles

- `user_profiles.role`: `user | store_manager | admin`.
- Policies ya restringen CRUD de tiendas/listings/ofertas por rol o propietario.

## 13) Notas

- Revisa `lib/features/stores/presentation/stores_map_page.dart` para centrar mapa y mostrar marcadores de tiendas (TO DO).
- Completa los tokens reales en `.env`.
