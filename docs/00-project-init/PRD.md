# PRD: ChangaYa

> Marketplace de servicios locales para la provincia de Formosa, Argentina — conecta clientes con prestadores de servicios independientes (plomeros, electricistas, carpinteros y más) de forma organizada, confiable y accesible.

**Version**: 0.1.0-draft (MVP)
**Author**: Equipo ChangaYa
**Date**: Marzo 2026
**Status**: Draft
**RFC asociado**: [RFC.md](./RFC.md)

---

> **Qué es este documento:**
> Este PRD (Product Requirements Document) define QUÉ se construye y PARA QUIÉN. Se enfoca en el problema, los usuarios, el alcance funcional, los requisitos y el roadmap. Para el diseño técnico detallado (arquitectura, stack, deployment, testing), ver el [RFC.md](./RFC.md) asociado.

---

## 1. Contexto y Objetivo

> **Por qué existe esta sección:** Definí el problema real, no la solución. Sé específico: quién sufre el problema, con qué frecuencia, y cuál es el costo de no resolverlo. Si arrancás hablando de features antes de hablar del dolor, el producto va a fallar.

### 1.1 Problem Statement

El mercado de servicios independientes en la provincia de Formosa opera de forma mayormente informal y fragmentada. Trabajadores independientes —plomeros, electricistas, carpinteros, mecánicos, contadores, pintores, diseñadores gráficos, programadores, entre otros— consiguen sus clientes casi exclusivamente a través de contactos personales, recomendaciones de boca en boca o publicaciones informales en grupos de WhatsApp y Facebook. Del mismo modo, quienes necesitan contratar alguno de estos servicios no disponen de un canal centralizado donde buscar, comparar y contactar prestadores de confianza.

Desde el lado del prestador, el alcance queda limitado al círculo de conocidos inmediatos, no existe un espacio propio donde mostrar trabajo, experiencia, tarifas y valoraciones previas, y la informalidad del canal dificulta la construcción de una reputación profesional sostenible. Los prestadores de servicios digitales tienen aún menos visibilidad local y suelen migrar a plataformas nacionales donde compiten en desventaja.

Desde el lado del cliente, quien necesita contratar un servicio recurre a grupos de Facebook, pregunta en WhatsApp o espera una recomendación personal. No existe un mecanismo que permita comparar prestadores, consultar reseñas de otros clientes o verificar la idoneidad de quien se va a contratar. La falta de información genera desconfianza y malas experiencias que podrían evitarse con mayor transparencia.

Es un problema cotidiano y persistente. La escala es provincial (~600.000 habitantes en Formosa) con alta densidad de trabajadores informales.

| Rol afectado | Problemas específicos |
|---|---|
| Prestadores de oficios tradicionales | Alcance limitado al boca en boca, sin espacio para mostrar portfolio ni acumular reputación verificable |
| Prestadores de servicios digitales | Aún menos visibilidad local, migración forzada a plataformas nacionales con competencia desigual |
| Clientes que necesitan contratar servicios | Sin canal organizado, dependen de recomendaciones personales, no pueden comparar ni verificar antecedentes |

| Solución actual | Limitaciones |
|---|---|
| Grupos de WhatsApp | Sin organización, sin historial, sin reputación verificable, alcance limitado |
| Grupos de Facebook | Publicaciones se pierden, sin búsqueda por categoría, sin calificaciones |
| Boca en boca personal | Alcance extremadamente limitado, no escalable |
| Plataformas nacionales (Workana, GetOnBoard) | No contemplan oficios tradicionales ni escala local |

### 1.2 Propuesta de Valor

Para conseguir valor real se necesita:

- Un canal centralizado donde cualquier vecino de Formosa pueda buscar prestadores por categoría, zona y reputación verificable.
- Un espacio propio para prestadores donde mostrar portfolio, acumular calificaciones y recibir solicitudes organizadas.
- Un ciclo de vida completo para las solicitudes de servicio: desde el primer contacto hasta la reseña final.
- Un modelo freemium que permita a los prestadores empezar sin costo y crecer con herramientas pagas.

Los usuarios primarios son ciudadanos de Formosa —clientes que necesitan contratar servicios y prestadores que quieren hacer crecer su negocio— con distintos niveles de experiencia tecnológica. La app debe ser accesible para alguien que usa principalmente WhatsApp.

**Este producto resuelve el problema al proveer una plataforma digital centralizada que conecta prestadores de servicios con clientes de la provincia, ofreciendo perfiles profesionales con portfolio y reputación verificable, búsqueda organizada por categoría y zona, un sistema de solicitudes de presupuesto con ciclo de vida completo, y mensajería contextual, todo diseñado para la escala y las características del mercado local formoseño.**

### 1.3 Visión

> La visión es el norte del producto. Cada decisión de diseño y arquitectura debe poder justificarse contra esta visión. Si una feature no contribuye a la visión, no va.

Ser la plataforma de referencia para la contratación de servicios independientes en Formosa, donde cualquier vecino pueda encontrar al profesional que necesita con confianza, y cualquier trabajador pueda hacer crecer su negocio más allá de su círculo cercano.

| Componente | Descripción |
|---|---|
| App Móvil (Android/iOS) | Aplicación Flutter multiplataforma para clientes y prestadores. Canal principal de interacción. |
| App Web | Versión web para navegación pública de perfiles (compartibles por WhatsApp) y acceso al panel de administración. |
| Panel de Administración | Interfaz web (Flutter Web) para gestión de categorías, usuarios, reportes y verificaciones. |
| Backend Serverless (Firebase) | Authentication, Firestore, Storage, Cloud Functions, FCM, Security Rules. |
| Integración de Pagos (Fase 2) | Mercado Pago para procesamiento de suscripciones Pro y comisiones. |

### 1.4 Fuentes de Referencia Clave

- `context.md` — Documento de contexto completo del proyecto (fuente de verdad)
- Propuesta de Trabajo Integrador Final — Documento académico original que describe el contexto del problema y los objetivos del proyecto

---

## 2. Público Objetivo

> **Por qué existe esta sección:** Código que no conoce a su usuario siempre falla. Definí exactamente para quién construís. El agente IA usa esta sección para tomar decisiones de UX coherentes.

### 2.1 Usuarios Primarios

| Rol | Responsabilidad | Necesidades específicas |
|---|---|---|
| Cliente | Buscar servicios, enviar solicitudes de presupuesto, coordinar trabajos, calificar prestadores | Encontrar prestadores confiables cerca de su zona. Comparar opciones con reseñas verificables. Proceso simple y de baja fricción, accesible para usuarios con distintos niveles tecnológicos. Navegación sin registro obligatorio. |
| Prestador de servicios | Ofrecer servicios, gestionar perfil profesional, responder solicitudes, construir reputación | Visibilidad más allá del boca en boca. Espacio propio para mostrar trabajo y acumular reputación. Recibir solicitudes organizadas. Herramientas para gestionar su negocio (estadísticas, portfolio). Plan gratuito funcional con opción de mejora paga. |

**Notas sobre roles:**
- Un usuario puede ser cliente y prestador simultáneamente (misma cuenta, rol ampliado). No son tipos de cuenta separados.
- El rol de prestador se activa sobre una cuenta de cliente existente (patrón Airbnb: cualquier huésped puede volverse anfitrión).
- Los roles se implementan mediante Custom Claims en el token JWT de Firebase Authentication.

### 2.2 Usuarios Secundarios

| Rol | Responsabilidad | Necesidades específicas |
|---|---|---|
| Administrador | Gestionar la operación de la plataforma: categorías, usuarios, reportes, verificaciones | Panel con métricas operativas. Cola de reportes pendientes. Herramientas de moderación con registro de auditoría. Gestión de verificaciones de identidad. |

El rol de administrador se asigna manualmente vía consola de Firebase o Cloud Function protegida.

---

## 3. Alcance

> **Por qué existe esta sección:** Definir el alcance previene scope creep y alinea al equipo sobre qué se construye y qué NO se construye en esta versión. Lo que está fuera de scope se documenta explícitamente para no perder las ideas.

### 3.1 Dentro del Alcance (v1)

- Registro y autenticación (email/contraseña + Google)
- Gestión de roles cliente/prestador/admin con Custom Claims
- Perfiles de prestadores con portfolio, categorías, zonas y reputación
- Motor de búsqueda por categoría, zona y texto libre con filtros
- Sistema de solicitudes de presupuesto con ciclo de vida de 9 estados
- Mensajería contextual vinculada a solicitudes (texto + imágenes)
- Valoraciones y reseñas post-servicio (1-5 estrellas)
- Notificaciones push (FCM) + in-app
- Panel de administración web (Flutter Web)
- Sistema de reportes de contenido inapropiado
- Suscripción freemium para prestadores (Básico/Pro)
- Verificación de identidad manual por admin
- Geolocalización opcional para distancias aproximadas

### 3.2 Fuera del Alcance (v1)

- Pagos entre cliente y prestador a través de la plataforma (solo suscripciones Pro)
- Comisión sobre trabajos completados (Fase 2+, requiere pagos integrados)
- Geolocalización por GPS obligatoria o almacenamiento de coordenadas del cliente
- Full-text search con fuzzy matching (Algolia/Typesense — se evalúa a 500+ prestadores)
- Bloqueo del prestador hacia el cliente (solo cliente → prestador en v1)
- Flujo de apelación formal para verificaciones rechazadas
- Export/delete self-service de datos personales (gestionado manualmente en v1)
- Landing page pública con HTML estático
- Penalizaciones automáticas por cancelación
- Integración GDPR (mercado exclusivamente argentino)

---

## 4. Plataformas y Entornos Soportados

> **Por qué existe esta sección:** Las decisiones de plataforma determinan la arquitectura técnica. Definirlas antes evita descubrir incompatibilidades tarde. Asignale prioridades para saber en qué invertir primero.

| Plataforma | Prioridad | Versión mínima | Notas |
|---|---|---|---|
| Android | Alta (primaria) | Android 8.0+ (API 26) | Mercado principal. Gama media-baja (2GB RAM, Snapdragon 400-series o equivalente). |
| iOS | Media | iOS 14+ | Mercado secundario en Formosa. Misma codebase Flutter. |
| Web | Baja (admin) | Navegadores modernos (Chrome 90+, Firefox 88+, Safari 14+) | Principalmente para panel de administración y navegación pública de perfiles. |

**Notas de compatibilidad:**
- Un único codebase Flutter cubre Android, iOS y Web (RNF-01).
- Red mínima soportada: 3G. Decisión explícita: no hay estrategia 2G (cobertura 3G garantizada en Formosa).
- Carga de imagen < 5s en 3G. Pantallas principales < 3s en 4G. Búsqueda < 2s.
- Flutter Web tiene rendimiento inferior a web nativa para interfaces con mucho scroll — aceptable para panel admin (uso interno).

---

## 5. Requisitos Funcionales

> **Por qué existe esta sección:** Esta es la columna vertebral del PRD. Cada feature tiene su propio bloque con descripción, tabla de sub-componentes y requirements numerados. Los requirements se mapean directamente a specs SDD y a tests TDD. Si no podés escribir un test para un requirement, está mal redactado.

### RF-01 — Registro y Autenticación

Registro mediante email/contraseña o Google (OAuth 2.0). Verificación de email y recuperación de contraseña.

| Sub-componente | Descripción |
|---|---|
| Registro email/contraseña | Nombre + email + contraseña. Acepta términos y condiciones. |
| Registro con Google | OAuth 2.0 via Firebase Authentication. |
| Verificación de email | Enlace enviado al crear cuenta. El usuario puede navegar pero no enviar solicitudes hasta verificar. |
| Recuperación de contraseña | Enlace de recuperación vía email. Validez: 1 hora. |
| Sesión persistente | Sin expiración forzada. Refresh automático de tokens. |
| Bloqueo de cuenta | Bloqueo temporal tras 5 intentos fallidos. |
| Cierre de sesión | Limpieza de estado local. |

### RF-02 — Gestión de Roles

Tres roles: cliente, prestador, administrador. Cliente puede activar rol de prestador sobre la misma cuenta.

| Sub-componente | Descripción |
|---|---|
| Rol cliente | Por defecto al registrarse. |
| Rol prestador | Se activa sobre cuenta cliente existente. Wizard de 4 pasos (categorías → zonas → descripción → portfolio). |
| Rol admin | Asignado manualmente vía Firebase Console o Cloud Function protegida. |
| Custom Claims | Implementación via JWT Claims. Guardias de navegación por rol en GoRouter. |

### RF-03 — Perfiles de Prestadores

Perfil profesional con categorías, especialidades, zona de cobertura, descripción, experiencia, tarifas y portfolio.

| Sub-componente | Descripción |
|---|---|
| Datos básicos | Categorías (sin límite), especialidades libres, zonas de cobertura (sin límite), descripción, experiencia, tarifas orientativas. |
| Portfolio | Fotos de trabajos (sin límite) con compresión automática (1024px, 80%). |
| Indicador de completitud | Porcentaje visible al prestador con sugerencias de mejora. |
| Guardado automático | Por campo individual (patrón LinkedIn). Sin botón "Guardar todo". |
| Toggle visibilidad | Prestador puede desactivarse temporalmente sin perder datos ni reseñas. |
| Badges | Pro (plan pago) + Verificado (identidad aprobada). |

### RF-04 — Búsqueda y Filtrado

Motor de búsqueda por categoría, zona geográfica, valoración y texto libre. Ordenamiento por relevancia.

| Sub-componente | Descripción |
|---|---|
| Navegación por categorías | Grid con íconos en home. |
| Búsqueda por texto libre | Keywords generados automáticamente por Cloud Function (singular/plural, sin acentos). |
| Filtros | Zona, valoración mínima, rango de precio, criterio de ordenamiento. |
| Ordenamiento | Mejor valorados, más reseñas, más recientes. |
| Relevancia | `rating_promedio × log(reseñas + 1)` con boost **50%** para plan Pro (diferencia visible en resultados). |
| Sección "Recomendados" | Solo prestadores Pro. Aparece en home antes del grid de categorías. Ordenada por relevancia entre Pro. |
| Paginación | Infinite scroll, 20 resultados por carga. |
| Distancia aproximada | Si el usuario concede permiso de ubicación: muestra "~X km" calculado client-side (Haversine). No se almacena la ubicación del cliente en el backend. |

### RF-05 — Solicitudes de Presupuesto

Envío de solicitudes con descripción, fotos y ubicación. Ciclo de vida con 9 estados definidos.

| Estado | Descripción |
|---|---|
| pending | Solicitud enviada, esperando respuesta del prestador (timeout: 48hs) |
| accepted | Prestador aceptó, trabajo pendiente de inicio |
| in_progress | Trabajo en ejecución |
| awaiting_confirmation | Prestador marcó finalización, esperando confirmación del cliente (timeout: 72hs) |
| completed | Trabajo confirmado |
| reviewed | Cliente dejó reseña (terminal) |
| rejected | Prestador rechazó (terminal) |
| expired | Sin respuesta en 48hs (terminal) |
| cancelled | Cancelado por alguna de las partes (terminal) |

**Límite de sistema:** hasta 5 solicitudes activas simultáneas por usuario (free). No es un diferenciador comercial — es una medida de protección del sistema para la escala del MVP. Las solicitudes ilimitadas están disponibles con plan Pro. Activa = pending, accepted, in_progress, awaiting_confirmation.

### RF-06 — Mensajería Contextual

Mensajes entre cliente y prestador vinculados a una solicitud. Soporte para texto e imágenes.

| Sub-componente | Descripción |
|---|---|
| Hilo vinculado | Creado automáticamente con la solicitud. |
| Tipos de mensaje | Usuario (texto + hasta 3 imágenes) y sistema (cambios de estado). |
| Indicadores de lectura | El remitente ve si su mensaje fue leído. |
| Cierre al terminar | Solo lectura cuando la solicitud llega a estado terminal. |
| Inmutabilidad | Los mensajes no se pueden editar ni eliminar (decisión intencional — preserva historial para disputas). |

### RF-07 — Valoraciones y Reseñas

Calificación 1-5 estrellas con comentario post-servicio. Rating promedio en perfil del prestador.

- Una reseña por solicitud completada. Solo el cliente de esa solicitud.
- Rating recalculado desde cero por Cloud Function (full recalculation, idempotente).
- Reseñas públicas. Admin puede ocultarlas.

### RF-08 — Notificaciones

Push y notificaciones in-app para eventos relevantes: solicitudes, estados, mensajes, reseñas.

- **Push (FCM):** solo para prestadores **Pro**. Tiempo real al crearse una solicitud que coincide con su perfil (categoría + zona). Esto es un gate de plan, no solo una feature de UX.
- **In-app:** todos los usuarios (free y Pro). Respaldo si push no llega; único canal para free.
- Centro de notificaciones: badge de no leídas, navegación al contexto, marcar todas como leídas.
- Push para otros eventos (mensajes, cambios de estado) disponibles para todos — el gate aplica solo a notificaciones de nueva solicitud entrante.

### RF-09 — Panel de Administración

Gestión de usuarios, categorías, reportes y métricas básicas (Flutter Web).

| Pantalla | Funciones |
|---|---|
| Dashboard | Métricas (usuarios, prestadores, solicitudes, reportes), alertas operativas |
| Usuarios | Lista filtrable por rol/estado/fecha, detalle con historial, acciones (suspender/reactivar/eliminar) |
| Categorías | CRUD, ordenamiento, protección contra eliminar categorías con prestadores activos |
| Reportes | Cola pendientes, contenido reportado, acciones + auditoría |
| Verificaciones | Cola solicitudes, revisión documentos, aprobar/rechazar |

### RF-10 — Sistema de Reportes

Reporte de contenido inapropiado con selección de motivo por cualquier usuario autenticado.

- Motivos disponibles: contenido ofensivo, información falsa, spam, datos personales expuestos, otro (con texto obligatorio).
- Contenido reportado NO se oculta automáticamente (previene abuso).
- Admin revisa y elige: desestimar, ocultar, advertir, suspender (7 o 30 días).
- Toda acción queda en `admin_log/`.

### RF-11 — Suscripción Freemium

Plan gratuito y plan Pro con diferenciación basada en **visibilidad** y **acceso prioritario a demanda** — no en límites artificiales de funcionalidad.

**Principio de diseño:** El free tier es genuinamente útil (sin límites de fotos/categorías/zonas). El Pro tier resuelve un dolor visible y directamente ligado a ingresos: "Con Pro, los clientes te ven primero."

| Feature | ChangaYa Básico (free) | ChangaYa Pro (ARS $4.500/mes) |
|---|---|---|
| Perfil, fotos, categorías, zonas | Sin límite | Sin límite |
| Responder solicitudes + mensajería | ✅ | ✅ |
| Notificaciones in-app | ✅ | ✅ |
| **Push en tiempo real (solicitudes nuevas)** | ❌ | ✅ |
| **Sección "Recomendados" en home** | ❌ | ✅ |
| **Posición en búsqueda** | Normal | Prioritaria (+50% boost) |
| **Estadísticas de perfil** | ❌ | ✅ visitas, conversión, comparativa |
| Badge Pro prominente | ❌ | ✅ |
| Verificación de identidad | Costo separado | Incluida |

- Trial 30 días gratis (una vez, solo plan Pro).
- Medio de pago: Mercado Pago.
- Push como gate de plan: free recibe notificaciones solo in-app; Pro recibe push en tiempo real al crearse una solicitud que coincide con su perfil. Esto crea diferencia real de velocidad de respuesta.
- Al cancelar Pro: perfil vuelve a posición normal en búsqueda, pierde push y sección Recomendados. Datos intactos.
- Estrategia trial→paid: secuencia de notificaciones en días 7, 23, 28, 30 y 60 (ver context.md Anexo F.5).

### RF-12 — Verificación de Identidad

Solicitud de verificación mediante documentación, sujeta a aprobación del administrador.

- El prestador sube foto de DNI (frente + dorso) y matrícula opcional.
- Admin revisa manualmente. Badge permanente "Identidad Verificada" al aprobar.
- Si rechaza: notificación con motivo (`rejectionReason`) + botón "Volver a intentar" (máx 3 intentos/día).
- Pago único ARS $1.500-$2.500 (Fase 2). En Fase 1: gratuito o diferido.

### RF-13 — Geolocalización Opcional

La app puede usar la ubicación del dispositivo (con consentimiento explícito) para mostrar distancia aproximada entre el usuario y los prestadores en resultados de búsqueda.

- Completamente opcional: si el usuario no concede permiso, todos los flujos continúan sin cambios.
- Las coordenadas del cliente NUNCA se almacenan en el backend.
- Cálculo de distancia Haversine client-side.
- También permite seleccionar ubicación del trabajo en solicitudes mediante pin en mapa (flutter_map + OpenStreetMap).

---

## 6. Requisitos No Funcionales

> **Por qué existe esta sección:** Los NFRs son los que se ignoran hasta que el sistema explota en producción. Definirlos acá asegura que el RFC los considere en la arquitectura.

### 6.1 Performance

- Pantallas principales < 3s en 4G. Búsqueda < 2s. Carga de imagen < 5s en 3G.
- Dispositivos mínimos: Android 8.0+ (API 26), iOS 14+, gama media-baja (2GB RAM, Snapdragon 400-series o equivalente).
- Red mínima: 3G. Sin estrategia 2G (decisión explícita).

**Herramientas de validación:**
- Firebase Performance Monitoring — latencias de red en producción.
- flutter_driver / integration_test — benchmarks automatizados de flujos críticos contra Firebase Emulator.
- Playwright CLI (`npx skills add https://github.com/microsoft/playwright-cli --skill playwright-cli`) — E2E del admin dashboard y flujos web.

### 6.2 Security

- HTTPS/TLS en todas las comunicaciones.
- Firestore Security Rules server-side. Contraseñas nunca en texto plano (gestionadas por Firebase Auth).
- Webhook Mercado Pago: validación HMAC-SHA256 obligatoria antes de procesar cualquier evento.
- Asignación de rol provider: Cloud Function valida `uid` caller == dueño del documento + audit log.
- File uploads: tipos permitidos = image/jpeg, image/png, image/webp. Tamaño máximo = 5MB. Content-Disposition: attachment.
- Rate limiting: máx 10 mensajes/minuto por usuario.
- Operaciones sensibles verifican `users.suspendedUntil` server-side (no solo client-side).
- Cumplimiento Ley 25.326 (Argentina). Registro AAIP obligatorio antes del lanzamiento.

### 6.3 Reliability

- ≥ 99% uptime (infraestructura Firebase — SLA de Google).
- In-app notifications como respaldo si push no llega (FCM no garantiza entrega).
- Cloud Functions idempotentes (full recalculation, nunca incrementos).
- Operaciones multi-documento con Firestore transactions.

### 6.4 Extensibility

- De cientos a decenas de miles de usuarios sin cambios estructurales (escalado automático Firebase).
- Umbrales definidos con acciones concretas:

| Umbral | Acción requerida |
|---|---|
| 500+ prestadores | Evaluar Algolia/Typesense para búsqueda full-text |
| 10.000+ usuarios | Habilitar Firebase App Check |
| 50.000+ lecturas/día | Cache con Firestore bundles para categorías |
| 100.000+ imágenes | Extensión Resize Images para thumbnails |
| Expansión geográfica | Particionamiento de datos por región |

### 6.5 Accessibility

- Utilizable por personas con distintos niveles de experiencia tecnológica.
- Material Design 3 (Material You) — accesibilidad incluida (contraste, tamaños, etiquetas).
- Diseñado para usuarios que usan principalmente WhatsApp: flujos simples, sin jerga técnica.

---

## 7. User Experience

> **Por qué existe esta sección:** El flujo de usuario define la arquitectura de la UI antes de escribir una línea. Documentarlo como diagrama evita rediseños costosos. El agente IA genera componentes coherentes con este flujo cuando lo tiene como referencia.

### 7.1 User Flow Principal

**Flujo Cliente:**
```
Visitante → [Navega Home / Busca] → [Ve perfil prestador] → [Registro/Login] 
→ [Verifica email] → [Completa datos mínimos] → [Envía solicitud de presupuesto]
→ [Coordina por mensajería] → [Confirma trabajo completado] → [Deja reseña]
```

**Flujo Prestador:**
```
Cliente existente → [Activa perfil prestador] → [Wizard: categorías → zonas → descripción → portfolio]
→ [Perfil publicado] → [Recibe notificación de solicitud] → [Acepta/rechaza]
→ [Inicia trabajo] → [Marca finalización] → [Recibe confirmación/reseña]
```

**Flujo Admin:**
```
[Login admin] → [Dashboard con métricas] → [Gestiona cola de reportes]
→ [Revisa verificaciones de identidad] → [Modera usuarios si es necesario]
```

### 7.2 Pantallas / Vistas

| # | Pantalla | Acceso | Datos / Funciones clave |
|---|---|---|---|
| P-01 | Home | Pública | Grid categorías, barra de búsqueda, CTA registro |
| P-02 | Resultados de búsqueda | Pública | Lista prestadores, filtros, infinite scroll, distancia aproximada si GPS activo |
| P-03 | Perfil de prestador | Pública | Foto, rating, badges, portfolio, reseñas, botón "Solicitar presupuesto" |
| P-04 | Login | Pública | Email + contraseña, Google |
| P-05 | Registro | Pública | Nombre + email + contraseña, Google, checkbox términos |
| P-06 | Verificación de email | Autenticada | "Revisá tu correo", reenvío con cooldown 60s |
| P-07 | Recuperar contraseña | Pública | Email, enviar enlace |
| P-08 | Completar datos | Autenticada | Teléfono, localidad, foto perfil (opcional) |
| P-09 | Wizard prestador | Autenticada | 4 pasos: categorías → zonas → sobre vos → portfolio |
| P-10 | Editar perfil prestador | Prestador | Campos editables, completitud %, toggle visibilidad |
| P-11 | Crear solicitud | Autenticada | Título, descripción, fotos, ubicación (barrio o pin en mapa) |
| P-12 | Mis solicitudes | Autenticada | Lista por estado, como cliente o prestador |
| P-13 | Detalle de solicitud | Autenticada | Estado, datos, acciones por rol, acceso a chat |
| P-14 | Chat | Autenticada | Hilo de mensajes, input texto + fotos, indicador lectura |
| P-15 | Dejar reseña | Autenticada | Selector estrellas, campo comentario |
| P-16 | Notificaciones | Autenticada | Lista, indicador lectura, marcar todas como leídas |
| P-17 | Configuración | Autenticada | Cerrar sesión, datos de cuenta, preferencias |
| P-18 | Suscripción | Prestador | Comparación planes, trial / suscribirse, estado actual |
| P-19 | Verificación de identidad | Prestador | Upload DNI frente/dorso, matrícula opcional, estado solicitud |
| P-20 | Admin — Dashboard | Admin | Métricas, alertas operativas |
| P-21 | Admin — Usuarios | Admin | Lista filtrable, detalle, acciones |
| P-22 | Admin — Categorías | Admin | CRUD, protección contra eliminación con prestadores |
| P-23 | Admin — Reportes | Admin | Cola pendientes, acciones + auditoría |
| P-24 | Admin — Verificaciones | Admin | Cola solicitudes, aprobar/rechazar |

### 7.3 Modo No-Interactivo / CLI / API

No aplica. ChangaYa es una aplicación móvil/web interactiva. No hay CLI ni API pública en v1.

**Requerimientos de UX clave:**
- Progressive profiling: datos mínimos al registrarse, el resto se pide cuando se necesitan.
- Navegación pública: sin registro para buscar y ver perfiles.
- Guardado automático por campo en perfil prestador (sin "Guardar todo").
- Acciones de bloqueo, reintento de verificación y ajustes de suscripción accesibles desde Configuración.

---

## 8. Historias de Usuario

> **Por qué existe esta sección:** Las historias de usuario conectan los requisitos funcionales con el valor que recibe el usuario. Cada historia sigue el formato "Como [rol], quiero [acción], para [beneficio]" y tiene criterios de aceptación verificables.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| CU-01 | Como visitante, quiero registrarme con email o Google, para tener una cuenta en ChangaYa | Cuenta creada, email de verificación enviado, rol cliente asignado por defecto |
| CU-02 | Como usuario, quiero iniciar sesión, para acceder a mi cuenta | Login exitoso, perfil cargado, redirección según rol |
| CU-03 | Como usuario, quiero recuperar mi contraseña olvidada, para retomar el acceso | Enlace enviado al email, válido 1 hora, nueva contraseña funcional |
| CU-04 | Como cliente, quiero activarme como prestador, para ofrecer mis servicios en la plataforma | Wizard completado (mínimo pasos 2 y 3), perfil publicado en búsquedas |
| CU-05 | Como prestador, quiero editar mi perfil, para mantenerlo actualizado y atractivo | Cambios guardados automáticamente por campo, visibles públicamente en < 5s |
| CU-06 | Como visitante, quiero buscar prestadores por categoría y zona, para encontrar quien necesito | Lista de resultados ordenada por relevancia, con filtros funcionales |
| CU-07 | Como cliente, quiero ver el perfil de un prestador, para evaluar si contratarlo | Perfil completo: descripción, portfolio, rating, reseñas, botón solicitar |
| CU-08 | Como cliente, quiero enviar una solicitud de presupuesto, para coordinar un servicio | Solicitud creada en estado pending, notificación enviada al prestador |
| CU-09 | Como prestador, quiero responder una solicitud, para aceptarla o rechazarla en 48hs | Estado cambia a accepted/rejected, notificación al cliente, mensaje de sistema en el hilo |
| CU-10 | Como prestador, quiero marcar el inicio y fin del trabajo, para gestionar el ciclo de vida | Transiciones de estado correctas, notificaciones en cada cambio |
| CU-11 | Como cliente o prestador, quiero intercambiar mensajes dentro de una solicitud, para coordinar detalles | Mensajes enviados y recibidos en tiempo real, con indicador de lectura |
| CU-12 | Como cliente, quiero dejar una reseña tras completar un servicio, para ayudar a otros usuarios | Reseña guardada, rating del prestador recalculado, badge visible en perfil |
| CU-13 | Como usuario, quiero reportar contenido inapropiado, para mantener la plataforma confiable | Reporte creado con motivo, en cola de admin para revisión |
| CU-14 | Como usuario, quiero gestionar mis notificaciones, para no perder eventos relevantes | Notificaciones listadas con badge, navegación al contexto, marcar como leídas |
| CU-15 | Como prestador, quiero suscribirme al plan Pro, para acceder a más herramientas y visibilidad | Trial activado o pago procesado via Mercado Pago, límites Pro aplicados |
| CU-16 | Como prestador, quiero solicitar verificación de identidad, para tener el badge de confianza | Documentos subidos, solicitud en cola de admin |
| CU-17 | Como admin, quiero gestionar las categorías, para mantener el catálogo actualizado | CRUD funcional, protección contra eliminar categorías con prestadores |
| CU-18 | Como admin, quiero gestionar usuarios, para moderar la plataforma | Lista filtrable, acciones de suspensión/reactivación/eliminación con audit log |
| CU-19 | Como admin, quiero resolver reportes, para moderar contenido inapropiado | Cola de reportes, acciones disponibles, todo registrado en admin_log |
| CU-20 | Como admin, quiero revisar verificaciones de identidad, para aprobar o rechazar con motivo | Revisión de documentos, aprobación activa badge, rechazo notifica al prestador |

---

## 9. Dependencias y Restricciones

> **Por qué existe esta sección:** Las dependencias son la fuente número uno de fallos silenciosos. Documentarlas ANTES de implementar evita "funciona en mi máquina". El RFC detalla la resolución técnica de estas dependencias.

### 9.1 Dependencias del Sistema

| Dependencia | Versión | Rol |
|---|---|---|
| Flutter | 3.x (stable) | Framework principal — Android, iOS, Web |
| Dart | 3.x | Lenguaje nativo de Flutter |
| Firebase SDK para Flutter | Latest | Integración con todos los servicios Firebase |
| Cloud Functions v2 | Node.js 20 + TypeScript | Lógica de servidor |
| Firebase Emulator Suite | — | Entorno de desarrollo local |

### 9.2 Dependencias Externas (APIs, Servicios)

| Servicio | Uso | Fase |
|---|---|---|
| Mercado Pago (API preapproval) | Procesamiento de pagos de suscripción Pro y verificación de identidad | Fase 2 (meses 4-6) |
| Google Sign-In (OAuth 2.0) | Autenticación con Google via Firebase Authentication | Fase 1 |
| OpenStreetMap (tiles) | Mapas en flutter_map (sin API key, sin billing) | Fase 1 |
| Firebase Cloud Messaging (FCM) | Push notifications a Android, iOS y Web | Fase 1 |

### 9.3 Restricciones Conocidas

**Técnicas:**
- Firestore no soporta JOINs (mitigado con cache local y denormalización).
- Firestore no soporta full-text search nativo (búsqueda por keywords suficiente para < 500 prestadores).
- Cloud Functions — cold start de 1-3s en primera invocación tras inactividad (aceptable en MVP).
- FCM no garantiza entrega (respaldo con in-app notifications).
- Flutter Web — rendimiento inferior a web nativa para interfaces con mucho scroll (aceptable para admin interno).
- Firestore no permite dos `array-contains` en la misma query (filtro zona por cliente).

**De producto:**
- No se implementan pagos entre cliente y prestador en v1.
- No hay penalizaciones automáticas por cancelación en v1.
- No hay NLP para bloqueo automático de datos de contacto en mensajes.
- Registro AAIP es prerrequisito de lanzamiento (responsable: Fabricio Gómez).

---

## 10. Roadmap

> **Por qué existe esta sección:** El roadmap define el orden de construcción a nivel de producto. Los detalles técnicos de cada incremento van en el RFC (sección 6). Acá se define QUÉ se entrega en cada fase, no CÓMO se construye.

### 10.1 Fases de Entrega

**Fase 1 — MVP (meses 1-3):** Todo gratuito. Objetivo: validar product-market fit.
- Registro y autenticación completa (RF-01, RF-02)
- Perfiles de prestadores (RF-03)
- Búsqueda y filtrado (RF-04)
- Solicitudes de presupuesto con ciclo de vida completo (RF-05)
- Mensajería contextual (RF-06)
- Valoraciones y reseñas (RF-07)
- Notificaciones push + in-app (RF-08)
- Panel de administración básico (RF-09)
- Sistema de reportes (RF-10)
- Geolocalización opcional (RF-13)

**Fase 2 — Monetización (meses 4-6):**
- Suscripción Pro con trial 30 días (RF-11)
- Verificación de identidad (RF-12)
- Integración Mercado Pago (pagos de suscripción)
- Introducción de comisión 5-8% sobre trabajos completados
- Estrategia trial→paid automatizada (notificaciones días 7, 23, 28, 30, 60)

**Fase 3 — Optimización (meses 7-12):**
- Ajuste de precios según aprendizajes
- Boost individual (por encima del plan)
- Plan anual (20% de descuento)
- Evaluación de Algolia/Typesense si supera 500 prestadores
- Firebase App Check si supera 10.000 usuarios

### 10.2 Criterios de Éxito por Fase

| Fase | Métricas clave | Meta |
|---|---|---|
| Fase 1 | Prestadores registrados | 100 prestadores activos |
| Fase 1 | Volumen de solicitudes | 50 solicitudes/mes |
| Fase 1 | Tasa de conversión prestador (wizard completo) | > 60% de los que inician el wizard |
| Fase 2 | Conversión free → Pro | 5-8% (modelo visibilidad tiene dolor más tangible que modelo de features) |
| Fase 2 | Conversión trial → paid | > 10% con secuencia de notificaciones activa |
| Fase 3 | Conversión acumulada | 8-12% más comisión cubriendo costos operativos |

---

## 11. Relación con Sistemas Existentes

> **Por qué existe esta sección:** Ningún producto existe en el vacío. Documentar cómo se relaciona con sistemas existentes previene conflictos y malentendidos sobre el scope.

ChangaYa es un sistema **greenfield** — no existe integración con sistemas legacy. No hay migración de datos históricos.

Las únicas relaciones externas son:
- Google Sign-In: OAuth 2.0 manejado completamente por Firebase Authentication. No hay integración adicional.
- Mercado Pago: integración en Fase 2 via API de preapproval. Toda la integración es nueva.

---

## 12. Métricas de Éxito

> **Por qué existe esta sección:** "El proyecto fue exitoso" no es una métrica. Esta sección define EXACTAMENTE cómo se mide el éxito con números concretos.

| Métrica | Fase 1 | Fase 2 | Fase 3 |
|---|---|---|---|
| Prestadores activos | 100 | 250 | 500 |
| Solicitudes por mes | 50 | 200 | 500 |
| Tasa de conversión Pro | — | 2-3% | 3-5% |
| NPS (Net Promoter Score) | > 30 | > 40 | > 50 |
| Tiempo promedio respuesta (pending→accepted) | < 24hs | < 12hs | < 8hs |
| Tasa de cancelación | < 20% | < 15% | < 10% |
| Crash-free sessions | > 99% | > 99.5% | > 99.5% |

### Definición de "Hecho" (DoD)

> Un feature no está hecho hasta que cumple TODOS estos criterios.

```
Un feature está DONE cuando:
  ✅ Todos los tests unitarios y de integración pasan.
  ✅ La cobertura de código cumple con los umbrales definidos.
  ✅ La funcionalidad ha sido validada por un test E2E.
  ✅ La documentación relevante ha sido actualizada.
  ✅ El feature funciona en staging sin regresiones.
```

---

## 13. Preguntas Abiertas

> **Por qué existe esta sección:** Preguntas que deben resolverse antes de iniciar la implementación. Para preguntas técnicas sin resolver, ver RFC.md sección 11.

| # | Pregunta | Impacto | Estado |
|---|---|---|---|
| 1 | ¿El registro AAIP requiere contratar un profesional legal o puede hacerlo el equipo directamente? | Alto — prerrequisito de lanzamiento | Pendiente |
| 2 | ¿Cuántas categorías tendrá el catálogo inicial? ¿Se definen antes del lanzamiento o se agregan progresivamente? | Medio — impacta datos de seed y wizard de onboarding | Pendiente |
| 3 | ¿La verificación de identidad (RF-12) es gratuita en Fase 1 o se lanza directo con pago en Fase 2? | Medio — impacta flujo de monetización | Pendiente |
| 4 | ¿Se necesita landing page pública antes del lanzamiento o el perfil compartible por WhatsApp es suficiente? | Bajo — puede posponerse | Pendiente |
| 5 | ¿Cómo se manejan prestadores con múltiples roles (ej. plomero + gasista)? ¿Pueden tener un perfil por categoría o solo uno con múltiples categorías? | Bajo — el modelo actual soporta múltiples categorías en un solo perfil | Resuelto: un perfil, múltiples categorías |
