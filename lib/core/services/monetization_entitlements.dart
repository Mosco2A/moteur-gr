/// Les droits par trek : possession, etapes acquises, migration des achats
/// legacy, abandon, et le cache synchrone des gardes de routes.
///
/// Collaborateur de [MonetizationService] (lot 645-06b) : la responsabilite
/// « droits ». Les cles legacy sont re-exportees par
/// `monetization_service.dart` ; la classe ne l'est pas.
library;

import 'package:drift/drift.dart' show Value;
import 'package:logger/logger.dart';

import '../config/feature_flags.dart';
import '../data/database.dart';
import 'monetization_dependencies.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Clé SharedPreferences legacy #1 : treks achetés (booléen par trek).
///
/// Écrite par l'ANCIEN `MonetizationService` (`purchaseTrail` stub). Migrée en
/// runtime vers `TrekEntitlements.owned=true` par `migrateLegacyPurchases`.
const kPurchasedTrailsPrefsKey = 'monetization.purchasedTrails';

/// Clé SharedPreferences legacy #2 : treks achetés vus par `DemoModeService`.
///
/// 2ᵉ source d'achat historique (doublon). Migrée elle aussi vers
/// `TrekEntitlements.owned=true` (idempotent).
const kDemoModePurchasedTrailsPrefsKey = 'purchased_trail_ids';

/// Les droits par trek, et leur reflet dans [FeatureFlags].
class TrekEntitlementLedger {
  /// Les droits lisent et ecrivent la table des droits de [_deps].
  TrekEntitlementLedger(this._deps);

  final MonetizationDependencies _deps;

  /// Migre les 2 clés prefs legacy d'achats vers `TrekEntitlements.owned=true`.
  ///
  /// Sources : [kPurchasedTrailsPrefsKey] (ancien `MonetizationService`) +
  /// [kDemoModePurchasedTrailsPrefsKey] (`demo_mode_service.dart`). IDEMPOTENT :
  /// un trek déjà `owned` n'est pas réécrit ; l'union des 2 listes est traitée.
  /// Les clés legacy sont laissées en place (aucune donnée détruite).
  Future<void> migrateLegacyPurchases() async {
    final prefs = await _deps.preferences;
    final legacy = <String>{
      ...(prefs.getStringList(kPurchasedTrailsPrefsKey) ?? const []),
      ...(prefs.getStringList(kDemoModePurchasedTrailsPrefsKey) ?? const []),
    };
    if (legacy.isEmpty) return;

    var migrated = 0;
    for (final trailId in legacy) {
      if (trailId.isEmpty) continue;
      final existing = await _deps.entitlementsDao.getByTrailId(trailId);
      if (existing?.owned ?? false) continue; // déjà migré (idempotent)
      final now = _deps.now();
      await _deps.entitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: trailId,
          owned: const Value(true),
          purchaseSource: const Value('legacy'),
          purchasedAt: Value(existing?.purchasedAt ?? now),
          acquiredStages: Value(existing?.acquiredStages ?? 0),
          totalStages: Value(existing?.totalStages ?? 0),
          updatedAt: now,
        ),
      );
      migrated++;
    }
    if (migrated > 0) {
      _log.i('[Monetization] $migrated achat(s) legacy migré(s) en droits');
    }
  }

  /// Vrai si le trek [trailId] est POSSÉDÉ (achat confirmé store).
  ///
  /// Un sentier VITRINE n'est PAS « owned » (il est jouable sans achat, cf.
  /// `accessFor`) — la possession reste un fait d'achat.
  Future<bool> ownsTrail(String trailId) async {
    final e = await _deps.entitlementsDao.getByTrailId(trailId);
    return e?.owned ?? false;
  }

  /// Observe le droit d'accès du trek [trailId] (émet à chaque mutation Drift).
  ///
  /// Signal réactif du flip démo ⇄ jouable : quand un achat confirmé pose
  /// `owned` ([markOwned] → upsert), le stream émet et l'UI (gate) se
  /// reconstruit sans rester sur un état périmé (StepWays LOT 1).
  Stream<TrekEntitlement?> watchEntitlement(String trailId) =>
      _deps.entitlementsDao.watchByTrailId(trailId);

  /// Nombre d'étapes déjà acquises pour [trailId] (base du non-repaiement).
  Future<int> acquiredStagesFor(String trailId) async {
    final e = await _deps.entitlementsDao.getByTrailId(trailId);
    return e?.acquiredStages ?? 0;
  }

  /// Pose `owned` sur [trailId] (achat confirme) et le reflete en premium.
  Future<void> markOwned(
    String trailId, {
    required int totalStages,
    required int acquiredStages,
    required int consumedComplementSteps,
    required String source,
  }) async {
    final now = _deps.now();
    await _deps.entitlementsDao.upsert(
      TrekEntitlementsCompanion.insert(
        trailId: trailId,
        owned: const Value(true),
        acquiredStages: Value(acquiredStages),
        totalStages: Value(totalStages),
        consumedComplementSteps: Value(consumedComplementSteps),
        purchaseSource: Value(source),
        purchasedAt: Value(now),
        updatedAt: now,
      ),
    );
    FeatureFlags.setOverride('premium', trailId, enabled: true);
  }

  /// Enregistre l'abandon d'un trek : les étapes acquises deviennent la BASE de
  /// rachat à la reprise (spec §2.4). Ne détruit rien, ne rembourse rien.
  ///
  /// On mémorise le complément store DÉJÀ consommé
  /// (`consumedComplementSteps`) pour que la reprise ne le refasse pas payer :
  /// à la reprise, seules les étapes NON encore acquises sont (re)dues.
  Future<void> onTrailAbandoned(String trailId) async {
    final e = await _deps.entitlementsDao.getByTrailId(trailId);
    if (e == null) return;
    // Le trek n'est plus "owned" (abandonné) mais acquiredStages est conservé
    // comme base de rachat. Le complément déjà consommé reste tracé.
    final now = _deps.now();
    await _deps.entitlementsDao.upsert(
      TrekEntitlementsCompanion.insert(
        trailId: trailId,
        owned: const Value(false),
        acquiredStages: Value(e.acquiredStages),
        totalStages: Value(e.totalStages),
        consumedComplementSteps: Value(e.consumedComplementSteps),
        purchaseSource: Value(e.purchaseSource),
        purchasedAt: Value(e.purchasedAt),
        updatedAt: now,
      ),
    );
    FeatureFlags.setOverride('premium', trailId, enabled: false);
    _log.i(
      '[Monetization] $trailId abandonné (acquis conservés: '
      '${e.acquiredStages})',
    );
  }

  /// Efface tous les droits et leur reflet premium (reset du service).
  Future<void> deleteAll() async {
    final entitlements = await _deps.entitlementsDao.getAll();
    for (final e in entitlements) {
      await _deps.entitlementsDao.deleteByTrailId(e.trailId);
      FeatureFlags.setOverride('premium', e.trailId, enabled: false);
    }
  }

  /// Resynchronise le cache synchrone [FeatureFlags] premium depuis les droits.
  ///
  /// `premium:trailId = owned`. Les gardes de routes synchrones lisent ce cache ;
  /// il est réalimenté au boot (`load`) et à chaque mutation.
  ///
  /// LES SENTIERS GRATUITS N'Y ENTRENT PAS (tâche 601). `premium` dit « ce trek a
  /// été PAYÉ » : y inscrire un sentier gratuit — ce que faisait la boucle
  /// vitrine — c'est refabriquer l'exemption dans un cache. Leur jouabilité est
  /// portée par `accessFor`, source unique, qui lit leur prix.
  Future<void> syncFeatureFlags() async {
    final entitlements = await _deps.entitlementsDao.getAll();
    for (final e in entitlements) {
      FeatureFlags.setOverride('premium', e.trailId, enabled: e.owned);
    }
  }
}
