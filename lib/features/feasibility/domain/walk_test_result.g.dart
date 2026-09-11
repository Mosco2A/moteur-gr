// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walk_test_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalkTestResult _$WalkTestResultFromJson(Map<String, dynamic> json) =>
    _WalkTestResult(
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      level: json['level'] as String,
      takenAt: DateTime.parse(json['takenAt'] as String),
    );

Map<String, dynamic> _$WalkTestResultToJson(_WalkTestResult instance) =>
    <String, dynamic>{
      'distanceMeters': instance.distanceMeters,
      'level': instance.level,
      'takenAt': instance.takenAt.toIso8601String(),
    };
