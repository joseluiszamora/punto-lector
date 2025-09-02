import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/author.dart';

abstract class IAuthorsRepository {
  Future<List<Author>> listAll({int limit});
  Future<Author> create({
    required String name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? website,
  });
  Future<Author> update(
    String id, {
    required String name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? website,
  });
  Future<void> delete(String id);
}

class AuthorsRepository implements IAuthorsRepository {
  final SupabaseClient _client;
  AuthorsRepository(this._client);

  String? _toPgDate(DateTime? d) =>
      d == null ? null : d.toIso8601String().split('T').first;

  @override
  Future<List<Author>> listAll({int limit = 500}) async {
    final res = await _client
        .from('authors')
        .select(
          'id, name, bio, birth_date, death_date, photo_url, website, created_at, updated_at',
        )
        .order('name')
        .limit(limit);
    final List raw = (res as List);
    return raw
        .map((e) => Author.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Author> create({
    required String name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? website,
  }) async {
    final payload = {
      'name': name,
      'bio': bio,
      'birth_date': _toPgDate(birthDate),
      'death_date': _toPgDate(deathDate),
      'photo_url': photoUrl,
      'website': website,
    };
    final res =
        await _client
            .from('authors')
            .insert(payload)
            .select(
              'id, name, bio, birth_date, death_date, photo_url, website, created_at, updated_at',
            )
            .single();
    return Author.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<Author> update(
    String id, {
    required String name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? photoUrl,
    String? website,
  }) async {
    final payload = {
      'name': name,
      'bio': bio,
      'birth_date': _toPgDate(birthDate),
      'death_date': _toPgDate(deathDate),
      'photo_url': photoUrl,
      'website': website,
    };
    final res =
        await _client
            .from('authors')
            .update(payload)
            .eq('id', id)
            .select(
              'id, name, bio, birth_date, death_date, photo_url, website, created_at, updated_at',
            )
            .single();
    return Author.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('authors').delete().eq('id', id);
  }
}
