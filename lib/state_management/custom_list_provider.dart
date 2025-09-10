import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/firestore/custom_list_firestore_service.dart';
import 'package:faunty/models/custom_list.dart';

class ListKey {
  final String placeId;
  final String listId;
  const ListKey(this.placeId, this.listId);
  @override
  bool operator ==(Object other) => other is ListKey && other.placeId == placeId && other.listId == listId;
  @override
  int get hashCode => Object.hash(placeId, listId);
}

final customListServiceProvider = Provider<CustomListFirestoreService>((ref) {
  return CustomListFirestoreService(firestore: FirebaseFirestore.instance);
});

final customListsProvider = StreamProvider.family<List<CustomList>, String>((ref, placeId) {
  final svc = ref.read(customListServiceProvider);
  return svc.streamListsForPlace(placeId);
});

final customListItemsProvider = StreamProvider.family<List<ListItem>, ListKey>((ref, key) {
  final svc = ref.read(customListServiceProvider);
  return svc.streamListItems(key.placeId, key.listId);
});

final customListActionsProvider = Provider<CustomListFirestoreService>((ref) => ref.read(customListServiceProvider));
