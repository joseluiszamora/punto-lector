import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puntolector/core/supabase/supabase_client_provider.dart';
import 'package:puntolector/data/repositories/books_repository.dart';
import 'package:puntolector/features/books/application/books_bloc.dart';
import 'package:puntolector/features/books/presentation/search_section.dart';

class SearchBookPage extends StatelessWidget {
  const SearchBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => BooksRepository(SupabaseInit.client),
      child: BlocProvider(
        create: (ctx) => BooksBloc(ctx.read<BooksRepository>()),
        child: Scaffold(
          appBar: AppBar(title: const Text('Buscar libros')),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: const BookSearchSection(),
            ),
          ),
        ),
      ),
    );
  }
}
