# Project Context — ChangaYa

> Documento de contexto completo del proyecto. Sirve como input para generación de PRD y como referencia técnica unificada del sistema.

## Identificación

- **Nombre del proyecto**: ChangaYa
- **Versión inicial**: 0.1.0-draft (MVP)
- **Fecha**: Marzo 2026
- **Autor/es**: Equipo ChangaYa
- **Tipo de producto**: Marketplace de servicios locales (two-sided market)
- **Alcance geográfico**: Provincia de Formosa, Argentina (expansible a provincias vecinas)
- **Plataformas**: Android (prioritario), iOS, Web

---

## 1. Problem Statement

- **Descripción del problema**:

  El mercado de servicios independientes en la provincia de Formosa opera de forma mayormente informal y fragmentada. Trabajadores independientes —plomeros, electricistas, carpinteros, mecánicos, contadores, pintores, diseñadores gráficos, programadores, entre otros— consiguen sus clientes casi exclusivamente a través de contactos personales, recomendaciones de boca en boca o publicaciones informales en grupos de WhatsApp y Facebook. Del mismo modo, quienes necesitan contratar alguno de estos servicios no disponen de un canal centralizado donde buscar, comparar y contactar prestadores de confianza.

  Desde el lado del prestador, el alcance queda limitado al círculo de conocidos inmediatos, no existe un espacio propio donde mostrar trabajo, experiencia, tarifas y valoraciones previas, y la informalidad del canal dificulta la construcción de una reputación profesional sostenible. Los prestadores de servicios digitales tienen aún menos visibilidad local y suelen migrar a plataformas nacionales donde compiten en desventaja.

  Desde el lado del cliente, quien necesita contratar un servicio recurre a grupos de Facebook, pregunta en WhatsApp o espera una recomendación personal. No existe un mecanismo que permita comparar prestadores, consultar reseñas de otros clientes o verificar la idoneidad de quien se va a contratar. La falta de información genera desconfianza y malas experiencias que podrían evitarse con mayor transparencia.

- **Quién lo sufre**:

  | Rol afectado | Problemas específicos |
  |---|---|
  | Prestadores de oficios tradicionales (plomeros, electricistas, carpinteros, pintores, gasistas, etc.) | Alcance limitado al boca en boca, sin espacio para mostrar portfolio ni acumular reputación verificable, imposibilidad de darse visibilidad más allá del círculo cercano |
  | Prestadores de servicios digitales (diseñadores, programadores, redactores, contadores) | Aún menos visibilidad local, migración forzada a plataformas nacionales donde compiten en desventaja con perfiles de todo el país |
  | Clientes que necesitan contratar servicios | Sin canal organizado para buscar, dependen de recomendaciones personales o grupos de Facebook/WhatsApp, no pueden comparar ni verificar antecedentes, experiencias negativas frecuentes por falta de información |

- **Con qué frecuencia / magnitud**:

  Es un problema cotidiano y persistente. Cada vez que un ciudadano de Formosa necesita un plomero, electricista o cualquier servicio independiente, enfrenta la misma fricción. El mercado de servicios independientes existe y es activo, pero opera sin infraestructura tecnológica que lo organice. La escala es provincial (población de Formosa: ~600.000 habitantes) con alta densidad de trabajadores informales.

- **Soluciones temporales existentes**:

  | Solución actual | Limitaciones |
  |---|---|
  | Grupos de WhatsApp | Sin organización, sin historial, sin reputación verificable, alcance limitado a los miembros del grupo |
  | Grupos de Facebook | Publicaciones se pierden en el feed, sin mecanismo de búsqueda por categoría o zona, sin sistema de calificaciones |
  | Boca en boca personal | Alcance extremadamente limitado, no escalable, depende de la red social del individuo |
  | Plataformas nacionales (Workana, GetOnBoard) | Orientadas al mercado nacional/internacional, no contemplan oficios tradicionales ni la escala local, competencia desigual con perfiles de todo el país |

---

## 2. Solución Propuesta

- **Nombre del producto**: ChangaYa

- **Visión**: Ser la plataforma de referencia para la contratación de servicios independientes en Formosa, donde cualquier vecino pueda encontrar al profesional que necesita con confianza, y cualquier trabajador pueda hacer crecer su negocio más allá de su círculo cercano.

- **Statement de solución**: Este producto resuelve el problema al proveer una plataforma digital centralizada que conecta prestadores de servicios con clientes de la provincia, ofreciendo perfiles profesionales con portfolio y reputación verificable, búsqueda organizada por categoría y zona, un sistema de solicitudes de presupuesto con ciclo de vida completo, y mensajería contextual, todo diseñado para la escala y las características del mercado local formoseño.

- **Componentes de la solución**:

  | Componente | Descripción |
  |---|---|
  | App Móvil (Android/iOS) | Aplicación Flutter multiplataforma para clientes y prestadores. Canal principal de interacción. |
  | App Web | Versión web para navegación pública de perfiles (compartibles por WhatsApp) y acceso al panel de administración. |
  | Panel de Administración | Interfaz web (Flutter Web) para gestión de categorías, usuarios, reportes y verificaciones. |
  | Backend Serverless (Firebase) | Conjunto de servicios administrados: Authentication, Firestore, Storage, Cloud Functions, FCM, Security Rules. |
  | Integración de Pagos (Fase 2) | Mercado Pago para procesamiento de suscripciones Pro. |

### 2.1 Requerimientos Funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-01 | Registro y autenticación | Registro mediante email/contraseña o Google. Verificación de email y recuperación de contraseña. |
| RF-02 | Gestión de roles | Tres roles: cliente, prestador, administrador. Cliente puede activar rol de prestador sobre la misma cuenta. |
| RF-03 | Perfiles de prestadores | Perfil profesional con categorías, especialidades, zona de cobertura, descripción, experiencia, tarifas y portfolio. |
| RF-04 | Búsqueda y filtrado | Motor de búsqueda por categoría, zona geográfica, valoración y texto libre. Ordenamiento por relevancia. |
| RF-05 | Solicitudes de presupuesto | Envío de solicitudes con descripción, fotos y ubicación. Ciclo de vida con 9 estados definidos. |
| RF-06 | Mensajería contextual | Mensajes entre cliente y prestador vinculados a una solicitud. Soporte para texto e imágenes. |
| RF-07 | Valoraciones y reseñas | Calificación 1-5 estrellas con comentario post-servicio. Rating promedio en perfil del prestador. |
| RF-08 | Notificaciones | Push y notificaciones in-app para eventos relevantes: solicitudes, estados, mensajes, reseñas. |
| RF-09 | Panel de administración | Gestión de usuarios, categorías, reportes y métricas básicas. |
| RF-10 | Sistema de reportes | Reporte de contenido inapropiado con selección de motivo por cualquier usuario autenticado. |
| RF-11 | Suscripción freemium | Plan gratuito y plan pago para prestadores con diferenciación de límites y beneficios. |
| RF-12 | Verificación de identidad | Solicitud de verificación mediante documentación, sujeta a aprobación del administrador. |
| RF-13 | Geolocalización opcional | La app puede usar la ubicación del dispositivo (con consentimiento explícito) para mostrar distancia aproximada entre el usuario y los prestadores en resultados de búsqueda, y para seleccionar la ubicación de trabajo en solicitudes mediante pin en mapa. El uso es completamente opcional: si el usuario no concede permiso de ubicación, todos los flujos existentes (selección por zona/barrio) continúan sin cambios. Las coordenadas del cliente nunca se almacenan en el backend. |

### 2.2 Requerimientos No Funcionales

| ID | Requerimiento | Criterio de aceptación |
|---|---|---|
| RNF-01 | Multiplataforma | Android, iOS y web modernos desde un único codebase (Flutter). |
| RNF-02 | Rendimiento | Pantallas principales < 3s en 4G. Búsqueda < 2s. Carga de imagen < 5s en 3G. Dispositivos mínimos: Android 8.0+ (API 26), iOS 14+, gama media-baja (2GB RAM, Snapdragon 400-series o equivalente). Red mínima soportada: 3G (sin estrategia 2G — cobertura 3G garantizada en Formosa). |
| RNF-03 | Disponibilidad | ≥ 99% uptime (infraestructura Firebase). |
| RNF-04 | Escalabilidad | De cientos a decenas de miles de usuarios sin cambios estructurales. |
| RNF-05 | Accesibilidad | Utilizable por personas con distintos niveles de experiencia tecnológica. Material Design 3. |
| RNF-06 | Seguridad | HTTPS/TLS. Reglas de seguridad server-side. Contraseñas nunca en texto plano. |
| RNF-07 | Offline parcial | Navegación de datos previamente cargados sin conexión (persistencia offline Firestore). |
| RNF-08 | Bajo costo operativo | Dentro del tier gratuito/bajo costo de Firebase para la escala MVP. |
| RNF-09 | Cumplimiento Ley 25.326 | Protección de datos personales (Ley Argentina 25.326). Política de privacidad accesible desde la app. Consentimiento explícito al registrarse. Derecho de acceso, rectificación y supresión gestionable por el usuario. Registro ante AAIP (Agencia de Acceso a la Información Pública) previo al lanzamiento. |

### 2.2.1 Estrategia de Validación de Performance

Herramientas para verificar el cumplimiento de RNF-02 antes y después de cada release:

- **Firebase Performance Monitoring** — latencias de red, tiempo de renderizado de pantallas en producción.
- **flutter_driver / integration_test** — benchmarks automatizados de flujos críticos (carga home, búsqueda, apertura de solicitud) corriendo contra Firebase Emulator.
- **Playwright CLI** (via skills.sh: `npx skills add https://github.com/microsoft/playwright-cli --skill playwright-cli`) — testing E2E del admin dashboard (Flutter Web) y validación de performance en flujos web. Usado principalmente para panel de administración y flujos de verificación de identidad que tienen componente web.

No se define estrategia de testing en 2G. Decisión explícita: Formosa tiene cobertura 3G mínima garantizada en zona urbana.

### 2.3 Casos de Uso

| ID | Caso de Uso | Actor | Descripción |
|---|---|---|---|
| CU-01 | Registrarse como usuario | Visitante | Crea cuenta con email/contraseña o Google. Se envía verificación. Rol cliente por defecto. |
| CU-02 | Iniciar sesión | Usuario | Accede con credenciales. Se carga perfil y redirige según rol. |
| CU-03 | Recuperar contraseña | Usuario | Solicita enlace de recuperación vía email. Validez: 1 hora. |
| CU-04 | Activarse como prestador | Cliente | Wizard de 4 pasos: categorías, zonas, descripción, portfolio. Publica perfil al completar datos mínimos. |
| CU-05 | Editar perfil de prestador | Prestador | Modifica campos individuales. Guardado automático por campo. Toggle de visibilidad. |
| CU-06 | Buscar prestadores | Visitante / Cliente | Navega categorías o busca por texto. Filtros por zona, valoración, precio. Orden por relevancia. |
| CU-07 | Ver perfil de prestador | Visitante / Cliente | Consulta perfil completo: descripción, portfolio, rating, reseñas. |
| CU-08 | Enviar solicitud de presupuesto | Cliente | Describe trabajo, adjunta fotos, indica ubicación. Requiere email verificado y datos completos. |
| CU-09 | Responder solicitud | Prestador | Acepta (con presupuesto), rechaza o pide más info. Plazo: 48hs. |
| CU-10 | Gestionar solicitud | Cliente / Prestador | Marca inicio/fin de trabajo, confirma finalización, cancela con motivo. |
| CU-11 | Enviar mensaje | Cliente / Prestador | Intercambia texto e imágenes dentro de solicitud activa. Mensajes de sistema automáticos. |
| CU-12 | Dejar reseña | Cliente | Califica 1-5 estrellas con comentario tras servicio completado. Una reseña por solicitud. |
| CU-13 | Reportar contenido | Cliente / Prestador | Reporta contenido inapropiado con motivo de lista cerrada. |
| CU-14 | Gestionar notificaciones | Cliente / Prestador | Consulta notificaciones, marca como leídas, navega al contexto. |
| CU-15 | Suscribirse al plan Pro | Prestador | Activa trial de 30 días o paga suscripción mensual. |
| CU-16 | Solicitar verificación de identidad | Prestador | Envía fotos de DNI y matrícula opcional. Badge permanente al aprobarse. |
| CU-17 | Gestionar categorías | Administrador | CRUD de categorías. No puede eliminar categorías con prestadores activos. |
| CU-18 | Gestionar usuarios | Administrador | Lista filtrable, detalle, suspensión/reactivación/eliminación. |
| CU-19 | Resolver reportes | Administrador | Revisa contenido reportado. Acciones: desestimar, ocultar, advertir, suspender. Log de auditoría. |
| CU-20 | Revisar verificación de identidad | Administrador | Examina documentación. Aprueba o rechaza. Badge se activa al aprobar. |

### 2.4 Funcionalidades por Módulo

**Módulo de Autenticación:** Registro email/contraseña, login email/contraseña, login con Google (OAuth 2.0), verificación de email por enlace, recuperación de contraseña por enlace, sesión persistente sin expiración forzada con refresh automático, cierre de sesión con limpieza local, bloqueo temporal tras 5 intentos fallidos.

**Módulo de Perfiles:** Perfil de cliente (nombre, email, teléfono, localidad, foto). Perfil de prestador (categorías sin límite, especialidades, zonas de cobertura sin límite, descripción, experiencia, tarifas, portfolio sin límite de fotos). Indicador de completitud (%). Guardado automático por campo. Badges Pro y Verificado. Toggle de visibilidad en búsquedas.

**Módulo de Búsqueda:** Navegación por categorías (grid con íconos). Búsqueda por texto libre (keywords en Firestore). Filtros: zona, valoración mínima, rango de precio, ordenamiento. Opciones de orden: mejor valorados, más reseñas, más recientes. Infinite scroll (20 resultados/carga). Fórmula de relevancia: `rating_promedio × log(reseñas + 1)` con boost 15% para Pro. Prestadores inactivos/suspendidos excluidos.

**Módulo de Solicitudes:** Creación con título, descripción, fotos (hasta 5), ubicación, disponibilidad. Ciclo de vida con 9 estados (ver §11.1). Timeout 48hs para respuesta (recordatorio a 24hs). Timeout 72hs para confirmación (auto-completación). Cancelación con motivo obligatorio post-aceptación. Límite por plan: 5 activas simultáneas (free), ilimitadas (Pro).

**Módulo de Mensajería:** Hilo vinculado a solicitud. Texto + imágenes (hasta 3/mensaje). Mensajes de sistema automáticos por cambio de estado. Indicador de lectura. Solo lectura en estados terminales. Push en background.

**Módulo de Valoraciones:** 1-5 estrellas con comentario opcional. Solo post-completación confirmada. Una reseña por solicitud. Recálculo automático de rating (full recalculation). Reseñas públicas. Admin puede ocultar.

**Módulo de Notificaciones:** Push (FCM) para acciones urgentes. In-app para todo evento. Centro de notificaciones con badge, navegación al contexto, marcar todas como leídas. Agrupación de repetidas.

**Módulo de Administración:** Dashboard (métricas + alertas). Gestión de usuarios (filtros, detalle, historial, acciones). Gestión de categorías (CRUD con protección). Gestión de reportes (cola, revisión, acciones + auditoría). Gestión de verificaciones (revisión, aprobación/rechazo).

**Módulo de Monetización:** Plan gratuito funcional con límites. Plan Pro con beneficios ampliados. Trial 30 días (una vez). Pagos vía Mercado Pago. Verificación de identidad como servicio adicional con pago único.

---

## 3. Usuarios

### Primary

| Rol | Responsabilidad | Necesidades específicas |
|---|---|---|
| Cliente | Buscar servicios, enviar solicitudes de presupuesto, coordinar trabajos, calificar prestadores | Encontrar prestadores confiables cerca de su zona. Comparar opciones con reseñas verificables. Proceso simple y de baja fricción, accesible para usuarios con distintos niveles tecnológicos. Navegación sin registro obligatorio. |
| Prestador de servicios | Ofrecer servicios, gestionar perfil profesional, responder solicitudes, construir reputación | Visibilidad más allá del boca en boca. Espacio propio para mostrar trabajo y acumular reputación. Recibir solicitudes organizadas. Herramientas para gestionar su negocio (estadísticas, portfolio). Plan gratuito funcional con opción de mejora paga. |

### Secondary

| Rol | Responsabilidad | Necesidades específicas |
|---|---|---|
| Administrador | Gestionar la operación de la plataforma: categorías, usuarios, reportes, verificaciones | Panel con métricas operativas. Cola de reportes pendientes. Herramientas de moderación con registro de auditoría. Gestión de verificaciones de identidad. |

### Notas sobre roles

- Un usuario puede ser cliente y prestador simultáneamente (misma cuenta, rol ampliado). No son tipos de cuenta separados.
- El rol de prestador se activa sobre una cuenta de cliente existente (patrón Airbnb: cualquier huésped puede volverse anfitrión).
- El rol de administrador se asigna manualmente vía consola de Firebase o Cloud Function protegida.
- Los roles se implementan mediante Custom Claims en el token JWT de Firebase Authentication.

---

## 4. Stack Tecnológico

### Frontend (Flutter)

| Componente | Tecnología | Versión | Justificación |
|---|---|---|---|
| Framework | Flutter | 3.x (stable) | Único codebase para Android, iOS y Web. Compilación nativa. Gran ecosistema de paquetes. |
| Lenguaje | Dart | 3.x | Lenguaje nativo de Flutter. Tipado fuerte. Null safety. |
| Estado | Riverpod | 2.x | Independiente de BuildContext, inyección de dependencias nativa, reactividad granular, testing directo de providers. Superior a Provider (limitaciones técnicas) y BLoC (más verboso) para equipo pequeño. |
| Navegación | GoRouter | 14.x | Router oficial de Flutter. Deep linking nativo (compartir perfiles por WhatsApp). URLs legibles para web. Redirects centralizados por rol. |
| Formularios | flutter_form_builder + form_builder_validators | 9.x | Campos predefinidos, validación declarativa, estado centralizado. Reduce código repetitivo en formularios complejos (onboarding, solicitudes). |
| Imágenes | cached_network_image + image_picker + flutter_image_compress | 3.x / 1.x / 2.x | Cache de red, selección cámara/galería, compresión pre-upload (1024px, 80%). |
| UI / Estilos | Material 3 (Material You) + google_fonts | Nativo / 6.x | Design system nativo de Flutter. Paleta desde color seed. Accesibilidad incluida. Cero tiempo en design system custom para MVP. |
| Storage local | shared_preferences | 2.x | Preferencias simples (tema, onboarding visto). No se necesita BD local: Firestore tiene cache offline nativo. |
| Utilidades | intl, timeago, url_launcher | latest | Formateo de fechas/números (locale AR), tiempos relativos ("hace 2 horas"), abrir WhatsApp/email/links. |
| Notificaciones locales | flutter_local_notifications | latest | Manejo de taps en push, notificaciones locales. |
| Mapas | flutter_map + latlong2 | 6.x / 0.9.x | Tiles OpenStreetMap sin API key ni billing. Mapa de zonas del prestador y pin picker en solicitudes. Distancia Haversine client-side. Alternativa elegida sobre google_maps_flutter (requiere billing) y mapbox (SDK más complejo). |
| Geolocalización | geolocator | 11.x | Acceso a GPS del dispositivo (opcional, con permiso explícito). Solo para mostrar distancia aproximada. Nunca se almacenan coordenadas del cliente. |

### Backend (Firebase — Serverless)

| Componente | Tecnología | Versión / Config | Justificación |
|---|---|---|---|
| BaaS | Firebase (plan Blaze) | — | Ecosistema completo (auth + DB + storage + functions + push + analytics + crash) bajo un solo SDK. Cero administración de servidores. Free tier generoso para MVP. |
| Base de datos | Cloud Firestore | Región: southamerica-east1 | NoSQL documental con persistencia offline, snapshot listeners (real-time), Security Rules integradas. Relaciones simples del modelo no requieren JOINs. |
| Autenticación | Firebase Authentication | — | Email/contraseña + Google Sign-In. Custom Claims para roles. Hashing bcrypt. Tokens JWT. |
| Almacenamiento | Firebase Storage | — | Fotos de perfil, portfolio, adjuntos de solicitudes, documentos de verificación. Reglas de seguridad por UID. |
| Funciones servidor | Cloud Functions v2 | Node.js 20 + TypeScript | Lógica que no debe residir en cliente: recálculo de ratings, keywords, timeouts, notificaciones, roles, pagos. TypeScript por tipado estático y autocompletado. |
| Push notifications | Firebase Cloud Messaging (FCM) | — | Push a Android, iOS y Web. Gratuito. Multi-dispositivo por usuario. |
| Security | Firestore Security Rules | — | Control de acceso por rol, propiedad de documento y transiciones de estado válidas. |
| Crash reporting | Firebase Crashlytics | — | Reportes de crashes en producción con stack trace y contexto de dispositivo. |
| Analytics | Firebase Analytics | — | Eventos clave: registro, onboarding, búsqueda, solicitudes, reseñas, conversión a Pro. |
| Monitoreo | Firebase Performance | — | Tiempos de carga, latencia de red en dispositivos reales. |
| Desarrollo local | Firebase Emulator Suite | — | Emula Auth, Firestore, Storage, Functions, Pub/Sub. Desarrollo offline, sin cuota, sin riesgo. |

### Servicios Externos

| Servicio | Uso | Fase |
|---|---|---|
| Mercado Pago (API de suscripciones) | Procesamiento de pagos de suscripción Pro y verificación de identidad | Fase 2 (meses 4-6) |

### Paquetes explícitamente excluidos

| Paquete | Razón de exclusión |
|---|---|
| dio / http | No se necesita HTTP client. Toda comunicación vía SDK de Firebase. Se agregaría solo para API externa (Mercado Pago). |
| GetX | Mezcla concerns, dificulta testing, APIs mágicas. Desaconsejado por la comunidad Flutter. |
| Hive / Isar | No se necesita BD local. Firestore tiene cache offline nativo. shared_preferences cubre preferencias. |
| BLoC / flutter_bloc | Viable pero más verboso. Cada feature requiere Event + State + Bloc. Menos productivo para equipo pequeño. |
| Algolia / Typesense | No en MVP. Búsqueda por keywords en Firestore suficiente para < 500 prestadores. Se evalúa al crecer. |
| google_maps_flutter | Requiere API key con billing activo en GCP. Riesgo de costo operativo inesperado. Reemplazado por flutter_map + OpenStreetMap. |

### Testing

| Capa | Framework / Herramienta |
|---|---|
| Unit / Widget tests (Flutter) | flutter_test + mockito |
| Integration tests (Firebase) | Firebase Emulator Suite |
| E2E | integration_test (Flutter) con emuladores |

---

## 5. Arquitectura

- **Tipo de arquitectura**: Monorepo (un proyecto Flutter para app móvil/web + directorio `functions/` para Cloud Functions)

- **Razón de la elección**: Un solo repositorio simplifica la gestión de versiones, CI/CD y la coherencia entre cliente y funciones del servidor. El tamaño del proyecto (MVP, equipo pequeño) no justifica multi-repo.

- **Patrón arquitectónico**: Clean Architecture simplificada por feature.

  Cada módulo funcional (auth, profile, search, service_request, reviews, notifications, subscription, admin) se organiza internamente en tres capas:
  - `data/`: Repositorios con implementación concreta (Firebase).
  - `domain/`: Entidades de negocio y contratos (interfaces) de repositorio.
  - `presentation/`: Pantallas, widgets y providers Riverpod.

  Esta separación permite testear la lógica de negocio independientemente de Firebase, y reemplazar la implementación de datos sin afectar la presentación.

### 5.1 Visión General de Componentes

```
┌──────────────────────────────────────────────────┐
│                 CLIENTE (Flutter 3.x)             │
│                                                  │
│  ┌────────────┐ ┌────────────┐ ┌──────────────┐ │
│  │  App Móvil  │ │  App Web   │ │ Admin Panel  │ │
│  │ Android/iOS │ │            │ │ (Flutter Web)│ │
│  └──────┬──────┘ └──────┬─────┘ └──────┬───────┘ │
│         └───────────┬───┘──────────────┘         │
│                     │                            │
│              Firebase SDK para Flutter            │
└─────────────────────┬────────────────────────────┘
                      │ HTTPS / WebSocket
┌─────────────────────┴────────────────────────────┐
│                 BACKEND (Firebase)                 │
│                                                  │
│  Firebase Authentication    Cloud Firestore       │
│  Firebase Storage           Cloud Functions v2    │
│  Cloud Messaging (FCM)      Security Rules        │
│  Crashlytics                Analytics             │
└──────────────────────────────────────────────────┘
                      │
┌─────────────────────┴────────────────────────────┐
│             SERVICIOS EXTERNOS                    │
│                                                  │
│  Mercado Pago (pagos de suscripción, fase 2)     │
└──────────────────────────────────────────────────┘
```

### 5.2 Integración con Firebase — Servicios y Roles

| Servicio | Rol en ChangaYa |
|---|---|
| Firebase Authentication | Gestión completa de identidad: registro (email/Google), login, verificación de email, recuperación de contraseña, tokens de sesión y Custom Claims para roles. |
| Cloud Firestore | Base de datos principal. Todas las colecciones del sistema. Persistencia offline habilitada. Snapshot listeners para real-time en chat y estado de solicitudes. Región: southamerica-east1. |
| Firebase Storage | Almacenamiento binario: fotos de perfil, portfolio, adjuntos de solicitudes y documentación de verificación. Organizado en carpetas por tipo y UID. |
| Cloud Functions v2 | Lógica de servidor: recálculo de ratings/métricas, generación de keywords de búsqueda, gestión de timeouts, envío de notificaciones, asignación de roles, procesamiento de pagos. TypeScript + Node.js 20. |
| Firebase Cloud Messaging | Push notifications a Android, iOS y Web. Múltiples tokens por usuario. |
| Firebase Crashlytics | Captura crashes y errores no manejados en producción. |
| Firebase Analytics | Trackeo de eventos clave para medir adopción, engagement y conversión. |
| Firebase Emulator Suite | Entorno local: emula Auth, Firestore, Storage, Functions, Pub/Sub sin consumir cuota. |

### 5.3 Cloud Functions — Catálogo Completo

| Función | Tipo | Trigger | Descripción |
|---|---|---|---|
| onUserCreate | Auth trigger | Al crear cuenta | Crea documentos iniciales en users/ y subscriptions/ |
| setProviderRole | Callable | Invocación del cliente | Asigna Custom Claim "provider" y actualiza Firestore |
| onProviderWrite | Firestore trigger | onWrite en providers/{uid} | Recalcula searchKeywords y completionPercentage |
| onRequestCreate | Firestore trigger | onCreate en service_requests/ | Envía notificación push e in-app al prestador |
| onRequestUpdate | Firestore trigger | onUpdate en service_requests/ | Notificaciones por cambio de estado, crea mensajes de sistema, actualiza responseRate |
| onReviewCreate | Firestore trigger | onCreate en reviews/ | Recalcula rating del prestador, actualiza estado a "reviewed" |
| onMessageCreate | Firestore trigger | onCreate en messages/ (collection group) | Push al destinatario para mensajes tipo "user" |
| checkExpiredRequests | Scheduled | Cada hora | Marca solicitudes pending con expiresAt vencido como expired |
| checkAutoComplete | Scheduled | Cada hora | Marca solicitudes awaiting_confirmation con autoCompleteAt vencido como completed |
| onSubscriptionExpire | Scheduled | Diaria | Busca suscripciones/trials vencidos, revierte a plan free |
| processSubscription | Callable / HTTP | Webhook de Mercado Pago | Activa o renueva suscripción Pro |

---

## 6. Estructura de Directorios

```
changaya/
├── lib/
│   ├── main.dart
│   ├── main_dev.dart                   # Entry point con emuladores
│   ├── main_prod.dart                  # Entry point producción
│   ├── app/
│   │   ├── app.dart                    # MaterialApp, tema, navegación raíz
│   │   ├── routes.dart                 # GoRouter con guardias de rol
│   │   └── theme.dart                  # Material 3 con color seed
│   ├── core/
│   │   ├── constants/                  # Enums, valores constantes
│   │   ├── errors/                     # Clases de error y excepciones
│   │   ├── utils/                      # Helpers de formateo, validación
│   │   └── widgets/                    # Widgets reutilizables (botones, cards, inputs)
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/                   # Repositorios (implementación Firebase)
│   │   │   ├── domain/                 # Entidades y contratos de repositorio
│   │   │   └── presentation/           # Screens, widgets, providers Riverpod
│   │   ├── profile/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── search/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── service_request/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── reviews/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── notifications/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── subscription/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   └── admin/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   └── services/
│       ├── firebase_service.dart       # Inicialización de Firebase
│       ├── auth_service.dart           # Wrapper de FirebaseAuth
│       ├── firestore_service.dart      # Acceso genérico a Firestore
│       ├── storage_service.dart        # Wrapper de Firebase Storage
│       └── notification_service.dart   # FCM
├── functions/                          # Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── index.ts                    # Exports de todas las funciones
│   │   ├── auth/                       # onUserCreate, setProviderRole
│   │   ├── providers/                  # onProviderWrite
│   │   ├── requests/                   # onRequestCreate, onRequestUpdate, scheduled
│   │   ├── reviews/                    # onReviewCreate
│   │   ├── messages/                   # onMessageCreate
│   │   ├── subscriptions/              # processSubscription, onSubscriptionExpire
│   │   └── utils/                      # sendPushToUser, helpers
│   ├── package.json
│   └── tsconfig.json
├── test/                               # Tests Flutter
├── firebase.json                       # Configuración de emuladores y deploy
├── firestore.rules                     # Security Rules de Firestore
├── storage.rules                       # Security Rules de Storage
├── firestore.indexes.json              # Índices compuestos
└── pubspec.yaml
```

---

## 7. Convenciones de Código

### Frontend (Flutter / Dart)

**Stack frontend**: Flutter 3.x + Dart 3.x + Riverpod 2.x

**Reglas clave**:
- Cada feature es un módulo independiente con subcarpetas `data/`, `domain/`, `presentation/`.
- La lógica de negocio reside en `domain/` como entidades y contratos de repositorio. Nunca en widgets.
- Los repositorios en `data/` implementan los contratos de `domain/` con Firebase.
- La UI en `presentation/` consume providers Riverpod que exponen datos del repositorio.
- Estado global (sesión, rol, plan): providers globales. Estado local de feature: providers autodisposables.
- Navegación centralizada en `routes.dart` con guardias por rol. No se navega desde widgets directamente con MaterialPageRoute.
- Guardado automático por campo (patrón LinkedIn), no formularios con botón "Guardar todo".
- Imágenes se comprimen en cliente antes de subir: 1024px ancho máximo, calidad 80%.
- Snapshot listeners solo donde se requiere real-time: chat, estado de solicitud, badge de notificaciones. El resto son queries estáticas.

### Backend (Cloud Functions / TypeScript)

**Stack backend**: Cloud Functions v2 + TypeScript + Node.js 20

**Reglas clave**:
- Todas las funciones son idempotentes. Los recálculos se hacen desde cero (full recalculation), nunca incrementos.
- Las operaciones sensibles a concurrencia usan Firestore transactions.
- Los datos desnormalizados (rating, plan, searchKeywords, completionPercentage, responseRate) solo se modifican desde Cloud Functions, nunca desde el cliente.
- Los mensajes de sistema en el chat los crea la Cloud Function onRequestUpdate, no el cliente.
- Toda acción del admin se registra en admin_log/ con timestamp, nota y metadata.
- Región de deploy: southamerica-east1 (misma que Firestore).

### Testing

**Framework de testing**: flutter_test + mockito + Firebase Emulator Suite

**Reglas clave**:
- Unit tests en repositorios y providers de Riverpod.
- Widget tests en pantallas clave (login, búsqueda, solicitud).
- Integration tests contra Firebase Emulator Suite para flujos completos.
- Datos de seed en emuladores: 15 categorías, 30 prestadores ficticios, 50 solicitudes en distintos estados, 100 reseñas, 5 reportes, 3 usuarios de prueba (cliente, prestador, admin).

### Estilo de código

**Linting / formateo**:
- `flutter analyze` con reglas strict del `analysis_options.yaml` oficial de Flutter.
- `dart format` para formateo automático.
- En Cloud Functions: ESLint con reglas TypeScript strict + Prettier.

---

## 8. Deployment

- **Plataforma de hosting**: Firebase (Firestore, Functions, Storage, Authentication, FCM — plan Blaze pay-as-you-go)

- **Contenerización**: Serverless (Cloud Functions). No se usa Docker. Todo es administrado por Firebase.

- **CI/CD**: GitHub Actions
  - En cada Pull Request: `flutter analyze` + `flutter test` (lint y tests).
  - Al mergear a main: deploy automático de Cloud Functions, Firestore Security Rules y Storage Rules vía `firebase deploy`.
  - Build de APK/IPA se realiza manualmente para MVP (firma de stores requiere configuración única por proyecto).

- **Entornos**:

  | Entorno | Infraestructura | Uso |
  |---|---|---|
  | Desarrollo | Firebase Emulator Suite (local) | Desarrollo diario. Datos de seed. Hot reload. Costo: $0. |
  | Staging | Proyecto Firebase separado (changaya-staging) | Testing de integración con servicios reales (FCM, Storage, Auth). Pre-release. Costo mínimo (free tier). |
  | Producción | Proyecto Firebase principal (changaya-prod) | Datos reales. Crashlytics + Analytics activos. Backups de Firestore. |

---

## 9. Restricciones Known

### Limitaciones técnicas

- **Firestore no soporta JOINs.** Cada consulta de perfil + reseñas requiere dos queries. Se mitiga con cache local de Firestore. Aceptable a esta escala.
- **Firestore no soporta full-text search nativo.** La búsqueda por keywords con `array-contains-any` es limitada: no fuzzy matching, no ordenamiento por relevancia textual, máximo 10 valores por query. Suficiente para MVP si se generan keywords con variaciones (singular/plural, sin acentos). Se evalúa Algolia/Typesense al superar 500 prestadores.
- **Cloud Functions — cold start.** Primera invocación tras inactividad tiene latencia de 1-3s. Se acepta en MVP. Se mitiga con min_instances=1 en producción si es necesario (~USD 5/mes).
- **FCM no garantiza entrega.** Push no llega si usuario desactivó notificaciones, modo ahorro de batería agresivo, o sin conexión. Se crean siempre notificaciones in-app como respaldo.
- **Flutter Web — rendimiento inferior a web nativa** para interfaces con mucho texto y scroll. Aceptable para panel de admin (uso interno). Para landing page pública, se podría considerar HTML estático en el futuro.
- **Búsqueda por zona + categoría simultánea.** Firestore no permite dos `array-contains` en una misma query. Solución: filtrar por categoría en Firestore, filtrar por zona en el cliente.

### Limitaciones de producto

- No se implementan pagos a través de la plataforma (solo suscripciones). Los pagos entre cliente y prestador son externos (efectivo, transferencia directa).
- No se implementa geolocalización por GPS. Se usa selección manual de zona/barrio predefinida (menor fricción para el público objetivo).
- No se implementa bloqueo automático de datos de contacto en mensajes (requiere NLP, falsos positivos). Se puede agregar si se identifica como problema.
- No se implementan penalizaciones por cancelación en el MVP. Los motivos se registran para análisis futuro.

### Umbrales de escalabilidad

| Umbral | Acción requerida | Complejidad |
|---|---|---|
| 500+ prestadores | Evaluar Algolia o Typesense para búsqueda full-text | Media |
| 10.000+ usuarios | Habilitar Firebase App Check contra abuso de API | Baja |
| 50.000+ lecturas/día | Implementar cache con Firestore bundles para categorías | Media |
| 100.000+ imágenes | Activar extensión Resize Images para thumbnails automáticos | Baja |
| Expansión geográfica | Evaluar particionamiento de datos por región | Alta |

---

## 10. Referencias Externas

- **APIs externas que se consumen**:
  - Mercado Pago — API de suscripciones (preapproval) para pagos de plan Pro (Fase 2, meses 4-6). Webhook a Cloud Function para confirmación de pago.
  - Google Sign-In — OAuth 2.0 para autenticación con Google (via Firebase Authentication).

- **Sistemas existentes con los que se integra**:
  - Ninguno. ChangaYa es un sistema greenfield sin dependencias de sistemas legacy.

- **Artefactos existentes**:
  - Propuesta de Trabajo Integrador Final (documento académico original que describe el contexto del problema y los objetivos del proyecto).

---

## Anexo A — Flujos del Sistema (Detallados)

### A.1 Onboarding — Registro de Cliente

**Paso 1:** El usuario accede a la pantalla de registro desde el modal que aparece al intentar una acción que requiere autenticación (solicitar presupuesto, dejar reseña). Ingresa nombre, email y contraseña, o selecciona "Continuar con Google". Acepta los términos y condiciones.

**Paso 2:** El sistema crea la cuenta, envía un email de verificación y muestra una pantalla indicando "Revisá tu correo". El usuario puede navegar la app pero no puede enviar solicitudes hasta verificar.

**Paso 3:** Al intentar enviar su primera solicitud, si el usuario no ha completado sus datos, el sistema muestra una pantalla de completar datos mínimos: teléfono de contacto, localidad (selector predefinido) y foto de perfil (opcional). Este enfoque de progressive profiling reduce la fricción del registro inicial.

### A.2 Onboarding — Activación como Prestador

**Paso 1:** Desde el menú de perfil, el usuario toca "Quiero ofrecer mis servicios". Se inicia un wizard guiado de cuatro pasos.

**Paso 2 — Categorías:** El usuario selecciona una o más categorías de servicio y opcionalmente agrega especialidades como texto libre.

**Paso 3 — Zonas:** El usuario selecciona las localidades o barrios donde trabaja, mediante una lista predefinida con selección múltiple.

**Paso 4 — Sobre vos:** El usuario completa su descripción profesional, experiencia y tarifas orientativas. Este paso es opcional y puede completarse después.

**Paso 5 — Portfolio:** El usuario puede subir fotos de trabajos realizados o seleccionar "Agregar después".

Al completar los pasos 2 y 3 (datos mínimos obligatorios), el perfil se publica en las búsquedas. El wizard se puede abandonar y retomar; el progreso se preserva localmente.

### A.3 Gestión de Perfil del Prestador

El prestador accede a la pantalla "Mi perfil de prestador", que muestra todos los campos editables junto con un indicador de completitud ("Tu perfil está al 70%") y sugerencias de mejora ("Los prestadores con fotos reciben 3x más solicitudes").

La edición de cada campo se realiza de forma individual: el prestador toca el campo, lo edita en un editor inline o pantalla dedicada, y confirma. El guardado es automático por campo, sin necesidad de un botón global "Guardar".

La gestión de portfolio permite subir fotos (con compresión automática), agregar descripciones, reordenar y eliminar. La primera foto se muestra como imagen principal del perfil.

El toggle "Visible en búsquedas" permite al prestador desactivar temporalmente su perfil sin perder datos ni reseñas. Las solicitudes en curso no se ven afectadas.

### A.4 Solicitudes de Servicio

**Creación (cliente).** Desde el perfil del prestador, el cliente toca "Solicitar presupuesto". Completa un formulario con título breve, descripción detallada, fotos opcionales (hasta 5), dirección aproximada y disponibilidad sugerida. Al confirmar, la solicitud se crea en estado "pendiente" con un timeout de 48 horas, y se notifica al prestador.

**Respuesta (prestador).** El prestador recibe una notificación push, abre la solicitud y puede: aceptar (opcionalmente con un mensaje indicando presupuesto estimado y disponibilidad), rechazar, o solicitar más información mediante mensaje sin cambiar el estado. Si no responde en 48 horas, el sistema envía un recordatorio a las 24 horas y marca la solicitud como expirada al cumplirse el plazo.

**Ejecución (prestador).** El prestador marca el inicio del trabajo cuando comienza (estado "en progreso") y marca la finalización cuando termina (estado "esperando confirmación").

**Confirmación (cliente).** El cliente recibe una notificación preguntando si el trabajo se completó satisfactoriamente. Puede confirmar (estado "completada", se ofrece dejar reseña) o reportar un problema (estado regresa a "en progreso" para coordinación adicional). Si no responde en 72 horas, el sistema marca la solicitud como completada automáticamente.

**Cancelación.** El cliente puede cancelar sin motivo mientras la solicitud está pendiente. A partir del estado "aceptada", cualquiera de las partes puede cancelar pero debe proporcionar un motivo.

### A.5 Mensajería

El hilo de mensajes se crea automáticamente junto con la solicitud. El primer mensaje es generado por el sistema con los datos de la solicitud. Ambas partes pueden intercambiar mensajes mientras la solicitud esté activa (no en estado terminal).

Los cambios de estado generan mensajes del sistema automáticos que se intercalan en el hilo. Los indicadores de lectura muestran al remitente si su mensaje fue visto. Al abrir el chat, los mensajes no leídos del otro participante se marcan como leídos automáticamente.

Cuando la solicitud llega a un estado terminal, el hilo se cierra: los mensajes anteriores permanecen legibles pero no se pueden enviar nuevos.

### A.6 Moderación y Reportes

Cualquier usuario autenticado puede reportar contenido desde un menú contextual disponible en reseñas, perfiles de prestadores y mensajes. El reporte requiere seleccionar un motivo de una lista cerrada (contenido ofensivo, información falsa, spam, datos personales expuestos, u otro con texto obligatorio).

El contenido reportado no se oculta automáticamente para evitar abusos del sistema. El administrador revisa, examina el contenido original y toma una acción: desestimar, ocultar contenido, advertir al usuario o suspender la cuenta temporalmente (7 o 30 días). Toda acción queda registrada en el log de auditoría.

El usuario que reportó recibe una notificación genérica indicando que su reporte fue revisado, sin detalle de la acción tomada.

### A.7 Notificaciones

Las notificaciones operan en doble canal. Push (FCM) para eventos que requieren acción inmediata. In-app para todo evento, incluyendo los informativos.

Al recibir una push, el usuario es dirigido al contexto relevante mediante deep linking. El centro de notificaciones muestra badge con cantidad de no leídas, permite navegar al contexto de cada una, y ofrece marcar todas como leídas.

### A.8 Búsqueda

La pantalla principal presenta un grid de categorías con íconos. Al tocar una categoría, se muestra la lista de prestadores filtrados. Una barra de búsqueda en la parte superior permite buscar por texto libre en cualquier momento.

La búsqueda por texto opera sobre un campo de keywords generado automáticamente al guardar el perfil del prestador. Los filtros se presentan en un panel desplegable: zona, valoración mínima, rango de precio y criterio de ordenamiento. Los resultados se cargan de forma incremental (20 por página) con infinite scroll.

### A.9 Flujos Adicionales

**Bloqueo entre usuarios.** Un cliente puede bloquear a un prestador desde el menú contextual del perfil o del hilo de mensajes. El bloqueo es unilateral y silencioso: el prestador bloqueado no recibe notificación. Efectos: el prestador bloqueado no aparece en resultados de búsqueda para ese cliente; el cliente bloqueador no puede recibir solicitudes de ese prestador; los mensajes futuros son silenciados. El bloqueo no afecta solicitudes activas ya en curso. El cliente puede desbloquear desde su configuración. En v1 no hay bloqueo del prestador hacia el cliente.

**Rechazo de verificación de identidad y reintento.** Si el administrador rechaza la solicitud de verificación, el usuario recibe una notificación in-app y push con el motivo del rechazo (`rejectionReason`). La pantalla de verificación muestra el estado "Rechazada" con el motivo visible y un botón "Volver a intentar". El usuario puede resubir documentación hasta 3 veces por día. No existe flujo de apelación formal en v1 — el usuario puede contactar soporte por email.

**Inmutabilidad de mensajes.** Los mensajes de chat son inmutables en v1: no se pueden editar ni eliminar una vez enviados. Esta decisión es intencional: preserva el historial completo para resolución de disputas. La UI no presenta opciones de edición/borrado. Los mensajes del sistema (cambios de estado) tampoco son modificables.

---

## Anexo B — Pantallas Principales (UI Lógica)

| # | Pantalla | Acceso | Datos / Funciones |
|---|---|---|---|
| P-01 | Home | Pública | Grid de categorías con íconos, barra de búsqueda, resumen de solicitudes pendientes (si prestador), CTA registro (si visitante) |
| P-02 | Resultados de búsqueda | Pública | Lista de prestadores (foto, nombre, rating, especialidades, zona, precios), filtros (zona, rating, precio, orden), infinite scroll. Si el usuario concedió permiso de ubicación: muestra "~X km" junto a cada card (cálculo Haversine client-side, no requiere backend). |
| P-03 | Perfil de prestador | Pública | Foto, nombre, rating (estrellas + nro), badges (Pro, Verificado), categorías, zonas, descripción, tarifas, portfolio grid, reseñas paginadas, botón "Solicitar presupuesto" (sticky bottom). Mapa pequeño no interactivo con zona(s) del prestador marcadas (flutter_map, tiles OSM). |
| P-04 | Login | Pública | Email + contraseña, botón Google, enlace a registro, enlace "¿Olvidaste tu contraseña?" |
| P-05 | Registro | Pública | Nombre + email + contraseña, botón Google, checkbox términos |
| P-06 | Verificación de email | Autenticada | "Revisá tu correo", botón reenvío (cooldown 60s) |
| P-07 | Recuperar contraseña | Pública | Email, botón enviar enlace, confirmación |
| P-08 | Completar datos | Autenticada | Teléfono, localidad (selector), foto perfil (opcional) |
| P-09 | Wizard prestador | Autenticada | 4 pasos: categorías → zonas → sobre vos → portfolio. Paso 2 (zonas): mapa pequeño que visualiza la zona seleccionada (no obligatorio, degradar a lista si sin mapa). |
| P-10 | Editar perfil prestador | Prestador | Campos editables, indicador completitud %, toggle visibilidad, sugerencias |
| P-11 | Crear solicitud | Autenticada | Título, descripción, fotos (hasta 5), ubicación, disponibilidad. Campo ubicación: selector de barrio/localidad (existente) + opción alternativa "Marcar en mapa" (LocationPickerWidget). Si elige mapa, guarda address aproximado + coordinates opcionales. |
| P-12 | Mis solicitudes | Autenticada | Lista por estado, filtros, como cliente o como prestador |
| P-13 | Detalle de solicitud | Autenticada | Estado prominente (color), datos, acciones según estado/rol, acceso a chat, historial |
| P-14 | Chat | Autenticada | Hilo de mensajes, mensajes de sistema, input texto + fotos, indicador lectura |
| P-15 | Dejar reseña | Autenticada | Selector estrellas (1-5), campo comentario, botón enviar |
| P-16 | Notificaciones | Autenticada | Lista con indicador lectura, navegación al contexto, marcar todas como leídas |
| P-17 | Configuración | Autenticada | Cerrar sesión, datos de cuenta, preferencias |
| P-18 | Suscripción | Prestador | Comparación planes (Básico vs Pro), botón trial / suscribirse, estado actual |
| P-19 | Verificación de identidad | Prestador | Upload DNI (frente/dorso), matrícula opcional, estado solicitud |
| P-20 | Admin — Dashboard | Admin | Métricas (usuarios, prestadores, solicitudes, reportes), alertas operativas |
| P-21 | Admin — Usuarios | Admin | Lista filtrable (rol, estado, fecha), detalle con historial, acciones |
| P-22 | Admin — Categorías | Admin | CRUD, ordenamiento, protección contra eliminación de categorías con prestadores |
| P-23 | Admin — Reportes | Admin | Cola pendientes, contenido reportado, acciones + auditoría |
| P-24 | Admin — Verificaciones | Admin | Cola solicitudes, revisión documentos, aprobar/rechazar |

---

## Anexo C — Modelo de Datos (Firestore)

### C.1 Diagrama de Colecciones

```
firestore-root/
│
├── users/{uid}
├── providers/{uid}
├── categories/{categoryId}
├── service_requests/{requestId}
│   └── messages/{messageId}
├── reviews/{reviewId}
├── reports/{reportId}
├── subscriptions/{uid}
├── notifications/{uid}
│   └── items/{notifId}
├── verification_requests/{requestId}
└── admin_log/{logId}
```

### C.2 Estructura de Documentos

**users/{uid}**

| Campo | Tipo | Descripción |
|---|---|---|
| email | string | Email del usuario |
| displayName | string | Nombre completo |
| role | string | "client", "provider" o "admin" |
| phoneNumber | string? | Teléfono (progressive profiling) |
| photoURL | string? | URL foto de perfil en Storage |
| location | map | { locality: string, neighborhood: string? } |
| emailVerified | boolean | Si verificó email |
| isProvider | boolean | Si tiene perfil de prestador activo |
| onboardingCompleted | boolean | Si completó datos mínimos |
| fcmTokens | string[] | Tokens de dispositivos para push |
| suspendedUntil | timestamp? | Fecha de fin de suspensión (null si activo) |
| suspensionReason | string? | Motivo de suspensión |
| createdAt | timestamp | Fecha de registro |
| updatedAt | timestamp | Última modificación |

**providers/{uid}** (mismo UID que users/)

| Campo | Tipo | Descripción |
|---|---|---|
| specialties | string[] | Especialidades en texto libre |
| categoryIds | string[] | IDs de categorías |
| description | string | Descripción profesional |
| experience | string | Experiencia |
| coverageZones | string[] | Localidades/barrios |
| primaryCoordinates | map? | { lat: number, lng: number } — Centroide de zona principal. Nunca domicilio exacto. Set en wizard o derivado de zona. Usado para cálculo de distancia client-side. |
| pricing | map | { type, minPrice?, maxPrice?, currency } |
| portfolio | array | [{ url, caption? }] |
| rating | map | { average: number, count: number } — Cloud Function |
| isActive | boolean | Visible en búsquedas |
| plan | string | "free", "pro", "trial" — duplicado de subscriptions/ |
| isVerified | boolean | Badge verificación de identidad |
| searchKeywords | string[] | Keywords normalizados — Cloud Function |
| completionPercentage | number | 0-100 — Cloud Function |
| responseRate | number | % solicitudes respondidas a tiempo |
| totalRequestsCompleted | number | Contador desnormalizado |
| createdAt | timestamp | Activación como prestador |
| updatedAt | timestamp | Última modificación |

**categories/{categoryId}**

| Campo | Tipo | Descripción |
|---|---|---|
| name | string | Nombre |
| description | string? | Descripción |
| icon | string | Nombre de ícono o URL |
| parentId | string? | Categoría padre (subcategorías) |
| order | number | Orden de visualización |
| isActive | boolean | Visible en plataforma |

**service_requests/{requestId}**

| Campo | Tipo | Descripción |
|---|---|---|
| clientId | string | UID del cliente |
| providerId | string | UID del prestador |
| categoryId | string | ID de categoría |
| title | string | Título breve |
| description | string | Descripción detallada |
| images | string[]? | URLs fotos (hasta 5) |
| location | map | { locality, neighborhood?, address?, coordinates?: { lat: number, lng: number } } — coordinates solo presente si el cliente eligió pin en mapa. Corresponde al lugar del trabajo, no al domicilio. |
| availability | string? | Disponibilidad sugerida |
| status | string | pending, accepted, rejected, expired, in_progress, awaiting_confirmation, completed, reviewed, cancelled |
| expiresAt | timestamp | createdAt + 48hs |
| autoCompleteAt | timestamp? | Set al pasar a awaiting_confirmation (+72hs) |
| cancelReason | string? | Motivo (obligatorio post-aceptación) |
| cancelledBy | string? | UID de quien canceló |
| acceptedAt | timestamp? | Momento de aceptación |
| startedAt | timestamp? | Momento de inicio |
| completedAt | timestamp? | Momento de finalización |
| createdAt | timestamp | Creación |
| updatedAt | timestamp | Última modificación |

**service_requests/{requestId}/messages/{messageId}**

| Campo | Tipo | Descripción |
|---|---|---|
| senderId | string | UID remitente o "system" |
| text | string | Contenido |
| type | string | "user" o "system" |
| images | string[]? | URLs imágenes (hasta 3) |
| read | boolean | Leído por destinatario |
| createdAt | timestamp | Envío |

**reviews/{reviewId}**

| Campo | Tipo | Descripción |
|---|---|---|
| requestId | string | ID solicitud completada |
| clientId | string | UID cliente |
| providerId | string | UID prestador |
| rating | number | 1-5 |
| comment | string? | Comentario |
| isVisible | boolean | Pública (admin puede ocultar) |
| createdAt | timestamp | Fecha |

**reports/{reportId}**

| Campo | Tipo | Descripción |
|---|---|---|
| reporterId | string | UID reportador |
| targetType | string | "review", "provider", "message" |
| targetId | string | ID contenido reportado |
| reason | string | Motivo seleccionado |
| description | string? | Descripción adicional |
| status | string | "pending", "resolved", "dismissed" |
| actionTaken | string? | Acción del admin |
| adminNote | string? | Nota interna |
| resolvedBy | string? | UID admin |
| resolvedAt | timestamp? | Fecha resolución |
| createdAt | timestamp | Fecha reporte |

**subscriptions/{uid}**

| Campo | Tipo | Descripción |
|---|---|---|
| plan | string | "free", "pro", "trial" |
| status | string | "active", "cancelled", "expired" |
| trialStartDate | timestamp? | Inicio trial |
| trialEndDate | timestamp? | Fin trial |
| trialUsed | boolean | No se puede reactivar |
| subscriptionStartDate | timestamp? | Inicio suscripción paga |
| subscriptionEndDate | timestamp? | Fin período actual |
| nextBillingDate | timestamp? | Próximo cobro |
| paymentMethod | string? | Medio de pago |
| mercadoPagoSubscriptionId | string? | ID externo |
| limits | map | { maxPhotos, maxCategories, maxZones, maxActiveRequests } |
| createdAt | timestamp | Creación |
| updatedAt | timestamp | Última modificación |

**notifications/{uid}/items/{notifId}**

| Campo | Tipo | Descripción |
|---|---|---|
| type | string | Tipo de evento |
| title | string | Título |
| body | string | Cuerpo |
| targetRoute | string | Deep link |
| relatedId | string? | ID recurso |
| read | boolean | Leída |
| createdAt | timestamp | Creación |

**verification_requests/{requestId}**

| Campo | Tipo | Descripción |
|---|---|---|
| uid | string | UID prestador |
| status | string | "pending", "approved", "rejected" |
| documentFrontUrl | string | DNI frente |
| documentBackUrl | string | DNI dorso |
| professionalLicenseUrl | string? | Matrícula |
| rejectionReason | string? | Motivo rechazo |
| reviewedBy | string? | UID admin |
| createdAt | timestamp | Solicitud |
| reviewedAt | timestamp? | Revisión |

**admin_log/{logId}**

| Campo | Tipo | Descripción |
|---|---|---|
| adminId | string | UID admin |
| action | string | Tipo acción |
| targetType | string | Tipo recurso |
| targetId | string | ID recurso |
| note | string? | Nota interna |
| metadata | map? | Datos adicionales |
| createdAt | timestamp | Fecha |

### C.3 Relaciones entre Colecciones

- **users ↔ providers:** 1:1 por UID compartido. Todo provider tiene un user; no todo user tiene un provider.
- **users ↔ subscriptions:** 1:1 por UID compartido.
- **providers → categories:** N:M mediante array categoryIds.
- **service_requests → users:** N:1 mediante clientId y providerId.
- **service_requests → categories:** N:1 mediante categoryId.
- **reviews → service_requests:** 1:1 mediante requestId.
- **reviews → providers:** N:1 mediante providerId.
- **reports → contenido:** Polimórfica mediante targetType + targetId.
- **notifications → usuarios:** Composición (subcolección por usuario).

### C.4 Índices Compuestos

```
providers:
  categoryIds (array-contains) + rating.average (desc)
  searchKeywords (array-contains-any) + rating.average (desc)
  categoryIds (array-contains) + plan (==) + rating.average (desc)

service_requests:
  clientId (==) + createdAt (desc)
  providerId (==) + status (==) + createdAt (desc)
  status (==) + expiresAt (<=)
  status (==) + autoCompleteAt (<=)

reviews:
  providerId (==) + createdAt (desc)

reports:
  status (==) + createdAt (asc)

notifications/{uid}/items:
  read (==) + createdAt (desc)

verification_requests:
  status (==) + createdAt (asc)

admin_log:
  action (==) + createdAt (desc)
  targetType (==) + targetId (==) + createdAt (desc)
```

---

## Anexo D — Lógica de Negocio

### D.1 Máquina de Estados — Solicitud de Servicio

```
                         ┌──────────┐
              ┌─────────>│ EXPIRED  │ (terminal)
              │          └──────────┘
              │
              │          ┌──────────┐
              ├─────────>│ REJECTED │ (terminal)
              │          └──────────┘
              │
┌─────────────┤          ┌───────────┐
│   PENDING   ├─────────>│ CANCELLED │ (terminal)
└──────┬──────┘          └───────────┘
       │
       │ (prestador acepta)
       v
┌──────────────┐         ┌───────────┐
│   ACCEPTED   ├────────>│ CANCELLED │ (terminal)
└──────┬───────┘         └───────────┘
       │
       │ (prestador inicia)
       v
┌──────────────┐         ┌───────────┐
│ IN_PROGRESS  ├────────>│ CANCELLED │ (terminal)
└──────┬───────┘         └───────────┘
       │
       │ (prestador finaliza)
       v
┌───────────────────┐
│    AWAITING       │
│  CONFIRMATION     ├───> (cliente disputa) ──> IN_PROGRESS
└──────┬──────┬─────┘
       │      │
       │      └──> (72hs timeout) ──> COMPLETED
       │
       │ (cliente confirma)
       v
┌──────────────┐
│  COMPLETED   │
└──────┬───────┘
       │
       │ (cliente deja reseña)
       v
┌──────────────┐
│   REVIEWED   │ (terminal)
└──────────────┘
```

**Tabla de transiciones:**

| Origen | Destino | Actor | Condición |
|---|---|---|---|
| pending | accepted | Prestador | — |
| pending | rejected | Prestador | — |
| pending | expired | Sistema | expiresAt alcanzado (48hs) |
| pending | cancelled | Cliente | Sin motivo obligatorio |
| accepted | in_progress | Prestador | — |
| accepted | cancelled | Ambos | Motivo obligatorio |
| in_progress | awaiting_confirmation | Prestador | — |
| in_progress | cancelled | Ambos | Motivo obligatorio |
| awaiting_confirmation | completed | Cliente | — |
| awaiting_confirmation | in_progress | Cliente | Disputa |
| awaiting_confirmation | completed | Sistema | autoCompleteAt (72hs) |
| completed | reviewed | Cliente | Una sola reseña por solicitud |

Estados terminales: expired, rejected, cancelled, reviewed.

### D.2 Máquina de Estados — Suscripción

| Origen | Destino | Trigger |
|---|---|---|
| free | trial | Prestador activa trial |
| trial | free | 30 días sin pago |
| trial | pro | Pago durante trial |
| free | pro | Pago directo |
| pro | free | Cancelación o no renovación (al fin del período) |

Restricción: trial una sola vez (trialUsed permanente).

### D.3 Reglas de Negocio Clave

**Registro y acceso:** Navegación pública sin registro. Solicitudes requieren email verificado + datos completos. Usuario suspendido no puede crear solicitudes, enviar mensajes ni reseñar.

**Perfiles:** Datos mínimos para publicar: 1+ categoría + 1+ zona. Eliminación de datos mínimos desactiva perfil. Campos rating, plan, isVerified, searchKeywords solo modificables por Cloud Functions. Desactivación manual no afecta solicitudes en curso.

**Solicitudes:** Hasta 5 activas simultáneas (free), ilimitadas (Pro). Activa = pending, accepted, in_progress, awaiting_confirmation. Cancelación post-pending requiere motivo. Timeout respuesta: 48hs (recordatorio a 24hs). Timeout confirmación: 72hs (auto-completación).

**Reseñas:** Una por solicitud completada. Solo el cliente de esa solicitud. Rating 1-5. Recálculo full desde cero (idempotencia).

**Monetización:** Plan free completamente funcional. Boost Pro: 15% sobre score. Fotos/categorías excedentes se ocultan (no eliminan) al bajar de plan. Cancelación mantiene acceso hasta fin del período.

**Enforcement server-side de límites de plan:** Los límites definidos en `subscriptions.limits` (maxPhotos, maxCategories, maxZones, maxActiveRequests) son validados EXCLUSIVAMENTE por Cloud Functions — nunca por el cliente. El cliente NO es fuente de verdad para límites del plan. Triggers responsables: `onProviderWrite` valida fotos/categorías/zonas al escribir; `onRequestCreate` valida maxActiveRequests antes de crear. Si un usuario free intenta exceder el límite: la operación falla silenciosamente (los datos extra son descartados) y el cliente recibe el documento actualizado sin los campos excedentes. Este enforcement server-side es no negociable: un usuario con acceso directo a Firestore no puede bypasear los límites del plan.

---

## Anexo E — Seguridad

### E.1 Autenticación

Firebase Authentication gestiona credenciales (hashing bcrypt), tokens JWT, bloqueo tras intentos fallidos. Métodos: email/contraseña + Google Sign-In (OAuth 2.0). Sesión persistente sin expiración forzada, refresh automático.

### E.2 Autorización

Custom Claims en JWT (`role`: client, provider, admin) establecidos por Cloud Functions. Firestore Security Rules verifican autenticación, rol, propiedad y transiciones de estado válidas (función `validTransition()`).

### E.3 Reglas de Acceso por Colección

| Colección | Lectura | Escritura |
|---|---|---|
| users/{uid} | Autenticado | Propietario (excepto role) o admin |
| providers/{uid} | Pública | Propietario (excepto campos protegidos) o admin |
| categories/ | Pública | Solo admin |
| service_requests/ | Partes involucradas o admin | Creación: cliente no suspendido. Update: según máquina de estados. |
| messages/ (sub) | Partes de la solicitud | Participante + solicitud activa + senderId == auth.uid |
| reviews/ | Pública | Creación: cliente (clientId == auth.uid). Modificación: admin. |
| reports/ | Reportador o admin | Creación: autenticado. Modificación: admin. |
| subscriptions/{uid} | Propietario o admin | Solo Cloud Functions |
| notifications/{uid}/items/ | Propietario | Propietario (solo campo read). Creación: Cloud Functions. |
| admin_log/ | Solo admin | Solo Cloud Functions |
| verification_requests/ | Solicitante o admin | Creación: propietario. Modificación: admin. |

### E.4 Protección de Datos Sensibles

- Campos calculados (rating, searchKeywords, plan, isVerified, completionPercentage, responseRate) protegidos contra escritura cliente. Solo Cloud Functions.
- Contraseñas gestionadas por Firebase Auth, nunca en Firestore.
- Documentos de verificación en Storage con acceso restringido a propietario + admin.
- Tokens FCM limpiados automáticamente al detectar inválidos.

### E.5 Decisiones de Seguridad Explícitas

Las siguientes decisiones son no negociables y deben implementarse antes del lanzamiento:

**Webhook Mercado Pago:** Toda invocación al endpoint de webhook debe validar la firma HMAC-SHA256 contra el webhook secret antes de procesar cualquier evento. Sin validación de firma, el endpoint debe responder 401. Razón: sin validación, cualquier actor puede simular activaciones de suscripción Pro sin pagar.

**Asignación de rol provider:** El Cloud Function que setea el Custom Claim `role: provider` debe validar que el `uid` del caller coincide con el `uid` del documento que se está modificando. Toda asignación de rol queda registrada en `admin_log/`. Razón: sin esta validación, cualquier usuario autenticado puede escalar su propio rol.

**File uploads:** Storage rules y Cloud Functions deben enforcer: tipos permitidos = `image/jpeg`, `image/png`, `image/webp`; tamaño máximo = 5MB por archivo; headers de respuesta incluyen `Content-Disposition: attachment` para prevenir ejecución en el browser. Razón: sin restricciones, un actor puede hacer DoS con archivos grandes o servir contenido ejecutable.

**Rate limiting en mensajes:** Cloud Functions deben limitar la creación de mensajes a máximo 10 por minuto por usuario. Solicitudes que excedan el límite reciben error 429. Razón: sin rate limiting, un actor puede generar spam de FCM y agotar cuota de notificaciones.

**Verificación server-side de suspensión:** Las operaciones sensibles (crear solicitud, enviar mensaje, dejar reseña) deben verificar `users.suspendedUntil` en el servidor antes de ejecutar, no solo en el cliente. Razón: el cliente puede tener estado cacheado stale; la suspensión debe ser efectiva inmediatamente desde el servidor.

### E.6 Política de Privacidad y Retención de Datos

Conforme a Ley 25.326 y como requisito previo al lanzamiento:

**Retención de datos:** Datos de usuarios activos se conservan indefinidamente mientras la cuenta esté activa. Cuentas inactivas por 2 años reciben notificación de próximo borrado. A los 3 años de inactividad, los datos personales son eliminados; los datos agregados anónimos (ratings, contadores) pueden conservarse.

**Derecho de supresión y exportación:** En v1, ejercicio de derechos (acceso, rectificación, supresión, exportación) se gestiona manualmente vía admin panel. No hay flujo self-service para el usuario final en v1. El usuario puede solicitar supresión por email a soporte; el admin ejecuta la eliminación en Firestore y Storage.

**Registro AAIP:** El registro ante la Agencia de Acceso a la Información Pública (AAIP) es obligatorio antes del lanzamiento. Responsable: Fabricio Gómez. Sin registro AAIP, la app no puede lanzarse públicamente.

**Alcance:** Mercado exclusivamente argentino. Sin integración GDPR en v1. La política de privacidad debe estar accesible desde la pantalla de registro y desde la configuración de la cuenta.

---

## Anexo F — Monetización

### F.1 Modelo

Modelo basado en **visibilidad diferenciada** + comisión sobre trabajos completados (Fase 2+). Clientes no pagan. El eje del valor Pro no son límites artificiales de funcionalidad, sino visibilidad y acceso prioritario a demanda.

**Principio de diseño:** El free tier debe ser genuinamente útil para atraer prestadores. El Pro tier resuelve un dolor visible y directamente ligado a ingresos: "Con Pro, los clientes te ven primero."

**Fase 1 (MVP):** Suscripción con visibilidad diferenciada. Sin comisión (los pagos entre partes son externos en v1 — efectivo/transferencia).

**Fase 2+:** Introducir comisión del 5-8% sobre el valor declarado de trabajos completados, procesada via Mercado Pago. Esto desacopla el revenue de la conversión de plan y lo escala con el volumen de transacciones.

**Fundamentación:** Los límites artificiales (fotos, categorías, zonas) no generan dolor real — la mayoría de los prestadores trabaja en 1-2 categorías y zonas. El verdadero dolor es: "Un cliente buscó plomeros y yo aparecí en la segunda pantalla." Eso es pérdida de ingresos, tangible y comprensible.

### F.2 Planes

| Feature | ChangaYa Básico (free) | ChangaYa Pro |
|---|---|---|
| Perfil público | ✅ | ✅ |
| Fotos de portfolio | Sin límite | Sin límite |
| Categorías | Sin límite | Sin límite |
| Zonas de cobertura | Sin límite | Sin límite |
| Responder solicitudes | ✅ | ✅ |
| Mensajería | ✅ | ✅ |
| Valoraciones y reseñas | ✅ | ✅ |
| Notificaciones in-app | ✅ | ✅ |
| **Push en tiempo real (solicitudes nuevas)** | ❌ | ✅ |
| **Sección "Recomendados" en home** | ❌ | ✅ |
| **Posición en búsqueda** | Normal | Prioritaria (+50% boost) |
| **Estadísticas de perfil** | ❌ | ✅ visitas, conversión, comparativa por categoría |
| Badge Pro prominente | ❌ | ✅ |
| Verificación de identidad | Costo separado | Incluida |

**Precio:** Pro ARS $4.500/mes. Mensual sin compromiso. Trial 30 días gratis (una vez). Medio: Mercado Pago.

**Por qué el push es clave:** Un prestador free que no tiene push no se entera de una solicitud hasta que abre la app. Un prestador Pro la ve en el momento. Si dos plomeros reciben la misma solicitud, el Pro responde primero. Este mecanismo es invisible para el cliente pero muy real para el prestador.

### F.3 Modelo Secundario

Verificación de identidad: pago único $1.500-$2.500 ARS. DNI + matrícula opcional. Admin revisa manualmente. Badge permanente "Identidad Verificada" sin ventaja en ranking.

### F.4 Hoja de Ruta

**Fase 1 (meses 1-3):** Todo gratis. Meta: 100 prestadores, 50 solicitudes/mes.
**Fase 2 (meses 4-6):** Pro con trial + visibilidad diferenciada activa. Verificación de identidad. Meta: 5-8% conversión a Pro (el dolor de visibilidad es tangible, target más alto que modelo de features). Introducir comisión 5-8% en trabajos completados via Mercado Pago.
**Fase 3 (meses 7-12):** Ajuste de precios, plan anual (20% off), estadísticas avanzadas (benchmark vs competidores en la misma categoría). Meta: 8-12% conversión + comisión cubriendo costos operativos.

### F.5 Estrategia de Conversión Trial → Paid

El trial por defecto convierte por debajo del 1% sin intervención activa. Secuencia de conversión obligatoria:

- **Día 7 del trial:** Push + email mostrando estadísticas de perfil ("Tuviste X visitas esta semana con Pro").
- **Día 23 del trial:** Push + email con oferta de 10% de descuento en el primer mes si se suscribe antes del vencimiento.
- **Día 28 del trial:** Segunda notificación con opción de plan anual a 20% de descuento.
- **Día 30 (vencimiento):** Downgrade silencioso a Free. Badge Pro desaparece; límites se aplican.
- **Día 60 (winback):** Email/push con oferta de reactivación ("Volvé a Pro por ARS $2.000 el primer mes").

Esta secuencia debe estar documentada como requisito funcional del módulo de suscripciones y ejecutada por Cloud Functions programadas (no por el cliente).

### F.5 Estrategias de Rendimiento y Escalabilidad

**Rendimiento:** Desnormalización de campos frecuentes. Cache offline Firestore. Snapshot listeners selectivos (solo chat, estado solicitud, badge notificaciones). Compresión de imágenes en cliente. Infinite scroll (20 resultados/carga).

**Escalabilidad:** Escalado automático Firebase. Separación lectura/escritura. Cloud Functions idempotentes (full recalculation). Umbrales definidos con acciones concretas (ver sección 9).
