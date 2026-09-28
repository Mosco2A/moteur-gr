import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/trail_engine.dart';
import '../../features/trek/data/seed_data_loader.dart';
import '../../features/trek/providers/session_recovery_provider.dart';
import '../../features/trek/providers/stage_providers.dart';
import '../services/monetization_service.dart';
import 'database_provider.dart';

/// Amorce de l'application — chargement initial des donnees (PARITE GR20, LOT 1).
///
/// Probleme corrige (#99423 §4.1) : `SeedDataLoader.seedIfNeeded()` n'etait
/// appele NULLE PART, donc les tables Drift (etapes/POI/trace) restaient vides
/// (carte vide, etapes vides, meteo « introuvable »). Ce provider est le point
/// de boot unique qui declenche le seed du sentier actif AVANT le rendu des
/// ecrans data (voir la garde dans `main.dart`).
///
/// LE SEED FORCE A CHAQUE LANCEMENT A ETE RETIRE (tache 613), ET C'ETAIT UN
/// IMPERATIF, PAS UN NETTOYAGE. Cette amorce effacait le flag `data_seeded` a
/// chaque demarrage parce que la base etait volatile : sans cela, le sentier
/// embarque n'aurait ete seede qu'une fois et la carte serait restee vide au
/// lancement suivant.
///
/// La base est desormais durable — et `seedIfNeeded()` INSERE sans jamais vider.
/// Garder ce forcage aurait donc DUPLIQUE les etapes, les POI et la trace GPX
/// ENTIERE a chaque ouverture de l'application : le randonneur aurait vu sa
/// trace se doubler, se tripler, et la base grossir sans fin. Le flag n'est plus
/// efface ; l'idempotence, qui n'etait vraie que « dans la session », devient
/// vraie tout court.
///
/// ET LE DRAPEAU EN PREFERENCES A DISPARU, PAS ETE DEPLACE. Un drapeau global
/// (`data_seeded`) suffisait quand il etait remis a zero a chaque lancement ;
/// conserve, il aurait empeche le seed du DEUXIEME sentier embarque, puisque
/// cette amorce se rejoue a chaque changement de sentier. Un drapeau PAR SENTIER
/// aurait corrige cela sans corriger le fond : une preference ne peut pas
/// repondre a une question qui porte sur la base, et elle peut mentir dans les
/// deux sens (voir [SeedDataLoader.kDataSeededPrefsKey], qui nomme les deux cas
/// reels). C'est donc la BASE qu'on interroge : « ce sentier est-il deja pose ? ».
/// Le moteur reste generique : le sentier seede est celui de
/// `trailConfigProvider` (une donnee), aucune localite ici.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  final config = ref.watch(trailConfigProvider);

  final prefs = await SharedPreferences.getInstance();

  final loader = SeedDataLoader(db: db, prefs: prefs, trailConfig: config);
  await loader.seedIfNeeded();

  // Synchronise le fil d'etapes sur le sentier seede. `currentTrailIdProvider`
  // derive deja de `trailConfigProvider.id` (defaut), mais on l'ecrit
  // explicitement au cas ou une lecture prealable l'aurait fige a vide.
  ref.read(currentTrailIdProvider.notifier).state = config.id;

  // StepWays LOT 1 (ST4/ST5) : charge le compte-etapes + droits AVANT le rendu.
  // Corrige l'ancien `loadPurchases()` JAMAIS appele : hydrate le wallet, migre
  // les 2 cles prefs legacy vers les droits (idempotent), demarre l'ecoute IAP
  // et resynchronise le cache FeatureFlags premium (gardes de routes synchrones).
  await ref.watch(monetizationReadyProvider.future);

  // StepWays LOT 2 (C4) : reprise orpheline enfin cablee au boot. Nettoie les
  // sessions en cours de plus de 7 jours puis detecte une eventuelle session
  // orpheline (crash/fermeture brutale) que l'UI proposera de reprendre ou
  // d'abandonner (`pendingSessionProvider`). Best-effort en interne : ne bloque
  // jamais le demarrage. AVANT LOT 2, checkPendingSession/cleanOrphans
  // existaient mais n'etaient JAMAIS appeles.
  await ref.watch(pendingSessionProvider.future);
});
