import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:rxdart/rxdart.dart';

// StreamProvider for real-time user updates based on authStateChanges
final userProvider = StreamProvider<UserEntity?>((ref) {
  // Kick off a one-time background backfill for missing authUid fields.
  // This runs in the background and is idempotent (recorded via SharedPreferences).
  () async {
    try {
      final sp = await SharedPreferences.getInstance();
      final done = sp.getBool('backfill_authUid_v1') ?? false;
      if (done) return;

      // Scan user_list and set authUid = doc.id for non-placeholder docs missing it.
      final col = FirebaseFirestore.instance.collection('user_list');
      final snap = await col.get();
      final batchSize = 200;
      List<WriteBatch> batches = [];
      WriteBatch currentBatch = FirebaseFirestore.instance.batch();
      int ops = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final isPlaceholder = data['isPlaceholder'] == true;
        final hasAuth = data.containsKey('authUid') && (data['authUid'] != null && data['authUid'].toString().isNotEmpty);
        if (!isPlaceholder && !hasAuth) {
          currentBatch.update(doc.reference, {'authUid': doc.id});
          ops++;
          if (ops >= batchSize) {
            batches.add(currentBatch);
            currentBatch = FirebaseFirestore.instance.batch();
            ops = 0;
          }
        }
      }
      if (ops > 0) batches.add(currentBatch);
      for (final b in batches) {
        try {
          await b.commit();
        } catch (e) {
          // ignore individual batch failures for now; continue
        }
      }
      await sp.setBool('backfill_authUid_v1', true);
    } catch (e) {
      // ignore errors; backfill can be retried on next app start
    }
  }();

  return FirebaseAuth.instance.authStateChanges().switchMap((firebaseUser) {
    if (firebaseUser == null) return Stream<UserEntity?>.value(null);

    // Ensure the doc with id==authUid has authUid set (this is a cheap one-doc
    // read + optional update only when the query by 'authUid' returns nothing).
    () async {
      try {
        final docRef = FirebaseFirestore.instance.collection('user_list').doc(firebaseUser.uid);
        final doc = await docRef.get();
        if (doc.exists) {
          final data = doc.data();
          final hasAuth = data != null && data.containsKey('authUid') && (data['authUid'] != null && data['authUid'].toString().isNotEmpty);
          final isPlaceholder = data != null && data['isPlaceholder'] == true;
          if (!isPlaceholder && !hasAuth) {
            await docRef.update({'authUid': firebaseUser.uid});
          }
        }
      } catch (e) {
        // ignore
      }
    }();

    // Primary stream: query by authUid only (createUser now ensures authUid exists
    // for non-placeholder users and placeholders get authUid when linked).
    return FirebaseFirestore.instance
      .collection('user_list')
      .where('authUid', isEqualTo: firebaseUser.uid)
      .limit(1)
      .snapshots()
      .map((qs) => qs.docs.isNotEmpty ? UserEntity.fromMap(qs.docs.first.data()) : null);
  });
});