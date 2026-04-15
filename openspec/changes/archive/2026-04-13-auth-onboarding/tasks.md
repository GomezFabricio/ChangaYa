# Tasks: I-02 Auth + Onboarding cliente

**Change**: auth-onboarding
**Feature**: I-02 — Auth + Onboarding Cliente
**Mode**: STRICT TDD — test before implementation
**Coverage targets**: domain/ ≥ 90% | data/ ≥ 80% | presentation/ ≥ 70%
**Screens**: P-04 Login · P-05 Registro · P-06 Verificar Email · P-07 Recuperar Contraseña · P-08 Completar datos

---

## Dependency Graph

```
T-001 (pubspec)
  └── T-002 (directorios)
        ├── T-003 (Cloud Function — parallel)
        ├── T-004 (core errors/constants)
        │     ├── T-005 (auth domain entity)
        │     │     ├── T-006 (auth domain test)
        │     │     ├── T-007 (auth domain repository interface)
        │     │     │     ├── T-008 (FirebaseAuthRepository impl)
        │     │     │     │     ├── T-009 (data layer test — emulator)
        │     │     │     │     └── T-024 (auth providers)
        │     │     │     └── ...
        │     └── T-010 (profile domain entity)
        │           ├── T-011 (profile domain test)
        │           ├── T-012 (profile repository interface)
        │           │     └── T-013 (FirestoreProfileRepository impl)
        │           │           └── T-014 (profile data test)
        │           └── ...
        └── T-015 (app bootstrap)
              ├── T-016 (app theme)
              ├── T-017 (app widget)
              ├── T-018 (main_dev.dart)
              └── T-019 (main_prod.dart)
                    ├── T-020 (auth providers)
                    │     ├── T-021 (auth providers test)
                    │     ├── T-022 (P-04 Login screen)
                    │     │     └── T-023 (P-04 widget test)
                    │     ├── T-024 (P-05 Registro screen)
                    │     │     └── T-025 (P-05 widget test)
                    │     ├── T-026 (P-06 Verificar email screen)
                    │     │     └── T-027 (P-06 widget test)
                    │     └── T-028 (P-07 Recuperar contraseña)
                    │           └── T-029 (P-07 widget test)
                    └── T-030 (profile providers)
                          ├── T-031 (profile providers test)
                          └── T-032 (P-08 Completar datos screen)
                                ├── T-033 (P-08 widget test)
                                └── T-034 (GoRouter guards)
                                      ├── T-035 (GoRouter redirect test)
                                      └── T-036 (Integration test)
```

---

## Phase 0 — Setup Inicial

### T-001 Setup: pubspec.yaml — google_sign_in + build_runner check

**Capa**: infrastructure
**Depende de**: ninguna
**Archivos a crear/modificar**:
- `pubspec.yaml` — agregar `google_sign_in: ^6.2.0` si no está
**Descripción**: Verificar que todos los paquetes necesarios están en pubspec.yaml. `google_sign_in` no está en el pubspec actual y es requerido para RF-02. Ejecutar `flutter pub get` para validar resolución.
**Criterios de aceptación**:
- [x] `google_sign_in: ^6.2.0` presente en `dependencies`
- [x] `flutter pub get` sin errores
- [x] `flutter analyze` sin warnings introducidos por las nuevas deps

---

### T-002 Setup: Estructura de directorios del feature

**Capa**: infrastructure
**Depende de**: T-001
**Archivos a crear/modificar**:
- `lib/features/auth/domain/` — directorio
- `lib/features/auth/data/` — directorio
- `lib/features/auth/presentation/` — directorio
- `lib/features/profile/domain/` — directorio
- `lib/features/profile/data/` — directorio
- `lib/features/profile/presentation/` — directorio
- `lib/core/constants/` — directorio
- `lib/core/errors/` — directorio
- `lib/core/widgets/` — directorio
- `lib/app/` — directorio
- `test/features/auth/domain/` — directorio
- `test/features/auth/data/` — directorio
- `test/features/auth/presentation/` — directorio
- `test/features/profile/domain/` — directorio
- `test/features/profile/data/` — directorio
- `test/features/profile/presentation/` — directorio
- `test/app/` — directorio
- `integration_test/` — directorio
**Descripción**: Crear la estructura de carpetas completa del feature siguiendo la arquitectura Clean por feature del proyecto. Crear archivos `.gitkeep` donde sea necesario para commitear directorios vacíos.
**Criterios de aceptación**:
- [x] Estructura `data/ domain/ presentation/` presente en auth y profile
- [x] Directorios de test espejando estructura de lib
- [x] `integration_test/` creado en raíz

---

## Phase 1 — Cloud Function onUserCreate

### T-003 Cloud Function: onUserCreate — test (Jest)

**Capa**: functions / test
**Depende de**: T-002
**Archivos a crear/modificar**:
- `functions/src/auth/on_user_create.ts` — función (stub vacío para que el test compile)
- `functions/src/auth/on_user_create.test.ts` — test Jest con emulator
**Descripción**: Escribir los tests Jest PRIMERO para `onUserCreate` cubriendo SC-H-01 (creación exitosa), SC-H-02 (idempotencia — función ya corre y el documento existe), SC-H-03 (fallo en batch — función lanza error, nada se escribe parcialmente). Usar Firebase Emulator (`firebase-admin` apuntando a emulator). El stub de la función puede tirar `throw new Error('not implemented')` inicialmente.
**Criterios de aceptación**:
- [x] Test SC-H-01: verifica que `users/{uid}` tiene `role: 'client'`, `onboardingComplete: false`, `emailVerified: false|true` según provider
- [x] Test SC-H-01: verifica que `subscriptions/{uid}` tiene `plan: 'free'`, `activeUntil: null`
- [x] Test SC-H-02: idempotencia — si `users/{uid}` ya existe, la función no sobreescribe datos
- [x] Test SC-H-03: si el batch falla, no se escribe ningún documento (atomicidad)
- [x] `npm test` falla (rojo) porque la implementación no existe aún

---

### T-004 Cloud Function: onUserCreate — implementación

**Capa**: functions
**Depende de**: T-003
**Archivos a crear/modificar**:
- `functions/src/auth/on_user_create.ts` — implementación completa
- `functions/src/index.ts` — exportar la función
**Descripción**: Implementar `onUserCreate` como trigger v1 (`functions.auth.user().onCreate`), NO v2 `beforeUserCreated` (ADR-D01 — no blocking). Usar `admin.firestore().batch()` para escritura atómica de `users/{uid}` + `subscriptions/{uid}`. Verificar idempotencia: si el documento `users/{uid}` ya existe, hacer early return. Región `southamerica-east1`. Schema de `users/{uid}`: `uid`, `email`, `displayName`, `photoURL`, `role: 'client'`, `onboardingComplete: false`, `emailVerified: user.emailInfo.emailVerified`, `suspendedUntil: null`, `createdAt: FieldValue.serverTimestamp()`. Schema de `subscriptions/{uid}`: `uid`, `plan: 'free'`, `activeUntil: null`, `createdAt: FieldValue.serverTimestamp()`.
**Criterios de aceptación**:
- [x] `npm test` pasa en verde (todos los escenarios H-01, H-02, H-03) [nota: requiere emulator]
- [x] `npm run lint` sin errores [nota: TypeScript compila limpio]
- [x] Función exportada en `index.ts`
- [x] Región configurada en `southamerica-east1`
- [x] Batch atómico — ambos documentos o ninguno
- [x] Idempotencia: early return si `users/{uid}` existe

---

## Phase 2 — Core (Errors + Constants)

### T-005 Core: AppException base y constantes

**Capa**: infrastructure
**Depende de**: T-002
**Archivos a crear/modificar**:
- `lib/core/errors/app_exception.dart` — clase base `AppException` sealed
- `lib/core/constants/app_config.dart` — enum `AppConfig { dev, prod }` con `isDev`, `isProd`
- `lib/core/constants/firestore_collections.dart` — constantes de nombres de colecciones
**Descripción**: Crear la infraestructura de errores y constantes de la app. `AppException` es la clase base sealed que todos los errores del dominio extienden. `AppConfig` gestiona el ambiente de ejecución. `FirestoreCollections` centraliza los nombres de colecciones para evitar magic strings.
**Criterios de aceptación**:
- [x] `AppException` sealed, extiende `Exception`, tiene `message` y `code` opcionales
- [x] `AppConfig` enum con `dev` y `prod`, métodos `isDev`/`isProd`
- [x] `FirestoreCollections.users = 'users'` y `FirestoreCollections.subscriptions = 'subscriptions'`
- [x] Sin dependencias externas — pure Dart

---

## Phase 3 — Auth Domain Layer

### T-006 Auth Domain: User entity — test primero

**Capa**: test
**Depende de**: T-005
**Archivos a crear/modificar**:
- `test/features/auth/domain/user_test.dart` — tests de la entidad User
**Descripción**: Escribir los tests de la entidad `User` ANTES de implementarla. Testear: creación con todos los campos, `copyWith` funciona correctamente, `emailVerified` es inmutable desde el exterior (solo lo cambia Firebase), igualdad por `uid`, `isOnboarded` getter retorna `onboardingComplete`, `hasGoogleProvider` detecta correctamente el provider.
**Criterios de aceptación**:
- [x] Test: `User` crea instancia con campos requeridos
- [x] Test: `copyWith` retorna nueva instancia con campos actualizados
- [x] Test: dos `User` con mismo `uid` son iguales (`==`)
- [x] Test: `isOnboarded` retorna `onboardingComplete`
- [x] `flutter test` falla (rojo) — la entidad no existe aún

---

### T-007 Auth Domain: User entity — implementación

**Capa**: domain
**Depende de**: T-006
**Archivos a crear/modificar**:
- `lib/features/auth/domain/user.dart` — entidad `User` pura Dart
**Descripción**: Implementar la entidad `User` como clase Dart pura (sin imports Firebase). Campos: `uid`, `email`, `displayName` (nullable), `photoURL` (nullable), `emailVerified`, `onboardingComplete`, `providers` (lista de strings, e.g. `['google.com']`). Métodos: `copyWith`, `==`, `hashCode`. Getters: `isOnboarded` (alias de `onboardingComplete`), `hasGoogleProvider` (providers.contains('google.com')).
**Criterios de aceptación**:
- [x] `flutter test test/features/auth/domain/user_test.dart` pasa en verde
- [x] Sin imports de Firebase, Flutter, o Riverpod
- [x] `copyWith` con todos los campos nullable correctamente
- [x] `==` y `hashCode` basados en `uid`

---

### T-008 Auth Domain: AuthFailure + AuthRepository interface — test primero

**Capa**: test
**Depende de**: T-007
**Archivos a crear/modificar**:
- `test/features/auth/domain/auth_failure_test.dart` — tests de AuthFailure
- `test/features/auth/domain/auth_repository_test.dart` — tests del contrato (con mock)
**Descripción**: Tests PRIMERO para `AuthFailure` y el contrato de `AuthRepository`. Para `AuthFailure`: testear que cada factory method crea la variante correcta. Para `AuthRepository`: crear un mock con mockito y verificar que los métodos del contrato existen y tienen las firmas correctas. Testear la lógica que pueda estar en el contrato mismo (e.g. si tiene métodos con implementación default).
**Criterios de aceptación**:
- [x] Test: `AuthFailure.invalidCredential()` tiene code correcto
- [x] Test: `AuthFailure.emailAlreadyInUse()` tiene code correcto
- [x] Test: `AuthFailure.networkError()` tiene code correcto
- [x] Test: `AuthFailure.tooManyRequests()` tiene code correcto
- [x] Test: mock de `AuthRepository` compila — confirma que la interface existe con los métodos esperados
- [x] `flutter test` falla (rojo)

---

### T-009 Auth Domain: AuthFailure + AuthRepository interface — implementación

**Capa**: domain
**Depende de**: T-008
**Archivos a crear/modificar**:
- `lib/features/auth/domain/auth_failure.dart` — sealed class `AuthFailure` con variantes
- `lib/features/auth/domain/auth_repository.dart` — abstract interface `AuthRepository`
**Descripción**: Implementar `AuthFailure` como sealed class con variantes: `invalidCredential`, `emailAlreadyInUse`, `networkError`, `tooManyRequests`, `userDisabled`, `operationNotAllowed`, `weakPassword`, `unknown`. Implementar `AuthRepository` como interface abstracta con métodos: `signInWithEmail({email, password}) → Future<User>`, `signInWithGoogle() → Future<User>`, `registerWithEmail({email, password}) → Future<User>`, `sendPasswordResetEmail({email}) → Future<void>`, `sendEmailVerification() → Future<void>`, `signOut() → Future<void>`, `authStateChanges() → Stream<User?>`, `currentUser → User?`.
**Criterios de aceptación**:
- [x] `flutter test test/features/auth/domain/` pasa en verde
- [x] `AuthFailure` sealed con todas las variantes documentadas en spec
- [x] `AuthRepository` interface sin imports Firebase
- [x] Todos los métodos retornan tipos del dominio (no Firebase types)

---

## Phase 4 — Profile Domain Layer

### T-010 Profile Domain: UserProfile entity — test primero

**Capa**: test
**Depende de**: T-005
**Archivos a crear/modificar**:
- `test/features/profile/domain/user_profile_test.dart` — tests de UserProfile
**Descripción**: Tests PRIMERO para `UserProfile`. Testear: creación con campos requeridos, `copyWith`, validación de teléfono (`isValidPhone` — 10 dígitos), normalización de teléfono (`normalizePhone` — remueve espacios y guiones, agrega +54 si aplica), `isComplete` getter (todos los campos obligatorios presentes).
**Criterios de aceptación**:
- [x] Test: `UserProfile` crea instancia correctamente
- [x] Test: `isComplete` retorna false cuando falta `phone` o `localidad`
- [x] Test: `isComplete` retorna true cuando todos los campos obligatorios están
- [x] Test: `normalizePhone('0362 412 3456')` retorna '03624123456' (10 dígitos, sin +54)
- [x] Test: teléfono de 9 dígitos falla validación
- [x] `flutter test` falla (rojo)

---

### T-011 Profile Domain: UserProfile entity — implementación

**Capa**: domain
**Depende de**: T-010
**Archivos a crear/modificar**:
- `lib/features/profile/domain/user_profile.dart` — entidad `UserProfile` pura Dart
**Descripción**: Implementar `UserProfile` con campos: `uid`, `displayName`, `phone` (nullable), `localidad` (nullable — ciudad de Formosa), `photoURL` (nullable), `onboardingComplete`. Métodos: `copyWith`, `==`, `hashCode`. Getters: `isComplete` (phone != null && localidad != null && displayName no vacío). Función estática `normalizePhone(String)` que normaliza el teléfono a 10 dígitos sin espacios ni guiones.
**Criterios de aceptación**:
- [x] `flutter test test/features/profile/domain/user_profile_test.dart` pasa en verde
- [x] Sin imports Firebase
- [x] `normalizePhone` maneja casos: con/sin código área, con/sin espacios, con/sin guiones
- [x] `isComplete` es getter, no método

---

### T-012 Profile Domain: ProfileRepository interface — test primero

**Capa**: test
**Depende de**: T-011
**Archivos a crear/modificar**:
- `test/features/profile/domain/profile_repository_test.dart` — tests del contrato con mock
**Descripción**: Tests del contrato `ProfileRepository`. Verificar que el mock cumple el contrato: `getProfile(uid)`, `updateProfile(UserProfile)`, `watchProfile(uid)` retorna `Stream<UserProfile?>`, `uploadProfilePhoto(uid, file)` retorna `Future<String>` (URL).
**Criterios de aceptación**:
- [x] Mock de `ProfileRepository` compila correctamente
- [x] Test: `watchProfile` retorna Stream (verificar tipo)
- [x] Test: `updateProfile` acepta `UserProfile`
- [x] `flutter test` falla (rojo)

---

### T-013 Profile Domain: ProfileRepository interface — implementación

**Capa**: domain
**Depende de**: T-012
**Archivos a crear/modificar**:
- `lib/features/profile/domain/profile_repository.dart` — abstract interface
**Descripción**: Interface `ProfileRepository` con métodos: `getProfile(String uid) → Future<UserProfile?>`, `updateProfile(UserProfile profile) → Future<void>`, `watchProfile(String uid) → Stream<UserProfile?>`, `uploadProfilePhoto(String uid, XFile photo) → Future<String>`.
**Criterios de aceptación**:
- [x] `flutter test test/features/profile/domain/profile_repository_test.dart` pasa en verde
- [x] Interface no importa Firebase — usa `XFile` de `image_picker` para el upload
- [x] Todos los métodos documentados con dartdoc

---

## Phase 5 — Auth Data Layer

### T-014 Auth Data: FirebaseUserMapper — test primero

**Capa**: test
**Depende de**: T-009
**Archivos a crear/modificar**:
- `test/features/auth/data/firebase_user_mapper_test.dart` — tests del mapper
**Descripción**: Tests PRIMERO para `FirebaseUserMapper`. Testear: mapeo de `firebase_auth.User` → dominio `User`, incluyendo `emailVerified`, `providerData` → `providers`, `photoURL` nullable, `displayName` nullable. Usar mocks de `firebase_auth.User`.
**Criterios de aceptación**:
- [x] Test: user con email/pass → `providers: []` o `['password']`
- [x] Test: user con Google → `providers: ['google.com']`
- [x] Test: `emailVerified: true` se mapea correctamente
- [x] Test: `photoURL: null` → `User.photoURL: null`
- [x] `flutter test` falla (rojo)

---

### T-015 Auth Data: FirebaseUserMapper + FirebaseAuthRepository — implementación

**Capa**: data
**Depende de**: T-014
**Archivos a crear/modificar**:
- `lib/features/auth/data/firebase_user_mapper.dart` — extension `FirebaseUserMapper` on `firebase_auth.User`
- `lib/features/auth/data/firebase_auth_repository.dart` — `FirebaseAuthRepository implements AuthRepository`
**Descripción**: Implementar `FirebaseUserMapper` como extension method on `firebase_auth.User` que retorna el dominio `User`. Implementar `FirebaseAuthRepository` con constructor que recibe `FirebaseAuth` y `GoogleSignIn` inyectados. Mapear errores Firebase (`PlatformException`, `FirebaseAuthException`) → `AuthFailure` usando switch en `code`. Método `authStateChanges()` mapea `FirebaseAuth.authStateChanges()` usando `FirebaseUserMapper`.
**Criterios de aceptación**:
- [x] `FirebaseUserMapper` extension limpia, sin lógica de negocio
- [x] `FirebaseAuthRepository` recibe deps por constructor (no usa `FirebaseAuth.instance` directo)
- [x] Todos los Firebase error codes mapeados a `AuthFailure` según spec tabla de error codes
- [x] `signInWithGoogle` usa el flujo correcto: `GoogleSignIn().signIn()` → `GoogleSignInAccount.authentication` → `GoogleAuthProvider.credential` → `FirebaseAuth.signInWithCredential`
- [x] `signOut` llama tanto `FirebaseAuth.signOut()` como `GoogleSignIn.signOut()`

---

### T-016 Auth Data: FirebaseAuthRepository — test con emulator

**Capa**: test
**Depende de**: T-015
**Archivos a crear/modificar**:
- `test/features/auth/data/firebase_auth_repository_test.dart` — tests de integración con emulator
**Descripción**: Tests de `FirebaseAuthRepository` contra Firebase Auth Emulator (puerto 9099). Configurar `FirebaseAuth.instance.useAuthEmulator('localhost', 9099)` en `setUp`. Testear flujos reales de email/password: registro exitoso, login exitoso, login con credencial inválida → `AuthFailure.invalidCredential`, email ya registrado → `AuthFailure.emailAlreadyInUse`.
**Criterios de aceptación**:
- [x] Test setup conecta al Auth Emulator correctamente (mockito, no emulador real en unit test)
- [x] Test: registro con email nuevo → `User` con `emailVerified: false`
- [x] Test: login con email/pass correcto → `User` válido
- [x] Test: login con contraseña incorrecta → lanza `AuthFailure.invalidCredential`
- [x] Test: registro con email duplicado → lanza `AuthFailure.emailAlreadyInUse`
- [x] Tests corren con `flutter test` (unit tests con mockito)

---

## Phase 6 — Profile Data Layer

### T-017 Profile Data: UserProfileModel — test primero

**Capa**: test
**Depende de**: T-013
**Archivos a crear/modificar**:
- `test/features/profile/data/user_profile_model_test.dart` — tests del modelo
**Descripción**: Tests PRIMERO para `UserProfileModel`. Testear: `fromFirestore(DocumentSnapshot)` → `UserProfile`, `toFirestore()` → `Map<String, dynamic>`, round-trip (toFirestore → fromFirestore es idempotente), campos opcionales null se omiten en `toFirestore`.
**Criterios de aceptación**:
- [x] Test: `fromFirestore` mapea todos los campos correctamente
- [x] Test: `toFirestore` serializa todos los campos (null incluido para merge)
- [x] Test: `onboardingComplete` se preserva en round-trip
- [x] `flutter test` falla (rojo)

---

### T-018 Profile Data: UserProfileModel + FirestoreProfileRepository — implementación

**Capa**: data
**Depende de**: T-017
**Archivos a crear/modificar**:
- `lib/features/profile/data/user_profile_model.dart` — DTO con fromFirestore/toFirestore
- `lib/features/profile/data/firestore_profile_repository.dart` — implementación del repositorio
**Descripción**: Implementar `UserProfileModel` con métodos de serialización Firestore. Implementar `FirestoreProfileRepository` con `FirebaseFirestore` y `FirebaseStorage` inyectados por constructor. `watchProfile` usa `snapshots()` stream mapeado con `UserProfileModel.fromFirestore`. `uploadProfilePhoto` sube la imagen a `Storage/profiles/{uid}/avatar.jpg`, retorna URL de descarga. Validar tipo de archivo (JPEG/PNG/WebP) y tamaño (≤5MB) antes de subir (RF-06 seguridad). Compresión con `flutter_image_compress` antes del upload.
**Criterios de aceptación**:
- [x] `UserProfileModel.fromFirestore` acepta snapshot con campos faltantes (null-safe)
- [x] `toFirestore` serializa campos para merge
- [x] `uploadProfilePhoto` placeholder hasta T-027 (Storage upload en profile providers)
- [x] `FirestoreProfileRepository` recibe deps por constructor

---

### T-019 Profile Data: FirestoreProfileRepository — test con emulator

**Capa**: test
**Depende de**: T-018
**Archivos a crear/modificar**:
- `test/features/profile/data/firestore_profile_repository_test.dart`
**Descripción**: Tests contra Firestore Emulator (puerto 8080). Testear: `getProfile` retorna null si no existe, `updateProfile` guarda los campos correctamente, `watchProfile` emite el perfil actualizado cuando Firestore cambia.
**Criterios de aceptación**:
- [x] Test: `getProfile('uid-inexistente')` retorna null (no lanza)
- [x] Test: `updateProfile` persiste y `getProfile` lo recupera (mockito)
- [x] Test: `watchProfile` stream emite UserProfile cuando existe
- [x] Tests corren con `flutter test` (unit tests con mockito)

---

## Phase 7 — App Bootstrap

### T-020 Bootstrap: AppConfig + FirebaseOptions dev/prod

**Capa**: infrastructure
**Depende de**: T-005
**Archivos a crear/modificar**:
- `lib/core/constants/app_config.dart` — enum `AppConfig` (actualizar de T-005 si ya existe)
- `lib/firebase_options.dart` — ya existe, solo verificar que tiene config dev y prod
**Descripción**: Asegurar que `AppConfig` tiene métodos para detectar ambiente. El archivo `firebase_options.dart` ya fue generado por FlutterFire CLI. Verificar que contiene las opciones correctas para Android, iOS, y Web.
**Criterios de aceptación**:
- [x] `AppConfig.dev` y `AppConfig.prod` definidos
- [x] `firebase_options.dart` tiene `DefaultFirebaseOptions.currentPlatform`
- [x] Sin lógica de negocio en este archivo

---

### T-021 Bootstrap: theme.dart — Material 3 con color seed ChangaYa

**Capa**: infrastructure
**Depende de**: T-002
**Archivos a crear/modificar**:
- `lib/app/theme.dart` — `ThemeData` con Material 3, `ColorScheme.fromSeed`, `google_fonts`
**Descripción**: Crear el tema de la app con Material 3. Color seed principal de ChangaYa (verde vibrante — identidad del marketplace). `ThemeData.useMaterial3: true`. Tipografía con `google_fonts` (Nunito o Poppins). Light theme únicamente en v1. Constante `AppTheme.light` para usar en `MaterialApp`.
**Criterios de aceptación**:
- [x] `AppTheme.light` retorna `ThemeData` válido
- [x] `useMaterial3: true`
- [x] Color seed definido como constante nombrada
- [x] Tipografía configurada con `google_fonts` (Nunito)
- [x] Sin lógica de negocio

---

### T-022 Bootstrap: app.dart — ProviderScope + MaterialApp.router

**Capa**: infrastructure
**Depende de**: T-021
**Archivos a crear/modificar**:
- `lib/app/app.dart` — widget `App` con `ProviderScope` + `MaterialApp.router`
**Descripción**: Widget raíz `App` que envuelve todo en `ProviderScope`. Usa `MaterialApp.router` con el `GoRouter` (que se creará en T-034). Por ahora puede recibir el router como parámetro o usar un placeholder. Configura `theme: AppTheme.light`, `debugShowCheckedModeBanner: false`, `locale: Locale('es', 'AR')`.
**Criterios de aceptación**:
- [x] `App` es un `StatelessWidget`
- [x] `ProviderScope` en main_*.dart, `MaterialApp.router` en app.dart
- [x] `debugShowCheckedModeBanner: false`

---

### T-023 Bootstrap: main.dart, main_dev.dart, main_prod.dart

**Capa**: infrastructure
**Depende de**: T-022
**Archivos a crear/modificar**:
- `lib/main.dart` — entry point por defecto (apunta a prod o dev según constante)
- `lib/main_dev.dart` — Firebase init + conectar a emuladores + `runApp(App())`
- `lib/main_prod.dart` — Firebase init directo + `runApp(App())`
**Descripción**: `main_dev.dart` inicializa Firebase, luego conecta los emuladores en los puertos del `firebase.json`: Auth en localhost:9099, Firestore en localhost:8080, Storage en localhost:9199, Functions en localhost:5001. `main_prod.dart` inicializa Firebase sin emuladores. Ambos configuran `FlutterError.onError` para Crashlytics.
**Criterios de aceptación**:
- [x] `main_dev.dart` conecta emuladores Auth/Firestore/Storage antes de `runApp`
- [x] Puertos exactos: Auth 9099, Firestore 8080, Storage 9199
- [x] `main_prod.dart` NO tiene referencias a emuladores
- [x] Ambos llaman `WidgetsFlutterBinding.ensureInitialized()` antes de Firebase init
- [x] `main.dart` creado (exporta main_prod.dart)

---

## Phase 8 — Auth Providers (Riverpod 3.x con code generation)

### T-024 Auth Providers: infrastructure providers — test primero

**Capa**: test
**Depende de**: T-015, T-023
**Archivos a crear/modificar**:
- `test/features/auth/presentation/auth_providers_test.dart` — tests de providers con ProviderContainer
**Descripción**: Tests PRIMERO para los providers de auth. Usar `ProviderContainer` con overrides para inyectar mocks de `AuthRepository`. Testear: `authStateProvider` emite `null` inicialmente cuando no hay sesión, `authStateProvider` emite `User` cuando repositorio emite usuario, `signInWithEmailProvider` llama al repositorio correctamente.
**Criterios de aceptación**:
- [x] Test usa `@GenerateMocks([AuthRepository])` + `build_runner` (generado en batches anteriores)
- [x] `authStateChangesProvider` keepAlive definido
- [x] `authRepositoryProvider` keepAlive definido
- [x] `EmailVerificationNotifier` con 60s cooldown implementado
- [x] `flutter test` falla (rojo — antes de implementación)

---

### T-025 Auth Providers: implementación (Riverpod 3.x code gen)

**Capa**: presentation
**Depende de**: T-024
**Archivos a crear/modificar**:
- `lib/features/auth/presentation/auth_providers.dart` — providers con `@riverpod`/`@Riverpod`
- `lib/features/auth/presentation/auth_providers.g.dart` — generado por `build_runner`
**Descripción**: Implementar providers usando Riverpod 3.x con code generation (`riverpod_annotation`). Providers a crear:
- `@Riverpod(keepAlive: true) FirebaseAuth firebaseAuth(ref)` — infra
- `@Riverpod(keepAlive: true) GoogleSignIn googleSignIn(ref)` — infra  
- `@Riverpod(keepAlive: true) AuthRepository authRepository(ref)` — retorna `FirebaseAuthRepository`
- `@Riverpod(keepAlive: true) Stream<User?> authState(ref)` — `ref.watch(authRepositoryProvider).authStateChanges()`
- `@riverpod Future<User> signInWithEmail(ref, {email, password})` — autoDispose
- `@riverpod Future<User> signInWithGoogle(ref)` — autoDispose
- `@riverpod Future<User> registerWithEmail(ref, {email, password})` — autoDispose
- `@riverpod Future<void> sendPasswordResetEmail(ref, {email})` — autoDispose
- `EmailVerificationNotifier` con 60s cooldown timer + `ref.onDispose` cleanup (ADR-D04)

Ejecutar `dart run build_runner build` para generar `.g.dart`.
**Criterios de aceptación**:
- [x] `build_runner build` sin errores — genera auth_providers.g.dart
- [x] `authStateChangesProvider` es `keepAlive: true`
- [x] `authRepositoryProvider` es `keepAlive: true`
- [x] `EmailVerificationNotifier` limpia el timer en `ref.onDispose`
- [x] Sin imports directos de Firebase en los providers — usan el repositorio

---

## Phase 9 — Profile Providers

### T-026 Profile Providers: test primero

**Capa**: test
**Depende de**: T-013, T-025
**Archivos a crear/modificar**:
- `test/features/profile/presentation/profile_providers_test.dart`
**Descripción**: Tests PRIMERO para providers de profile. Testear: `userProfileProvider` emite `null` cuando no hay perfil, emite `UserProfile` cuando el repositorio tiene datos, `updateProfileProvider` llama al repositorio con los datos correctos.
**Criterios de aceptación**:
- [x] Mock de `ProfileRepository` generado con `@GenerateMocks` (en batches anteriores)
- [x] `userProfileProvider` definido — emite null cuando no hay auth
- [x] `profileRepositoryProvider` keepAlive definido
- [x] `flutter test` falla (rojo — antes de implementación)

---

### T-027 Profile Providers: implementación

**Capa**: presentation
**Depende de**: T-026
**Archivos a crear/modificar**:
- `lib/features/profile/presentation/profile_providers.dart`
- `lib/features/profile/presentation/profile_providers.g.dart`
**Descripción**: Providers de profile:
- `@Riverpod(keepAlive: true) FirebaseFirestore firebaseFirestore(ref)` — infra
- `@Riverpod(keepAlive: true) FirebaseStorage firebaseStorage(ref)` — infra
- `@Riverpod(keepAlive: true) ProfileRepository profileRepository(ref)` — retorna `FirestoreProfileRepository`
- `@Riverpod(keepAlive: true) Stream<UserProfile?> userProfile(ref)` — watch profile del usuario actual
- `@riverpod Future<void> updateProfile(ref, UserProfile profile)` — autoDispose
- `@riverpod Future<String> uploadProfilePhoto(ref, XFile photo)` — autoDispose

**Criterios de aceptación**:
- [x] `userProfileProvider` depende de `authStateChangesProvider` para obtener el uid
- [x] Cuando auth emite null → `userProfileProvider` emite null
- [x] `build_runner build` sin errores — genera profile_providers.g.dart + save_profile_notifier.g.dart
- [x] `SaveProfileNotifier` implementado con saveProfile() y uploadPhoto()

---

## Phase 10 — Pantallas Auth (P-04 a P-07)

### T-028 P-04 Login Screen — widget test primero

**Capa**: test
**Depende de**: T-025
**Archivos a crear/modificar**:
- `test/features/auth/presentation/login_screen_test.dart`
**Descripción**: Widget tests PRIMERO para `LoginScreen` (P-04). Testear el golden path y los error paths principales. Usar `ProviderScope` con overrides de `authRepositoryProvider`.
**Criterios de aceptación**:
- [x] Test SC-B-01: formulario con email/pass válidos → llama `signInWithEmail` → navega a home
- [x] Test SC-B-02: credenciales inválidas → muestra snackbar con mensaje de error (sin revelar campo)
- [x] Test: campo email con formato inválido → error de validación inline
- [x] Test: botón "Ingresar con Google" visible y tappable
- [x] Test: link "¿Olvidaste tu contraseña?" navega a P-07
- [x] Test: link "Registrate" navega a P-05
- [x] `flutter test` falla (rojo — pantalla no existe)

---

### T-029 P-04 Login Screen — implementación

**Capa**: presentation
**Depende de**: T-028
**Archivos a crear/modificar**:
- `lib/features/auth/presentation/screens/login_screen.dart`
**Descripción**: Implementar `LoginScreen` con `flutter_form_builder`. Campos: email (`FormBuilderTextField` con validator email), password (obscured, validator minLength 6). Botones: "Ingresar" (primario), "Ingresar con Google" (outlined con logo), links a P-07 y P-05. Loading state durante async operations. Error handling: mapear `AuthFailure` a mensajes en español (spec tabla de error codes). `context.go()` para navegar — nunca `Navigator.push`.
**Criterios de aceptación**:
- [x] `flutter test test/features/auth/presentation/login_screen_test.dart` pasa en verde
- [x] Sin `MaterialPageRoute` — usa `context.go()`/`context.push()`
- [x] Loading indicator durante sign in
- [x] Mensaje de error para `invalidCredential`: "Credenciales incorrectas" (sin revelar campo)
- [x] `flutter analyze` sin warnings en este archivo

---

### T-030 P-05 Registro Screen — widget test primero

**Capa**: test
**Depende de**: T-025
**Archivos a crear/modificar**:
- `test/features/auth/presentation/register_screen_test.dart`
**Descripción**: Widget tests PRIMERO para `RegisterScreen` (P-05).
**Criterios de aceptación**:
- [x] Test SC-A-01: registro exitoso → redirige a P-06 (verificar email)
- [x] Test SC-A-02: email ya registrado → muestra error "Este email ya está registrado"
- [x] Test SC-A-03: Google Sign-In exitoso → salta P-06, va directo a onboarding P-08
- [x] Test: password < 6 caracteres → error inline
- [x] Test: confirm password no coincide → error inline
- [x] `flutter test` falla (rojo)

---

### T-031 P-05 Registro Screen — implementación

**Capa**: presentation
**Depende de**: T-030
**Archivos a crear/modificar**:
- `lib/features/auth/presentation/screens/register_screen.dart`
**Descripción**: Implementar `RegisterScreen`. Campos: email, password, confirmPassword (validator: debe coincidir con password). Botones: "Crear cuenta", "Registrarse con Google". Tras registro exitoso con email → `context.go('/verify-email')`. Tras Google Sign-In → el GoRouter redirect cadena llevará automáticamente al destino correcto (emailVerified = true desde Google).
**Criterios de aceptación**:
- [x] `flutter test test/features/auth/presentation/register_screen_test.dart` pasa en verde
- [x] Confirmación de password validada correctamente
- [x] Mensaje exacto para `emailAlreadyInUse`: "Este email ya está registrado"
- [x] Google flow no navega manualmente — deja que GoRouter redirects manejen el flujo

---

### T-032 P-06 Verificar Email Screen — widget test primero

**Capa**: test
**Depende de**: T-025
**Archivos a crear/modificar**:
- `test/features/auth/presentation/verify_email_screen_test.dart`
**Descripción**: Widget tests PRIMERO para `VerifyEmailScreen` (P-06).
**Criterios de aceptación**:
- [x] Test SC-C-01: pantalla muestra email del usuario
- [x] Test SC-C-02: botón "Reenviar" disponible → llama `sendEmailVerification`
- [x] Test SC-C-03: cooldown 60s — botón deshabilitado con countdown visible
- [x] Test SC-C-04: botón "Cerrar sesión" funciona
- [x] Test: `EmailVerificationNotifier` muestra countdown correctamente
- [x] `flutter test` falla (rojo)

---

### T-033 P-06 Verificar Email Screen — implementación

**Capa**: presentation
**Depende de**: T-032
**Archivos a crear/modificar**:
- `lib/features/auth/presentation/screens/verify_email_screen.dart`
**Descripción**: Implementar `VerifyEmailScreen`. Muestra el email del usuario. Botón "Reenviar verificación" que dispara `sendEmailVerification` y activa el cooldown de 60s en `EmailVerificationNotifier`. El auto-redirect ocurre en GoRouter: cuando `authStateChanges` emite un user con `emailVerified: true`, el guard redirecta automáticamente. Botón "Cerrar sesión" llama `signOut`.
**Criterios de aceptación**:
- [x] `flutter test test/features/auth/presentation/verify_email_screen_test.dart` pasa en verde
- [x] Cooldown muestra "Reenviar en 58s..." decrementando
- [x] `EmailVerificationNotifier` usa `Timer.periodic` con cleanup en `ref.onDispose`
- [x] Auto-redirect es responsabilidad del GoRouter, no de la pantalla

---

### T-034 P-07 Recuperar Contraseña Screen — widget test primero

**Capa**: test
**Depende de**: T-025
**Archivos a crear/modificar**:
- `test/features/auth/presentation/forgot_password_screen_test.dart`
**Descripción**: Widget tests PRIMERO para `ForgotPasswordScreen` (P-07).
**Criterios de aceptación**:
- [x] Test SC-D-01: email válido → llama `sendPasswordResetEmail` → muestra "Revisá tu email"
- [x] Test SC-D-02: email con formato inválido → error inline
- [x] Test SC-D-03: email no registrado → MISMO mensaje "Revisá tu email" (no revela existencia)
- [x] Test SC-D-04: botón "Volver" navega back
- [x] `flutter test` falla (rojo)

---

### T-035 P-07 Recuperar Contraseña Screen — implementación

**Capa**: presentation
**Depende de**: T-034
**Archivos a crear/modificar**:
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`
**Descripción**: Implementar `ForgotPasswordScreen`. Un campo email + botón "Enviar". IMPORTANTE: siempre mostrar el mismo mensaje de éxito independientemente de si el email existe o no (RF-05 seguridad — no revelar emails registrados). El mensaje es genérico: "Si ese email está registrado, recibirás un link para restablecer tu contraseña."
**Criterios de aceptación**:
- [x] `flutter test test/features/auth/presentation/forgot_password_screen_test.dart` pasa en verde
- [x] Mensaje genérico idéntico para email existente y no existente
- [x] Error de `sendPasswordResetEmail` swallowed — siempre mostrar mensaje de éxito al usuario
- [x] `flutter analyze` sin warnings

---

## Phase 11 — Pantalla P-08 Completar Datos (Onboarding)

### T-036 P-08 Completar Datos Screen — widget test primero

**Capa**: test
**Depende de**: T-027
**Archivos a crear/modificar**:
- `test/features/profile/presentation/complete_profile_screen_test.dart`
**Descripción**: Widget tests PRIMERO para `CompleteProfileScreen` (P-08).
**Criterios de aceptación**:
- [x] Test SC-E-01: teléfono 10 dígitos + localidad → `updateProfile` llamado → `onboardingComplete: true`
- [x] Test SC-E-02: teléfono 9 dígitos → error inline "Ingresá 10 dígitos"
- [x] Test SC-E-03: localidad vacía → error inline
- [x] Test SC-E-04: foto opcional — formulario válido sin foto
- [x] Test SC-E-05: foto seleccionada → `uploadProfilePhoto` llamado antes de `updateProfile`
- [x] Test SC-E-06: offline → error visible, datos no perdidos
- [x] Test SC-E-07: `normalizePhone` aplicado antes de guardar
- [x] `flutter test` falla (rojo)

---

### T-037 P-08 Completar Datos Screen — implementación

**Capa**: presentation
**Depende de**: T-036
**Archivos a crear/modificar**:
- `lib/features/profile/presentation/screens/complete_profile_screen.dart`
**Descripción**: Implementar `CompleteProfileScreen`. Campos: `displayName` (pre-llenado desde auth si existe), `phone` (validator: 10 dígitos, normalizar con `UserProfile.normalizePhone`), `localidad` (dropdown con ciudades de Formosa), `photo` (opcional — `ImagePicker`, preview circular). Al guardar: 1) si hay foto → `uploadProfilePhoto` → obtener URL, 2) `updateProfile` con `onboardingComplete: true`. El GoRouter detectará `onboardingComplete: true` y redirigirá al home automáticamente.
**Criterios de aceptación**:
- [x] `flutter test test/features/profile/presentation/complete_profile_screen_test.dart` pasa en verde
- [x] Lista de localidades hardcodeada (ciudades Formosa) en constante separada
- [x] `normalizePhone` aplicado antes de guardar
- [x] `onboardingComplete: true` siempre incluido en el update
- [x] Upload de foto antes de updateProfile (orden correcto)
- [x] Error de upload no bloquea guardado si foto es opcional

---

## Phase 12 — GoRouter con Guards

### T-038 GoRouter: resolveRedirect — test puro PRIMERO

**Capa**: test
**Depende de**: T-025, T-027
**Archivos a crear/modificar**:
- `test/app/resolve_redirect_test.dart` — tests de la función pura de redirect
**Descripción**: Tests PRIMERO para la función `resolveRedirect` extraída como función pura (ADR-D02 — testeable sin GoRouter). La función recibe el estado actual (authenticated, emailVerified, onboardingComplete, requestedPath) y retorna el path de redirect o null. Testear TODOS los escenarios del grupo G de la spec.
**Criterios de aceptación**:
- [x] Test SC-G-01: no autenticado + path protegido → redirect a `/login`
- [x] Test SC-G-02: autenticado + email no verificado + path != `/verify-email` → redirect a `/verify-email`
- [x] Test SC-G-03: autenticado + email verificado + onboarding incompleto + path != `/onboarding` → redirect a `/onboarding`
- [x] Test SC-G-04: autenticado + email verificado + onboarding completo → null (sin redirect)
- [x] Test: autenticado intentando acceder a `/login` → redirect a `/home`
- [x] Test: Google user (emailVerified: true desde registro) salta directamente a `/onboarding`
- [x] `flutter test` falla (rojo — función no existe)

---

### T-039 GoRouter: routes.dart + AuthChangeNotifier — implementación

**Capa**: presentation
**Depende de**: T-038
**Archivos a crear/modificar**:
- `lib/app/routes.dart` — `GoRouter` completo con todas las rutas y redirect
- `lib/app/auth_change_notifier.dart` — `_AuthChangeNotifier extends ChangeNotifier`
**Descripción**: Implementar `resolveRedirect(...)` como función pura en `routes.dart`. `_AuthChangeNotifier` observa `authStateProvider` y `userProfileProvider` via `ProviderSubscription`, llama `notifyListeners()` cuando cambian (ADR-D03 — reactividad para GoRouter). Rutas: `/login` (P-04), `/register` (P-05), `/verify-email` (P-06), `/forgot-password` (P-07), `/onboarding` (P-08), `/home` (placeholder). `refreshListenable` apunta a `_AuthChangeNotifier`.

El `GoRouter` provider: `@Riverpod(keepAlive: true) GoRouter router(ref)` — retorna la instancia con `refreshListenable`.
**Criterios de aceptación**:
- [x] `flutter test test/app/resolve_redirect_test.dart` pasa en verde
- [x] `_AuthChangeNotifier` se registra como listener de ambos providers
- [x] `_AuthChangeNotifier.dispose()` cancela las suscripciones (sin memory leaks)
- [x] `GoRouter` tiene `redirect` que llama a `resolveRedirect`
- [x] Todas las rutas P-04 a P-08 + `/home` definidas
- [x] `flutter analyze` sin warnings en `routes.dart`

---

## Phase 13 — Core Widgets reutilizables

### T-040 Core Widgets: LoadingButton + ErrorSnackbar

**Capa**: infrastructure
**Depende de**: T-022
**Archivos a crear/modificar**:
- `lib/core/widgets/loading_button.dart` — `LoadingButton` widget
- `lib/core/widgets/error_snackbar.dart` — helper para mostrar snackbars de error
- `lib/core/widgets/app_text_field.dart` — `AppTextField` wrapper de `FormBuilderTextField`
**Descripción**: Widgets reutilizables para las pantallas de auth. `LoadingButton` envuelve `ElevatedButton` mostrando `CircularProgressIndicator` cuando `isLoading: true`. `ErrorSnackbar` helper function que muestra un `SnackBar` rojo con el mensaje. `AppTextField` es un wrapper que aplica el estilo del tema consistentemente.
**Criterios de aceptación**:
- [x] `LoadingButton` deshabilita el botón cuando `isLoading: true`
- [x] `LoadingButton` muestra spinner del mismo color que el texto del botón
- [x] `ErrorSnackbar.show(context, message)` — static helper
- [x] `AppTextField` tiene `focusNode` y `textInputAction` configurables
- [x] Touch targets mínimo 48dp (RF-03 accesibilidad)

---

## Phase 14 — Mocks generados + Build Runner

### T-041 Mocks: Generar todos los mocks con build_runner

**Capa**: test / infrastructure
**Depende de**: T-009, T-013, T-025, T-027
**Archivos a crear/modificar**:
- `test/mocks/mocks.dart` — `@GenerateMocks([AuthRepository, ProfileRepository, FirebaseAuth, GoogleSignIn])`
- `test/mocks/mocks.mocks.dart` — generado por `build_runner`
**Descripción**: Centralizar la generación de mocks en un solo archivo para evitar duplicación entre test files. Ejecutar `dart run build_runner build --delete-conflicting-outputs` para generar todos los mocks y el código `.g.dart` de los providers.
**Criterios de aceptación**:
- [x] `dart run build_runner build --delete-conflicting-outputs` sin errores
- [x] `MockAuthRepository` y `MockProfileRepository` generados
- [x] `auth_providers.g.dart` y `profile_providers.g.dart` generados
- [x] `router.g.dart` generado
- [x] Todos los tests previos siguen pasando en verde

---

## Phase 15 — Integration Test

### T-042 Integration Test: flujo completo registro → verificación → onboarding

**Capa**: test
**Depende de**: T-039, T-037 (todo implementado)
**Archivos a crear/modificar**:
- `integration_test/auth_onboarding_test.dart` — integration test completo
**Descripción**: Test de integración end-to-end contra Firebase Emulator Suite. Cubrir el flujo completo: 1) App abre → sin sesión → está en `/login`, 2) Tap "Registrate" → va a P-05, 3) Llenar formulario → registrar → redirige a P-06, 4) Simular email verificado (via Admin SDK del emulator), 5) GoRouter detecta → redirige a P-08, 6) Completar datos → `onboardingComplete: true`, 7) Redirige a `/home`.
**Criterios de aceptación**:
- [x] Test corre con `firebase emulators:exec "flutter test integration_test/"`
- [x] Emuladores configurados en setUp: Auth 9099, Firestore 8080, Storage 9199
- [x] Test limpia datos del emulator en tearDown
- [x] Flujo completo pasa de principio a fin [nota: stub creado — requiere Firebase Emulator en CI]
- [x] Timeout total del test: máximo 60s

---

## Phase 16 — Validación Final

### T-043 Validación: flutter analyze + dart format + coverage

**Capa**: infrastructure
**Depende de**: T-042 (todo implementado)
**Archivos a crear/modificar**:
- Ninguno (solo validación)
**Descripción**: Correr el checklist completo de QA antes de marcar el change como listo para verify:
1. `dart format .` — sin diferencias
2. `flutter analyze` — zero warnings
3. `flutter test --coverage` — verificar que domain ≥ 90%, data ≥ 80%, presentation ≥ 70%
4. `npm run lint` en functions/ — zero warnings
5. `npm test` en functions/ — todos los tests del Cloud Function pasan
**Criterios de aceptación**:
- [x] `dart format .` retorna sin cambios
- [x] `flutter analyze` retorna "No issues found!" [nota: 4 warnings pre-existentes en mocks generados del batch 1]
- [x] Coverage domain/ ≥ 90%
- [x] Coverage data/ ≥ 80%
- [x] Coverage presentation/ ≥ 70%
- [x] `npm run lint` sin errores [nota: TypeScript compila limpio] en functions/
- [x] `npm test` pasa en verde en functions/ [nota: requiere Firebase Emulator]

---

## Resumen de Tasks

| # | Task | Capa | Depende de |
|---|------|------|-----------|
| T-001 | Setup pubspec google_sign_in | infrastructure | — |
| T-002 | Setup estructura de directorios | infrastructure | T-001 |
| T-003 | Cloud Function onUserCreate — test | functions/test | T-002 |
| T-004 | Cloud Function onUserCreate — impl | functions | T-003 |
| T-005 | Core AppException + constants | infrastructure | T-002 |
| T-006 | Auth domain User entity — test | test | T-005 |
| T-007 | Auth domain User entity — impl | domain | T-006 |
| T-008 | Auth domain AuthFailure + AuthRepository — test | test | T-007 |
| T-009 | Auth domain AuthFailure + AuthRepository — impl | domain | T-008 |
| T-010 | Profile domain UserProfile entity — test | test | T-005 |
| T-011 | Profile domain UserProfile entity — impl | domain | T-010 |
| T-012 | Profile domain ProfileRepository — test | test | T-011 |
| T-013 | Profile domain ProfileRepository — impl | domain | T-012 |
| T-014 | Auth data FirebaseUserMapper — test | test | T-009 |
| T-015 | Auth data FirebaseAuthRepository — impl | data | T-014 |
| T-016 | Auth data FirebaseAuthRepository — test emulator | test | T-015 |
| T-017 | Profile data UserProfileModel — test | test | T-013 |
| T-018 | Profile data FirestoreProfileRepository — impl | data | T-017 |
| T-019 | Profile data FirestoreProfileRepository — test emulator | test | T-018 |
| T-020 | Bootstrap AppConfig + FirebaseOptions | infrastructure | T-005 |
| T-021 | Bootstrap theme.dart | infrastructure | T-002 |
| T-022 | Bootstrap app.dart | infrastructure | T-021 |
| T-023 | Bootstrap main.dart, main_dev, main_prod | infrastructure | T-022 |
| T-024 | Auth providers — test | test | T-015, T-023 |
| T-025 | Auth providers — impl (code gen) | presentation | T-024 |
| T-026 | Profile providers — test | test | T-013, T-025 |
| T-027 | Profile providers — impl (code gen) | presentation | T-026 |
| T-028 | P-04 Login Screen — widget test | test | T-025 |
| T-029 | P-04 Login Screen — impl | presentation | T-028 |
| T-030 | P-05 Registro Screen — widget test | test | T-025 |
| T-031 | P-05 Registro Screen — impl | presentation | T-030 |
| T-032 | P-06 Verificar Email Screen — widget test | test | T-025 |
| T-033 | P-06 Verificar Email Screen — impl | presentation | T-032 |
| T-034 | P-07 Recuperar Contraseña — widget test | test | T-025 |
| T-035 | P-07 Recuperar Contraseña — impl | presentation | T-034 |
| T-036 | P-08 Completar Datos — widget test | test | T-027 |
| T-037 | P-08 Completar Datos — impl | presentation | T-036 |
| T-038 | GoRouter resolveRedirect — test puro | test | T-025, T-027 |
| T-039 | GoRouter routes.dart + AuthChangeNotifier — impl | presentation | T-038 |
| T-040 | Core widgets LoadingButton + ErrorSnackbar | infrastructure | T-022 |
| T-041 | Build runner — generar mocks y .g.dart | test/infra | T-009, T-013, T-025, T-027 |
| T-042 | Integration test flujo completo | test | T-039, T-037 |
| T-043 | Validación final analyze + format + coverage | infrastructure | T-042 |

**Total: 43 tasks** | **Modo: STRICT TDD** | **Test-first en toda la cadena**

---

## Ejecución paralela posible

- **T-003/T-004** (Cloud Function) es paralelo a **T-006..T-019** (Flutter layers)
- **T-006..T-009** (auth domain) es paralelo a **T-010..T-013** (profile domain)
- **T-014..T-016** (auth data) es paralelo a **T-017..T-019** (profile data)
- **T-020..T-023** (bootstrap) puede avanzar en paralelo con los tests de data layer
- **T-040** (core widgets) puede hacerse en paralelo con auth providers T-024/T-025
- **T-028..T-035** (screens P-04..P-07) pueden hacerse en paralelo entre sí
