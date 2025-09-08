part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class SignInWithGoogle extends AuthEvent {
  const SignInWithGoogle();
}

class SignInWithEmailPassword extends AuthEvent {
  final String email;
  final String password;
  const SignInWithEmailPassword(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class SignUpWithEmailPassword extends AuthEvent {
  final String email;
  final String password;
  final String? name;
  final String? nationalityId;
  const SignUpWithEmailPassword(
    this.email,
    this.password, {
    this.name,
    this.nationalityId,
  });
  @override
  List<Object?> get props => [email, password, name, nationalityId];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
