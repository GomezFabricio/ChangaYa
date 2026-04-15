import 'package:changaya/features/profile/domain/user_profile.dart';

/// Modelo de datos para serializar/deserializar [UserProfile] desde/hacia Firestore.
///
/// Corresponde al documento `users/{uid}` en Firestore.
///
/// Solo lógica de mapeo — CERO lógica de negocio.
/// La lógica de negocio vive en [UserProfile] (dominio).
class UserProfileModel {
  const UserProfileModel({
    required this.uid,
    required this.displayName,
    required this.onboardingComplete,
    this.phone,
    this.localidad,
    this.photoURL,
  });

  final String uid;
  final String displayName;
  final String? phone;
  final String? localidad;
  final String? photoURL;
  final bool onboardingComplete;

  // ---------------------------------------------------------------------------
  // Firestore deserialization
  // ---------------------------------------------------------------------------

  /// Crea un [UserProfileModel] desde un mapa de Firestore.
  ///
  /// [data] es el mapa `Map<String,dynamic>` del documento.
  /// [uid] es el ID del documento — se usa si no está en el mapa.
  factory UserProfileModel.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    return UserProfileModel(
      uid: (data['uid'] as String?) ?? uid,
      displayName: (data['displayName'] as String?) ?? '',
      phone: data['phone'] as String?,
      localidad: data['locality'] as String?,
      photoURL: data['photoURL'] as String?,
      onboardingComplete: (data['onboardingComplete'] as bool?) ?? false,
    );
  }

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  /// Serializa este modelo a un mapa compatible con Firestore.
  ///
  /// Incluye campos null para soportar `SetOptions(merge: true)` en Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'phone': phone,
      'locality': localidad,
      'photoURL': photoURL,
      'onboardingComplete': onboardingComplete,
    };
  }

  // ---------------------------------------------------------------------------
  // Domain ↔ Model conversion
  // ---------------------------------------------------------------------------

  /// Crea un [UserProfileModel] desde la entidad de dominio [UserProfile].
  factory UserProfileModel.fromDomain(UserProfile profile) {
    return UserProfileModel(
      uid: profile.uid,
      displayName: profile.displayName,
      phone: profile.phone,
      localidad: profile.localidad,
      photoURL: profile.photoURL,
      onboardingComplete: profile.onboardingComplete,
    );
  }

  /// Convierte este model a la entidad de dominio [UserProfile].
  UserProfile toDomain() {
    return UserProfile(
      uid: uid,
      displayName: displayName,
      phone: phone,
      localidad: localidad,
      photoURL: photoURL,
      onboardingComplete: onboardingComplete,
    );
  }
}
