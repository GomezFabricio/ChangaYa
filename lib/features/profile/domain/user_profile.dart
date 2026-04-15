/// Entidad de dominio [UserProfile] — representa el perfil del usuario en Firestore.
///
/// Corresponde al documento `users/{uid}` en Firestore.
/// CERO imports de Firebase — pertenece a la capa de dominio.
///
/// Mapeada desde/hacia Firestore en la capa de datos
/// mediante `UserProfileModel`.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.onboardingComplete,
    this.phone,
    this.localidad,
    this.photoURL,
  });

  /// Identificador único del usuario (mismo que Firebase Auth uid).
  final String uid;

  /// Nombre de pantalla del usuario.
  final String displayName;

  /// Teléfono normalizado a 10 dígitos (código de área + número, sin +54).
  /// Nullable hasta que el usuario complete el onboarding (P-08).
  final String? phone;

  /// Localidad dentro de Formosa (e.g. 'Formosa Capital', 'Clorinda').
  /// Nullable hasta que el usuario complete el onboarding (P-08).
  final String? localidad;

  /// URL de la foto de perfil (opcional — no requerida para isComplete).
  final String? photoURL;

  /// True si el usuario completó el onboarding (P-08).
  final bool onboardingComplete;

  // ---------------------------------------------------------------------------
  // Getters de conveniencia
  // ---------------------------------------------------------------------------

  /// True si el perfil tiene todos los campos obligatorios del onboarding:
  /// - [displayName] no vacío
  /// - [phone] no nulo
  /// - [localidad] no nulo
  ///
  /// [photoURL] es opcional — no forma parte del criterio de completitud.
  bool get isComplete =>
      displayName.isNotEmpty && phone != null && localidad != null;

  // ---------------------------------------------------------------------------
  // Normalización de teléfono
  // ---------------------------------------------------------------------------

  /// Normaliza un número de teléfono argentino a 10 dígitos sin separadores.
  ///
  /// Reglas:
  /// - Remueve espacios, guiones y paréntesis
  /// - Remueve prefijo +54 o 54 si está al inicio
  /// - Retorna los dígitos restantes (no trunca a 10 — la validación es externa)
  ///
  /// Ejemplos:
  /// - '0362 412 3456' → '03624123456'
  /// - '0362-412-3456' → '03624123456'
  /// - '+5403624123456' → '03624123456'
  static String normalizePhone(String phone) {
    // Remover todos los caracteres no numéricos excepto +
    String normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Remover prefijo +54 o +549
    if (normalized.startsWith('+549')) {
      normalized = normalized.substring(4);
    } else if (normalized.startsWith('+54')) {
      normalized = normalized.substring(3);
    } else if (normalized.startsWith('549')) {
      normalized = normalized.substring(3);
    }

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Retorna una nueva instancia con los campos especificados actualizados.
  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? phone,
    String? localidad,
    String? photoURL,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      localidad: localidad ?? this.localidad,
      photoURL: photoURL ?? this.photoURL,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  // ---------------------------------------------------------------------------
  // Igualdad por uid
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'UserProfile(uid: $uid, displayName: $displayName, '
      'phone: $phone, localidad: $localidad, '
      'onboardingComplete: $onboardingComplete)';
}
