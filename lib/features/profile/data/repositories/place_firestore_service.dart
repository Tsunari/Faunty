import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faunty/features/profile/domain/entities/place_model.dart';

class PlaceFirestoreService {
  static final _placesRef = FirebaseFirestore.instance.collection('places');

  /// Ensures at least one place exists in Firestore. If none, creates a default place.
  /// Not used right now but can be called during app initialization if needed.
  // static Future<void> ensureAtLeastOnePlaceExists() async {
  //   final snapshot = await _placesRef.limit(1).get();
  //   if (snapshot.docs.isEmpty) {
  //     final defaultPlace = PlaceModel(
  //       id: '', // Firestore will auto-generate ID
  //       name: 'main',
  //       displayName: 'Main Place',
  //       registrationMode: false,
  //     );
  //     await _placesRef.add(defaultPlace.toMap());
  //   }
  // }

  static Future<List<PlaceModel>> fetchPlaces() async {
  // Order by createdAt to ensure newly created places appear at the end (append behavior)
  final snapshot = await _placesRef.orderBy('createdAt').get();
  return snapshot.docs.map((doc) => PlaceModel.fromFirestore(doc)).toList();
  }

  static Stream<List<PlaceModel>> placesStream() {
  // Stream ordered by createdAt so new places show up appended
  return _placesRef.orderBy('createdAt').snapshots().map((snapshot) =>
    snapshot.docs.map((doc) => PlaceModel.fromFirestore(doc)).toList());
  }

  static Future<PlaceModel?> getPlaceById(String id) async {
    final doc = await _placesRef.doc(id).get();
    if (!doc.exists) return null;
    return PlaceModel.fromFirestore(doc);
  }

  static Future<void> addPlace(PlaceModel place) async {
  // Add a server timestamp so places can be ordered and new ones are appended
  final data = Map<String, dynamic>.from(place.toMap());
  data['createdAt'] = FieldValue.serverTimestamp();
  await _placesRef.add(data);
  }

  static Future<void> updatePlace(String id, Map<String, dynamic> data) async {
    await _placesRef.doc(id).update(data);
  }

  static Future<void> deletePlace(String id) async {
    await _placesRef.doc(id).delete();
  }
}