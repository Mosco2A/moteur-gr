import '../models/programme_entrainement.dart';

/// Niveau declare par l'utilisateur (F6E-01) — parametre le volume du plan.
enum NiveauEntrainement { debutant, intermediaire, avance }

/// Generateur de programme d'entrainement pre-trek (F6E-01).
///
/// Construit un plan J-N progressif a partir de la duree (en semaines) et du
/// niveau declare, en s'appuyant sur des bonnes pratiques trek (cadrage
/// #85929) :
/// - PROGRESSIVITE : le volume des sorties longues croit chaque semaine.
/// - VARIETE : alternance marche (sorties), cardio, renforcement
///   (jambes/gainage).
/// - RECUPERATION : pas de seance tous les jours (jours de repos implicites).
///
/// Tout est calcule LOCALEMENT, sans aucune donnee de sante stockee
/// (minimisation RGPD).
class ProgrammeGenerator {
  const ProgrammeGenerator._();

  /// Duree de base d'une sortie marche (min) selon le niveau, semaine 1.
  static int _marcheBaseMin(NiveauEntrainement niveau) {
    switch (niveau) {
      case NiveauEntrainement.debutant:
        return 30;
      case NiveauEntrainement.intermediaire:
        return 45;
      case NiveauEntrainement.avance:
        return 60;
    }
  }

  /// Genere un programme sur [dureeSemaines] semaines pour un [niveau] donne.
  ///
  /// Schema hebdomadaire (3 seances/semaine, jours 1/3/5) :
  /// - jour 1 : renforcement (jambes/gainage), intensite moderee.
  /// - jour 3 : cardio, intensite croissante avec les semaines.
  /// - jour 5 : sortie marche longue, duree croissante (progressivite).
  static ProgrammeEntrainement generer({
    required int dureeSemaines,
    required NiveauEntrainement niveau,
    String id = 'prog-default',
  }) {
    final semaines = dureeSemaines < 1 ? 1 : dureeSemaines;
    final seances = <SeanceEntrainement>[];
    final marcheBase = _marcheBaseMin(niveau);

    for (var s = 0; s < semaines; s++) {
      final baseDay = s * 7;
      // Progressivite : +15 % de duree de marche par semaine.
      final marcheMin = (marcheBase * (1 + 0.15 * s)).round();
      // Intensite cardio qui monte avec l'avancement du plan.
      final intensiteCardio = s < semaines / 3
          ? IntensiteSeance.faible
          : (s < 2 * semaines / 3
              ? IntensiteSeance.moderee
              : IntensiteSeance.elevee);

      seances
        ..add(SeanceEntrainement(
          jourOffset: baseDay,
          type: TypeSeance.renforcement,
          dureeMin: 30,
          intensite: IntensiteSeance.moderee,
          description: 'Renforcement jambes et gainage',
        ))
        ..add(SeanceEntrainement(
          jourOffset: baseDay + 2,
          type: TypeSeance.cardio,
          dureeMin: 30,
          intensite: intensiteCardio,
          description: 'Cardio (velo, course ou natation)',
        ))
        ..add(SeanceEntrainement(
          jourOffset: baseDay + 4,
          type: TypeSeance.marche,
          dureeMin: marcheMin,
          intensite: IntensiteSeance.moderee,
          description: 'Sortie marche longue avec denivele',
        ));
    }

    return ProgrammeEntrainement(
      id: id,
      dureeSemaines: semaines,
      seances: seances,
    );
  }
}
