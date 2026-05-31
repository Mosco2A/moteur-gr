// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delta_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeltaUpdate _$DeltaUpdateFromJson(Map<String, dynamic> json) => _DeltaUpdate(
      trailId: json['trailId'] as String,
      fromVersion: (json['fromVersion'] as num).toInt(),
      toVersion: (json['toVersion'] as num).toInt(),
      changedTables: (json['changedTables'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      downloadSize: (json['downloadSize'] as num).toInt(),
    );

Map<String, dynamic> _$DeltaUpdateToJson(_DeltaUpdate instance) =>
    <String, dynamic>{
      'trailId': instance.trailId,
      'fromVersion': instance.fromVersion,
      'toVersion': instance.toVersion,
      'changedTables': instance.changedTables,
      'downloadSize': instance.downloadSize,
    };
