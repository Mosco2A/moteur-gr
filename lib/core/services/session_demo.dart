/// LA DEMO VOLONTAIRE — UN MODE QU'ON CHOISIT, SUR LE VRAI SENTIER, ET QUI
/// N'ECRIT RIEN.
///
/// TACHE 638 (DEM-260930-1014, bug 8). Retour de test de Christophe du 30/09,
/// verbatim : « la demo de Mare a Mare ce doit etre la demo de Mare a Mare, pas
/// un truc avec 2 etapes !! ». Le lot 634 ouvrait un sentier de demonstration
/// AMPUTE (`mare_a_mare_centre_demo_trail_config.dart`, deux etapes, lot 601) ;
/// ce sentier n'existe plus, et la demo s'applique au sentier REEL, entier.
///
/// TACHE 634 (DEM-260929-1123), toujours valable. Retour de Christophe du 29/09
/// 11:23 : « il faut mettre demo en haut des sentiers juste un bouton "paasez en
/// mode demo" » ; « LE MODE DEMO c est juste un mode demo, on prend Mare a Mare,
/// ce sera toujours lui » ; « un bouton demo qui montre comment marche l appli de
/// A a Z » ; « ON EST EN MODE DEMO » = rien ne compte.
///
/// CE FICHIER EST UNE FEUILLE : il ne connait que Riverpod, le catalogue des
/// sentiers et les preferences. L'ENTREE et la SORTIE, elles, touchent au
/// tracking, a la selection de sentier et aux ecrans : elles vivent dans
/// `pilote_demo.dart`, qui importe celui-ci. Sans cette separation, la barriere
/// d'ecriture (lue par le sac, le journal, la monetisation, le GPS) importerait
/// en retour le moteur de trek qui l'importe deja — dependance croisee.
///
/// TROIS PROPRIETES, ET CHACUNE REPOND A UNE PHRASE DE CHRISTOPHE.
///
/// 1. LA SESSION DE DEMO NE VIT QU'EN MEMOIRE. Aucune table, aucun fichier,
///    aucune preference. Fermer l'application met fin a la demo. C'est la
///    garantie la plus forte qu'on puisse donner a « rien ne compte » : il n'y a
///    rien a nettoyer, parce qu'il n'y a jamais rien eu a ecrire.
///
///    SEULE EXCEPTION, ET ELLE N'EST PAS L'ETAT DE LA DEMO : le reglage
///    « cacher le bouton demo » ([boutonDemoCacheProvider]), demande par
///    Christophe le 30/09 a 10:30. C'est une PREFERENCE D'AFFICHAGE du
///    catalogue, persistante et reversible depuis Mon compte — elle ne dit
///    jamais qu'une demo est en cours, et elle n'accorde aucun droit.
///
/// 2. ELLE EST ATTACHEE A UN SENTIER PRECIS, et toujours le meme : le Mare a
///    Mare Centre COMPLET (sept etapes, refuges, ravitaillements, POI,
///    faisabilite — les memes donnees que la version payante).
///
/// 3. ELLE NE DEBLOQUE RIEN — GARDE-FOU DU LOT 601. Ce lot avait supprime le
///    drapeau `isShowcaseTrail` parce qu'une exemption est un trou dans le
///    modele d'acces. Ce mode-ci n'accorde AUCUN droit : `ownsTrail`,
///    `canRealizeTrail` et `isDemoMode` du [MonetizationService] repondent
///    EXACTEMENT la meme chose pendant la demo et hors demo. Ce qui change,
///    c'est que les ecrans se laissent VISITER et que la rando se SIMULE — et
///    que tout ce qui s'y passe meurt a la sortie.
///
/// LA DEMO MONTRE, ELLE NE DEBLOQUE RIEN.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/mare_a_mare_centre_trail_config.dart';

/// L'identifiant du sentier de demonstration : le VRAI Mare a Mare Centre.
///
/// Toujours le meme (« on prend Mare a Mare, ce sera toujours lui »), et c'est
/// le sentier COMPLET : sept etapes. Le sentier ampute a deux etapes du lot 601
/// a ete supprime avec le bug 8 (DEM-260930-1014).
final String kSentierDeDemo = mareAMareCentreTrailConfig.id;

/// L'etat de la demo volontaire — EN MEMOIRE, pour la duree de la session.
///
/// Il porte aussi ce qu'il faut pour REVENIR EN ARRIERE (bug 19,
/// DEM-260930-1028, verbatim : « quand on quitte le mode demo, ca doit revenir a
/// Mes treks !!! la on se retrouve dans un mode demo batard ! »). Sans memoire
/// de l'etat d'avant, quitter la demo laissait le sentier de demo selectionne :
/// l'application semblait revenue en reel alors qu'elle montrait encore la demo.
class SessionDemo {
  /// Hors demo.
  const SessionDemo.inactive() : trailId = null, sentierAvant = null;

  /// En demo sur [trailId], en se souvenant du sentier selectionne AVANT.
  const SessionDemo.sur(this.trailId, {this.sentierAvant});

  /// Le sentier parcouru en demo, `null` hors demo.
  final String? trailId;

  /// Le sentier qui etait selectionne avant d'entrer en demo, a restaurer a la
  /// sortie. `null` si inconnu (ou hors demo).
  final String? sentierAvant;

  /// Vrai pendant une demo.
  bool get active => trailId != null;

  @override
  bool operator ==(Object other) =>
      other is SessionDemo &&
      other.trailId == trailId &&
      other.sentierAvant == sentierAvant;

  @override
  int get hashCode => Object.hash(trailId, sentierAvant);

  @override
  String toString() => active
      ? 'SessionDemo($trailId, avant: $sentierAvant)'
      : 'SessionDemo(hors)';
}

/// Le pilote de l'ETAT de la demo : entrer, sortir. Rien d'autre.
///
/// Les CONSEQUENCES de l'entree et de la sortie (bascule de sentier, arret de la
/// simulation, retour a Mes treks, purge des changements en memoire) sont dans
/// `pilote_demo.dart` : ce notifier-ci doit rester lisible par la barriere
/// d'ecriture sans rien importer du moteur de trek.
class SessionDemoNotifier extends Notifier<SessionDemo> {
  @override
  SessionDemo build() => const SessionDemo.inactive();

  /// Entre en demo sur le sentier de demonstration.
  ///
  /// N'ACCEPTE QUE LUI. Un appel avec un autre sentier est refuse en silence :
  /// la demo est celle du Mare a Mare Centre, et d'aucun autre sentier. Ce
  /// refus n'est PAS un droit accorde — voir l'en-tete du fichier : aucun
  /// verdict de [MonetizationService] ne change pendant une demo.
  void entrer({String? trailId, String? sentierAvant}) {
    final cible = trailId ?? kSentierDeDemo;
    if (cible != kSentierDeDemo) return;
    state = SessionDemo.sur(cible, sentierAvant: sentierAvant);
  }

  /// Quitte la demo. Rien a effacer en base : rien n'y a ete ecrit.
  void sortir() => state = const SessionDemo.inactive();
}

/// L'etat de la demo volontaire, en memoire pour la duree de la session.
final sessionDemoProvider = NotifierProvider<SessionDemoNotifier, SessionDemo>(
  SessionDemoNotifier.new,
);

/// Vrai pendant une demo volontaire — le raccourci que lisent les ecrans et la
/// barriere d'ecriture.
final enDemoProvider = Provider<bool>(
  (ref) => ref.watch(sessionDemoProvider).active,
);

// ---------------------------------------------------------------------------
// LE REGLAGE « CACHER LE BOUTON DEMO » (tache 638, precision de Christophe du
// 30/09 10:30 sur le bug 18, DEM-260930-1027).
// ---------------------------------------------------------------------------

/// Cle de preference du reglage « cacher le bouton demo ».
///
/// UNE PREFERENCE D'AFFICHAGE, PAS UN DROIT, ET PAS L'ETAT DE LA DEMO.
/// Christophe, 30/09 10:30 : au moment de quitter la demo, on propose une case
/// a cocher « Cacher le mode demo » ; si elle est cochee, le bouton orange
/// disparait du catalogue et un message dit qu'on pourra le retrouver dans
/// « Mon compte » ; sinon le bouton reste en tete du catalogue comme avant. Le
/// choix est PERSISTANT et REVERSIBLE depuis Mon compte.
///
/// Elle ne dit rien des droits : cacher le bouton ne debloque ni ne verrouille
/// quoi que ce soit, et la demo reste relancable depuis Mon compte.
const String kClefBoutonDemoCache = 'demo_bouton_cache';

/// Le bouton demo est-il masque du catalogue ? (reglage local, persistant)
class BoutonDemoCacheNotifier extends Notifier<bool> {
  @override
  bool build() {
    _relire();
    // Par defaut le bouton est VISIBLE : au premier lancement, la demo doit
    // sauter aux yeux en tete du catalogue.
    return false;
  }

  Future<void> _relire() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    state = prefs.getBool(kClefBoutonDemoCache) ?? false;
  }

  /// Cache ou reaffiche le bouton, et l'ecrit sur le telephone.
  ///
  /// ECRITURE AUTORISEE MEME PENDANT LA DEMO, et c'est voulu : c'est le geste
  /// meme de la sortie (la case cochee dans le dialogue de fin de demo). Ce
  /// n'est pas une donnee de randonnee, c'est un reglage d'affichage — la
  /// barriere d'ecriture protege la base, la cagnotte, les droits et le
  /// journal, pas les preferences d'interface.
  Future<void> definir(bool cache) async {
    state = cache;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kClefBoutonDemoCache, cache);
  }
}

/// Reglage « le bouton demo est cache du catalogue » (persistant, reversible).
final boutonDemoCacheProvider = NotifierProvider<BoutonDemoCacheNotifier, bool>(
  BoutonDemoCacheNotifier.new,
);
