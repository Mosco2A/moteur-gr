/// La journee destinee a l'EDITION par le marcheur : regrouper, separer,
/// insErer un repos — ce que le plan fige ne permet pas.
library;

import '../core/models/stage_row.dart';
import '../core/models/stage_duration.dart';
import 'mesure_de_la_journee.dart';
import 'nuit_possible.dart';

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
    this.mesure,
    this.segments = const <SegmentEntreNuits>[],
  });

  /// Numero du jour (1-indexed).
  final int dayNumber;

  /// Etapes TOUCHEES ce jour-la — plusieurs apres un regroupement, UNE SEULE et
  /// partiellement quand la journee s arrete a une nuit interieure a l etape.
  ///
  /// « Touchees » et non « parcourues », depuis la tache 855 : quand une etape
  /// se marche en DEUX journees, les deux journees portent la MEME etape. C est
  /// exactement le modele de Christophe (18/10 11:03, « 16 etape en 17 jours »)
  /// et le compte d etapes du programme en tient compte — il compte les numeros
  /// DISTINCTS et non les entrees ([PlanningStats.stageCount]), donc seize
  /// etapes etalees sur dix-sept journees restent seize.
  ///
  /// Vide pour un jour de repos.
  final List<StageModel> stages;

  /// Jour de repos (aucune marche).
  final bool isRestDay;

  /// LA MESURE PROPRE DE LA JOURNEE, quand elle ne vaut pas la somme de ses
  /// etapes entieres. Nulle quand la journee couvre des etapes ENTIERES, et
  /// alors les totaux se deduisent des etapes comme ils l ont toujours fait.
  ///
  /// C EST CE CHAMP QUI FAIT QUE LE PROGRAMME PEUT ENFIN COUPER COMME LA FICHE
  /// LE PROMET (tache 855). Voir [MesureDeLaJournee] pour le defaut qu il
  /// repare : a seize jours la fiche annoncait 26,48 km-effort de pire journee
  /// quand le programme en produisait 36,45.
  final MesureDeLaJournee? mesure;

  /// Les SEGMENTS mesures entre nuits relevees que la journee reunit.
  ///
  /// Vides quand la journee vient du regroupement d etapes. Ils servent a
  /// DEGROUPER : « Separer » rend a chaque segment sa journee, exactement comme
  /// il rend a chaque etape la sienne quand la journee groupe des etapes. Sans
  /// eux, une journee posee sur les nuits serait indivisible.
  final List<SegmentEntreNuits> segments;

  /// Distance totale du jour, en km.
  ///
  /// LA MESURE PROPRE FAIT AUTORITE QUAND ELLE EXISTE. Sommer les etapes d une
  /// journee qui n en couvre qu un morceau annoncerait l etape entiere : c est
  /// precisement l ecart de neuf km-effort que la tache 855 a ferme.
  double get totalDistanceKm =>
      mesure?.km ?? stages.fold<double>(0, (sum, s) => sum + s.distanceKm);

  /// Denivele positif total du jour, en metres.
  int get totalElevationGainM =>
      mesure?.deniveleM ??
      stages.fold<int>(0, (sum, s) => sum + s.elevationGainM);

  /// Denivele negatif total du jour, en metres.
  int get totalElevationLossM =>
      mesure?.descenteM ??
      stages.fold<int>(0, (sum, s) => sum + s.elevationLossM);

  /// Duree estimee du jour, en heures.
  ///
  /// Somme des durees d'etape via la source unique [stageDurationMinutes] : la
  /// duree RICHE du sentier fait autorite par etape quand elle existe, sinon
  /// repli sur la regle de marche Naismith (memes coefficients que GR20 /
  /// [PlanningCalculator] : distance / 4 km/h + D+ / 400 m/h).
  ///
  /// La mesure propre fait autorite quand elle existe, pour la meme raison que
  /// les trois totaux ci-dessus : ses minutes sont celles des segments
  /// reellement marches, detour vers le couchage compris.
  double get estimatedHours =>
      (mesure?.minutes ?? totalStagesDurationMinutes(stages)) / 60.0;

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
    MesureDeLaJournee? mesure,
    List<SegmentEntreNuits>? segments,
  }) {
    return PlannedDay(
      dayNumber: dayNumber ?? this.dayNumber,
      stages: stages ?? this.stages,
      isRestDay: isRestDay ?? this.isRestDay,
      mesure: mesure ?? this.mesure,
      segments: segments ?? this.segments,
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
