import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/models/custom_list.dart';

class CustomListFirestoreService {
  final FirebaseFirestore _db;
  CustomListFirestoreService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference _listsRef(String placeId) => _db.collection('places').doc(placeId).collection('custom_lists');

  Stream<List<CustomList>> streamListsForPlace(String placeId) {
    return _listsRef(placeId).orderBy('order').snapshots().map((snap) {
      return snap.docs.map((d) => CustomList.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<String> createList(String placeId, CustomList list) async {
    // If the caller left order at a high default, compute next order as max+1
    var order = list.order;
    if (order == 0 || order >= 9000) {
      final snap = await _listsRef(placeId).orderBy('order', descending: true).limit(1).get();
      if (snap.docs.isNotEmpty) {
        final max = (snap.docs.first.data() as Map<String, dynamic>)['order'] as int? ?? 0;
        order = max + 1;
      } else {
        order = 0;
      }
    }
    final data = {...list.toMap(), 'order': order, 'createdAt': FieldValue.serverTimestamp()};
    final doc = await _listsRef(placeId).add(data);
    return doc.id;
  }

  Future<void> updateList(String placeId, String listId, Map<String, dynamic> patch) async {
    await _listsRef(placeId).doc(listId).update(patch);
  }

  Future<void> deleteList(String placeId, String listId) async {
    // delete subcollection items first (paginated) - simple approach: delete items in small batches
    final itemsRef = _listsRef(placeId).doc(listId).collection('items');
    final batchSize = 100;
    while (true) {
      final snap = await itemsRef.limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final d in snap.docs) batch.delete(d.reference);
      await batch.commit();
      if (snap.docs.length < batchSize) break;
    }
    await _listsRef(placeId).doc(listId).delete();
  }

  Stream<List<ListItem>> streamListItems(String placeId, String listId) {
    final itemsRef = _listsRef(placeId).doc(listId).collection('items');
    return itemsRef.orderBy('order').snapshots().map((snap) {
      return snap.docs.map((d) => ListItem.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<String> addItem(String placeId, String listId, Map<String, dynamic> payload, {int? order}) async {
    final itemsRef = _listsRef(placeId).doc(listId).collection('items');
    final docRef = itemsRef.doc();
    final now = FieldValue.serverTimestamp();
    final data = {
      'payload': payload,
      'order': order ?? 0,
      'createdAt': now,
    };
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateItem(String placeId, String listId, String itemId, Map<String, dynamic> patch) async {
    await _listsRef(placeId).doc(listId).collection('items').doc(itemId).update(patch);
  }

  Future<void> deleteItem(String placeId, String listId, String itemId) async {
    await _listsRef(placeId).doc(listId).collection('items').doc(itemId).delete();
  }

  Future<void> reorderItems(String placeId, String listId, List<String> orderedItemIds) async {
    final batch = _db.batch();
    final itemsRef = _listsRef(placeId).doc(listId).collection('items');
    for (var i = 0; i < orderedItemIds.length; i++) {
      final docRef = itemsRef.doc(orderedItemIds[i]);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  /// Migration helper: Convert any items that store a subsection (payload.type=='subsection' with payload.rows)
  /// into separate item documents where each row becomes its own item (type: 'assignment').
  /// This is a best-effort migration and preserves relative ordering by appending new rows at the end.
  Future<void> migrateSubsectionsToPerRow(String placeId, String listId) async {
    final itemsRef = _listsRef(placeId).doc(listId).collection('items');

    // find current max order to append new rows after existing items
    final maxSnap = await itemsRef.orderBy('order', descending: true).limit(1).get();
    int maxOrder = 0;
    if (maxSnap.docs.isNotEmpty) {
      maxOrder = maxSnap.docs.first.data()['order'] as int? ?? 0;
      // start new items after maxOrder
    }

    final all = await itemsRef.orderBy('order').get();
    for (final doc in all.docs) {
      final data = doc.data();
      final payload = data['payload'] as Map<String, dynamic>?;
      final type = payload?['type'] as String? ?? 'assignment';
      if (type == 'subsection') {
        final rows = (payload?['rows'] as List<dynamic>?) ?? [];
        // create new docs for each row
        for (final row in rows) {
          maxOrder++;
          final rowMap = row as Map<String, dynamic>?;
          final Map<String, dynamic> rowPayload = {
            'type': 'assignment',
            'left': rowMap?['left'] ?? '',
            'right': rowMap?['right'] ?? '',
          };
          await itemsRef.add({
            'payload': rowPayload,
            'order': maxOrder,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        // delete the old subsection document
        await itemsRef.doc(doc.id).delete();
      }
    }
  }

  /// Update a specific field inside a row of a subsection item document.
  /// rowIndex is the index inside payload['rows'] for that document.
  Future<void> updateRowInItem(String placeId, String listId, String itemId, int rowIndex, String field, dynamic value) async {
    final docRef = _listsRef(placeId).doc(listId).collection('items').doc(itemId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw Exception('item not found');
      final data = snap.data() as Map<String, dynamic>;
      final payload = Map<String, dynamic>.from(data['payload'] as Map<String, dynamic>? ?? {});
      final rows = List<dynamic>.from((payload['rows'] as List<dynamic>?) ?? []);
      if (rowIndex < 0 || rowIndex >= rows.length) throw Exception('rowIndex out of range');
      final row = Map<String, dynamic>.from(rows[rowIndex] as Map<String, dynamic>);
      row[field] = value;
      rows[rowIndex] = row;
      payload['rows'] = rows;
      tx.update(docRef, {'payload': payload, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }
}
