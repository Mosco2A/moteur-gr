import '../../../core/models/stage.dart';

/// Une journee planifiee du PROGRAMME (parite GR20 `PlannedDay`).
///
/// Contrairement a [DayPlan] (produit fige du calcul de repartition), ce modele
/// est destine a l'EDITION par l'utilisateur : reorganisation, regroupement /
/// separation d'etapes, ajout / suppression de jours de repos. Il porte donc la
/// liste des etapes du jour (deja resolues depuis le sentier courant) et un flag
/// [isRestDay]. Aucune donnee de localite en dur : les etapes proviennent du
/// sentier actif (generique multi-sentiers).
class PlannedDay {
  const PlannedDay({
    required this.dayNumber,
    required this.stages,
    this.isRestDay = false,
  });

  /// Numero du jour (1-indexed).
  final int dayNumber;

  /// Etapes parcourues ce jour-la (peut en combiner plusieurs apres un merge).
  /// Vide pour un jour de repos.
  final List<StageModel> stages;

  /// Jour de repos (aucune marche).
  final bool isRestDay;

  /// Distance totale du jour (somme des etapes), en km.
  double get totalDistanceKm =>
      stages.fold<double>(0, (sum, s) => sum + s.distanceKm);

  /// Denivele positif total du jour, en metres.
  int get totalElevationGainM =>
      stages.fold<int>(0, (sum, s) => sum + s.elevationGainM);

  /// Denivele negatif total du jour, en metres.
  int get totalElevationLossM =>
      stages.fold<int>(0, (sum, s) => sum + s.elevationLossM);

  /// Duree estimee du jour, en heures (memes coefficients que GR20 /
  /// [PlanningCalculator] : distance / 4 km/h + D+ / 400 m/h).
  double get estimatedHours =>
      stages.fold<double>(0, (sum, s) => sum + s.distanceKm / 4.0) +
      stages.fold<double>(0, (sum, s) => sum + s.elevationGainM / 400.0);

  /// Difficulte maximale des etapes du jour (echelle 1..4, teinte de la carte).
  /// Repli sur 1 (facile) pour un jour sans etape.
  int get maxDifficulty {
    var max = 1;
    for (final s in stages) {
      final d = difficultyRank(s.difficulty);
      if (d > max) max = d;
    }
    return max;
  }

  PlannedDay copyWith({
    int? dayNumber,
    List<StageModel>? stages,
    bool? isRestDay,
  }) {
    return PlannedDay(
      dayNumber: dayNumber ?? this.dayNumber,
      stages: stages ?? this.stages,
      isRestDay: isRestDay ?? this.isRestDay,
    );
  }
}

/// Convertit la difficulte textuelle du modele ([StageModel.difficulty]) en rang
/// numerique 1..4 (parite GR20 : facile/modere/difficile/extreme). Sert au tri
/// de couleur (pastille jour, profil altimetrique, legende).
int difficultyRank(String difficulty) {
  switch (difficulty) {
    case 'easy':
      return 1;
    case 'moderate':
      return 2;
    case 'hard':
      return 3;
    case 'extreme':
      return 4;
    default:
      return 2;
  }
}
