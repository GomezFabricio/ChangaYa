/// Configuración del entorno de ejecución de la app.
///
/// Gestiona el ambiente activo (dev o prod) para configurar Firebase,
/// URLs y comportamiento diferenciado por entorno.
enum AppConfig {
  /// Entorno de desarrollo — usa Firebase Emulator Suite.
  dev,

  /// Entorno de producción — usa Firebase changaya-prod.
  prod;

  /// Retorna true si el entorno actual es desarrollo.
  bool get isDev => this == AppConfig.dev;

  /// Retorna true si el entorno actual es producción.
  bool get isProd => this == AppConfig.prod;
}
