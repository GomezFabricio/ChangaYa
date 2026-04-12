# ChangaYa - test/ (Testing)

<!-- type: tests -->

> **Stack:** flutter_test + mockito + Firebase Emulator Suite + Playwright CLI (E2E web)

---

## CRITICAL RULES — NON-NEGOTIABLE

### TDD — Test Primero Siempre

1. **Test primero, siempre.** Escribir el test que falla ANTES de escribir la implementación.
2. **Red → Green → Refactor.** El ciclo no se completa sin pasar por los tres estados.
3. **Un test, una responsabilidad.** Cada test verifica exactamente una cosa.
4. **No lógica en tests.** Los tests no tienen condicionales (`if`). Si necesitás lógica, son dos tests.
5. **Si un test es difícil de escribir, el diseño está mal.** Los tests difíciles son señal de acoplamiento.

### Aislamiento por capa

- **Tests de `domain/`** (unit): sin Firebase. Usar mocks de repositorio generados con `mockito` + `build_runner`.
- **Tests de `data/`** (integration): usar **Firebase Emulator Suite**. Nunca mockear Firestore directamente.
- **Tests de `presentation/`** (widget): usar mocks del repositorio. Sin Firebase real.
- **Tests E2E del admin dashboard** (Flutter Web): usar Playwright CLI.

### Datos de seed para emuladores

Al correr integration tests contra el emulador, cargar el seed definido:
- 15 categorías
- 30 prestadores ficticios (distribuidos en categorías y zonas)
- 50 solicitudes en distintos estados
- 100 reseñas
- 5 reportes pendientes
- 3 usuarios de prueba: `cliente@test.com`, `prestador@test.com`, `admin@test.com`

---

## PIRÁMIDE DE TESTS

```
              ▲
             / \
            /E2E\         10% — Playwright (admin web)
           /-----\
          / Integ \       20% — Firebase Emulator Suite
         /----------\
        /    Unit    \    70% — flutter_test + mockito
       /--------------\
```

**Target de cobertura:**
- `domain/`: 90% mínimo
- `data/`: 80% mínimo (con Emulator)
- `presentation/` (pantallas críticas): 70% mínimo
- Cloud Functions: 80% mínimo

---

## NAMING CONVENTIONS

```dart
// Formato: should_[comportamiento]_when_[condición]
void main() {
  group('SearchProvider', () {
    test('should_return_providers_when_category_selected', () { ... });
    test('should_boost_pro_providers_in_results', () { ... });
    test('should_return_empty_when_no_match', () { ... });
  });
}
```

```typescript
// Cloud Functions (Jest)
describe('onRequestCreate', () => {
  it('should_send_push_when_provider_is_pro', async () => { ... });
  it('should_create_inapp_notification_for_free_provider', async () => { ... });
  it('should_reject_when_max_active_requests_exceeded', async () => { ... });
});
```

---

## MATRIZ DE COBERTURA

| Capa | Tipo | Cobertura mínima | Herramienta |
|---|---|---|---|
| `domain/` (entidades, lógica pura) | Unit | 90% | flutter_test + mockito |
| `data/` (repositorios Firebase) | Integration | 80% | Firebase Emulator Suite |
| `presentation/` (screens críticas) | Widget | 70% | flutter_test |
| Cloud Functions | Unit + Integration | 80% | Jest + Firebase Emulator |
| Flujos E2E (admin web) | E2E | Golden paths | Playwright CLI |

---

## PROJECT STRUCTURE

```
test/
├── unit/
│   ├── features/
│   │   ├── auth/
│   │   ├── search/
│   │   ├── service_request/
│   │   └── ...
│   └── core/
├── widget/
│   ├── screens/
│   │   ├── login_screen_test.dart
│   │   ├── search_screen_test.dart
│   │   └── ...
│   └── widgets/
└── integration/
    ├── auth_flow_test.dart
    ├── service_request_flow_test.dart
    └── review_flow_test.dart
```

---

## COMMANDS

```bash
# Unit + widget tests
flutter test

# Con cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html  # Reporte HTML

# Integration tests (requiere emuladores corriendo)
firebase emulators:start --only auth,firestore,storage,functions
flutter test integration_test/

# Shortcut: emuladores + tests en un solo comando
firebase emulators:exec "flutter test integration_test/"

# E2E admin dashboard (Playwright)
npx playwright test
npx playwright test --ui  # Con interfaz visual

# Cloud Functions tests (Jest)
cd functions && npm test
```

---

## QA CHECKLIST

- [ ] Test escrito ANTES de la implementación (TDD)
- [ ] Tests de `domain/` no importan Firebase
- [ ] Tests de `data/` usan Firebase Emulator (no mocks de Firestore)
- [ ] Naming: `should_[comportamiento]_when_[condición]`
- [ ] Cada test verifica exactamente una cosa
- [ ] Cobertura no baja del mínimo por capa
- [ ] Datos de seed cargados antes de integration tests
