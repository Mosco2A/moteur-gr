import 'badge.dart';
import 'user_stats.dart';

/// Moteur d'attribution de badges, evaluation 100 % LOCALE (F7C-01).
///
/// REGLE R2 : aucune dependance serveur. Les badges sont calcules a partir des
/// realisations LOCALES de l'utilisateur ([UserStats]), offline-first. Les
/// regles DEBUTANT (premiers pas) et EXPERT (exploits cumules) sont distinctes.
///
/// [evaluateBadges] est une fonction PURE et testable : meme entree -> meme
/// sortie. Elle prend le CATALOGUE de badges (libelles deja localises via
/// Slang) et renvoie une nouvelle liste ou chaque badge est marque obtenu
/// (obtainedAt) ou verrouille (obtainedAt == null).
class BadgeEngine {
  const BadgeEngine();

  /// Seuils EXPERT (regles distinctes du palier debutant).
  static const double expertElevationM = 5000;
  static const int expertStages = 10;

  /// Predicat d'obtention d'un badge par son [code], a partir des [stats].
  ///
  /// DEBUTANT = premiers pas ; EXPERT = exploits cumules. Tout code inconnu
  /// renvoie faux (jamais d'attribution implicite).
  static bool isEarned(String code, UserStats stats) {
    switch (code) {
      // --- Debutant ---
      case BadgeCode.firstStage:
        return stats.stagesCompleted >= 1;
      case BadgeCode.firstTrek:
        return stats.treksCompleted >= 1;
      case BadgeCode.firstSegment:
        return stats.segmentsCompleted >= 1;
      // --- Expert ---
      case BadgeCode.elevation5000:
        return stats.totalElevationGainM >= expertElevationM;
      case BadgeCode.tenStages:
        return stats.stagesCompleted >= expertStages;
      case BadgeCode.challenger:
        return stats.challengesWon >= 1;
      default:
        return false;
    }
  }

  /// Evalue le [catalog] de badges contre les [stats] de l'utilisateur.
  ///
  /// Retourne une NOUVELLE liste : un badge gagne recoit [now] comme
  /// `obtainedAt` (sauf s'il portait deja une date d'obtention anterieure,
  /// conservee) ; un badge non gagne reste verrouille (`obtainedAt == null`).
  List<Badge> evaluateBadges(
    UserStats stats,
    List<Badge> catalog, {
    DateTime? now,
  }) {
    final ts = (now ?? DateTime.now()).toUtc();
    return catalog.map((badge) {
      final earned = isEarned(badge.code, stats);
      if (!earned) {
        // Non gagne : verrouille (on n'invente jamais d'obtention).
        return badge.copyWith(obtainedAt: null);
      }
      // Gagne : conserve la date d'obtention existante, sinon horodate.
      return badge.copyWith(obtainedAt: badge.obtainedAt ?? ts);
    }).toList();
  }
}
