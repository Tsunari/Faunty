import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_entity.dart';
// import '../models/places.dart';

class CateringFirestoreService {
  final UserEntity user;
  CateringFirestoreService(this.user);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference get _docRef {
    final placeId = user.placeId;
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('catering')
        .doc('weekPlan');
  }

  Stream<List<List<List<String>>>> watchWeekPlan() {
    return _docRef.snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null || data['weekPlan'] == null) {
        // 7 days, 3 meals, empty
        return List.generate(7, (_) => List.generate(3, (_) => <String>[]));
      }
      final raw = data['weekPlan'] as Map<String, dynamic>;
      // Convert map back to List<List<List<String>>>
      List<List<List<String>>> weekPlan = List.generate(7, (day) => List.generate(3, (meal) {
        final key = '${day}_$meal';
        final users = raw[key];
        if (users is List) {
          return users.map((u) => u.toString()).toList();
        } else {
          return <String>[];
        }
      }));
      return weekPlan;
    });
  }

  /// Sets the entire week plan
  /// weekPlan is List<List<List<String>>> (7 days, 3 meals, users)
  Future<void> setWeekPlan(List<List<List<String>>> weekPlan) async {
    // Convert to Map<String, List<String>>
    final Map<String, List<String>> flat = {};
    for (int day = 0; day < weekPlan.length; day++) {
      for (int meal = 0; meal < weekPlan[day].length; meal++) {
        flat['${day}_$meal'] = List<String>.from(weekPlan[day][meal]);
      }
    }
    await _docRef.set({'weekPlan': flat});
  }

  String _slotKey(int day, int meal) => '${day}_$meal';

  /// Watch a single slot as a stream of user ids
  Stream<List<String>> watchSlot(int day, int meal) {
    final key = _slotKey(day, meal);
    return _docRef.snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      final raw = data == null ? null : data['weekPlan'] as Map<String, dynamic>?;
      final users = raw == null ? null : raw[key];
      if (users is List) return users.map((u) => u.toString()).toList();
      return <String>[];
    });
  }

  /// Read current users for a slot (one-off)
  Future<List<String>> getSlotUsers(int day, int meal) async {
    final snap = await _docRef.get();
    final data = snap.data() as Map<String, dynamic>?;
    final raw = data == null ? null : data['weekPlan'] as Map<String, dynamic>?;
    final users = raw == null ? null : raw[_slotKey(day, meal)];
    if (users is List) return users.map((u) => u.toString()).toList();
    return <String>[];
  }

  /// Replace users for a slot
  Future<void> setSlotUsers(int day, int meal, List<String> users) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_docRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final weekPlan = Map<String, dynamic>.from(data['weekPlan'] ?? {});
      weekPlan[_slotKey(day, meal)] = users;
      tx.set(_docRef, {'weekPlan': weekPlan}, SetOptions(merge: true));
    });
  }

  /// Add a user to the slot (idempotent)
  Future<void> addUserToSlot(int day, int meal, String uid) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_docRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final weekPlan = Map<String, dynamic>.from(data['weekPlan'] ?? {});
      final key = _slotKey(day, meal);
      final list = List<String>.from((weekPlan[key] as List<dynamic>?)?.map((e) => e.toString()) ?? []);
      if (!list.contains(uid)) list.add(uid);
      weekPlan[key] = list;
      tx.set(_docRef, {'weekPlan': weekPlan}, SetOptions(merge: true));
    });
  }

  /// Remove a user from the slot
  Future<void> removeUserFromSlot(int day, int meal, String uid) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_docRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final weekPlan = Map<String, dynamic>.from(data['weekPlan'] ?? {});
      final key = _slotKey(day, meal);
      final list = List<String>.from((weekPlan[key] as List<dynamic>?)?.map((e) => e.toString()) ?? []);
      list.removeWhere((x) => x == uid);
      weekPlan[key] = list;
      tx.set(_docRef, {'weekPlan': weekPlan}, SetOptions(merge: true));
    });
  }

  /// Toggle user membership in slot (add if missing, remove if present)
  Future<void> toggleUserInSlot(int day, int meal, String uid) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_docRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final weekPlan = Map<String, dynamic>.from(data['weekPlan'] ?? {});
      final key = _slotKey(day, meal);
      final list = List<String>.from((weekPlan[key] as List<dynamic>?)?.map((e) => e.toString()) ?? []);
      if (list.contains(uid))
        list.removeWhere((x) => x == uid);
      else
        list.add(uid);
      weekPlan[key] = list;
      tx.set(_docRef, {'weekPlan': weekPlan}, SetOptions(merge: true));
    });
  }
}
