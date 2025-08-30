import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/navigation/nav_cubit.dart';
import '../books/presentation/search_section.dart';
import '../stores/presentation/stores_map_page.dart';
import '../favorites/presentation/favorites_page.dart';
import '../profile/presentation/profile_page.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../data/repositories/books_repository.dart';
import '../books/application/books_bloc.dart';
import '../stores/presentation/my_store_page.dart';

class RootNavPage extends StatelessWidget {
  const RootNavPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      // Libros
      BlocProvider(
        create: (_) => BooksBloc(BooksRepository(SupabaseInit.client)),
        child: const SingleChildScrollView(child: BookSearchSection()),
      ),
      // Tiendas (mapa)
      const StoresMapPage(),
      // Mi tienda (administración)
      const MyStorePage(),
      // Favoritos
      const FavoritesPage(),
      // Perfil
      const ProfilePage(),
    ];

    final items = const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_outlined),
        label: 'Libros',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.store_mall_directory_outlined),
        label: 'Tiendas',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.storefront_outlined),
        label: 'Mi tienda',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite_outline),
        label: 'Favoritos',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Perfil',
      ),
    ];

    return BlocProvider(
      create: (_) => NavCubit(),
      child: BlocBuilder<NavCubit, int>(
        builder: (context, index) {
          return Scaffold(
            appBar: AppBar(title: const Text('Punto Lector')),
            body: IndexedStack(index: index, children: pages),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: index,
              onTap: context.read<NavCubit>().setTab,
              type: BottomNavigationBarType.fixed,
              items: items,
            ),
          );
        },
      ),
    );
  }
}
