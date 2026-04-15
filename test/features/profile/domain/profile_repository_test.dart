// test/features/profile/domain/profile_repository_test.dart
//
// Tests del contrato ProfileRepository usando mock de Mockito.
// STRICT TDD: este archivo existe ANTES de lib/features/profile/domain/profile_repository.dart
//
// Verifica que el mock cumple el contrato:
// - getProfile(uid) → Future<UserProfile?>
// - updateProfile(UserProfile) → Future<void>
// - watchProfile(uid) → Stream<UserProfile?>
// - uploadProfilePhoto(uid, XFile) → Future<String>
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart';
import 'package:changaya/features/profile/domain/profile_repository.dart';
import 'package:changaya/features/profile/domain/user_profile.dart';

import 'profile_repository_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
  });

  const testProfile = UserProfile(
    uid: 'uid-test',
    displayName: 'Test User',
    phone: '03624123456',
    localidad: 'Formosa Capital',
    onboardingComplete: false,
  );

  group('ProfileRepository contract tests', () {
    group('getProfile', () {
      test('retorna UserProfile cuando existe', () async {
        when(mockProfileRepository.getProfile(any))
            .thenAnswer((_) async => testProfile);

        final result = await mockProfileRepository.getProfile('uid-test');

        expect(result, isA<UserProfile>());
        expect(result!.uid, 'uid-test');
      });

      test('retorna null cuando no existe', () async {
        when(mockProfileRepository.getProfile(any))
            .thenAnswer((_) async => null);

        final result =
            await mockProfileRepository.getProfile('uid-inexistente');

        expect(result, isNull);
      });
    });

    group('updateProfile', () {
      test('acepta UserProfile y completa sin error', () async {
        when(mockProfileRepository.updateProfile(any)).thenAnswer((_) async {});

        await expectLater(
          mockProfileRepository.updateProfile(testProfile),
          completes,
        );

        verify(mockProfileRepository.updateProfile(testProfile)).called(1);
      });
    });

    group('watchProfile', () {
      test('retorna Stream<UserProfile?>', () {
        when(mockProfileRepository.watchProfile(any))
            .thenAnswer((_) => Stream.value(testProfile));

        final stream = mockProfileRepository.watchProfile('uid-test');

        expect(stream, isA<Stream<UserProfile?>>());
      });

      test('stream emite UserProfile actualizado', () async {
        when(mockProfileRepository.watchProfile(any))
            .thenAnswer((_) => Stream.fromIterable([testProfile, null]));

        final values =
            await mockProfileRepository.watchProfile('uid-test').toList();

        expect(values, hasLength(2));
        expect(values[0], isA<UserProfile>());
        expect(values[1], isNull);
      });
    });

    group('uploadProfilePhoto', () {
      test('retorna String (URL de descarga)', () async {
        const photoUrl = 'https://storage.googleapis.com/photo.jpg';
        final fakeFile = XFile('fake/path/photo.jpg');

        when(mockProfileRepository.uploadProfilePhoto(any, any))
            .thenAnswer((_) async => photoUrl);

        final result = await mockProfileRepository.uploadProfilePhoto(
            'uid-test', fakeFile);

        expect(result, isA<String>());
        expect(result, photoUrl);
      });
    });
  });
}
