// test/features/auth/presentation/register_screen_test.dart
//
// Widget tests para RegisterScreen (P-05).
// STRICT TDD: tests escritos ANTES de la implementación.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:changaya/features/auth/domain/auth_failure.dart';
import 'package:changaya/features/auth/domain/auth_repository.dart';
import 'package:changaya/features/auth/domain/user.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/auth/presentation/screens/register_screen.dart';

import 'register_screen_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;

  const testUser = User(
    uid: 'uid-register-001',
    email: 'nuevo@example.com',
    emailVerified: false,
    onboardingComplete: false,
    providers: ['password'],
  );

  Widget buildRegisterScreen() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: RegisterScreen(),
      ),
    );
  }

  setUp(() {
    mockRepo = MockAuthRepository();
    when(mockRepo.authStateChanges).thenAnswer(
      (_) => const Stream.empty(),
    );
  });

  group('RegisterScreen — renders', () {
    testWidgets(
      'should_render_name_field',
      (tester) async {
        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        expect(find.byKey(registerNameFieldKey), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_email_field',
      (tester) async {
        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        expect(find.byKey(registerEmailFieldKey), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_password_field',
      (tester) async {
        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        expect(find.byKey(registerPasswordFieldKey), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_terms_checkbox',
      (tester) async {
        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        expect(find.byType(Checkbox), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_register_button',
      (tester) async {
        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        expect(find.byKey(registerSubmitButtonKey), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_google_signup_button',
      (tester) async {
        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        expect(find.text('Registrarse con Google'), findsOneWidget);
      },
    );
  });

  group('RegisterScreen — validaciones', () {
    testWidgets(
      'should_show_error_when_name_is_empty',
      (tester) async {
        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        await tester.tap(find.byKey(registerSubmitButtonKey));
        await tester.pump();

        expect(find.text('Ingresá tu nombre'), findsOneWidget);
      },
    );

    testWidgets(
      'should_show_error_when_email_is_invalid',
      (tester) async {
        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(registerNameFieldKey),
          'Juan Pérez',
        );
        await tester.enterText(
          find.byKey(registerEmailFieldKey),
          'not-an-email',
        );
        await tester.tap(find.byKey(registerSubmitButtonKey));
        await tester.pump();

        expect(find.text('Ingresá un email válido'), findsOneWidget);
      },
    );

    testWidgets(
      'should_show_error_when_password_too_short',
      (tester) async {
        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(registerNameFieldKey),
          'Juan Pérez',
        );
        await tester.enterText(
          find.byKey(registerEmailFieldKey),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(registerPasswordFieldKey),
          '123',
        );
        await tester.tap(find.byKey(registerSubmitButtonKey));
        await tester.pump();

        expect(
          find.text(
            'La contraseña debe tener al menos 8 caracteres, una mayúscula y un número',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_show_error_when_terms_not_accepted',
      (tester) async {
        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(registerNameFieldKey),
          'Juan Pérez',
        );
        await tester.enterText(
          find.byKey(registerEmailFieldKey),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(registerPasswordFieldKey),
          'Password1',
        );
        await tester.enterText(
          find.byKey(registerConfirmPasswordFieldKey),
          'Password1',
        );
        await tester.tap(find.byKey(registerSubmitButtonKey));
        await tester.pump();

        expect(
          find.text('Debés aceptar los términos'),
          findsOneWidget,
        );
      },
    );
  });

  group('RegisterScreen — registro exitoso', () {
    testWidgets(
      'should_call_registerWithEmail_when_form_valid_and_terms_accepted',
      (tester) async {
        when(
          mockRepo.registerWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
            name: anyNamed('name'),
          ),
        ).thenAnswer((_) async => testUser);
        when(mockRepo.signOut()).thenAnswer((_) async {});

        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(registerNameFieldKey),
          'Juan Pérez',
        );
        await tester.enterText(
          find.byKey(registerEmailFieldKey),
          'nuevo@example.com',
        );
        await tester.enterText(
          find.byKey(registerPasswordFieldKey),
          'Password1',
        );
        await tester.enterText(
          find.byKey(registerConfirmPasswordFieldKey),
          'Password1',
        );

        // Accept terms
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(find.byKey(registerSubmitButtonKey));
        await tester.pump();

        verify(
          mockRepo.registerWithEmail(
            email: 'nuevo@example.com',
            password: 'Password1',
            name: 'Juan Pérez',
          ),
        ).called(1);
      },
    );
  });

  group('RegisterScreen — errores de registro', () {
    testWidgets(
      'should_show_snackbar_when_email_already_in_use',
      (tester) async {
        when(
          mockRepo.registerWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
            name: anyNamed('name'),
          ),
        ).thenThrow(AuthFailure.emailAlreadyInUse());

        await tester.pumpWidget(buildRegisterScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(registerNameFieldKey),
          'Juan Pérez',
        );
        await tester.enterText(
          find.byKey(registerEmailFieldKey),
          'existente@example.com',
        );
        await tester.enterText(
          find.byKey(registerPasswordFieldKey),
          'Password1',
        );
        await tester.enterText(
          find.byKey(registerConfirmPasswordFieldKey),
          'Password1',
        );

        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(find.byKey(registerSubmitButtonKey));
        await tester.pumpAndSettle();

        expect(
          find.text('Ya existe una cuenta con este email.'),
          findsOneWidget,
        );
      },
    );
  });
}
