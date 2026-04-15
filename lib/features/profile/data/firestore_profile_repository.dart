import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:changaya/core/constants/firestore_collections.dart';
import 'package:changaya/features/profile/data/user_profile_model.dart';
import 'package:changaya/features/profile/domain/profile_repository.dart';
import 'package:changaya/features/profile/domain/user_profile.dart';

/// Implementación de [ProfileRepository] usando Cloud Firestore.
///
/// Única clase que puede importar `cloud_firestore` en el feature profile.
/// La capa de dominio y presentación NO deben importar Firestore directamente.
class FirestoreProfileRepository implements ProfileRepository {
  const FirestoreProfileRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _docRef(String uid) =>
      _firestore.collection(FirestoreCollections.users).doc(uid);

  // ---------------------------------------------------------------------------
  // getProfile
  // ---------------------------------------------------------------------------

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final snapshot = await _docRef(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return UserProfileModel.fromFirestore(snapshot.data()!, snapshot.id)
        .toDomain();
  }

  // ---------------------------------------------------------------------------
  // watchProfile
  // ---------------------------------------------------------------------------

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _docRef(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserProfileModel.fromFirestore(snapshot.data()!, snapshot.id)
          .toDomain();
    });
  }

  // ---------------------------------------------------------------------------
  // updateProfile
  // ---------------------------------------------------------------------------

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final model = UserProfileModel.fromDomain(profile);
    final data = model.toFirestore()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _docRef(profile.uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // uploadProfilePhoto — Firebase Storage upload
  // ---------------------------------------------------------------------------

  @override
  Future<String> uploadProfilePhoto(String uid, XFile photo) async {
    final ref = _storage.ref().child('profile_photos/$uid.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putFile(File(photo.path), metadata);
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }
}
