import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_selection.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/monetization_service.dart';

/// Identifiants des treks POSSEDES par l'utilisateur (StepWays LOT 2, Phase 1).
///
/// Point d'injection L1 (spec §1). Comme on est sur la branche WALLET (tables
/// `TrekEntitlements` + `MonetizationService` refondu dispos), il est implemente
/// DIRECTEMENT sur la source reelle — PAS le shim transitoire :
///
///   owned = `TrekEntitlementsDao.owned` (achats confirmes) ∪ VITRINE
///           (sentiers `isShowcaseTrail`, jouables sans achat, parite GR20).
///
/// La vitrine est incluse car un sentier vitrine est traite comme possede
/// (jouable sans achat) partout dans le socle (`MonetizationService.accessFor`
/// -> `TrailAccess.owned`) : il doit apparaitre dans « Mes treks ».
///
/// FutureProvider (lecture async Drift). Depend de [monetizationReadyProvider]
/// pour garantir que le boot est passe (hydratation wallet + migration des
/// achats legacy vers les droits) AVANT de lister les possedes : sans ca, un
/// achat legacy pas encore migre manquerait a l'appel. La liste des sentiers
/// vitrine derive du catalogue ([availableTrailsProvider]), overridable en test.
final ownedTrailIdsProvider = FutureProvider<Set<String>>((ref) async {
  // Garantit boot + migration legacy passes (droits a jour) avant de lister.
  await ref.watch(monetizationReadyProvider.future);

  final db = ref.watch(databaseProvider);
  final ownedIds = await db.trekEntitlementsDao.owned();

  // Vitrine derivee du catalogue (flag de donnees isShowcaseTrail), jamais un
  // id de localite en dur. Union avec les achats confirmes.
  final showcaseIds = ref
      .watch(availableTrailsProvider)
      .where((c) => c.isShowcaseTrail)
      .map((c) => c.id);

  return <String>{...ownedIds, ...showcaseIds};
});
