/// La journee destinee a l'EDITION par le marcheur : regrouper, separer,
/// insErer un repos — ce que le plan fige ne permet pas.
library;

import '../core/models/stage_row.dart';
import '../core/models/stage_duration.dart';

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

  /// Duree estimee du jour, en heures.
  ///
  /// Somme des durees d'etape via la source unique [stageDurationMinutes] : la
  /// duree RICHE du sentier fait autorite par etape quand elle existe, sinon
  /// repli sur la regle de marche Naismith (memes coefficients que GR20 /
  /// [PlanningCalculator] : distance / 4 km/h + D+ / 400 m/h).
  double get estimatedHours => totalStagesDurationMinutes(stages) / 60.0;

  // PLUS DE `maxDifficulty` (tache 860). Il rendait le rang de l'etiquette
  // STOCKEE la plus haute du jour, sur une echelle de 1 a 4, et deux ecrans
  // s'en servaient pour TEINDRE une journee. Le rang d'une etiquette fixe ne
  // dit rien d'une journee qui groupe ou coupe des etapes : c'est le defaut
  // structurel que la tache 860 retire. Les deux ecrans peignent desormais en
  // couleur neutre, et la difficulte se lit la ou elle se mesure — la note sur
  // vingt de la journee, sur la fiche du sentier.

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

// LE RANG D'ETIQUETTE EST RETIRE AVEC L'ETIQUETTE (tache 860). Il convertissait
// `easy` / `moderate` / `hard` / `extreme` en 1 a 4 pour teindre une journee.
// Le rang d'une etiquette FIXE PAR ETAPE ne dit rien d'une journee qui groupe
// ou coupe des etapes : c'est le defaut structurel que ce lot corrige. La
// difficulte se lit desormais sur la note sur vingt de la journee, qui suit le
// decoupage reel.
