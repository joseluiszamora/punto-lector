import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puntolector/features/books/book_lists_page.dart';
import 'package:puntolector/features/books/presentation/search_book_page.dart';
import 'package:puntolector/features/maps/map_page.dart';
import '../../core/navigation/nav_cubit.dart';
import '../books/presentation/search_section.dart';
import '../stores/presentation/stores_map_page.dart';
import '../favorites/presentation/favorites_page.dart';
import '../profile/presentation/profile_page.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../data/repositories/books_repository.dart';
import '../books/application/books_bloc.dart';
import '../stores/presentation/my_store_page.dart';
import '../admin/presentation/admin_page.dart';
import '../auth/state/auth_bloc.dart';
import '../../data/models/user_role.dart';

class RootNavPage extends StatelessWidget {
  const RootNavPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is Authenticated && authState.user.role.isAdmin;
    final isStoreManager =
        authState is Authenticated && authState.user.role.isStoreManager;
    final isUser = authState is Authenticated && authState.user.role.isUser;

    final pages = [
      // Todos los Libros
      const BookListsPage(),
      // Libros
      const SearchBookPage(),
      // Tiendas (mapa)
      // const StoresMapPage(),
      // Mi tienda (administración)
      if (isStoreManager) const MyStorePage(),
      // Favoritos
      if (isUser) const FavoritesPage(),
      // Perfil
      const ProfilePage(),
      if (isAdmin) const AdminPage(),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_outlined),
        label: 'Todos',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_outlined),
        label: 'Libros',
      ),
      // const BottomNavigationBarItem(
      //   icon: Icon(Icons.store_mall_directory_outlined),
      //   label: 'Tiendas',
      // ),
      if (isStoreManager)
        const BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          label: 'Mi tienda',
        ),
      if (isUser)
        const BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          label: 'Favoritos',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Perfil',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          label: 'Admin',
        ),
    ];

    return BlocProvider(
      create: (_) => NavCubit(),
      child: BlocBuilder<NavCubit, int>(
        builder: (context, index) {
          final safeIndex = index >= pages.length ? pages.length - 1 : index;
          return Scaffold(
            // appBar: AppBar(title: const Text('Punto Lector')),
            body: IndexedStack(index: safeIndex, children: pages),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: safeIndex,
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
