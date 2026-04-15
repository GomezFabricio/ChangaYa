import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:changaya/features/auth/domain/user.dart';

/// Mapper entre [fb.User] (Firebase Auth) y la entidad de dominio [User].
///
/// Solo lógica de mapeo — CERO lógica de negocio.
/// [onboardingComplete] siempre es `false` aquí porque ese campo
/// viene de Firestore (UserProfile), no de Firebase Auth.
/// Los providers combinan ambos después de obtener el perfil.
abstract final class FirebaseUserMapper {
  /// Convierte un [fb.User] de Firebase Auth en la entidad de dominio [User].
  ///
  /// Nunca retorna null — si [firebaseUser] existe, existe el [User].
  static User toDomain(fb.User firebaseUser) {
    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      // onboardingComplete no existe en firebase_auth.User.
      // Se combina con UserProfile.onboardingComplete en el provider de auth.
      onboardingComplete: false,
      providers:
          firebaseUser.providerData.map((info) => info.providerId).toList(),
    );
  }
}
