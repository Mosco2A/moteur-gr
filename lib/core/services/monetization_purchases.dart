/// Les achats : devis, achat d'un trek (wallet d'abord, complement store),
/// reprise, recharge du compte-etapes et restauration des achats store.
///
/// Collaborateur de [MonetizationService] (lot 645-06b) : la responsabilite
/// « achats ». Non re-exporte.
library;

import 'package:logger/logger.dart';

import '../network/connectivity_monitor.dart';
import 'monetization_dependencies.dart';
import 'monetization_entitlements.dart';
import 'monetization_models.dart';
import 'monetization_pricing.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Les achats d'un trek et du compte-etapes.
class TrailPurchases {
  /// Les achats debitent le wallet de [_deps], lisent le prix par [_pricing]
  /// et posent les droits par [_entitlements].
  TrailPurchases(this._deps, this._pricing, this._entitlements);

  final MonetizationDependencies _deps;
  final TrailPricing _pricing;
  final TrekEntitlementLedger _entitlements;

  /// Recharge le compte-étapes via un [pack] (achat store consommable).
  ///
  /// Délègue au store ; le crédit réel du wallet arrive par la
  /// boucle de complétion (`purchaseStream`). Retourne true si l'achat est
  /// initié (false en mode stub / hors-ligne). Le crédit n'est PAS immédiat.
  Future<bool> rechargeWallet(StepPack pack) async {
    // DEMO : on ne recharge pas un compte qui ne compte pas (tache 634).
    if (_deps.enDemo) return false;
    return _deps.iap.buyCredits(pack.productId);
  }

  /// Devis d'achat d'un trek : besoin, part wallet, complément store.
  ///
  /// `need = prix − acquis` ; `fromWallet = min(wallet, need)` ;
  /// `complément = need − fromWallet`. Le pack de complément est le plus petit
  /// couvrant le manque (reco §3.1). N'engage RIEN (lecture seule).
  ///
  /// Le prix vient du catalogue (`stagesOfTrail`), plus de l'appelant
  /// (avenant 614) : un devis et l'achat qui le suit lisent le MÊME nombre.
  Future<TrailQuote> quoteTrail(String trailId) {
    return _quote(
      trailId,
      totalStages: _pricing.stagesOfTrail(trailId),
      useAcquired: true,
    );
  }

  /// Devis de REPRISE : ne facture que les étapes non encore acquises.
  ///
  /// Identique à [quoteTrail] mais explicite sur l'intention de reprise : le
  /// besoin = `prix − acquis` (les étapes déjà acquises ne sont pas repayées,
  /// spec §2.5 « rachat du complément consommé »). Prix lu au catalogue.
  Future<TrailQuote> quoteResume(String trailId) {
    return _quote(
      trailId,
      totalStages: _pricing.stagesOfTrail(trailId),
      useAcquired: true,
    );
  }

  Future<TrailQuote> _quote(
    String trailId, {
    required int totalStages,
    required bool useAcquired,
  }) async {
    final acquired = useAcquired
        ? await _entitlements.acquiredStagesFor(trailId)
        : 0;
    final needed = (totalStages - acquired).clamp(0, totalStages);
    final fromWallet = needed < _deps.wallet.balanceSteps
        ? needed
        : _deps.wallet.balanceSteps;
    final complement = needed - fromWallet;
    return TrailQuote(
      trailId: trailId,
      totalStages: totalStages,
      acquiredStages: acquired,
      stepsNeeded: needed,
      stepsFromWallet: fromWallet,
      complementSteps: complement,
      complementPack: complement > 0
          ? _pricing.smallestPackCovering(complement)
          : null,
    );
  }

  /// Achète le trek [trailId] (algo spec §2.5 — wallet d'abord, complément store).
  ///
  /// Étapes :
  ///   1. si déjà possédé → [PurchaseStatusResult.alreadyOwned] (idempotent) ;
  ///   2. `need = totalStages − acquis` ; `fromWallet = min(wallet, need)` ;
  ///   3. DÉBIT wallet de `fromWallet` (offline OK) ;
  ///   4. si `complément > 0` → EXIGE le réseau ([ConnectivityMonitor]) :
  ///        - hors-ligne → ROLLBACK du débit → `offlineComplementRequired` ;
  ///        - en ligne → achat du PLUS PETIT PACK couvrant le complément ; en
  ///          l'état (stub IAP) l'achat n'est pas confirmé synchronement →
  ///          ROLLBACK + `complementFailed` (le crédit du pack, quand il
  ///          arrivera par la boucle de complétion, réalimentera le wallet) ;
  ///   5. sinon (`complément == 0`) → `owned` POSÉ (achat couvert par le wallet).
  ///
  /// `owned` n'est JAMAIS posé tant que le complément store n'est pas confirmé
  /// (spec §5). Jamais de wallet débité sans contrepartie : tout échec du
  /// complément rollback le débit.
  ///
  /// LE PRIX N'EST PLUS UN PARAMÈTRE (avenant 614). Il était `required`, donc
  /// déclaré par l'appelant, et un zéro traversait l'algorithme sans débit
  /// jusqu'à poser `owned` : un sentier payant devenait gratuit sur une erreur
  /// d'argument. Il est désormais LU au catalogue (`stagesOfTrail`) — voir cette
  /// méthode pour la mesure complète du trou et la raison de le fermer en
  /// retirant le choix plutôt qu'en le surveillant.
  ///
  /// Lot 645-06b : l'algorithme est inchange, pas a pas ; il est seulement
  /// lu en trois temps — les refus d'avant tout debit ([_refusal]), le prix,
  /// puis le reglement ([_settle]).
  Future<PurchaseOutcome> buyTrail(String trailId) async {
    final refusal = await _refusal(trailId);
    if (refusal != null) return refusal;

    // LE PRIX VIENT DU CATALOGUE, ET S'IL N'Y EST PAS ON NE VEND PAS.
    //
    // L'ordre de ces trois gardes est le fond de l'affaire. « Déjà possédé » et
    // « gratuit » sont traités AVANT : un sentier dont le catalogue dit que le
    // prix est nul reste jouable sans débit (décision de Christophe du 27/09,
    // modèle éco §2 bis — tout se déduit du prix). Ce qui tombe ICI est le cas
    // opposé : un identifiant que le catalogue ne connaît pas, dont on ignore
    // le prix. Zéro étape n'est alors pas une gratuité, c'est une ignorance —
    // et l'offrir serait rejouer `isShowcaseTrail`, l'exemption qui a rendu le
    // Mare a Mare invendable jusqu'à ce qu'un audit la trouve.
    final totalStages = _pricing.stagesOfTrail(trailId);
    if (totalStages <= 0) {
      _log.w(
        '[Monetization] $trailId : prix introuvable au catalogue -> '
        'vente REFUSEE (rien debite, aucun droit pose)',
      );
      return PurchaseOutcome(
        status: PurchaseStatusResult.unknownPrice,
        trailId: trailId,
      );
    }
    return _settle(trailId, totalStages);
  }

  /// Les refus d'AVANT tout debit : demo, deja possede, sentier gratuit.
  /// `null` quand l'achat peut continuer.
  Future<PurchaseOutcome?> _refusal(String trailId) async {
    // DEMO : AUCUN DEBIT, AUCUN DROIT (tache 634, DEM-260929-1123). C'est le
    // refus le plus important des cinq : c'est ici qu'un sentier payant
    // deviendrait possede, et c'est exactement le trou que le lot 601 avait
    // ferme en supprimant le drapeau vitrine. La demo MONTRE, elle ne DEBLOQUE
    // jamais.
    if (_deps.enDemo) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.refuseEnDemo,
        trailId: trailId,
      );
    }
    if (await _entitlements.ownsTrail(trailId)) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.alreadyOwned,
        trailId: trailId,
      );
    }

    // ON NE VEND PAS UN SENTIER GRATUIT (tâche 601). Son prix est nul : il n'y a
    // rien à débiter, rien à compléter au store, et l'accès est DÉJÀ acquis.
    //
    // ET ON NE LUI POSE PAS DE DROIT D'ACHAT POUR AUTANT. Ce serait la même
    // faute que le drapeau vitrine sous un autre nom : une ligne `owned` en base
    // lui donnerait le sans-pub PERMANENT réservé à celui qui a payé. Sa
    // gratuité est une propriété du catalogue, lue par `accessFor` ; elle n'a
    // aucune raison de se recopier en droit acquis.
    if (_pricing.isFreeTrail(trailId)) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.alreadyOwned,
        trailId: trailId,
      );
    }
    return null;
  }

  /// Le reglement d'un trek au prix connu [totalStages] : debit du wallet,
  /// puis complement store ([_complement]) ou pose de `owned`.
  Future<PurchaseOutcome> _settle(String trailId, int totalStages) async {
    final quote = await _quote(
      trailId,
      totalStages: totalStages,
      useAcquired: true,
    );

    // 1) Débit wallet (offline OK). Jamais de solde négatif (garde WalletStore).
    if (quote.stepsFromWallet > 0) {
      await _deps.wallet.debit(quote.stepsFromWallet);
    }

    // 2) Complément store : EXIGE le réseau, sinon rollback.
    if (quote.complementSteps > 0) return _complement(trailId, quote);

    // 3) Complément nul : le wallet couvre tout -> achat confirmé, owned posé.
    await _entitlements.markOwned(
      trailId,
      totalStages: totalStages,
      acquiredStages: totalStages,
      consumedComplementSteps: 0,
      source: 'wallet',
    );
    _log.i(
      '[Monetization] $trailId acheté (wallet: '
      '${quote.stepsFromWallet} étapes)',
    );
    return PurchaseOutcome(
      status: PurchaseStatusResult.owned,
      trailId: trailId,
      stepsFromWallet: quote.stepsFromWallet,
    );
  }

  /// Le complement store d'un achat : il EXIGE le reseau, et faute de
  /// confirmation synchrone le debit du wallet est toujours rendu.
  Future<PurchaseOutcome> _complement(String trailId, TrailQuote quote) async {
    final online = await _isOnline();
    if (!online) {
      await _rollbackWallet(quote.stepsFromWallet);
      _log.w(
        '[Monetization] $trailId : complément store hors-ligne -> '
        'rollback wallet (${quote.stepsFromWallet} étapes)',
      );
      return PurchaseOutcome(
        status: PurchaseStatusResult.offlineComplementRequired,
        trailId: trailId,
        complementSteps: quote.complementSteps,
        complementPack: quote.complementPack,
      );
    }
    // En ligne : initier l'achat du pack de complément (best-effort). La
    // confirmation store est ASYNCHRONE (boucle de complétion) : elle ne peut
    // pas poser `owned` dans cet appel. Tant que l'IAP n'est pas confirmé
    // synchronement (kill-switch off = stub), on ROLLBACK le débit wallet et on
    // signale l'échec (jamais de wallet débité sans contrepartie, §5). Le
    // crédit du pack, quand il arrivera, réalimentera le wallet pour un futur
    // achat. POINT D'EXTENSION : à confirmation synchrone, poser `owned` ici.
    await rechargeWallet(quote.complementPack!);
    await _rollbackWallet(quote.stepsFromWallet);
    _log.w(
      '[Monetization] $trailId : complément store non confirmé (async) -> '
      'rollback wallet (${quote.stepsFromWallet} étapes)',
    );
    return PurchaseOutcome(
      status: PurchaseStatusResult.complementFailed,
      trailId: trailId,
      complementSteps: quote.complementSteps,
      complementPack: quote.complementPack,
    );
  }

  /// Vrai si l'appareil est en ligne (complement store exige le reseau, §5).
  Future<bool> _isOnline() async {
    final status = await _deps.connectivity.checkStatus();
    return status == ConnectivityStatusValues.online;
  }

  Future<void> _rollbackWallet(int steps) async {
    if (steps > 0) await _deps.wallet.credit(steps);
  }

  /// Reprend un trek abandonné : rachète UNIQUEMENT le complément restant.
  ///
  /// Même algo que [buyTrail] (wallet d'abord, complément store, rollback si
  /// hors-ligne/échec), mais le besoin part des étapes déjà acquises. Le prix
  /// vient du catalogue, comme pour l'achat (avenant 614).
  Future<PurchaseOutcome> resumeTrail(String trailId) {
    return buyTrail(trailId);
  }

  /// Restaure les achats passés (abo, recharges) via le store, ET DIT CE QU'ELLE
  /// A PU FAIRE (tâche 594, A3).
  ///
  /// Délègue au store ; les événements arrivent en `restored` sur
  /// la boucle de complétion. Quand l'achat in-app est indisponible (mode stub,
  /// kill-switch fermé, appareil sans store), on retourne
  /// [PurchaseRestoreStatus.storeUnavailable] au lieu de ne rien faire en
  /// silence — l'UI a de quoi expliquer le refus.
  ///
  /// CE QUE LA RESTAURATION NE RAMÈNE PAS ICI : les droits de trek achetés avec
  /// le compte-étapes ne sont PAS des produits store. Depuis la tâche 631 ils
  /// vivent AU SERVEUR et redescendent par `DescenteDesDroits`, pas par ce
  /// chemin — la base locale n'en est qu'une copie. Ce commentaire renvoyait
  /// à `CloudSyncService.syncWallet`, qui MONTAIT le compte ; cette méthode a
  /// été retirée par la tâche 635 parce que les règles refusent désormais au
  /// téléphone d'écrire ses propres droits.
  Future<PurchaseRestoreOutcome> restorePurchases() async {
    // DEMO : on ne restaure pas des achats reels au milieu d'une demo
    // (tache 634) — ils ecriraient de vrais droits en base.
    if (_deps.enDemo) {
      return const PurchaseRestoreOutcome(
        status: PurchaseRestoreStatus.storeUnavailable,
      );
    }
    if (!await _deps.iap.isAvailable()) {
      _log.w(
        '[Monetization] Restauration demandée mais achat in-app '
        'indisponible',
      );
      return const PurchaseRestoreOutcome(
        status: PurchaseRestoreStatus.storeUnavailable,
      );
    }
    await _deps.iap.restorePurchases();
    return const PurchaseRestoreOutcome(
      status: PurchaseRestoreStatus.requested,
    );
  }
}
