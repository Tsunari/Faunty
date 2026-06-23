import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalsFirestoreService {
  final String placeId;
  GlobalsFirestoreService(this.placeId);

  /// Stream of the entire globals document for a place (real-time updates)
  Stream<Map<String, dynamic>> globalsStream() {
    return FirebaseFirestore.instance
      .collection('places')
      .doc(placeId)
      .snapshots()
      .map((doc) => doc.data() ?? {});
  }

  /// Update any field in the globals document
  Future<void> setGlobalField(String key, dynamic value) async {
    await FirebaseFirestore.instance
      .collection('places')
      .doc(placeId)
      .set({key: value}, SetOptions(merge: true));
  }

  /// Convenience: update multiple fields at once
  Future<void> setGlobals(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
      .collection('places')
      .doc(placeId)
      .set(data, SetOptions(merge: true));
  }
}
