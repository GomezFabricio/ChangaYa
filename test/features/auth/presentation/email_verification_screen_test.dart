// test/features/auth/presentation/email_verification_screen_test.dart
//
// Widget tests para EmailVerificationScreen (P-06).
// STRICT TDD: tests escritos ANTES de la implementación.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:changaya/features/auth/domain/auth_repository.dart';
import 'package:changaya/features/auth/domain/user.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/auth/presentation/screens/email_verification_screen.dart';

import 'email_verification_screen_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;

  const unverifiedUser = User(
    uid: 'uid-unverified-001',
    email: 'test@example.com',
    emailVerified: false,
    onboardingComplete: false,
    providers: ['password'],
  );

  Widget buildEmailVerificationScreen() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(unverifiedUser),
        ),
      ],
      child: const MaterialApp(
        home: EmailVerificationScreen(),
      ),
    );
  }

  setUp(() {
    mockRepo = MockAuthRepository();
    when(mockRepo.authStateChanges).thenAnswer(
      (_) => Stream.value(unverifiedUser),
    );
  });

  group('EmailVerificationScreen — renders', () {
    testWidgets(
      'should_render_user_email',
      (tester) async {
        await tester.pumpWidget(buildEmailVerificationScreen());
        await tester.pump();

        expect(find.text('test@example.com'), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_resend_button',
      (tester) async {
        await tester.pumpWidget(buildEmailVerificationScreen());
        await tester.pump();

        expect(find.text('Reenviar email'), findsOneWidget);
      },
    );

    testWidgets(
      'should_render_already_verified_button',
      (tester) async {
        await tester.pumpWidget(buildEmailVerificationScreen());
        await tester.pump();

        expect(find.text('Ya verifiqué mi email'), findsOneWidget);
      },
    );
  });

  group('EmailVerificationScreen — reenvío', () {
    testWidgets(
      'should_call_sendEmailVerification_when_resend_tapped',
      (tester) async {
        when(mockRepo.sendEmailVerification()).thenAnswer((_) async {});

        await tester.pumpWidget(buildEmailVerificationScreen());
        await tester.pump();

        await tester.tap(find.text('Reenviar email'));
        await tester.pump();

        verify(mockRepo.sendEmailVerification()).called(1);
      },
    );

    testWidgets(
      'should_show_cooldown_after_resend',
      (tester) async {
        when(mockRepo.sendEmailVerification()).thenAnswer((_) async {});

        await tester.pumpWidget(buildEmailVerificationScreen());
        await tester.pump();

        await tester.tap(find.text('Reenviar email'));
        await tester.pump();

        // Tras reenvío el botón debe mostrar el cooldown
        expect(find.textContaining('60'), findsOneWidget);
      },
    );
  });

  group('EmailVerificationScreen — ya verificado', () {
    testWidgets(
      'should_render_button_and_not_throw_when_tapped',
      (tester) async {
        when(mockRepo.reloadUser()).thenAnswer((_) async {});
        // Tras reloadUser, el screen lee repo.currentUser para decidir si
        // navega (patrón híbrido declarativo + imperativo). Stub: user con
        // emailVerified=false, entonces no debe intentar navegar.
        when(
          mockRepo.currentUser,
        ).thenReturn(unverifiedUser);

        await tester.pumpWidget(buildEmailVerificationScreen());
        await tester.pump();

        // El botón debe estar presente
        expect(find.text('Ya verifiqué mi email'), findsOneWidget);

        // Tap no debe lanzar excepción
        await tester.tap(find.text('Ya verifiqué mi email'));
        await tester.pump();

        expect(tester.takeException(), isNull);
        verify(mockRepo.reloadUser()).called(1);
      },
    );
  });
}
