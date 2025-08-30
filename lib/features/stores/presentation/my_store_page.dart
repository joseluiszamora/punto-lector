import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/state/auth_bloc.dart';
import '../application/stores_bloc.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../data/repositories/stores_repository.dart';
import '../../../data/models/store.dart';
import 'store_form_page.dart';
import '../../../data/models/book.dart';
import '../application/store_listings_bloc.dart';
import '../../../data/repositories/listings_repository.dart';
import '../../../data/models/store_listing.dart';
import '../../books/application/books_bloc.dart';
import '../../../data/repositories/books_repository.dart';
import '../../books/presentation/new_book_page.dart';

class MyStorePage extends StatelessWidget {
  const MyStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final ownerUid = auth is Authenticated ? auth.user.id : '';

    return BlocProvider(
      create:
          (_) => StoresBloc(
            StoresRepository(SupabaseInit.client),
            ownerUid: ownerUid,
          )..add(const StoresRequested()),
      child: BlocBuilder<StoresBloc, StoresState>(
        builder: (context, state) {
          if (state is StoresLoading || state is StoresInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StoresError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          final stores = state is StoresLoaded ? state.stores : <Store>[];

          // Si no hay sesión iniciada
          if (ownerUid.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Inicia sesión para administrar tu tienda'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(const SignInWithGoogle());
                    },
                    child: const Text('Iniciar sesión'),
                  ),
                ],
              ),
            );
          }

          // Si no tiene tienda, invitamos a crear
          if (stores.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Aún no tienes una tienda'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_business),
                    label: const Text('Crear mi tienda'),
                    onPressed: () async {
                      final bloc = context.read<StoresBloc>();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => BlocProvider.value(
                                value: bloc,
                                child: const StoreFormPage(),
                              ),
                        ),
                      );
                      // Al volver, recargar
                      bloc.add(const StoresRequested());
                    },
                  ),
                ],
              ),
            );
          }

          // Mostrar la primera tienda (asumimos una por usuario por ahora)
          final store = stores.first;
          return BlocProvider(
            create:
                (_) => StoreListingsBloc(
                  ListingsRepository(SupabaseInit.client),
                  storeId: store.id,
                )..add(const StoreListingsRequested()),
            // Usamos Builder para obtener un contexto bajo este Provider
            child: Builder(
              builder:
                  (innerCtx) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.store_mall_directory_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                store.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Switch(
                              value: store.active,
                              onChanged: (v) {
                                context.read<StoresBloc>().add(
                                  StoreUpdateRequested(store.id, {'active': v}),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(store.managerName ?? '—'),
                          subtitle: const Text('Encargado'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(store.address ?? '—'),
                          subtitle: Text(store.city ?? ''),
                        ),
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(
                            'Horario: ${store.openHour ?? '--:--'} - ${store.closeHour ?? '--:--'}',
                          ),
                          subtitle: Text(
                            'Días: ${(store.openDays).join(', ')}',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: Text(store.phone ?? '—'),
                        ),
                        if (store.description != null &&
                            store.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(store.description!),
                          ),

                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'Libros en mi tienda',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () async {
                                // 1) Crear un nuevo libro
                                final created = await Navigator.push<Book>(
                                  innerCtx,
                                  MaterialPageRoute(
                                    builder: (_) => const NewBookPage(),
                                  ),
                                );
                                if (created == null) return;
                                // 2) Pedir precio y stock y crear listing
                                final priceCtrl = TextEditingController(
                                  text: '0',
                                );
                                final stockCtrl = TextEditingController(
                                  text: '0',
                                );
                                final formKey = GlobalKey<FormState>();
                                final ok = await showDialog<bool>(
                                  context: innerCtx,
                                  builder:
                                      (_) => AlertDialog(
                                        title: const Text('Detalles de venta'),
                                        content: Form(
                                          key: formKey,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextFormField(
                                                controller: priceCtrl,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Precio',
                                                    ),
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                validator: (v) {
                                                  final val = double.tryParse(
                                                    (v ?? '').replaceAll(
                                                      ',',
                                                      '.',
                                                    ),
                                                  );
                                                  if (val == null)
                                                    return 'Precio inválido';
                                                  if (val < 0)
                                                    return 'No puede ser negativo';
                                                  return null;
                                                },
                                              ),
                                              TextFormField(
                                                controller: stockCtrl,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Stock',
                                                    ),
                                                keyboardType:
                                                    TextInputType.number,
                                                validator: (v) {
                                                  final val = int.tryParse(
                                                    (v ?? '').trim(),
                                                  );
                                                  if (val == null)
                                                    return 'Stock inválido';
                                                  if (val < 0)
                                                    return 'No puede ser negativo';
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  innerCtx,
                                                  false,
                                                ),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              if (!formKey.currentState!
                                                  .validate())
                                                return;
                                              Navigator.pop(innerCtx, true);
                                            },
                                            child: const Text('Agregar'),
                                          ),
                                        ],
                                      ),
                                );
                                if (ok == true) {
                                  final price = double.parse(
                                    priceCtrl.text.replaceAll(',', '.'),
                                  );
                                  final stock = int.parse(
                                    stockCtrl.text.trim(),
                                  );
                                  innerCtx.read<StoreListingsBloc>().add(
                                    StoreListingAddRequested(
                                      bookId: created.id,
                                      price: price,
                                      stock: stock,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar libro'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        BlocBuilder<StoreListingsBloc, StoreListingsState>(
                          builder: (ctx, st) {
                            if (st is StoreListingsLoading ||
                                st is StoreListingsInitial) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (st is StoreListingsError) {
                              return Text(
                                st.message,
                                style: const TextStyle(color: Colors.red),
                              );
                            }
                            final items =
                                st is StoreListingsLoaded
                                    ? st.items
                                    : <StoreListing>[];
                            if (items.isEmpty) {
                              return const Text('Aún no agregaste libros.');
                            }
                            return ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: items.length,
                              itemBuilder: (itemCtx, i) {
                                final it = items[i];
                                final b = it.book;
                                return ListTile(
                                  leading:
                                      b.coverUrl != null
                                          ? Image.network(
                                            b.coverUrl!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          )
                                          : const Icon(Icons.menu_book),
                                  title: Text(b.title),
                                  subtitle: Text(
                                    '${b.author} • ${it.price.toStringAsFixed(2)} ${it.currency} • stock: ${it.stock}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      itemCtx.read<StoreListingsBloc>().add(
                                        StoreListingRemoveRequested(it.id),
                                      );
                                    },
                                    tooltip: 'Eliminar',
                                  ),
                                );
                              },
                              separatorBuilder:
                                  (_, __) => const Divider(height: 1),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }
}

class _AddListingSheet extends StatefulWidget {
  final String storeId;
  const _AddListingSheet({required this.storeId});

  @override
  State<_AddListingSheet> createState() => _AddListingSheetState();
}

class _AddListingSheetState extends State<_AddListingSheet> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _askPriceAndAdd(String bookId) async {
    final priceCtrl = TextEditingController(text: '0');
    final stockCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Agregar libro'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Precio'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final val = double.tryParse(
                        (v ?? '').replaceAll(',', '.'),
                      );
                      if (val == null) return 'Precio inválido';
                      if (val < 0) return 'No puede ser negativo';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: stockCtrl,
                    decoration: const InputDecoration(labelText: 'Stock'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final val = int.tryParse((v ?? '').trim());
                      if (val == null) return 'Stock inválido';
                      if (val < 0) return 'No puede ser negativo';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
    );
    if (ok == true) {
      final price = double.parse(priceCtrl.text.replaceAll(',', '.'));
      final stock = int.parse(stockCtrl.text.trim());
      context.read<StoreListingsBloc>().add(
        StoreListingAddRequested(bookId: bookId, price: price, stock: stock),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BlocProvider(
        create: (_) => BooksBloc(BooksRepository(SupabaseInit.client)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Buscar libro',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _authorCtrl,
              decoration: const InputDecoration(labelText: 'Autor'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                context.read<BooksBloc>().add(
                  BooksSearchRequested(
                    title: _titleCtrl.text,
                    author: _authorCtrl.text,
                  ),
                );
              },
              child: const Text('Buscar'),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: BlocBuilder<BooksBloc, BooksState>(
                builder: (context, state) {
                  if (state is BooksLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is BooksError) {
                    return Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    );
                  }
                  final books = state is BooksLoaded ? state.books : <Book>[];
                  if (books.isEmpty) {
                    return const Text('Sin resultados');
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: books.length,
                    itemBuilder: (_, i) {
                      final b = books[i];
                      return ListTile(
                        leading:
                            b.coverUrl != null
                                ? Image.network(
                                  b.coverUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                )
                                : const Icon(Icons.menu_book),
                        title: Text(b.title),
                        subtitle: Text(b.author),
                        onTap: () => _askPriceAndAdd(b.id),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
