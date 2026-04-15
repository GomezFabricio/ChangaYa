import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changaya/app/app.dart';
import 'package:changaya/core/constants/app_config.dart';
import 'package:changaya/firebase_options.dart';

/// Entry point de PRODUCCIÓN — conecta a Firebase changaya-prod.
///
/// NO conecta emuladores.
///
/// Correr con: `flutter run -t lib/main_prod.dart`
/// Build con:  `flutter build apk --release`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const config = AppConfig.prod;
  assert(config.isProd, 'Este entry point es solo para producción.');

  runApp(
    const ProviderScope(
      child: AppRoot(),
    ),
  );
}
