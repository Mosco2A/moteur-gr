import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../i18n/translations.g.dart';
import 'tip_theme.dart';

part 'tip_card.freezed.dart';
part 'tip_card.g.dart';

/// Modele immutable representant une fiche conseil contextualisee.
///
/// Supporte i18n 5 langues (fr, en, de, it, es).
/// scope, season, category sont des String extensibles (JAMAIS enum)
/// pour permettre l'ajout de valeurs sans recompilation.
///
/// CALIBRE DU CONTENU (tache 555, retour Chris « fiches conseil toujours aussi
/// light ») : une fiche porte une LISTE DE POINTS ([pointsFr] et ses quatre
/// traductions), pas un paragraphe unique — cinq points autonomes et chiffres,
/// comme les fiches FC01-FC25 du GR20. Le paragraphe unique [contentFr] reste
/// accepte pour les fiches HISTORIQUES non converties : il sert alors de repli et
/// la fiche s'affiche comme un point unique ([localizedPoints]). Aucun ecran ne
/// lit les champs bruts : tout passe par [localizedPoints] / [localizedContent].
@freezed
abstract class TipCard with _$TipCard {
  const TipCard._();

  const factory TipCard({
    /// Identifiant unique de la fiche conseil
    required String id,

    /// Titre -- francais
    required String titleFr,

    /// Titre -- anglais
    @Default('') String titleEn,

    /// Titre -- allemand
    @Default('') String titleDe,

    /// Titre -- italien
    @Default('') String titleIt,

    /// Titre -- espagnol
    @Default('') String titleEs,

    /// POINTS du conseil -- francais. Contenu de reference d'une fiche au
    /// calibre (5 points autonomes et chiffres). Vide -> repli sur [contentFr].
    @Default(<String>[]) List<String> pointsFr,

    /// POINTS du conseil -- anglais.
    @Default(<String>[]) List<String> pointsEn,

    /// POINTS du conseil -- allemand.
    @Default(<String>[]) List<String> pointsDe,

    /// POINTS du conseil -- italien.
    @Default(<String>[]) List<String> pointsIt,

    /// POINTS du conseil -- espagnol.
    @Default(<String>[]) List<String> pointsEs,

    /// Contenu paragraphe -- francais (HISTORIQUE, repli si [pointsFr] est vide)
    @Default('') String contentFr,

    /// Contenu paragraphe -- anglais (HISTORIQUE)
    @Default('') String contentEn,

    /// Contenu paragraphe -- allemand (HISTORIQUE)
    @Default('') String contentDe,

    /// Contenu paragraphe -- italien (HISTORIQUE)
    @Default('') String contentIt,

    /// Contenu paragraphe -- espagnol (HISTORIQUE)
    @Default('') String contentEs,

    /// Perimetre du conseil -- String extensible (gr10, tmb, all, ...)
    @Default('all') String scope,

    /// Saison de pertinence -- String extensible (summer, winter, spring, autumn, all, ...)
    @Default('all') String season,

    /// Categorie du conseil -- String extensible (preparation, equipment, nutrition, safety, nature, recovery, ...)
    @Default('general') String category,

    /// THEME de regroupement (StepWays LOT 5, sous-ensemble C) -- String
    /// extensible : gear/safety/health/weather/refuge/... Les fiches sont
    /// RANGEES PAR THEME (decision Chris #99615). Vide -> derive de [category]
    /// via [TipTheme.fromCategory] (repli, jamais de fiche sans theme).
    @Default('') String theme,

    /// Lien FACEBOOK de la fiche (StepWays LOT 5, C) -- null = pas de bouton FB.
    /// Renvoie vers la fiche/le post equivalent sur le compte de la marque.
    /// AUCUNE url inventee : fournie par la donnee (JSON), jamais en dur.
    String? urlFacebook,

    /// Lien INSTAGRAM de la fiche (StepWays LOT 5, C) -- null = pas de bouton IG.
    String? urlInstagram,

    /// Tags libres pour filtrage supplementaire
    @Default([]) List<String> tags,

    /// Altitude minimale de pertinence en metres (null = pas de filtre altitude)
    int? minAltitudeM,

    /// Chemin vers l asset image associe (null = pas d image)
    String? imageAsset,

    /// Priorite d affichage (plus le nombre est eleve, plus le conseil est prioritaire)
    @Default(0) int priority,
  }) = _TipCard;

  /// Deserialisation depuis JSON
  factory TipCard.fromJson(Map<String, dynamic> json) =>
      _$TipCardFromJson(json);

  /// Theme de regroupement RESOLU (StepWays LOT 5, C) : [theme] s'il est fourni,
  /// sinon derive de [category] ([TipTheme.fromCategory]) — jamais vide.
  String get resolvedTheme =>
      theme.isNotEmpty ? theme : TipTheme.fromCategory(category);

  /// Titre resolu selon la langue courante (i18n INLINE, repli FR base).
  String get localizedTitle =>
      _pick(fr: titleFr, en: titleEn, de: titleDe, it: titleIt, es: titleEs);

  /// POINTS resolus selon la langue courante (i18n INLINE, repli FR base).
  ///
  /// C'est LE contenu qu'un ecran affiche : une fiche au calibre rend ses cinq
  /// points ; une fiche historique (paragraphe unique) rend un point unique, de
  /// sorte qu'aucune fiche ne s'affiche vide pendant la conversion.
  List<String> get localizedPoints {
    final points = _pickList(
      fr: pointsFr,
      en: pointsEn,
      de: pointsDe,
      it: pointsIt,
      es: pointsEs,
    );
    if (points.isNotEmpty) return points;
    final legacy = _pick(
      fr: contentFr,
      en: contentEn,
      de: contentDe,
      it: contentIt,
      es: contentEs,
    );
    return legacy.isEmpty ? const <String>[] : <String>[legacy];
  }

  /// Contenu resolu A PLAT selon la langue courante (apercu, recherche, seed).
  ///
  /// Paragraphe historique s'il existe, sinon les points joints par un retour a
  /// la ligne — jamais vide quand la fiche porte du contenu.
  String get localizedContent {
    final single = _pick(
      fr: contentFr,
      en: contentEn,
      de: contentDe,
      it: contentIt,
      es: contentEs,
    );
    if (single.isNotEmpty) return single;
    return _pickList(
      fr: pointsFr,
      en: pointsEn,
      de: pointsDe,
      it: pointsIt,
      es: pointsEs,
    ).join('\n');
  }

  /// Vrai si la fiche est AU CALIBRE : au moins cinq points dans la langue
  /// courante (garde-fou de QA, utilise par les tests de contenu).
  bool get isAtCalibre => localizedPoints.length >= 5;

  /// Vrai si au moins un lien reseau (FB ou IG) est renseigne (bouton affiche).
  bool get hasSocialLinks =>
      (urlFacebook != null && urlFacebook!.isNotEmpty) ||
      (urlInstagram != null && urlInstagram!.isNotEmpty);

  /// Selection de langue INLINE (repli sur le francais si traduction absente).
  String _pick({
    required String fr,
    required String en,
    required String de,
    required String it,
    required String es,
  }) {
    final value = switch (LocaleSettings.currentLocale) {
      AppLocale.fr => fr,
      AppLocale.en => en,
      AppLocale.de => de,
      AppLocale.it => it,
      AppLocale.es => es,
    };
    return value.isNotEmpty ? value : fr;
  }

  /// Selection de langue INLINE pour une LISTE (repli FR si traduction absente).
  List<String> _pickList({
    required List<String> fr,
    required List<String> en,
    required List<String> de,
    required List<String> it,
    required List<String> es,
  }) {
    final value = switch (LocaleSettings.currentLocale) {
      AppLocale.fr => fr,
      AppLocale.en => en,
      AppLocale.de => de,
      AppLocale.it => it,
      AppLocale.es => es,
    };
    return value.isNotEmpty ? value : fr;
  }
}
