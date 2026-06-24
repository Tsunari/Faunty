import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/core/network/firebase_providers.dart';
import 'package:faunty/core/constants/firestore_paths.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  Stream<UserEntity?> watchCurrentUser() {
    _runBackfillIfNeeded();
    return _auth.authStateChanges().switchMap((firebaseUser) {
      if (firebaseUser == null) return Stream<UserEntity?>.value(null);

      _ensureUserAuthUid(firebaseUser.uid);

      return _firestore
          .collection(FirestorePaths.users)
          .where('authUid', isEqualTo: firebaseUser.uid)
          .limit(1)
          .snapshots()
          .map((qs) => qs.docs.isNotEmpty ? UserEntity.fromMap(qs.docs.first.data()) : null);
    });
  }

  Future<void> _runBackfillIfNeeded() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final done = sp.getBool('backfill_authUid_v1') ?? false;
      if (done) return;

      final col = _firestore.collection(FirestorePaths.users);
      final snap = await col.get();
      final batchSize = 200;
      List<WriteBatch> batches = [];
      WriteBatch currentBatch = _firestore.batch();
      int ops = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final isPlaceholder = data['isPlaceholder'] == true;
        final hasAuth = data.containsKey('authUid') && 
            (data['authUid'] != null && data['authUid'].toString().isNotEmpty);
        if (!isPlaceholder && !hasAuth) {
          currentBatch.update(doc.reference, {'authUid': doc.id});
          ops++;
          if (ops >= batchSize) {
            batches.add(currentBatch);
            currentBatch = _firestore.batch();
            ops = 0;
          }
        }
      }
      if (ops > 0) batches.add(currentBatch);
      for (final b in batches) {
        try {
          await b.commit();
        } catch (_) {}
      }
      await sp.setBool('backfill_authUid_v1', true);
    } catch (_) {}
  }

  Future<void> _ensureUserAuthUid(String uid) async {
    try {
      final docRef = _firestore.collection(FirestorePaths.users).doc(uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data();
        final hasAuth = data != null && 
            data.containsKey('authUid') && 
            (data['authUid'] != null && data['authUid'].toString().isNotEmpty);
        final isPlaceholder = data != null && data['isPlaceholder'] == true;
        if (!isPlaceholder && !hasAuth) {
          await docRef.update({'authUid': uid});
        }
      }
    } catch (_) {}
  }
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
}
