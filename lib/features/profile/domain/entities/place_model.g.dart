// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlaceModelImpl _$$PlaceModelImplFromJson(Map<String, dynamic> json) =>
    _$PlaceModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      mapsUrl: json['mapsUrl'] as String?,
      registrationMode: json['registrationMode'] as bool? ?? false,
    );

Map<String, dynamic> _$$PlaceModelImplToJson(_$PlaceModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'displayName': instance.displayName,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'mapsUrl': instance.mapsUrl,
      'registrationMode': instance.registrationMode,
    };
