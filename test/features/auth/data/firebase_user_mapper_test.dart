import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:changaya/features/auth/data/firebase_user_mapper.dart';
import 'package:changaya/features/auth/domain/user.dart';

import 'firebase_user_mapper_test.mocks.dart';

@GenerateMocks([fb.User, fb.UserInfo])
void main() {
  group('FirebaseUserMapper', () {
    late MockUser mockFirebaseUser;

    setUp(() {
      mockFirebaseUser = MockUser();
    });

    /// Helper para configurar el mock con valores completos
    void setupFullUser() {
      when(mockFirebaseUser.uid).thenReturn('uid-123');
      when(mockFirebaseUser.email).thenReturn('test@example.com');
      when(mockFirebaseUser.displayName).thenReturn('Test User');
      when(mockFirebaseUser.photoURL)
          .thenReturn('https://example.com/photo.jpg');
      when(mockFirebaseUser.emailVerified).thenReturn(true);
      when(mockFirebaseUser.providerData).thenReturn([]);
    }

    group('toDomain()', () {
      test('mapea todos los campos correctamente con valores completos', () {
        // Arrange
        setupFullUser();

        // Act
        final user = FirebaseUserMapper.toDomain(mockFirebaseUser);

        // Assert
        expect(user.uid, equals('uid-123'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
        expect(user.photoURL, equals('https://example.com/photo.jpg'));
        expect(user.emailVerified, isTrue);
        expect(user.onboardingComplete,
            isFalse); // siempre false — viene de Firestore
      });

      test('maneja displayName null correctamente', () {
        // Arrange
        when(mockFirebaseUser.uid).thenReturn('uid-456');
        when(mockFirebaseUser.email).thenReturn('no-name@example.com');
        when(mockFirebaseUser.displayName).thenReturn(null);
        when(mockFirebaseUser.photoURL).thenReturn(null);
        when(mockFirebaseUser.emailVerified).thenReturn(false);
        when(mockFirebaseUser.providerData).thenReturn([]);

        // Act
        final user = FirebaseUserMapper.toDomain(mockFirebaseUser);

        // Assert
        expect(user.displayName, isNull);
        expect(user.uid, equals('uid-456'));
      });

      test('maneja photoURL null correctamente', () {
        // Arrange
        when(mockFirebaseUser.uid).thenReturn('uid-789');
        when(mockFirebaseUser.email).thenReturn('no-photo@example.com');
        when(mockFirebaseUser.displayName).thenReturn('Some User');
        when(mockFirebaseUser.photoURL).thenReturn(null);
        when(mockFirebaseUser.emailVerified).thenReturn(true);
        when(mockFirebaseUser.providerData).thenReturn([]);

        // Act
        final user = FirebaseUserMapper.toDomain(mockFirebaseUser);

        // Assert
        expect(user.photoURL, isNull);
        expect(user.displayName, equals('Some User'));
      });

      test('emailVerified false se mapea correctamente', () {
        // Arrange
        when(mockFirebaseUser.uid).thenReturn('uid-unverified');
        when(mockFirebaseUser.email).thenReturn('unverified@example.com');
        when(mockFirebaseUser.displayName).thenReturn(null);
        when(mockFirebaseUser.photoURL).thenReturn(null);
        when(mockFirebaseUser.emailVerified).thenReturn(false);
        when(mockFirebaseUser.providerData).thenReturn([]);

        // Act
        final user = FirebaseUserMapper.toDomain(mockFirebaseUser);

        // Assert
        expect(user.emailVerified, isFalse);
      });

      test(
          'onboardingComplete siempre es false en el mapper (viene de Firestore)',
          () {
        // Arrange
        setupFullUser();

        // Act
        final user = FirebaseUserMapper.toDomain(mockFirebaseUser);

        // Assert
        // onboardingComplete NO viene de firebase_auth.User — es un campo Firestore.
        // El mapper siempre devuelve false; se combina con UserProfile en los providers.
        expect(user.onboardingComplete, isFalse);
      });

      test('retorna entidad User de dominio pura (sin imports de Firebase)',
          () {
        // Arrange
        setupFullUser();

        // Act
        final user = FirebaseUserMapper.toDomain(mockFirebaseUser);

        // Assert — el tipo retornado es la entidad de dominio
        expect(user, isA<User>());
      });

      test('providers vacíos se mapean como lista vacía', () {
        // Arrange
        when(mockFirebaseUser.uid).thenReturn('uid-noproviders');
        when(mockFirebaseUser.email).thenReturn('test@example.com');
        when(mockFirebaseUser.displayName).thenReturn(null);
        when(mockFirebaseUser.photoURL).thenReturn(null);
        when(mockFirebaseUser.emailVerified).thenReturn(false);
        when(mockFirebaseUser.providerData).thenReturn([]);

        // Act
        final user = FirebaseUserMapper.toDomain(mockFirebaseUser);

        // Assert
        expect(user.providers, isEmpty);
      });

      test('providers google.com se mapean correctamente', () {
        // Arrange
        final mockUserInfo = MockUserInfo();
        when(mockUserInfo.providerId).thenReturn('google.com');
        when(mockFirebaseUser.uid).thenReturn('uid-google');
        when(mockFirebaseUser.email).thenReturn('google@example.com');
        when(mockFirebaseUser.displayName).thenReturn('Google User');
        when(mockFirebaseUser.photoURL).thenReturn('https://photo.url');
        when(mockFirebaseUser.emailVerified).thenReturn(true);
        when(mockFirebaseUser.providerData).thenReturn([mockUserInfo]);

        // Act
        final user = FirebaseUserMapper.toDomain(mockFirebaseUser);

        // Assert
        expect(user.providers, contains('google.com'));
        expect(user.hasGoogleProvider, isTrue);
      });

      test('providers password se mapean correctamente', () {
        // Arrange
        final mockUserInfo = MockUserInfo();
        when(mockUserInfo.providerId).thenReturn('password');
        when(mockFirebaseUser.uid).thenReturn('uid-password');
        when(mockFirebaseUser.email).thenReturn('pw@example.com');
        when(mockFirebaseUser.displayName).thenReturn(null);
        when(mockFirebaseUser.photoURL).thenReturn(null);
        when(mockFirebaseUser.emailVerified).thenReturn(false);
        when(mockFirebaseUser.providerData).thenReturn([mockUserInfo]);

        // Act
        final user = FirebaseUserMapper.toDomain(mockFirebaseUser);

        // Assert
        expect(user.providers, contains('password'));
        expect(user.hasGoogleProvider, isFalse);
      });
    });
  });
}
