// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PackManifest _$PackManifestFromJson(
  Map<String, dynamic> json,
) => _PackManifest(
  packId: json['packId'] as String,
  mbtilesRefs:
      (json['mbtilesRefs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  gpxRefs:
      (json['gpxRefs'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  poiRefs:
      (json['poiRefs'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  townGuideRefs:
      (json['townGuideRefs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  waypointsSnapshotRef: json['waypointsSnapshotRef'] as String,
  tailleMo: (json['tailleMo'] as num).toInt(),
  checksum: json['checksum'] as String?,
);

Map<String, dynamic> _$PackManifestToJson(_PackManifest instance) =>
    <String, dynamic>{
      'packId': instance.packId,
      'mbtilesRefs': instance.mbtilesRefs,
      'gpxRefs': instance.gpxRefs,
      'poiRefs': instance.poiRefs,
      'townGuideRefs': instance.townGuideRefs,
      'waypointsSnapshotRef': instance.waypointsSnapshotRef,
      'tailleMo': instance.tailleMo,
      'checksum': instance.checksum,
    };
