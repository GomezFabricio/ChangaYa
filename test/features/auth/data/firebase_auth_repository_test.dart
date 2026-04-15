import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:changaya/features/auth/data/firebase_auth_repository.dart';
import 'package:changaya/features/auth/domain/auth_failure.dart';
import 'package:changaya/features/auth/domain/user.dart';

import 'firebase_auth_repository_test.mocks.dart';

@GenerateMocks([
  fb.FirebaseAuth,
  fb.UserCredential,
  fb.User,
  fb.UserInfo,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
])
void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late FirebaseAuthRepository repository;
  late MockUser mockFirebaseUser;
  late MockUserCredential mockUserCredential;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    repository = FirebaseAuthRepository(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
    );
    mockFirebaseUser = MockUser();
    mockUserCredential = MockUserCredential();

    // Default user setup
    when(mockFirebaseUser.uid).thenReturn('uid-123');
    when(mockFirebaseUser.email).thenReturn('test@example.com');
    when(mockFirebaseUser.displayName).thenReturn('Test User');
    when(mockFirebaseUser.photoURL).thenReturn(null);
    when(mockFirebaseUser.emailVerified).thenReturn(true);
    when(mockFirebaseUser.providerData).thenReturn([]);
    when(mockUserCredential.user).thenReturn(mockFirebaseUser);
  });

  group('FirebaseAuthRepository', () {
    group('authStateChanges', () {
      test('emite null cuando no hay usuario autenticado', () {
        when(mockFirebaseAuth.userChanges())
            .thenAnswer((_) => Stream.value(null));

        expect(repository.authStateChanges, emits(isNull));
      });

      test('emite User cuando hay usuario autenticado', () {
        when(mockFirebaseAuth.userChanges())
            .thenAnswer((_) => Stream.value(mockFirebaseUser));

        expect(
          repository.authStateChanges,
          emits(isA<User>().having((u) => u.uid, 'uid', 'uid-123')),
        );
      });
    });

    group('currentUser', () {
      test('retorna null cuando no hay sesión activa', () {
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        expect(repository.currentUser, isNull);
      });

      test('retorna User cuando hay sesión activa', () {
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);

        final user = repository.currentUser;
        expect(user, isNotNull);
        expect(user!.uid, equals('uid-123'));
      });
    });

    group('signInWithEmail()', () {
      test('retorna User al iniciar sesión con credenciales válidas', () async {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUserCredential);

        final user = await repository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(user.uid, equals('uid-123'));
        expect(user.email, equals('test@example.com'));
      });

      test('lanza AuthFailure.invalidCredential para user-not-found', () async {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(fb.FirebaseAuthException(code: 'user-not-found'));

        expect(
          () => repository.signInWithEmail(
            email: 'noexiste@example.com',
            password: 'pass',
          ),
          throwsA(isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            'invalid-credential',
          )),
        );
      });

      test('lanza AuthFailure.invalidCredential para wrong-password', () async {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(fb.FirebaseAuthException(code: 'wrong-password'));

        expect(
          () => repository.signInWithEmail(
            email: 'test@example.com',
            password: 'wrongpass',
          ),
          throwsA(isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            'invalid-credential',
          )),
        );
      });

      test('lanza AuthFailure.invalidCredential para invalid-credential',
          () async {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(fb.FirebaseAuthException(code: 'invalid-credential'));

        expect(
          () => repository.signInWithEmail(
            email: 'test@example.com',
            password: 'wrongpass',
          ),
          throwsA(isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            'invalid-credential',
          )),
        );
      });

      test('lanza AuthFailure.networkError para network-request-failed',
          () async {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(fb.FirebaseAuthException(code: 'network-request-failed'));

        expect(
          () => repository.signInWithEmail(
            email: 'test@example.com',
            password: 'pass',
          ),
          throwsA(isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            'network-request-failed',
          )),
        );
      });

      test('lanza AuthFailure.tooManyRequests para too-many-requests',
          () async {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(fb.FirebaseAuthException(code: 'too-many-requests'));

        expect(
          () => repository.signInWithEmail(
            email: 'test@example.com',
            password: 'pass',
          ),
          throwsA(isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            'too-many-requests',
          )),
        );
      });

      test('lanza AuthFailure.userDisabled para user-disabled', () async {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(fb.FirebaseAuthException(code: 'user-disabled'));

        expect(
          () => repository.signInWithEmail(
            email: 'test@example.com',
            password: 'pass',
          ),
          throwsA(isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            'user-disabled',
          )),
        );
      });
    });

    group('registerWithEmail()', () {
      test('retorna User al registrar con email válido', () async {
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUserCredential);

        final user = await repository.registerWithEmail(
          email: 'nuevo@example.com',
          password: 'Password123',
        );

        expect(user, isA<User>());
        expect(user.uid, equals('uid-123'));
      });

      test('lanza AuthFailure.emailAlreadyInUse para email-already-in-use',
          () async {
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(fb.FirebaseAuthException(code: 'email-already-in-use'));

        expect(
          () => repository.registerWithEmail(
            email: 'existente@example.com',
            password: 'pass',
          ),
          throwsA(isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            'email-already-in-use',
          )),
        );
      });

      test('lanza AuthFailure.weakPassword para weak-password', () async {
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(fb.FirebaseAuthException(code: 'weak-password'));

        expect(
          () => repository.registerWithEmail(
            email: 'test@example.com',
            password: '123',
          ),
          throwsA(isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            'weak-password',
          )),
        );
      });
    });

    group('signInWithGoogle() — mobile path', () {
      test('retorna User cuando Google Sign-In es exitoso', () async {
        final mockAccount = MockGoogleSignInAccount();
        final mockAuthentication = MockGoogleSignInAuthentication();

        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockAccount);
        when(mockAccount.authentication)
            .thenAnswer((_) async => mockAuthentication);
        when(mockAuthentication.accessToken).thenReturn('access-token');
        when(mockAuthentication.idToken).thenReturn('id-token');
        when(mockFirebaseAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);

        final user = await repository.signInWithGoogle();

        expect(user.uid, equals('uid-123'));
      });

      test('lanza AuthFailure.operationNotAllowed cuando usuario cancela',
          () async {
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        expect(
          () => repository.signInWithGoogle(),
          throwsA(isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            'operation-not-allowed',
          )),
        );
      });
    });

    group('signOut()', () {
      test('llama a signOut en FirebaseAuth y GoogleSignIn', () async {
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        await repository.signOut();

        verify(mockFirebaseAuth.signOut()).called(1);
        verify(mockGoogleSignIn.signOut()).called(1);
      });
    });

    group('sendEmailVerification()', () {
      test('llama sendEmailVerification en el usuario actual', () async {
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(mockFirebaseUser.sendEmailVerification()).thenAnswer((_) async {});

        await repository.sendEmailVerification();

        verify(mockFirebaseUser.sendEmailVerification()).called(1);
      });
    });

    group('sendPasswordResetEmail()', () {
      test('llama sendPasswordResetEmail en FirebaseAuth', () async {
        when(mockFirebaseAuth.sendPasswordResetEmail(
          email: anyNamed('email'),
        )).thenAnswer((_) async {});

        await repository.sendPasswordResetEmail(email: 'reset@example.com');

        verify(mockFirebaseAuth.sendPasswordResetEmail(
          email: 'reset@example.com',
        )).called(1);
      });
    });
  });
}
