import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginEmail extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginEmail(this.email, this.password);
}

class AuthSignupEmail extends AuthEvent {
  final String email;
  final String password;
  const AuthSignupEmail(this.email, this.password);
}

class AuthLoginGoogle extends AuthEvent {}

class AuthLogout extends AuthEvent {}
