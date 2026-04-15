import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/profile/data/firestore_profile_repository.dart';
import 'package:changaya/features/profile/domain/profile_repository.dart';
import 'package:changaya/features/profile/domain/user_profile.dart';

part 'profile_providers.g.dart';

// ---------------------------------------------------------------------------
// Infraestructura — Firestore
// ---------------------------------------------------------------------------

/// Proveedor de la instancia de [FirebaseFirestore].
///
/// keepAlive: true — instancia singleton.
@Riverpod(keepAlive: true)
FirebaseFirestore firebaseFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

/// Proveedor de la instancia de [FirebaseStorage].
///
/// keepAlive: true — instancia singleton.
@Riverpod(keepAlive: true)
FirebaseStorage firebaseStorage(Ref ref) {
  return FirebaseStorage.instance;
}

// ---------------------------------------------------------------------------
// Repositorio de perfil
// ---------------------------------------------------------------------------

/// Proveedor del [ProfileRepository].
///
/// keepAlive: true — el repositorio persiste durante toda la sesión.
@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return FirestoreProfileRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
}

// ---------------------------------------------------------------------------
// Stream reactivo del perfil
// ---------------------------------------------------------------------------

/// Stream del perfil del usuario autenticado actualmente.
///
/// Requiere que haya un usuario autenticado (uid de [authStateChangesProvider]).
/// Emite [UserProfile] cuando el documento existe, `null` si no.
/// keepAlive: true — suscripción permanente para el guard chain de GoRouter.
@Riverpod(keepAlive: true)
Stream<UserProfile?> userProfile(Ref ref) {
  final authStateAsync = ref.watch(authStateChangesProvider);

  return authStateAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(profileRepositoryProvider).watchProfile(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
}
