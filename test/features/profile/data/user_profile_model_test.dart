import 'package:flutter_test/flutter_test.dart';
import 'package:changaya/features/profile/data/user_profile_model.dart';
import 'package:changaya/features/profile/domain/user_profile.dart';

void main() {
  group('UserProfileModel', () {
    const uid = 'uid-abc';

    // Mapa completo simulando un documento Firestore
    final fullFirestoreMap = <String, dynamic>{
      'uid': uid,
      'displayName': 'Juan Pérez',
      'phone': '3624123456',
      'locality': 'Formosa Capital',
      'photoURL': 'https://storage.example.com/photo.jpg',
      'onboardingComplete': true,
    };

    // Mapa minimal — campos opcionales null
    final minimalFirestoreMap = <String, dynamic>{
      'uid': uid,
      'displayName': 'Sin Nombre',
      'onboardingComplete': false,
    };

    group('fromFirestore()', () {
      test('mapea todos los campos correctamente con datos completos', () {
        final model = UserProfileModel.fromFirestore(fullFirestoreMap, uid);

        expect(model.uid, equals(uid));
        expect(model.displayName, equals('Juan Pérez'));
        expect(model.phone, equals('3624123456'));
        expect(model.localidad, equals('Formosa Capital'));
        expect(model.photoURL, equals('https://storage.example.com/photo.jpg'));
        expect(model.onboardingComplete, isTrue);
      });

      test('campos opcionales son null cuando ausentes en el mapa', () {
        final model = UserProfileModel.fromFirestore(minimalFirestoreMap, uid);

        expect(model.uid, equals(uid));
        expect(model.displayName, equals('Sin Nombre'));
        expect(model.phone, isNull);
        expect(model.localidad, isNull);
        expect(model.photoURL, isNull);
        expect(model.onboardingComplete, isFalse);
      });

      test('onboardingComplete ausente del mapa defaults a false', () {
        final mapSinOnboarding = <String, dynamic>{
          'uid': uid,
          'displayName': 'Test',
        };

        final model = UserProfileModel.fromFirestore(mapSinOnboarding, uid);

        expect(model.onboardingComplete, isFalse);
      });

      test('usa uid parámetro cuando uid no está en el mapa', () {
        final mapSinUid = <String, dynamic>{
          'displayName': 'Test User',
          'onboardingComplete': false,
        };

        final model = UserProfileModel.fromFirestore(mapSinUid, uid);

        expect(model.uid, equals(uid));
      });
    });

    group('toFirestore()', () {
      test('serializa todos los campos correctamente', () {
        final model = UserProfileModel(
          uid: uid,
          displayName: 'Juan Pérez',
          phone: '3624123456',
          localidad: 'Formosa Capital',
          photoURL: 'https://photo.url',
          onboardingComplete: true,
        );

        final map = model.toFirestore();

        expect(map['uid'], equals(uid));
        expect(map['displayName'], equals('Juan Pérez'));
        expect(map['phone'], equals('3624123456'));
        expect(map['locality'], equals('Formosa Capital'));
        expect(map['photoURL'], equals('https://photo.url'));
        expect(map['onboardingComplete'], isTrue);
      });

      test('campos null se serializan como null (para Firestore merge)', () {
        final model = UserProfileModel(
          uid: uid,
          displayName: 'Test',
          phone: null,
          localidad: null,
          photoURL: null,
          onboardingComplete: false,
        );

        final map = model.toFirestore();

        expect(map.containsKey('phone'), isTrue);
        expect(map['phone'], isNull);
        expect(map['locality'], isNull);
        expect(map['photoURL'], isNull);
      });
    });

    group('fromDomain()', () {
      test('crea model desde entidad de dominio correctamente', () {
        const profile = UserProfile(
          uid: uid,
          displayName: 'María García',
          phone: '3624987654',
          localidad: 'Clorinda',
          photoURL: null,
          onboardingComplete: true,
        );

        final model = UserProfileModel.fromDomain(profile);

        expect(model.uid, equals(uid));
        expect(model.displayName, equals('María García'));
        expect(model.phone, equals('3624987654'));
        expect(model.localidad, equals('Clorinda'));
        expect(model.photoURL, isNull);
        expect(model.onboardingComplete, isTrue);
      });

      test('crea model con campos opcionales null', () {
        const profile = UserProfile(
          uid: uid,
          displayName: 'Nuevo Usuario',
          onboardingComplete: false,
        );

        final model = UserProfileModel.fromDomain(profile);

        expect(model.phone, isNull);
        expect(model.localidad, isNull);
        expect(model.photoURL, isNull);
        expect(model.onboardingComplete, isFalse);
      });
    });

    group('toDomain()', () {
      test('convierte model a entidad de dominio correctamente', () {
        final model = UserProfileModel(
          uid: uid,
          displayName: 'Carlos López',
          phone: '3624555666',
          localidad: 'El Colorado',
          photoURL: 'https://photo.url',
          onboardingComplete: true,
        );

        final profile = model.toDomain();

        expect(profile, isA<UserProfile>());
        expect(profile.uid, equals(uid));
        expect(profile.displayName, equals('Carlos López'));
        expect(profile.phone, equals('3624555666'));
        expect(profile.localidad, equals('El Colorado'));
        expect(profile.onboardingComplete, isTrue);
      });

      test('isComplete es true cuando tiene displayName, phone y localidad',
          () {
        final model = UserProfileModel(
          uid: uid,
          displayName: 'Test',
          phone: '3624111222',
          localidad: 'Clorinda',
          onboardingComplete: true,
        );

        final profile = model.toDomain();

        expect(profile.isComplete, isTrue);
      });

      test('isComplete es false cuando faltan campos obligatorios', () {
        final model = UserProfileModel(
          uid: uid,
          displayName: 'Test',
          phone: null,
          localidad: null,
          onboardingComplete: false,
        );

        final profile = model.toDomain();

        expect(profile.isComplete, isFalse);
      });
    });

    group('roundtrip domain → model → domain', () {
      test('preserva todos los datos en conversión completa', () {
        const original = UserProfile(
          uid: uid,
          displayName: 'Roundtrip User',
          phone: '3624777888',
          localidad: 'Ingeniero Juárez',
          photoURL: 'https://roundtrip.url',
          onboardingComplete: true,
        );

        final model = UserProfileModel.fromDomain(original);
        final recovered = model.toDomain();

        expect(recovered.uid, equals(original.uid));
        expect(recovered.displayName, equals(original.displayName));
        expect(recovered.phone, equals(original.phone));
        expect(recovered.localidad, equals(original.localidad));
        expect(recovered.photoURL, equals(original.photoURL));
        expect(
            recovered.onboardingComplete, equals(original.onboardingComplete));
      });
    });
  });
}
