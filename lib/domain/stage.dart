/// Une etape vue du domaine, avec ses noms en cinq langues et sa duree en
/// SECONDES. Autre type que le StageModel de core/models/stage_row.dart
/// (ARB-645-04-a, tranche en voie A le 02/10/2026).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'stage.freezed.dart';
part 'stage.g.dart';

/// Modele immutable representant une etape de sentier.
///
/// Supporte i18n 5 langues (fr, en, de, it, es),
/// coordonnees GPS depart/arrivee, et difficulte extensible (String).
@freezed
abstract class Stage with _$Stage {
  const Stage._();

  const factory Stage({
    /// Identifiant unique de l'etape
    required String id,

    /// Nom — francais
    required String nameFr,

    /// Nom — anglais
    @Default('') String nameEn,

    /// Nom — allemand
    @Default('') String nameDe,

    /// Nom — italien
    @Default('') String nameIt,

    /// Nom — espagnol
    @Default('') String nameEs,

    /// Distance en kilometres
    required double distance,

    /// Denivele positif en metres
    required int elevationGain,

    /// Denivele negatif en metres
    required int elevationLoss,

    /// Duree estimee en secondes (serialisable)
    @Default(0) int estimatedDurationSeconds,

    /// Difficulte — String extensible (easy, moderate, hard, extreme, ...)
    @Default('moderate') String difficulty,

    /// Ordre d'affichage (1-indexed)
    required int orderIndex,

    /// Latitude du point de depart
    required double startLat,

    /// Longitude du point de depart
    required double startLng,

    /// Latitude du point d'arrivee
    required double endLat,

    /// Longitude du point d'arrivee
    required double endLng,

    /// Description — francais
    @Default('') String descriptionFr,

    /// Description — anglais
    @Default('') String descriptionEn,

    /// Description — allemand
    @Default('') String descriptionDe,

    /// Description — italien
    @Default('') String descriptionIt,

    /// Description — espagnol
    @Default('') String descriptionEs,

    /// Nom du point de DEPART de l'etape (parite GR20 sous-ligne « Depart ->
    /// Arrivee »). Vide quand la donnee du sentier ne le fournit pas ->
    /// l'affichage retombe proprement sur le nom de l'etape.
    @Default('') String departureName,

    /// Nom du point d'ARRIVEE de l'etape (parite GR20 sous-ligne « Depart ->
    /// Arrivee »). Vide quand la donnee du sentier ne le fournit pas ->
    /// l'affichage retombe proprement sur le nom de l'etape.
    @Default('') String arrivalName,
  }) = _Stage;

  /// Duree estimee sous forme de Duration
  Duration get estimatedDuration => Duration(seconds: estimatedDurationSeconds);

  /// Le nom de l'etape dans [langue], avec repli sur le francais.
  ///
  /// Les noms d'etape sont des noms de LIEUX, mais ils ne sont pas pour autant
  /// identiques d'une langue a l'autre : « Ghisonaccia - Catastaghju » devient
  /// « Ghisonaccia to Catastaghju » en anglais. Un repli sur le francais vaut
  /// toujours mieux qu'un vide — une etape sans nom n'est plus une etape.
  ///
  /// POSE SUR LE MODELE, ET PAS DANS L'ECRAN QUI EN A BESOIN (tache 810). Deux
  /// copies privees de ce choix existent deja — `_stageName` dans
  /// `features/after/presentation/gpx_import_screen.dart` et `_localizedName`
  /// dans `features/trek/presentation/stages/stage_card.dart`, repris par
  /// `trek_stage_detail_screen.dart`. Elles sont SIGNALEES, pas touchees : les
  /// replier ici changerait trois ecrans qui ne sont pas l'objet de ce lot.
  /// Mais une troisieme copie n'etait pas acceptable, et le nom d'une etape est
  /// une affaire d'etape.
  String nomLocalise(String langue) {
    final localise = switch (langue) {
      'en' => nameEn,
      'de' => nameDe,
      'it' => nameIt,
      'es' => nameEs,
      _ => nameFr,
    };
    return localise.isNotEmpty ? localise : nameFr;
  }

  /// Deserialisation depuis JSON
  factory Stage.fromJson(Map<String, dynamic> json) => _$StageFromJson(json);
}
