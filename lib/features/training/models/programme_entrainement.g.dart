// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'programme_entrainement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SeanceEntrainement _$SeanceEntrainementFromJson(Map<String, dynamic> json) =>
    _SeanceEntrainement(
      jourOffset: (json['jourOffset'] as num).toInt(),
      type: $enumDecode(_$TypeSeanceEnumMap, json['type']),
      dureeMin: (json['dureeMin'] as num).toInt(),
      intensite: $enumDecode(_$IntensiteSeanceEnumMap, json['intensite']),
      description: json['description'] as String,
    );

Map<String, dynamic> _$SeanceEntrainementToJson(_SeanceEntrainement instance) =>
    <String, dynamic>{
      'jourOffset': instance.jourOffset,
      'type': _$TypeSeanceEnumMap[instance.type]!,
      'dureeMin': instance.dureeMin,
      'intensite': _$IntensiteSeanceEnumMap[instance.intensite]!,
      'description': instance.description,
    };

const _$TypeSeanceEnumMap = {
  TypeSeance.marche: 'marche',
  TypeSeance.cardio: 'cardio',
  TypeSeance.renforcement: 'renforcement',
};

const _$IntensiteSeanceEnumMap = {
  IntensiteSeance.faible: 'faible',
  IntensiteSeance.moderee: 'moderee',
  IntensiteSeance.elevee: 'elevee',
};

_ProgrammeEntrainement _$ProgrammeEntrainementFromJson(
  Map<String, dynamic> json,
) => _ProgrammeEntrainement(
  id: json['id'] as String,
  dureeSemaines: (json['dureeSemaines'] as num).toInt(),
  seances: (json['seances'] as List<dynamic>)
      .map((e) => SeanceEntrainement.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProgrammeEntrainementToJson(
  _ProgrammeEntrainement instance,
) => <String, dynamic>{
  'id': instance.id,
  'dureeSemaines': instance.dureeSemaines,
  'seances': instance.seances,
};
