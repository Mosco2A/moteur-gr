/// Les fournisseurs Riverpod de la monetisation.
///
/// Morceau de `monetization_service.dart` (lot 645-06, vague 2) :
/// meme bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'monetization_service.dart';

/// Provider Riverpod du [MonetizationService] (StepWays LOT 1, ST4).
///
/// Branché sur les briques ST1-ST3 : [walletStoreProvider],
/// [walletIapServiceProvider], les DAOs de [databaseProvider] et le
/// [connectivityMonitorProvider]. L'initialisation asynchrone ([load]) est
/// awaitée au boot par [monetizationReadyProvider] (corrige l'ancien
/// `loadPurchases()` jamais appelé).
final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  final db = ref.watch(databaseProvider);
  return MonetizationService(
    walletStore: ref.watch(walletStoreProvider),
    entitlementsDao: db.trekEntitlementsDao,
    noAdsDao: db.noAdsDao,
    iapService: ref.watch(walletIapServiceProvider),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
    // LA BARRIERE DE LA DEMO (tache 634, DEM-260929-1123). `ref.read` DANS la
    // fonction, comme `stagesOf` juste en dessous : l'etat est lu A L'INSTANT
    // de l'ecriture, donc entrer ou quitter la demo agit sans reconstruire le
    // service ni invalider quoi que ce soit.
    enDemo: () => ref.read(enDemoProvider),
    // LE PRIX VIENT DU CATALOGUE EFFECTIF (avenant 614), pas du catalogue
    // compilé. La nuance est tout l'enjeu depuis la tâche 605 : un sentier
    // décrit à DISTANCE n'a pas le nombre d'étapes du sentier compilé du même
    // nom, et c'est précisément pour cela que laisser six écrans déclarer
    // chacun leur montant était six occasions de vendre au mauvais prix.
    //
    // `ref.read` DANS la fonction, et non au-dessus : le nombre est lu À
    // L'INSTANT DE L'ACHAT. Un manifeste distant reçu entre-temps est donc pris
    // en compte, sans reconstruire le service ni invalider quoi que ce soit.
    stagesOf: (trailId) {
      for (final trail in ref.read(availableTrailsProvider)) {
        if (trail.id == trailId) return trail.totalStages;
      }
      return TrailCatalog.byId(trailId)?.totalStages ?? 0;
    },
  );
});

/// Provider asynchrone qui garantit le chargement du [MonetizationService].
///
/// À `watch` au boot (`app_bootstrap_provider.dart`) AVANT tout accès aux droits
/// : hydrate le wallet, migre le legacy, démarre l'écoute IAP et resynchronise
/// le cache [FeatureFlags]. Retourne l'instance chargée.
final monetizationReadyProvider = FutureProvider<MonetizationService>((
  ref,
) async {
  final service = ref.watch(monetizationServiceProvider);
  await service.load();
  return service;
});

/// Observe le droit d'accès d'un trek (StreamProvider indexé par `trailId`).
///
/// Émet à chaque mutation Drift des `TrekEntitlements` : c'est le signal qui
/// permet à [isDemoModeProvider] de se réévaluer quand un achat pose `owned`.
final _entitlementProvider = StreamProvider.family<TrekEntitlement?, String>((
  ref,
  trailId,
) {
  return ref.watch(monetizationServiceProvider).watchEntitlement(trailId);
});

/// Mode démo RÉACTIF d'un trek (`isDemoMode`), indexé par `trailId`.
///
/// Remplace l'appel one-shot `FutureBuilder(monetization.isDemoMode(...))` du
/// [PurchaseGateWidget] : en observant [monetizationReadyProvider] (boot) ET
/// [_entitlementProvider] (mutations Drift), le calcul est RELANCÉ dès qu'un
/// achat débloque le trek pendant l'affichage — le bandeau démo ne peut plus
/// rester périmé (réserve QA StepWays LOT 1). Vitrine/abo restent couverts par
/// la source unique [MonetizationService.isDemoMode].
final isDemoModeProvider = FutureProvider.family<bool, String>((
  ref,
  trailId,
) async {
  final service = await ref.watch(monetizationReadyProvider.future);
  ref.watch(_entitlementProvider(trailId)); // relance au flip owned
  return service.isDemoMode(trailId);
});

/// Solde du COMPTE-ÉTAPES, en étapes (correctif L7-1).
///
/// Le portefeuille existait entièrement — table Drift, DAO, `WalletStore`,
/// recharge et débit dans ce service — mais son solde n'était affiché NULLE
/// PART : le randonneur dépensait des étapes sans jamais voir ce qu'il lui en
/// restait. Ce provider n'ajoute aucune règle métier, il expose la source
/// existante ([MonetizationService.watchWalletSteps]) en la faisant précéder du
/// chargement ([monetizationReadyProvider]) — sans quoi le premier rendu
/// afficherait un solde de zéro avant l'hydratation des préférences.
final walletStepsProvider = StreamProvider<int>((ref) async* {
  final service = await ref.watch(monetizationReadyProvider.future);
  // Valeur d'ouverture : le solde déjà hydraté, pour ne pas attendre le
  // premier mouvement du portefeuille avant d'afficher quelque chose.
  yield service.walletSteps;
  yield* service.watchWalletSteps();
});
