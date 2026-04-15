# Spec: I-02 Auth + Onboarding Cliente

**Change**: `auth-onboarding`
**Status**: spec
**Date**: 2026-04-13
**Author**: sdd-spec agent

---

## 1. Requirements Funcionales

### RF-01 — Registro con Email y Contraseña

- RF-01.1: El sistema permite registrar un usuario con email y contraseña.
- RF-01.2: El email debe ser válido (formato RFC 5322).
- RF-01.3: La contraseña debe tener mínimo 8 caracteres, al menos una mayúscula, una minúscula y un número.
- RF-01.4: El sistema verifica si el email ya existe en Firebase Auth antes de intentar el registro. Si existe, muestra error `email-already-in-use`.
- RF-01.5: Tras el registro exitoso, Firebase Auth emite un email de verificación automáticamente.
- RF-01.6: La Cloud Function `onUserCreate` crea `users/{uid}` y `subscriptions/{uid}` de forma atómica (batch write) inmediatamente después del trigger `onCreate`.
- RF-01.7: El usuario es redirigido a la pantalla P-06 (Verificar Email) tras el registro.

### RF-02 — Registro con Google OAuth

- RF-02.1: El sistema permite registrar/iniciar sesión con cuenta Google mediante `google_sign_in`.
- RF-02.2: Si el usuario Google es nuevo, la Cloud Function `onUserCreate` crea los documentos Firestore igual que en RF-01.6.
- RF-02.3: Si el usuario Google ya existe en Firebase Auth, el sistema inicia sesión directamente (no duplica documentos Firestore).
- RF-02.4: Los usuarios autenticados con Google tienen `emailVerified: true` desde el inicio — se omite el paso P-06 y se redirige directamente a P-08 si el onboarding no está completo, o a `/home` si ya lo está.
- RF-02.5: Si el usuario cancela el flujo OAuth (dismiss del picker de Google), el sistema retorna al estado previo sin error visible.

### RF-03 — Login con Email y Contraseña

- RF-03.1: El sistema permite iniciar sesión con email y contraseña registrados previamente.
- RF-03.2: La sesión es persistente: al cerrar y reabrir la app, el usuario continúa autenticado (Firebase Auth maneja la persistencia via SharedPreferences en Android/iOS, IndexedDB en web).
- RF-03.3: Si el email o contraseña son incorrectos, el sistema muestra el error `invalid-credential` sin revelar cuál campo es incorrecto.
- RF-03.4: Firebase Auth aplica bloqueo automático tras múltiples intentos fallidos. El sistema muestra el mensaje `too-many-requests` cuando ocurra.
- RF-03.5: El sistema redirige tras login según el guard chain: si email no verificado → P-06; si perfil incompleto → P-08; si todo OK → `/home`.

### RF-04 — Verificación de Email (P-06)

- RF-04.1: La pantalla P-06 muestra el email al que se envió la verificación.
- RF-04.2: El usuario puede solicitar reenvío del email de verificación.
- RF-04.3: El botón de reenvío tiene un cooldown de 60 segundos (countdown visible). Durante el cooldown, el botón está deshabilitado.
- RF-04.4: La pantalla verifica el estado de verificación al volver al foco (app resume / `onAuthStateChanged`). En cuanto `emailVerified` pasa a `true`, redirige automáticamente al paso siguiente.
- RF-04.5: El usuario puede cerrar sesión desde P-06 y volver a la pantalla de login.
- RF-04.6: Si el usuario vuelve a abrir la app sin haber verificado, vuelve a P-06.

### RF-05 — Recuperar Contraseña (P-07)

- RF-05.1: El sistema permite solicitar un email de recuperación de contraseña ingresando el email registrado.
- RF-05.2: Firebase Auth envía el email de recuperación. El enlace tiene validez de 1 hora (comportamiento estándar de Firebase — no configurable por la app).
- RF-05.3: Si el email no existe en el sistema, el sistema muestra igualmente un mensaje de éxito genérico para no revelar qué emails están registrados.
- RF-05.4: El sistema muestra un mensaje de confirmación al enviar el email, con instrucción de revisar bandeja (incluyendo spam).
- RF-05.5: Si el campo email está vacío o tiene formato inválido, el sistema muestra error de validación antes de llamar a Firebase.

### RF-06 — Onboarding Cliente: Completar Perfil (P-08)

- RF-06.1: La pantalla P-08 solicita: número de teléfono (obligatorio), localidad (obligatorio), foto de perfil (opcional).
- RF-06.2: El teléfono debe tener formato argentino válido: 10 dígitos, comenzando con código de área (ej: `3704123456`). Se acepta con o sin `+54` o `0` prefijo — la app normaliza internamente.
- RF-06.3: La localidad se selecciona de una lista predefinida de localidades de la provincia de Formosa.
- RF-06.4: La foto de perfil es opcional. Si se sube, debe ser JPEG, PNG o WebP, máximo 5MB. Se sube a Firebase Storage en `avatars/{uid}`.
- RF-06.5: Al guardar, el sistema actualiza el documento `users/{uid}` con los campos `phone`, `locality`, `photoURL` (si aplica), y setea `onboardingComplete: true`.
- RF-06.6: Tras guardar exitosamente, el usuario es redirigido a `/home`.
- RF-06.7: Si la actualización falla (offline o error Firestore), el sistema muestra un mensaje de error con opción de reintentar. El usuario no queda en un estado inconsistente.
- RF-06.8: El campo `onboardingComplete` se setea únicamente desde la Cloud Function (vía trigger) en `false` inicial, y desde el cliente en `true` al completar P-08. No hay otro camino.

### RF-07 — Sign Out

- RF-07.1: El usuario puede cerrar sesión desde cualquier pantalla que lo permita.
- RF-07.2: Al cerrar sesión, Firebase Auth invalida el token local.
- RF-07.3: Riverpod descarta todos los providers con `autoDispose` relacionados al usuario actual (profile, onboarding state, etc.).
- RF-07.4: El usuario es redirigido a `/login` inmediatamente tras el sign out.
- RF-07.5: Los providers con `keepAlive: true` (authStateProvider) emiten `null` tras el sign out, triggereando el guard de GoRouter.

### RF-08 — GoRouter Guard Chain

- RF-08.1: El router evalúa el redirect en cascada en un solo callback:
  1. `authState == null` → redirigir a `/login`
  2. `authState != null && !emailVerified` → redirigir a `/verify-email`
  3. `authState != null && emailVerified && !onboardingComplete` → redirigir a `/complete-profile`
  4. Todo OK → permitir navegación normal
- RF-08.2: El redirect se re-evalúa cada vez que `authStateProvider` emite un nuevo valor (usando `refreshListenable`).
- RF-08.3: Las rutas `/login`, `/register`, `/verify-email`, `/forgot-password`, `/complete-profile` son accesibles únicamente en el contexto correcto del guard. Un usuario autenticado con todo completo no puede navegar a `/login`.
- RF-08.4: La pantalla `/home` (stub en este change) es accesible únicamente con auth completa (auth + verified + onboarding).

### RF-09 — Cloud Function `onUserCreate`

- RF-09.1: La función se dispara en el trigger `onAuthUserCreated` de Firebase Functions v2.
- RF-09.2: Crea `users/{uid}` con los campos definidos en ADR-04 (ver Propuesta).
- RF-09.3: Crea `subscriptions/{uid}` con `plan: 'free'`, `status: 'active'`, `createdAt: serverTimestamp()`.
- RF-09.4: Ambas escrituras ocurren en un batch atómico. Si alguna falla, ninguna se aplica.
- RF-09.5: La función es idempotente: si los documentos ya existen (ej: retry de Firebase), usa `set` sin `merge` pero verifica existencia antes. Alternativamente, usa `{merge: false}` y maneja el error `already-exists` sin propagar.
- RF-09.6: La región de deploy es `southamerica-east1`.
- RF-09.7: La función loguea errores con `logger.error()` de Firebase Functions y no expone datos sensibles en logs.

---

## 2. Requirements No Funcionales

### RNF-01 — Performance

- RNF-01.1: La pantalla de login debe ser interactiva en menos de 2 segundos en dispositivos Android mid-range (SD 665 o equivalente).
- RNF-01.2: La operación de sign in (email o Google) debe completarse en menos de 5 segundos en condiciones normales de red (4G). Si supera este tiempo, mostrar indicador de carga.
- RNF-01.3: El guard de GoRouter debe evaluar el redirect de forma sincrónica cuando el estado ya está en caché (no esperar queries adicionales a Firestore en cada navegación).
- RNF-01.4: `onUserCreate` debe completarse en menos de 3 segundos (batch write a Firestore en `southamerica-east1`).

### RNF-02 — Seguridad

- RNF-02.1: Las contraseñas nunca se loguean ni almacenan localmente. Solo Firebase Auth maneja credenciales.
- RNF-02.2: Los tokens de Firebase Auth (ID token) se renuevan automáticamente. La app no los gestiona manualmente.
- RNF-02.3: El campo `role` en `users/{uid}` solo puede ser modificado por Cloud Functions o reglas de Firestore Admin. El cliente no puede escribir ese campo directamente.
- RNF-02.4: Las Firestore Security Rules (fuera de scope de I-02 pero documentadas como TODO) deben garantizar que `users/{uid}` solo es legible/escribible por el propio usuario, y que `role`, `suspendedUntil`, `onboardingComplete` solo son escribibles desde Admin SDK.
- RNF-02.5: Las fotos de perfil (Firebase Storage) deben servirse con `Content-Disposition: attachment` para prevenir ataques XSS. (Implementación en change de security rules — se documenta aquí como constraint).
- RNF-02.6: El flujo de Google Sign-In utiliza el nonce generado por `google_sign_in` para prevenir replay attacks.

### RNF-03 — Accesibilidad

- RNF-03.1: Todos los campos de formulario tienen `Semantics` labels en español.
- RNF-03.2: Los botones de acción tienen tamaño mínimo de 48x48dp (Material Design touch target).
- RNF-03.3: Los mensajes de error son accesibles para screen readers (`Semantics` con `liveRegion: true` o equivalente en Flutter).
- RNF-03.4: El contraste de texto sobre fondos cumple WCAG 2.1 AA (ratio 4.5:1 mínimo para texto normal).

### RNF-04 — Offline / Conectividad

- RNF-04.1: Cuando no hay conexión, el intento de login muestra un mensaje claro: "Sin conexión. Verificá tu red e intentá de nuevo."
- RNF-04.2: Firebase Auth puede restaurar sesiones cacheadas sin conexión (token local válido), pero las operaciones de escritura en Firestore fallarán. La app distingue "sin sesión" de "sin conexión con sesión válida".
- RNF-04.3: La pantalla P-08 muestra error específico si falla la escritura Firestore por offline, con opción de reintentar cuando se restaure la conexión.

### RNF-05 — Testing

- RNF-05.1: Coverage mínimo en `domain/`: 90%.
- RNF-05.2: Coverage mínimo en `data/`: 80%.
- RNF-05.3: Coverage mínimo en `presentation/`: 70%.
- RNF-05.4: Todos los tests usan mocks (mockito) para dependencias externas (Firebase Auth, Firestore). Cero dependencias de red en tests unitarios.
- RNF-05.5: Los tests de Cloud Function corren contra Firebase Emulator Suite.

---

## 3. Scenarios (Given / When / Then)

### Grupo A — Registro

---

**SC-A-01: Registro exitoso con email y contraseña**

```
Given: el usuario está en la pantalla P-05 (Registro)
  And: ingresa email válido no registrado previamente
  And: ingresa contraseña que cumple los requisitos (≥8 chars, mayúscula, minúscula, número)
  And: confirma la contraseña correctamente
When: toca "Registrarse"
Then: Firebase Auth crea el usuario
  And: la Cloud Function onUserCreate crea users/{uid} con onboardingComplete: false
  And: la Cloud Function crea subscriptions/{uid} con plan: free
  And: Firebase Auth envía email de verificación automáticamente
  And: el router redirige a P-06 (Verificar Email)
```

---

**SC-A-02: Registro con email ya registrado**

```
Given: el usuario está en P-05
  And: ingresa un email que ya existe en Firebase Auth
  And: ingresa contraseña válida
When: toca "Registrarse"
Then: el sistema muestra el error "Este email ya está registrado. ¿Querés iniciar sesión?"
  And: NO crea un nuevo usuario
  And: NO dispara onUserCreate
```

---

**SC-A-03: Registro con contraseña débil**

```
Given: el usuario está en P-05
  And: ingresa email válido no registrado
  And: ingresa contraseña de menos de 8 caracteres (ej: "abc123")
When: toca fuera del campo o toca "Registrarse"
Then: el campo muestra error inline "La contraseña debe tener al menos 8 caracteres, una mayúscula y un número"
  And: el botón "Registrarse" permanece deshabilitado (o el submit no llama a Firebase)
```

---

**SC-A-04: Registro con email inválido**

```
Given: el usuario está en P-05
  And: ingresa "usuario@" como email (formato inválido)
When: toca fuera del campo o toca "Registrarse"
Then: el campo muestra error inline "Ingresá un email válido"
  And: no se llama a Firebase Auth
```

---

**SC-A-05: Registro con contraseñas que no coinciden**

```
Given: el usuario está en P-05
  And: ingresa contraseña válida en el campo "Contraseña"
  And: ingresa una contraseña diferente en el campo "Confirmar contraseña"
When: toca "Registrarse"
Then: el campo "Confirmar contraseña" muestra error inline "Las contraseñas no coinciden"
  And: no se llama a Firebase Auth
```

---

**SC-A-06: Registro con Google — usuario nuevo**

```
Given: el usuario está en P-05 o P-04
  And: toca "Continuar con Google"
  And: selecciona una cuenta Google no registrada en ChangaYa
When: completa el flujo OAuth exitosamente
Then: Firebase Auth crea el usuario con emailVerified: true
  And: onUserCreate crea users/{uid} y subscriptions/{uid}
  And: el router evalúa el guard: emailVerified: true → onboardingComplete: false → redirige a P-08
```

---

**SC-A-07: Registro con Google — usuario ya existente**

```
Given: el usuario tiene una cuenta Google ya registrada en ChangaYa con onboarding completo
  And: toca "Continuar con Google"
  And: selecciona la misma cuenta Google
When: completa el flujo OAuth exitosamente
Then: Firebase Auth inicia sesión sin crear usuario duplicado
  And: onUserCreate NO se dispara (usuario ya existe)
  And: el router redirige a /home
```

---

**SC-A-08: Cancelación del flujo Google OAuth**

```
Given: el usuario toca "Continuar con Google"
  And: el picker de cuentas de Google se abre
When: el usuario cierra el picker sin seleccionar cuenta
Then: la app retorna al estado previo (pantalla de login o registro)
  And: no se muestra ningún error
  And: no se crea usuario
```

---

### Grupo B — Login

---

**SC-B-01: Login exitoso con email y contraseña — onboarding completo**

```
Given: el usuario está en P-04 (Login)
  And: tiene cuenta registrada con email verificado y onboarding completo
  And: ingresa email y contraseña correctos
When: toca "Iniciar sesión"
Then: Firebase Auth autentica al usuario
  And: el guard chain evalúa: autenticado + verificado + onboardingComplete: true
  And: el router redirige a /home
```

---

**SC-B-02: Login exitoso — email no verificado**

```
Given: el usuario tiene cuenta registrada pero nunca verificó el email
  And: ingresa credenciales correctas en P-04
When: toca "Iniciar sesión"
Then: Firebase Auth autentica al usuario
  And: el guard chain evalúa: autenticado + emailVerified: false
  And: el router redirige a P-06
```

---

**SC-B-03: Login exitoso — onboarding incompleto**

```
Given: el usuario tiene cuenta con email verificado pero no completó P-08
  And: ingresa credenciales correctas en P-04
When: toca "Iniciar sesión"
Then: Firebase Auth autentica al usuario
  And: el guard chain evalúa: autenticado + verificado + onboardingComplete: false
  And: el router redirige a P-08
```

---

**SC-B-04: Login con credenciales incorrectas**

```
Given: el usuario está en P-04
  And: ingresa email registrado con contraseña incorrecta
When: toca "Iniciar sesión"
Then: el sistema muestra error "Email o contraseña incorrectos"
  And: NO revela si el email existe o no
  And: el usuario permanece en P-04
```

---

**SC-B-05: Login con demasiados intentos fallidos**

```
Given: el usuario ha intentado iniciar sesión con credenciales incorrectas múltiples veces
  And: Firebase Auth ha bloqueado temporalmente el acceso (too-many-requests)
When: el usuario intenta nuevamente
Then: el sistema muestra "Demasiados intentos. Esperá unos minutos e intentá de nuevo."
  And: el botón puede quedar deshabilitado temporalmente
```

---

**SC-B-06: Sesión persistente al reabrir la app**

```
Given: el usuario inició sesión previamente y tiene onboarding completo
  And: cierra la app completamente (kill process)
When: reabre la app
Then: Firebase Auth restaura la sesión desde el token cacheado localmente
  And: el guard chain evalúa el estado y redirige a /home sin mostrar P-04
  And: NO se solicita volver a ingresar credenciales
```

---

**SC-B-07: Login sin conexión**

```
Given: el usuario está en P-04
  And: el dispositivo no tiene conexión a internet
When: ingresa credenciales y toca "Iniciar sesión"
Then: el sistema muestra "Sin conexión. Verificá tu red e intentá de nuevo."
  And: el usuario permanece en P-04
```

---

### Grupo C — Verificación de Email

---

**SC-C-01: Verificación exitosa desde el email**

```
Given: el usuario está en P-06 (Verificar Email)
  And: abre el link de verificación en el email recibido
  And: vuelve a la app (app resume o foreground)
When: Firebase Auth detecta que emailVerified pasó a true (onAuthStateChanged)
Then: el provider authStateProvider emite el nuevo estado con emailVerified: true
  And: GoRouter re-evalúa el redirect
  And: si onboardingComplete: false → redirige a P-08
  And: si onboardingComplete: true → redirige a /home
  And: P-06 nunca vuelve a mostrarse para este usuario
```

---

**SC-C-02: Reenvío de email de verificación**

```
Given: el usuario está en P-06
  And: el botón "Reenviar email" está habilitado (cooldown en 0)
When: toca "Reenviar email"
Then: el sistema llama a sendEmailVerification() en Firebase Auth
  And: el botón se deshabilita inmediatamente
  And: un countdown visible muestra los segundos restantes (60, 59, 58 ... 0)
  And: al llegar a 0, el botón se reactiva
```

---

**SC-C-03: Intento de reenvío durante cooldown**

```
Given: el usuario está en P-06
  And: acaba de enviar un email de verificación (cooldown activo, ej: 45 segundos restantes)
When: intenta tocar el botón de reenvío
Then: el botón está deshabilitado — el toque no tiene efecto
  And: el countdown sigue corriendo normalmente
```

---

**SC-C-04: Sign out desde P-06**

```
Given: el usuario está en P-06 sin haber verificado el email
When: toca "Cerrar sesión" (acción disponible en P-06)
Then: Firebase Auth cierra la sesión
  And: Riverpod descarta los providers autoDispose del usuario
  And: GoRouter detecta authState: null y redirige a /login
```

---

**SC-C-05: Reapertura sin verificar**

```
Given: el usuario registró una cuenta pero cerró la app sin verificar el email
When: reabre la app
Then: Firebase Auth restaura la sesión (token válido)
  And: el guard chain evalúa: autenticado + emailVerified: false
  And: redirige a P-06
```

---

### Grupo D — Recuperar Contraseña

---

**SC-D-01: Recuperación exitosa — email registrado**

```
Given: el usuario está en P-07 (Recuperar Contraseña)
  And: ingresa un email que está registrado en Firebase Auth
When: toca "Enviar instrucciones"
Then: Firebase Auth envía el email de recuperación
  And: el sistema muestra "Te enviamos un email a [email]. Revisá tu bandeja (y spam)."
  And: el enlace del email tiene validez de 1 hora (comportamiento Firebase estándar)
```

---

**SC-D-02: Recuperación — email no registrado**

```
Given: el usuario está en P-07
  And: ingresa un email que NO existe en Firebase Auth
When: toca "Enviar instrucciones"
Then: el sistema muestra el mismo mensaje de éxito genérico "Te enviamos un email..."
  And: NO revela que el email no existe (previene enumeración de usuarios)
```

---

**SC-D-03: Recuperación — campo email vacío**

```
Given: el usuario está en P-07
  And: el campo email está vacío
When: toca "Enviar instrucciones"
Then: el campo muestra error inline "Ingresá tu email"
  And: no se llama a Firebase Auth
```

---

**SC-D-04: Recuperación — email con formato inválido**

```
Given: el usuario está en P-07
  And: ingresa "texto-sin-arroba"
When: toca "Enviar instrucciones"
Then: el campo muestra error inline "Ingresá un email válido"
  And: no se llama a Firebase Auth
```

---

### Grupo E — Onboarding Cliente (P-08)

---

**SC-E-01: Onboarding completo con foto**

```
Given: el usuario llegó a P-08 (Completar Perfil)
  And: ingresa teléfono válido (10 dígitos): "3704123456"
  And: selecciona localidad de la lista: "Formosa"
  And: sube una foto de perfil JPG de 2MB
When: toca "Guardar"
Then: la foto se sube a Firebase Storage en avatars/{uid}
  And: el sistema actualiza users/{uid} con phone, locality, photoURL, onboardingComplete: true
  And: el guard chain detecta onboardingComplete: true
  And: el router redirige a /home
```

---

**SC-E-02: Onboarding completo sin foto**

```
Given: el usuario llegó a P-08
  And: ingresa teléfono válido
  And: selecciona localidad
  And: NO sube foto de perfil
When: toca "Guardar"
Then: el sistema actualiza users/{uid} con phone, locality, onboardingComplete: true
  And: photoURL permanece como la cadena vacía definida por onUserCreate
  And: el router redirige a /home
```

---

**SC-E-03: Onboarding — teléfono inválido**

```
Given: el usuario está en P-08
  And: ingresa "12345" como teléfono (menos de 10 dígitos)
When: toca fuera del campo o toca "Guardar"
Then: el campo muestra error inline "Ingresá un número de teléfono válido (10 dígitos)"
  And: no se llama a Firestore
```

---

**SC-E-04: Onboarding — sin localidad seleccionada**

```
Given: el usuario está en P-08
  And: no seleccionó localidad (campo vacío)
When: toca "Guardar"
Then: el campo localidad muestra error "Seleccioná tu localidad"
  And: no se llama a Firestore
```

---

**SC-E-05: Onboarding — foto con formato no permitido**

```
Given: el usuario está en P-08
  And: intenta subir un archivo .gif o .pdf como foto
When: selecciona el archivo del picker
Then: el sistema rechaza el archivo antes de subirlo
  And: muestra "Solo se permiten imágenes JPG, PNG o WebP"
  And: no se realiza ninguna operación en Firebase Storage
```

---

**SC-E-06: Onboarding — foto mayor a 5MB**

```
Given: el usuario está en P-08
  And: intenta subir una imagen PNG de 7MB
When: selecciona el archivo del picker
Then: el sistema rechaza el archivo antes de subirlo
  And: muestra "La imagen no puede superar los 5MB"
  And: no se realiza ninguna operación en Firebase Storage
```

---

**SC-E-07: Onboarding — falla Firestore por offline**

```
Given: el usuario está en P-08 con teléfono y localidad válidos
  And: el dispositivo pierde conexión antes de guardar
When: toca "Guardar"
Then: el sistema intenta la escritura en Firestore
  And: la operación falla con error de red
  And: muestra "No se pudo guardar. Verificá tu conexión e intentá de nuevo."
  And: el usuario permanece en P-08 con los datos ingresados conservados
  And: onboardingComplete no se setea en true (el documento no se actualiza parcialmente)
```

---

**SC-E-08: Normalización del teléfono**

```
Given: el usuario ingresa "+543704123456" o "03704123456"
When: el sistema procesa el valor
Then: el valor se normaliza a "3704123456" antes de guardar en Firestore
  And: el campo en Firestore contiene siempre el formato normalizado (10 dígitos, sin prefijo)
```

---

### Grupo F — Sign Out

---

**SC-F-01: Sign out exitoso**

```
Given: el usuario está autenticado y en cualquier pantalla con opción de cerrar sesión
When: toca "Cerrar sesión" y confirma (si hay diálogo de confirmación)
Then: Firebase Auth cierra la sesión (revoca token local)
  And: authStateProvider emite null
  And: Riverpod descarta todos los providers autoDispose del usuario (profile, etc.)
  And: GoRouter detecta el cambio y redirige a /login
  And: el usuario no puede navegar "atrás" hacia pantallas autenticadas
```

---

**SC-F-02: Estado limpio tras sign out**

```
Given: el usuario se autenticó como Usuario A y luego hizo sign out
When: el usuario inicia sesión como Usuario B
Then: los providers de Riverpod NO muestran datos cacheados del Usuario A
  And: el perfil cargado corresponde al Usuario B
```

---

### Grupo G — GoRouter Guards

---

**SC-G-01: Usuario no autenticado intenta acceder a /home**

```
Given: no hay usuario autenticado (authState: null)
When: la app intenta navegar a /home (ej: desde un deep link)
Then: GoRouter evalúa el redirect y redirige a /login
  And: el usuario nunca ve /home
```

---

**SC-G-02: Usuario con todo completo intenta acceder a /login**

```
Given: el usuario está autenticado con email verificado y onboarding completo
When: la app intenta navegar a /login (ej: desde un deep link o botón back)
Then: GoRouter evalúa el redirect y redirige a /home
  And: el usuario nunca ve la pantalla de login mientras esté autenticado
```

---

**SC-G-03: Cambio de estado re-evalúa guards automáticamente**

```
Given: el usuario está en P-06 (email no verificado)
When: verifica su email desde el cliente de correo y vuelve a la app
Then: Firebase Auth emite nuevo estado con emailVerified: true
  And: authStateProvider propaga el cambio
  And: refreshListenable de GoRouter dispara re-evaluación del redirect
  And: el router redirige automáticamente (sin acción del usuario) a P-08 o /home según onboardingComplete
```

---

**SC-G-04: Redirect chain — orden de evaluación**

```
Given: un usuario no autenticado
When: intenta acceder a /complete-profile
Then: el redirect evalúa primero "¿autenticado?" → false → redirige a /login
  And: no evalúa emailVerified ni onboardingComplete (cortocircuito)
```

---

### Grupo H — Cloud Function onUserCreate

---

**SC-H-01: Creación de documentos tras registro email/password**

```
Given: Firebase Auth crea un nuevo usuario via email/password
When: el trigger onAuthUserCreated se dispara
Then: la función crea users/{uid} con todos los campos requeridos
  And: la función crea subscriptions/{uid} con plan: free, status: active
  And: ambas escrituras ocurren en batch atómico
  And: la función completa en menos de 3 segundos
```

---

**SC-H-02: Idempotencia de onUserCreate**

```
Given: users/{uid} ya existe en Firestore (ej: el trigger se disparó dos veces por retry de Firebase)
When: la función intenta crear los documentos nuevamente
Then: la función detecta la existencia previa (o maneja el error already-exists)
  And: no sobreescribe datos del usuario existente (o falla silenciosamente)
  And: no genera un error que rompa el flujo de autenticación
```

---

**SC-H-03: Fallo de onUserCreate — usuario debe poder continuar**

```
Given: la Cloud Function onUserCreate falla (error transitorio de Firestore)
  And: el usuario fue creado en Firebase Auth exitosamente
When: el usuario intenta continuar en la app
Then: el frontend detecta que users/{uid} no existe en Firestore
  And: muestra un mensaje de error con opción de reintentar o contactar soporte
  And: el usuario NO queda en un estado irrecuperable
```

---

## 4. Validaciones de Formulario — Resumen

| Campo | Regla | Error |
|-------|-------|-------|
| Email | RFC 5322 — contiene @ y dominio válido | "Ingresá un email válido" |
| Contraseña (registro) | ≥8 chars, ≥1 mayúscula, ≥1 minúscula, ≥1 número | "La contraseña debe tener al menos 8 caracteres, una mayúscula y un número" |
| Confirmar contraseña | Igual a contraseña | "Las contraseñas no coinciden" |
| Teléfono | 10 dígitos, se normaliza quitando +54 o 0 inicial | "Ingresá un número de teléfono válido (10 dígitos)" |
| Localidad | Selección de lista — no puede estar vacío | "Seleccioná tu localidad" |
| Foto de perfil | JPEG / PNG / WebP, máximo 5MB, opcional | "Solo se permiten imágenes JPG, PNG o WebP" / "La imagen no puede superar los 5MB" |

---

## 5. Firestore Document Schemas (Contractual)

### `users/{uid}`
```
{
  uid: string,                        // Firebase Auth UID
  email: string,                      // email del usuario
  displayName: string,                // nombre (vacío si no disponible)
  photoURL: string,                   // URL avatar (vacío si no hay foto)
  phone: string,                      // formato normalizado: "3704123456"
  locality: string,                   // ej: "Formosa", "Clorinda"
  role: 'client' | 'provider' | 'admin',  // seteado por Cloud Function, NO editable por cliente
  onboardingComplete: boolean,        // false → creado por CF; true → seteado por P-08
  emailVerified: boolean,             // se sincroniza desde Firebase Auth via Cloud Functions
  suspendedUntil: timestamp | null,   // fuera de scope I-02
  createdAt: timestamp,               // serverTimestamp()
  updatedAt: timestamp,               // serverTimestamp()
}
```

### `subscriptions/{uid}`
```
{
  uid: string,
  plan: 'free' | 'premium',          // siempre 'free' en I-02
  status: 'active' | 'cancelled',    // siempre 'active' en I-02
  createdAt: timestamp,
}
```

---

## 6. Error Codes Firebase → Mensajes UI

| Firebase Error Code | Mensaje UI (español) |
|---------------------|----------------------|
| `auth/email-already-in-use` | "Este email ya está registrado. ¿Querés iniciar sesión?" |
| `auth/invalid-credential` | "Email o contraseña incorrectos" |
| `auth/too-many-requests` | "Demasiados intentos. Esperá unos minutos e intentá de nuevo." |
| `auth/network-request-failed` | "Sin conexión. Verificá tu red e intentá de nuevo." |
| `auth/user-disabled` | "Tu cuenta fue deshabilitada. Contactá a soporte." |
| `auth/popup-closed-by-user` | (silencioso — no mostrar error) |
| `auth/cancelled-popup-request` | (silencioso — no mostrar error) |
| `storage/unauthorized` | "No tenés permiso para subir esta imagen." |
| `storage/canceled` | (silencioso — el usuario canceló) |
| `firestore/unavailable` | "No se pudo guardar. Verificá tu conexión e intentá de nuevo." |

---

## 7. Definition of Done (vinculada a esta spec)

- [ ] Todos los scenarios del Grupo A (Registro) pasan como tests de widget o integración
- [ ] Todos los scenarios del Grupo B (Login) pasan como tests de widget o integración
- [ ] SC-C-01 a SC-C-05 pasan como tests unitarios o widget
- [ ] SC-D-01 a SC-D-04 pasan como tests de widget
- [ ] SC-E-01 a SC-E-08 pasan como tests de widget o integración
- [ ] SC-F-01 y SC-F-02 pasan como tests unitarios
- [ ] SC-G-01 a SC-G-04 pasan como tests unitarios del redirect logic
- [ ] SC-H-01 a SC-H-03 pasan como tests de Cloud Function con emulador
- [ ] Coverage: domain ≥90%, data ≥80%, presentation ≥70%
- [ ] `flutter analyze` — zero warnings
- [ ] `dart format .` — todo formateado
- [ ] Tabla de error codes implementada en una clase `AuthFailure` o equivalente en domain/errors
