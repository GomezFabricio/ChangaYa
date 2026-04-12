# ChangaYa - lib/ (Flutter Frontend)

<!-- type: frontend -->

> **Stack:** Flutter 3.x + Dart 3.x + Riverpod 2.x + GoRouter 14.x + Material 3

---

## Auto-invoke Skills

When performing these actions, ALWAYS invoke the corresponding skill FIRST:

| Action | Skill |
|--------|-------|
| Crear nueva feature o módulo | Leer `docs/00-project-init/RFC.md` sección 3.4 (Arquitectura de Capas) |
| Agregar nuevo provider Riverpod | Verificar si es global (`keepAlive`) o local (`autoDispose`) según scope |
| Implementar nueva pantalla | Verificar que existe widget test antes de implementar (TDD) |

---

## CRITICAL RULES — NON-NEGOTIABLE

### Arquitectura

- **Cada feature es un módulo independiente** con subcarpetas `data/`, `domain/`, `presentation/`. No se mezclan capas entre sí.
- **La lógica de negocio reside en `domain/`** como entidades puras y contratos de repositorio (interfaces). Nunca en widgets ni en providers directamente.
- **Los repositorios en `data/`** implementan los contratos de `domain/` con Firebase. Son los únicos que importan Firebase.
- **La UI en `presentation/`** consume providers Riverpod que exponen datos del repositorio. Los providers no acceden a Firebase directamente.
- La regla de dependencia es **unidireccional:** `presentation/ → domain/ ← data/`. Nunca al revés.

### Estado (Riverpod)

- **Estado global** (sesión, rol, plan): providers con `keepAlive: true`.
- **Estado local de feature**: providers con `autoDispose`.
- Los providers no llaman a Firebase directamente — llaman al repositorio (contrato del `domain/`).

### Navegación

- **Toda navegación centralizada en `app/routes.dart`** con GoRouter y guardias por rol.
- Los widgets **NO navegan** con `MaterialPageRoute` directamente.
- El deep linking para perfiles compartibles por WhatsApp debe funcionar sin autenticación previa.

### UX / Formularios

- **Guardado automático por campo** (patrón LinkedIn): cada campo se guarda al confirmar, sin botón "Guardar todo".
- **Imágenes:** comprimir en cliente antes de subir — 1024px máximo, calidad 80% — usando `flutter_image_compress`.

### Performance

- **Snapshot listeners** solo donde se requiere real-time: chat (`messages/`), estado de solicitud, badge de notificaciones.
- El resto son **queries estáticas** (Futures, no Streams).
- Infinite scroll con páginas de 20 resultados.

### Seguridad (cliente)

- El cliente **NUNCA valida** límites de plan por sí mismo. El servidor es fuente de verdad.
- Las coordenadas del cliente **nunca se almacenan** en Firestore.
- La geolocalización es siempre **opt-in** con permiso explícito.

---

## TECH STACK

| Componente | Tecnología | Versión |
|---|---|---|
| Framework | Flutter | 3.x (stable) |
| Lenguaje | Dart | 3.x |
| Estado | Riverpod | 2.x |
| Navegación | GoRouter | 14.x |
| Formularios | flutter_form_builder + form_builder_validators | 9.x |
| Imágenes | cached_network_image + image_picker + flutter_image_compress | 3.x / 1.x / 2.x |
| UI | Material 3 + google_fonts | Nativo / 6.x |
| Storage local | shared_preferences | 2.x |
| Mapas | flutter_map + latlong2 | 6.x / 0.9.x |
| Geolocalización | geolocator | 11.x (opt-in) |
| Notificaciones locales | flutter_local_notifications | latest |
| Firebase | firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_messaging, firebase_analytics, firebase_crashlytics, firebase_performance | latest stable |

**Paquetes excluidos:** `dio`, `http`, `GetX`, `Hive`, `Isar`, `BLoC/flutter_bloc`, `google_maps_flutter`.

---

## PROJECT STRUCTURE

```
lib/
├── main.dart
├── main_dev.dart              # Entry point con emuladores Firebase
├── main_prod.dart             # Entry point producción
├── app/
│   ├── app.dart               # MaterialApp, tema, navegación raíz
│   ├── routes.dart            # GoRouter con guardias de rol
│   └── theme.dart             # Material 3 con color seed
├── core/
│   ├── constants/             # Enums, valores constantes globales
│   ├── errors/                # Clases de error y excepciones
│   ├── utils/                 # Helpers: formateo de fechas (locale AR), Haversine, validaciones
│   └── widgets/               # Widgets reutilizables: botones, cards, inputs, loading states
├── features/
│   ├── auth/
│   │   ├── data/              # FirebaseAuthRepository (implementa AuthRepository)
│   │   ├── domain/            # User entity, AuthRepository interface
│   │   └── presentation/      # LoginScreen, RegisterScreen, providers Riverpod
│   ├── profile/               # data/ domain/ presentation/
│   ├── search/                # data/ domain/ presentation/
│   ├── service_request/       # data/ domain/ presentation/
│   ├── reviews/               # data/ domain/ presentation/
│   ├── notifications/         # data/ domain/ presentation/
│   ├── subscription/          # data/ domain/ presentation/
│   └── admin/                 # data/ domain/ presentation/
└── services/
    ├── firebase_service.dart  # Inicialización Firebase
    ├── auth_service.dart      # Wrapper FirebaseAuth
    ├── firestore_service.dart # Acceso genérico Firestore
    ├── storage_service.dart   # Wrapper Firebase Storage
    └── notification_service.dart # FCM
```

---

## COMMANDS

```bash
# Análisis y formateo
flutter analyze                          # Zero warnings antes de commit
dart format .                            # Formateo automático

# Tests
flutter test                             # Unit + widget tests
flutter test --coverage                  # Con reporte de cobertura
firebase emulators:exec "flutter test integration_test/"  # Integration tests

# Run
flutter run -t lib/main_dev.dart         # Desarrollo (contra emuladores)
flutter run -t lib/main_prod.dart        # Producción

# Build
flutter build apk --release             # Android
flutter build ipa --release             # iOS
flutter build web --release             # Web (admin panel)
```

---

## QA CHECKLIST BEFORE COMMIT

- [ ] `flutter analyze` sin warnings
- [ ] `dart format .` aplicado
- [ ] Tests unitarios del dominio cubren la lógica nueva
- [ ] Si se agrega pantalla nueva: widget test del golden path
- [ ] Snapshot listeners usados solo donde se requiere real-time
- [ ] Imágenes comprimidas antes de subir (1024px, 80%)
- [ ] No hay navegación con `MaterialPageRoute` fuera de `routes.dart`
- [ ] No hay referencias directas a Firebase en `presentation/` o `domain/`
