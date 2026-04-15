import 'package:changaya/features/auth/domain/user.dart';

/// Interface abstracta para el repositorio de autenticación.
///
/// Define el contrato que la capa de datos debe implementar.
/// Sin imports de Firebase — pertenece a la capa de dominio.
///
/// Implementada por `FirebaseAuthRepository` en la capa de datos.
abstract interface class AuthRepository {
  // ---------------------------------------------------------------------------
  // Estado de autenticación
  // ---------------------------------------------------------------------------

  /// Stream que emite el usuario actual cuando el estado de auth cambia.
  /// Emite `null` cuando el usuario cierra sesión.
  /// keepAlive: siempre activo (no se descarta con autoDispose).
  Stream<User?> get authStateChanges;

  /// Retorna el usuario actualmente autenticado, o `null` si no hay sesión.
  User? get currentUser;

  // ---------------------------------------------------------------------------
  // Métodos de autenticación
  // ---------------------------------------------------------------------------

  /// Inicia sesión con email y contraseña.
  ///
  /// Lanza [AuthFailure.invalidCredential] si las credenciales son incorrectas.
  /// Lanza [AuthFailure.tooManyRequests] si se excedió el límite de intentos.
  /// Lanza [AuthFailure.networkError] si no hay conexión.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  /// Inicia sesión con cuenta de Google (OAuth 2.0).
  ///
  /// Lanza [AuthFailure.operationNotAllowed] si Google no está habilitado.
  /// Lanza [AuthFailure.networkError] si no hay conexión.
  Future<User> signInWithGoogle();

  /// Registra un nuevo usuario con email y contraseña.
  ///
  /// Lanza [AuthFailure.emailAlreadyInUse] si el email ya está registrado.
  /// Lanza [AuthFailure.weakPassword] si la contraseña es demasiado débil.
  Future<User> registerWithEmail({
    required String email,
    required String password,
    String? name,
  });

  // ---------------------------------------------------------------------------
  // Verificación de email
  // ---------------------------------------------------------------------------

  /// Envía un email de verificación al usuario actual.
  ///
  /// Implementar con cooldown de 60s en el notifier de presentación (ADR-D04).
  Future<void> sendEmailVerification();

  // ---------------------------------------------------------------------------
  // Recuperación de contraseña
  // ---------------------------------------------------------------------------

  /// Envía un email de recuperación de contraseña.
  ///
  /// Usa mensaje genérico para no revelar si el email existe (RF-05).
  Future<void> sendPasswordResetEmail({required String email});

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  /// Cierra sesión. Limpia estado de Firebase Auth y Google Sign-In.
  Future<void> signOut();

  // ---------------------------------------------------------------------------
  // Reload user
  // ---------------------------------------------------------------------------

  /// Recarga el estado del usuario desde Firebase Auth (fuerza refresh del token).
  ///
  /// Usar cuando el usuario afirma haber verificado su email para que
  /// [authStateChanges] emita el estado actualizado con emailVerified=true.
  Future<void> reloadUser();
}
