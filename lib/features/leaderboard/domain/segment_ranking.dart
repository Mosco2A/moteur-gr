// Modeles de classement de segment "Roi de l etape" (F7A-04, Phase 7).
//
// Ces modeles sont une VUE LECTURE du document de classement calcule COTE
// SERVEUR (Cloud Function F7A-03) et mis en cache local (offline-first, R2).
// Le client NE CALCULE JAMAIS le classement : il se contente d'afficher.
//
// REGLE R1 (pseudonyme, jamais anonyme) : les libelles sont des PSEUDONYMES
// derives d'un UID hache. Aucun champ ni libelle "anonyme". Aucun timestamp
// fin individuel n'est porte par ces modeles (k-anonymat CNIL A4-4).

/// Une entree de classement (un participant pseudonyme et son temps).
class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.pseudonym,
    required this.durationSeconds,
  });

  /// Rang dans la tranche (1 = meilleur).
  final int rank;

  /// Libelle PSEUDONYME (jamais nom reel, jamais "anonyme").
  final String pseudonym;

  /// Temps de l'effort en secondes.
  final int durationSeconds;

  factory RankingEntry.fromMap(Map<String, dynamic> map) {
    return RankingEntry(
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      pseudonym: map['pseudonym'] as String? ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Le classement d'une TRANCHE (large) d'un segment.
///
/// Si [published] est faux (moins de [SegmentRanking.kMin] participants), les
/// entrees ne sont PAS exposees (k-anonymat) : l'UI affiche un message
/// "pas assez de participants pour publier ce classement".
class RankingTranche {
  const RankingTranche({
    required this.tranche,
    required this.participantCount,
    required this.published,
    required this.entries,
  });

  /// Etiquette de tranche large (ex: 'all', 'sportif', 'decouverte').
  final String tranche;

  /// Nombre de participants distincts de la tranche.
  final int participantCount;

  /// Vrai si la tranche atteint le seuil de k-anonymat et est publiee.
  final bool published;

  /// Entrees du classement (vide si non publiee, k-anonymat).
  final List<RankingEntry> entries;

  factory RankingTranche.fromMap(Map<String, dynamic> map) {
    final rawEntries = (map['entries'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RankingEntry.fromMap)
        .toList();
    return RankingTranche(
      tranche: map['tranche'] as String? ?? 'all',
      participantCount: (map['participantCount'] as num?)?.toInt() ?? 0,
      published: map['published'] as bool? ?? false,
      entries: rawEntries,
    );
  }
}

/// Classement complet d'un segment "Roi de l etape", par tranche.
class SegmentRanking {
  const SegmentRanking({
    required this.segmentId,
    required this.tranches,
  });

  /// Seuil de k-anonymat (doit rester aligne avec la Cloud Function F7A-03).
  static const int kMin = 5;

  final String segmentId;
  final List<RankingTranche> tranches;

  bool get isEmpty => tranches.isEmpty;

  factory SegmentRanking.fromMap(Map<String, dynamic> map) {
    final rawTranches = (map['tranches'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RankingTranche.fromMap)
        .toList();
    return SegmentRanking(
      segmentId: map['segmentId'] as String? ?? '',
      tranches: rawTranches,
    );
  }
}
