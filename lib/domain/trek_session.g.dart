// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trek_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrekSession _$TrekSessionFromJson(Map<String, dynamic> json) => _TrekSession(
  id: json['id'] as String,
  trailId: json['trailId'] as String,
  startedAt: DateTime.parse(json['startedAt'] as String),
  finishedAt: json['finishedAt'] == null
      ? null
      : DateTime.parse(json['finishedAt'] as String),
  status: json['status'] as String? ?? "active",
  completedStages:
      (json['completedStages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  parcoursFullyWalked: json['parcoursFullyWalked'] as bool? ?? false,
);

Map<String, dynamic> _$TrekSessionToJson(_TrekSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trailId': instance.trailId,
      'startedAt': instance.startedAt.toIso8601String(),
      'finishedAt': instance.finishedAt?.toIso8601String(),
      'status': instance.status,
      'completedStages': instance.completedStages,
      'parcoursFullyWalked': instance.parcoursFullyWalked,
    };
