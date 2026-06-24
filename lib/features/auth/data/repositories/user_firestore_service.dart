import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:faunty/features/auth/domain/entities/user_entity.dart';

class UserFirestoreService {
  CollectionReference get _usersCollection => FirebaseFirestore.instance.collection('user_list');

  Future<void> createUser(UserEntity user, {Map<String, dynamic>? extraFields}) async {
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
  }

  Future<UserEntity?> getUserByUid({required String uid}) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserEntity.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUser(UserEntity user) async {
    await _usersCollection.doc(user.uid).update(user.toMap());
  }

  Future<void> deleteUser(UserEntity user) async {
    await _usersCollection.doc(user.uid).delete();
  }
}