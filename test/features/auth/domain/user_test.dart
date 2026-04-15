// test/features/auth/domain/user_test.dart
//
// Tests para la entidad User del dominio de auth.
// STRICT TDD: este archivo existe ANTES de lib/features/auth/domain/user.dart
//
// Escenarios cubiertos:
// - Creación con campos requeridos
// - copyWith retorna nueva instancia con campos actualizados
// - Igualdad por uid
// - Getter isOnboarded (alias de onboardingComplete)
// - Getter hasGoogleProvider
import 'package:flutter_test/flutter_test.dart';
import 'package:changaya/features/auth/domain/user.dart';

void main() {
  group('User entity', () {
    const baseUser = User(
      uid: 'uid-001',
      email: 'test@example.com',
      emailVerified: false,
      onboardingComplete: false,
      providers: [],
    );

    group('creación', () {
      test('crea instancia con campos requeridos', () {
        const user = User(
          uid: 'uid-001',
          email: 'test@example.com',
          emailVerified: false,
          onboardingComplete: false,
          providers: [],
        );

        expect(user.uid, 'uid-001');
        expect(user.email, 'test@example.com');
        expect(user.emailVerified, false);
        expect(user.onboardingComplete, false);
        expect(user.providers, isEmpty);
      });

      test('crea instancia con campos opcionales nulos', () {
        const user = User(
          uid: 'uid-002',
          email: 'other@example.com',
          emailVerified: true,
          onboardingComplete: true,
          providers: ['google.com'],
          displayName: null,
          photoURL: null,
        );

        expect(user.displayName, isNull);
        expect(user.photoURL, isNull);
      });

      test('crea instancia con displayName y photoURL', () {
        const user = User(
          uid: 'uid-003',
          email: 'full@example.com',
          emailVerified: true,
          onboardingComplete: false,
          providers: ['google.com'],
          displayName: 'Full Name',
          photoURL: 'https://photo.url',
        );

        expect(user.displayName, 'Full Name');
        expect(user.photoURL, 'https://photo.url');
      });
    });

    group('copyWith', () {
      test('retorna nueva instancia con emailVerified actualizado', () {
        final updated = baseUser.copyWith(emailVerified: true);

        expect(updated.emailVerified, true);
        expect(updated.uid, baseUser.uid);
        expect(updated.email, baseUser.email);
        expect(updated.onboardingComplete, baseUser.onboardingComplete);
      });

      test('retorna nueva instancia con onboardingComplete actualizado', () {
        final updated = baseUser.copyWith(onboardingComplete: true);

        expect(updated.onboardingComplete, true);
        expect(updated.uid, baseUser.uid);
      });

      test('retorna nueva instancia con displayName actualizado', () {
        final updated = baseUser.copyWith(displayName: 'Nuevo Nombre');

        expect(updated.displayName, 'Nuevo Nombre');
        expect(updated.uid, baseUser.uid);
      });

      test('la instancia original no muta', () {
        baseUser.copyWith(emailVerified: true, onboardingComplete: true);

        expect(baseUser.emailVerified, false);
        expect(baseUser.onboardingComplete, false);
      });

      test('copyWith sin argumentos retorna instancia con mismos valores', () {
        final copy = baseUser.copyWith();

        expect(copy, equals(baseUser));
      });
    });

    group('igualdad', () {
      test('dos User con mismo uid son iguales', () {
        const user1 = User(
          uid: 'uid-001',
          email: 'a@example.com',
          emailVerified: false,
          onboardingComplete: false,
          providers: [],
        );
        const user2 = User(
          uid: 'uid-001',
          email: 'b@example.com', // email distinto
          emailVerified: true,
          onboardingComplete: true,
          providers: ['google.com'],
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('dos User con uid distinto no son iguales', () {
        const user1 = User(
          uid: 'uid-001',
          email: 'test@example.com',
          emailVerified: false,
          onboardingComplete: false,
          providers: [],
        );
        const user2 = User(
          uid: 'uid-002',
          email: 'test@example.com',
          emailVerified: false,
          onboardingComplete: false,
          providers: [],
        );

        expect(user1, isNot(equals(user2)));
      });
    });

    group('getters', () {
      test('isOnboarded retorna true cuando onboardingComplete es true', () {
        const user = User(
          uid: 'uid-001',
          email: 'test@example.com',
          emailVerified: false,
          onboardingComplete: true,
          providers: [],
        );

        expect(user.isOnboarded, true);
      });

      test('isOnboarded retorna false cuando onboardingComplete es false', () {
        expect(baseUser.isOnboarded, false);
      });

      test('hasGoogleProvider retorna true para usuario con google.com', () {
        const googleUser = User(
          uid: 'uid-001',
          email: 'g@example.com',
          emailVerified: true,
          onboardingComplete: false,
          providers: ['google.com'],
        );

        expect(googleUser.hasGoogleProvider, true);
      });

      test('hasGoogleProvider retorna false para usuario email/password', () {
        const emailUser = User(
          uid: 'uid-001',
          email: 'e@example.com',
          emailVerified: false,
          onboardingComplete: false,
          providers: ['password'],
        );

        expect(emailUser.hasGoogleProvider, false);
      });

      test('hasGoogleProvider retorna false para providers vacío', () {
        expect(baseUser.hasGoogleProvider, false);
      });
    });
  });
}
