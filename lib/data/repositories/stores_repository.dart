import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/store.dart';

abstract class IStoresRepository {
  Future<List<Store>> listMyStores(String ownerUid);
  Future<Store> create(Store store);
  Future<Store> update(String id, Map<String, dynamic> patch);
}

class StoresRepository implements IStoresRepository {
  final SupabaseClient _client;
  StoresRepository(this._client);

  @override
  Future<List<Store>> listMyStores(String ownerUid) async {
    // Si ownerUid está vacío, evitamos filtrar por UUID para no provocar 22P02
    final query = _client.from('stores').select().eq('active', true);
    final res =
        ownerUid.trim().isEmpty
            ? await query
            : await query.eq('owner_uid', ownerUid);
    final List data = (res as List);
    return data
        .map((e) => Store.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Store> create(Store store) async {
    final res =
        await _client.from('stores').insert(store.toInsert()).select().single();
    return Store.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<Store> update(String id, Map<String, dynamic> patch) async {
    final res =
        await _client
            .from('stores')
            .update(patch)
            .eq('id', id)
            .select()
            .single();
    return Store.fromMap(Map<String, dynamic>.from(res as Map));
  }
}
