import 'package:freezed_annotation/freezed_annotation.dart';

part 'variante_etape.freezed.dart';
part 'variante_etape.g.dart';

/// Difficulte d'une variante d'etape (F6D-01).
enum VarianteDifficulte {
  @JsonValue('facile')
  facile,
  @JsonValue('moyen')
  moyen,
  @JsonValue('difficile')
  difficile,
}

/// Modele d'une VARIANTE d'etape (F6.3, Phase 6).
///
/// Une etape de base peut offrir plusieurs traces alternatives (officielle ou
/// variantes : raccourci, version sportive, contournement meteo...). Chaque
/// variante porte sa propre distance, denivele, difficulte et reference de
/// trace GPX. Les donnees viennent de la config sentier (TrailConfig / Drift),
/// fictives en P2-P3 (fiche #84627) — pas de Firebase reel ici.
@freezed
abstract class VarianteEtape with _$VarianteEtape {
  const VarianteEtape._();

  const factory VarianteEtape({
    /// Identifiant unique de la variante.
    required String id,

    /// Identifiant de l'etape de base a laquelle se rattache la variante.
    required String etapeBaseId,

    /// Libelle court de la variante (ex. 'Officielle', 'Raccourci sud').
    required String label,

    /// Distance de la variante en kilometres.
    required double distanceKm,

    /// Denivele positif de la variante en metres.
    required double deniveleM,

    /// Niveau de difficulte de la variante.
    required VarianteDifficulte difficulte,

    /// Reference de la trace GPX de la variante (asset / fichier).
    required String traceGpxRef,

    /// Vrai si c'est la variante officielle (par defaut) de l'etape.
    @Default(false) bool isOfficielle,
  }) = _VarianteEtape;

  /// Deserialisation depuis JSON (config sentier).
  factory VarianteEtape.fromJson(Map<String, dynamic> json) =>
      _$VarianteEtapeFromJson(json);
}

/// Selection d'une variante par etape de base, pour le planning (F6D-01).
///
/// Etat immuable : la map associe un `etapeBaseId` a l'`id` de variante choisi.
@freezed
abstract class VarianteSelection with _$VarianteSelection {
  const VarianteSelection._();

  const factory VarianteSelection({
    /// Variante choisie par etape de base (etapeBaseId -> varianteId).
    @Default(<String, String>{}) Map<String, String> selectionParEtape,
  }) = _VarianteSelection;

  /// Selectionne [varianteId] pour [etapeBaseId] (retourne un nouvel etat).
  VarianteSelection selectionner(String etapeBaseId, String varianteId) {
    final updated = Map<String, String>.from(selectionParEtape)
      ..[etapeBaseId] = varianteId;
    return copyWith(selectionParEtape: updated);
  }

  /// Id de la variante choisie pour [etapeBaseId], ou null si aucun choix.
  String? varianteChoisie(String etapeBaseId) => selectionParEtape[etapeBaseId];

  factory VarianteSelection.fromJson(Map<String, dynamic> json) =>
      _$VarianteSelectionFromJson(json);
}
