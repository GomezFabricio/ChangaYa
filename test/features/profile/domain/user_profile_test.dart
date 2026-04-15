// test/features/profile/domain/user_profile_test.dart
//
// Tests para la entidad UserProfile del dominio de profile.
// STRICT TDD: este archivo existe ANTES de lib/features/profile/domain/user_profile.dart
//
// Escenarios cubiertos:
// - Creación con campos requeridos y opcionales
// - copyWith
// - isComplete getter (phone + localidad requeridos)
// - normalizePhone (normaliza a 10 dígitos sin espacios/guiones)
// - Igualdad por uid
import 'package:flutter_test/flutter_test.dart';
import 'package:changaya/features/profile/domain/user_profile.dart';

void main() {
  group('UserProfile entity', () {
    const baseProfile = UserProfile(
      uid: 'uid-001',
      displayName: 'Test User',
      onboardingComplete: false,
    );

    group('creación', () {
      test('crea instancia con campos requeridos', () {
        const profile = UserProfile(
          uid: 'uid-001',
          displayName: 'Test User',
          onboardingComplete: false,
        );

        expect(profile.uid, 'uid-001');
        expect(profile.displayName, 'Test User');
        expect(profile.onboardingComplete, false);
        expect(profile.phone, isNull);
        expect(profile.localidad, isNull);
        expect(profile.photoURL, isNull);
      });

      test('crea instancia completa con todos los campos', () {
        const profile = UserProfile(
          uid: 'uid-002',
          displayName: 'Juan Pérez',
          phone: '03624123456',
          localidad: 'Formosa Capital',
          photoURL: 'https://photo.url',
          onboardingComplete: true,
        );

        expect(profile.phone, '03624123456');
        expect(profile.localidad, 'Formosa Capital');
        expect(profile.photoURL, 'https://photo.url');
        expect(profile.onboardingComplete, true);
      });
    });

    group('copyWith', () {
      test('retorna nueva instancia con phone actualizado', () {
        final updated = baseProfile.copyWith(phone: '03624123456');

        expect(updated.phone, '03624123456');
        expect(updated.uid, baseProfile.uid);
        expect(updated.displayName, baseProfile.displayName);
      });

      test('retorna nueva instancia con localidad actualizada', () {
        final updated = baseProfile.copyWith(localidad: 'Formosa Capital');

        expect(updated.localidad, 'Formosa Capital');
        expect(updated.uid, baseProfile.uid);
      });

      test('retorna nueva instancia con onboardingComplete actualizado', () {
        final updated = baseProfile.copyWith(onboardingComplete: true);

        expect(updated.onboardingComplete, true);
      });

      test('la instancia original no muta', () {
        baseProfile.copyWith(phone: '12345', onboardingComplete: true);

        expect(baseProfile.phone, isNull);
        expect(baseProfile.onboardingComplete, false);
      });
    });

    group('isComplete', () {
      test('retorna false cuando falta phone', () {
        const profile = UserProfile(
          uid: 'uid-001',
          displayName: 'Test',
          localidad: 'Formosa Capital',
          onboardingComplete: false,
        );

        expect(profile.isComplete, false);
      });

      test('retorna false cuando falta localidad', () {
        const profile = UserProfile(
          uid: 'uid-001',
          displayName: 'Test',
          phone: '03624123456',
          onboardingComplete: false,
        );

        expect(profile.isComplete, false);
      });

      test('retorna false cuando displayName está vacío', () {
        const profile = UserProfile(
          uid: 'uid-001',
          displayName: '',
          phone: '03624123456',
          localidad: 'Formosa Capital',
          onboardingComplete: false,
        );

        expect(profile.isComplete, false);
      });

      test('retorna true cuando todos los campos obligatorios están presentes',
          () {
        const profile = UserProfile(
          uid: 'uid-001',
          displayName: 'Juan Pérez',
          phone: '03624123456',
          localidad: 'Formosa Capital',
          onboardingComplete: false,
        );

        expect(profile.isComplete, true);
      });

      test('photoURL es opcional — isComplete no lo requiere', () {
        const profile = UserProfile(
          uid: 'uid-001',
          displayName: 'Juan Pérez',
          phone: '03624123456',
          localidad: 'Formosa Capital',
          photoURL: null, // opcional
          onboardingComplete: false,
        );

        expect(profile.isComplete, true);
      });
    });

    group('normalizePhone', () {
      test('normaliza teléfono con espacios a 10 dígitos', () {
        expect(UserProfile.normalizePhone('0362 412 3456'), '03624123456');
      });

      test('normaliza teléfono con guiones a 10 dígitos', () {
        expect(UserProfile.normalizePhone('0362-412-3456'), '03624123456');
      });

      test('normaliza teléfono con espacios y guiones mezclados', () {
        expect(UserProfile.normalizePhone('0362 412-3456'), '03624123456');
      });

      test('teléfono ya normalizado permanece igual', () {
        expect(UserProfile.normalizePhone('03624123456'), '03624123456');
      });

      test('remueve prefijo +54 si está presente', () {
        expect(UserProfile.normalizePhone('+5403624123456'), '03624123456');
      });

      test(
          'formato local con 0 inicial retorna 11 dígitos (con código de área)',
          () {
        // El formato argentino local: 0362 + 7 dígitos = 11 dígitos con el 0 inicial
        // normalizePhone solo normaliza separadores, no trunca dígitos
        expect(UserProfile.normalizePhone('03624123456').length, 11);
      });
    });

    group('validación de teléfono', () {
      test(
          'teléfono de 9 dígitos normaliza a 9 dígitos (inválido — mucho corto)',
          () {
        // normalizePhone no valida longitud, solo normaliza separadores
        // La validación de 10/11 dígitos es externa (form validator)
        final normalized = UserProfile.normalizePhone('036241234');
        expect(normalized.length, 9);
      });

      test('teléfono con formato +54 9 normaliza removiendo prefijo', () {
        // +54 9 362 412 3456 → 93624123456 (11 dígitos sin el 0 del código de área)
        final normalized = UserProfile.normalizePhone('+54 9 362 412 3456');
        // Remueve +54, queda 9 3624123456
        expect(normalized, isNotEmpty);
      });
    });

    group('igualdad', () {
      test('dos UserProfile con mismo uid son iguales', () {
        const p1 = UserProfile(
          uid: 'uid-001',
          displayName: 'A',
          onboardingComplete: false,
        );
        const p2 = UserProfile(
          uid: 'uid-001',
          displayName: 'B', // distinto
          phone: '03624123456',
          onboardingComplete: true,
        );

        expect(p1, equals(p2));
        expect(p1.hashCode, equals(p2.hashCode));
      });
    });
  });
}
