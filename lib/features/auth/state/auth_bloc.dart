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
    on<SignInWithEmailPassword>(_onEmailSignIn);
    on<SignUpWithEmailPassword>(_onEmailSignUp);
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

  Future<void> _onEmailSignIn(
    SignInWithEmailPassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthState.loading());
      await _repo.signInWithEmailPassword(event.email, event.password);
      // el stream actualizará el estado
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onEmailSignUp(
    SignUpWithEmailPassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthState.loading());
      await _repo.signUpWithEmailPassword(
        event.email,
        event.password,
        name: event.name,
        nationalityId: event.nationalityId,
      );
      // Si Supabase requiere verificación por correo, mantendremos al usuario como no autenticado hasta confirmar
      emit(const AuthState.unauthenticated());
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
