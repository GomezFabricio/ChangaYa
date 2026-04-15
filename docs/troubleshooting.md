# Troubleshooting — ChangaYa

Registro de problemas encontrados en desarrollo y cómo se resolvieron.
Ordenado por fecha descendente (más reciente arriba).

---

## 2026-04-13 — "Guardar perfil" no navega a /home tras save exitoso

### Síntoma

En `CompleteProfileScreen`, al tocar "Guardar perfil":
1. El perfil se escribe correctamente en Firestore (verificado vía admin REST).
2. La UI se queda estática — no navega a /home.

Workaround previo: cerrar y reabrir la app.

### Causa raíz

El screen dependía 100% del stream de Firestore `.snapshots()` para detectar
el cambio de `onboardingComplete` y dejaba que GoRouter redirect decidiera
la navegación. Ese listener contra el emulador Android es flaky (ver
sección anterior sobre Firestore listeners).

### Fix aplicado — patrón híbrido declarativo + imperativo

**Archivo:** `lib/features/profile/presentation/screens/complete_profile_screen.dart`

```dart
await notifier.saveProfile(profile);
if (!mounted) return;
final state = ref.read(saveProfileProvider);
if (state is AsyncError) {
  showErrorSnackbar(context, '...');
  return;
}
// Navegación imperativa tras save exitoso.
context.go('/home');
```

Se agregó `import 'package:go_router/go_router.dart';` y se reemplazó la
confianza ciega en el listener por una navegación imperativa tras save
exitoso.

### Filosofía

GoRouter propone un modelo declarativo puro: el estado cambia, el router
observa, navega automáticamente. Ese modelo es correcto para cambios de
estado globales (login/logout, expiración de token, suspensión del user).

Para **acciones explícitas del usuario** (tocar "Guardar", "Crear", etc.)
el patrón imperativo es más apropiado:

- **UX inmediata**: no depende de la latencia del stream.
- **Intent clarísima**: ya sabemos el resultado, no necesitamos deducirlo.
- **Resiliente**: si el stream falla o se atrasa, la navegación igual sucede.

Toda app de producción seria usa este patrón híbrido: declarativo para
flujos de estado, imperativo para acciones del usuario.

### Tests actualizados

`test/features/profile/presentation/complete_profile_screen_test.dart`
ahora monta un `MaterialApp.router` con un `GoRouter` mínimo (stub de /home)
para que `context.go('/home')` funcione en el harness. 52/52 tests del
feature profile pasan.

### Aplica a producción

Este fix NO es un workaround del emulador. Es una mejora general que da
UX más robusta en cualquier entorno (incluyendo Firebase real).

---

## 2026-04-14 — Usuario atascado en /complete-profile tras login

### Síntoma

Tras hacer login con un user existente (email verificado + onboarding completo),
la app navegaba brevemente a `/complete-profile` en vez de `/home`. Una vez
ahí, se quedaba para siempre.

### Causa raíz

El redirect de GoRouter hacía:
1. Login → emite auth state → redirect evalúa en `/login`
2. En ese momento, `userProfileProvider` todavía no emitió el profile →
   `onboardingComplete` resuelve a `false` (default)
3. Redirect manda a `/complete-profile`
4. Profile stream emite → `onboardingComplete=true`
5. Redirect re-evalúa en `/complete-profile`:
   - step 3 (email no verificado): skip
   - step 4 (onboarding incompleto): skip
   - → `return null` (QUEDATE) ← bug

El redirect **empujaba al user hacia** la pantalla correcta cuando tenía estado
incompleto, pero **no lo sacaba de ahí** cuando el estado se volvía completo.

### Fix aplicado

**Archivo:** `lib/app/routes.dart`

Se agregó un step 5 justo antes del `return null` final:

```dart
// 5. Usuario con estado completo pero parado en una pantalla de onboarding
if (location == '/verify-email' || location == '/complete-profile') {
  return '/home';
}
```

### Tests

`test/app/resolve_redirect_test.dart` — 12/12 pasan sin modificar.
Backwards-compatible.

### Aplica a producción

Sí. Este bug afectaba a cualquier user que cerrara la app mientras estaba
en /complete-profile con profile ya guardado — al reabrir la app quedaría
atascado ahí.

### Descubrimiento

Este bug se descubrió escribiendo el test E2E Playwright del flow #2
(login con user existente → home). Sin el fix, el test no podía pasar.

---

## 2026-04-13 — Flash visible de `/home` tras registro/login

### Síntoma

Al completar el registro o login con un usuario que todavía no tiene email
verificado u onboarding completo, se veía **por milisegundos** la pantalla
`/home` ("Home — próximamente") antes de aterrizar en la pantalla correcta
(`/verify-email` o `/complete-profile`). Comportamiento visualmente desprolijo.

### Causa raíz

El redirect de `GoRouter` (en `lib/app/routes.dart`) hacía una cascada de
dos pasos:

1. User autenticado en ruta pública (`/login`, `/register`) → redirect
   ciego a `/home`.
2. Ya en `/home`, re-evalúa: email no verificado → redirect a `/verify-email`.

Esos dos redirects consecutivos provocaban que el framework montara
brevemente `/home` antes de irse al destino final.

### Fix aplicado

**Archivo:** `lib/app/routes.dart`

```diff
- // 2. Autenticado intentando acceder a ruta pública → home
  if (isPublic) {
-   return '/home';
+   if (!emailVerified) return '/verify-email';
+   if (!onboardingComplete) return '/complete-profile';
+   return '/home';
  }
```

En vez de mandar al `/home` y dejar que el próximo redirect corrija, ahora
evaluamos el estado completo del user **en el mismo redirect** y vamos
directo al destino correcto. Un solo redirect = sin flash.

### Tests

`test/app/resolve_redirect_test.dart` — los 12 tests existentes pasan sin
modificar. Los tests cubren los casos principales:
- User no autenticado (5 casos)
- User autenticado, email no verificado (2 casos)
- User autenticado, onboarding incompleto (2 casos)
- User completamente onboarded (3 casos)

El cambio es backwards-compatible porque mantiene el mismo comportamiento
para el user completamente onboarded (→ `/home`) y solo corrige los casos
intermedios que antes pasaban por el flash.

### Aplica a producción

Sí. Es una mejora de UX que aplica igual a dev y prod. No es workaround
de emulador.

---

## 2026-04-13 — Doble tap necesario en "Ya verifiqué mi email"

### Síntoma

Tras marcar el user como verified (vía REST helper en dev, o vía link real
en prod), el usuario debía tocar **dos veces** "Ya verifiqué mi email" para
que la app detectara la verificación y navegara a /complete-profile.

### Causa raíz

Quirk conocido del Firebase Auth SDK en Android: `currentUser.reload()`
refresca los metadatos del user desde el servidor, pero **`emailVerified`
específicamente se propaga vía el ID token**, no vía los metadatos. Sin
forzar un refresh del token también, el primer `currentUser.emailVerified`
post-reload puede devolver el valor stale.

La segunda llamada funciona porque Firebase ya refrescó el token
internamente.

### Fix aplicado

**Archivo:** `lib/features/auth/data/firebase_auth_repository.dart`

```diff
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
+     // Fuerza refresh del ID token para propagar `emailVerified` al
+     // currentUser local.
+     await _firebaseAuth.currentUser?.getIdToken(true);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }
```

### Aplica a producción

Sí. Este fix no es emulator-specific. El quirk de `reload()` + `emailVerified`
en Android afecta también a Firebase real. Los usuarios en prod iban a
experimentar el mismo doble-tap sin este fix.

---

## 2026-04-13 — "Ya verifiqué mi email" no navega tras verificación

### Síntoma

En `EmailVerificationScreen`, al tocar "Ya verifiqué mi email", el método
`reloadUser()` ejecuta correctamente y Firebase actualiza `emailVerified=true`
localmente. Pero la UI se queda estática — GoRouter no re-evalúa el redirect
y el usuario nunca avanza a `/complete-profile`.

El workaround era cerrar y reabrir la app.

### Causa raíz

`FirebaseAuthRepository.authStateChanges` (getter público) usaba internamente
`_firebaseAuth.authStateChanges()` de Firebase. **Ese stream solo emite en
sign-in / sign-out — NO emite cuando propiedades del user cambian (como
`emailVerified` tras `reloadUser()`)**.

Firebase Auth expone tres streams con semántica distinta:

| Stream | Emite en |
|--------|----------|
| `authStateChanges()` | Solo sign-in / sign-out |
| `idTokenChanges()` | Lo anterior + refresh de token |
| `userChanges()` | Lo anterior + cambios en propiedades del user |

El guard chain de GoRouter escucha via `AuthChangeNotifier` → si el stream no
emite, el redirect no re-evalúa. Por eso la UI se quedaba pegada.

### Fix aplicado

**Archivo:** `lib/features/auth/data/firebase_auth_repository.dart`

```diff
  Stream<User?> get authStateChanges {
-   return _firebaseAuth.authStateChanges().map(
+   return _firebaseAuth.userChanges().map(
          (fbUser) =>
              fbUser != null ? FirebaseUserMapper.toDomain(fbUser) : null,
        );
  }
```

El nombre del getter público (`authStateChanges`) se mantuvo porque el
contrato del dominio no cambió — solo la implementación interna.

### Tests afectados

`test/features/auth/data/firebase_auth_repository_test.dart` tenía mocks de
`when(mockFirebaseAuth.authStateChanges())` — se actualizaron a
`when(mockFirebaseAuth.userChanges())`. Los 19 tests del repo pasan.

### Aprendizaje para el futuro

- **Regla mnemotécnica**: si necesitás reaccionar a cambios en propiedades
  del user (`emailVerified`, `displayName`, etc.), usá `userChanges()`.
  `authStateChanges()` solo para flujos de autenticación en el sentido
  estricto (login/logout).
- El comentario del código ya mencionaba "polling automático vía
  authStateChanges para detectar verificación" — pero conceptualmente
  estaba mal. Los comentarios pueden mentir, el código no.

---

## 2026-04-13 — Firestore snapshot listeners flaky en Android emulator

### Síntoma

Tras guardar el perfil en /complete-profile el write llega a Firestore
(confirmado vía admin REST endpoint) pero la UI no navega a /home. El
`userProfileProvider` (basado en `.snapshots()`) no emite el nuevo valor
hasta que la app se reinicia.

### Diagnóstico

Los listeners de Firestore se cierran con errores variados en los logs:

```
W/Firestore: [WatchStream]: Stream closed with status:
  Status{code=RESOURCE_EXHAUSTED, description=HTTP/2 error code: ENHANCE_YOUR_CALM
W/Firestore: [WatchStream]: Stream closed with status:
  Status{code=UNAVAILABLE, description=End of stream or IOException
W/Firestore: Listen for QueryWrapper(...users/{uid}...) failed:
  Status{code=PERMISSION_DENIED
```

Sólo se reproduce en la combinación **Android emulator + Firestore emulator**.
En web (Chrome) contra los mismos emuladores los listeners funcionan normal.
En Firebase real (staging/prod) no se observa.

### Workaround dev-only

Cerrar y reabrir la app — en el nuevo launch el redirect hace una lectura
fresca y evalúa correctamente.

### Causa (hipótesis)

Problema de gRPC/HTTP2 entre el SDK Android y el Firestore emulator local.
No hay fix oficial para este issue en la versión `cloud_firestore: 26.1.0`.

### Posible mejora futura

Para mayor robustez, `SaveProfileNotifier` podría hacer un `getProfile(uid)`
explícito tras `updateProfile(profile)` y dispararlo manualmente en el
provider — independiente del listener. No se aplicó ahora porque:

1. El bug solo ocurre contra emuladores, no en producción
2. Complicaría el código de producción por un workaround de dev
3. El restart-app es aceptable en el flujo de desarrollo

### Validación del flow I-02 (manual)

Registro → verificación (vía REST helper) → onboarding → home: PASS
con el workaround del restart.

---

## 2026-04-13 — "Ocurrió un error inesperado" al registrar en Android emulator

### Síntoma

En el emulador de Android, al intentar cualquier operación de auth (registro por email+password, Google Sign-In desde Register, Continuar con Google desde Login) la app mostraba el snackbar **"Ocurrió un error inesperado."** y no avanzaba.

En Chrome (web) el mismo flujo funcionaba sin problemas.

### Diagnóstico

El mensaje "Ocurrió un error inesperado." proviene del segundo `catch` en los screens de auth:

```dart
// lib/features/auth/presentation/screens/register_screen.dart
} on AuthFailure catch (e) {
  showErrorSnackbar(context, _messageForFailure(e));
} catch (_) {
  showErrorSnackbar(context, 'Ocurrió un error inesperado.');
}
```

Eso significa que la excepción lanzada **no es un `AuthFailure`** — es otra cosa.
En el 99% de los casos esto indica un error de red: la llamada a Firebase
Auth Emulator nunca llegó a destino.

### Causa raíz

En `lib/main_dev.dart` los emuladores estaban configurados con host hardcodeado:

```dart
const emulatorHost = '127.0.0.1';
```

En el emulador de Android, `127.0.0.1` apunta a la **propia VM del emulador**,
no al host Mac que lo hospeda. Por eso la app no podía llegar a los servicios
Firebase que corrían en el host.

Google reserva la IP `10.0.2.2` como alias al host desde un emulador Android.
Otras plataformas (iOS simulator, Chrome, desktop) corren directamente sobre
el host, donde `localhost` / `127.0.0.1` funciona normal.

| Plataforma | Host correcto al Mac |
|------------|----------------------|
| Android emulator | `10.0.2.2` |
| iOS simulator | `localhost` |
| Chrome (web) | `localhost` |
| macOS / Windows / Linux desktop | `localhost` |

### Fix aplicado

**Archivo:** `lib/main_dev.dart`

Se agregó una función helper que resuelve el host según la plataforma en runtime:

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

String _emulatorHost() {
  if (kIsWeb) return 'localhost';
  if (Platform.isAndroid) return '10.0.2.2';
  return 'localhost';
}
```

Y se reemplazó la constante hardcodeada:

```diff
- const emulatorHost = '127.0.0.1';
+ final emulatorHost = _emulatorHost();
```

### Verificación

1. `flutter analyze lib/main_dev.dart` → sin issues.
2. Hot restart de la app en el emulador Android.
3. Registro por email+password → debe avanzar a `/verify-email`.

### Follow-up: "Cleartext HTTP traffic to 10.0.2.2 not permitted"

Tras aplicar el fix del host, el log de Android mostró:

```
E/RecaptchaCallWrapper: Initial task failed for action RecaptchaAction(action=signUpPassword)
  with exception - An internal error has occurred.
  [ Cleartext HTTP traffic to 10.0.2.2 not permitted ]
```

**Causa:** Android 9+ bloquea tráfico HTTP (cleartext) por default. El Firebase
Emulator corre en HTTP plano (no HTTPS), por lo que Android cortaba la
conexión aunque el host fuera correcto.

**Fix aplicado:** `android/app/src/debug/AndroidManifest.xml`

Se permitió cleartext traffic **solo en builds de debug** (el manifest de
debug se mergea únicamente cuando `buildType=debug`, producción queda
intacta):

```xml
<application
    android:usesCleartextTraffic="true"
    tools:replace="android:usesCleartextTraffic"
    xmlns:tools="http://schemas.android.com/tools" />
```

**Alternativas consideradas y por qué se descartaron:**

- `usesCleartextTraffic="true"` en el manifest de `src/main/` → habilitaría
  HTTP en producción también. Inseguro.
- `network_security_config.xml` con hosts específicos (localhost, 10.0.2.2)
  → más quirúrgico, pero requiere archivo XML adicional y más config.
  Válido si en el futuro se quiere restringir más. Para dev-only alcanza
  con lo aplicado.

**Requiere:** rebuild completo (stop + flutter run). No alcanza con hot restart
porque el manifest es parte del APK.

### Notas sobre Google Sign-In

Google Sign-In contra el Firebase Auth Emulator puede requerir configuración
adicional aparte del fix de red (SHA-1 del debug keystore registrado en el
Firebase project de dev, `google-services.json` correcto). Si el fix de red
no resuelve el flujo de Google, diagnosticar con `adb logcat` y logs del
Auth Emulator antes de tocar más código.

### Aprendizaje para el futuro

- **Síntoma "Error inesperado" en flujos que usan red → sospechar del host del
  emulador antes de mirar la lógica de negocio.**
- El integration test automatizado en `integration_test/auth_flow_test.dart`
  NO habría atrapado este bug, porque el test corre desde el host Mac
  directamente (donde `127.0.0.1` funciona). Este tipo de bugs solo se
  detectan con testing manual o E2E sobre el device real.
