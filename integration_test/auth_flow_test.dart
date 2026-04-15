// integration_test/auth_flow_test.dart
//
// Tests de integración del flujo completo de auth + onboarding.
//
// REQUISITOS — antes de correr:
//   1. Firebase Emulator Suite levantado:
//      firebase emulators:start --only auth,firestore,storage,functions
//   2. Un device target disponible (emulador Android, iOS o Chrome).
//
// Correr con:
//   flutter test integration_test/auth_flow_test.dart -d emulator-5554
//
// O contra Chrome (más rápido para iterar):
//   flutter test integration_test/auth_flow_test.dart -d chrome
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:changaya/features/auth/presentation/screens/register_screen.dart';
import 'package:changaya/features/profile/presentation/screens/complete_profile_screen.dart';
import 'package:changaya/main_dev.dart' as app;

import 'helpers/auth_emulator_rest.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow — integración completa', () {
    setUp(() async {
      // Aislamiento entre tests: limpiar Auth y Firestore antes de cada uno.
      await clearAuthEmulator();
      await clearFirestoreEmulator();
    });

    testWidgets(
      'should_register_user_then_verify_email_then_complete_profile',
      (tester) async {
        // Datos del test — email único por corrida para evitar colisiones
        // (aunque setUp limpia, ayuda en debug si algo queda colgado).
        final email =
            'test_${DateTime.now().millisecondsSinceEpoch}@changaya.test';
        const password = 'Test1234';
        const name = 'Juan Pérez';
        const phone = '03624 123456';
        const localidad = 'Formosa Capital';

        // 1. Levantar la app — main_dev conecta a emuladores automáticamente.
        app.main();
        await tester.pumpAndSettle();

        // Estamos en /login. Tap "Registrate" (pero el LoginScreen no tiene key
        // en el botón, así que usamos text finder).
        // Buscamos un botón cuyo texto sea "Registrate" o navegación equivalente.
        // Si LoginScreen no expone un botón directo, navegamos por GoRouter.
        // Para mantener el test robusto: vamos por finders de texto.
        final goToRegisterFinder = find.text('Registrate');
        expect(
          goToRegisterFinder,
          findsOneWidget,
          reason: 'LoginScreen debería ofrecer un link/botón "Registrate"',
        );
        await tester.tap(goToRegisterFinder);
        await tester.pumpAndSettle();

        // 2. Llenar form de registro.
        await tester.enterText(find.byKey(registerNameFieldKey), name);
        await tester.enterText(find.byKey(registerEmailFieldKey), email);
        await tester.enterText(find.byKey(registerPasswordFieldKey), password);
        await tester.enterText(
          find.byKey(registerConfirmPasswordFieldKey),
          password,
        );

        // Aceptar términos (Checkbox).
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // Submit.
        await tester.tap(find.byKey(registerSubmitButtonKey));
        // Esperar a que el repo registre + GoRouter redirija a /verify-email.
        // pumpAndSettle puede colgar con streams permanentes — usamos pump loops.
        await _pumpUntil(
          tester,
          () => find.text('Verificá tu email').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 10),
          reason: 'Tras registro debería navegar a /verify-email',
        );

        // 3. Simular verificación de email vía REST API del Auth Emulator.
        final uid = FirebaseAuth.instance.currentUser?.uid;
        expect(uid, isNotNull, reason: 'El usuario debería estar autenticado');
        await setEmailVerified(uid!);

        // 4. Tap "Ya verifiqué mi email" → reload + redirect a /complete-profile.
        await tester.tap(find.text('Ya verifiqué mi email'));
        await _pumpUntil(
          tester,
          () => find.text('Completá tu perfil').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 10),
          reason: 'Tras verificar email debería navegar a /complete-profile',
        );

        // 5. Llenar form de onboarding.
        await tester.enterText(
          find.byKey(completeProfilePhoneFieldKey),
          phone,
        );

        // Localidad — DropdownButtonFormField sin key. Tap para abrirlo,
        // tap en el item.
        await tester.tap(find.text('Seleccioná tu localidad'));
        await tester.pumpAndSettle();
        // El dropdown abierto muestra los items duplicados (uno en el menú,
        // uno colapsado). Tomamos el último que aparece.
        await tester.tap(find.text(localidad).last);
        await tester.pumpAndSettle();

        // 6. Tap "Guardar perfil" → onboarding complete → redirect a /home.
        await tester.tap(find.text('Guardar perfil'));
        await _pumpUntil(
          tester,
          () => find.text('Home — próximamente').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 10),
          reason: 'Tras guardar perfil debería navegar a /home',
        );

        // 7. Assert final.
        expect(find.text('Home — próximamente'), findsOneWidget);
      },
    );

    // Los siguientes tests siguen pendientes — se implementarán en
    // iteraciones posteriores una vez validado el flow #1.
    // TODO: implementar después de validar flow #1
    testWidgets(
      'should_login_with_existing_verified_account',
      (tester) async {},
      skip: true,
    );

    // TODO: implementar después de validar flow #1
    testWidgets(
      'should_reset_password_and_show_generic_message',
      (tester) async {},
      skip: true,
    );
  });
}

/// Bombea frames hasta que [condition] sea true o se exceda el [timeout].
///
/// Reemplazo de `pumpAndSettle` cuando hay streams permanentes (como
/// authStateChanges) que impiden que el widget tree quede idle.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  String? reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  fail(
    'Timeout de _pumpUntil tras $timeout${reason != null ? ': $reason' : ''}',
  );
}
