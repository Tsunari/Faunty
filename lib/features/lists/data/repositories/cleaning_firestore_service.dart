import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
// import '../models/places.dart';
import 'package:uuid/uuid.dart';


class CleaningFirestoreService {
  final UserEntity user;
  CleaningFirestoreService(this.user);
  DocumentReference get _docRef {
    final placeId = user.placeId;
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('cleaning')
        .doc('data');
  }

  /// Watches the cleaning places and assignments structure:
  /// { places: { placeId: { name: String, assignees: [userId, ...] }, ... } }
  Stream<Map<String, dynamic>> watchCleaning() {
    return _docRef.snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return <String, dynamic>{};

      // Ensure shapes
      final placesMap = Map<String, dynamic>.from(data['places'] ?? {});
      final groupsMap = Map<String, dynamic>.from(data['groups'] ?? {});
      final orderList = (data['order'] as List?)?.cast<String>();
      final groupOrder = (data['groupOrder'] as List?)?.cast<String>();

      // If there's an explicit order array, use it to build an ordered places map
      final orderedPlaces = <String, dynamic>{};
      if (orderList != null && orderList.isNotEmpty) {
        for (final id in orderList) {
          if (placesMap.containsKey(id)) orderedPlaces[id] = placesMap[id];
        }
        for (final e in placesMap.entries) {
          if (!orderedPlaces.containsKey(e.key)) orderedPlaces[e.key] = e.value;
        }
      } else {
        orderedPlaces.addAll(placesMap);
      }

      // Return a combined doc map so callers can access places and groups and orders
      return {
        'places': Map<String, dynamic>.from(orderedPlaces),
        'groups': Map<String, dynamic>.from(groupsMap),
        'order': orderList ?? orderedPlaces.keys.toList(),
        'groupOrder': groupOrder ?? groupsMap.keys.toList(),
      };
    });
  }

  /// Sets the entire places map (overwrites all places and assignments)
  Future<void> setCleaning(Map<String, dynamic> places) async {
    // Persist places and explicit order while preserving existing groups
    final snapshot = await _docRef.get();
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final groups = Map<String, dynamic>.from(data['groups'] ?? {});
    final order = places.keys.toList();
    await _docRef.set({'places': places, 'order': order, 'groups': groups, 'groupOrder': data['groupOrder'] ?? groups.keys.toList()});
  }

  /// Adds a new place with a generated id
  Future<String> addPlace(String name) async {
    final id = const Uuid().v4();
    final snapshot = await _docRef.get();
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final places = Map<String, dynamic>.from(data['places'] ?? {});
    final groups = Map<String, dynamic>.from(data['groups'] ?? {});
    final order = (data['order'] as List?)?.cast<String>() ?? places.keys.toList();
    // determine max existing pos
    int maxPos = -1;
    for (final v in places.values) {
      if (v is Map && v['pos'] is int) {
        final p = v['pos'] as int;
        if (p > maxPos) maxPos = p;
      }
    }
    final pos = maxPos + 1;
    places[id] = {'name': name, 'assignees': <String>[], 'group': null, 'pos': pos};
    order.add(id);
    await _docRef.set({'places': places, 'order': order, 'groups': groups, 'groupOrder': data['groupOrder'] ?? groups.keys.toList()});
    return id;
  }

  /// Deletes a place by id
  Future<void> deletePlace(String placeId) async {
    final snapshot = await _docRef.get();
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final places = Map<String, dynamic>.from(data['places'] ?? {});
    final groups = Map<String, dynamic>.from(data['groups'] ?? {});
    final order = (data['order'] as List?)?.cast<String>() ?? places.keys.toList();
    places.remove(placeId);
    order.remove(placeId);
    // Also remove from any group's places list if present
    for (final g in groups.entries) {
      final gMap = Map<String, dynamic>.from(g.value as Map<String, dynamic>);
      final plist = (gMap['places'] as List?)?.cast<String>() ?? [];
      if (plist.contains(placeId)) {
        plist.remove(placeId);
        gMap['places'] = plist;
        groups[g.key] = gMap;
      }
    }
    await _docRef.set({'places': places, 'order': order, 'groups': groups, 'groupOrder': data['groupOrder'] ?? groups.keys.toList()});
  }

  /// Updates a place's name
  Future<void> updatePlace(String placeId, String newName) async {
    final snapshot = await _docRef.get();
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final places = Map<String, dynamic>.from(data['places'] ?? {});
    if (places[placeId] != null) {
      places[placeId]['name'] = newName;
      final groups = Map<String, dynamic>.from(data['groups'] ?? {});
      // preserve existing order if present
      final order = (data['order'] as List?)?.cast<String>() ?? places.keys.toList();
      await _docRef.set({'places': places, 'order': order, 'groups': groups, 'groupOrder': data['groupOrder'] ?? groups.keys.toList()});
    }
  }

  /// Adds a new group with a generated id
  Future<String> addGroup(String title) async {
    final id = const Uuid().v4();
    final snapshot = await _docRef.get();
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final groups = Map<String, dynamic>.from(data['groups'] ?? {});
    final groupOrder = (data['groupOrder'] as List?)?.cast<String>() ?? groups.keys.toList();
    groups[id] = {'title': title, 'places': <String>[]};
    groupOrder.add(id);
    await _docRef.set({'places': data['places'] ?? {}, 'order': data['order'] ?? (data['places'] as Map?)?.keys.toList() ?? [], 'groups': groups, 'groupOrder': groupOrder});
    return id;
  }

  /// Updates a group's title
  Future<void> updateGroup(String groupId, String newTitle) async {
    final snapshot = await _docRef.get();
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final groups = Map<String, dynamic>.from(data['groups'] ?? {});
    if (groups.containsKey(groupId)) {
      final g = Map<String, dynamic>.from(groups[groupId] as Map<String, dynamic>);
      g['title'] = newTitle;
      groups[groupId] = g;
      await _docRef.set({'places': data['places'] ?? {}, 'order': data['order'] ?? (data['places'] as Map?)?.keys.toList() ?? [], 'groups': groups, 'groupOrder': data['groupOrder'] ?? groups.keys.toList()});
    }
  }

  /// Deletes a group and removes references from places
  Future<void> deleteGroup(String groupId) async {
    final snapshot = await _docRef.get();
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final groups = Map<String, dynamic>.from(data['groups'] ?? {});
    final places = Map<String, dynamic>.from(data['places'] ?? {});
    final groupOrder = (data['groupOrder'] as List?)?.cast<String>() ?? groups.keys.toList();
    if (groups.containsKey(groupId)) {
      groups.remove(groupId);
      groupOrder.remove(groupId);
      // Remove group reference from places
      for (final pid in places.keys) {
        if (places[pid] is Map && (places[pid]['group'] == groupId)) {
          places[pid]['group'] = null;
        }
      }
      await _docRef.set({'places': places, 'order': data['order'] ?? places.keys.toList(), 'groups': groups, 'groupOrder': groupOrder});
    }
  }

  Future<void> setGroups(Map<String, dynamic> groups) async {
    final snapshot = await _docRef.get();
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    await _docRef.set({'places': data['places'] ?? {}, 'order': data['order'] ?? (data['places'] as Map?)?.keys.toList() ?? [], 'groups': groups, 'groupOrder': (groups.keys.toList())});
  }
}