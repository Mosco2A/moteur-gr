import 'package:freezed_annotation/freezed_annotation.dart';

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
  factory TipCard.fromJson(Map<String, dynamic> json) => _$TipCardFromJson(json);
}
