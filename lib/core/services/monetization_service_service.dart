/// Le service de monetisation : la source unique des droits.
///
/// Morceau de `monetization_service.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'monetization_service.dart';

/// Service de monétisation compte-étapes (StepWays LOT 1, ST4 — le CŒUR).
///
/// REMPLACE le modèle per-trek booléen historique (#81774 : `_purchases` Set en
/// prefs, `kPricePerStageEur`, `purchaseTrail` stub) par le modèle DEUX POCHES :
///
///   1. COMPTE-ÉTAPES (wallet, [WalletStore]) : solde d'étapes rechargeable ;
///   2. DROITS PAR TREK ([TrekEntitlementsDao]) : `owned` posé à confirmation
///      store, avec `acquiredStages` / `consumedComplementSteps` (rachat reprise).
///
/// [buyTrail] (algo spec §2.5) : `need = prix − acquis` ; `fromWallet =
/// min(wallet, need)` ; `complément = need − fromWallet`. On DÉBITE le wallet
/// (offline OK) ; si un complément > 0 subsiste, l'achat store EXIGE le réseau
/// ([ConnectivityMonitor]) — sinon le débit wallet est ROLLBACK (jamais de wallet
/// débité sans contrepartie, spec §5). `owned` n'est posé qu'à confirmation store.
/// Le complément passe par le PLUS PETIT PACK couvrant le manque (reco §3.1).
///
/// Sans-pub (#99404) : `isNoAdsActive(trailId) = ownsTrail || isSubscriberActive
/// || isRewardNoAdsActive` — SOURCE UNIQUE, aucune UI ne recalcule. L'état est
/// reflété dans [FeatureFlags] (`premium:trailId`, cache synchrone) pour les
/// gardes de routes.
///
/// Injection intégrale (tests) : collaborateurs + horloge [nowFn] (reward 24 h)
/// + `freeTrailIds`. La persistance durable reste SharedPreferences via
/// [WalletStore] ; ce service ne fait QUE la règle métier. (La base n'est plus
/// volatile depuis la tâche 613 — voir [WalletStore] pour l'arbitrage qui laisse
/// les préférences en source durable du solde.)
class MonetizationService {
  MonetizationService({
    required WalletStore walletStore,
    required TrekEntitlementsDao entitlementsDao,
    required NoAdsDao noAdsDao,
    required WalletIapService iapService,
    required ConnectivityMonitor connectivityMonitor,
    DateTime Function()? nowFn,
    SharedPreferences? prefs,
    Set<String>? freeTrailIds,
    int Function(String trailId)? stagesOf,
    bool Function()? enDemo,
  }) : _enDemo = enDemo,
       _wallet = walletStore,
       _entitlementsDao = entitlementsDao,
       _noAdsDao = noAdsDao,
       _iap = iapService,
       _connectivity = connectivityMonitor,
       _now = nowFn ?? DateTime.now,
       _prefs = prefs,
       _freeTrailIds = freeTrailIds,
       _stagesOf = stagesOf;

  /// LA BARRIERE D'ECRITURE DE LA DEMO (tache 634, DEM-260929-1123).
  ///
  /// Rendue par une FONCTION et non par un booleen fige : la demo s'entre et se
  /// quitte pendant la vie du service, et le service n'est pas reconstruit pour
  /// autant. On interroge donc l'etat A L'INSTANT DE L'ECRITURE — meme
  /// raisonnement que `stagesOf`, qui lit le prix a l'instant de l'achat.
  ///
  /// `null` (defaut) = jamais en demo. C'est ce que lisent les tests qui ne
  /// connaissent pas ce mode, et le comportement d'origine est donc
  /// strictement inchange pour eux.
  final bool Function()? _enDemo;

  /// Vrai quand une demo volontaire est en cours : AUCUNE ecriture d'argent,
  /// de droit ou d'abonnement ne doit partir.
  bool get enDemo => _enDemo?.call() ?? false;

  final WalletStore _wallet;
  final TrekEntitlementsDao _entitlementsDao;
  final NoAdsDao _noAdsDao;
  final WalletIapService _iap;
  final ConnectivityMonitor _connectivity;

  /// Horloge injectable (reward 24 h testable via `Clock`).
  final DateTime Function() _now;

  SharedPreferences? _prefs;

  /// Sentiers GRATUITS (injectés en test, sinon dérivés du catalogue).
  final Set<String>? _freeTrailIds;

  /// Nombre d'étapes d'un sentier — LE PRIX, résolu depuis le CATALOGUE.
  ///
  /// Injecté par [monetizationServiceProvider] sur le catalogue EFFECTIF
  /// (distant > dernier reçu > compilé) ; `null` en test ou hors Riverpod, où
  /// l'on retombe sur le catalogue COMPILÉ. Même forme d'injection que
  /// [_freeTrailIds], et pour la même raison : le prix et la gratuité sont deux
  /// lectures de la même donnée, jamais deux décisions.
  final int Function(String trailId)? _stagesOf;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  bool _loaded = false;

  /// Indique si l'état persisté a été chargé ([load]).
  bool get isLoaded => _loaded;

  // --- Sentiers GRATUITS (prix nul, tâche 601) ------------------------------

  /// Ensemble effectif des sentiers gratuits (injection > catalogue).
  Set<String> get _gratuits => _freeTrailIds ?? TrailCatalog.freeIds;

  /// Vrai si [trailId] est un sentier GRATUIT — son prix est nul.
  ///
  /// Dérive du PRIX porté par la donnée du catalogue, jamais d'un id de localité
  /// en dur ni d'un drapeau d'exemption (tâche 601).
  bool isFreeTrail(String trailId) => _gratuits.contains(trailId);

  // --- LE PRIX D'UN SENTIER, ET PERSONNE D'AUTRE NE LE DÉCIDE (avenant 614) --

  /// Nombre d'étapes du sentier [trailId] — SOURCE UNIQUE DU PRIX.
  ///
  /// LE TROU QUE CETTE MÉTHODE FERME. [buyTrail] prenait `totalStages` en
  /// paramètre REQUIS : c'était l'APPELANT qui annonçait le prix. Un appelant
  /// qui passait zéro sur un sentier payant traversait tout l'algorithme sans
  /// rien débiter — `need = 0`, `fromWallet = 0`, `complément = 0` — et
  /// atteignait la pose de `owned`. Autrement dit : il existait un chemin par
  /// lequel un sentier PAYANT devenait GRATUIT, et il suffisait de se tromper
  /// d'argument. C'est exactement le motif `isShowcaseTrail` du lot 601 sous un
  /// autre nom : une exemption qui n'est écrite nulle part dans le modèle.
  ///
  /// LA CORRECTION EST DE RETIRER LE CHOIX, PAS DE LE SURVEILLER. Le prix d'un
  /// sentier est une propriété de la DONNÉE du catalogue, comme sa gratuité
  /// ([isFreeTrail]) et comme tout le reste du modèle éco §2 bis. Le service la
  /// lit ; plus aucun appelant ne la déclare, donc plus aucun appelant ne peut
  /// se tromper. Les six écrans qui passaient chacun leur montant n'ont plus
  /// rien à passer.
  ///
  /// Rend 0 pour un sentier INCONNU du catalogue — et 0 n'est pas gratuit :
  /// [buyTrail] refuse alors la vente par [PurchaseStatusResult.unknownPrice]
  /// plutôt que d'offrir le sentier.
  int stagesOfTrail(String trailId) =>
      _stagesOf?.call(trailId) ?? TrailCatalog.byId(trailId)?.totalStages ?? 0;

  /// Prix EUR du sentier [trailId], lu depuis le catalogue (affichage).
  ///
  /// Point d'entrée UNIQUE du prix affiché : la vitrine, le catalogue et le
  /// cockpit l'appellent, et il repose sur la même lecture que le débit. Le
  /// montant montré et le montant prélevé ne peuvent donc plus diverger.
  double eurPriceForTrail(String trailId) =>
      eurPriceForSteps(stagesOfTrail(trailId));

  // --- Boot / migration -----------------------------------------------------

  /// Charge l'état durable (wallet + droits) et migre le legacy (idempotent).
  ///
  /// À appeler au boot (`monetizationReadyProvider` dans
  /// `app_bootstrap_provider.dart`). Corrige l'ancien `loadPurchases()` JAMAIS
  /// appelé : hydrate le [WalletStore], migre les 2 clés prefs legacy vers les
  /// `TrekEntitlements`, démarre l'écoute IAP et resynchronise le cache
  /// [FeatureFlags] premium.
  Future<void> load() async {
    await _wallet.load();
    await migrateLegacyPurchases();
    _iap.startListening();
    await _syncFeatureFlags();
    _loaded = true;
    _log.d('[Monetization] Chargé (wallet=${_wallet.balanceSteps} étapes)');
  }

  /// Migre les 2 clés prefs legacy d'achats vers `TrekEntitlements.owned=true`.
  ///
  /// Sources : [kPurchasedTrailsPrefsKey] (ancien `MonetizationService`) +
  /// [kDemoModePurchasedTrailsPrefsKey] (`demo_mode_service.dart`). IDEMPOTENT :
  /// un trek déjà `owned` n'est pas réécrit ; l'union des 2 listes est traitée.
  /// Les clés legacy sont laissées en place (aucune donnée détruite).
  Future<void> migrateLegacyPurchases() async {
    final prefs = await _preferences;
    final legacy = <String>{
      ...(prefs.getStringList(kPurchasedTrailsPrefsKey) ?? const []),
      ...(prefs.getStringList(kDemoModePurchasedTrailsPrefsKey) ?? const []),
    };
    if (legacy.isEmpty) return;

    var migrated = 0;
    for (final trailId in legacy) {
      if (trailId.isEmpty) continue;
      final existing = await _entitlementsDao.getByTrailId(trailId);
      if (existing?.owned ?? false) continue; // déjà migré (idempotent)
      final now = _now();
      await _entitlementsDao.upsert(
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

  // --- Compte-étapes (wallet) ----------------------------------------------

  /// Solde courant du compte-étapes, en étapes.
  int get walletSteps => _wallet.balanceSteps;

  /// Observe le solde du compte-étapes (émet à chaque mouvement).
  Stream<int> watchWalletSteps() =>
      _wallet.watch().map((snap) => snap.balanceSteps);

  /// Recharge le compte-étapes via un [pack] (achat store consommable).
  ///
  /// Délègue au [WalletIapService] ; le crédit réel du wallet arrive par la
  /// boucle de complétion (`purchaseStream`). Retourne true si l'achat est
  /// initié (false en mode stub / hors-ligne). Le crédit n'est PAS immédiat.
  Future<bool> rechargeWallet(StepPack pack) async {
    // DEMO : on ne recharge pas un compte qui ne compte pas (tache 634).
    if (enDemo) return false;
    return _iap.buyCredits(pack.productId);
  }

  // --- Droits / accès -------------------------------------------------------

  /// Vrai si le trek [trailId] est POSSÉDÉ (achat confirmé store).
  ///
  /// Un sentier VITRINE n'est PAS « owned » (il est jouable sans achat, cf.
  /// [accessFor]) — la possession reste un fait d'achat.
  Future<bool> ownsTrail(String trailId) async {
    final e = await _entitlementsDao.getByTrailId(trailId);
    return e?.owned ?? false;
  }

  /// Observe le droit d'accès du trek [trailId] (émet à chaque mutation Drift).
  ///
  /// Signal réactif du flip démo ⇄ jouable : quand un achat confirmé pose
  /// `owned` ([_markOwned] → upsert), le stream émet et l'UI (gate) se
  /// reconstruit sans rester sur un état périmé (StepWays LOT 1).
  Stream<TrekEntitlement?> watchEntitlement(String trailId) =>
      _entitlementsDao.watchByTrailId(trailId);

  /// Niveau d'accès effectif du trek (spec §2.4) :
  /// owned > freeTrail > subscriber > free.
  ///
  /// Priorité : possédé → [TrailAccess.owned] ; sinon sentier GRATUIT →
  /// [TrailAccess.freeTrail] ; sinon abo actif → [TrailAccess.subscriber] ;
  /// sinon [TrailAccess.free] (démo bridée + pub).
  ///
  /// POURQUOI LE SENTIER GRATUIT PASSE AVANT L'ABONNÉ : le niveau doit rester
  /// JOUABLE pour un abonné qui marche la démo. Son sans-pub, lui, ne dépend pas
  /// de ce niveau — [isNoAdsActive] interroge l'abonnement séparément, parce que
  /// « jouable » et « sans pub » sont deux axes distincts (tâche 601).
  ///
  /// ET POURQUOI `owned` PASSE AVANT LE GRATUIT : si un sentier gratuit devenait
  /// payant un jour, un randonneur qui l'a réellement acheté garde son droit.
  Future<TrailAccess> accessFor(String trailId) async {
    if (await ownsTrail(trailId)) return TrailAccess.owned;
    if (isFreeTrail(trailId)) return TrailAccess.freeTrail;
    if (await isSubscriberActive()) return TrailAccess.subscriber;
    return TrailAccess.free;
  }

  /// LE DROIT DE **RÉALISER** LE TREK [trailId] (tâche 594, A1).
  ///
  /// SOURCE UNIQUE du verrou de réalisation. Vrai pour un trek ACHETÉ, et pour
  /// un SENTIER GRATUIT — dont il n'y avait rien à acheter : `accessFor.isPlayable`.
  ///
  /// CE QUI MANQUAIT. Le modèle éco réserve la réalisation au trek acheté
  /// (§2, « Trek acheté : outils COMPLETS … + réalisation »). Le code ne la
  /// verrouillait nulle part : « Démarrer la randonnée » n'avait qu'une
  /// condition de PRÉPARATION (itinéraire + date + programme), et le
  /// démarrage de session n'interrogeait NI ce service NI les droits d'achat.
  /// N'importe qui démarrait, enregistrait et terminait le parcours entier
  /// sans payer — la contradiction la plus coûteuse de l'inventaire 593 (§M2),
  /// et la seule atteignable en trois gestes depuis l'accueil.
  ///
  /// L'ABONNÉ N'EST PAS CONCERNÉ : l'abo light ne débloque pas la réalisation
  /// (arbitrage du 08/09, qui prime sur #99405). Il faut acheter le trek.
  ///
  /// HORS-LIGNE : dérive des droits Drift LOCAUX, aucun appel réseau — un
  /// payeur n'est jamais bloqué faute de réseau sur le sentier.
  Future<bool> canRealizeTrail(String trailId) async {
    return (await accessFor(trailId)).isPlayable;
  }

  /// Nombre d'étapes déjà acquises pour [trailId] (base du non-repaiement).
  Future<int> acquiredStagesFor(String trailId) async {
    final e = await _entitlementsDao.getByTrailId(trailId);
    return e?.acquiredStages ?? 0;
  }

  // --- Grille de prix -------------------------------------------------------

  /// Prix « catalogue » d'un trek EN ÉTAPES = son nombre d'étapes.
  ///
  /// Remplace `priceForTrail` (qui rendait des euros). Le prix en étapes est
  /// l'unité du compte-étapes ; l'affichage EUR passe par [eurPriceForSteps].
  int stepPriceForTrail({required int totalStages}) => totalStages;

  /// Prix EUR d'un nombre d'étapes au tarif palier ([kStepTierEur]).
  double eurPriceForSteps(int steps) => steps * kStepTierEur;

  /// Nombre d'étapes créditées par un [pack] (raccourci).
  int packSteps(StepPack pack) => pack.steps;

  /// Prix EUR d'un [pack] (raccourci sur la grille).
  double packPriceEur(StepPack pack) => pack.priceEur;

  /// Le plus petit pack couvrant [steps] étapes (reco complément §3.1).
  ///
  /// Retourne le pack de plus petit `steps >= steps demandé` ; si aucun ne
  /// couvre (demande > plus gros pack), retourne le plus gros pack.
  StepPack smallestPackCovering(int steps) {
    for (final pack in kStepPacks) {
      if (pack.steps >= steps) return pack;
    }
    return kStepPacks.last;
  }

  // --- Devis / achat --------------------------------------------------------

  /// Devis d'achat d'un trek : besoin, part wallet, complément store.
  ///
  /// `need = prix − acquis` ; `fromWallet = min(wallet, need)` ;
  /// `complément = need − fromWallet`. Le pack de complément est le plus petit
  /// couvrant le manque (reco §3.1). N'engage RIEN (lecture seule).
  ///
  /// Le prix vient du catalogue ([stagesOfTrail]), plus de l'appelant
  /// (avenant 614) : un devis et l'achat qui le suit lisent le MÊME nombre.
  Future<TrailQuote> quoteTrail(String trailId) {
    return _quote(
      trailId,
      totalStages: stagesOfTrail(trailId),
      useAcquired: true,
    );
  }

  Future<TrailQuote> _quote(
    String trailId, {
    required int totalStages,
    required bool useAcquired,
  }) async {
    final acquired = useAcquired ? await acquiredStagesFor(trailId) : 0;
    final needed = (totalStages - acquired).clamp(0, totalStages);
    final fromWallet = needed < walletSteps ? needed : walletSteps;
    final complement = needed - fromWallet;
    return TrailQuote(
      trailId: trailId,
      totalStages: totalStages,
      acquiredStages: acquired,
      stepsNeeded: needed,
      stepsFromWallet: fromWallet,
      complementSteps: complement,
      complementPack: complement > 0 ? smallestPackCovering(complement) : null,
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
  /// d'argument. Il est désormais LU au catalogue ([stagesOfTrail]) — voir cette
  /// méthode pour la mesure complète du trou et la raison de le fermer en
  /// retirant le choix plutôt qu'en le surveillant.
  Future<PurchaseOutcome> buyTrail(String trailId) async {
    // DEMO : AUCUN DEBIT, AUCUN DROIT (tache 634, DEM-260929-1123). C'est le
    // refus le plus important des cinq : c'est ici qu'un sentier payant
    // deviendrait possede, et c'est exactement le trou que le lot 601 avait
    // ferme en supprimant le drapeau vitrine. La demo MONTRE, elle ne DEBLOQUE
    // jamais.
    if (enDemo) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.refuseEnDemo,
        trailId: trailId,
      );
    }
    if (await ownsTrail(trailId)) {
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
    // gratuité est une propriété du catalogue, lue par [accessFor] ; elle n'a
    // aucune raison de se recopier en droit acquis.
    if (isFreeTrail(trailId)) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.alreadyOwned,
        trailId: trailId,
      );
    }

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
    final totalStages = stagesOfTrail(trailId);
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

    final quote = await _quote(
      trailId,
      totalStages: totalStages,
      useAcquired: true,
    );

    // 1) Débit wallet (offline OK). Jamais de solde négatif (garde WalletStore).
    if (quote.stepsFromWallet > 0) {
      await _wallet.debit(quote.stepsFromWallet);
    }

    // 2) Complément store : EXIGE le réseau, sinon rollback.
    if (quote.complementSteps > 0) {
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

    // 3) Complément nul : le wallet couvre tout -> achat confirmé, owned posé.
    await _markOwned(
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

  /// Vrai si l'appareil est en ligne (complement store exige le reseau, §5).
  Future<bool> _isOnline() async {
    final status = await _connectivity.checkStatus();
    return status == ConnectivityStatusValues.online;
  }

  Future<void> _rollbackWallet(int steps) async {
    if (steps > 0) await _wallet.credit(steps);
  }

  Future<void> _markOwned(
    String trailId, {
    required int totalStages,
    required int acquiredStages,
    required int consumedComplementSteps,
    required String source,
  }) async {
    final now = _now();
    await _entitlementsDao.upsert(
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

  // --- Abonnement -----------------------------------------------------------

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
    final now = _now();
    final states = await _noAdsDao.getAll();
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
    final now = _now();
    final actifs = (await _noAdsDao.getAll())
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
  /// Délègue au [WalletIapService] ; la pose réelle de l'abo arrive par la
  /// boucle de complétion. Retourne true si initié (false en stub).
  Future<bool> subscribe() =>
      // DEMO : pas d'abonnement souscrit depuis une demonstration (tache 634).
      enDemo ? Future.value(false) : _iap.buyNoAdsSubscription();

  /// Vrai si l'achat in-app est réellement proposé (kill-switch ouvert).
  ///
  /// L'UI en a besoin pour ne PAS promettre un paiement qui n'aura pas lieu :
  /// un bouton qui ne produit rien est un mensonge (règle du LOT X).
  bool get purchaseEnabled => _iap.purchaseEnabled;

  /// Callback à appeler quand un abonnement est VALIDÉ (store/backend).
  ///
  /// Pose (ou REMPLACE) l'unique source sans-pub 'subscription', avec une
  /// échéance à `now + `[kSubscriptionNoAdsWindow] — jamais `null`. Un
  /// abonnement est un ÉTAT, pas une collection de lignes : chaque
  /// confirmation remplace la précédente au lieu de s'empiler.
  Future<void> onSubscriptionValidated() async {
    final now = _now();
    await _noAdsDao.deleteBySource('subscription');
    await _noAdsDao.insertState(
      NoAdsStateCompanion.insert(
        source: 'subscription',
        startedAt: now,
        updatedAt: now,
        expiresAt: Value(now.add(kSubscriptionNoAdsWindow)),
      ),
    );
    await _syncFeatureFlags();
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
    final supprimees = await _noAdsDao.deleteBySource('subscription');
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
    if (enDemo) return SubscriberAllowanceOutcome.notSubscriber;
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
    final prefs = await _preferences;
    final periode = (await subscriptionExpiresAt())?.toIso8601String();
    if (periode != null &&
        prefs.getString(kSubscriberAllowanceGrantedAtPrefsKey) == periode) {
      return SubscriberAllowanceOutcome.alreadyGranted;
    }
    await _wallet.credit(montant);
    if (periode != null) {
      await prefs.setString(kSubscriberAllowanceGrantedAtPrefsKey, periode);
    }
    _log.i('[Monetization] Cagnotte abonné : +$montant étapes');
    return SubscriberAllowanceOutcome.granted;
  }

  // --- Reward sans-pub (24 h) ----------------------------------------------

  /// Vrai si une récompense sans-pub (rewarded) est ACTIVE (non expirée).
  ///
  /// Une source 'reward' pose `expiresAt = now + 24 h`. Testable via [nowFn].
  Future<bool> isRewardNoAdsActive() async {
    final now = _now();
    final states = await _noAdsDao.getAll();
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
  /// Même forme que [subscriptionExpiresAt], et la même source unique : la table
  /// des états sans-pub, jamais un second calcul.
  Future<DateTime?> rewardNoAdsExpiresAt() async {
    final now = _now();
    final actives = (await _noAdsDao.getAll())
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
  /// Pose une source 'reward' `expiresAt = now + 24 h` (horloge [nowFn]).
  Future<void> grantRewardNoAds() async {
    // DEMO : aucune recompense video ecrite en base (tache 634).
    if (enDemo) return;
    final now = _now();
    await _noAdsDao.insertState(
      NoAdsStateCompanion.insert(
        source: 'reward',
        startedAt: now,
        updatedAt: now,
        expiresAt: Value(now.add(const Duration(hours: 24))),
      ),
    );
    _log.i('[Monetization] Reward sans-pub 24 h accordé');
  }

  // --- Règle sans-pub #99404 (source unique) --------------------------------

  /// SOURCE UNIQUE de la règle sans-pub (#99404) :
  /// `ownsTrail(trailId) || isSubscriberActive || isRewardNoAdsActive`.
  ///
  /// LE SANS-PUB EST LA CONTREPARTIE D'AVOIR PAYÉ, jamais d'être jouable
  /// (modèle éco §3 : « trek acheté → sans pub sur ce trek »). Un SENTIER
  /// GRATUIT ([TrailAccess.freeTrail]) est entièrement jouable et n'a rien
  /// payé : il relève du niveau gratuit du §2, « AVEC pub ». C'est ce que
  /// `accessFor` produit, et la nuance n'est pas décorative — le drapeau
  /// vitrine, lui, résolvait le sentier de démonstration en `owned` et lui
  /// offrait donc le sans-pub PERMANENT réservé à l'achat : il donnait
  /// gratuitement ce que l'abonnement fait payer (tâche 601).
  ///
  /// CE QUI RESTE VRAI APRÈS UNE ANNULATION D'ABONNEMENT (règle de Chris,
  /// 27/09 12:27 : « quand il arrête l'abonnement il revoit la pub partout sauf
  /// sur les sentiers achetés ») : la première condition ne porte AUCUNE
  /// échéance — la propriété d'un sentier est permanente. Arrêter l'abonnement
  /// éteint la deuxième et laisse la première intacte.
  ///
  /// Aucune UI ne recalcule cette règle ; `AdService.shouldShowAd(isPaid: …)`
  /// se branche dessus (branchement app-wide = ST7, hors périmètre ST4).
  Future<bool> isNoAdsActive(String trailId) async {
    // MODE PUBS DE TEST : SEUL L'ABONNEMENT ETEINT LA PUBLICITE
    // (tache 639, DEM-260930-1224).
    //
    // La demande de Christophe : « Et j aimerais voir les pubs sur la version de
    // test », et la règle posée avec Skynet : « bannière et vidéo de test
    // visibles sur tout sentier tant qu'on n'est pas abonné ». Sans cette
    // dérogation, un testeur qui possède le sentier qu'il teste ne voit JAMAIS de
    // publicité — l'exception « acheté » suffit à tout éteindre, et c'est
    // exactement ce qui s'est passé quand le sentier gratuit a disparu du
    // catalogue.
    //
    // L'ABONNEMENT RESTE RESPECTE, ET C'EST VOULU : c'est le seul des trois états
    // qui se PAIE en argent tous les mois. Le priver de ce qu'il paie, même sur un
    // build de test, serait la mauvaise dérogation — et c'est aussi ce qui permet
    // de VERIFIER que l'abonnement éteint bien la publicité.
    //
    // ELLE NE PEUT PAS ATTEINDRE LA PRODUCTION : [AdConfig.testAdsForced] rend
    // `false` dès qu'un ad-unit de production est injecté, quel que soit le
    // `--dart-define`. Un build de release porte ses vrais identifiants.
    if (AdConfig.testAdsForced) return isSubscriberActive();

    // ACHETÉ : permanent, sans échéance (le « sauf » de la règle de Chris).
    if (await accessFor(trailId) == TrailAccess.owned) return true;
    if (await isSubscriberActive()) return true;
    if (await isRewardNoAdsActive()) return true;
    return false;
  }

  // --- Abandon / reprise ----------------------------------------------------

  /// Enregistre l'abandon d'un trek : les étapes acquises deviennent la BASE de
  /// rachat à la reprise (spec §2.4). Ne détruit rien, ne rembourse rien.
  ///
  /// On mémorise le complément store DÉJÀ consommé
  /// (`consumedComplementSteps`) pour que la reprise ne le refasse pas payer :
  /// à la reprise, seules les étapes NON encore acquises sont (re)dues.
  Future<void> onTrailAbandoned(String trailId) async {
    final e = await _entitlementsDao.getByTrailId(trailId);
    if (e == null) return;
    // Le trek n'est plus "owned" (abandonné) mais acquiredStages est conservé
    // comme base de rachat. Le complément déjà consommé reste tracé.
    final now = _now();
    await _entitlementsDao.upsert(
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

  /// Devis de REPRISE : ne facture que les étapes non encore acquises.
  ///
  /// Identique à [quoteTrail] mais explicite sur l'intention de reprise : le
  /// besoin = `prix − acquis` (les étapes déjà acquises ne sont pas repayées,
  /// spec §2.5 « rachat du complément consommé »). Prix lu au catalogue.
  Future<TrailQuote> quoteResume(String trailId) {
    return _quote(
      trailId,
      totalStages: stagesOfTrail(trailId),
      useAcquired: true,
    );
  }

  /// Reprend un trek abandonné : rachète UNIQUEMENT le complément restant.
  ///
  /// Même algo que [buyTrail] (wallet d'abord, complément store, rollback si
  /// hors-ligne/échec), mais le besoin part des étapes déjà acquises. Le prix
  /// vient du catalogue, comme pour l'achat (avenant 614).
  Future<PurchaseOutcome> resumeTrail(String trailId) {
    return buyTrail(trailId);
  }

  // --- Restauration / reset -------------------------------------------------

  /// Restaure les achats passés (abo, recharges) via le store, ET DIT CE QU'ELLE
  /// A PU FAIRE (tâche 594, A3).
  ///
  /// Délègue au [WalletIapService] ; les événements arrivent en `restored` sur
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
    if (enDemo) {
      return const PurchaseRestoreOutcome(
        status: PurchaseRestoreStatus.storeUnavailable,
      );
    }
    if (!await _iap.isAvailable()) {
      _log.w(
        '[Monetization] Restauration demandée mais achat in-app '
        'indisponible',
      );
      return const PurchaseRestoreOutcome(
        status: PurchaseRestoreStatus.storeUnavailable,
      );
    }
    await _iap.restorePurchases();
    return const PurchaseRestoreOutcome(
      status: PurchaseRestoreStatus.requested,
    );
  }

  /// Réinitialise TOUT l'état monétisation (tests / support).
  ///
  /// Efface les droits, les sources sans-pub et le cache [FeatureFlags] premium.
  /// Le solde du compte-étapes est laissé à [WalletStore] (non touché ici).
  Future<void> reset() async {
    // DEMO : une demonstration n'efface pas les droits REELS du randonneur
    // (tache 634). Rien ne s'ecrit pendant une demo, et effacer est encore une
    // ecriture.
    if (enDemo) return;
    final entitlements = await _entitlementsDao.getAll();
    for (final e in entitlements) {
      await _entitlementsDao.deleteByTrailId(e.trailId);
      FeatureFlags.setOverride('premium', e.trailId, enabled: false);
    }
    await _noAdsDao.clear();
    _log.d('[Monetization] reset');
  }

  // --- Features (rétro-compat) ----------------------------------------------

  /// Resynchronise le cache synchrone [FeatureFlags] premium depuis les droits.
  ///
  /// `premium:trailId = owned`. Les gardes de routes synchrones lisent ce cache ;
  /// il est réalimenté au boot ([load]) et à chaque mutation.
  ///
  /// LES SENTIERS GRATUITS N'Y ENTRENT PAS (tâche 601). `premium` dit « ce trek a
  /// été PAYÉ » : y inscrire un sentier gratuit — ce que faisait la boucle
  /// vitrine — c'est refabriquer l'exemption dans un cache. Leur jouabilité est
  /// portée par [accessFor], source unique, qui lit leur prix.
  Future<void> _syncFeatureFlags() async {
    final entitlements = await _entitlementsDao.getAll();
    for (final e in entitlements) {
      FeatureFlags.setOverride('premium', e.trailId, enabled: e.owned);
    }
  }

  /// Features du mode gratuit : préparation avec pub + démo.
  TrailFeatures getTrialFeatures() {
    return const TrailFeatures(
      hasAds: true,
      isDemo: true,
      hasGpsTracking: false,
      hasJournal: false,
      hasDiploma: false,
      hasGoodies: false,
      freeFollowerSlots: 0,
      hasPreparation: true,
    );
  }

  /// Features du mode premium (jouable) : tout, sans pub.
  TrailFeatures getPremiumFeatures() {
    return const TrailFeatures(
      hasAds: false,
      isDemo: false,
      hasGpsTracking: true,
      hasJournal: true,
      hasDiploma: true,
      hasGoodies: true,
      freeFollowerSlots: 2,
      hasPreparation: true,
    );
  }

  /// Features applicables pour un trek : premium si JOUABLE (trek acheté ou
  /// vitrine), sinon démo bridée. Décision dérivée d'[accessFor].
  ///
  /// LA PUB EST DÉCIDÉE À PART (règle d'or #99404) : l'abonné light reste en
  /// démo bridée — il n'a pas acheté le trek — mais il n'a PAS de pub. Les deux
  /// axes viennent de la même source ([TrailAccess.isPlayable] et
  /// [TrailAccess.showAds]), ils ne sont simplement plus confondus.
  Future<TrailFeatures> featuresForTrail(String trailId) async {
    final access = await accessFor(trailId);
    final base = access.isPlayable ? getPremiumFeatures() : getTrialFeatures();
    return base.withAds(access.showAds);
  }

  /// Vrai si le trek est en mode démo (non jouable).
  ///
  /// Un trek est en démo s'il n'est ni possédé, ni couvert par un abo, ni
  /// vitrine (parité GR20). Async car dérive des droits Drift.
  Future<bool> isDemoMode(String trailId) async {
    final access = await accessFor(trailId);
    return !access.isPlayable;
  }
}
