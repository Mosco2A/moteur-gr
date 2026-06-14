/// Statistiques de realisation de l'utilisateur (F7C-01).
///
/// Source LOCALE des regles d'obtention de badges (offline-first, R2 : pas de
/// dependance serveur pour les badges). Alimentee par les donnees locales
/// (progres, segments completes, defis reussis). Immuable.
class UserStats {
  const UserStats({
    this.stagesCompleted = 0,
    this.treksCompleted = 0,
    this.segmentsCompleted = 0,
    this.totalElevationGainM = 0,
    this.challengesWon = 0,
  });

  /// Nombre d'etapes terminees.
  final int stagesCompleted;

  /// Nombre de treks complets termines.
  final int treksCompleted;

  /// Nombre de segments completes (efforts detectes).
  final int segmentsCompleted;

  /// Denivele positif cumule (metres).
  final double totalElevationGainM;

  /// Nombre de defis saisonniers reussis.
  final int challengesWon;
}
