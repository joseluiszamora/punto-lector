import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/store_listing.dart';

abstract class IListingsRepository {
  Future<List<StoreListing>> listByStore(String storeId);
  Future<StoreListing> add({
    required String storeId,
    required String bookId,
    required double price,
    String currency = 'BOB',
    int stock = 0,
  });
  Future<void> remove(String id);
  // Nuevo: actualizar listing
  Future<StoreListing> update(
    String id, {
    double? price,
    String? currency,
    int? stock,
    bool? active,
  });
}

class ListingsRepository implements IListingsRepository {
  final SupabaseClient _client;
  ListingsRepository(this._client);

  String _bookSelect() =>
      'book:books(*, books_authors(authors(*)), book_categories(categories(*)))';

  @override
  Future<List<StoreListing>> listByStore(String storeId) async {
    final res = await _client
        .from('listings')
        .select(
          'id, store_id, book_id, price, currency, stock, active, ${_bookSelect()}',
        )
        .eq('store_id', storeId)
        .eq('active', true);
    final List raw = (res as List);
    return raw
        .map((e) => StoreListing.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<StoreListing> add({
    required String storeId,
    required String bookId,
    required double price,
    String currency = 'BOB',
    int stock = 0,
  }) async {
    final res =
        await _client
            .from('listings')
            .insert({
              'store_id': storeId,
              'book_id': bookId,
              'price': price,
              'currency': currency,
              'stock': stock,
              'active': true,
            })
            .select(
              'id, store_id, book_id, price, currency, stock, active, ${_bookSelect()}',
            )
            .single();
    return StoreListing.fromMap(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<void> remove(String id) async {
    // soft delete
    await _client.from('listings').update({'active': false}).eq('id', id);
  }

  @override
  Future<StoreListing> update(
    String id, {
    double? price,
    String? currency,
    int? stock,
    bool? active,
  }) async {
    final patch = <String, dynamic>{};
    if (price != null) patch['price'] = price;
    if (currency != null) patch['currency'] = currency;
    if (stock != null) patch['stock'] = stock;
    if (active != null) patch['active'] = active;
    final res =
        await _client
            .from('listings')
            .update(patch)
            .eq('id', id)
            .select(
              'id, store_id, book_id, price, currency, stock, active, ${_bookSelect()}',
            )
            .single();
    return StoreListing.fromMap(Map<String, dynamic>.from(res as Map));
  }
}
