import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

abstract class ICategoriesRepository {
  Future<List<Category>> listAll({int limit});
  Future<List<Category>> getCategoriesTree();
  Future<List<Category>> getCategoriesByLevel({
    int level = 0,
    String? parentId,
  });
  Future<List<Category>> getCategoryPath(String categoryId);
  Future<List<Category>> searchCategories(String searchTerm);
  Future<Category> create({
    required String name,
    String? description,
    String? color,
    String? parentId,
    int level = 0,
    int sortOrder = 0,
  });
  Future<Category> update(
    String id, {
    required String name,
    String? description,
    String? color,
    String? parentId,
    int? level,
    int? sortOrder,
  });
  Future<void> delete(String id);
}

class CategoriesRepository implements ICategoriesRepository {
  final SupabaseClient _client;
  CategoriesRepository(this._client);

  @override
  Future<List<Category>> listAll({int limit = 500}) async {
    final res = await _client
        .from('categories')
        .select('id, name, description, color, parent_id, level, sort_order')
        .order('level')
        .order('sort_order')
        .order('name')
        .limit(limit);
    final List raw = (res as List);
    return raw
        .map((e) => Category.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<Category>> getCategoriesTree() async {
    final res = await _client.rpc('get_categories_tree');
    final List raw = (res as List);
    return raw
        .map((e) => Category.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<Category>> getCategoriesByLevel({
    int level = 0,
    String? parentId,
  }) async {
    final res = await _client.rpc(
      'get_categories_by_level',
      params: {'target_level': level, 'parent_category_id': parentId},
    );
    final List raw = (res as List);
    return raw
        .map((e) => Category.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<Category>> getCategoryPath(String categoryId) async {
    final res = await _client.rpc(
      'get_category_path',
      params: {'category_id': categoryId},
    );
    final List raw = (res as List);
    return raw
        .map((e) => Category.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<Category>> searchCategories(String searchTerm) async {
    final res = await _client.rpc(
      'search_categories_hierarchy',
      params: {'search_term': searchTerm, 'include_children': true},
    );
    final List raw = (res as List);
    return raw
        .map((e) => Category.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<bool> existsByName(
    String name, {
    String? excludeId,
    String? parentId,
  }) async {
    var q = _client.from('categories').select('id').ilike('name', name);

    if (parentId != null) {
      q = q.eq('parent_id', parentId);
    } else {
      q = q.isFilter('parent_id', null);
    }

    if (excludeId != null) q = q.neq('id', excludeId);

    final res = await q.limit(1);
    final List raw = (res as List);
    return raw.isNotEmpty;
  }

  @override
  Future<Category> create({
    required String name,
    String? description,
    String? color,
    String? parentId,
    int level = 0,
    int sortOrder = 0,
  }) async {
    if (await existsByName(name, parentId: parentId)) {
      throw Exception('Ya existe una categoría con ese nombre en este nivel');
    }

    final data = {
      'name': name,
      'description': description,
      'color': color,
      'parent_id': parentId,
      'level': level,
      'sort_order': sortOrder,
    };

    final res =
        await _client
            .from('categories')
            .insert(data)
            .select(
              'id, name, description, color, parent_id, level, sort_order',
            )
            .single();

    return Category.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<Category> update(
    String id, {
    required String name,
    String? description,
    String? color,
    String? parentId,
    int? level,
    int? sortOrder,
  }) async {
    if (await existsByName(name, excludeId: id, parentId: parentId)) {
      throw Exception('Ya existe una categoría con ese nombre en este nivel');
    }

    final data = {
      'name': name,
      'description': description,
      'color': color,
      'parent_id': parentId,
      'level': level,
      'sort_order': sortOrder,
    };

    final res =
        await _client
            .from('categories')
            .update(data)
            .eq('id', id)
            .select(
              'id, name, description, color, parent_id, level, sort_order',
            )
            .single();

    return Category.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  // Additional helper methods
  Future<List<Category>> getMainCategories() async {
    return getCategoriesByLevel(level: 0);
  }

  Future<List<Category>> getSubcategories(String parentId) async {
    return getCategoriesByLevel(level: 1, parentId: parentId);
  }

  Future<Category?> getById(String id) async {
    final res =
        await _client
            .from('categories')
            .select(
              'id, name, description, color, parent_id, level, sort_order',
            )
            .eq('id', id)
            .maybeSingle();

    if (res == null) return null;
    return Category.fromMap(Map<String, dynamic>.from(res as Map));
  }
}
