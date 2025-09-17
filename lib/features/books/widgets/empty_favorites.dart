import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puntolector/features/auth/state/auth_bloc.dart';

class EmptyFavorites extends StatelessWidget {
  const EmptyFavorites({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! Authenticated) {
      return const Center(child: Text('Inicia sesión para ver tus favoritos'));
    }
    return const Center(child: Text('Aún no tienes favoritos'));
  }
}
