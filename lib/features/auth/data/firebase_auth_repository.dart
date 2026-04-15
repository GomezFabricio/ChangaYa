import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:changaya/features/auth/data/firebase_user_mapper.dart';
import 'package:changaya/features/auth/domain/auth_failure.dart';
import 'package:changaya/features/auth/domain/auth_repository.dart';
import 'package:changaya/features/auth/domain/user.dart';

/// Implementación de [AuthRepository] usando Firebase Auth + Google Sign-In.
///
/// Única clase que puede importar `firebase_auth`. La capa de dominio
/// y presentación NO deben tener este import directo.
///
/// Mapea [fb.FirebaseAuthException] a variantes de [AuthFailure].
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository({
    required fb.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  // ---------------------------------------------------------------------------
  // Estado de autenticación
  // ---------------------------------------------------------------------------

  @override
  Stream<User?> get authStateChanges {
    // NOTA: usamos `userChanges()` en lugar de `authStateChanges()` porque el
    // primero también emite cuando cambian propiedades del user (como
    // `emailVerified` tras `reloadUser()`), no solo en sign-in/sign-out. Esto
    // es necesario para que el guard chain de GoRouter re-evalúe el redirect
    // después de la verificación de email. Ver docs/troubleshooting.md.
    return _firebaseAuth.userChanges().map(
          (fbUser) =>
              fbUser != null ? FirebaseUserMapper.toDomain(fbUser) : null,
        );
  }

  @override
  User? get currentUser {
    final fbUser = _firebaseAuth.currentUser;
    return fbUser != null ? FirebaseUserMapper.toDomain(fbUser) : null;
  }

  // ---------------------------------------------------------------------------
  // Autenticación con email/password
  // ---------------------------------------------------------------------------

  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return FirebaseUserMapper.toDomain(credential.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<User> registerWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;
      if (name != null && name.isNotEmpty) {
        await fbUser.updateDisplayName(name);
      }
      return FirebaseUserMapper.toDomain(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In (plataforma-aware)
  // ---------------------------------------------------------------------------

  @override
  Future<User> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // En web: Firebase Auth popup — no requiere google_sign_in package.
        final userCredential = await _firebaseAuth.signInWithPopup(
          fb.GoogleAuthProvider(),
        );
        return FirebaseUserMapper.toDomain(userCredential.user!);
      }

      // Mobile (Android / iOS): flujo google_sign_in → credential → Firebase.
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // Usuario canceló el flujo
        throw AuthFailure.operationNotAllowed();
      }
      final auth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return FirebaseUserMapper.toDomain(userCredential.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Email verification
  // ---------------------------------------------------------------------------

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    final futures = <Future<void>>[_firebaseAuth.signOut()];
    // En web el usuario no firmó con google_sign_in, no hay sesión que cerrar.
    if (!kIsWeb) {
      futures.add(_googleSignIn.signOut());
    }
    await Future.wait(futures);
  }

  // ---------------------------------------------------------------------------
  // Reload user
  // ---------------------------------------------------------------------------

  @override
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      // Fuerza refresh del ID token para propagar `emailVerified` al
      // currentUser local. Sin esto, Firebase Auth Android puede devolver
      // el valor stale en la primera lectura post-reload (requeriría un
      // segundo tap del user). Ver docs/troubleshooting.md.
      await _firebaseAuth.currentUser?.getIdToken(true);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Mapeo de excepciones Firebase → AuthFailure de dominio
  // ---------------------------------------------------------------------------

  AuthFailure _mapException(fb.FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-email' =>
        AuthFailure.invalidCredential(),
      'email-already-in-use' => AuthFailure.emailAlreadyInUse(),
      'network-request-failed' => AuthFailure.networkError(),
      'too-many-requests' => AuthFailure.tooManyRequests(),
      'user-disabled' => AuthFailure.userDisabled(),
      'weak-password' => AuthFailure.weakPassword(),
      'operation-not-allowed' => AuthFailure.operationNotAllowed(),
      _ => AuthFailure.unknown(e.code),
    };
  }
}
