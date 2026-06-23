import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/core/network/firebase_providers.dart';
import 'package:faunty/core/constants/firestore_paths.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/features/profile/domain/entities/place_model.dart';
import 'package:faunty/features/profile/data/repositories/globals_firestore_service.dart';
import 'package:faunty/features/profile/data/repositories/place_firestore_service.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository(this._firestore);

  GlobalsFirestoreService getGlobalsService(String placeId) =>
      GlobalsFirestoreService(placeId);

  // Places API
  Future<List<PlaceModel>> fetchPlaces() async {
    return await PlaceFirestoreService.fetchPlaces();
  }

  Stream<List<PlaceModel>> placesStream() {
    return PlaceFirestoreService.placesStream();
  }

  // Users API
  Stream<List<UserEntity>> watchAllUsers() {
    return _firestore
        .collection(FirestorePaths.users)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList());
  }

  Stream<List<UserEntity>> watchUsersByPlace(String placeId) {
    return _firestore
        .collection(FirestorePaths.users)
        .where('placeId', isEqualTo: placeId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList());
  }

  Stream<List<UserEntity>> watchUsersByRoles(List<String> roleNames) {
    return _firestore
        .collection(FirestorePaths.users)
        .where('role', whereIn: roleNames)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList());
  }

  Stream<List<UserEntity>> watchUsersByPlaceAndRoles(String placeId, List<String> roleNames) {
    return _firestore
        .collection(FirestorePaths.users)
        .where('placeId', isEqualTo: placeId)
        .where('role', whereIn: roleNames)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList());
  }
}

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository(ref.watch(firestoreProvider));
}
