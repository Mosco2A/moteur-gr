/// LA DEMO VOLONTAIRE — UN MODE QU'ON CHOISIT, ET QUI N'ECRIT RIEN.
///
/// TACHE 634 (DEM-260929-1123). Retour de Christophe du 29/09 11:23, pendant
/// son premier test de StepWays sur telephone, verbatim : « il faut mettre demo
/// en haut des sentiers juste un bouton "paasez en mode demo", le tour des
/// ecran devient orange ». Puis, precise le meme jour : « UN BOUTON DEMO ORANGE
/// TOUT BETE, au-dessus des sentiers non achetes : quand tu cliques dessus tu
/// arrives a la demo Mare a Mare » ; « LE MODE DEMO c est juste un mode demo,
/// on prend Mare a Mare, ce sera toujours lui » ; « un bouton demo qui montre
/// comment marche l appli de A a Z » ; « ON EST EN MODE DEMO » = rien ne compte.
///
/// CE QU'IL Y AVAIT AVANT, ET POURQUOI CHRISTOPHE L'A REFUSE. Le « mode demo »
/// etait SUBI : `isDemoMode(trailId)` valait `!estJouable(trailId)`, autrement
/// dit « ce sentier n'est pas a toi ». Personne ne le choisissait, et personne
/// n'etait prevenu. Taper un sentier non achete ouvrait son cockpit de
/// preparation, avec la publicite, sans un mot — verbatim de Christophe :
/// « MAIS NON !!! il s ouvre en mode prepa AVEC PUB !!! ».
///
/// CE QUE CE FICHIER APPORTE : un mode qu'on ENTRE et qu'on QUITTE, par un
/// geste. Trois proprietes, et chacune repond a une phrase de Christophe.
///
/// 1. IL NE VIT QU'EN MEMOIRE. Aucun `SharedPreferences`, aucune table, aucun
///    fichier. Fermer l'application met fin a la demo. C'est la garantie la
///    plus forte qu'on puisse donner a « rien ne compte » : il n'y a rien a
///    nettoyer, parce qu'il n'y a jamais rien eu a ecrire.
///
/// 2. IL EST ATTACHE A UN SENTIER PRECIS, et toujours le meme : le sentier de
///    demonstration du lot 601, deux etapes, gratuit. « on prend Mare a Mare,
///    ce sera toujours lui ».
///
/// 3. IL NE DEBLOQUE RIEN — GARDE-FOU DU LOT 601. Ce lot avait supprime le
///    drapeau `isShowcaseTrail` parce qu'une exemption est un trou dans le
///    modele d'acces. Ce mode-ci n'accorde AUCUN droit : il ouvre un sentier
///    qui est deja gratuit pour tout le monde. Le jour ou quelqu'un voudra lui
///    faire ouvrir un sentier payant, il faudra rouvrir ce trou — et ce fichier
///    est la pour dire non.
///
/// LA DEMO MONTRE, ELLE NE DEBLOQUE JAMAIS.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/mare_a_mare_centre_demo_trail_config.dart';

/// L'identifiant du sentier de demonstration. Toujours le meme.
final String kSentierDeDemo = mareAMareCentreDemoTrailConfig.id;

/// L'etat de la demo volontaire.
class SessionDemo {
  /// Hors demo.
  const SessionDemo.inactive() : trailId = null;

  /// En demo sur [trailId].
  const SessionDemo.sur(this.trailId);

  /// Le sentier parcouru en demo, `null` hors demo.
  final String? trailId;

  /// Vrai pendant une demo.
  bool get active => trailId != null;

  @override
  bool operator ==(Object other) =>
      other is SessionDemo && other.trailId == trailId;

  @override
  int get hashCode => trailId.hashCode;

  @override
  String toString() => active ? 'SessionDemo($trailId)' : 'SessionDemo(hors)';
}

/// Le pilote de la demo : entrer, sortir.
class SessionDemoNotifier extends Notifier<SessionDemo> {
  @override
  SessionDemo build() => const SessionDemo.inactive();

  /// Entre en demo sur le sentier de demonstration.
  ///
  /// N'ACCEPTE QUE LUI. Un appel avec un autre sentier est refuse en silence :
  /// c'est la porte par laquelle un sentier payant deviendrait gratuit, et elle
  /// est fermee par construction (garde-fou du lot 601). La demo MONTRE, elle
  /// ne DEBLOQUE jamais.
  void entrer({String? trailId}) {
    final cible = trailId ?? kSentierDeDemo;
    if (cible != kSentierDeDemo) return;
    state = SessionDemo.sur(cible);
  }

  /// Quitte la demo. Rien a effacer : rien n'a ete ecrit.
  void sortir() => state = const SessionDemo.inactive();
}

/// L'etat de la demo volontaire, en memoire pour la duree de la session.
final sessionDemoProvider = NotifierProvider<SessionDemoNotifier, SessionDemo>(
  SessionDemoNotifier.new,
);

/// Vrai pendant une demo volontaire — le raccourci que lisent les ecrans.
final enDemoProvider = Provider<bool>(
  (ref) => ref.watch(sessionDemoProvider).active,
);
