import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/features/lists/data/repositories/custom_list_firestore_service.dart';
import 'package:faunty/features/lists/data/repositories/lists_repository.dart';
import 'package:faunty/features/lists/domain/entities/custom_list.dart';

part 'custom_list_provider.g.dart';

class ListKey {
  final String placeId;
  final String listId;
  const ListKey(this.placeId, this.listId);
  @override
  bool operator ==(Object other) => other is ListKey && other.placeId == placeId && other.listId == listId;
  @override
  int get hashCode => Object.hash(placeId, listId);
}

@riverpod
CustomListFirestoreService customListService(CustomListServiceRef ref) {
  return ref.watch(listsRepositoryProvider).getCustomListService();
}

@riverpod
Stream<List<CustomList>> customLists(CustomListsRef ref, String placeId) {
  return ref.watch(customListServiceProvider).streamListsForPlace(placeId);
}

@riverpod
Stream<List<ListItem>> customListItems(CustomListItemsRef ref, ListKey key) {
  return ref.watch(customListServiceProvider).streamListItems(key.placeId, key.listId);
}

// Legacy alias
final customListActionsProvider = customListServiceProvider;