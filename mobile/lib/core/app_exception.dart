class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class AuthenticationRequiredException extends AppException {
  const AuthenticationRequiredException() : super('Please log in to continue.');
}
