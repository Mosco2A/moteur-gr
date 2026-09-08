import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/no_ads_state_table.dart';

part 'no_ads_dao.g.dart';

/// DAO de l'etat sans-pub app-wide (StepWays LOT 1, regle #99404).
///
/// CRUD de base sur la table [NoAdsState] : insertion d'une source
/// (abonnement / reward), lecture de l'ensemble et observation (`watch`).
/// Contrairement au wallet et aux entitlements, il n'y a PAS de cle metier
/// unique : plusieurs sources sans-pub peuvent coexister (abo + reward). La
/// cle primaire est auto-incrementee ; l'upsert n'a donc pas de sens ici, on
/// insere puis on purge les entrees expirees.
///
/// Rappel #99404 : `isNoAdsActive` combine cette table AVEC
/// `TrekEntitlements.owned` (le trek achete N'EST PAS stocke ici).
@DriftAccessor(tables: [NoAdsState])
class NoAdsDao extends DatabaseAccessor<AppDatabase> with _$NoAdsDaoMixin {
  NoAdsDao(super.db);

  /// Enregistre une nouvelle source sans-pub (abonnement ou reward).
  ///
  /// Retourne l'id auto-incremente de la ligne inseree.
  Future<int> insertState(NoAdsStateCompanion entry) {
    return into(noAdsState).insert(entry);
  }

  /// Relit toutes les sources sans-pub enregistrees.
  Future<List<NoAdsStateData>> getAll() {
    return select(noAdsState).get();
  }

  /// Observe l'ensemble des sources sans-pub (emet a chaque modification).
  Stream<List<NoAdsStateData>> watchAll() {
    return select(noAdsState).watch();
  }

  /// Purge les entrees expirees a la date [now] (reward passe).
  ///
  /// Les lignes sans `expiresAt` (abonnement tant qu'actif) ne sont jamais
  /// purgees par cette methode.
  Future<int> deleteExpired(DateTime now) {
    return (delete(noAdsState)
          ..where((t) => t.expiresAt.isSmallerThanValue(now)))
        .go();
  }

  /// Supprime toutes les sources sans-pub (reset complet).
  Future<int> clear() {
    return delete(noAdsState).go();
  }
}
