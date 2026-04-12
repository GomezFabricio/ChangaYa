# ChangaYa - functions/ (Cloud Functions Backend)

<!-- type: backend -->

> **Stack:** Cloud Functions v2 + TypeScript strict + Node.js 20 + Firebase Admin SDK

---

## Auto-invoke Skills

When performing these actions, ALWAYS invoke the corresponding skill FIRST:

| Action | Skill |
|--------|-------|
| Crear nueva Cloud Function | Leer `docs/00-project-init/RFC.md` sección 3.6 (Catálogo de Cloud Functions) |
| Implementar lógica de suscripción | Verificar ADR-03 en RFC — modelo freemium por visibilidad |
| Tocar webhook de Mercado Pago | Verificar E.5 en context.md — validación HMAC-SHA256 obligatoria |

---

## CRITICAL RULES — NON-NEGOTIABLE

### Idempotencia

- **Toda Cloud Function es idempotente.** Los recálculos se hacen desde cero (full recalculation), nunca con incrementos.
- Una doble ejecución del mismo trigger debe producir el mismo resultado final.
- Ejemplo correcto: recalcular `rating.average` leyendo TODAS las reseñas del prestador.
- Ejemplo incorrecto: `rating.average = rating.average + (newRating / count)`.

### Concurrencia

- Las operaciones con condiciones de carrera usan **Firestore transactions** (`runTransaction`).
- Nunca asumir que dos escrituras concurrentes no van a colisionar.

### Campos protegidos

Los siguientes campos son escritos **EXCLUSIVAMENTE por Cloud Functions**. Nunca por el cliente:
- `providers.rating` (average + count)
- `providers.plan`
- `providers.isVerified`
- `providers.searchKeywords`
- `providers.completionPercentage`
- `providers.responseRate`
- `subscriptions.*`

### Enforcement de límites de plan

- Los límites del plan (`maxPhotos`, `maxCategories`, `maxZones`, `maxActiveRequests`) se validan **exclusivamente en Cloud Functions**, nunca en el cliente.
- `onProviderWrite` valida fotos/categorías/zonas al escribir.
- `onRequestCreate` valida `maxActiveRequests` antes de crear.
- Si el usuario excede el límite: la operación falla silenciosamente (datos extra descartados). El cliente recibe el documento actualizado sin los campos excedentes.

### Seguridad — Obligatoria

- **Webhook Mercado Pago:** Validar firma HMAC-SHA256 antes de procesar CUALQUIER evento. Sin validación → responder 401 inmediatamente.
- **Asignación de rol provider (`setProviderRole`):** Verificar que `uid` del caller coincide con `uid` del documento que se modifica. Toda asignación queda registrada en `admin_log/`.
- **Rate limiting en mensajes:** Máximo 10 mensajes por minuto por usuario. Responder 429 si se excede.
- **Verificación de suspensión:** Las operaciones sensibles (crear solicitud, enviar mensaje) verifican `users.suspendedUntil` **server-side** antes de ejecutar.

### File Uploads

- Tipos permitidos: `image/jpeg`, `image/png`, `image/webp` únicamente.
- Tamaño máximo: 5MB por archivo.
- Headers de respuesta incluyen `Content-Disposition: attachment` para prevenir ejecución en el browser.

### Auditoría

- **Toda acción del admin queda registrada en `admin_log/`** con `adminId`, `action`, `targetType`, `targetId`, `note`, `metadata`, `createdAt`.
- Los mensajes de sistema en el chat los crea la Cloud Function `onRequestUpdate`, **no el cliente**.

### Deployment

- Región de deploy: **southamerica-east1** (misma que Firestore — reduce latencia).
- TypeScript strict: `strict: true` en `tsconfig.json`. Sin `any` explícito.
- Linting: ESLint `@typescript-eslint/recommended` + Prettier.

---

## TECH STACK

| Componente | Tecnología | Versión |
|---|---|---|
| Runtime | Node.js | 20 |
| Lenguaje | TypeScript | strict |
| Framework | Firebase Functions v2 | latest |
| Admin SDK | firebase-admin | latest |
| Linting | ESLint + @typescript-eslint | latest |
| Formatter | Prettier | latest |
| Tests | Jest + Firebase Emulator Suite | latest |

---

## CLOUD FUNCTIONS CATALOG

| Función | Tipo | Trigger | Responsabilidad |
|---|---|---|---|
| `onUserCreate` | Auth trigger | Crear cuenta | Crea `users/` y `subscriptions/` iniciales |
| `setProviderRole` | Callable | Cliente invoca | Asigna Custom Claim `provider` + `admin_log/` |
| `onProviderWrite` | Firestore trigger | onWrite `providers/{uid}` | Recalcula `searchKeywords`, `completionPercentage` |
| `onRequestCreate` | Firestore trigger | onCreate `service_requests/` | Push Pro / in-app free; valida `maxActiveRequests` |
| `onRequestUpdate` | Firestore trigger | onUpdate `service_requests/` | Notificaciones; mensajes de sistema; `responseRate` |
| `onReviewCreate` | Firestore trigger | onCreate `reviews/` | Full recalculation del rating |
| `onMessageCreate` | Firestore trigger | onCreate `messages/` | Push al destinatario; rate limit 10/min |
| `checkExpiredRequests` | Scheduled | Cada hora | `pending` con `expiresAt` vencido → `expired` |
| `checkAutoComplete` | Scheduled | Cada hora | `awaiting_confirmation` timeout → `completed` |
| `onSubscriptionExpire` | Scheduled | Diaria | Trials/suscripciones vencidas → plan `free` |
| `processSubscription` | HTTP (webhook) | Mercado Pago | Valida HMAC-SHA256, activa/renueva `pro` |

---

## PROJECT STRUCTURE

```
functions/
├── src/
│   ├── index.ts               # Exports de todas las funciones
│   ├── auth/
│   │   ├── onUserCreate.ts    # Auth trigger: crea docs iniciales
│   │   └── setProviderRole.ts # Callable: asigna Custom Claim provider
│   ├── providers/
│   │   └── onProviderWrite.ts # Recalcula searchKeywords + completionPercentage
│   ├── requests/
│   │   ├── onRequestCreate.ts # Push/in-app + valida límites
│   │   ├── onRequestUpdate.ts # Notificaciones + mensajes sistema + responseRate
│   │   ├── checkExpired.ts    # Scheduled: pending → expired
│   │   └── checkAutoComplete.ts # Scheduled: awaiting → completed
│   ├── reviews/
│   │   └── onReviewCreate.ts  # Full recalculation rating
│   ├── messages/
│   │   └── onMessageCreate.ts # Push + rate limiting
│   ├── subscriptions/
│   │   ├── processSubscription.ts # Webhook Mercado Pago
│   │   └── onSubscriptionExpire.ts # Scheduled: downgrade a free
│   └── utils/
│       ├── sendPushToUser.ts  # Helper: envía FCM a tokens de usuario
│       └── helpers.ts         # Utilidades compartidas
├── package.json
└── tsconfig.json
```

---

## COMMANDS

```bash
# Desarrollo
cd functions
npm run build          # Compilar TypeScript
npm run lint           # ESLint + Prettier check
npm run serve          # Emulador local (desde raíz: firebase emulators:start)

# Tests
npm test               # Jest contra Firebase Emulator

# Deploy
firebase deploy --only functions
firebase deploy --only functions:onRequestCreate  # Deploy función específica
```

---

## QA CHECKLIST BEFORE COMMIT

- [ ] TypeScript compila sin errores (`npm run build`)
- [ ] ESLint + Prettier sin warnings (`npm run lint`)
- [ ] Sin `any` explícito en el código
- [ ] Toda función nueva es idempotente (verificar con test de doble ejecución)
- [ ] Si toca campos protegidos: verificar que NO hay path de escritura desde el cliente
- [ ] Si toca roles: verificar validación `uid caller == uid documento`
- [ ] Si toca el webhook: verificar que valida HMAC-SHA256 antes de cualquier lógica
- [ ] Si toca mensajes: verificar rate limiting implementado
- [ ] Acción de admin registrada en `admin_log/`
- [ ] Región de deploy es `southamerica-east1`
