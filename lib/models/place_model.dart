import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceModel {
  /// Firestore document ID, used as canonical placeId everywhere
  final String id;
  final String name;
  final String? displayName;
  final String? description;
  final String? imageUrl;
  final String? mapsUrl;
  final bool registrationMode;

  PlaceModel({
    required this.id,
    required this.name,
    this.displayName,
    this.mapsUrl,
    this.description,
    this.imageUrl,
    this.registrationMode = false,
  });

  /// Helper: Find a PlaceModel by id from a list
  static PlaceModel? findById(List<PlaceModel> places, String id) {
    try {
      return places.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  factory PlaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlaceModel(
      id: doc.id,
      name: data['name'] ?? '',
      displayName: data['displayName'],
      mapsUrl: data['mapsUrl'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      registrationMode: data['registrationMode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (displayName != null) 'displayName': displayName,
      if (mapsUrl != null) 'mapsUrl': mapsUrl,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'registrationMode': registrationMode,
    };
  }
}
