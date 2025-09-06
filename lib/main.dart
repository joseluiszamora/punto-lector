import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/env.dart';
import 'core/routing/app_router.dart';
import 'core/supabase/supabase_client_provider.dart';
import 'data/repositories/auth_repository.dart';
import 'features/auth/state/auth_bloc.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseInit.init();
  runApp(const PuntoLectorApp());
}

class PuntoLectorApp extends StatelessWidget {
  const PuntoLectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepository(SupabaseInit.client);
    return MultiRepositoryProvider(
      providers: [RepositoryProvider<IAuthRepository>.value(value: authRepo)],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(authRepo)..add(const AuthStarted()),
          ),
        ],
        child: MaterialApp(
          title: Env.appName,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          initialRoute: '/',
          onGenerateRoute: onGenerateRoute,
        ),
      ),
    );
  }
}
