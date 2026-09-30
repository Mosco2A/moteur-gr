/// ENTRER EN DEMO, ET EN SORTIR D'UN SEUL BLOC (tache 638, bugs 18 et 19).
///
/// BUG 19 (DEM-260930-1028), verbatim de Christophe, 30/09 10:28 : « quand on
/// quitte le mode demo, ca doit revenir a Mes treks !!! la on se retrouve dans un
/// mode demo batard ! on est toujours en mode demo sans le savoir !!!! ».
///
/// CE QUI SE PASSAIT, MESURE. La sortie du lot 634 tenait en une ligne :
/// `sessionDemoProvider.notifier.sortir()`. Elle effacait le DRAPEAU, et rien
/// d'autre :
///   * le sentier de demo restait SELECTIONNE ([selectedTrailIdProvider]) — donc
///     le cockpit, la carte, le sac et le journal continuaient de montrer la
///     demo, sans le cadre qui le disait ;
///   * l'ecran courant restait celui de la demo — aucun retour a « Mes treks » ;
///   * les changements faits EN MEMOIRE pendant la demo (etapes de preparation
///     marquees, sac coche, date de depart, duree du programme) restaient dans
///     les providers, et le randonneur les prenait pour les siens ;
///   * la simulation de trek restait en cours dans le gestionnaire de session.
/// C'est exactement le « mode demo batard » : plus aucun signal, et pourtant
/// rien de ce qui etait a l'ecran n'etait vrai.
///
/// CE FICHIER EST LA SORTIE UNIQUE, ET ELLE EST ATOMIQUE. Six gestes, dans cet
/// ordre, et le dernier seulement leve les barrieres d'ecriture :
///   1. la simulation est arretee (sans rien finaliser ni ecrire) ;
///   2. l'etat de tracking d'AVANT la demo est remis en place ;
///   3. le sentier d'AVANT la demo est reselectionne ;
///   4. les providers qui ont vecu en memoire pendant la demo sont jetes, donc
///      relus depuis le telephone (leur vraie valeur) ;
///   5. l'etat de demo est detruit — les barrieres tombent, une vraie ecriture
///      repart normalement ;
///   6. le reglage « cacher le bouton demo » est ecrit s'il a ete demande, puis
///      l'application revient a « Mes treks ».
///
/// L'ORDRE N'EST PAS DECORATIF. Tout le demontage des points 1 a 4 se fait
/// PENDANT que la demo est encore active : c'est ce qui garantit qu'aucun de ces
/// gestes n'ecrit quoi que ce soit. Lever la barriere d'abord, ce serait laisser
/// la simulation ecrire sa derniere session en base en s'arretant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/checklist/providers/checklist_provider.dart';
import '../../features/hub/providers/cockpit_start_providers.dart';
import '../../features/notifications/providers/download_reminder_provider.dart';
import '../../features/planning/providers/planned_days_provider.dart';
import '../../features/planning/providers/planning_provider.dart';
import '../../features/trek/providers/tracking_providers.dart';
import '../config/trail_selection.dart';
import '../engine/trail_engine.dart';
import '../routing/home_location_provider.dart';
import 'session_demo.dart';

/// ENTRE EN DEMO SUR LE MARE A MARE CENTRE COMPLET, et se souvient d'ou l'on
/// venait.
///
/// Le sentier selectionne avant la demo est note dans l'etat de demo pour etre
/// restaure a la sortie (bug 19). C'est la seule chose que l'entree memorise :
/// il n'y a rien d'autre a sauvegarder, parce que rien ne sera ecrit.
void entrerEnDemo(WidgetRef ref) {
  final sentierAvant = ref.read(selectedTrailIdProvider);
  ref.read(sessionDemoProvider.notifier).entrer(sentierAvant: sentierAvant);
  // On entre en demo AVANT de basculer de sentier : la barriere d'ecriture est
  // donc deja posee quand le moteur resout le nouveau sentier.
  choisirSentier(ref, kSentierDeDemo);
}

/// QUITTE LA DEMO : sortie COMPLETE et ATOMIQUE (bug 19), puis retour a
/// « Mes treks ».
///
/// [cacherBouton] porte la case a cocher « Cacher le mode demo » du dialogue de
/// fin (precision de Christophe du 30/09 10:30 sur le bug 18) : cochee, le
/// bouton orange disparait du catalogue et se retrouve dans Mon compte ;
/// decochee, il reste en tete du catalogue. Le reglage est persistant et
/// reversible depuis Mon compte — il ne touche AUCUN droit.
///
/// [context] sert au retour a « Mes treks ». S'il est absent (test unitaire), la
/// sortie s'execute quand meme : c'est l'etat qui fait la sortie, pas l'ecran.
Future<void> quitterLaDemo(
  WidgetRef ref, {
  BuildContext? context,
  bool cacherBouton = false,
}) async {
  final session = ref.read(sessionDemoProvider);
  if (!session.active) return;

  // 1 ET 2. LA SIMULATION S'ARRETE, ET L'ETAT DE TRACKING D'AVANT REVIENT.
  // Encore sous barriere : rien ne part en base.
  await ref.read(trekSessionManagerProvider.notifier).arreterSimulationDemo();

  // 3. LE SENTIER D'AVANT REDEVIENT LE SENTIER ACTIF. Sans cela, « Mes treks »
  // s'ouvrait sur le sentier de la demo : le randonneur restait dans la demo
  // sans le savoir.
  final avant = session.sentierAvant;
  if (avant != null) choisirSentier(ref, avant);

  // 4. LES PROVIDERS QUI ONT VECU EN MEMOIRE PENDANT LA DEMO SONT JETES.
  //
  // Ce sont les seuls endroits ou la demo a change quelque chose : le sac coche,
  // les etapes de preparation marquees, la date de depart, la duree et le
  // decoupage du programme. Les jeter les fait relire depuis le telephone a la
  // prochaine lecture — c'est-a-dire retrouver la VRAIE valeur du randonneur,
  // « l'etat exact d'avant la demo ».
  ref.invalidate(checklistProvider);
  ref.invalidate(prepareCoreStepsProvider);
  ref.invalidate(downloadReminderProvider);
  ref.invalidate(selectedDurationProvider);
  ref.invalidate(plannedDaysProvider);

  // 5. L'ETAT DE DEMO EST DETRUIT — LES BARRIERES TOMBENT ICI, ET PAS AVANT.
  ref.read(sessionDemoProvider.notifier).sortir();

  // 6. LE REGLAGE DEMANDE, PUIS LE RETOUR A MES TREKS.
  await ref.read(boutonDemoCacheProvider.notifier).definir(cacherBouton);
  if (context != null && context.mounted) {
    // `maybeOf` ET PAS `context.go` : la sortie doit rester ATOMIQUE meme si
    // l'appel vient d'un contexte sans routeur (un dialogue monte hors de
    // l'arbre route, un test). Un `context.go` y leve une assertion — et une
    // assertion levee APRES avoir detruit l'etat de demo laisserait exactement
    // l'etat hybride que le bug 19 denonce.
    GoRouter.maybeOf(context)?.go(HomeLocations.maison);
  }
}

/// RELANCE LA DEMO DEPUIS MON COMPTE (bug 18, precision du 30/09 10:30).
///
/// « on pourra la retrouver dans Mon compte » : ce geste est l'autre porte
/// d'entree de la demo, celle qui reste quand le bouton du catalogue a ete
/// cache. Il n'y en a pas une troisieme, et les deux passent par [entrerEnDemo].
void relancerLaDemoDepuisMonCompte(WidgetRef ref, BuildContext context) {
  entrerEnDemo(ref);
  GoRouter.maybeOf(context)?.go('/home');
}
