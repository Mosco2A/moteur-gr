// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrailManifest _$TrailManifestFromJson(Map<String, dynamic> json) =>
    _TrailManifest(
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      trails: (json['trails'] as List<dynamic>)
          .map((e) => TrailManifestEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TrailManifestToJson(_TrailManifest instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'trails': instance.trails.map((e) => e.toJson()).toList(),
    };

_TrailManifestEntry _$TrailManifestEntryFromJson(Map<String, dynamic> json) =>
    _TrailManifestEntry(
      trailId: json['trailId'] as String,
      dataVersion: (json['dataVersion'] as num).toInt(),
      hash: json['hash'] as String,
      filePath: json['filePath'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      status: json['status'] as String,
      lastUpdated: json['lastUpdated'] as String,
    );

Map<String, dynamic> _$TrailManifestEntryToJson(_TrailManifestEntry instance) =>
    <String, dynamic>{
      'trailId': instance.trailId,
      'dataVersion': instance.dataVersion,
      'hash': instance.hash,
      'filePath': instance.filePath,
      'fileSize': instance.fileSize,
      'status': instance.status,
      'lastUpdated': instance.lastUpdated,
    };
