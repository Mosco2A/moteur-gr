// Modeles de classement de defi (F7C-02, Phase 7) — VUE LECTURE du document
// calcule COTE SERVEUR (Cloud Function classementDefi, F7A-03/index.js) et mis
// en cache local (offline-first, R2). Le client NE CALCULE JAMAIS le classement.
//
// REGLE R1 (pseudonyme, jamais anonyme) : libelles PSEUDONYMES, aucun champ ni
// libelle "anonyme", aucun timestamp fin individuel (k-anonymat CNIL A4-4).

/// Une entree de classement de defi (participant pseudonyme et son score).
class DefiRankingEntry {
  const DefiRankingEntry({
    required this.rank,
    required this.pseudonym,
    required this.value,
  });

  final int rank;
  final String pseudonym;
  final double value;

  factory DefiRankingEntry.fromMap(Map<String, dynamic> map) {
    return DefiRankingEntry(
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      pseudonym: map['pseudonym'] as String? ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Classement d'une TRANCHE (large) d'un defi (k-anonymat applique serveur).
class DefiRankingTranche {
  const DefiRankingTranche({
    required this.tranche,
    required this.participantCount,
    required this.published,
    required this.entries,
  });

  final String tranche;
  final int participantCount;
  final bool published;
  final List<DefiRankingEntry> entries;

  factory DefiRankingTranche.fromMap(Map<String, dynamic> map) {
    final rawEntries = (map['entries'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DefiRankingEntry.fromMap)
        .toList();
    return DefiRankingTranche(
      tranche: map['tranche'] as String? ?? 'all',
      participantCount: (map['participantCount'] as num?)?.toInt() ?? 0,
      published: map['published'] as bool? ?? false,
      entries: rawEntries,
    );
  }
}

/// Classement complet d'un defi, par tranche.
class DefiRanking {
  const DefiRanking({required this.defiId, required this.tranches});

  /// Seuil de k-anonymat (aligne avec la Cloud Function classementDefi).
  static const int kMin = 5;

  final String defiId;
  final List<DefiRankingTranche> tranches;

  bool get isEmpty => tranches.isEmpty;

  factory DefiRanking.fromMap(Map<String, dynamic> map) {
    final rawTranches = (map['tranches'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DefiRankingTranche.fromMap)
        .toList();
    return DefiRanking(
      defiId: map['defiId'] as String? ?? '',
      tranches: rawTranches,
    );
  }
}
