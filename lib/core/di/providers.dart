import 'package:flutter_bloc/flutter_bloc.dart';
import '../supabase/supabase_client_provider.dart';
import '../../data/repositories/auth_repository.dart';

class AppProviders {
  static RepositoryProvider<IAuthRepository> authRepo() =>
      RepositoryProvider<IAuthRepository>(
        create: (_) => AuthRepository(SupabaseInit.client),
      );
}
