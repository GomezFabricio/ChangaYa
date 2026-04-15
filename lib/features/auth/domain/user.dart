/// Entidad de dominio [User] — representa al usuario autenticado.
///
/// CERO imports de Firebase, Flutter o Riverpod.
/// Solo Dart puro. Esta es la capa de dominio del feature auth.
///
/// Mapeada desde `firebase_auth.User` en la capa de datos
/// mediante `FirebaseUserMapper`.
class User {
  const User({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.onboardingComplete,
    required this.providers,
    this.displayName,
    this.photoURL,
  });

  /// Identificador único del usuario en Firebase Auth.
  final String uid;

  /// Email del usuario.
  final String email;

  /// Nombre de pantalla (puede ser null para registro email/password sin configurar).
  final String? displayName;

  /// URL de foto de perfil (puede ser null).
  final String? photoURL;

  /// True si el email fue verificado.
  final bool emailVerified;

  /// True si el usuario completó el onboarding (P-08).
  final bool onboardingComplete;

  /// Lista de proveedores de identidad (e.g. ['google.com'], ['password']).
  final List<String> providers;

  // ---------------------------------------------------------------------------
  // Getters de conveniencia
  // ---------------------------------------------------------------------------

  /// Alias de [onboardingComplete]. True si el onboarding está completo.
  bool get isOnboarded => onboardingComplete;

  /// True si el usuario se autenticó con Google OAuth.
  bool get hasGoogleProvider => providers.contains('google.com');

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Retorna una nueva instancia con los campos especificados actualizados.
  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    bool? onboardingComplete,
    List<String>? providers,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      providers: providers ?? this.providers,
    );
  }

  // ---------------------------------------------------------------------------
  // Igualdad por uid (identidad del usuario)
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'User(uid: $uid, email: $email, '
      'emailVerified: $emailVerified, onboardingComplete: $onboardingComplete, '
      'providers: $providers)';
}
