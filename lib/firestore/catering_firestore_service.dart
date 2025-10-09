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

  /// Stream a list of 7 booleans indicating whether each day
  /// uses a uniform assignment across all meals.
  Stream<List<bool>> watchUniformDays() {
    return _docRef.snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      final raw = data == null ? null : data['uniformDays'] as Map<String, dynamic>?;
      final List<bool> days = List<bool>.generate(7, (i) {
        final v = raw == null ? null : raw['$i'];
        if (v is bool) return v;
        if (v is num) return v != 0; // tolerate legacy numeric flags
        return false;
      });
      return days;
    });
  }

  /// Set the uniform flag for a given day. Stored under 'uniformDays' map.
  Future<void> setUniformDay(int day, bool value) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_docRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final uniform = Map<String, dynamic>.from(data['uniformDays'] ?? {});
      uniform['$day'] = value;
      tx.set(_docRef, {'uniformDays': uniform}, SetOptions(merge: true));
    });
  }

  Stream<List<List<List<String>>>> watchWeekPlan() {
    return _docRef.snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      final raw = data == null ? null : data['weekPlan'] as Map<String, dynamic>?;
      if (raw == null) {
        // default: 7 days, 3 meals
        return List.generate(7, (_) => List.generate(3, (_) => <String>[]));
      }

      // Determine dynamic meal count by scanning keys like 'day_meal'
      int globalMaxMeal = -1;
      for (final key in raw.keys) {
        final parts = key.split('_');
        if (parts.length != 2) continue;
        final mealIdx = int.tryParse(parts[1]);
        if (mealIdx != null && mealIdx > globalMaxMeal) globalMaxMeal = mealIdx;
      }
      final mealCount = (globalMaxMeal >= 0) ? (globalMaxMeal + 1) : 3;

      List<List<List<String>>> weekPlan = List.generate(7, (day) {
        return List.generate(mealCount, (meal) {
          final key = '${day}_$meal';
          final users = raw[key];
          if (users is List) return users.map((u) => u.toString()).toList();
          return <String>[];
        });
      });
      return weekPlan;
    });
  }

  /// Stream the slot (custom) names stored under 'slotNames' map.
  Stream<Map<String, String>> watchSlotNames() {
    return _docRef.snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      final raw = data == null ? null : data['slotNames'] as Map<String, dynamic>?;
      if (raw == null) return <String, String>{};
      return raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    });
  }

  Future<Map<String, String>> getSlotNames() async {
    final snap = await _docRef.get();
    final data = snap.data() as Map<String, dynamic>?;
    final raw = data == null ? null : data['slotNames'] as Map<String, dynamic>?;
    if (raw == null) return <String, String>{};
    return raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  }

  /// Set a single slot name (e.g. 'Cleaning') for a specific day & meal index.
  Future<void> setSlotName(int day, int meal, String? name) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_docRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final slotNames = Map<String, dynamic>.from(data['slotNames'] ?? {});
      final key = _slotKey(day, meal);
      if (name == null || name.isEmpty) {
        slotNames.remove(key);
      } else {
        slotNames[key] = name;
      }
      tx.set(_docRef, {'slotNames': slotNames}, SetOptions(merge: true));
    });
  }

  /// Replace all slot names at once.
  Future<void> setSlotNames(Map<String, String> names) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_docRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final slotNames = Map<String, dynamic>.from(data['slotNames'] ?? {});
      // merge/replace provided entries (empty values remove key)
      for (final entry in names.entries) {
        if (entry.value.isEmpty)
          slotNames.remove(entry.key);
        else
          slotNames[entry.key] = entry.value;
      }
      tx.set(_docRef, {'slotNames': slotNames}, SetOptions(merge: true));
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
    await _docRef.set({'weekPlan': flat}, SetOptions(merge: true));
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
