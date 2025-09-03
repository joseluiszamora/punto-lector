import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/app_user.dart';
import '../../data/models/user_role.dart';

abstract class IUsersRepository {
  Future<List<AppUser>> listAll();
  Future<AppUser> updateRole(String id, UserRole role);
}

class UsersRepository implements IUsersRepository {
  final SupabaseClient _client;
  UsersRepository(this._client);

  @override
  Future<List<AppUser>> listAll() async {
    final res = await _client
        .from('user_profiles')
        .select('id, email, name, avatar_url, role');
    final List data = (res as List);
    return data
        .map((e) => AppUser.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<AppUser> updateRole(String id, UserRole role) async {
    final res =
        await _client
            .from('user_profiles')
            .update({'role': role.asString})
            .eq('id', id)
            .select('id, email, name, avatar_url, role')
            .single();
    return AppUser.fromMap(Map<String, dynamic>.from(res as Map));
  }
}
