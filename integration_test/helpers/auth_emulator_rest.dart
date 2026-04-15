// integration_test/helpers/auth_emulator_rest.dart
//
// Helpers para interactuar con la REST API del Firebase Auth Emulator
// y del Firestore Emulator durante integration tests.
//
// Usa dart:io HttpClient (sin package:http — http está excluido del proyecto,
// ver lib/CLAUDE.md).
//
// Endpoints documentados en:
// - https://firebase.google.com/docs/emulator-suite/connect_auth#rest_api
// - https://firebase.google.com/docs/emulator-suite/connect_firestore#clear_database
import 'dart:convert';
import 'dart:io';

const _projectId = 'changaya-dev';
const _authHost = '127.0.0.1';
const _authPort = 9099;
const _firestoreHost = '127.0.0.1';
const _firestorePort = 8080;

/// Marca el email del usuario [uid] como verificado en el Auth Emulator.
///
/// Permite simular el click del usuario en el link del email de verificación
/// sin necesitar un email real ni un servicio de correo en el test.
Future<void> setEmailVerified(String uid) async {
  final uri = Uri.parse(
    'http://$_authHost:$_authPort/emulator/v1/projects/$_projectId/accounts/$uid',
  );
  final client = HttpClient();
  try {
    final req = await client.patchUrl(uri);
    req.headers.contentType = ContentType.json;
    req.headers.add('Authorization', 'Bearer owner');
    req.write(jsonEncode({'emailVerified': true}));
    final res = await req.close();
    if (res.statusCode != 200) {
      final body = await res.transform(utf8.decoder).join();
      throw StateError(
        'setEmailVerified failed: ${res.statusCode} $body',
      );
    }
    await res.drain<void>();
  } finally {
    client.close();
  }
}

/// Borra todos los usuarios del Auth Emulator.
///
/// Llamar en `setUp` para garantizar aislamiento entre tests.
Future<void> clearAuthEmulator() async {
  final uri = Uri.parse(
    'http://$_authHost:$_authPort/emulator/v1/projects/$_projectId/accounts',
  );
  final client = HttpClient();
  try {
    final req = await client.deleteUrl(uri);
    req.headers.add('Authorization', 'Bearer owner');
    final res = await req.close();
    if (res.statusCode != 200) {
      final body = await res.transform(utf8.decoder).join();
      throw StateError(
        'clearAuthEmulator failed: ${res.statusCode} $body',
      );
    }
    await res.drain<void>();
  } finally {
    client.close();
  }
}

/// Borra todos los documentos del Firestore Emulator.
///
/// Llamar en `setUp` para garantizar aislamiento entre tests.
Future<void> clearFirestoreEmulator() async {
  final uri = Uri.parse(
    'http://$_firestoreHost:$_firestorePort/emulator/v1/projects/$_projectId/databases/(default)/documents',
  );
  final client = HttpClient();
  try {
    final req = await client.deleteUrl(uri);
    final res = await req.close();
    if (res.statusCode != 200) {
      final body = await res.transform(utf8.decoder).join();
      throw StateError(
        'clearFirestoreEmulator failed: ${res.statusCode} $body',
      );
    }
    await res.drain<void>();
  } finally {
    client.close();
  }
}
