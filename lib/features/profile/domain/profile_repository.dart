import 'package:image_picker/image_picker.dart';
import 'package:changaya/features/profile/domain/user_profile.dart';

/// Interface abstracta para el repositorio de perfiles de usuario.
///
/// Define el contrato que la capa de datos debe implementar.
/// Usa [XFile] de `image_picker` para el upload de foto de perfil.
///
/// Implementada por `FirestoreProfileRepository` en la capa de datos.
abstract interface class ProfileRepository {
  /// Obtiene el perfil del usuario por UID.
  ///
  /// Retorna `null` si el documento no existe en Firestore.
  Future<UserProfile?> getProfile(String uid);

  /// Actualiza el perfil del usuario en Firestore.
  ///
  /// Hace merge de los campos — no sobreescribe campos no incluidos.
  Future<void> updateProfile(UserProfile profile);

  /// Stream reactivo del perfil del usuario.
  ///
  /// Emite el perfil actualizado cuando Firestore cambia.
  /// Emite `null` si el documento no existe.
  /// Usado por GoRouter para re-evaluar el guard chain (ADR-D03).
  Stream<UserProfile?> watchProfile(String uid);

  /// Sube una foto de perfil a Firebase Storage.
  ///
  /// Ruta de storage: `profiles/{uid}/avatar.jpg`
  /// Valida tipo de archivo (JPEG/PNG/WebP) y tamaño (≤5MB) antes de subir.
  /// Comprime la imagen a 1024px máximo, 80% calidad.
  ///
  /// Retorna la URL de descarga pública de la foto subida.
  Future<String> uploadProfilePhoto(String uid, XFile photo);
}
