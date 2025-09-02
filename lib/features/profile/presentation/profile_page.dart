import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/state/auth_bloc.dart';
import '../../../core/routing/app_router.dart' as r;

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final text =
        authState is Authenticated
            ? 'Sesión iniciada: ${authState.user.email}'
            : 'No has iniciado sesión';

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is Unauthenticated,
      listener: (ctx, state) {
        Navigator.of(
          ctx,
        ).pushNamedAndRemoveUntil(r.AppRoutes.login, (route) => false);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text),
              const SizedBox(height: 16),
              if (authState is Authenticated)
                Text('Rol de usuario: ${authState.user.role}'),
              const SizedBox(height: 16),
              if (authState is Authenticated)
                ElevatedButton(
                  onPressed:
                      () => context.read<AuthBloc>().add(
                        const SignOutRequested(),
                      ),
                  child: const Text('Cerrar sesión'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
