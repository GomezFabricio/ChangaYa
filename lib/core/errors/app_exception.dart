/// Clase base sealed para todos los errores del dominio de ChangaYa.
///
/// Todas las excepciones del dominio extienden [AppException].
/// Al ser sealed, se puede usar switch exhaustivo para manejarlas.
sealed class AppException implements Exception {
  const AppException({this.message, this.code});

  /// Mensaje legible por el usuario (en español).
  final String? message;

  /// Código de error interno para diagnóstico.
  final String? code;

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Errores relacionados con autenticación (RF-01 a RF-07).
final class AuthFailure extends AppException {
  const AuthFailure({super.message, super.code});
}

/// Errores relacionados con el perfil de usuario (RF-06).
final class ProfileFailure extends AppException {
  const ProfileFailure({super.message, super.code});
}
