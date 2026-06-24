import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'place_model.freezed.dart';
part 'place_model.g.dart';

@freezed
class PlaceModel with _$PlaceModel {
  const PlaceModel._();

  const factory PlaceModel({
    required String id,
    required String name,
    String? displayName,
    String? description,
    String? imageUrl,
    String? mapsUrl,
    @Default(false) bool registrationMode,
  }) = _PlaceModel;

  factory PlaceModel.fromJson(Map<String, dynamic> json) => _$PlaceModelFromJson(json);

  factory PlaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlaceModel.fromJson(data..['id'] = doc.id);
  }

  Map<String, dynamic> toMap() => toJson()..remove('id');

  static PlaceModel? findById(List<PlaceModel> places, String id) {
    try {
      return places.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

