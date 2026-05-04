// core/error/exceptions.dart

class ServerException implements Exception {
  final String message;
  final int statusCode;

  const ServerException({
    required this.message,
    this.statusCode = 500,
  });

  @override
  String toString() => 'ServerException(message: $message, statusCode: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache operation failed'});

  @override
  String toString() => 'CacheException(message: $message)';
}

class AuthException implements Exception {
  final String message;

  const AuthException({this.message = 'Authentication failed'});

  @override
  String toString() => 'AuthException(message: $message)';
}
