// test/features/profile/presentation/complete_profile_screen_test.dart
//
// Widget tests para CompleteProfileScreen (P-08).
// STRICT TDD: tests escritos ANTES de la implementación.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:changaya/features/auth/domain/user.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/profile/domain/profile_repository.dart';
import 'package:changaya/features/profile/presentation/providers/profile_providers.dart';
import 'package:changaya/features/profile/presentation/screens/complete_profile_screen.dart';

import 'complete_profile_screen_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  late MockProfileRepository mockProfileRepo;

  const authenticatedUser = User(
    uid: 'uid-profile-001',
    email: 'test@example.com',
    emailVerified: true,
    onboardingComplete: false,
    providers: ['password'],
    displayName: 'Juan Pérez',
  );

  Widget buildCompleteProfileScreen() {
    // Router mínimo para que `context.go('/home')` tras guardado funcione
    // en los tests. Las rutas son stubs — no validamos navegación acá.
    final router = GoRouter(
      initialLocation: '/complete-profile',
      routes: [
        GoRoute(
          path: '/complete-profile',
          builder: (context, state) => const CompleteProfileScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('home-stub'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(authenticatedUser),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  setUp(() {
    mockProfileRepo = MockProfileRepository();
  });

  group('CompleteProfileScreen — renders', () {
    testWidgets(
      'should_render_phone_field',
      (tester) async {
        await tester.pumpWidget(buildCompleteProfileScreen());
        await tester.pump();

        expect(find.byKey(completeProfilePhoneFieldKey), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_localidad_dropdown',
      (tester) async {
        await tester.pumpWidget(buildCompleteProfileScreen());
        await tester.pump();

        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_save_button',
      (tester) async {
        await tester.pumpWidget(buildCompleteProfileScreen());
        await tester.pump();

        expect(find.text('Guardar perfil'), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_photo_option',
      (tester) async {
        await tester.pumpWidget(buildCompleteProfileScreen());
        await tester.pump();

        expect(find.text('Foto de perfil'), findsOneWidget);
      },
    );
  });

  group('CompleteProfileScreen — validaciones', () {
    testWidgets(
      'should_show_error_when_phone_is_empty',
      (tester) async {
        await tester.pumpWidget(buildCompleteProfileScreen());
        await tester.pump();

        await tester.tap(find.text('Guardar perfil'));
        await tester.pump();

        expect(find.text('Ingresá tu teléfono'), findsOneWidget);
      },
    );

    testWidgets(
      'should_show_error_when_phone_has_invalid_length',
      (tester) async {
        await tester.pumpWidget(buildCompleteProfileScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(completeProfilePhoneFieldKey),
          '12345',
        );
        await tester.tap(find.text('Guardar perfil'));
        await tester.pump();

        expect(
          find.text('El teléfono debe tener 10 u 11 dígitos'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_show_error_when_localidad_not_selected',
      (tester) async {
        await tester.pumpWidget(buildCompleteProfileScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(completeProfilePhoneFieldKey),
          '03624123456',
        );
        await tester.tap(find.text('Guardar perfil'));
        await tester.pump();

        expect(find.text('Seleccioná tu localidad'), findsWidgets);
      },
    );
  });

  group('CompleteProfileScreen — guardado exitoso', () {
    testWidgets(
      'should_call_updateProfile_when_form_is_valid',
      (tester) async {
        when(
          mockProfileRepo.updateProfile(any),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(buildCompleteProfileScreen());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(completeProfilePhoneFieldKey),
          '03624123456',
        );

        // Open dropdown and select localidad
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        // Select Formosa Capital from dropdown list
        final formosaCapitalInList = find.text('Formosa Capital').last;
        await tester.tap(formosaCapitalInList);
        await tester.pumpAndSettle();

        // Tap save button
        await tester.ensureVisible(find.text('Guardar perfil'));
        await tester.tap(find.text('Guardar perfil'));
        await tester.pumpAndSettle();

        // If updateProfile was called, test passes
        // Note: this test verifies the integration between screen and notifier
        // If mock wasn't called, it means the form/state didn't submit correctly
        // which is a screen integration issue to investigate in CI
        verifyNever(mockProfileRepo.watchProfile(any));
        verify(mockProfileRepo.updateProfile(any)).called(greaterThan(0));
      },
    );
  });
}
