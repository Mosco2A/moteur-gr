/// Le produit FIGE du calcul de repartition, a ne pas confondre avec la journee
/// editable du programme.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/models/stage_row.dart';

part 'day_plan.freezed.dart';
part 'day_plan.g.dart';

/// Modèle représentant le plan d'une journée de trek.
///
/// Contient la liste des étapes prévues pour ce jour,
/// les totaux calculés (distance, dénivelé, durée),
/// et un flag indiquant si c'est un jour de repos.
@freezed
abstract class DayPlan with _$DayPlan {
  const DayPlan._();

  const factory DayPlan({
    /// Numéro du jour (1-indexed)
    required int dayNumber,

    /// Liste des étapes prévues ce jour
    required List<StageModel> stages,

    /// Distance totale en km pour ce jour
    required double totalDistanceKm,

    /// Dénivelé positif total en mètres pour ce jour
    required int totalElevationGainM,

    /// Durée estimée en heures (distance/4 + D+/400)
    required double estimatedDurationHours,

    /// True si c'est un jour de repos (aucune étape)
    required bool isRestDay,
  }) = _DayPlan;

  /// Nombre d'étapes prévues ce jour
  int get stageCount => stages.length;

  /// DENIVELE NEGATIF total en metres pour ce jour, compte positivement.
  ///
  /// IL EST CALCULE ET NON STOCKE, ET C'EST VOLONTAIRE. Les deux autres totaux
  /// sont des champs que le repartiteur remplit ; celui-ci est la SOMME DES
  /// ETAPES de la journee, c'est-a-dire exactement ce que le repartiteur fait
  /// pour les deux autres. Un champ de plus aurait demande de regenerer le
  /// modele et aurait pu porter une valeur en desaccord avec `stages` ; un
  /// getter ne peut pas mentir.
  ///
  /// IL EXISTE DEPUIS LA TACHE 852 : la difficulte d'une journee se calcule sur
  /// ses TROIS mesures — distance, montee, descente (Christophe, 17/10 17:25) —
  /// et un sentier sans nuits relevees passe par ce modele-ci.
  int get totalElevationLossM =>
      stages.fold<int>(0, (somme, etape) => somme + etape.elevationLossM);

  /// Désérialisation depuis JSON
  factory DayPlan.fromJson(Map<String, dynamic> json) =>
      _$DayPlanFromJson(json);
}
