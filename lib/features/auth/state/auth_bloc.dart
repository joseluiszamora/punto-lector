import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/app_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(const AuthState.initial()) {
    on<AuthStarted>(_onStarted);
    on<SignInWithGoogle>(_onGoogle);
    on<SignOutRequested>(_onSignOut);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    await emit.forEach<AppUser?>(
      _repo.authStateChanges(),
      onData: (user) {
        if (user != null) return AuthState.authenticated(user);
        return const AuthState.unauthenticated();
      },
      onError: (_, __) => const AuthState.error('Error de autenticación'),
    );
  }

  Future<void> _onGoogle(
    SignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthState.loading());
      await _repo.signInWithGoogle();
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.signOut();
  }
}
