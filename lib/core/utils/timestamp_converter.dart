import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is Map) {
      // Handles {_seconds: ..., _nanoseconds: ...} structure from Firestore Emulator / REST API
      final seconds = json['_seconds'] as int?;
      final nanoseconds = json['_nanoseconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000,
        );
      }
    }
    return DateTime.now();
  }

  @override
  dynamic toJson(DateTime date) => Timestamp.fromDate(date);
}

class NullableTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is Map) {
      final seconds = json['_seconds'] as int?;
      final nanoseconds = json['_nanoseconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000,
        );
      }
    }
    return null;
  }

  @override
  dynamic toJson(DateTime? date) => date == null ? null : Timestamp.fromDate(date);
}
