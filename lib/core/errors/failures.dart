import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server operation failed']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache operation failed']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class RateLimitFailure extends Failure {
  final Duration retryAfter;
  const RateLimitFailure([
    super.message = 'Too many requests. Please slow down.',
    this.retryAfter = const Duration(seconds: 3),
  ]);

  @override
  List<Object?> get props => [message, retryAfter];
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  const ValidationFailure(super.message, [this.fieldErrors]);

  @override
  List<Object?> get props => [message, fieldErrors];
}
