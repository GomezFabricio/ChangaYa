# Design: I-02 Auth + Onboarding Cliente

**Change**: `auth-onboarding`
**Status**: designed
**Date**: 2026-04-13
**Author**: sdd-design agent
**Stack**: Flutter 3.41.6 + Dart 3.x + Riverpod 3.3.1 + GoRouter 17.2.x + Firebase Auth 6.x + Cloud Functions v2

---

## 1. Directory Structure -- Complete File Listing

Every file that must be created or modified, grouped by layer.

### 1.1 App Bootstrap

```
lib/
  main.dart                           # CREATE -- default entry (prod)
  main_dev.dart                       # CREATE -- dev entry (emulators)
  main_prod.dart                      # CREATE -- explicit prod entry
  app/
    app.dart                          # CREATE -- ProviderScope + MaterialApp.router
    app_config.dart                   # CREATE -- environment enum + emulator ports
    routes.dart                       # CREATE -- GoRouter + redirect chain
    theme.dart                        # CREATE -- Material 3 theme
```

### 1.2 Core Scaffolding

```
lib/core/
  errors/
    app_exception.dart                # CREATE -- base sealed class
    auth_exceptions.dart              # CREATE -- auth-specific failures
  constants/
    firestore_paths.dart              # CREATE -- collection/doc path constants
    app_constants.dart                # CREATE -- cooldown timers, limits
  widgets/
    primary_button.dart               # CREATE -- reusable CTA button
    loading_overlay.dart              # CREATE -- full-screen loading
```

### 1.3 Feature: Auth

```
lib/features/auth/
  domain/
    entities/
      user.dart                       # CREATE -- User domain entity
    repositories/
      auth_repository.dart            # CREATE -- abstract interface
  data/
    repositories/
      firebase_auth_repository.dart   # CREATE -- implements AuthRepository
    mappers/
      firebase_user_mapper.dart       # CREATE -- firebase_auth.User -> User
  presentation/
    providers/
      auth_providers.dart             # CREATE -- authState, signIn, register, etc.
      auth_providers.g.dart           # GENERATED -- riverpod_generator output
    screens/
      login_screen.dart               # CREATE -- P-04
      register_screen.dart            # CREATE -- P-05
      verify_email_screen.dart        # CREATE -- P-06
      forgot_password_screen.dart     # CREATE -- P-07
    widgets/
      social_sign_in_button.dart      # CREATE -- Google sign-in button
      auth_text_field.dart            # CREATE -- styled TextField for auth forms
```

### 1.4 Feature: Profile (Onboarding)

```
lib/features/profile/
  domain/
    entities/
      user_profile.dart               # CREATE -- UserProfile domain entity
    repositories/
      profile_repository.dart         # CREATE -- abstract interface
  data/
    repositories/
      firestore_profile_repository.dart  # CREATE -- implements ProfileRepository
    models/
      user_profile_model.dart         # CREATE -- Firestore serialization
  presentation/
    providers/
      profile_providers.dart          # CREATE -- userProfile, onboarding state
      profile_providers.g.dart        # GENERATED -- riverpod_generator output
    screens/
      complete_profile_screen.dart    # CREATE -- P-08
    widgets/
      locality_selector.dart          # CREATE -- dropdown/search Formosa localidades
      phone_input.dart                # CREATE -- AR phone field
      avatar_picker.dart              # CREATE -- optional photo picker
```

### 1.5 Cloud Function

```
functions/src/
  auth/
    on-user-create.ts                 # CREATE -- Auth trigger onCreate
  index.ts                            # MODIFY -- add export
```

### 1.6 Tests

```
test/
  unit/
    features/
      auth/
        domain/
          user_entity_test.dart             # CREATE
        data/
          firebase_auth_repository_test.dart # CREATE
        presentation/
          auth_providers_test.dart           # CREATE
      profile/
        domain/
          user_profile_entity_test.dart      # CREATE
        data/
          firestore_profile_repository_test.dart # CREATE
        presentation/
          profile_providers_test.dart        # CREATE
    app/
      routes_redirect_test.dart             # CREATE -- guard logic unit tests
  widget/
    screens/
      login_screen_test.dart                # CREATE
      register_screen_test.dart             # CREATE
      verify_email_screen_test.dart         # CREATE
      complete_profile_screen_test.dart     # CREATE
  helpers/
    test_helpers.dart                       # CREATE -- mock setup, pump helpers
    mock_auth_repository.dart              # CREATE -- @GenerateMocks
    mock_profile_repository.dart           # CREATE -- @GenerateMocks

functions/src/auth/
  on-user-create.test.ts                   # CREATE -- Jest test
```

### 1.7 Modified Files

```
pubspec.yaml                          # MODIFY -- add google_sign_in ^6.2.1
functions/src/index.ts                # MODIFY -- export onUserCreate
```

---

## 2. Data Models

### 2.1 User Entity (Domain -- `lib/features/auth/domain/entities/user.dart`)

This is the app's own `User` -- **NOT** `firebase_auth.User`. Firebase types stay in `data/`.

```dart
/// Domain entity representing an authenticated user.
/// Independent of Firebase -- mapped from firebase_auth.User in data layer.
class User {
  const User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    required this.emailVerified,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final bool emailVerified;

  /// Whether the user has a verified email address.
  /// Used by GoRouter redirect to gate onboarding flow.
  bool get isEmailVerified => emailVerified;

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          photoURL == other.photoURL &&
          emailVerified == other.emailVerified;

  @override
  int get hashCode => Object.hash(uid, email, displayName, photoURL, emailVerified);

  @override
  String toString() => 'User(uid: $uid, email: $email, emailVerified: $emailVerified)';
}
```

### 2.2 UserProfile Entity (Domain -- `lib/features/profile/domain/entities/user_profile.dart`)

```dart
/// Domain entity for user profile data stored in Firestore.
/// Separate from auth User -- represents the `users/{uid}` document.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    required this.phone,
    required this.locality,
    required this.role,
    required this.onboardingComplete,
    required this.emailVerified,
    this.suspendedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String phone;
  final String locality;
  final String role; // 'client' | 'provider' | 'admin'
  final bool onboardingComplete;
  final bool emailVerified;
  final DateTime? suspendedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// True when phone + locality are filled and onboarding flag is set.
  bool get isOnboardingComplete => onboardingComplete;

  /// True when user is currently suspended.
  bool get isSuspended =>
      suspendedUntil != null && suspendedUntil!.isAfter(DateTime.now());

  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    String? phone,
    String? locality,
    bool? onboardingComplete,
    bool? emailVerified,
    DateTime? suspendedUntil,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phone: phone ?? this.phone,
      locality: locality ?? this.locality,
      role: role,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      emailVerified: emailVerified ?? this.emailVerified,
      suspendedUntil: suspendedUntil ?? this.suspendedUntil,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          onboardingComplete == other.onboardingComplete &&
          phone == other.phone &&
          locality == other.locality;

  @override
  int get hashCode => Object.hash(uid, onboardingComplete, phone, locality);
}
```

### 2.3 Firestore Document Schemas

#### `users/{uid}`

```
{
  uid: string,                        // matches Auth UID
  email: string,                      // from Auth, synced by onUserCreate
  displayName: string,                // from Auth or user input
  photoURL: string | null,            // profile photo URL in Storage
  phone: string,                      // e.g. "+5493704123456"
  locality: string,                   // e.g. "Formosa Capital"
  role: "client" | "provider" | "admin",
  onboardingComplete: boolean,        // true once P-08 is submitted
  emailVerified: boolean,             // synced from Auth on relevant operations
  suspendedUntil: Timestamp | null,   // admin suspension
  createdAt: Timestamp,               // server timestamp
  updatedAt: Timestamp                // server timestamp
}
```

**Security**: Readable by any authenticated user. Writable only by owner or admin. Protected fields (`role`) only via Admin SDK in Cloud Functions.

#### `subscriptions/{uid}`

```
{
  uid: string,                        // matches Auth UID
  plan: "free" | "pro" | "trial",     // current plan
  status: "active" | "expired" | "cancelled",
  startDate: Timestamp | null,        // when pro/trial started
  endDate: Timestamp | null,          // when pro/trial expires
  mercadoPagoId: string | null,       // preapproval ID (Fase 2)
  createdAt: Timestamp,               // server timestamp
  updatedAt: Timestamp                // server timestamp
}
```

**Security**: Readable only by owner or admin. Writable only by Cloud Functions (`allow write: if false`).

---

## 3. Layer Design by Feature

### 3.1 Auth -- Domain Layer

**File: `lib/features/auth/domain/entities/user.dart`**
- `User` class as defined in section 2.1
- Immutable, pure Dart, no Firebase imports

**File: `lib/features/auth/domain/repositories/auth_repository.dart`**

```dart
import 'package:changaya/features/auth/domain/entities/user.dart';

/// Contract for authentication operations.
/// Implemented by FirebaseAuthRepository in data layer.
/// Consumed by Riverpod providers in presentation layer.
abstract class AuthRepository {
  /// Stream of auth state changes. Emits null on sign-out.
  Stream<User?> get authStateChanges;

  /// Current user, or null if not authenticated.
  User? get currentUser;

  /// Sign in with email and password.
  /// Throws [AuthException] on failure.
  Future<User> signInWithEmail(String email, String password);

  /// Sign in with Google OAuth.
  /// Throws [AuthException] on failure.
  Future<User> signInWithGoogle();

  /// Register with email, password, and display name.
  /// Throws [AuthException] on failure.
  Future<User> registerWithEmail(String email, String password, String name);

  /// Send email verification to current user.
  /// Throws [AuthException] if no user signed in.
  Future<void> sendEmailVerification();

  /// Send password reset email.
  /// Throws [AuthException] on failure.
  Future<void> sendPasswordResetEmail(String email);

  /// Reload the current user to refresh emailVerified status.
  /// Returns updated User or null.
  Future<User?> reloadUser();

  /// Sign out the current user.
  Future<void> signOut();
}
```

**File: `lib/core/errors/auth_exceptions.dart`**

```dart
/// Sealed class for auth-related failures.
/// Maps Firebase Auth error codes to domain exceptions.
sealed class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class InvalidEmailException extends AuthException {
  const InvalidEmailException() : super('El email ingresado no es valido.');
}

class WrongPasswordException extends AuthException {
  const WrongPasswordException() : super('La contrasena es incorrecta.');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException() : super('No existe una cuenta con ese email.');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException() : super('Ya existe una cuenta con ese email.');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException() : super('La contrasena es muy debil. Usa al menos 6 caracteres.');
}

class TooManyRequestsException extends AuthException {
  const TooManyRequestsException() : super('Demasiados intentos. Intenta de nuevo en unos minutos.');
}

class GoogleSignInCancelledException extends AuthException {
  const GoogleSignInCancelledException() : super('Inicio de sesion con Google cancelado.');
}

class UnknownAuthException extends AuthException {
  const UnknownAuthException([String message = 'Error de autenticacion inesperado.'])
      : super(message);
}
```

### 3.2 Auth -- Data Layer

**File: `lib/features/auth/data/mappers/firebase_user_mapper.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:changaya/features/auth/domain/entities/user.dart';

/// Maps firebase_auth.User to our domain User entity.
/// This is the ONLY place where firebase_auth types cross into domain types.
extension FirebaseUserMapper on firebase.User {
  User toDomain() {
    return User(
      uid: uid,
      email: email ?? '',
      displayName: displayName ?? '',
      photoURL: photoURL,
      emailVerified: emailVerified,
    );
  }
}
```

**File: `lib/features/auth/data/repositories/firebase_auth_repository.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:changaya/core/errors/auth_exceptions.dart';
import 'package:changaya/features/auth/data/mappers/firebase_user_mapper.dart';
import 'package:changaya/features/auth/domain/entities/user.dart';
import 'package:changaya/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required firebase.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  final firebase.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(
      (firebaseUser) => firebaseUser?.toDomain(),
    );
  }

  @override
  User? get currentUser => _firebaseAuth.currentUser?.toDomain();

  @override
  Future<User> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!.toDomain();
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const GoogleSignInCancelledException();
      }
      final googleAuth = await googleUser.authentication;
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user!.toDomain();
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<User> registerWithEmail(String email, String password, String name) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);
      // Reload to get updated profile
      await credential.user!.reload();
      final updatedUser = _firebaseAuth.currentUser!;
      // Send verification email automatically on registration
      await updatedUser.sendEmailVerification();
      return updatedUser.toDomain();
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const UnknownAuthException('No hay usuario autenticado.');
    }
    try {
      await user.sendEmailVerification();
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<User?> reloadUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _firebaseAuth.currentUser?.toDomain();
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Maps Firebase Auth error codes to domain exceptions.
  AuthException _mapFirebaseException(firebase.FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => const InvalidEmailException(),
      'wrong-password' ||
      'invalid-credential' => const WrongPasswordException(),
      'user-not-found' => const UserNotFoundException(),
      'email-already-in-use' => const EmailAlreadyInUseException(),
      'weak-password' => const WeakPasswordException(),
      'too-many-requests' => const TooManyRequestsException(),
      _ => UnknownAuthException('${e.message} (${e.code})'),
    };
  }
}
```

**Key design decisions for data layer:**
- `FirebaseAuthRepository` receives `FirebaseAuth` and `GoogleSignIn` via constructor injection -- testable
- The mapper extension (`FirebaseUserMapper`) is the ONLY file that imports both `firebase_auth` and domain `User`
- `signOut()` signs out from both Firebase and Google to prevent stale Google sessions
- `registerWithEmail` sends verification email automatically after registration
- `reloadUser()` is needed to refresh `emailVerified` status after user clicks email link

### 3.3 Auth -- Presentation Layer (Riverpod Providers)

**File: `lib/features/auth/presentation/providers/auth_providers.dart`**

All providers use Riverpod 3.x code generation (`@riverpod` / `@Riverpod(keepAlive: true)`).

```dart
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:changaya/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:changaya/features/auth/domain/entities/user.dart';
import 'package:changaya/features/auth/domain/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

// ──────────────────────────────────────────────────────────────
// Infrastructure providers (keepAlive -- global singletons)
// ──────────────────────────────────────────────────────────────

/// Provides the FirebaseAuth instance. Override in tests.
@Riverpod(keepAlive: true)
firebase.FirebaseAuth firebaseAuth(Ref ref) {
  return firebase.FirebaseAuth.instance;
}

/// Provides the GoogleSignIn instance. Override in tests.
@Riverpod(keepAlive: true)
GoogleSignIn googleSignIn(Ref ref) {
  return GoogleSignIn();
}

/// Provides the AuthRepository implementation.
/// Depends on firebaseAuth and googleSignIn providers.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
}

// ──────────────────────────────────────────────────────────────
// Auth state (keepAlive -- session-level, reactive)
// ──────────────────────────────────────────────────────────────

/// Stream of auth state changes. Used by GoRouter refreshListenable.
/// Emits null when signed out, User when signed in.
@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

// ──────────────────────────────────────────────────────────────
// Action providers (autoDispose -- used by screens)
// ──────────────────────────────────────────────────────────────

/// Sign in with email/password. Returns User on success.
@riverpod
Future<User> signInWithEmail(Ref ref, {required String email, required String password}) {
  return ref.read(authRepositoryProvider).signInWithEmail(email, password);
}

/// Sign in with Google. Returns User on success.
@riverpod
Future<User> signInWithGoogle(Ref ref) {
  return ref.read(authRepositoryProvider).signInWithGoogle();
}

/// Register with email/password/name. Returns User on success.
@riverpod
Future<User> registerWithEmail(
  Ref ref, {
  required String email,
  required String password,
  required String name,
}) {
  return ref.read(authRepositoryProvider).registerWithEmail(email, password, name);
}

/// Send password reset email.
@riverpod
Future<void> sendPasswordResetEmail(Ref ref, {required String email}) {
  return ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
}
```

**File: `lib/features/auth/presentation/providers/email_verification_provider.dart`**

```dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:changaya/features/auth/domain/entities/user.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';

part 'email_verification_provider.g.dart';

/// State for the email verification screen.
class EmailVerificationState {
  const EmailVerificationState({
    this.cooldownRemaining = 0,
    this.isSending = false,
    this.error,
  });

  final int cooldownRemaining;
  final bool isSending;
  final String? error;

  bool get canResend => cooldownRemaining == 0 && !isSending;

  EmailVerificationState copyWith({
    int? cooldownRemaining,
    bool? isSending,
    String? error,
  }) {
    return EmailVerificationState(
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

/// Manages email verification resend with 60s cooldown.
/// autoDispose -- only alive while P-06 is mounted.
@riverpod
class EmailVerification extends _$EmailVerification {
  Timer? _cooldownTimer;

  @override
  EmailVerificationState build() => const EmailVerificationState();

  /// Resend verification email with cooldown enforcement.
  Future<void> resendVerification() async {
    if (!state.canResend) return;
    state = state.copyWith(isSending: true, error: null);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      state = state.copyWith(isSending: false, cooldownRemaining: 60);
      _startCooldown();
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  /// Check if user has verified their email (poll after clicking link).
  Future<bool> checkVerified() async {
    final user = await ref.read(authRepositoryProvider).reloadUser();
    return user?.emailVerified ?? false;
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.cooldownRemaining - 1;
      if (remaining <= 0) {
        _cooldownTimer?.cancel();
        state = state.copyWith(cooldownRemaining: 0);
      } else {
        state = state.copyWith(cooldownRemaining: remaining);
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    // Note: Riverpod codegen Notifiers do NOT have a dispose method
    // by default. The timer cleanup happens via ref.onDispose in build():
    // ref.onDispose(() => _cooldownTimer?.cancel());
    // This will be handled in the actual build() method.
  }
}
```

**Important Riverpod 3.x note**: In Riverpod 3.x with code generation, Notifier classes do NOT have a `dispose()` method. Timer cleanup must use `ref.onDispose()` inside `build()`:

```dart
@override
EmailVerificationState build() {
  ref.onDispose(() => _cooldownTimer?.cancel());
  return const EmailVerificationState();
}
```

### 3.4 Profile -- Domain Layer

**File: `lib/features/profile/domain/repositories/profile_repository.dart`**

```dart
import 'package:changaya/features/profile/domain/entities/user_profile.dart';

/// Contract for user profile operations in Firestore.
/// Implemented by FirestoreProfileRepository in data layer.
abstract class ProfileRepository {
  /// Get user profile from Firestore. Returns null if document doesn't exist.
  Future<UserProfile?> getProfile(String uid);

  /// Watch user profile for real-time updates.
  /// Used by GoRouter to reactively detect onboarding completion.
  Stream<UserProfile?> watchProfile(String uid);

  /// Update specific fields in the user profile document.
  /// Used by P-08 onboarding and future profile editing.
  Future<void> updateProfile(String uid, Map<String, dynamic> fields);

  /// Mark onboarding as complete. Sets onboardingComplete = true
  /// and updatedAt to server timestamp.
  Future<void> completeOnboarding(String uid);
}
```

### 3.5 Profile -- Data Layer

**File: `lib/features/profile/data/models/user_profile_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:changaya/features/profile/domain/entities/user_profile.dart';

/// Firestore serialization/deserialization for UserProfile.
/// Handles Timestamp <-> DateTime conversion.
class UserProfileModel {
  /// Create domain entity from Firestore document snapshot.
  static UserProfile fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      uid: data['uid'] as String,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoURL: data['photoURL'] as String?,
      phone: data['phone'] as String? ?? '',
      locality: data['locality'] as String? ?? '',
      role: data['role'] as String? ?? 'client',
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
      emailVerified: data['emailVerified'] as bool? ?? false,
      suspendedUntil: (data['suspendedUntil'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
```

**File: `lib/features/profile/data/repositories/firestore_profile_repository.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:changaya/core/constants/firestore_paths.dart';
import 'package:changaya/features/profile/data/models/user_profile_model.dart';
import 'package:changaya/features/profile/domain/entities/user_profile.dart';
import 'package:changaya/features/profile/domain/repositories/profile_repository.dart';

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserProfileModel.fromFirestore(doc);
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc);
    });
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> fields) async {
    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> completeOnboarding(String uid) async {
    await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .update({
      'onboardingComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

### 3.6 Profile -- Presentation Layer

**File: `lib/features/profile/presentation/providers/profile_providers.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/profile/data/repositories/firestore_profile_repository.dart';
import 'package:changaya/features/profile/domain/entities/user_profile.dart';
import 'package:changaya/features/profile/domain/repositories/profile_repository.dart';

part 'profile_providers.g.dart';

// ──────────────────────────────────────────────────────────────
// Infrastructure
// ──────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
FirebaseFirestore firebaseFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return FirestoreProfileRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

// ──────────────────────────────────────────────────────────────
// Profile state (keepAlive -- needed by GoRouter for redirect)
// ──────────────────────────────────────────────────────────────

/// Watches the current user's profile in real-time.
/// Emits null when: no auth user, or profile document doesn't exist yet.
/// keepAlive because GoRouter redirect depends on this.
@Riverpod(keepAlive: true)
Stream<UserProfile?> userProfile(Ref ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(authUser.uid);
}

// ──────────────────────────────────────────────────────────────
// Onboarding actions (autoDispose -- P-08 only)
// ──────────────────────────────────────────────────────────────

/// Saves onboarding data field by field (LinkedIn-style auto-save).
/// Each field is saved independently on confirmation.
@riverpod
Future<void> saveProfileField(
  Ref ref, {
  required String uid,
  required String field,
  required dynamic value,
}) async {
  await ref.read(profileRepositoryProvider).updateProfile(uid, {field: value});
}

/// Marks onboarding as complete.
@riverpod
Future<void> completeOnboarding(Ref ref, {required String uid}) async {
  await ref.read(profileRepositoryProvider).completeOnboarding(uid);
}
```

---

## 4. GoRouter Design

**File: `lib/app/routes.dart`**

### 4.1 Route Table

| Path | Screen | Auth Required | Notes |
|------|--------|:---:|-------|
| `/login` | LoginScreen (P-04) | No | Redirect to /home if already authed |
| `/register` | RegisterScreen (P-05) | No | Redirect to /home if already authed |
| `/verify-email` | VerifyEmailScreen (P-06) | Yes | Only if emailVerified == false |
| `/forgot-password` | ForgotPasswordScreen (P-07) | No | Accessible from login |
| `/complete-profile` | CompleteProfileScreen (P-08) | Yes | Only if onboardingComplete == false |
| `/home` | HomeScreen (stub) | Yes | Default logged-in destination |

### 4.2 Router Implementation

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:changaya/features/auth/domain/entities/user.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/profile/domain/entities/user_profile.dart';
import 'package:changaya/features/profile/presentation/providers/profile_providers.dart';
import 'package:changaya/features/auth/presentation/screens/login_screen.dart';
import 'package:changaya/features/auth/presentation/screens/register_screen.dart';
import 'package:changaya/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:changaya/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:changaya/features/profile/presentation/screens/complete_profile_screen.dart';

part 'routes.g.dart';

// ──────────────────────────────────────────────────────────────
// Route paths as constants (avoid magic strings)
// ──────────────────────────────────────────────────────────────

abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const completeProfile = '/complete-profile';
  static const home = '/home';

  /// Routes that don't require authentication.
  static const publicRoutes = [login, register, forgotPassword];
}

// ──────────────────────────────────────────────────────────────
// GoRouter provider
// ──────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Create a listenable that fires on auth state changes.
  // This triggers GoRouter's redirect re-evaluation.
  final authNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authNotifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home -- stub')),
        ),
      ),
    ],
  );
}

// ──────────────────────────────────────────────────────────────
// Redirect logic -- single callback, cascading evaluation
// ──────────────────────────────────────────────────────────────

/// Redirect chain evaluated on every navigation and auth state change.
/// Order: auth -> emailVerified -> onboardingComplete
///
/// Returns null to allow navigation, or a path to redirect.
String? _redirect(Ref ref, GoRouterState state) {
  final authAsync = ref.read(authStateProvider);
  final user = authAsync.valueOrNull;
  final isLoggedIn = user != null;
  final currentPath = state.matchedLocation;
  final isPublicRoute = AppRoutes.publicRoutes.contains(currentPath);

  // ── CASE 1: Not authenticated ──
  if (!isLoggedIn) {
    // Allow access to public routes
    if (isPublicRoute) return null;
    // Redirect everything else to login
    return AppRoutes.login;
  }

  // ── CASE 2: Authenticated but email NOT verified ──
  if (!user.emailVerified) {
    // Already on verify-email? Stay.
    if (currentPath == AppRoutes.verifyEmail) return null;
    // Redirect to verify-email
    return AppRoutes.verifyEmail;
  }

  // ── CASE 3: Email verified, check onboarding ──
  final profileAsync = ref.read(userProfileProvider);
  final profile = profileAsync.valueOrNull;

  if (profile != null && !profile.isOnboardingComplete) {
    // Already on complete-profile? Stay.
    if (currentPath == AppRoutes.completeProfile) return null;
    // Redirect to complete profile
    return AppRoutes.completeProfile;
  }

  // ── CASE 4: Fully authenticated + verified + onboarded ──
  // If trying to access public routes or onboarding screens, go home
  if (isPublicRoute ||
      currentPath == AppRoutes.verifyEmail ||
      currentPath == AppRoutes.completeProfile) {
    return AppRoutes.home;
  }

  // Allow navigation
  return null;
}

// ──────────────────────────────────────────────────────────────
// ChangeNotifier bridge for GoRouter refreshListenable
// ──────────────────────────────────────────────────────────────

/// Bridges Riverpod's auth state stream to GoRouter's ChangeNotifier
/// so redirect is re-evaluated when auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    // Listen to auth state changes
    _subscription = _ref
        .listen(authStateProvider, (_, __) => notifyListeners());
    // Also listen to profile changes (onboarding completion)
    _profileSubscription = _ref
        .listen(userProfileProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<User?>> _subscription;
  late final ProviderSubscription<AsyncValue<UserProfile?>> _profileSubscription;

  @override
  void dispose() {
    _subscription.close();
    _profileSubscription.close();
    super.dispose();
  }
}
```

### 4.3 Redirect Flow Diagram

```
Navigation request
       |
       v
  Is user logged in?
       |
    NO ──> Is route public? ──YES──> Allow
       |                     NO──> Redirect /login
    YES
       |
       v
  Is email verified?
       |
    NO ──> Already on /verify-email? ──YES──> Allow
       |                               NO──> Redirect /verify-email
    YES
       |
       v
  Is profile loaded? && Is onboarding complete?
       |
    NO ──> Already on /complete-profile? ──YES──> Allow
       |                                   NO──> Redirect /complete-profile
    YES
       |
       v
  Is route public/onboarding? ──YES──> Redirect /home
                                NO──> Allow
```

### 4.4 Important GoRouter 17.x Notes

- `refreshListenable` triggers `redirect` re-evaluation on auth changes
- The `redirect` callback is synchronous -- it reads `.valueOrNull` from `AsyncValue`, not awaiting futures
- When `authStateProvider` is still loading (first app launch), `valueOrNull` is null, so user sees login. Once auth resolves, redirect fires again via `refreshListenable`
- Profile stream (`userProfileProvider`) is also listened by `_AuthChangeNotifier` so completing onboarding triggers redirect to `/home`

---

## 5. App Bootstrap

### 5.1 AppConfig

**File: `lib/app/app_config.dart`**

```dart
/// Environment configuration passed to the App widget.
enum Environment { dev, prod }

class AppConfig {
  const AppConfig({required this.environment});

  final Environment environment;

  bool get useEmulators => environment == Environment.dev;

  // Emulator ports matching firebase.json
  static const authEmulatorPort = 9099;
  static const firestoreEmulatorPort = 8080;
  static const storageEmulatorPort = 9199;
  static const functionsEmulatorPort = 5001;
  static const emulatorHost = 'localhost'; // Android: '10.0.2.2'
}
```

### 5.2 main_dev.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:changaya/app/app.dart';
import 'package:changaya/app/app_config.dart';
import 'package:changaya/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Connect to Firebase Emulator Suite
  const host = AppConfig.emulatorHost;
  FirebaseAuth.instance.useAuthEmulator(host, AppConfig.authEmulatorPort);
  FirebaseFirestore.instance.useFirestoreEmulator(host, AppConfig.firestoreEmulatorPort);
  FirebaseStorage.instance.useStorageEmulator(host, AppConfig.storageEmulatorPort);

  runApp(const App(config: AppConfig(environment: Environment.dev)));
}
```

### 5.3 main_prod.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:changaya/app/app.dart';
import 'package:changaya/app/app_config.dart';
import 'package:changaya/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const App(config: AppConfig(environment: Environment.prod)));
}
```

### 5.4 main.dart (alias for prod)

```dart
import 'package:changaya/main_prod.dart' as prod;

Future<void> main() async => prod.main();
```

### 5.5 App Widget

**File: `lib/app/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changaya/app/app_config.dart';
import 'package:changaya/app/routes.dart';
import 'package:changaya/app/theme.dart';

class App extends StatelessWidget {
  const App({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _AppContent(config: config),
    );
  }
}

class _AppContent extends ConsumerWidget {
  const _AppContent({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ChangaYa',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: config.environment == Environment.dev,
    );
  }
}
```

### 5.6 Theme

**File: `lib/app/theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 theme built from a single color seed.
/// ChangaYa brand: warm orange (#FF6B35) as primary seed.
abstract class AppTheme {
  static const _seedColor = Color(0xFFFF6B35);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
```

---

## 6. Cloud Function `onUserCreate`

**File: `functions/src/auth/on-user-create.ts`**

```typescript
import { beforeUserCreated } from "firebase-functions/v2/identity";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";

/**
 * Auth trigger: fires when a new user is created in Firebase Auth.
 * Creates two documents:
 * 1. users/{uid} -- user profile with default values
 * 2. subscriptions/{uid} -- free plan subscription
 *
 * IDEMPOTENT: checks existence before writing to handle retries.
 * REGION: southamerica-east1 (same as Firestore).
 */
export const onUserCreate = beforeUserCreated(
  { region: "southamerica-east1" },
  async (event) => {
    const user = event.data;
    const db = getFirestore();

    const userRef = db.collection("users").doc(user.uid);
    const subscriptionRef = db.collection("subscriptions").doc(user.uid);

    // Idempotency check: if user doc already exists, skip
    const userDoc = await userRef.get();
    if (userDoc.exists) {
      logger.info(`User doc already exists for ${user.uid}, skipping.`);
      return;
    }

    const batch = db.batch();

    batch.set(userRef, {
      uid: user.uid,
      email: user.email ?? "",
      displayName: user.displayName ?? "",
      photoURL: user.photoURL ?? "",
      phone: "",
      locality: "",
      role: "client",
      onboardingComplete: false,
      emailVerified: user.emailVerified ?? false,
      suspendedUntil: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    batch.set(subscriptionRef, {
      uid: user.uid,
      plan: "free",
      status: "active",
      startDate: null,
      endDate: null,
      mercadoPagoId: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();
    logger.info(`Created user and subscription docs for ${user.uid}`);
  }
);
```

**IMPORTANT NOTE on trigger type**: The proposal uses `onAuthUserCreated` which is the v2 `identity` trigger (`beforeUserCreated`). However, if we want the function to run AFTER the user is created (not before/blocking), we should use the v1-style `functions.auth.user().onCreate()` or the v2 equivalent. Let me clarify:

- `beforeUserCreated` (v2 identity) runs BEFORE the user record is finalized -- can block/modify registration
- For our use case (creating Firestore docs after user creation), we want the non-blocking trigger

**Corrected approach using v2 event trigger:**

```typescript
import * as functions from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

// Note: As of firebase-functions v2, the auth event triggers use the
// firebase-functions/v1 API. v2 identity triggers (beforeUserCreated,
// beforeUserSignedIn) are blocking functions.
// For non-blocking onCreate, use v1 auth trigger:
import * as functionsV1 from "firebase-functions";

export const onUserCreate = functionsV1
  .region("southamerica-east1")
  .auth.user()
  .onCreate(async (user) => {
    const db = getFirestore();

    const userRef = db.collection("users").doc(user.uid);
    const subscriptionRef = db.collection("subscriptions").doc(user.uid);

    // Idempotency check
    const userDoc = await userRef.get();
    if (userDoc.exists) {
      logger.info(`User doc already exists for ${user.uid}, skipping.`);
      return;
    }

    const batch = db.batch();

    batch.set(userRef, {
      uid: user.uid,
      email: user.email ?? "",
      displayName: user.displayName ?? "",
      photoURL: user.photoURL ?? "",
      phone: "",
      locality: "",
      role: "client",
      onboardingComplete: false,
      emailVerified: user.emailVerified ?? false,
      suspendedUntil: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    batch.set(subscriptionRef, {
      uid: user.uid,
      plan: "free",
      status: "active",
      startDate: null,
      endDate: null,
      mercadoPagoId: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();
    logger.info(`Created user and subscription docs for ${user.uid}`);
  });
```

**File: `functions/src/index.ts`** (modified)

```typescript
import * as admin from "firebase-admin";

admin.initializeApp();

export { onUserCreate } from "./auth/on-user-create";
```

---

## 7. Core Scaffolding

### 7.1 Firestore Paths

**File: `lib/core/constants/firestore_paths.dart`**

```dart
/// Centralized Firestore collection and document paths.
/// Avoids magic strings scattered across repositories.
abstract class FirestorePaths {
  static const users = 'users';
  static const subscriptions = 'subscriptions';
  static const providers = 'providers';
  static const serviceRequests = 'service_requests';
  static const reviews = 'reviews';
  static const reports = 'reports';
  static const notifications = 'notifications';
  static const adminLog = 'admin_log';
  static const categories = 'categories';
}
```

### 7.2 App Constants

**File: `lib/core/constants/app_constants.dart`**

```dart
/// Application-wide constants.
abstract class AppConstants {
  /// Cooldown in seconds between email verification resends.
  static const emailVerificationCooldownSeconds = 60;

  /// Localidades de Formosa for the locality selector dropdown.
  static const formosaLocalidades = [
    'Formosa Capital',
    'Clorinda',
    'Pirané',
    'El Colorado',
    'Laguna Blanca',
    'Ibarreta',
    'Las Lomitas',
    'Ingeniero Juárez',
    'General Belgrano',
    'Herradura',
    'San Francisco de Laishí',
    'Villa 213',
    'Laguna Naineck',
    'Misión Tacaaglé',
    'Comandante Fontana',
    'Estanislao del Campo',
    'Pozo del Tigre',
    'General Güemes',
    'Palo Santo',
    'Gran Guardia',
  ];
}
```

### 7.3 Base Exception

**File: `lib/core/errors/app_exception.dart`**

```dart
/// Base sealed class for all application exceptions.
/// Each feature defines its own subclasses.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}
```

---

## 8. Testing Strategy

### 8.1 Approach by Layer

| Layer | Strategy | Tools | Coverage Target |
|-------|----------|-------|:---:|
| `auth/domain/` | Pure unit tests, no deps | flutter_test | 90% |
| `auth/data/` | Mock `FirebaseAuth` + `GoogleSignIn` | mockito | 80% |
| `auth/presentation/` (providers) | Override repository provider with mock | flutter_riverpod testing | 70% |
| `auth/presentation/` (screens) | Widget tests with mock providers | flutter_test + ProviderScope.overrides | 70% |
| `profile/domain/` | Pure unit tests | flutter_test | 90% |
| `profile/data/` | Mock `FirebaseFirestore` or use emulator | mockito / emulator | 80% |
| `profile/presentation/` | Widget tests with mock providers | flutter_test + ProviderScope.overrides | 70% |
| `app/routes.dart` (redirect) | Unit test the redirect function | flutter_test | 90% |
| Cloud Function | Jest + Firebase Emulator | jest + firebase-tools | 80% |

### 8.2 Mock Setup

**File: `test/helpers/mock_auth_repository.dart`**

```dart
import 'package:mockito/annotations.dart';
import 'package:changaya/features/auth/domain/repositories/auth_repository.dart';

@GenerateMocks([AuthRepository])
void main() {}
// Generates: mock_auth_repository.mocks.dart
```

**File: `test/helpers/mock_profile_repository.dart`**

```dart
import 'package:mockito/annotations.dart';
import 'package:changaya/features/profile/domain/repositories/profile_repository.dart';

@GenerateMocks([ProfileRepository])
void main() {}
// Generates: mock_profile_repository.mocks.dart
```

### 8.3 Testing Riverpod Providers

```dart
// Example: testing auth state provider with mock repository
void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  test('should_emit_user_when_signed_in', () async {
    final testUser = User(
      uid: 'test-uid',
      email: 'test@test.com',
      displayName: 'Test',
      photoURL: null,
      emailVerified: true,
    );

    when(mockAuthRepo.authStateChanges)
        .thenAnswer((_) => Stream.value(testUser));

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
    );

    // Wait for stream to emit
    await container.read(authStateProvider.future);

    final state = container.read(authStateProvider);
    expect(state.valueOrNull, testUser);

    container.dispose();
  });
}
```

### 8.4 Testing Widget Screens

```dart
// Example: LoginScreen widget test
void main() {
  testWidgets('should_show_error_when_wrong_password', (tester) async {
    final mockAuthRepo = MockAuthRepository();

    when(mockAuthRepo.signInWithEmail(any, any))
        .thenThrow(const WrongPasswordException());
    when(mockAuthRepo.authStateChanges)
        .thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    // Enter credentials
    await tester.enterText(find.byKey(const Key('email-field')), 'test@test.com');
    await tester.enterText(find.byKey(const Key('password-field')), 'wrong');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.text('La contrasena es incorrecta.'), findsOneWidget);
  });
}
```

### 8.5 Testing GoRouter Redirect

The redirect function `_redirect` should be extracted to a testable top-level function or made `@visibleForTesting`:

```dart
// In routes.dart -- make redirect testable
@visibleForTesting
String? resolveRedirect({
  required User? user,
  required UserProfile? profile,
  required String currentPath,
}) {
  // ... same logic as _redirect but receiving data directly
}
```

Test:

```dart
void main() {
  group('Router redirect', () {
    test('should_redirect_to_login_when_not_authenticated', () {
      final result = resolveRedirect(
        user: null,
        profile: null,
        currentPath: '/home',
      );
      expect(result, AppRoutes.login);
    });

    test('should_redirect_to_verify_email_when_not_verified', () {
      final result = resolveRedirect(
        user: User(uid: '1', email: 'a@b.c', displayName: '', photoURL: null, emailVerified: false),
        profile: null,
        currentPath: '/home',
      );
      expect(result, AppRoutes.verifyEmail);
    });

    test('should_redirect_to_complete_profile_when_onboarding_incomplete', () {
      final result = resolveRedirect(
        user: User(uid: '1', email: 'a@b.c', displayName: '', photoURL: null, emailVerified: true),
        profile: UserProfile(/* ... onboardingComplete: false ... */),
        currentPath: '/home',
      );
      expect(result, AppRoutes.completeProfile);
    });

    test('should_allow_home_when_fully_onboarded', () {
      final result = resolveRedirect(
        user: User(uid: '1', email: 'a@b.c', displayName: '', photoURL: null, emailVerified: true),
        profile: UserProfile(/* ... onboardingComplete: true ... */),
        currentPath: '/home',
      );
      expect(result, null); // null means allow
    });
  });
}
```

### 8.6 Cloud Function Test

**File: `functions/src/auth/on-user-create.test.ts`**

```typescript
import * as admin from "firebase-admin";
import { describe, it, expect, beforeAll, afterAll, beforeEach } from "@jest/globals";

// Initialize with emulator
process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "localhost:9099";

describe("onUserCreate", () => {
  let db: admin.firestore.Firestore;

  beforeAll(() => {
    admin.initializeApp({ projectId: "changaya-test" });
    db = admin.firestore();
  });

  afterAll(async () => {
    await admin.app().delete();
  });

  beforeEach(async () => {
    // Clean up test data
    const users = await db.collection("users").listDocuments();
    const subs = await db.collection("subscriptions").listDocuments();
    const batch = db.batch();
    [...users, ...subs].forEach((doc) => batch.delete(doc));
    await batch.commit();
  });

  it("should_create_user_doc_with_default_values", async () => {
    // Simulate: create user in Auth emulator, then verify
    // Firestore docs were created by the trigger.
    // In practice, use firebase-functions-test or the emulator directly.
    const uid = "test-user-123";

    // Create user via Auth emulator
    await admin.auth().createUser({
      uid,
      email: "test@example.com",
      displayName: "Test User",
    });

    // Wait for trigger to execute
    await new Promise((r) => setTimeout(r, 2000));

    const userDoc = await db.collection("users").doc(uid).get();
    expect(userDoc.exists).toBe(true);
    expect(userDoc.data()?.role).toBe("client");
    expect(userDoc.data()?.onboardingComplete).toBe(false);
    expect(userDoc.data()?.phone).toBe("");
    expect(userDoc.data()?.locality).toBe("");

    const subDoc = await db.collection("subscriptions").doc(uid).get();
    expect(subDoc.exists).toBe(true);
    expect(subDoc.data()?.plan).toBe("free");
    expect(subDoc.data()?.status).toBe("active");
  });

  it("should_be_idempotent_on_duplicate_execution", async () => {
    const uid = "test-user-456";

    // Pre-create user doc
    await db.collection("users").doc(uid).set({
      uid,
      email: "existing@example.com",
      displayName: "Existing",
      phone: "123456",
      locality: "Formosa",
      role: "client",
      onboardingComplete: true,
      emailVerified: true,
    });

    // Create auth user (triggers onUserCreate)
    await admin.auth().createUser({
      uid,
      email: "existing@example.com",
    });

    await new Promise((r) => setTimeout(r, 2000));

    // Verify original data was NOT overwritten
    const userDoc = await db.collection("users").doc(uid).get();
    expect(userDoc.data()?.phone).toBe("123456");
    expect(userDoc.data()?.onboardingComplete).toBe(true);
  });
});
```

---

## 9. Implementation Order

Dependencies determine order. Tasks marked with `||` can be parallelized.

```
Phase 1: Foundation (BLOCKING -- everything depends on this)
  1.1 pubspec.yaml -- add google_sign_in ^6.2.1
  1.2 lib/core/errors/app_exception.dart
  1.3 lib/core/errors/auth_exceptions.dart
  1.4 lib/core/constants/firestore_paths.dart
  1.5 lib/core/constants/app_constants.dart

Phase 2: App Bootstrap (BLOCKING -- app must run before features)
  2.1 lib/app/app_config.dart
  2.2 lib/app/theme.dart
  2.3 lib/app/app.dart (stub router)
  2.4 lib/main.dart, lib/main_dev.dart, lib/main_prod.dart
  => CHECKPOINT: flutter run -t lib/main_dev.dart must launch

Phase 3: Cloud Function (CAN PARALLEL with Phase 4)
  3.1 functions/src/auth/on-user-create.ts
  3.2 functions/src/index.ts (add export)
  3.3 functions/src/auth/on-user-create.test.ts
  => CHECKPOINT: firebase emulators:start + create user = docs exist

Phase 4: Auth Feature -- Domain + Data (CAN PARALLEL with Phase 3)
  4.1 lib/features/auth/domain/entities/user.dart
  4.2 lib/features/auth/domain/repositories/auth_repository.dart
  4.3 test/unit/features/auth/domain/user_entity_test.dart
  4.4 lib/features/auth/data/mappers/firebase_user_mapper.dart
  4.5 lib/features/auth/data/repositories/firebase_auth_repository.dart
  4.6 test/helpers/mock_auth_repository.dart
  4.7 test/unit/features/auth/data/firebase_auth_repository_test.dart

Phase 5: Auth Feature -- Presentation (DEPENDS ON Phase 4)
  5.1 lib/features/auth/presentation/providers/auth_providers.dart
  5.2 dart run build_runner build (generate .g.dart)
  5.3 lib/features/auth/presentation/providers/email_verification_provider.dart
  5.4 dart run build_runner build (generate .g.dart)
  5.5 lib/features/auth/presentation/widgets/auth_text_field.dart
  5.6 lib/features/auth/presentation/widgets/social_sign_in_button.dart
  5.7 lib/features/auth/presentation/screens/login_screen.dart (P-04)
  5.8 lib/features/auth/presentation/screens/register_screen.dart (P-05)
  5.9 lib/features/auth/presentation/screens/verify_email_screen.dart (P-06)
  5.10 lib/features/auth/presentation/screens/forgot_password_screen.dart (P-07)
  5.11 test/widget/screens/login_screen_test.dart
  5.12 test/widget/screens/register_screen_test.dart
  5.13 test/widget/screens/verify_email_screen_test.dart
  5.14 test/unit/features/auth/presentation/auth_providers_test.dart

Phase 6: Profile Feature (DEPENDS ON Phase 4 for auth state)
  6.1 lib/features/profile/domain/entities/user_profile.dart
  6.2 lib/features/profile/domain/repositories/profile_repository.dart
  6.3 lib/features/profile/data/models/user_profile_model.dart
  6.4 lib/features/profile/data/repositories/firestore_profile_repository.dart
  6.5 lib/features/profile/presentation/providers/profile_providers.dart
  6.6 dart run build_runner build (generate .g.dart)
  6.7 lib/features/profile/presentation/widgets/locality_selector.dart
  6.8 lib/features/profile/presentation/widgets/phone_input.dart
  6.9 lib/features/profile/presentation/widgets/avatar_picker.dart
  6.10 lib/features/profile/presentation/screens/complete_profile_screen.dart (P-08)
  6.11 test/unit/features/profile/domain/user_profile_entity_test.dart
  6.12 test/helpers/mock_profile_repository.dart
  6.13 test/unit/features/profile/data/firestore_profile_repository_test.dart
  6.14 test/unit/features/profile/presentation/profile_providers_test.dart
  6.15 test/widget/screens/complete_profile_screen_test.dart

Phase 7: Routing Guards (DEPENDS ON Phase 5 + Phase 6)
  7.1 lib/app/routes.dart (full redirect logic)
  7.2 dart run build_runner build (generate .g.dart)
  7.3 test/unit/app/routes_redirect_test.dart
  => CHECKPOINT: full flow works end-to-end

Phase 8: Core Widgets (CAN PARALLEL with Phase 5+)
  8.1 lib/core/widgets/primary_button.dart
  8.2 lib/core/widgets/loading_overlay.dart

Phase 9: Final Validation
  9.1 flutter analyze (zero warnings)
  9.2 dart format . (all formatted)
  9.3 flutter test (all pass)
  9.4 cd functions && npm run lint && npm test
```

### Dependency Graph (Phases)

```
Phase 1 ──> Phase 2 ──> Phase 5 ──> Phase 7 ──> Phase 9
                 \                    /
                  > Phase 4 ────────/
                 /         \       /
Phase 3 ───────/            > Phase 6
                                  |
Phase 8 ────────────────────────(parallel)
```

---

## 10. Screen Specifications (Brief)

### P-04 Login Screen
- Email + password fields
- "Iniciar sesion" button
- "Iniciar con Google" button (social_sign_in_button.dart)
- "Olvidaste tu contrasena?" link -> /forgot-password
- "Crear cuenta" link -> /register
- Error display inline (below form)
- Loading state on buttons during auth

### P-05 Register Screen
- Name + Email + Password + Confirm Password fields
- "Crear cuenta" button
- "Iniciar con Google" button
- "Ya tengo cuenta" link -> /login
- Password strength indicator (min 6 chars)
- Auto-sends verification email on success

### P-06 Verify Email Screen
- Message: "Te enviamos un email de verificacion a {email}"
- "Reenviar email" button with 60s cooldown timer
- "Ya verifique mi email" button -> calls reloadUser() -> redirects if verified
- "Cerrar sesion" option
- No back navigation (guard prevents it)

### P-07 Forgot Password Screen
- Email field
- "Enviar email de recuperacion" button
- Success confirmation message
- "Volver al login" link

### P-08 Complete Profile Screen
- Phone input (AR format, +54 prefix)
- Locality selector (dropdown from AppConstants.formosaLocalidades)
- Avatar picker (optional -- camera or gallery)
- "Completar perfil" button
- Each field auto-saves on confirmation (LinkedIn pattern)
- Completes onboarding flag on final submit

---

## 11. Key ADRs from this Design

### ADR-D01: v1 Auth Trigger for onUserCreate

**Decision**: Use `functions.auth.user().onCreate()` (v1 trigger) instead of v2 `beforeUserCreated` blocking function.

**Rationale**: `beforeUserCreated` is a blocking identity trigger that runs BEFORE the user record is finalized. It can reject registration. We want a non-blocking trigger that fires AFTER successful registration to create Firestore documents. As of firebase-functions v4.9.x, the non-blocking auth event trigger still uses the v1 API pattern with `.region()`.

**Consequence**: The function uses `firebase-functions` v1 API for this specific trigger. Other Cloud Functions (Firestore triggers, HTTP, scheduled) will use v2 API.

### ADR-D02: Redirect Function Extracted for Testing

**Decision**: Extract the GoRouter redirect logic into a pure function `resolveRedirect` that receives data (User?, UserProfile?, currentPath) and returns a redirect path or null.

**Rationale**: GoRouter's `redirect` callback has access to `Ref` which makes it hard to test. Extracting the decision logic into a pure function allows unit testing all redirect scenarios without GoRouter or Riverpod.

### ADR-D03: Profile Stream (watchProfile) for GoRouter Reactivity

**Decision**: `userProfileProvider` uses `watchProfile` (Firestore snapshot listener) instead of a one-time `getProfile` future.

**Rationale**: GoRouter's `refreshListenable` needs to fire when `onboardingComplete` changes from false to true. A stream-based provider with snapshot listener achieves this reactively. The stream is kept alive (`keepAlive: true`) because GoRouter depends on it globally.

**Tradeoff**: One extra Firestore listener per session. Acceptable for a single document read.

### ADR-D04: Timer Cleanup via ref.onDispose

**Decision**: In Riverpod 3.x code-generated Notifiers, use `ref.onDispose()` inside `build()` instead of overriding `dispose()`.

**Rationale**: `@riverpod` generated Notifier classes do not expose a `dispose()` method. The lifecycle hook is `ref.onDispose(() => ...)` called during `build()`. This is the idiomatic Riverpod 3.x pattern.

---

## 12. Dependency Checklist

### pubspec.yaml Changes

```yaml
# Add under dependencies:
  google_sign_in: ^6.2.1
```

### No Other Dependency Changes

All other packages (`firebase_auth`, `cloud_firestore`, `flutter_riverpod`, `riverpod_annotation`, `go_router`, `flutter_form_builder`, `form_builder_validators`, `google_fonts`, `shared_preferences`, `mockito`, `build_runner`, `riverpod_generator`) are already in `pubspec.yaml` at the correct versions.

---

## Summary

| Aspect | Count |
|--------|:-----:|
| Files to CREATE | ~45 |
| Files to MODIFY | 2 (pubspec.yaml, functions/src/index.ts) |
| Domain entities | 2 (User, UserProfile) |
| Repository interfaces | 2 (AuthRepository, ProfileRepository) |
| Repository implementations | 2 (FirebaseAuthRepository, FirestoreProfileRepository) |
| Riverpod providers | ~12 (infra + state + action) |
| Screens | 5 (P-04 through P-08) + Home stub |
| Cloud Functions | 1 (onUserCreate) |
| GoRouter routes | 6 |
| Test files | ~12 |
| New dependencies | 1 (google_sign_in) |
| Implementation phases | 9 |
| ADRs (design-level) | 4 |
