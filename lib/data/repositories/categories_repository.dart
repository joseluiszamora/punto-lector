import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

abstract class ICategoriesRepository {
  Future<List<Category>> listAll({int limit});
  Future<Category> create({required String name, String? color});
  Future<Category> update(String id, {required String name, String? color});
  Future<void> delete(String id);
}

class CategoriesRepository implements ICategoriesRepository {
  final SupabaseClient _client;
  CategoriesRepository(this._client);

  @override
  Future<List<Category>> listAll({int limit = 500}) async {
    final res = await _client
        .from('categories')
        .select('id, name, color')
        .order('name')
        .limit(limit);
    final List raw = (res as List);
    return raw
        .map((e) => Category.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<bool> existsByName(String name, {String? excludeId}) async {
    var q = _client.from('categories').select('id').ilike('name', name);
    if (excludeId != null) q = q.neq('id', excludeId);
    final res = await q.limit(1);
    final List raw = (res as List);
    return raw.isNotEmpty;
  }

  @override
  Future<Category> create({required String name, String? color}) async {
    if (await existsByName(name)) {
      throw Exception('Ya existe una categoría con ese nombre');
    }
    final res =
        await _client
            .from('categories')
            .insert({'name': name, 'color': color})
            .select('id, name, color')
            .single();
    return Category.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<Category> update(
    String id, {
    required String name,
    String? color,
  }) async {
    if (await existsByName(name, excludeId: id)) {
      throw Exception('Ya existe una categoría con ese nombre');
    }
    final res =
        await _client
            .from('categories')
            .update({'name': name, 'color': color})
            .eq('id', id)
            .select('id, name, color')
            .single();
    return Category.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
