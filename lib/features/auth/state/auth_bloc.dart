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
    on<RequireProfileCompletion>(_onRequireProfileCompletion);
    on<UpdateProfileRequested>(_onUpdateProfile);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    await emit.forEach<AppUser?>(
      _repo.authStateChanges(),
      onData: (user) {
        if (user != null) {
          // No podemos hacer async aquí; emitimos provisionalmente y dejamos que UI redirija según Splash o evento explícito
          return AuthState.authenticated(user);
        }
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
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onRequireProfileCompletion(
    RequireProfileCompletion event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.requireProfileCompletion());
  }

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthState.loading());
      await _repo.updateCurrentUserProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        nationalityId: event.nationalityId,
      );
      final isComplete = await _repo.isCurrentUserProfileComplete();
      if (isComplete) {
        final user = _repo.currentUser;
        if (user != null) {
          emit(AuthState.authenticated(user));
          return;
        }
      }
      emit(const AuthState.requireProfileCompletion());
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
