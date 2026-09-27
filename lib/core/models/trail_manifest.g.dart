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
      fiche: json['fiche'] == null
          ? null
          : TrailManifestFiche.fromJson(json['fiche'] as Map<String, dynamic>),
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
      'fiche': instance.fiche?.toJson(),
    };

_TrailManifestFiche _$TrailManifestFicheFromJson(Map<String, dynamic> json) =>
    _TrailManifestFiche(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      tagline: json['tagline'] as String,
      region: json['region'] as String,
      country: json['country'] as String,
      totalStages: (json['totalStages'] as num).toInt(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      totalElevationGain: (json['totalElevationGain'] as num).toInt(),
      primaryColorValue: (json['primaryColorValue'] as num?)?.toInt(),
      secondaryColorValue: (json['secondaryColorValue'] as num?)?.toInt(),
      priceStages: (json['priceStages'] as num?)?.toInt(),
      directions: (json['directions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      availableDurations: (json['availableDurations'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      defaultDuration: (json['defaultDuration'] as num?)?.toInt(),
      emergencyNumbers: (json['emergencyNumbers'] as List<dynamic>?)
          ?.map((e) => FicheNumeroSecours.fromJson(e as Map<String, dynamic>))
          .toList(),
      privacyPolicyUrl: json['privacyPolicyUrl'] as String?,
    );

Map<String, dynamic> _$TrailManifestFicheToJson(_TrailManifestFiche instance) =>
    <String, dynamic>{
      'name': instance.name,
      'displayName': instance.displayName,
      'tagline': instance.tagline,
      'region': instance.region,
      'country': instance.country,
      'totalStages': instance.totalStages,
      'totalDistanceKm': instance.totalDistanceKm,
      'totalElevationGain': instance.totalElevationGain,
      'primaryColorValue': instance.primaryColorValue,
      'secondaryColorValue': instance.secondaryColorValue,
      'priceStages': instance.priceStages,
      'directions': instance.directions,
      'availableDurations': instance.availableDurations,
      'defaultDuration': instance.defaultDuration,
      'emergencyNumbers': instance.emergencyNumbers
          ?.map((e) => e.toJson())
          .toList(),
      'privacyPolicyUrl': instance.privacyPolicyUrl,
    };

_FicheNumeroSecours _$FicheNumeroSecoursFromJson(Map<String, dynamic> json) =>
    _FicheNumeroSecours(
      name: json['name'] as String,
      phone: json['phone'] as String,
    );

Map<String, dynamic> _$FicheNumeroSecoursToJson(_FicheNumeroSecours instance) =>
    <String, dynamic>{'name': instance.name, 'phone': instance.phone};
