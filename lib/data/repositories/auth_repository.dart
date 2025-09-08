import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../../core/config/env.dart';

abstract class IAuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser?> signInWithGoogle();
  Future<void> signInWithEmailPassword(String email, String password);
  Future<void> signUpWithEmailPassword(
    String email,
    String password, {
    String? name,
    String? nationalityId,
  });
  Future<bool> isCurrentUserProfileComplete();
  Future<void> updateCurrentUserProfile({
    String? firstName,
    String? lastName,
    String? nationalityId,
  });
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
      // Si falta avatar_url y el proveedor lo trae, actualizarlo
      final metaAvatar = user.userMetadata?['avatar_url'] as String?;
      if ((prof['avatar_url'] == null ||
              (prof['avatar_url'] as String).isEmpty) &&
          metaAvatar != null &&
          metaAvatar.isNotEmpty) {
        try {
          await _client
              .from('user_profiles')
              .update({'avatar_url': metaAvatar})
              .eq('id', user.id);
          prof['avatar_url'] = metaAvatar;
        } catch (_) {}
      }
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
  Future<void> signInWithEmailPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmailPassword(
    String email,
    String password, {
    String? name,
    String? nationalityId,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {if (name != null && name.isNotEmpty) 'name': name},
      emailRedirectTo:
          '${Env.supabaseRedirectScheme}://${Env.supabaseRedirectHostname}',
    );

    final newUser = res.user;
    if (newUser != null) {
      try {
        await _client.from('user_profiles').upsert({
          'id': newUser.id,
          'email': newUser.email ?? email,
          'name': name,
          if (nationalityId != null && nationalityId.isNotEmpty)
            'nationality_id': nationalityId,
        });
      } catch (_) {
        // noop, RLS puede impedir escritura inmediata si policies cambian
      }
    }
  }

  @override
  Future<bool> isCurrentUserProfileComplete() async {
    final u = _client.auth.currentUser;
    if (u == null) return false;
    final data =
        await _client
            .from('user_profiles')
            .select('first_name, last_name, nationality_id')
            .eq('id', u.id)
            .maybeSingle();
    if (data == null) return false;
    final map = Map<String, dynamic>.from(data as Map);
    final first = (map['first_name'] as String?)?.trim();
    final last = (map['last_name'] as String?)?.trim();
    final nat = map['nationality_id'] as String?;
    return (first != null && first.isNotEmpty) &&
        (last != null && last.isNotEmpty) &&
        (nat != null && nat.isNotEmpty);
  }

  @override
  Future<void> updateCurrentUserProfile({
    String? firstName,
    String? lastName,
    String? nationalityId,
  }) async {
    final u = _client.auth.currentUser;
    if (u == null) return;
    final payload = <String, dynamic>{};
    if (firstName != null) payload['first_name'] = firstName;
    if (lastName != null) payload['last_name'] = lastName;
    if (nationalityId != null) payload['nationality_id'] = nationalityId;
    if (payload.isEmpty) return;
    await _client.from('user_profiles').update(payload).eq('id', u.id);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
