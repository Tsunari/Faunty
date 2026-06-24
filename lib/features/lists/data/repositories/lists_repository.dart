import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:faunty/core/network/firebase_providers.dart';
import 'package:faunty/features/auth/domain/entities/user_entity.dart';
import 'package:faunty/features/lists/data/repositories/catering_firestore_service.dart';
import 'package:faunty/features/lists/data/repositories/cleaning_firestore_service.dart';
import 'package:faunty/features/lists/data/repositories/custom_list_firestore_service.dart';
import 'package:faunty/features/lists/data/repositories/program_firestore_service.dart';

part 'lists_repository.g.dart';

class ListsRepository {
  final FirebaseFirestore _firestore;

  ListsRepository(this._firestore);

  CateringFirestoreService getCateringService(UserEntity user) =>
      CateringFirestoreService(user);

  CleaningFirestoreService getCleaningService(UserEntity user) =>
      CleaningFirestoreService(user);

  CustomListFirestoreService getCustomListService() =>
      CustomListFirestoreService(firestore: _firestore);

  ProgramFirestoreService getProgramService(UserEntity user) =>
      ProgramFirestoreService(user);
}

@riverpod
ListsRepository listsRepository(ListsRepositoryRef ref) {
  return ListsRepository(ref.watch(firestoreProvider));
}
