// test/features/auth/presentation/forgot_password_screen_test.dart
//
// Widget tests para ForgotPasswordScreen (P-07).
// STRICT TDD: tests escritos ANTES de la implementación.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:changaya/features/auth/domain/auth_repository.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/auth/presentation/screens/forgot_password_screen.dart';

import 'forgot_password_screen_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;

  Widget buildForgotPasswordScreen() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
  }

  setUp(() {
    mockRepo = MockAuthRepository();
    when(mockRepo.authStateChanges).thenAnswer(
      (_) => const Stream.empty(),
    );
  });

  group('ForgotPasswordScreen — renders', () {
    testWidgets(
      'should_render_email_field',
      (tester) async {
        await tester.pumpWidget(buildForgotPasswordScreen());
        await tester.pump();

        expect(find.byKey(forgotPasswordEmailFieldKey), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_submit_button',
      (tester) async {
        await tester.pumpWidget(buildForgotPasswordScreen());
        await tester.pump();

        expect(find.text('Enviar instrucciones'), findsOneWidget);
      },
    );
  });

  group('ForgotPasswordScreen — validación', () {
    testWidgets(
      'should_show_error_when_email_is_empty',
      (tester) async {
        await tester.pumpWidget(buildForgotPasswordScreen());
        await tester.pump();

        await tester.tap(find.text('Enviar instrucciones'));
        await tester.pump();

        expect(find.text('Ingresá tu email'), findsOneWidget);
      },
    );

    testWidgets(
      'should_show_error_when_email_is_invalid',
      (tester) async {
        await tester.pumpWidget(buildForgotPasswordScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(forgotPasswordEmailFieldKey),
          'not-valid',
        );
        await tester.tap(find.text('Enviar instrucciones'));
        await tester.pump();

        expect(find.text('Ingresá un email válido'), findsOneWidget);
      },
    );
  });

  group('ForgotPasswordScreen — envío exitoso', () {
    testWidgets(
      'should_show_success_message_after_submit',
      (tester) async {
        when(
          mockRepo.sendPasswordResetEmail(email: anyNamed('email')),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(buildForgotPasswordScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(forgotPasswordEmailFieldKey),
          'test@example.com',
        );
        await tester.tap(find.text('Enviar instrucciones'));
        await tester.pumpAndSettle();

        // Mensaje genérico — no revela si el email existe (RF-05)
        expect(
          find.textContaining('Si el email está registrado'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should_show_same_success_message_even_when_email_not_found',
      (tester) async {
        // Incluso si el email no existe, la UI muestra el mismo mensaje genérico
        when(
          mockRepo.sendPasswordResetEmail(email: anyNamed('email')),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(buildForgotPasswordScreen());
        await tester.pump();

        await tester.enterText(
          find.byKey(forgotPasswordEmailFieldKey),
          'noexiste@example.com',
        );
        await tester.tap(find.text('Enviar instrucciones'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Si el email está registrado'),
          findsOneWidget,
        );
      },
    );
  });
}
