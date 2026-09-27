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
///   owned = `TrekEntitlementsDao.owned` (achats confirmes) ∪ SENTIERS GRATUITS
///           (prix nul, donc rien a acheter).
///
/// LES SENTIERS GRATUITS Y SONT, ET CE N'EST PAS UNE EXEMPTION (tache 601). Cette
/// liste repond a « quels sentiers le randonneur peut-il ouvrir », pas a « lesquels
/// a-t-il payes » : un sentier gratuit s'ouvre, il doit donc apparaitre dans « Mes
/// treks ». La liste derive du PRIX porte par le catalogue, la ou elle derivait
/// d'un drapeau d'exemption (`isShowcaseTrail`). Ce qui a disparu au passage, et
/// qui n'avait rien a faire la : ce drapeau resolvait aussi le sentier en
/// `TrailAccess.owned`, donc en sentier PAYE — avec le sans-pub permanent qui va
/// avec. Ici on ne parle que d'ouverture.
///
/// FutureProvider (lecture async Drift). Depend de [monetizationReadyProvider]
/// pour garantir que le boot est passe (hydratation wallet + migration des
/// achats legacy vers les droits) AVANT de lister les possedes : sans ca, un
/// achat legacy pas encore migre manquerait a l'appel. La liste des sentiers
/// gratuits derive du catalogue ([availableTrailsProvider]), overridable en test.
final ownedTrailIdsProvider = FutureProvider<Set<String>>((ref) async {
  // Garantit boot + migration legacy passes (droits a jour) avant de lister.
  await ref.watch(monetizationReadyProvider.future);

  final db = ref.watch(databaseProvider);
  final ownedIds = await db.trekEntitlementsDao.owned();

  // Sentiers GRATUITS derives du PRIX porte par la donnee du catalogue, jamais
  // un id de localite en dur. Union avec les achats confirmes.
  final gratuits = ref
      .watch(availableTrailsProvider)
      .where((c) => c.isFreeTrail)
      .map((c) => c.id);

  return <String>{...ownedIds, ...gratuits};
});
