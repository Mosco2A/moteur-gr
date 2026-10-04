/// L'abonnement sans-pub : son echeance, sa souscription, sa validation, sa
/// revocation, et la cagnotte d'etapes de l'abonne.
///
/// Collaborateur de [MonetizationService] (lot 645-06b) : la responsabilite
/// « abonnement ». Non re-exporte.
library;

import 'package:drift/drift.dart' show Value;
import 'package:logger/logger.dart';

import '../data/database.dart';
import 'monetization_dependencies.dart';
import 'monetization_entitlements.dart';
import 'monetization_models.dart';
import 'wallet_iap_service.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// L'abonnement sans-pub et la cagnotte de l'abonne.
class SubscriptionLedger {
  /// L'abonnement lit la table sans-pub de [_deps] ; il resynchronise le
  /// cache premium par [_entitlements] a chaque validation.
  SubscriptionLedger(this._deps, this._entitlements);

  final MonetizationDependencies _deps;
  final TrekEntitlementLedger _entitlements;

  /// Vrai si un abonnement sans-pub est ACTIF (source 'subscription' non expirée).
  ///
  /// **UNE ÉCHÉANCE EST DÉSORMAIS OBLIGATOIRE** (tâche 594, A2b). Une ligne
  /// d'abo sans `expiresAt` n'est plus acceptée : c'était exactement le
  /// « à vie » que la règle d'or #99404 interdit (« jamais à vie, toujours lié
  /// à un état actif »). L'abo était posé avec `expiresAt = null`, rien ne
  /// l'expirait jamais, `PurchaseStatus.canceled` ne faisait que journaliser,
  /// et le DAO écrivait noir sur blanc que ces lignes n'étaient jamais purgées
  /// (inventaire 593 §M5). Une fois posé, le sans-pub était acquis pour
  /// toujours.
  ///
  /// L'échéance est repoussée à chaque confirmation du store (achat initial et
  /// renouvellement) par [onSubscriptionValidated] ; elle est révoquée par
  /// [onSubscriptionCanceled]. Sans renouvellement, elle tombe d'elle-même.
  Future<bool> isSubscriberActive() async {
    final now = _deps.now();
    final states = await _deps.noAdsDao.getAll();
    return states.any(
      (s) =>
          s.source == 'subscription' &&
          s.expiresAt != null &&
          s.expiresAt!.isAfter(now),
    );
  }

  /// Échéance courante du sans-pub d'abonnement (null si aucun abo actif).
  ///
  /// Sert à l'écran d'abonnement : on affiche jusqu'à QUAND l'état est acquis,
  /// plutôt qu'un « actif » sans horizon.
  Future<DateTime?> subscriptionExpiresAt() async {
    final now = _deps.now();
    final actifs = (await _deps.noAdsDao.getAll())
        .where(
          (s) =>
              s.source == 'subscription' &&
              s.expiresAt != null &&
              s.expiresAt!.isAfter(now),
        )
        .map((s) => s.expiresAt!)
        .toList();
    if (actifs.isEmpty) return null;
    return actifs.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Lance la souscription à l'abonnement sans-pub (achat store).
  ///
  /// Délègue au store ; la pose réelle de l'abo arrive par la
  /// boucle de complétion. Retourne true si initié (false en stub).
  Future<bool> subscribe() =>
      // DEMO : pas d'abonnement souscrit depuis une demonstration (tache 634).
      _deps.enDemo ? Future.value(false) : _deps.iap.buyNoAdsSubscription();

  /// Callback à appeler quand un abonnement est VALIDÉ (store/backend).
  ///
  /// Pose (ou REMPLACE) l'unique source sans-pub 'subscription', avec une
  /// échéance à `now + `[kSubscriptionNoAdsWindow] — jamais `null`. Un
  /// abonnement est un ÉTAT, pas une collection de lignes : chaque
  /// confirmation remplace la précédente au lieu de s'empiler.
  Future<void> onSubscriptionValidated() async {
    final now = _deps.now();
    await _deps.noAdsDao.deleteBySource('subscription');
    await _deps.noAdsDao.insertState(
      NoAdsStateCompanion.insert(
        source: 'subscription',
        startedAt: now,
        updatedAt: now,
        expiresAt: Value(now.add(kSubscriptionNoAdsWindow)),
      ),
    );
    await _entitlements.syncFeatureFlags();
    _log.i(
      '[Monetization] Abo sans-pub validé jusqu au '
      '${now.add(kSubscriptionNoAdsWindow)}',
    );
  }

  /// Callback à appeler quand l'abonnement est ANNULÉ / expiré côté store.
  ///
  /// Révoque immédiatement la source sans-pub 'subscription'. Avant la tâche
  /// 594, `PurchaseStatus.canceled` ne faisait que journaliser : l'annulation
  /// ne retirait rien.
  Future<void> onSubscriptionCanceled() async {
    final supprimees = await _deps.noAdsDao.deleteBySource('subscription');
    if (supprimees > 0) {
      _log.i('[Monetization] Abo sans-pub révoqué ($supprimees source(s))');
    }
  }

  // --- Cagnotte de l'abonné (modèle éco §2 — MONTANT NON DÉCIDÉ) -----------

  /// Verse la CAGNOTTE d'étapes de l'abonné pour la période courante (A5).
  ///
  /// Mécanisme complet : on ne verse qu'à un abonné ACTIF, une seule fois par
  /// période (bornée par l'échéance de l'abo, clé prefs
  /// [kSubscriberAllowanceGrantedAtPrefsKey] — une cagnotte versée deux fois
  /// dans la même période serait un crédit gratuit).
  ///
  /// **LE MONTANT N'EST PAS DÉCIDÉ** : tant que [kSubscriberStepsAllowance]
  /// vaut `null`, rien n'est versé et l'appel retourne
  /// [SubscriberAllowanceOutcome.pendingDecision]. Voir la documentation de
  /// cette constante : la valeur attend une décision de Christophe.
  Future<SubscriberAllowanceOutcome> grantSubscriberAllowance() async {
    // DEMO : aucune cagnotte versee (tache 634).
    if (_deps.enDemo) return SubscriberAllowanceOutcome.notSubscriber;
    if (!await isSubscriberActive()) {
      return SubscriberAllowanceOutcome.notSubscriber;
    }
    const montant = kSubscriberStepsAllowance;
    if (montant == null || montant <= 0) {
      _log.w(
        '[Monetization] Cagnotte abonné : montant NON DÉCIDÉ '
        '(kSubscriberStepsAllowance == null) -> rien versé',
      );
      return SubscriberAllowanceOutcome.pendingDecision;
    }
    final prefs = await _deps.preferences;
    final periode = (await subscriptionExpiresAt())?.toIso8601String();
    if (periode != null &&
        prefs.getString(kSubscriberAllowanceGrantedAtPrefsKey) == periode) {
      return SubscriberAllowanceOutcome.alreadyGranted;
    }
    await _deps.wallet.credit(montant);
    if (periode != null) {
      await prefs.setString(kSubscriberAllowanceGrantedAtPrefsKey, periode);
    }
    _log.i('[Monetization] Cagnotte abonné : +$montant étapes');
    return SubscriberAllowanceOutcome.granted;
  }
}
