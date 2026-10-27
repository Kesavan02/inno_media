class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'An unexpected server error occurred']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Failed to access local cache']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Authentication failed']);
}

class RateLimitException implements Exception {
  final String message;
  final Duration retryAfter;
  const RateLimitException([
    this.message = 'Rate limit exceeded. Please wait a moment before trying again.',
    this.retryAfter = const Duration(seconds: 3),
  ]);
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;
  const ValidationException(this.message, [this.fieldErrors]);
}
