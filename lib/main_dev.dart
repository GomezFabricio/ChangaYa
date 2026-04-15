import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:changaya/app/app.dart';
import 'package:changaya/core/constants/app_config.dart';
import 'package:changaya/firebase_options.dart';

/// Host para conectar al Firebase Emulator Suite.
///
/// El emulador de Android corre en una VM aislada; `127.0.0.1` apunta al
/// propio emulador, no al host que lo hospeda. Google reservó `10.0.2.2`
/// como alias al host. iOS simulator, Chrome y desktop corren sobre el host
/// directamente, por lo que `localhost` funciona.
String _emulatorHost() {
  if (kIsWeb) return 'localhost';
  if (Platform.isAndroid) return '10.0.2.2';
  return 'localhost';
}

/// Entry point de DESARROLLO — conecta a Firebase Emulator Suite.
///
/// Emuladores (configurados en firebase.json):
/// - Auth:      localhost:9099
/// - Firestore: localhost:8080
/// - Storage:   localhost:9199
/// - Functions: localhost:5001
///
/// Correr con: `flutter run -t lib/main_dev.dart`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Conectar emuladores — solo en entorno dev.
  // Host resuelto según plataforma (Android emulator requiere 10.0.2.2).
  final emulatorHost = _emulatorHost();
  await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
  await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
  // Functions emulator: configurar en el cliente cuando se use cloud_functions package.

  const config = AppConfig.dev;
  assert(config.isDev, 'Este entry point es solo para desarrollo.');

  runApp(
    const ProviderScope(
      child: AppRoot(),
    ),
  );
}
