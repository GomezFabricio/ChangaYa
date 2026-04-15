/// Nombres de colecciones Firestore centralizados.
///
/// Evita magic strings dispersos en el código.
/// Alineado con el schema definido en el RFC y las Cloud Functions.
abstract final class FirestoreCollections {
  /// Colección principal de usuarios: `users/{uid}`
  static const String users = 'users';

  /// Colección de suscripciones: `subscriptions/{uid}`
  static const String subscriptions = 'subscriptions';

  /// Colección de perfiles de prestadores: `providers/{uid}`
  static const String providers = 'providers';

  /// Colección de solicitudes de servicio: `service_requests/{id}`
  static const String serviceRequests = 'service_requests';

  /// Colección de reseñas: `reviews/{id}`
  static const String reviews = 'reviews';

  /// Colección de mensajes: `messages/{id}`
  static const String messages = 'messages';

  /// Colección de log de administración: `admin_log/{id}`
  static const String adminLog = 'admin_log';
}
