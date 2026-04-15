import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changaya/app/app.dart';
import 'package:changaya/core/constants/app_config.dart';
import 'package:changaya/firebase_options.dart';

/// Entry point de STAGING — conecta a Firebase real (proyecto `changaya-dev`).
///
/// Staging usa el mismo proyecto Firebase que dev (`changaya-dev`) pero
/// **sin override a emuladores**. Esto permite validar contra backend real
/// antes de promover a producción:
/// - Google Sign-In funciona end-to-end (sin restricciones del emulator).
/// - Emails de verificación llegan a inbox real.
/// - Firestore listeners estables (sin flakiness del emulator Android).
/// - Comportamiento idéntico al que van a tener los usuarios reales en prod.
///
/// Cuando se cree `changaya-prod` se va a usar un proyecto separado. Hasta
/// entonces, staging comparte infra con dev — sin conflicto porque dev usa
/// emuladores locales y staging usa la nube real del mismo proyecto.
///
/// Correr con: `flutter run -t lib/main_staging.dart`
/// Build con:  `flutter build apk --release -t lib/main_staging.dart`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // NO hay useAuthEmulator / useFirestoreEmulator / useStorageEmulator.
  // Firebase apunta a los servidores reales del proyecto `changaya-dev`.

  const config = AppConfig.staging;
  assert(config.isStaging, 'Este entry point es solo para staging.');

  runApp(
    const ProviderScope(
      child: AppRoot(),
    ),
  );
}
