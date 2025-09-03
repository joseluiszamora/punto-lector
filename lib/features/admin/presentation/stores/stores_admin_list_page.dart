import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../data/models/store.dart';
import '../../../../data/repositories/stores_repository.dart';
import '../../../stores/presentation/widgets/store_form.dart';

class StoresAdminListPage extends StatelessWidget {
  const StoresAdminListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final user = SupabaseInit.client.auth.currentUser;
        final ownerUid = user?.id ?? '';
        return _StoresCubit(StoresRepository(SupabaseInit.client), ownerUid)
          ..load();
      },
      child: const _StoresView(),
    );
  }
}

class _StoresCubit extends Cubit<_StoresState> {
  final IStoresRepository repo;
  final String ownerUid;
  List<Store> _itemsCache = [];
  List<Store> get items => _itemsCache;

  _StoresCubit(this.repo, this.ownerUid) : super(const _StoresState.loading());

  Future<void> load() async {
    emit(const _StoresState.loading());
    try {
      final items = await repo.listMyStores(ownerUid);
      _itemsCache = items;
      emit(_StoresState.loaded(items));
    } catch (e) {
      emit(_StoresState.error(e.toString()));
    }
  }

  Future<void> create(Store store) async {
    emit(const _StoresState.operating());
    try {
      final created = await repo.create(store);
      _itemsCache = [created, ..._itemsCache];
      emit(const _StoresState.operationSuccess());
      emit(_StoresState.loaded(_itemsCache));
    } catch (e) {
      emit(_StoresState.error(e.toString()));
    }
  }

  Future<void> update(String id, Map<String, dynamic> patch) async {
    emit(const _StoresState.operating());
    try {
      final updated = await repo.update(id, patch);
      _itemsCache =
          _itemsCache.map((s) => s.id == updated.id ? updated : s).toList();
      emit(const _StoresState.operationSuccess());
      emit(_StoresState.loaded(_itemsCache));
    } catch (e) {
      emit(_StoresState.error(e.toString()));
    }
  }

  Future<void> remove(String id) async {
    emit(const _StoresState.operating());
    try {
      await repo.delete(id);
      _itemsCache = _itemsCache.where((s) => s.id != id).toList();
      emit(const _StoresState.operationSuccess());
      emit(_StoresState.loaded(_itemsCache));
    } catch (e) {
      emit(_StoresState.error(e.toString()));
    }
  }
}

sealed class _StoresState {
  const _StoresState();
  const factory _StoresState.loading() = _Loading;
  const factory _StoresState.loaded(List<Store> items) = _Loaded;
  const factory _StoresState.error(String message) = _Error;
  const factory _StoresState.operating() = _Operating;
  const factory _StoresState.operationSuccess() = _OperationSuccess;
}

class _Loading extends _StoresState {
  const _Loading();
}

class _Operating extends _StoresState {
  const _Operating();
}

class _OperationSuccess extends _StoresState {
  const _OperationSuccess();
}

class _Error extends _StoresState {
  final String message;
  const _Error(this.message);
}

class _Loaded extends _StoresState {
  final List<Store> items;
  const _Loaded(this.items);
}

class _StoresView extends StatelessWidget {
  const _StoresView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Tiendas'),
        actions: [
          IconButton(
            onPressed: () => context.read<_StoresCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nueva'),
      ),
      body: BlocConsumer<_StoresCubit, _StoresState>(
        listener: (context, state) {
          if (state is _Error) {
            final msg = state.message.replaceFirst('Exception: ', '');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $msg')));
          } else if (state is _OperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Operación exitosa')));
          }
        },
        builder: (context, state) {
          Widget buildList(List<Store> items) {
            if (items.isEmpty) return const Center(child: Text('Sin tiendas'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final s = items[i];
                final subtitle = [
                  s.city,
                  s.address,
                ].where((e) => (e ?? '').isNotEmpty).join(' • ');
                return ListTile(
                  leading:
                      (s.photoUrl != null && s.photoUrl!.isNotEmpty)
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              s.photoUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              cacheHeight: 96,
                              filterQuality: FilterQuality.low,
                              loadingBuilder:
                                  (c, child, p) =>
                                      p == null
                                          ? child
                                          : const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                              errorBuilder:
                                  (c, e, s) => const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ColoredBox(
                                      color: Colors.black12,
                                      child: Icon(Icons.storefront_outlined),
                                    ),
                                  ),
                            ),
                          )
                          : const SizedBox(
                            width: 48,
                            height: 48,
                            child: ColoredBox(
                              color: Colors.black12,
                              child: Icon(Icons.storefront_outlined),
                            ),
                          ),
                  title: Text(s.name),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(ctx, store: s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(ctx, s),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                );
              },
            );
          }

          if (state is _Loaded) return buildList(state.items);
          if (state is _Loading)
            return const Center(child: CircularProgressIndicator());
          if (state is _Operating || state is _OperationSuccess) {
            final cached = context.read<_StoresCubit>().items;
            return buildList(cached);
          }
          if (state is _Error) {
            final msg = state.message.replaceFirst('Exception: ', '');
            return Center(
              child: Text(msg, style: const TextStyle(color: Colors.red)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Store? store}) async {
    final result = await showDialog<StoreFormResult>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(store == null ? 'Nueva tienda' : 'Editar tienda'),
            content: StoreForm(
              initial: store,
              onSubmit: (res) => Navigator.pop(ctx, res),
            ),
          ),
    );
    if (result == null) return;
    final cubit = context.read<_StoresCubit>();
    if (store == null) {
      await cubit.create(result.toStore());
    } else {
      await cubit.update(store.id!, result.toPatch());
    }
  }

  Future<void> _confirmDelete(BuildContext context, Store s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar tienda'),
            content: Text('¿Deseas eliminar "${s.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await context.read<_StoresCubit>().remove(s.id!);
    }
  }
}

// Clases y formulario específicos del admin eliminados.
// Se utiliza StoreForm compartido (features/stores/presentation/widgets/store_form.dart).
