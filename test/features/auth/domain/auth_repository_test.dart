// test/features/auth/domain/auth_repository_test.dart
//
// Tests del contrato AuthRepository usando un mock de Mockito.
// STRICT TDD: verifica que la interface tiene los métodos esperados
// con las firmas correctas.
//
// Para generar mocks: dart run build_runner build
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:changaya/features/auth/domain/auth_repository.dart';
import 'package:changaya/features/auth/domain/user.dart';
import 'package:changaya/features/auth/domain/auth_failure.dart';

import 'auth_repository_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('AuthRepository contract tests', () {
    const testUser = User(
      uid: 'uid-test',
      email: 'test@example.com',
      emailVerified: false,
      onboardingComplete: false,
      providers: ['password'],
    );

    group('signInWithEmail', () {
      test('retorna User en éxito', () async {
        when(
          mockAuthRepository.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => testUser);

        final result = await mockAuthRepository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isA<User>());
        expect(result.uid, 'uid-test');
      });

      test('lanza AuthFailure en credencial inválida', () async {
        when(
          mockAuthRepository.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(AuthFailure.invalidCredential());

        expect(
          () => mockAuthRepository.signInWithEmail(
            email: 'test@example.com',
            password: 'wrong',
          ),
          throwsA(isA<AuthFailure>()),
        );
      });
    });

    group('signInWithGoogle', () {
      test('retorna User en éxito', () async {
        when(mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async => testUser);

        final result = await mockAuthRepository.signInWithGoogle();

        expect(result, isA<User>());
      });
    });

    group('registerWithEmail', () {
      test('retorna User al registrar nuevo usuario', () async {
        when(
          mockAuthRepository.registerWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => testUser);

        final result = await mockAuthRepository.registerWithEmail(
          email: 'new@example.com',
          password: 'pass123',
        );

        expect(result, isA<User>());
      });
    });

    group('authStateChanges', () {
      test('retorna Stream<User?>', () {
        when(mockAuthRepository.authStateChanges)
            .thenAnswer((_) => Stream.value(testUser));

        final stream = mockAuthRepository.authStateChanges;

        expect(stream, isA<Stream<User?>>());
      });
    });

    group('sendPasswordResetEmail', () {
      test('completa sin error para email válido', () async {
        when(
          mockAuthRepository.sendPasswordResetEmail(
            email: anyNamed('email'),
          ),
        ).thenAnswer((_) async {});

        await expectLater(
          mockAuthRepository.sendPasswordResetEmail(email: 'test@example.com'),
          completes,
        );
      });
    });

    group('sendEmailVerification', () {
      test('completa sin error', () async {
        when(mockAuthRepository.sendEmailVerification())
            .thenAnswer((_) async {});

        await expectLater(
          mockAuthRepository.sendEmailVerification(),
          completes,
        );
      });
    });

    group('signOut', () {
      test('completa sin error', () async {
        when(mockAuthRepository.signOut()).thenAnswer((_) async {});

        await expectLater(mockAuthRepository.signOut(), completes);
      });
    });

    group('currentUser', () {
      test('retorna User? (puede ser null)', () {
        when(mockAuthRepository.currentUser).thenReturn(null);

        expect(mockAuthRepository.currentUser, isNull);
      });

      test('retorna User cuando hay sesión activa', () {
        when(mockAuthRepository.currentUser).thenReturn(testUser);

        expect(mockAuthRepository.currentUser, isA<User>());
      });
    });
  });
}
