# Verify Report: I-02 Auth + Onboarding

**Change**: auth-onboarding
**Verifier**: sdd-verify agent
**Date**: 2026-04-13
**Test result**: 163/163 flutter tests pass

---

## CRITICAL (bloqueantes para merge)

- ❌ **Contraseña: validación incorrecta en RegisterScreen** — `lib/features/auth/presentation/screens/register_screen.dart` líneas 165, 183-184. La validación revisa solo `value.length < 6` con mensaje "al menos 6 caracteres". Spec RF-01.3 y SC-A-03 exigen ≥8 caracteres + mayúscula + número, con mensaje exacto: _"La contraseña debe tener al menos 8 caracteres, una mayúscula y un número"_. El test `should_show_error_when_password_too_short` también testea 6 chars, no 8, por lo que pasa en falso positivo.

- ❌ **Campo `displayName` recogido en P-05 pero nunca persistido** — `register_screen.dart` línea 57-60: `registerWithEmail` se llama solo con `email` y `password`. El `_nameController` tiene datos pero se descarta silenciosamente. La interfaz `AuthRepository.registerWithEmail` (design.md línea 373) define la firma como `registerWithEmail(String email, String password, String name)`. En el documento `users/{uid}` el campo `displayName` quedaría vacío para usuarios email/password. Viola RF-01 (el nombre es campo obligatorio en el form) y la spec de schema Firestore (spec línea 723).

- ❌ **Campo Firestore `localidad` vs `locality` — mismatch de schema** — `lib/features/profile/data/user_profile_model.dart` línea 43 y 62: `toFirestore()` escribe y lee el campo como `'localidad'`. La spec (RF-06.5, SC-E-01, SC-E-02, y schema línea 726) define el campo como `locality`. Producirá documentos Firestore con campo incorrecto, incompatible con el resto del backend y las Firestore Rules futuras.

- ❌ **`uploadProfilePhoto` lanza `UnimplementedError`** — `lib/features/profile/data/firestore_profile_repository.dart` línea 72. La subida de foto al Storage (RF-06.4) no está implementada. Cualquier usuario que intente subir una foto de perfil en P-08 verá un crash. SC-E-01 (flujo con foto) no puede completarse.

---

## WARNING (importante pero no bloqueante)

- ⚠️ **Confirm password ausente en P-05** — La pantalla `register_screen.dart` no tiene campo "Confirmar contraseña". Spec SC-A-05 exige validación de coincidencia de contraseñas con error inline "Las contraseñas no coinciden". El test tampoco cubre este escenario.

- ⚠️ **`updatedAt` no seteado en `updateProfile`** — `firestore_profile_repository.dart` línea 56-62: el método `updateProfile` no incluye `updatedAt: FieldValue.serverTimestamp()` en el merge. El schema spec (línea 732) define `updatedAt: timestamp`. Sin este campo, no es posible saber cuándo se actualizó el perfil por última vez.

- ⚠️ **`subscriptions/{uid}` sin campo `status`** — `functions/src/auth/on_user_create.ts` línea 41-45: el batch no incluye `status: 'active'`. El schema spec (línea 741) define `status: 'active' | 'cancelled'`. Cuando se implemente `onSubscriptionExpire`, leer el `status` retornará `undefined` para usuarios creados antes de la corrección.

- ⚠️ **Botón "Ya verifiqué mi email" es no-op** — `email_verification_screen.dart` líneas 88-96: el botón existe pero no hace nada. Depende solo del stream `authStateChanges` que Firebase re-emita `emailVerified: true`. En la práctica, Firebase Auth en mobile no siempre refresca el token en background — se requiere un `await FirebaseAuth.instance.currentUser?.reload()` antes de que el stream emita el cambio. RF-04.4: _"verifica el estado de verificación al volver al foco"_. Sin `reload()`, el usuario puede haber verificado su email pero la app no redirige hasta el próximo cold start.

- ⚠️ **4 warnings `duplicate_ignore` en mocks generados** — `test/features/auth/data/firebase_auth_repository_test.mocks.dart` línea 1186, `test/features/profile/data/firestore_profile_repository_test.mocks.dart` líneas 509, 1002, 1219. Archivos generados manualmente con `// ignore: must_be_immutable` duplicados. Corregible corriendo `build_runner` (T-041 fue marcado como completado pero usó mocks manuales). No afectan funcionalidad pero `flutter analyze test/` muestra 4 warnings.

---

## SUGGESTION (mejoras opcionales)

- 💡 **Integration test (T-042) es stub** — `integration_test/auth_flow_test.dart` está skipeado con `TODO`. No bloquea el merge pero dejar constancia en backlog para cuando CI tenga Firebase Emulator disponible.

- 💡 **`AuthChangeNotifier` podría suscribirse a `userProfileProvider` solo cuando hay usuario** — actualmente escucha ambos streams siempre. Optimización menor — sin impacto funcional.

- 💡 **`signInWithGoogle` cancellation lanza `AuthFailure.operationNotAllowed`** — semánticamente podría ser una excepción más específica (`cancelled`) para que la UI no muestre un snackbar de error cuando el usuario simplemente cancela. RF-02.5 especifica "retorna al estado previo sin error visible".

---

## PASSED

- ✅ **163/163 tests pasan** — `flutter test test/` sin errores.
- ✅ **`flutter analyze lib/` — 0 issues** — código de producción limpio.
- ✅ **`dart format .` — 0 cambios** — formato correcto.
- ✅ **Estructura de archivos completa** — todos los 45 archivos esperados existen en las rutas correctas.
- ✅ **`lib/features/auth/domain/user.dart` — zero Firebase imports** — entidad de dominio pura.
- ✅ **`AuthRepository` interface completa** — todos los métodos del contrato presentes: `authStateChanges`, `currentUser`, `signInWithEmail`, `signInWithGoogle`, `registerWithEmail`, `sendEmailVerification`, `sendPasswordResetEmail`, `signOut`.
- ✅ **`resolveRedirect()` extraída como función pura** — ADR-D02 cumplido. 12 tests unitarios sin instanciar GoRouter.
- ✅ **GoRouter guard chain correcto** — cascada auth → emailVerified → onboardingComplete implementada en `routes.dart`.
- ✅ **Google OAuth bypass P-06** — RF-02.4 cumplido: `emailVerified: true` en el user hace que `resolveRedirect` salte `/verify-email` y vaya directo a `/complete-profile` o `/home`.
- ✅ **`main_dev.dart` conecta emuladores** — Auth 9099, Firestore 8080, Storage 9199 (T-023).
- ✅ **`onUserCreate` — v1 trigger, batch atómico, idempotente, región southamerica-east1** — ADR-D01 cumplido.
- ✅ **`EmailVerificationNotifier` — cooldown 60s con `ref.onDispose` timer cleanup** — ADR-D04 cumplido.
- ✅ **`FirebaseAuthRepository` — constructor injection** — testable, todas las excepciones Firebase mapeadas a `AuthFailure`.
- ✅ **Riverpod keepAlive / autoDispose correctamente asignados** — auth y profile providers en keepAlive; EmailVerification y SaveProfile en autoDispose.
- ✅ **`AuthChangeNotifier` bridge Riverpod → GoRouter** — se suscribe a `authStateChangesProvider` y `userProfileProvider`.
- ✅ **`functions/src/index.ts` exporta `onUserCreate`** — deploy-ready.
- ✅ **Todos los 43 tasks marcados `[x]` en `tasks.md`** — sin tasks pendientes.
- ✅ **TDD evidenciado** — test files presentes para todas las capas: domain, data, presentation en auth y profile.

---

## Verdict

**FAIL**

4 issues CRITICAL que deben resolverse antes del merge:
1. Validación de contraseña incorrecta (≥6 vs ≥8 + complejidad) — viola RF-01.3 y SC-A-03
2. `displayName` recogido pero nunca persistido — viola el schema Firestore y la UX esperada
3. Campo Firestore `localidad` vs `locality` — mismatch de schema con la spec
4. `uploadProfilePhoto` no implementado — RF-06.4 no cumplido, crash en SC-E-01

Una vez corregidos estos 4, el change puede hacer merge. Los WARNING son improvements importantes pero no bloqueantes.
