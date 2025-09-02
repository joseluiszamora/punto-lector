import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../../core/config/env.dart';

abstract class IAuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser?> signInWithGoogle();
  Future<void> signOut();
  AppUser? get currentUser;
}

class AuthRepository implements IAuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  @override
  Stream<AppUser?> authStateChanges() async* {
    // Emitir estado inicial desde perfil
    final initial = await _mapUserFromProfiles(_client.auth.currentUser);
    yield initial;

    await for (final e in _client.auth.onAuthStateChange) {
      final user = e.session?.user;
      final mapped = await _mapUserFromProfiles(user);
      yield mapped;
    }
  }

  @override
  AppUser? get currentUser => _mapUserFromMetadata(_client.auth.currentUser);

  // Mapeo rápido desde metadata (fallback síncrono)
  AppUser? _mapUserFromMetadata(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? {};
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      name: metadata['name'] as String?,
      avatarUrl: metadata['avatar_url'] as String?,
      role: UserRoleX.fromString(metadata['role'] as String?),
    );
  }

  // Mapeo principal: lee perfil desde public.user_profiles (y lo crea si no existe)
  Future<AppUser?> _mapUserFromProfiles(User? user) async {
    if (user == null) return null;
    // Intentar leer perfil
    final prof = await _fetchProfile(user.id);
    if (prof != null) {
      return AppUser(
        id: prof['id'] as String,
        email: (prof['email'] as String?) ?? (user.email ?? ''),
        name: prof['name'] as String?,
        avatarUrl: prof['avatar_url'] as String?,
        role: UserRoleX.fromString(prof['role'] as String?),
      );
    }
    // Crear perfil mínimo si falta
    try {
      final inserted =
          await _client
              .from('user_profiles')
              .insert({
                'id': user.id,
                'email': user.email ?? '',
                'name': user.userMetadata?['name'],
                'avatar_url': user.userMetadata?['avatar_url'],
                // 'role' por defecto lo asigna la tabla ('user')
              })
              .select()
              .single();
      final map = Map<String, dynamic>.from(inserted as Map);
      return AppUser(
        id: map['id'] as String,
        email: (map['email'] as String?) ?? (user.email ?? ''),
        name: map['name'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        role: UserRoleX.fromString(map['role'] as String?),
      );
    } catch (_) {
      // Si falla por RLS, devolvemos al menos el usuario sin rol
      return AppUser(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'],
        avatarUrl: user.userMetadata?['avatar_url'],
        role: UserRole.user,
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    final res =
        await _client
            .from('user_profiles')
            .select('id, email, name, avatar_url, role')
            .eq('id', userId)
            .maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res as Map);
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo:
          '${Env.supabaseRedirectScheme}://${Env.supabaseRedirectHostname}',
      queryParams: const {'access_type': 'offline', 'prompt': 'consent'},
    );
    // El stream emitirá el usuario al volver del OAuth
    return null;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
