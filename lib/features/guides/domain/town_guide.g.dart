// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'town_guide.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuideCoordinates _$GuideCoordinatesFromJson(Map<String, dynamic> json) =>
    _GuideCoordinates(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$GuideCoordinatesToJson(_GuideCoordinates instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

_GuideItem _$GuideItemFromJson(Map<String, dynamic> json) => _GuideItem(
  nom: json['nom'] as String,
  description: json['description'] as String,
  deeplinkUrl: json['deeplinkUrl'] as String?,
  coordonnees: json['coordonnees'] == null
      ? null
      : GuideCoordinates.fromJson(json['coordonnees'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GuideItemToJson(_GuideItem instance) =>
    <String, dynamic>{
      'nom': instance.nom,
      'description': instance.description,
      'deeplinkUrl': instance.deeplinkUrl,
      'coordonnees': instance.coordonnees?.toJson(),
    };

_GuideSection _$GuideSectionFromJson(Map<String, dynamic> json) =>
    _GuideSection(
      categorie: json['categorie'] as String,
      titre: json['titre'] as String,
      contenu: json['contenu'] as String? ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => GuideItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <GuideItem>[],
    );

Map<String, dynamic> _$GuideSectionToJson(_GuideSection instance) =>
    <String, dynamic>{
      'categorie': instance.categorie,
      'titre': instance.titre,
      'contenu': instance.contenu,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_TownGuide _$TownGuideFromJson(Map<String, dynamic> json) => _TownGuide(
  id: json['id'] as String,
  trailId: json['trailId'] as String,
  nomLieu: json['nomLieu'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  sections:
      (json['sections'] as List<dynamic>?)
          ?.map((e) => GuideSection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <GuideSection>[],
);

Map<String, dynamic> _$TownGuideToJson(_TownGuide instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trailId': instance.trailId,
      'nomLieu': instance.nomLieu,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'sections': instance.sections.map((e) => e.toJson()).toList(),
    };
