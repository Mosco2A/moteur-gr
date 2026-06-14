import 'package:freezed_annotation/freezed_annotation.dart';

part 'town_guide.freezed.dart';
part 'town_guide.g.dart';

/// Categories d'une section de town guide (F8C-01, Phase 8 P8-C).
///
/// Modele FarOut « town guides » (A3-7) : infos pratiques d'une ville/village
/// d'etape regroupees par theme (ravitaillement, hebergement, transport,
/// services, eau, sante).
///
/// String extensible volontairement (meme principe que [PackType] F8B-01) : une
/// categorie inconnue recue d'un futur catalogue serveur retombe sur [fallback]
/// sans planter — le moteur reste generique (#84627).
abstract final class GuideCategory {
  /// Ravitaillement (epiceries, marches, points d'approvisionnement).
  static const String ravitaillement = 'ravitaillement';

  /// Hebergement (refuges, gites, hotels, campings).
  static const String hebergement = 'hebergement';

  /// Transport (bus, navettes, taxis, gares).
  static const String transport = 'transport';

  /// Services (poste, banque, laverie, pharmacie hors urgence).
  static const String services = 'services';

  /// Points d'eau potable de la localite.
  static const String eau = 'eau';

  /// Sante (medecin, pharmacie, secours de proximite).
  static const String sante = 'sante';

  /// Valeur de repli pour une categorie inconnue.
  static const String fallback = services;

  /// Toutes les categories connues, dans l'ordre d'affichage recommande.
  static const List<String> values = [
    ravitaillement,
    hebergement,
    transport,
    services,
    eau,
    sante,
  ];

  /// Normalise [value] vers une categorie connue, ou [fallback] sinon.
  static String fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Coordonnees geographiques d'un item de guide (F8C-01).
///
/// Optionnelles sur un [GuideItem] : presentes quand le prestataire a une
/// position cartographiable (affichable sur la carte du sentier), absentes
/// sinon (ex : une ligne de bus sans point fixe).
@freezed
abstract class GuideCoordinates with _$GuideCoordinates {
  const factory GuideCoordinates({
    /// Latitude en degres decimaux (WGS84).
    required double latitude,

    /// Longitude en degres decimaux (WGS84).
    required double longitude,
  }) = _GuideCoordinates;

  /// Deserialisation depuis JSON (contenu offline du pack).
  factory GuideCoordinates.fromJson(Map<String, dynamic> json) =>
      _$GuideCoordinatesFromJson(json);
}

/// Item concret d'une section de town guide (F8C-01, Phase 8 P8-C).
///
/// Un prestataire/point d'interet pratique (ex : « Epicerie du village »,
/// « Navette 14h »). [deeplinkUrl] permet a l'UI (F8C-02) d'OUVRIR le site/app
/// du prestataire via url_launcher — FACILITATEUR uniquement, AUCUNE reservation
/// ni paiement in-app (decision Chris #84100). [coordonnees] situe l'item sur la
/// carte quand c'est pertinent.
@freezed
abstract class GuideItem with _$GuideItem {
  const GuideItem._();

  const factory GuideItem({
    /// Nom de l'item/prestataire (ex « Epicerie du village »).
    required String nom,

    /// Description courte (horaires, specificites, conseils pratiques).
    required String description,

    /// Lien deeplink SORTANT vers le site/app du prestataire (facilitateur,
    /// #84100). Null = pas de lien (l'UI masque alors le bouton).
    String? deeplinkUrl,

    /// Coordonnees de l'item si cartographiable (null sinon).
    GuideCoordinates? coordonnees,
  }) = _GuideItem;

  /// Vrai si l'item expose un lien deeplink sortant (bouton facilitateur F8C-02).
  bool get hasDeeplink => deeplinkUrl != null && deeplinkUrl!.isNotEmpty;

  /// Deserialisation depuis JSON (contenu offline du pack).
  factory GuideItem.fromJson(Map<String, dynamic> json) =>
      _$GuideItemFromJson(json);
}

/// Section thematique d'un town guide (F8C-01, Phase 8 P8-C).
///
/// Regroupe les [GuideItem] d'une meme [categorie] (ravitaillement, hebergement,
/// transport, services, eau, sante). [titre] et [contenu] sont des libelles deja
/// LOCALISES (resolus a la construction des donnees, comme le catalogue de packs
/// F8B-01) — le domaine reste pur, aucun texte en dur cote moteur.
@freezed
abstract class GuideSection with _$GuideSection {
  const GuideSection._();

  const factory GuideSection({
    /// Categorie de la section ([GuideCategory]).
    required String categorie,

    /// Titre localise de la section (ex « Ravitaillement »).
    required String titre,

    /// Contenu introductif localise (paragraphe d'en-tete, peut etre vide).
    @Default('') String contenu,

    /// Items de la section (prestataires/points pratiques).
    @Default(<GuideItem>[]) List<GuideItem> items,
  }) = _GuideSection;

  /// Categorie normalisee vers une valeur connue ([GuideCategory.fromString]).
  String get normalizedCategorie => GuideCategory.fromString(categorie);

  /// Deserialisation depuis JSON (contenu offline du pack).
  factory GuideSection.fromJson(Map<String, dynamic> json) =>
      _$GuideSectionFromJson(json);
}

/// Town guide d'une ville/village d'etape (F8C-01, Phase 8 P8-C, offline R3).
///
/// Infos pratiques d'une localite du sentier (modele FarOut « town guides »,
/// A3-7), consultees 100 % OFFLINE : le contenu est embarque dans le pack via
/// [PackManifest.townGuideRefs] (F8B-01) et rapatrie AVANT le depart (R3). Le
/// moteur reste generique (#84627) : [trailId] rattache le guide a un sentier,
/// AUCUNE localite n'est hardcodee.
///
/// Donnees fictives en P2-P3 (#84627). [latitude]/[longitude] situent la
/// localite sur la carte du sentier.
@freezed
abstract class TownGuide with _$TownGuide {
  const TownGuide._();

  const factory TownGuide({
    /// Identifiant unique du guide (ex 'mam_corte').
    required String id,

    /// Identifiant du sentier auquel ce guide appartient (genericite #84627).
    required String trailId,

    /// Nom du lieu (ville/village d'etape, ex « Corte »).
    required String nomLieu,

    /// Latitude de la localite en degres decimaux (WGS84).
    required double latitude,

    /// Longitude de la localite en degres decimaux (WGS84).
    required double longitude,

    /// Sections thematiques du guide (ravitaillement, hebergement, etc.).
    @Default(<GuideSection>[]) List<GuideSection> sections,
  }) = _TownGuide;

  /// Vrai si le guide contient au moins une section avec du contenu.
  bool get hasContent => sections.any((s) => s.items.isNotEmpty);

  /// Categories couvertes par ce guide (ordre des sections), normalisees.
  List<String> get categories =>
      sections.map((s) => s.normalizedCategorie).toList(growable: false);

  /// Retourne la section de [categorie] si presente, null sinon.
  GuideSection? sectionFor(String categorie) {
    final normalized = GuideCategory.fromString(categorie);
    for (final section in sections) {
      if (section.normalizedCategorie == normalized) return section;
    }
    return null;
  }

  /// Deserialisation depuis JSON (contenu offline du pack).
  factory TownGuide.fromJson(Map<String, dynamic> json) =>
      _$TownGuideFromJson(json);
}
