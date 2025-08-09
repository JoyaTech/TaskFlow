import 'package:equatable/equatable.dart';

/// Abstract base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final String code;

  const Failure({
    required this.message,
    required this.code,
  });

  @override
  List<Object> get props => [message, code];
}

/// Failure for server/network related errors
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String code = 'SERVER_ERROR',
  }) : super(message: message, code: code);
}

/// Failure for local storage/cache related errors
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String code = 'CACHE_ERROR',
  }) : super(message: message, code: code);
}

/// Failure for network connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'No internet connection',
    String code = 'NETWORK_ERROR',
  }) : super(message: message, code: code);
}

/// Failure for validation errors
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String code = 'VALIDATION_ERROR',
  }) : super(message: message, code: code);
}

/// Failure for authentication/authorization errors
class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    String code = 'AUTH_ERROR',
  }) : super(message: message, code: code);
}

/// Failure for permission related errors
class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    String code = 'PERMISSION_ERROR',
  }) : super(message: message, code: code);
}

/// Generic failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    String message = 'An unexpected error occurred',
    String code = 'UNEXPECTED_ERROR',
  }) : super(message: message, code: code);
}
