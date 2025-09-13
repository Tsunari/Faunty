import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_entity.dart';
import 'firestore_quota_service.dart';

class UserFirestoreService {
  CollectionReference get _usersCollection => FirebaseFirestore.instance.collection('user_list');

  Future<void> createUser(UserEntity user, {FirestoreQuotaService? quota, Map<String, dynamic>? extraFields}) async {
    final data = {
      ...user.toMap(),
      if (extraFields != null) ...extraFields,
      'createdAt': FieldValue.serverTimestamp(),
    };
    // Ensure authUid is present for normal users so the provider can always
    // resolve the signed-in user's document via a single 'authUid' query.
    if (!data.containsKey('authUid')) {
      data['authUid'] = user.uid;
    }
    await _usersCollection.doc(user.uid).set(data);
    try { await quota?.recordWrite(); } catch (_) {}
  }

  Future<UserEntity?> getUserByUid({required String uid}) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserEntity.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUser(UserEntity user, {FirestoreQuotaService? quota}) async {
    await _usersCollection.doc(user.uid).update(user.toMap());
    try { await quota?.recordWrite(); } catch (_) {}
  }

  Future<void> deleteUser(UserEntity user, {FirestoreQuotaService? quota}) async {
    await _usersCollection.doc(user.uid).delete();
    try { await quota?.recordWrite(); } catch (_) {}
  }
}
