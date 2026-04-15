import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/profile/domain/profile_repository.dart';
import 'package:changaya/features/profile/domain/user_profile.dart';
import 'package:changaya/features/profile/presentation/providers/profile_providers.dart';

part 'save_profile_notifier.g.dart';

/// Notifier para guardar cambios de perfil y subir foto.
///
/// autoDispose: se descarta cuando ningún widget lo observa.
/// Los errores se propagan como [AsyncError] en el estado.
@riverpod
class SaveProfileNotifier extends _$SaveProfileNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  /// Guarda el perfil del usuario en Firestore.
  ///
  /// Actualiza el estado a [AsyncLoading] durante la operación.
  /// En caso de error, actualiza a [AsyncError] con la excepción.
  Future<void> saveProfile(UserProfile profile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.updateProfile(profile),
    );
  }

  /// Sube una foto de perfil a Firebase Storage.
  ///
  /// [photo] es el archivo seleccionado desde `image_picker`.
  /// Retorna la URL de descarga si es exitoso.
  ///
  /// Si la subida es exitosa, actualiza también el perfil en Firestore
  /// para persistir la nueva [photoURL].
  Future<String?> uploadPhoto(XFile photo) async {
    final authAsync = ref.read(authStateChangesProvider);
    final uid = authAsync.value?.uid;

    if (uid == null) {
      state = AsyncError(
        Exception('No hay usuario autenticado para subir foto.'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading();

    try {
      final url = await _repository.uploadProfilePhoto(uid, photo);

      // Actualizar el perfil en Firestore con la nueva photoURL
      final currentProfile = await _repository.getProfile(uid);
      if (currentProfile != null) {
        await _repository.updateProfile(
          currentProfile.copyWith(photoURL: url),
        );
      }

      state = const AsyncData(null);
      return url;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
