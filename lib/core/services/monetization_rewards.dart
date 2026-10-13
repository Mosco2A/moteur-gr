/// La recompense sans-pub de 24 h, gagnee par une video : son etat, son
/// echeance et son octroi.
///
/// Collaborateur de [MonetizationService] (lot 645-06b) : la responsabilite
/// « recompense ». Non re-exporte.
library;

import 'package:drift/drift.dart' show Value;
import 'package:logger/logger.dart';

import '../data/database.dart';
import 'monetization_dependencies.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// La recompense sans-pub de 24 h.
class RewardNoAdsLedger {
  /// La recompense lit et ecrit la table sans-pub de [_deps].
  RewardNoAdsLedger(this._deps);

  final MonetizationDependencies _deps;

  /// Vrai si une récompense sans-pub (rewarded) est ACTIVE (non expirée).
  ///
  /// Une source 'reward' pose `expiresAt = now + 24 h`. Testable via `nowFn`.
  Future<bool> isRewardNoAdsActive() async {
    final now = _deps.now();
    final states = await _deps.noAdsDao.getAll();
    return states.any(
      (s) =>
          s.source == 'reward' &&
          s.expiresAt != null &&
          s.expiresAt!.isAfter(now),
    );
  }

  /// Échéance de la récompense sans-pub de 24 h (null si aucune active).
  ///
  /// TACHE 639 (avenant, DEM-260930-1241) : Christophe a tranché « video 24h
  /// retire la pub prepa pendant 24h point », avec un COMPTE A REBOURS VISIBLE.
  /// Un booléen ne peut pas porter un compte à rebours ; il fallait l'échéance.
  /// Même forme que `subscriptionExpiresAt`, et la même source unique : la
  /// table des états sans-pub, jamais un second calcul.
  Future<DateTime?> rewardNoAdsExpiresAt() async {
    final now = _deps.now();
    final actives = (await _deps.noAdsDao.getAll())
        .where(
          (s) =>
              s.source == 'reward' &&
              s.expiresAt != null &&
              s.expiresAt!.isAfter(now),
        )
        .map((s) => s.expiresAt!)
        .toList();
    if (actives.isEmpty) return null;
    return actives.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Octroie une récompense sans-pub de 24 h (après une pub rewarded).
  ///
  /// Pose une source 'reward' `expiresAt = now + 24 h` (horloge `nowFn`).
  Future<void> grantRewardNoAds() async {
    // DEMO : aucune recompense video ecrite en base (tache 634).
    if (_deps.enDemo) return;
    final now = _deps.now();
    await _deps.noAdsDao.insertState(
      NoAdsStateCompanion.insert(
        source: 'reward',
        startedAt: now,
        updatedAt: now,
        expiresAt: Value(now.add(const Duration(hours: 24))),
      ),
    );
    _log.i('[Monetization] Reward sans-pub 24 h accordé');
  }
}
