import 'package:flutter/material.dart';
import 'books/books_admin_list_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Center(
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
            const Text('admin'),
          ],
        ),
      ),
    );
  }
}
