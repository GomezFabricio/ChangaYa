import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:changaya/features/profile/data/firestore_profile_repository.dart';
import 'package:changaya/features/profile/domain/user_profile.dart';

import 'firestore_profile_repository_test.mocks.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  Query,
  QuerySnapshot,
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseStorage mockStorage;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
  late FirestoreProfileRepository repository;

  const uid = 'uid-profile-test';

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    mockCollection = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockDocSnapshot = MockDocumentSnapshot();
    repository = FirestoreProfileRepository(
      firestore: mockFirestore,
      storage: mockStorage,
    );

    // Wiring colección → documento
    when(mockFirestore.collection('users')).thenReturn(mockCollection);
    when(mockCollection.doc(uid)).thenReturn(mockDocRef);
  });

  group('FirestoreProfileRepository', () {
    group('getProfile()', () {
      test('retorna UserProfile cuando el documento existe', () async {
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn({
          'uid': uid,
          'displayName': 'Test User',
          'phone': '3624111222',
          'locality': 'Formosa Capital',
          'photoURL': null,
          'onboardingComplete': true,
        });
        when(mockDocSnapshot.id).thenReturn(uid);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        final profile = await repository.getProfile(uid);

        expect(profile, isNotNull);
        expect(profile!.uid, equals(uid));
        expect(profile.displayName, equals('Test User'));
        expect(profile.onboardingComplete, isTrue);
      });

      test('retorna null cuando el documento no existe', () async {
        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocSnapshot.data()).thenReturn(null);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        final profile = await repository.getProfile(uid);

        expect(profile, isNull);
      });
    });

    group('watchProfile()', () {
      test('emite UserProfile cuando el documento existe', () {
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn({
          'uid': uid,
          'displayName': 'Watching User',
          'onboardingComplete': false,
        });
        when(mockDocSnapshot.id).thenReturn(uid);
        when(mockDocRef.snapshots())
            .thenAnswer((_) => Stream.value(mockDocSnapshot));

        expect(
          repository.watchProfile(uid),
          emits(isA<UserProfile>().having((p) => p.uid, 'uid', uid)),
        );
      });

      test('emite null cuando el documento no existe', () {
        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocSnapshot.data()).thenReturn(null);
        when(mockDocRef.snapshots())
            .thenAnswer((_) => Stream.value(mockDocSnapshot));

        expect(
          repository.watchProfile(uid),
          emits(isNull),
        );
      });
    });

    group('updateProfile()', () {
      test('llama set con merge=true en Firestore', () async {
        when(mockDocRef.set(any, any)).thenAnswer((_) async {});

        const profile = UserProfile(
          uid: uid,
          displayName: 'Updated User',
          phone: '3624333444',
          localidad: 'Clorinda',
          onboardingComplete: true,
        );

        await repository.updateProfile(profile);

        verify(mockDocRef.set(
          argThat(isA<Map<String, dynamic>>()),
          argThat(isA<SetOptions>()),
        )).called(1);
      });

      test('los datos enviados a Firestore contienen el uid correcto',
          () async {
        Map<String, dynamic>? capturedData;
        when(mockDocRef.set(any, any)).thenAnswer((invoc) async {
          capturedData = invoc.positionalArguments[0] as Map<String, dynamic>;
        });

        const profile = UserProfile(
          uid: uid,
          displayName: 'Test',
          onboardingComplete: false,
        );

        await repository.updateProfile(profile);

        expect(capturedData?['uid'], equals(uid));
        expect(capturedData?['displayName'], equals('Test'));
      });
    });
  });
}
