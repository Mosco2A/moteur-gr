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

    /// Contenu -- francais
    required String contentFr,

    /// Contenu -- anglais
    @Default('') String contentEn,

    /// Contenu -- allemand
    @Default('') String contentDe,

    /// Contenu -- italien
    @Default('') String contentIt,

    /// Contenu -- espagnol
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

  /// Contenu resolu selon la langue courante (i18n INLINE, repli FR base).
  String get localizedContent => _pick(
    fr: contentFr,
    en: contentEn,
    de: contentDe,
    it: contentIt,
    es: contentEs,
  );

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
}
