import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:changaya/features/auth/data/firebase_auth_repository.dart';
import 'package:changaya/features/auth/domain/auth_repository.dart';
import 'package:changaya/features/auth/domain/user.dart';

part 'auth_providers.g.dart';

// ---------------------------------------------------------------------------
// Infraestructura — Firebase Auth + GoogleSignIn
// ---------------------------------------------------------------------------

/// Proveedor de la instancia de [fb.FirebaseAuth].
///
/// keepAlive: true — instancia singleton para toda la app.
@Riverpod(keepAlive: true)
fb.FirebaseAuth firebaseAuth(Ref ref) {
  return fb.FirebaseAuth.instance;
}

/// Proveedor de [GoogleSignIn].
///
/// keepAlive: true — instancia singleton.
/// En web se pasa un clientId stub — el flujo real usa signInWithPopup.
@Riverpod(keepAlive: true)
GoogleSignIn googleSignIn(Ref ref) {
  if (kIsWeb) {
    // google_sign_in_web requiere un clientId no-null para inicializarse.
    // En web el sign-in real usa FirebaseAuth.signInWithPopup — este
    // objeto existe solo para satisfacer la interface del repositorio.
    return GoogleSignIn(clientId: 'web-not-used');
  }
  return GoogleSignIn();
}

// ---------------------------------------------------------------------------
// Repositorio de autenticación
// ---------------------------------------------------------------------------

/// Proveedor del [AuthRepository].
///
/// keepAlive: true — el repositorio debe persistir durante toda la sesión.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
}

// ---------------------------------------------------------------------------
// Estado de autenticación (stream reactivo)
// ---------------------------------------------------------------------------

/// Stream del usuario autenticado actualmente.
///
/// Emite [User] cuando hay sesión activa, `null` cuando no.
/// keepAlive: true — suscripción permanente, no se cancela al desmontar widgets.
@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}
