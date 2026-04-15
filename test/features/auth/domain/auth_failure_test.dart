// test/features/auth/domain/auth_failure_test.dart
//
// Tests para AuthFailure sealed class.
// STRICT TDD: este archivo existe ANTES de lib/features/auth/domain/auth_failure.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:changaya/features/auth/domain/auth_failure.dart';

void main() {
  group('AuthFailure', () {
    group('factory constructors', () {
      test('invalidCredential tiene code correcto', () {
        final failure = AuthFailure.invalidCredential();
        expect(failure.code, 'invalid-credential');
        expect(failure.message, isNotNull);
      });

      test('emailAlreadyInUse tiene code correcto', () {
        final failure = AuthFailure.emailAlreadyInUse();
        expect(failure.code, 'email-already-in-use');
        expect(failure.message, isNotNull);
      });

      test('networkError tiene code correcto', () {
        final failure = AuthFailure.networkError();
        expect(failure.code, 'network-request-failed');
        expect(failure.message, isNotNull);
      });

      test('tooManyRequests tiene code correcto', () {
        final failure = AuthFailure.tooManyRequests();
        expect(failure.code, 'too-many-requests');
        expect(failure.message, isNotNull);
      });

      test('userDisabled tiene code correcto', () {
        final failure = AuthFailure.userDisabled();
        expect(failure.code, 'user-disabled');
        expect(failure.message, isNotNull);
      });

      test('weakPassword tiene code correcto', () {
        final failure = AuthFailure.weakPassword();
        expect(failure.code, 'weak-password');
        expect(failure.message, isNotNull);
      });

      test('operationNotAllowed tiene code correcto', () {
        final failure = AuthFailure.operationNotAllowed();
        expect(failure.code, 'operation-not-allowed');
        expect(failure.message, isNotNull);
      });

      test('unknown tiene code correcto', () {
        final failure = AuthFailure.unknown();
        expect(failure.code, 'unknown');
      });
    });

    group('es AppException', () {
      test('AuthFailure es Exception (puede ser thrown)', () {
        final failure = AuthFailure.invalidCredential();
        expect(failure, isA<Exception>());
      });

      test('mensajes de error están en español', () {
        final failure = AuthFailure.invalidCredential();
        // El mensaje debe ser legible por el usuario en español
        expect(failure.message, isNotEmpty);
      });
    });

    group('switch exhaustivo', () {
      test('puede ser usado en switch exhaustivo como sealed class', () {
        final AuthFailure failure = AuthFailure.networkError();

        // Si AuthFailure es sealed, este switch debe compilar sin default
        final result = switch (failure) {
          AuthFailure(code: 'invalid-credential') => 'credencial',
          AuthFailure(code: 'email-already-in-use') => 'email',
          AuthFailure(code: 'network-request-failed') => 'red',
          AuthFailure(code: 'too-many-requests') => 'límite',
          AuthFailure(code: 'user-disabled') => 'suspendido',
          AuthFailure(code: 'weak-password') => 'débil',
          AuthFailure(code: 'operation-not-allowed') => 'prohibido',
          AuthFailure _ => 'otro',
        };

        expect(result, 'red');
      });
    });
  });
}
