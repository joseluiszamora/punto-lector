import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/routing/app_router.dart' as r;
import '../../auth/state/auth_bloc.dart';
import '../../../data/repositories/books_repository.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../books/application/books_bloc.dart';
import '../../books/presentation/search_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto Lector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed:
                () => Navigator.pushNamed(context, r.AppRoutes.storesMap),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed:
                () => context.read<AuthBloc>().add(const SignOutRequested()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: BlocProvider(
          create: (_) => BooksBloc(BooksRepository(SupabaseInit.client)),
          child: const SingleChildScrollView(child: BookSearchSection()),
        ),
      ),
    );
  }
}
