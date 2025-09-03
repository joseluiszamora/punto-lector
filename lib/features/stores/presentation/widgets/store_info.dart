import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puntolector/data/models/store.dart';
import 'package:puntolector/features/stores/application/stores_bloc.dart';

class StoreInfo extends StatelessWidget {
  const StoreInfo({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (store.photoUrl != null && store.photoUrl!.isNotEmpty);
    return Column(
      children: [
        // Foto de la tienda
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              hasPhoto
                  ? Image.network(
                    store.photoUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    cacheHeight: 320,
                    filterQuality: FilterQuality.low,
                    loadingBuilder:
                        (c, child, p) =>
                            p == null
                                ? child
                                : const SizedBox(
                                  height: 160,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                    errorBuilder:
                        (c, e, s) => const SizedBox(
                          height: 160,
                          child: ColoredBox(
                            color: Colors.black12,
                            child: Center(
                              child: Icon(Icons.storefront_outlined),
                            ),
                          ),
                        ),
                  )
                  : const SizedBox(
                    height: 160,
                    child: ColoredBox(
                      color: Colors.black12,
                      child: Center(child: Icon(Icons.storefront_outlined)),
                    ),
                  ),
        ),
        const SizedBox(height: 12),
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
                  StoreUpdateRequested(store.id!, {'active': v}),
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
          subtitle: Text('Días: ${(store.openDays).join(', ')}'),
        ),
        ListTile(
          leading: const Icon(Icons.phone_outlined),
          title: Text(store.phone ?? '—'),
        ),
        if (store.description != null && store.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(store.description!),
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}
