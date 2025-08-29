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
    yield _mapUser(_client.auth.currentUser);
    await for (final e in _client.auth.onAuthStateChange) {
      yield _mapUser(e.session?.user);
    }
  }

  @override
  AppUser? get currentUser => _mapUser(_client.auth.currentUser);

  AppUser? _mapUser(User? user) {
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

  @override
  Future<AppUser?> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo:
          '${Env.supabaseRedirectScheme}://${Env.supabaseRedirectHostname}',
      queryParams: const {'access_type': 'offline', 'prompt': 'consent'},
    );
    return _mapUser(_client.auth.currentUser);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
