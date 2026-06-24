import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SurveyFirestoreService {
  final String placeId;
  SurveyFirestoreService(this.placeId);

  CollectionReference get _surveyCollection => FirebaseFirestore.instance
      .collection('places')
      .doc(placeId)
      .collection('surveys');

  /// Stream of all surveys for a place (real-time updates)
  Stream<List<Map<String, dynamic>>> surveyStream() {
    return _surveyCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Add a new survey
  Future<void> addSurvey(Map<String, dynamic> survey) async {
    // Ensure createdBy is set to the current user uid if not already provided
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    survey['createdBy'] = survey['createdBy'] ?? uid;
    // Also set a server timestamp for createdAt if not provided
    survey['createdAt'] = survey['createdAt'] ?? FieldValue.serverTimestamp();
    await _surveyCollection.add(survey);
  }

  /// Update an existing survey
  Future<void> updateSurvey(String surveyId, Map<String, dynamic> data) async {
    // Ensure we stamp updates with the server timestamp
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _surveyCollection.doc(surveyId).update(data);
  }

  /// Increment vote for an option
  Future<void> incrementVote(String surveyId, String optionValue, {required String userId}) async {
    final docRef = _surveyCollection.doc(surveyId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      final options = List<Map<String, dynamic>>.from(data['options'] ?? []);
      for (var option in options) {
        if (option['value'] == optionValue) {
          final users = List<String>.from(option['users'] ?? []);
          // Only increment if the user isn't already present
          if (!users.contains(userId)) {
            option['voteCount'] = ((option['voteCount'] ?? 0) as num).toInt() + 1;
            users.add(userId);
            option['users'] = users;
          }
        }
      }
      transaction.update(docRef, {'options': options});
    });
  }

  /// Decrement vote for an option
  Future<void> decrementVote(String surveyId, String optionValue, {required String userId}) async {
    final docRef = _surveyCollection.doc(surveyId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      final options = List<Map<String, dynamic>>.from(data['options'] ?? []);
      for (var option in options) {
        if (option['value'] == optionValue) {
          final users = List<String>.from(option['users'] ?? []);
          // Only decrement if the user was present
          if (users.contains(userId)) {
            users.remove(userId);
            final current = (option['voteCount'] ?? 0) as num;
            final newCount = (current.toInt() - 1) < 0 ? 0 : (current.toInt() - 1);
            option['voteCount'] = newCount;
            option['users'] = users;
          }
        }
      }
      transaction.update(docRef, {'options': options});
    });
  }

  /// Select an option (single choice)
  Future<void> selectOption(String surveyId, String optionValue, {required String userId}) async {
    final docRef = _surveyCollection.doc(surveyId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      final options = List<Map<String, dynamic>>.from(data['options'] ?? []);
      // Remove user from all options first and decrement voteCount where necessary.
      for (var option in options) {
        final users = List<String>.from(option['users'] ?? []);
        final hadUser = users.contains(userId);
        if (hadUser) {
          users.remove(userId);
          final current = (option['voteCount'] ?? 0) as num;
          final newCount = (current.toInt() - 1) < 0 ? 0 : (current.toInt() - 1);
          option['voteCount'] = newCount;
        }
        option['users'] = users;
        // If this is the target option, add user and increment after removals
        if (option['value'] == optionValue) {
          final users2 = List<String>.from(option['users'] ?? []);
          // Only increment if user is not already present after removals
          if (!users2.contains(userId)) {
            final vc = (option['voteCount'] ?? 0) as num;
            option['voteCount'] = vc.toInt() + 1;
            users2.add(userId);
            option['users'] = users2;
          }
        }
      }
      transaction.update(docRef, {'options': options});
    });
  }

  /// Delete a survey
  Future<void> deleteSurvey(String surveyId) async {
    await _surveyCollection.doc(surveyId).delete();
  }
}
