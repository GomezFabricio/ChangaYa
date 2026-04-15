/// Sealed class que representa los posibles fallos del feature de auth.
///
/// Cada variante mapea a un error code de Firebase Auth o a un estado
/// de error de red/sistema. Los mensajes están en español para el usuario.
///
/// Sin imports de Firebase — pertenece a la capa de dominio.
sealed class AuthFailure implements Exception {
  const AuthFailure({this.message, this.code});

  /// Mensaje legible por el usuario en español.
  final String? message;

  /// Código de error (alineado con Firebase Auth error codes).
  final String? code;

  // ---------------------------------------------------------------------------
  // Factory constructors para cada variante
  // ---------------------------------------------------------------------------

  /// Credencial inválida (email o contraseña incorrectos).
  /// Mensaje genérico para no revelar qué campo está mal (RF-03).
  factory AuthFailure.invalidCredential() => const _InvalidCredential();

  /// El email ya está registrado con otro proveedor.
  factory AuthFailure.emailAlreadyInUse() => const _EmailAlreadyInUse();

  /// Error de red — sin conexión a internet.
  factory AuthFailure.networkError() => const _NetworkError();

  /// Demasiados intentos fallidos — cuenta temporalmente bloqueada.
  factory AuthFailure.tooManyRequests() => const _TooManyRequests();

  /// Cuenta de usuario deshabilitada por el administrador.
  factory AuthFailure.userDisabled() => const _UserDisabled();

  /// Contraseña demasiado débil (no cumple los requisitos mínimos).
  factory AuthFailure.weakPassword() => const _WeakPassword();

  /// Operación no permitida (proveedor no habilitado en Firebase Console).
  factory AuthFailure.operationNotAllowed() => const _OperationNotAllowed();

  /// Error desconocido o no mapeado.
  factory AuthFailure.unknown([String? originalCode]) => _Unknown(originalCode);

  @override
  String toString() => 'AuthFailure(code: $code, message: $message)';
}

// ---------------------------------------------------------------------------
// Variantes privadas (implementaciones de la sealed class)
// ---------------------------------------------------------------------------

final class _InvalidCredential extends AuthFailure {
  const _InvalidCredential()
      : super(
          code: 'invalid-credential',
          message: 'Email o contraseña incorrectos.',
        );
}

final class _EmailAlreadyInUse extends AuthFailure {
  const _EmailAlreadyInUse()
      : super(
          code: 'email-already-in-use',
          message: 'Ya existe una cuenta con este email.',
        );
}

final class _NetworkError extends AuthFailure {
  const _NetworkError()
      : super(
          code: 'network-request-failed',
          message: 'Sin conexión a internet. Verificá tu red.',
        );
}

final class _TooManyRequests extends AuthFailure {
  const _TooManyRequests()
      : super(
          code: 'too-many-requests',
          message:
              'Demasiados intentos. Tu cuenta fue bloqueada temporalmente.',
        );
}

final class _UserDisabled extends AuthFailure {
  const _UserDisabled()
      : super(
          code: 'user-disabled',
          message: 'Esta cuenta fue suspendida. Contactá soporte.',
        );
}

final class _WeakPassword extends AuthFailure {
  const _WeakPassword()
      : super(
          code: 'weak-password',
          message: 'La contraseña debe tener al menos 6 caracteres.',
        );
}

final class _OperationNotAllowed extends AuthFailure {
  const _OperationNotAllowed()
      : super(
          code: 'operation-not-allowed',
          message: 'Esta operación no está habilitada.',
        );
}

final class _Unknown extends AuthFailure {
  const _Unknown(this._originalCode)
      : super(
          code: 'unknown',
          message: 'Ocurrió un error inesperado.',
        );

  final String? _originalCode;

  @override
  String toString() =>
      'AuthFailure(code: unknown, originalCode: $_originalCode)';
}
