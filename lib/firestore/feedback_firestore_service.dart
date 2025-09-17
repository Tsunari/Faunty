import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/models/feedback_comment.dart';
import 'package:faunty/models/feedback_report.dart';

class FeedbackFirestoreService {
  final String placeId;
  FeedbackFirestoreService(this.placeId);

  CollectionReference<Map<String, dynamic>> get _reportsCol => FirebaseFirestore.instance
      .collection('places')
      .doc(placeId)
      .collection('feedback_reports');

  CollectionReference<Map<String, dynamic>> _commentsCol(String reportId) => _reportsCol.doc(reportId).collection('comments');

  Stream<List<FeedbackReport>> streamReports({bool includeArchived = false}) {
    // Fetch all and filter client-side; avoids composite index requirement for whereIn + orderBy.
    final q = _reportsCol.orderBy('updatedAt', descending: true);
    return q.snapshots().map((snap) => snap.docs.map((d) => FeedbackReport.fromDoc(d)).toList());
  }

  Future<String> addReport({
    required String title,
    required String description,
    required FeedbackType type,
    required String authorId,
    required String authorName,
    int? severity,
  }) async {
    final now = DateTime.now();
    final doc = await _reportsCol.add({
      'title': title,
      'description': description,
      'type': type.name,
      'status': FeedbackStatus.open.name,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'upvoteCount': 0,
      'upvoterIds': <String>[],
      'severity': severity,
    });
    return doc.id;
  }

  Future<void> updateStatus(String reportId, FeedbackStatus status) async {
    await _reportsCol.doc(reportId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateType(String reportId, FeedbackType type) async {
    await _reportsCol.doc(reportId).update({
      'type': type.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateReportFields(String reportId, Map<String, dynamic> fields) async {
    fields['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _reportsCol.doc(reportId).update(fields);
  }

  Future<void> deleteReport(String reportId) async {
    final commentsSnap = await _commentsCol(reportId).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in commentsSnap.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_reportsCol.doc(reportId));
    await batch.commit();
  }

  Future<void> toggleUpvote(String reportId, String userId) async {
    final ref = _reportsCol.doc(reportId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> upvoterIdsDynamic = data['upvoterIds'] ?? [];
      final upvoterIds = List<String>.from(upvoterIdsDynamic);
      if (upvoterIds.contains(userId)) {
        upvoterIds.remove(userId);
      } else {
        upvoterIds.add(userId);
      }
      tx.update(ref, {
        'upvoterIds': upvoterIds,
        'upvoteCount': upvoterIds.length,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  Stream<List<FeedbackComment>> streamComments(String reportId) {
    return _commentsCol(reportId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FeedbackComment.fromDoc(d)).toList());
  }

  Future<void> addComment({
    required String reportId,
    required String authorId,
    required String authorName,
    required String text,
  }) async {
    await _commentsCol(reportId).add({
      'reportId': reportId,
      'authorId': authorId,
      'authorName': authorName,
      'text': text,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    await _reportsCol.doc(reportId).update({
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateComment(String reportId, String commentId, String newText) async {
    await _commentsCol(reportId).doc(commentId).update({'text': newText});
    await _reportsCol.doc(reportId).update({'updatedAt': Timestamp.fromDate(DateTime.now())});
  }

  Future<void> deleteComment(String reportId, String commentId) async {
    await _commentsCol(reportId).doc(commentId).delete();
    await _reportsCol.doc(reportId).update({'updatedAt': Timestamp.fromDate(DateTime.now())});
  }
}
