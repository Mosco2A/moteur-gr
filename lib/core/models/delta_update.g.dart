// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delta_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeltaUpdate _$DeltaUpdateFromJson(Map<String, dynamic> json) => _DeltaUpdate(
  trailId: json['trailId'] as String,
  fromVersion: const HorodatageServeurJson().fromJson(json['fromVersion']),
  toVersion: const HorodatageServeurJson().fromJson(json['toVersion']),
  downloadSize: (json['downloadSize'] as num).toInt(),
);

Map<String, dynamic> _$DeltaUpdateToJson(_DeltaUpdate instance) =>
    <String, dynamic>{
      'trailId': instance.trailId,
      'fromVersion': const HorodatageServeurJson().toJson(instance.fromVersion),
      'toVersion': const HorodatageServeurJson().toJson(instance.toVersion),
      'downloadSize': instance.downloadSize,
    };

_ResultatSynchronisation _$ResultatSynchronisationFromJson(
  Map<String, dynamic> json,
) => _ResultatSynchronisation(
  famillesTouchees: (json['famillesTouchees'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  ecrits: (json['ecrits'] as num).toInt(),
  supprimes: (json['supprimes'] as num).toInt(),
  revisionAtteinte: const HorodatageServeurJson().fromJson(
    json['revisionAtteinte'],
  ),
);

Map<String, dynamic> _$ResultatSynchronisationToJson(
  _ResultatSynchronisation instance,
) => <String, dynamic>{
  'famillesTouchees': instance.famillesTouchees,
  'ecrits': instance.ecrits,
  'supprimes': instance.supprimes,
  'revisionAtteinte': const HorodatageServeurJson().toJson(
    instance.revisionAtteinte,
  ),
};
