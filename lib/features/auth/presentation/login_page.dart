import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/routing/app_router.dart' as r;
import '../../auth/state/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          state.maybeWhen(
            authenticated:
                (_) =>
                    Navigator.pushReplacementNamed(context, r.AppRoutes.home),
            orElse: () {},
          );
        },
        builder: (context, state) {
          final loading = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      loading
                          ? null
                          : () => context.read<AuthBloc>().add(
                            const SignInWithGoogle(),
                          ),
                  icon: const Icon(Icons.login),
                  label: const Text('Continuar con Google'),
                ),
                if (state is AuthError) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
