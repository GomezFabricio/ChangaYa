# Proposal: I-02 Auth + Onboarding Cliente

**Change**: `auth-onboarding`
**Status**: proposed
**Date**: 2026-04-13
**Author**: sdd-propose agent

---

## 1. Intent

Construir el sistema completo de autenticacion y onboarding del cliente para ChangaYa. Este es el PRIMER feature funcional del producto — sin auth no existe nada mas. El objetivo es que un usuario pueda:

1. Registrarse (email/password o Google OAuth)
2. Verificar su email
3. Completar su perfil de cliente (telefono, localidad, foto opcional)
4. Iniciar sesion en futuras visitas con sesion persistente
5. Recuperar su contrasena si la olvida

Esto habilita todo el flujo downstream: busqueda, solicitudes, mensajes, resenas.

## 2. Scope

### INCLUIDO

- **App bootstrap**: `main.dart`, `main_dev.dart`, `main_prod.dart`, `App` widget, tema, routing base
- **Feature auth completo** (`lib/features/auth/`):
  - Domain: `User` entity, `AuthRepository` abstract, use cases
  - Data: `FirebaseAuthRepository` implementation
  - Presentation: providers (Riverpod 3.x con code generation), pantallas P-04 a P-07
- **Feature profile/onboarding** (`lib/features/profile/`):
  - Domain: `UserProfile` entity, `ProfileRepository` abstract
  - Data: `FirestoreProfileRepository` implementation
  - Presentation: pantalla P-08 (completar datos cliente)
- **Core scaffolding**: `lib/core/errors/`, `lib/core/constants/`, `lib/core/widgets/` (solo lo necesario)
- **Cloud Function `onUserCreate`**: Auth trigger que crea `users/{uid}` + `subscriptions/{uid}` con plan `free`
- **Dependencia `google_sign_in`**: agregar a `pubspec.yaml`
- **Routing con guards**: GoRouter 17.x con redirect logic para email verification y onboarding completion
- **Tests unitarios**: repositories (mock), providers, use cases
- **Tests de widget**: pantallas criticas (login, registro)

### NO INCLUIDO

- Panel admin (I-06)
- Perfil de provider / flujo de "convertirse en provider" (I-03)
- Firestore security rules completas (se documentan pero se implementan en su propio change)
- Push notifications setup (I-07)
- CI/CD pipeline
- Internacionalizacion (i18n) — todo en espanol por ahora
- Tests de integracion con Firebase Emulator (se haran en un change separado)

## 3. Approach

### 3.1 App Bootstrap

Tres entry points comparten el mismo widget `App` pero difieren en configuracion:

```
main.dart        → Firebase default config (produccion)
main_dev.dart    → Firebase Emulator Suite (localhost)
main_prod.dart   → Firebase produccion explicitamente
```

Cada entry point llama a `App()` pasando un `AppConfig` que indica el environment. `App` es un `ProviderScope` + `MaterialApp.router` con GoRouter.

### 3.2 Clean Architecture por Feature

```
lib/features/auth/
  domain/
    entities/         → User (app model, NO el User de firebase_auth)
    repositories/     → AuthRepository (abstract)
    usecases/         → SignInWithEmail, SignInWithGoogle, Register, etc.
  data/
    repositories/     → FirebaseAuthRepository (implements AuthRepository)
    models/           → FirebaseUserMapper (extension o mapper)
  presentation/
    providers/        → authStateProvider, signInProvider, etc. (Riverpod 3.x + codegen)
    screens/          → LoginScreen, RegisterScreen, VerifyEmailScreen, ForgotPasswordScreen
    widgets/          → AuthFormField, SocialSignInButton, etc.
```

```
lib/features/profile/
  domain/
    entities/         → UserProfile
    repositories/     → ProfileRepository (abstract)
  data/
    repositories/     → FirestoreProfileRepository
    models/           → UserProfileModel (Firestore serialization)
  presentation/
    providers/        → userProfileProvider, onboardingProvider
    screens/          → CompleteProfileScreen (P-08)
    widgets/          → LocalitySelector, PhoneInput, AvatarPicker
```

### 3.3 State Management (Riverpod 3.x con Code Generation)

```dart
// Auth state — keepAlive: true (sesion global)
@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

// Profile — autoDispose (feature-level)
@riverpod
Future<UserProfile?> userProfile(Ref ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(user.uid);
}
```

### 3.4 Routing (GoRouter 17.x)

Router centralizado en `lib/app/routes.dart`. Redirect logic:

1. Si NO autenticado → `/login`
2. Si autenticado pero email NO verificado → `/verify-email`
3. Si autenticado + verificado pero perfil NO completo → `/complete-profile`
4. Si todo OK → `/home` (stub por ahora)

La verificacion de email NO bloquea la navegacion general — solo bloquea acciones que requieren solicitudes de servicio (segun decision del RFC). Sin embargo, como guard de ONBOARDING, si el email no esta verificado, el usuario ve la pantalla de verificacion como paso obligatorio antes de poder usar la app.

### 3.5 Cloud Function `onUserCreate`

```typescript
// functions/src/auth/on-user-create.ts
export const onUserCreate = onAuthUserCreated(async (event) => {
  const user = event.data;
  const batch = admin.firestore().batch();

  batch.set(doc(db, 'users', user.uid), {
    uid: user.uid,
    email: user.email,
    displayName: user.displayName ?? '',
    photoURL: user.photoURL ?? '',
    phone: '',
    locality: '',
    role: 'client',
    onboardingComplete: false,
    emailVerified: false,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  batch.set(doc(db, 'subscriptions', user.uid), {
    uid: user.uid,
    plan: 'free',
    status: 'active',
    createdAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();
});
```

Idempotente: si el documento ya existe, la Cloud Function usa `set` con merge o checks existence primero.

### 3.6 Google Sign-In

Agregar `google_sign_in: ^6.2.0` al pubspec. Implementar en `FirebaseAuthRepository.signInWithGoogle()`. Requiere configuracion en Firebase Console + `google-services.json` (Android) / `GoogleService-Info.plist` (iOS). Web usa el popup flow nativo de Firebase Auth.

### 3.7 Email Verification Cooldown

El cooldown de 60 segundos para reenvio se maneja con state local en el provider:

```dart
@riverpod
class EmailVerification extends _$EmailVerification {
  Timer? _cooldownTimer;

  @override
  EmailVerificationState build() => EmailVerificationState.initial();

  Future<void> resendVerification() async {
    if (state.cooldownRemaining > 0) return;
    await ref.read(authRepositoryProvider).sendEmailVerification();
    state = state.copyWith(cooldownRemaining: 60);
    _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (state.cooldownRemaining <= 0) {
        _cooldownTimer?.cancel();
        return;
      }
      state = state.copyWith(cooldownRemaining: state.cooldownRemaining - 1);
    });
  }
}
```

## 4. Risks & Mitigations

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| R1 | `google_sign_in` no esta en pubspec | HIGH | Agregarlo como primera tarea antes de cualquier codigo de auth |
| R2 | Docs CLAUDE.md dicen Riverpod 2.x / GoRouter 14.x pero pubspec tiene 3.x / 17.x | MEDIUM | Usar versiones del pubspec como fuente de verdad. Actualizar docs en un change separado |
| R3 | `onUserCreate` es prerequisito bloqueante — sin el, login funciona pero no hay perfil en Firestore | HIGH | Implementar Cloud Function PRIMERO, antes del frontend. Testear con emulador |
| R4 | Google Sign-In requiere config nativa (SHA-1 Android, plist iOS) | MEDIUM | Documentar pasos de config. No bloquea desarrollo porque se puede testear con email/password primero |
| R5 | Firebase Auth rate limiting (5 intentos) no es configurable — comportamiento por defecto | LOW | Documentar en UI. Mostrar mensaje claro al usuario cuando se bloquee |
| R6 | Firestore rules para `users/{uid}` no protegen campos sensibles | MEDIUM | Fuera de scope de I-02. Documentar como TODO para change de security rules |
| R7 | Riverpod 3.x con codegen requiere `build_runner` — puede ser lento en CI | LOW | Ya esta en devDependencies. Generar codigo antes de commit. Agregar archivos `.g.dart` al repo |

## 5. Dependencies

### Dependencias tecnicas

| Dependency | Type | Notes |
|------------|------|-------|
| `firebase_core` ^4.6.0 | Ya en pubspec | Base de Firebase |
| `firebase_auth` ^6.3.0 | Ya en pubspec | Auth provider |
| `cloud_firestore` ^6.2.0 | Ya en pubspec | Para leer perfil |
| `flutter_riverpod` ^3.3.1 | Ya en pubspec | State management |
| `riverpod_annotation` ^4.0.2 | Ya en pubspec | Codegen annotations |
| `go_router` ^17.2.0 | Ya en pubspec | Routing |
| `flutter_form_builder` ^10.3.0+2 | Ya en pubspec | Formularios |
| `google_sign_in` ^6.2.x | **AGREGAR** | Google OAuth |
| `riverpod_generator` ^4.0.3 | Ya en dev_deps | Codegen |
| `build_runner` ^2.4.0 | Ya en dev_deps | Codegen runner |
| `mockito` ^5.4.0 | Ya en dev_deps | Test mocks |

### Orden de implementacion

```
1. pubspec.yaml (agregar google_sign_in)
2. App bootstrap (main*.dart, App, theme, routes stub)
3. Cloud Function onUserCreate
4. Feature auth — domain layer
5. Feature auth — data layer
6. Feature auth — presentation layer (providers + screens)
7. Feature profile — domain + data
8. Feature profile — presentation (P-08)
9. Routing guards (redirect logic)
10. Tests
```

Las fases 4-6 y 7-8 pueden paralelizarse parcialmente, pero auth domain DEBE existir antes de profile (profile depende de auth state).

## 6. ADRs (Architecture Decision Records)

### ADR-01: User Entity separada de Firebase User

**Decision**: Crear un `User` entity propio en domain, NO exponer `firebase_auth.User` fuera de la data layer.

**Rationale**: Clean Architecture exige que el domain no dependa de implementaciones externas. Si manana migramos de Firebase Auth a Supabase o custom, solo cambia la data layer.

**Consequence**: Se necesita un mapper `FirebaseUser → User` en la data layer.

### ADR-02: Riverpod Code Generation (no manual providers)

**Decision**: Usar `@riverpod` / `@Riverpod(keepAlive: true)` annotations con `riverpod_generator` para TODOS los providers.

**Rationale**: Riverpod 3.x favorece codegen. Es mas type-safe, reduce boilerplate, y es la direccion oficial del framework. Los archivos `.g.dart` se commitean al repo para evitar que cada dev tenga que correr build_runner.

**Consequence**: Cada cambio a providers requiere `dart run build_runner build`. Se documenta en contributing guide.

### ADR-03: Email Verification como Gate de Onboarding

**Decision**: El email verification es un paso OBLIGATORIO del onboarding flow (pantalla P-06), NO un gate de funcionalidad individual.

**Rationale**: El RFC dice que solo bloquea "enviar solicitudes", pero desde UX es confuso dejar navegar sin email verificado. Como onboarding gate, el usuario ve: Login → Verify Email → Complete Profile → Home. Una vez completado, nunca mas ve esas pantallas.

**Clarification**: Si el usuario cierra la app y vuelve sin haber verificado, vuelve a P-06. Si ya verifico pero no completo perfil, va a P-08. Si completo todo, va a Home.

### ADR-04: Firestore Document Structure para `users/{uid}`

**Decision**: Documento plano (no sub-colecciones) para datos basicos del usuario:

```
users/{uid} = {
  uid: string,
  email: string,
  displayName: string,
  photoURL: string,
  phone: string,
  locality: string,
  role: 'client' | 'provider' | 'admin',
  onboardingComplete: boolean,
  emailVerified: boolean,
  suspendedUntil: timestamp | null,
  createdAt: timestamp,
  updatedAt: timestamp,
}
```

**Rationale**: Los datos del perfil basico se leen en una sola query. Datos de provider (categorias, areas, descripcion) iran en una sub-coleccion o documento separado en I-03.

### ADR-05: GoRouter Redirect Chain (no nested guards)

**Decision**: Un solo `redirect` callback en GoRouter que evalua el estado en cascada: auth → emailVerified → onboardingComplete. NO usar guards anidados ni middleware custom.

**Rationale**: GoRouter 17.x soporta redirect con `refreshListenable`. Usar un solo punto de decision es mas facil de debuggear y testear. El `refreshListenable` escucha al `authStateProvider`.

**Consequence**: El redirect callback puede crecer con el tiempo. Si pasa de ~30 lineas, extraer a una funcion `resolveRedirect(AuthState) → String?`.

### ADR-06: Archivos .g.dart commiteados al repositorio

**Decision**: Los archivos generados por `riverpod_generator` (`.g.dart`) se commitean al repo.

**Rationale**: Evita que cada developer necesite correr `build_runner` antes de poder compilar. Reduce friction en onboarding de nuevos devs y en CI. Tradeoff: merge conflicts en archivos generados, pero es menor que el costo de no tenerlos.

**Consequence**: Agregar step en pre-commit o CI que verifica que los `.g.dart` estan actualizados.

## 7. Definition of Done

- [ ] `google_sign_in` agregado a pubspec.yaml y resuelto
- [ ] App bootstrap funcional: `flutter run -t lib/main_dev.dart` arranca sin errores
- [ ] Cloud Function `onUserCreate` deployada y testeada con emulador
- [ ] Registro con email/password crea usuario en Firebase Auth + documento en Firestore
- [ ] Registro con Google crea usuario en Firebase Auth + documento en Firestore
- [ ] Login con email/password funciona con sesion persistente
- [ ] Login con Google funciona con sesion persistente
- [ ] Pantalla de verificacion de email muestra estado y permite reenvio con cooldown 60s
- [ ] Recuperacion de contrasena envia email correctamente
- [ ] Pantalla de completar datos guarda telefono, localidad y foto en Firestore
- [ ] GoRouter redirige correctamente segun estado: no-auth → login, no-verified → verify, no-profile → complete, all-ok → home
- [ ] Cierre de sesion limpia estado de Riverpod y redirige a login
- [ ] `flutter analyze` — zero warnings
- [ ] `dart format .` — todo formateado
- [ ] Tests unitarios para: AuthRepository (mock), ProfileRepository (mock), auth providers, routing redirect logic
- [ ] Tests de widget para: LoginScreen, RegisterScreen
- [ ] Cloud Function tests con emulador

---

## Summary

| Item | Value |
|------|-------|
| **Features** | 8 (register x2, login x2, verify email, forgot password, complete profile, logout) |
| **Screens** | 5 (P-04 to P-08) |
| **Cloud Functions** | 1 (onUserCreate) |
| **New dependencies** | 1 (google_sign_in) |
| **ADRs** | 6 |
| **Estimated task count** | 15-20 tasks (to be broken down in sdd-tasks) |
| **Risk level** | MEDIUM (mostly config/setup risks, no algorithmic complexity) |
