/// L'amorce qui APPELLE enfin la pose des donnees : sans elle, les tables
/// restaient vides parce que personne ne declenchait le seeder.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/trail_engine.dart';
import '../../features/feasibility/data/hiker_profile_repository.dart';
import '../../features/safety/presentation/health_info_screen.dart'
    show ficheMedicaleFichierProvider;
import '../../features/trek/data/seed_data_loader.dart';
import '../../features/trek/providers/session_recovery_provider.dart';
import '../../features/trek/providers/stage_providers.dart';
import '../services/garde_sauvegarde_ios.dart';
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
/// L'EXCLUSION iCLOUD DE LA FICHE MEDICALE EST REPOSEE ICI, A CHAQUE DEMARRAGE
/// (tache 615). Elle est posee a chaque ecriture de la fiche, ce qui protege ce
/// que l'application ecrit ELLE-MEME — mais pas le telephone d'un randonneur qui
/// avait deja rempli sa fiche avec la version de la tache 613 et met a jour :
/// celui-la ne reecrira peut-etre plus jamais sa fiche, et son `fiche.json` est
/// deja dans iCloud sans attribut. C'est l'amorce, et elle seule, qui repasse
/// derriere lui. Meme discipline que le re-alignement de la copie sauvegardable :
/// le disque converge vers la decision a chaque ouverture.
///
/// ELLE EST ATTENDUE, ET SANS RISQUE POUR LE DEMARRAGE : hors iPhone elle rend la
/// main sans toucher au canal natif, sur iPhone elle est bornee par
/// `ExclusionSauvegardeIcloud.delaiMax`, et elle ne leve jamais.
///
/// TACHE 617 — LE BALAYAGE COUVRE MAINTENANT TOUT LE STOCKAGE CONFIE, PAS SEULE
/// LA FICHE MEDICALE, ET IL PASSE APRES L'OUVERTURE DE LA BASE. La regle generale
/// de Christophe du 28/09 14:31 (« on ne partage aucune donnee confiee sauf si le
/// client decoche volontairement ») vaut pour la progression, le journal, les
/// photos et le profil. Cote Android une seule inclusion suffit et elle est
/// declarative ; cote iPhone il faut poser l'attribut chemin par chemin
/// ([GardeSauvegardeIos]).
///
/// L'ORDRE N'EST PAS INDIFFERENT : `ref.watch(databaseProvider)` puis une
/// requete ouvrent le fichier de la base, et le balayage doit passer APRES pour
/// que ce fichier existe deja et recoive son attribut. C'est pour cela que
/// l'appel est place apres le seed et non au debut. Un balayage place avant
/// laisserait la base hors de sa portee jusqu'au lancement suivant.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  final config = ref.watch(trailConfigProvider);

  await ref.read(ficheMedicaleFichierProvider).garantirExclusion();

  // TACHE 623 — LE PROFIL DU RANDONNEUR QUITTE LES PREFERENCES ICI, ET C'EST LE
  // SEUL ENDROIT QUI PUISSE LE FAIRE POUR UN TELEPHONE DEJA INSTALLE.
  //
  // Sur iPhone, `NSUserDefaults` (ce que `SharedPreferences` utilise) ne peut PAS
  // etre exclu de la sauvegarde iCloud : ce n'est pas un fichier de
  // l'application mais un domaine de preferences du systeme
  // (`SauvegardeSysteme.trouUserDefaultsIos`). L'age, la taille et le poids
  // montaient donc dans iCloud, contre la regle de Christophe du 27/09 en
  // majuscules. La migration les transporte vers le MEME fichier protege que la
  // fiche medicale, puis retire les cles.
  //
  // POURQUOI ICI ET PAS SEULEMENT A LA PREMIERE LECTURE DU PROFIL : on remplit sa
  // fiche UNE fois, avant de partir. Un randonneur qui met a jour l'application
  // et ne rouvre jamais l'ecran de faisabilite garderait son poids dans iCloud
  // pour toujours. C'est le meme raisonnement que `garantirExclusion` ci-dessus
  // (tache 615), et la migration est idempotente : sans cle heritee, elle ne fait
  // rien. Elle ne leve jamais.
  //
  // ET L'EXCLUSION EST REPOSEE DANS LE MEME GESTE, pour la meme raison que pour
  // la fiche : l'ecriture atomique remplace le fichier, et un fichier remplace ne
  // porte plus l'attribut de celui qu'il remplace.
  final profil = ref.read(hikerProfileRepositoryProvider);
  await profil.migrerDepuisPreferences();
  await profil.fichier.garantirExclusion();

  final prefs = await SharedPreferences.getInstance();

  final loader = SeedDataLoader(db: db, prefs: prefs, trailConfig: config);
  await loader.seedIfNeeded();

  // LE BALAYAGE IPHONE, ICI ET PAS PLUS HAUT : le seed vient d'ouvrir le fichier
  // de la base, donc il existe et peut recevoir son attribut. Sans objet hors
  // iPhone (il ne parcourt meme pas le disque), borne et non levant sur iPhone.
  await ref.read(gardeSauvegardeIosProvider).balayer();

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
