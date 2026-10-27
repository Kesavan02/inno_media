import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthSessionEvent extends AuthEvent {}

class LoginSubmittedEvent extends AuthEvent {
  final String mobile;
  final String password;

  const LoginSubmittedEvent({
    required this.mobile,
    required this.password,
  });

  @override
  List<Object?> get props => [mobile, password];
}

class RegisterSubmittedEvent extends AuthEvent {
  final String fullName;
  final String mobile;
  final String password;
  final String email;

  const RegisterSubmittedEvent({
    required this.fullName,
    required this.mobile,
    required this.password,
    required this.email,
  });

  @override
  List<Object?> get props => [fullName, mobile, password, email];
}

class LogoutRequestedEvent extends AuthEvent {}
