import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_entity.dart';
import 'user_provider.dart';
import '../tools/sort_utils.dart';
import 'firestore_quota_provider.dart';

final allUsersProvider = StreamProvider<List<UserEntity>>((ref) {
  final quota = ref.read(firestoreQuotaProvider);
  return FirebaseFirestore.instance
      .collection('user_list')
      .snapshots()
      .map((snapshot) {
        // record a read for this snapshot emission
        try {
          quota.recordRead();
        } catch (_) {}
        return snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList();
      });
});

// Backwards-compatible provider (no sort) kept for existing call sites
final usersByCurrentPlaceProvider = StreamProvider<List<UserEntity>>((ref) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return const Stream<List<UserEntity>>.empty();
  }
  final quota = ref.read(firestoreQuotaProvider);
  return FirebaseFirestore.instance
      .collection('user_list')
      .where('placeId', isEqualTo: user.placeId)
      .snapshots()
      .map((snapshot) {
        try { quota.recordRead(); } catch (_) {}
        return snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList();
      });
});

// New family provider supporting optional sorting
final usersByCurrentPlaceProviderWithOptions = StreamProvider.family<List<UserEntity>, UserSortOption?>((ref, sort) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return const Stream<List<UserEntity>>.empty();
  }
  final quota = ref.read(firestoreQuotaProvider);
  return FirebaseFirestore.instance
      .collection('user_list')
      .where('placeId', isEqualTo: user.placeId)
      .snapshots()
      .map((snapshot) {
        try { quota.recordRead(); } catch (_) {}
        final users = snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList();
        if (sort != null) users.sort((a, b) => compareUsersByOption(a, b, sort));
        return users;
      });
});

// Backwards-compatible family: accepts rolesKey (String) as before
final usersByRolesProvider = StreamProvider.family<List<UserEntity>, String>((ref, rolesKey) {
  final roleNames = rolesKey.split(',');
  final quota = ref.read(firestoreQuotaProvider);
  return FirebaseFirestore.instance
      .collection('user_list')
      .where('role', whereIn: roleNames)
      .snapshots()
      .map((snapshot) {
        try { quota.recordRead(); } catch (_) {}
        return snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList();
      });
});

// New family provider supporting rolesKey + optional sort via params map
final usersByRolesProviderWithOptions = StreamProvider.family<List<UserEntity>, Map<String, dynamic>>((ref, params) {
  final roleNames = (params['rolesKey'] as String).split(',');
  final UserSortOption? sort = params['sort'] as UserSortOption?;
  final quota = ref.read(firestoreQuotaProvider);
  return FirebaseFirestore.instance
      .collection('user_list')
      .where('role', whereIn: roleNames)
      .snapshots()
      .map((snapshot) {
        try { quota.recordRead(); } catch (_) {}
        final users = snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList();
        if (sort != null) users.sort((a, b) => compareUsersByOption(a, b, sort));
        return users;
      });
});

// Backwards-compatible family: accepts rolesKey (String) and filters by current user's place
final usersByRolesAndPlaceProvider = StreamProvider.family<List<UserEntity>, String>((ref, rolesKey) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return const Stream<List<UserEntity>>.empty();
  }
  final roleNames = rolesKey.split(',');
  final quota = ref.read(firestoreQuotaProvider);
  return FirebaseFirestore.instance
      .collection('user_list')
      .where('placeId', isEqualTo: user.placeId)
      .where('role', whereIn: roleNames)
      .snapshots()
      .map((snapshot) {
        try { quota.recordRead(); } catch (_) {}
        return snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList();
      });
});

// New family provider supporting rolesKey + optional sort via params map and current user's place
final usersByRolesAndPlaceProviderWithOptions = StreamProvider.family<List<UserEntity>, Map<String, dynamic>>((ref, params) {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return const Stream<List<UserEntity>>.empty();
  }
  final roleNames = (params['rolesKey'] as String).split(',');
  final UserSortOption? sort = params['sort'] as UserSortOption?;
  final quota = ref.read(firestoreQuotaProvider);
  return FirebaseFirestore.instance
      .collection('user_list')
      .where('placeId', isEqualTo: user.placeId)
      .where('role', whereIn: roleNames)
      .snapshots()
      .map((snapshot) {
        try { quota.recordRead(); } catch (_) {}
        final users = snapshot.docs.map((doc) => UserEntity.fromMap(doc.data())).toList();
        if (sort != null) users.sort((a, b) => compareUsersByOption(a, b, sort));
        return users;
      });
});
