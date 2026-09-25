// TACHE 562 (LOT K, K1) — LE CHAINON QUI MANQUAIT ENTRE LE DROIT ET LE
// RANDONNEUR.
//
// `DataRetentionService.deleteAccountData` etait correct et prouve par
// vingt-six tests au terme du LOT J, et il n'avait AUCUN APPELANT : pas de
// provider, pas d'ecran, pas de bouton. Un droit qu'on ne peut pas exercer n'est
// pas un droit. Ce fichier est la couche qui le rend atteignable depuis l'UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/data_retention_service.dart';
import '../../../core/services/recovery_code_service.dart';
import '../../after/providers/adventure_recap_provider.dart'
    show latestTrekSessionProvider;
import '../../booking/providers/nuitee_selections_provider.dart';
import '../../diploma/providers/session_trace_provider.dart';
import '../../consent/providers/consent_ui_providers.dart';
import '../../feasibility/data/hiker_profile_repository.dart';
import '../../journal/providers/journal_day_providers.dart';
import '../../journal/providers/journal_providers.dart';
import '../../safety/presentation/health_info_screen.dart'
    show healthInfoRepositoryProvider;
import '../../trail/providers/progress_provider.dart';
import '../../treks/providers/my_treks_provider.dart' show myTreksProvider;

/// Service de retention / droit a l'effacement, branche sur la base REELLE de
/// l'application et sur les preferences REELLES.
///
/// `FutureProvider` parce que `SharedPreferences.getInstance()` est
/// asynchrone ; la base vient de [databaseProvider], donc de la meme instance
/// que le reste de l'app (un effacement sur une autre instance n'effacerait
/// rien de ce que le randonneur voit).
final dataRetentionServiceProvider =
    FutureProvider<DataRetentionService>((ref) async {
  final db = ref.watch(databaseProvider);
  final prefs = await SharedPreferences.getInstance();
  return DataRetentionService(database: db, prefs: prefs);
});

/// Signature de l'effacement du compte. Injectable : un ecran ne doit pas avoir
/// besoin d'une base pour etre teste, et l'effacement reel doit pouvoir etre
/// observe dans un test d'ecran.
typedef AccountErasure = Future<DeletionReport> Function();

/// L'effacement du compte, tel que l'UI l'appelle.
///
/// PERIMETRE, DIT SANS ARRONDI : l'effacement est LOCAL. Aucune demande de
/// suppression serveur n'est emise, pour une raison et une seule — il n'existe
/// aujourd'hui aucun compte serveur a supprimer : Firebase n'est pas connecte
/// avant la phase 4, aucun identifiant hache n'est attribue, et les gardes de
/// l'article 9 refusent tout envoi sans consentement. Le jour ou un miroir cloud
/// existera, il faudra passer ici l'`uidHash` et une `ServerDeletionRequest` :
/// `deleteAccountData` sait deja les emettre EN PREMIER et laisse remonter
/// l'erreur. Le libelle montre au randonneur ne promet donc rien de plus que ce
/// qui est fait.
final accountErasureProvider = Provider<AccountErasure>((ref) {
  return () async {
    final service = await ref.read(dataRetentionServiceProvider.future);
    final report = await service.deleteAccountData();
    // QUATRIEME ETAGE DE STOCKAGE : LA MEMOIRE VIVE. Voir
    // [oublierLesDonneesPersonnellesEnMemoire]. L'oubli fait partie de
    // l'effacement, pas de l'ecran qui le declenche : un autre appelant
    // (raccourci, lien profond, geste du systeme) ne peut donc pas l'omettre.
    oublierLesDonneesPersonnellesEnMemoire(ref);
    return report;
  };
});

/// VIDE LES CACHES EN MEMOIRE DES DONNEES PERSONNELLES — quatrieme etage de
/// stockage de l'effacement (tache 564, LOT M, M1).
///
/// CE QUE LA CAMPAGNE A MESURE (verdict #100501). Effacement joue en vrai : le
/// disque est propre — la fiche randonneur se relit VIDE — mais l'ecran « Vos 5
/// dernieres randos » affiche TOUJOURS la randonnee saisie avant l'effacement, et
/// le moteur de faisabilite rend encore un verdict.
///
/// LA SIGNATURE QUI DESIGNE LA CAUSE. Les deux ecrans ne lisent pas au meme
/// endroit. La fiche randonneur relit le repository a chaque ouverture, donc elle
/// voit le disque efface. L'ecran des randos passees lit un provider Riverpod
/// (`pastHikesProvider`) que rien n'invalidait : il resservait son instantane
/// d'avant l'effacement. Une fiche vide a cote d'une liste pleine, dans la meme
/// session : c'est l'asymetrie qui prouve que le disque etait propre et que
/// c'etait la memoire vive qui parlait.
///
/// ET CE N'ETAIT PAS QU'UN AFFICHAGE. L'ecran des randos passees repart de cet
/// instantane pour enregistrer (`_addOrEdit` lit le provider puis persiste la
/// liste ENTIERE) : ajouter une randonnee apres un effacement REECRIVAIT sur le
/// disque les randonnees effacees. La donnee revenait, durablement. C'est la
/// « reecriture apres l'effacement », et son declencheur etait le cache.
///
/// ON INVALIDE D'ABORD LES RACINES, PAS LES ECRANS. Riverpod propage
/// l'invalidation a tous les dependants d'un provider : invalider un REPOSITORY
/// emporte donc tous les ecrans qui en derivent, presents ET futurs — un ecran
/// ajoute demain au-dessus de l'une de ces racines est couvert sans qu'on y
/// pense. C'est le meme renversement que pour les tables et les prefs aux LOTS J
/// et K : on ne tient pas la liste de ce qu'il faut vider.
///
/// POURQUOI PAS `databaseProvider`, QUI SERAIT LA RACINE DE TOUT. Ce serait la
/// seule invalidation a ecrire, et elle est ECARTEE POUR UNE RAISON PRECISE :
/// `appBootstrapProvider` l'observe, donc la re-creer rejouerait l'amorce, donc
/// `monetizationReadyProvider.load()` — qui DEMARRE L'ECOUTE DES ACHATS et n'a
/// pas de `dispose`. On se retrouverait avec deux abonnements IAP et le risque de
/// crediter deux fois un achat rejoue par le store. Un effacement de donnees
/// personnelles ne doit rien casser du cote de ce que le randonneur a paye.
///
/// LES FEUILLES NOMMEES CI-DESSOUS le sont donc chacune pour une raison, et la
/// raison est ecrite. Leur completude ne repose pas sur la bonne volonte : elle
/// est verrouillee par `account_erasure_memory_test.dart`, qui rejoue LIGNE PAR
/// LIGNE la promesse affichee au randonneur (« Ce qui part ») et exige que rien
/// ne soit plus servi apres l'effacement — et par le test d'empreinte de cette
/// promesse, qui echoue si le texte change sans que la preuve suive.
void oublierLesDonneesPersonnellesEnMemoire(Ref ref) {
  // RACINE — fiche randonneur (age, taille, poids), randos passees, note
  // d'experience, test de marche 6 min, et tout le moteur de faisabilite qui
  // s'en nourrit.
  ref.invalidate(hikerProfileRepositoryProvider);

  // RACINE — fiche de renseignement medical (art. 9, LOCAL ONLY).
  ref.invalidate(healthInfoRepositoryProvider);

  // RACINE — journal du randonneur (entrees, photos, quota du jour).
  ref.invalidate(journalRepositoryProvider);

  // FEUILLE — etapes marchees. Sa seule racine est `databaseProvider` (voir
  // ci-dessus). Famille indexee par sentier : l'invalider vide TOUTES ses
  // instances, et c'est ce qu'on veut — l'effacement ne connait pas de sentier.
  ref.invalidate(progressProvider);

  // FEUILLES — traces GPS et les chiffres qu'on en tire. Meme racine interdite.
  // `journalDayStatsProvider` derive de la trace et tombe avec elle ; le cumul
  // depuis le depart relit la base lui-meme, il est donc nomme. La trace du
  // diplome aussi.
  ref.invalidate(journalDayTraceProvider);
  ref.invalidate(journalCumulativeStatsProvider);
  ref.invalidate(sessionTraceProvider);

  // FEUILLES — randonnees FAITES : la liste « Mes treks » et le recapitulatif
  // d'aventure. Elles racontent les etapes marchees autant que la table de
  // progression, et elles seraient restees affichees apres l'effacement.
  ref.invalidate(myTreksProvider);
  ref.invalidate(latestTrekSessionProvider);

  // FEUILLE — nuitees choisies (type + reservation, par nuit). Meme racine
  // interdite, et son notifier lit la base en `read` : rien ne le reconstruirait.
  ref.invalidate(nuiteeSelectionsProvider);

  // FEUILLES — autorisations. Le service de consentement ne CACHE rien (il relit
  // les prefs a chaque appel), donc l'invalider ne jetterait rien : ce sont ses
  // lectures affichees qu'il faut reprendre. Et l'effacement RETIRE les cles sans
  // prendre de decision, donc aucun evenement ne part sur
  // `ConsentService.changes`, le flux qui rafraichit l'affichage le reste du
  // temps (M2).
  ref.invalidate(consentStatesProvider);
  ref.invalidate(consentPromptNeededProvider);

  // FEUILLE — code de reconnexion. IL EST BIEN MIS EN CACHE, contrairement a ce
  // qu'on croirait d'un secret lu dans le keystore : `recoveryCodeProvider` garde
  // la valeur rendue, et il l'aurait donc encore affichee alors que le keystore
  // etait vide — un code que le randonneur recopie et qui n'ouvre plus rien. On
  // l'invalide SANS LE RELIRE : sa lecture est un `getOrCreate`, qui RE-CREERAIT
  // et reecrirait un code dans le keystore qu'on vient de vider. Invalider ne fait
  // que jeter la valeur gardee ; un nouveau code ne naitra que si un ecran en
  // redemande un, et c'est alors legitime.
  ref.invalidate(recoveryCodeProvider);

  // VOLONTAIREMENT HORS PERIMETRE, ET DIT : L'ENREGISTREMENT EN COURS
  // (`trackingProvider`, `trekSessionManagerProvider`). Ces deux notifiers portent
  // l'etat d'une randonnee EN TRAIN de se faire — chronometre, distance du jour,
  // etapes validees de la session. Les remettre a zero au milieu d'une marche
  // arreterait le suivi du randonneur sans le lui dire, et l'effacement n'a pas a
  // decider d'interrompre sa journee. Ce qui est sur le disque est efface ; l'etat
  // de la session vivante s'eteint avec elle.
  //
  // HORS PERIMETRE AUSSI, POUR UNE RAISON TECHNIQUE PRECISE :
  // `pendingSessionProvider`. `appBootstrapProvider` l'OBSERVE, donc l'invalider
  // rejouerait l'amorce — et avec elle `monetizationReadyProvider.load()`, avec le
  // double abonnement IAP decrit plus haut. Il ne porte de toute facon qu'un
  // pointeur vers une session orpheline, dont la table vient d'etre videe.
}
