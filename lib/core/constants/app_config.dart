/// Configuración del entorno de ejecución de la app.
///
/// Gestiona el ambiente activo (dev, staging o prod) para configurar Firebase,
/// URLs y comportamiento diferenciado por entorno.
enum AppConfig {
  /// Entorno de desarrollo — usa Firebase Emulator Suite (localhost).
  ///
  /// Conecta a `changaya-dev` pero override con `useAuthEmulator` /
  /// `useFirestoreEmulator` / `useStorageEmulator` para que todo el tráfico
  /// quede local. Testing rápido sin costos ni datos en la nube.
  dev,

  /// Entorno de staging — usa Firebase real del proyecto `changaya-dev`.
  ///
  /// Backend real (sin emuladores). Sirve para validación previa a prod:
  /// Google Sign-In real, emails de verificación reales, listeners estables.
  /// Comparte el proyecto Firebase con dev pero sin override a emuladores.
  staging,

  /// Entorno de producción — usa Firebase del proyecto `changaya-prod`.
  ///
  /// (pendiente de crear — cuando esté, requiere `firebase_options_prod.dart`
  /// generado con `flutterfire configure --project=changaya-prod`).
  prod;

  /// Retorna true si el entorno actual es desarrollo.
  bool get isDev => this == AppConfig.dev;

  /// Retorna true si el entorno actual es staging.
  bool get isStaging => this == AppConfig.staging;

  /// Retorna true si el entorno actual es producción.
  bool get isProd => this == AppConfig.prod;
}
