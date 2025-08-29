part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];

  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(AppUser user) = Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.error(String message) = AuthError;

  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(AppUser user)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
  }) {
    final s = this;
    if (s is AuthInitial) return initial?.call();
    if (s is AuthLoading) return loading?.call();
    if (s is Authenticated) return authenticated?.call(s.user);
    if (s is Unauthenticated) return unauthenticated?.call();
    if (s is AuthError) return error?.call(s.message);
    return null;
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(AppUser user)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    return whenOrNull(
          initial: initial,
          loading: loading,
          authenticated: authenticated,
          unauthenticated: unauthenticated,
          error: error,
        ) ??
        orElse();
  }
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final AppUser user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
