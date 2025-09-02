import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/author.dart';
import '../models/category.dart';

class CatalogRepository {
  final SupabaseClient _client;
  CatalogRepository(this._client);

  Future<List<Author>> listAuthors({String? query, int limit = 200}) async {
    final res = await _client
        .from('authors')
        .select('id, name')
        .order('name')
        .limit(limit);
    final List raw = (res as List);
    var items =
        raw.map((e) => Author.fromMap(Map<String, dynamic>.from(e))).toList();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      items = items.where((a) => a.name.toLowerCase().contains(q)).toList();
    }
    return items;
  }

  Future<List<Category>> listCategories({
    String? query,
    int limit = 200,
  }) async {
    final res = await _client
        .from('categories')
        .select('id, name')
        .order('name')
        .limit(limit);
    final List raw = (res as List);
    var items =
        raw.map((e) => Category.fromMap(Map<String, dynamic>.from(e))).toList();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      items = items.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    return items;
  }
}
