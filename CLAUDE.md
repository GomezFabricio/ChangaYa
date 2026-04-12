# ChangaYa - Project Guidelines

## How to Use This Guide

- Start here for project norms
- Each component has its own `CLAUDE.md`:
  - `lib/CLAUDE.md` — Flutter frontend (Android, iOS, Web)
  - `functions/CLAUDE.md` — Cloud Functions backend (TypeScript)
  - `test/CLAUDE.md` — Testing conventions

Component docs override this file when conflicts exist.

---

## Available Skills

### SDD Skills (Spec-Driven Development)

| Skill | Description |
|-------|-------------|
| `sdd-init` | Bootstrap SDD structure and detect testing capabilities |
| `sdd-explore` | Investigate ideas; reads codebase, compares approaches |
| `sdd-apply` | Implement tasks in batches with progress tracking |
| `sdd-verify` | Validate implementation against specs |
| `sdd-archive` | Close a change and persist final state |
| `sdd-onboard` | Guided end-to-end walkthrough of SDD |

### Framework Skills

| Skill | Description |
|-------|-------------|
| `prd` | Generate PRD.md from context.md |
| `rfc` | Generate RFC.md from context.md + PRD.md |
| `sdd-setup` | Phase 0 setup: PRD + RFC + CLAUDE.md + deps + sdd-init |
| `definition-agent-rules` | Generate CLAUDE.md files from PRD + RFC |

### Project Skills

| Skill | Description |
|-------|-------------|
| `commit-convention` | Conventional commits enforcement |
| `branch-pr` | Branch and PR creation workflow |

---

## Project Overview

| Component | Location | Tech Stack |
|-----------|----------|------------|
| App Móvil / Web | `lib/` | Flutter 3.x + Dart 3.x + Riverpod 2.x + GoRouter 14.x |
| Cloud Functions | `functions/` | Node.js 20 + TypeScript + Firebase Functions v2 |
| Tests | `test/` | flutter_test + mockito + Firebase Emulator Suite |

**Tipo de producto:** Marketplace two-sided de servicios locales — Formosa, Argentina
**Alcance:** Android (primario), iOS, Web (admin panel)
**Backend:** Serverless (Firebase plan Blaze — southamerica-east1)

---

## Project Structure

```
changaya/
├── lib/
│   ├── main.dart
│   ├── main_dev.dart
│   ├── main_prod.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── routes.dart
│   │   └── theme.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── utils/
│   │   └── widgets/
│   ├── features/
│   │   ├── auth/
│   │   ├── profile/
│   │   ├── search/
│   │   ├── service_request/
│   │   ├── reviews/
│   │   ├── notifications/
│   │   ├── subscription/
│   │   └── admin/
│   └── services/
├── functions/
│   ├── src/
│   │   ├── index.ts
│   │   ├── auth/
│   │   ├── providers/
│   │   ├── requests/
│   │   ├── reviews/
│   │   ├── messages/
│   │   ├── subscriptions/
│   │   └── utils/
│   ├── package.json
│   └── tsconfig.json
├── test/
├── firebase.json
├── firestore.rules
├── storage.rules
├── firestore.indexes.json
└── pubspec.yaml
```

---

## Commit & Pull Request Guidelines

Follow conventional-commit style: `<type>[scope]: <description>`

**Types:** `feat`, `fix`, `docs`, `chore`, `perf`, `refactor`, `style`, `test`

**Examples:**
```
feat(auth): add Google Sign-In support
fix(search): correct relevance formula boost calculation
test(service_request): add state machine transition tests
```

Before creating a PR:
1. Run `flutter analyze` — zero warnings
2. Run `flutter test` — all tests pass
3. Run `dart format .` — formatted
4. For functions: `npm run lint` + `npm test`

---

## Code Style — General

- **Dart / Flutter:** `flutter analyze` strict + `dart format`. Nombres en inglés (código). Comentarios en español cuando aclaren lógica de negocio no obvia.
- **TypeScript:** ESLint `@typescript-eslint/recommended` + Prettier. `strict: true` en `tsconfig.json`. Sin `any` explícito.
- **Branches:** `main` → producción. `develop` → integración. `feature/[slug]` → features. `fix/[slug]` → bugs.
- **Commits:** Conventional Commits. Sin "Co-Authored-By" ni atribuciones de IA.

---

## Environments

| Entorno | Infraestructura | Entry point |
|---------|----------------|-------------|
| Desarrollo | Firebase Emulator Suite (local) | `main_dev.dart` |
| Staging | `changaya-staging` (Firebase project) | `main_dev.dart` + staging config |
| Producción | `changaya-prod` (Firebase project) | `main_prod.dart` |

```bash
# Iniciar emuladores
firebase emulators:start

# Correr app contra emuladores
flutter run -t lib/main_dev.dart

# Deploy producción
firebase deploy --only functions,firestore:rules,storage:rules,hosting
```

---

## Security — Non-Negotiable Rules

Estas reglas aplican a TODO el proyecto. Son no negociables y se implementan antes del lanzamiento:

1. **Webhook Mercado Pago:** Validar firma HMAC-SHA256 antes de procesar cualquier evento. Sin validación → 401.
2. **Asignación de rol provider:** Cloud Function verifica `uid caller == uid documento`. Toda asignación queda en `admin_log/`.
3. **File uploads:** Tipos permitidos = `image/jpeg`, `image/png`, `image/webp`. Máximo 5MB. Header `Content-Disposition: attachment`.
4. **Rate limiting mensajes:** Máximo 10 por minuto por usuario. Responde 429 si se excede.
5. **Verificación suspensión:** Las operaciones sensibles (crear solicitud, enviar mensaje) verifican `users.suspendedUntil` server-side, nunca solo en cliente.
6. **Límites de plan:** Los límites del plan se validan EXCLUSIVAMENTE en Cloud Functions, nunca en el cliente.

---

## Architecture — Key Decisions

- **Clean Architecture por feature:** `data/` → `domain/` → `presentation/`. Las capas no se saltan.
- **Riverpod 2.x:** Estado global con `keepAlive: true`. Estado de feature con `autoDispose`. Sin GetX, sin BLoC.
- **GoRouter 14.x:** Toda navegación centralizada en `routes.dart`. Los widgets no usan `MaterialPageRoute` directamente.
- **Firestore:** Sin JOINs. Dos queries para perfil + reseñas. Cache offline habilitado.
- **Cloud Functions idempotentes:** Full recalculation siempre. Nunca incrementos.
- **Freemium:** Visibilidad diferenciada (push, Recomendados, +50% boost), no límites funcionales. Ver `docs/00-project-init/RFC.md` ADR-03.
