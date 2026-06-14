// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'defi_saisonnier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DefiSaisonnier _$DefiSaisonnierFromJson(Map<String, dynamic> json) =>
    _DefiSaisonnier(
      id: json['id'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String,
      debut: DateTime.parse(json['debut'] as String),
      fin: DateTime.parse(json['fin'] as String),
      typeObjectif: json['typeObjectif'] as String,
      cible: (json['cible'] as num).toDouble(),
    );

Map<String, dynamic> _$DefiSaisonnierToJson(_DefiSaisonnier instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titre': instance.titre,
      'description': instance.description,
      'debut': instance.debut.toIso8601String(),
      'fin': instance.fin.toIso8601String(),
      'typeObjectif': instance.typeObjectif,
      'cible': instance.cible,
    };
