import 'package:cloud_firestore/cloud_firestore.dart';

class KantinFirestoreService {
  final String placeId;
  KantinFirestoreService(this.placeId);

  /// Stream of all user debts in kantin for a place (real-time updates)
  Stream<Map<String, double>> kantinStream() {
    return FirebaseFirestore.instance
      .collection('places')
      .doc(placeId)
      .collection('kantin')
      .snapshots()
      .map((snapshot) {
        final Map<String, double> debts = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final debt = (data['debt'] ?? 0).toDouble();
          debts[doc.id] = debt;
        }
        return debts;
      });
  }

  /// Update the debt for a specific user in kantin
  Future<void> updateUserDebt(String userUid, double debt) async {
    await FirebaseFirestore.instance
      .collection('places')
      .doc(placeId)
      .collection('kantin')
      .doc(userUid)
      .set({'debt': debt}, SetOptions(merge: true));
  }
}
