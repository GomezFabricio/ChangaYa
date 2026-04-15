// test/features/auth/presentation/login_screen_test.dart
//
// Widget tests para LoginScreen (P-04).
// STRICT TDD: tests escritos ANTES de la implementación.
//
// Para generar mocks: dart run build_runner build
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:changaya/features/auth/domain/auth_failure.dart';
import 'package:changaya/features/auth/domain/auth_repository.dart';
import 'package:changaya/features/auth/domain/user.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/auth/presentation/screens/login_screen.dart';

import 'login_screen_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;

  const testUser = User(
    uid: 'uid-test-001',
    email: 'test@example.com',
    emailVerified: true,
    onboardingComplete: true,
    providers: ['password'],
  );

  Widget buildLoginScreen({MockAuthRepository? repo}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo ?? mockRepo),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  setUp(() {
    mockRepo = MockAuthRepository();
    when(mockRepo.authStateChanges).thenAnswer(
      (_) => const Stream.empty(),
    );
  });

  group('LoginScreen — renders', () {
    testWidgets(
      'should_render_email_field',
      (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        expect(find.byKey(loginEmailFieldKey), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_password_field',
      (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        expect(find.byKey(loginPasswordFieldKey), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_login_button',
      (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        expect(find.text('Iniciar sesión'), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_register_link',
      (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        expect(find.text('Registrate'), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_forgot_password_link',
      (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_google_signin_button',
      (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        expect(find.text('Continuar con Google'), findsOneWidget);
      },
    );
  });

  group('LoginScreen — validaciones', () {
    testWidgets(
      'should_show_error_when_email_is_invalid',
      (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(loginEmailFieldKey),
          'not-an-email',
        );
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pump();

        expect(find.text('Ingresá un email válido'), findsOneWidget);
      },
    );

    testWidgets(
      'should_show_error_when_password_is_empty',
      (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(loginEmailFieldKey),
          'test@example.com',
        );
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pump();

        expect(find.text('Ingresá tu contraseña'), findsOneWidget);
      },
    );
  });

  group('LoginScreen — login exitoso', () {
    testWidgets(
      'should_call_signInWithEmail_when_form_is_valid',
      (tester) async {
        when(
          mockRepo.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => testUser);

        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(loginEmailFieldKey),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(loginPasswordFieldKey),
          'password123',
        );
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pump();

        verify(
          mockRepo.signInWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);
      },
    );
  });

  group('LoginScreen — error de credenciales', () {
    testWidgets(
      'should_show_snackbar_when_invalid_credential',
      (tester) async {
        when(
          mockRepo.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(AuthFailure.invalidCredential());

        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(loginEmailFieldKey),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(loginPasswordFieldKey),
          'wrongpassword',
        );
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();

        expect(
          find.text('Email o contraseña incorrectos.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_show_snackbar_when_too_many_requests',
      (tester) async {
        when(
          mockRepo.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(AuthFailure.tooManyRequests());

        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(loginEmailFieldKey),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(loginPasswordFieldKey),
          'password123',
        );
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();

        expect(
          find.text(
              'Demasiados intentos. Tu cuenta fue bloqueada temporalmente.'),
          findsOneWidget,
        );
      },
    );
  });

  group('LoginScreen — loading state', () {
    testWidgets(
      'should_show_loading_indicator_during_signin',
      (tester) async {
        when(
          mockRepo.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer(
          (_) => Future.delayed(
            const Duration(seconds: 1),
            () => testUser,
          ),
        );

        await tester.pumpWidget(buildLoginScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(loginEmailFieldKey),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(loginPasswordFieldKey),
          'password123',
        );
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();
      },
    );
  });
}
