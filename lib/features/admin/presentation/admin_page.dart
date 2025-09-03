import 'package:flutter/material.dart';
import 'books/books_admin_list_page.dart';
import 'categories/categories_admin_list_page.dart';
import 'authors/authors_admin_list_page.dart';
import 'stores/stores_admin_list_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BooksAdminListPage(),
                      ),
                    ),
                icon: const Icon(Icons.menu_book),
                label: const Text('Admin Libros'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CategoriesAdminListPage(),
                      ),
                    ),
                icon: const Icon(Icons.category),
                label: const Text('Admin Categorias'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AuthorsAdminListPage(),
                      ),
                    ),
                icon: const Icon(Icons.person_outline),
                label: const Text('Admin Autores'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StoresAdminListPage(),
                      ),
                    ),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Admin Tiendas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
