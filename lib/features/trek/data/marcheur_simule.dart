/// LE MARCHEUR SIMULE DE LA DEMO (tache 742) : il AVANCE sur la trace connue du
/// sentier de demonstration et fabrique des RELEVES, rien de plus.
///
/// ORDRE DE CHRISTOPHE DU 08/10 20:19, verbatim : « Le mode demo doit
/// fonctionner et en mode simulation pour le sentier en mode demo !!! ».
///
/// CE QUI NE MARCHAIT PAS, MESURE (recette du build 12, tache 739). En demo, la
/// barre de la carte affichait Parcouru « -- », Vit. moy. « -- », Altitude
/// « -- », rien ne bougeait apres dix minutes de randonnee lancee, aucun point
/// n'apparaissait sur la carte et le journal du jour restait vide. La cause
/// etait ECRITE dans `tracking_providers.dart` : le GPS de fond n'est pas arme
/// en demo et la session ne s'ecrit nulle part. C'etait VOULU (tache 638, bug
/// 16) pour ne pas demander une autorisation de position a quelqu'un qui ne
/// bouge pas — et c'est toujours voulu. Ce qui manquait, c'est la SOURCE : sans
/// GPS et sans base, PERSONNE ne disait ou se trouvait le randonneur.
///
/// CE QUE CETTE CLASSE EST, ET SURTOUT CE QU'ELLE N'EST PAS.
///
/// ELLE NE CALCULE RIEN DE CE QUI S'AFFICHE. Pas de distance, pas de denivele,
/// pas de vitesse moyenne, pas de Haversine, pas de seuil de bruit de trois
/// metres, pas de plafond de vitesse. Elle fabrique des RELEVES — latitude,
/// longitude, altitude, horodatage — et les fait entrer par LA MEME PORTE que
/// les releves reels : le robinet unique GPS ([PositionController], lot
/// 671-00). Ce sont donc les MEMES fonctions qu'en vrai qui mesurent la marche
/// simulee ([computeTrackStatsOnTrace]). Un deuxieme cumul ici donnerait deux
/// deniveles differents pour la meme demonstration : c'est exactement ce que la
/// chaine de calcul refuse depuis le lot 671-06.
///
/// ELLE N'INVENTE AUCUNE GEOGRAPHIE. Elle avance le long de la trace du sentier
/// actif telle qu'elle est deja chargee pour les chiffres
/// (`statsTraceProvider`), dans l'ordre de ses points, en se placant a une
/// distance cumulee donnee. Cette distance, elle ne la calcule pas non plus :
/// chaque [TrackPoint] porte son `distanceFromStart`. Entre deux points elle
/// interpole pour que le deplacement soit FLUIDE a l'oeil et que les chiffres
/// montent regulierement — ce placement vit a cote, dans
/// [pointSurLaTrace] (`placement_sur_la_trace.dart`), sorti d'ici par la
/// garde de taille ECR-15 a la tache 744.
///
/// LE TEMPS EST ACCELERE, ET LES RELEVES PORTENT LE TEMPS DE LA MARCHE, PAS
/// CELUI DE LA DEMONSTRATION. C'est le point le plus important de ce fichier.
/// Une demonstration dure une minute, pas six heures : une seconde reelle vaut
/// [kFacteurTemps] secondes de marche. Si les releves portaient l'heure REELLE
/// de la demonstration, le moteur de stats — qui divise la distance par l'ecart
/// des horodatages — afficherait une vitesse moyenne de 240 km/h. Les releves
/// portent donc l'HORLOGE DE LA MARCHE : chaque pas avance le temps simule de
/// [kFacteurTemps] fois la periode reelle. Le moteur existant en tire alors
/// tout seul [kVitesseSimuleeKmh], une allure de randonneur. On ne truque pas
/// le chiffre : on lui donne une marche coherente a mesurer.
///
/// ELLE N'ARME AUCUN GPS ET N'ECRIT NULLE PART. Elle ne connait ni Geolocator,
/// ni permission, ni base de donnees, ni preference : regardez ses imports. Les
/// releves qu'elle fabrique vivent dans [releves], en memoire, et meurent avec
/// [arreter]. C'est la raison d'etre du mode demo et les gardes de la tache 742
/// le verifient.
library;

import 'dart:async';

import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState;
import 'package:geolocator/geolocator.dart';

import '../../../core/data/daos/session_track_points_dao.dart';
import '../../../core/data/database.dart' show SessionTrackPoint;
import '../../../core/geo/trace_point.dart';
import 'placement_sur_la_trace.dart';

/// Fabrique de minuteries, injectable pour que les tests ne dorment pas.
typedef FabriqueDeMinuterie =
    Timer Function(Duration periode, void Function(Timer) action);

/// L'etat du marcheur simule, pour les ecrans et pour les gardes.
enum EtatDuMarcheur {
  /// Il n'a pas demarre, ou il a ete arrete : rien en memoire.
  arrete,

  /// Il avance : une position part a chaque periode.
  enMarche,

  /// Il est en pause : plus aucune minuterie, les releves sont conserves.
  enPause,

  /// Il a atteint le bout de la trace : la marche est finie, releves gardes.
  arrive,
}

/// UN MARCHEUR SIMULE SUR LA TRACE DU SENTIER DE DEMONSTRATION.
///
/// Cycle de vie : [demarrer] -> [pause] / [reprendre] -> [arreter]. Il se met
/// TOUJOURS en pause quand l'application passe en arriere-plan, et il REPREND
/// quand elle revient au premier plan si c'est l'arriere-plan qui l'avait
/// interrompu (cf. [_suivreLeCycleDeVie]) ; il s'arrete quand on quitte la
/// demo (`arreterSimulationDemo` appelle [arreter]). Aucune minuterie ne
/// survit a la sortie.
class MarcheurSimule {
  /// [minuterie] et [maintenant] sont injectes par les tests ; en production ce
  /// sont `Timer.periodic` et `DateTime.now`.
  MarcheurSimule({
    FabriqueDeMinuterie? minuterie,
    DateTime Function()? maintenant,
    bool surveillerLeCycleDeVie = true,
  }) : _minuterie = minuterie ?? Timer.periodic,
       _maintenant = maintenant ?? DateTime.now,
       _surveillerLeCycleDeVie = surveillerLeCycleDeVie;

  /// L'ALLURE SIMULEE : celle d'un randonneur charge sur un sentier corse.
  ///
  /// C'est la seule vitesse ecrite dans ce fichier, et elle ne s'affiche
  /// JAMAIS : elle sert a placer le marcheur. La vitesse moyenne montree a
  /// l'ecran est MESUREE par le moteur de stats sur les releves, et c'est elle
  /// qui doit tomber autour de ce chiffre — si elle en differe, c'est le moteur
  /// qui a raison et ce fichier qui a un defaut.
  static const double kVitesseSimuleeKmh = 4.0;

  /// LE FACTEUR D'ACCELERATION : une seconde reelle vaut une minute de marche.
  ///
  /// Choisi pour qu'une demonstration tienne dans le temps d'une phrase : a
  /// [kVitesseSimuleeKmh], une seconde d'ecran avance d'environ 67 m, dix
  /// secondes de 670 m, et une etape de dix kilometres passe en deux minutes et
  /// demie. L'ecran le DIT pendant toute la simulation (`demo.marcheSimulee`) :
  /// personne ne doit croire a une vraie marche.
  static const int kFacteurTemps = 60;

  /// La periode REELLE entre deux releves simules.
  ///
  /// A 500 ms le deplacement est fluide a l'oeil (deux positions par seconde)
  /// et la chaine de calcul reste tranquille : chaque releve declenche une
  /// relecture des releves de la session, et le lot 671-06 avait deja note
  /// cette dette. A 200 ms elle serait sollicitee cinq fois par seconde pour un
  /// gain visuel nul.
  static const Duration kPeriodeReelle = Duration(milliseconds: 500);

  /// Le temps de MARCHE ecoule a chaque periode reelle ([kFacteurTemps] fois
  /// plus que le temps de la demonstration) : 30 s de marche par demi-seconde
  /// d'ecran. Ecrit comme un RAPPORT et non comme une constante a part, pour
  /// qu'il reste juste si l'un des deux reglages change.
  static Duration get pasDeTempsSimule =>
      Duration(milliseconds: kPeriodeReelle.inMilliseconds * kFacteurTemps);

  /// Les metres parcourus a chaque periode, a [kVitesseSimuleeKmh] pendant
  /// [pasDeTempsSimule]. Une multiplication de placement, pas une mesure.
  static double get pasEnMetres =>
      kVitesseSimuleeKmh / 3.6 * (pasDeTempsSimule.inMilliseconds / 1000.0);

  /// Le temps de marche d'une distance, a l'allure simulee — l'inverse exact
  /// de [pasEnMetres]. Le calcul vit dans [tempsDeMarchePour], avec le reste du
  /// placement sur la trace.
  static Duration tempsDeMarcheDe(double metres) =>
      tempsDeMarchePour(metres, kVitesseSimuleeKmh);

  final FabriqueDeMinuterie _minuterie;
  final DateTime Function() _maintenant;
  final bool _surveillerLeCycleDeVie;

  /// LE FLUX, OUVERT UNE FOIS POUR TOUTE LA VIE DU MARCHEUR.
  ///
  /// Il n'est jamais referme par [arreter] : le robinet unique GPS s'y abonne
  /// une fois, et une fermeture lui ferait croire que la source est morte (son
  /// `onStreamDone` ferme alors sa propre sortie). Arreter, c'est cesser
  /// d'emettre — pas couper le tuyau.
  final StreamController<Position> _sortie =
      StreamController<Position>.broadcast();

  /// LE FLUX DES CHANGEMENTS D'ETAT, pour que l'ecran sache quand la marche
  /// part, s'interrompt, arrive ou s'arrete.
  ///
  /// [etat] est un champ : le modifier ne reveille personne, et la mention
  /// « marche simulee » de l'ecran serait restee sur sa premiere valeur. Ce
  /// flux est la notification qui manquait, et il ne porte QUE l'etat — aucun
  /// chiffre de randonnee n'y passe.
  final StreamController<EtatDuMarcheur> _etats =
      StreamController<EtatDuMarcheur>.broadcast();

  Timer? _minute;
  AppLifecycleListener? _cycleDeVie;

  /// VRAI quand c'est L'ARRIERE-PLAN qui a interrompu une marche EN COURS, et
  /// donc que le retour au premier plan doit la relancer.
  ///
  /// POURQUOI UN DRAPEAU ET PAS SEULEMENT L'ETAT « EN PAUSE ». La reprise doit
  /// avoir lieu si et seulement si la marche ETAIT EN COURS : jamais apres
  /// l'arrivee, jamais apres un arret, jamais apres la sortie de demo. Ce
  /// drapeau nomme exactement cette cause. Il garde aussi sa justesse le jour
  /// ou un bouton « Pause » existera dans l'interface : une pause VOULUE par
  /// le randonneur ne doit pas etre defaite par un simple passage d'ecran.
  bool _interrompuParLArrierePlan = false;
  final List<SessionTrackPoint> _releves = <SessionTrackPoint>[];

  List<TrackPoint> _trace = const <TrackPoint>[];
  String _trailId = '';
  String? _sessionId;
  DateTime _departDeLaMarche = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _tempsDeMarche = Duration.zero;
  double _distanceM = 0;
  double _longueurDeLaTrace = 0;
  Position? _dernierePosition;
  EtatDuMarcheur _etat = EtatDuMarcheur.arrete;

  /// LE FLUX DE POSITIONS SIMULEES : la source branchee sur le robinet unique.
  Stream<Position> get positions => _sortie.stream;

  /// LES RELEVES SIMULES, EN MEMOIRE ET NULLE PART AILLEURS.
  ///
  /// Meme type que les releves reels ([SessionTrackPoint]) pour entrer dans la
  /// MEME fonction de statistiques sans l'adapter. Aucune de ces lignes n'a
  /// jamais vu la base : elles ne sont pas lues depuis une table, elles sont
  /// construites ici et jetees par [arreter].
  List<SessionTrackPoint> get releves => List.unmodifiable(_releves);

  /// Ou en est la marche.
  EtatDuMarcheur get etat => _etat;

  /// Les changements de [etat], au fil de la marche.
  Stream<EtatDuMarcheur> get etats => _etats.stream;

  /// Pose [nouveau] et le publie, s'il change vraiment.
  void _changerEtat(EtatDuMarcheur nouveau) {
    if (_etat == nouveau) return;
    _etat = nouveau;
    if (!_etats.isClosed) _etats.add(nouveau);
  }

  /// La derniere position emise, nulle avant le premier pas. Une MEMOIRE : la
  /// lire n'avance rien et n'ouvre rien.
  Position? get dernierePosition => _dernierePosition;

  /// Vrai si une minuterie tourne. C'est ce que les gardes interrogent pour
  /// prouver qu'aucune minuterie ne survit a la sortie de la demo.
  bool get minuterieActive => _minute != null;

  /// La distance simulee depuis le depart, en metres. Sert au placement et aux
  /// tests ; les chiffres de l'ecran, eux, sont mesures par le moteur.
  double get distanceSimuleeM => _distanceM;

  /// DEMARRE LA MARCHE au debut de [trace].
  ///
  /// [trace] est la trace du sentier actif, deja chargee pour les chiffres : on
  /// ne relit aucun fichier et on n'invente aucun point. Une trace de moins de
  /// deux points ne permet pas de marcher : on refuse plutot que de simuler sur
  /// place (renvoie `false`).
  ///
  /// Le depart de la marche est l'instant REEL du depart ; a partir de la, le
  /// temps des releves est celui de la marche, accelere.
  bool demarrer({
    required List<TrackPoint> trace,
    required String trailId,
    String? sessionId,
    DateTime? depart,
  }) {
    if (trace.length < 2) return false;
    arreter();
    _trace = trace;
    _trailId = trailId;
    _sessionId = sessionId;
    _departDeLaMarche = depart ?? _maintenant();
    _longueurDeLaTrace = trace.last.distanceFromStart;
    if (_longueurDeLaTrace <= 0) return false;
    _tempsDeMarche = Duration.zero;
    _distanceM = 0;
    _changerEtat(EtatDuMarcheur.enMarche);

    // LE PREMIER RELEVE PART TOUT DE SUITE, au point de depart du sentier.
    // Sans lui, la carte resterait sans marqueur pendant une demi-seconde et la
    // barre garderait ses tirets : le moteur de stats a besoin de DEUX releves
    // pour avoir une duree mesurable, autant poser le premier sans attendre.
    _emettre();
    _armerLaMinuterie();

    // ELLE S'ARRETE QUAND L'APPLICATION PASSE EN ARRIERE-PLAN, ET ELLE REPREND
    // QUAND ELLE REVIENT. Une simulation qui continuerait d'avancer ecran
    // eteint ferait tourner une minuterie pour une demonstration que personne
    // ne regarde — et surtout, la demo ne doit RIEN faire vivre en fond, c'est
    // sa promesse. Voir [_suivreLeCycleDeVie] pour la reprise.
    if (_surveillerLeCycleDeVie) {
      _cycleDeVie ??= AppLifecycleListener(onStateChange: _suivreLeCycleDeVie);
    }
    return true;
  }

  /// L'ARRIERE-PLAN MET EN PAUSE, LE PREMIER PLAN REPREND (tache 744).
  ///
  /// CE QUI NE MARCHAIT PAS, MESURE A L'EXECUTION (recette du lot 742, tache
  /// 743) : la pause existait, la reprise N'EXISTAIT PAS. Tout passage en
  /// arriere-plan, meme d'une seconde — une notification, une fenetre systeme,
  /// un coup d'oeil a une autre application — arretait la demonstration
  /// DEFINITIVEMENT. Et comme aucun bouton « Reprendre » n'existe dans
  /// l'interface, il fallait quitter la demo et tout recommencer.
  ///
  /// LA PAUSE EN ARRIERE-PLAN RESTE : c'est une promesse du lot 742, rien ne
  /// vit en fond. C'est la REPRISE qui manquait.
  ///
  /// ELLE N'A LIEU QUE SI LA MARCHE ETAIT EN COURS, et le drapeau
  /// [_interrompuParLArrierePlan] est exactement cette condition : apres
  /// l'arrivee, apres un arret et apres la sortie de demo, rien ne redemarre.
  /// Dans ces trois cas l'observateur est d'ailleurs deja relache ([terminer],
  /// [arreter]) — le drapeau est la seconde serrure, pas la seule.
  void _suivreLeCycleDeVie(AppLifecycleState etatDeLApp) {
    if (etatDeLApp == AppLifecycleState.resumed) {
      if (!_interrompuParLArrierePlan) return;
      _interrompuParLArrierePlan = false;
      reprendre();
      return;
    }
    // Les etats intermediaires (`inactive`, `hidden`) passent ici aussi : la
    // premiere pause gagne, les suivantes sont sans effet, et le drapeau ne
    // se pose que sur une marche VRAIMENT en cours.
    if (_etat != EtatDuMarcheur.enMarche) return;
    _interrompuParLArrierePlan = true;
    pause();
  }

  /// MET LA MARCHE EN PAUSE : la minuterie est coupee, les releves restent.
  ///
  /// Sans effet hors marche (une pause de pause n'est pas une erreur).
  void pause() {
    if (_etat != EtatDuMarcheur.enMarche) return;
    _minute?.cancel();
    _minute = null;
    _changerEtat(EtatDuMarcheur.enPause);
  }

  /// REPREND LA MARCHE la ou elle s'etait arretee.
  ///
  /// LE TEMPS DE LA PAUSE NE COMPTE PAS : l'horloge de la marche reprend a
  /// [_tempsDeMarche], pas a l'heure qu'il est. Une pause de dix minutes
  /// pendant la demonstration ne doit pas faire chuter la vitesse moyenne
  /// mesuree — exactement comme la duree « active hors pauses » d'une vraie
  /// randonnee.
  void reprendre() {
    if (_etat != EtatDuMarcheur.enPause) return;
    _changerEtat(EtatDuMarcheur.enMarche);
    _armerLaMinuterie();
  }

  /// AVANCE D'UN COUP JUSQU'A L'ABSCISSE [distanceM] (tache 747).
  ///
  /// POURQUOI. Retours de Christophe du 09/10 : « la fleche orange ... ne
  /// fonctionne pas », « simuler ne fonctionne pas du tout ». Le bouton
  /// n'avancait RIEN — il remplissait `completedStages`, un ensemble que la
  /// barre de la carte ne lit pas. Il faisait avancer un COMPTEUR a cote de la
  /// source de verite. Celle-ci deplace LA SOURCE : nom d'etape, chiffres,
  /// point sur la carte et cadrage se deduisent tous de l'abscisse.
  ///
  /// L'HORLOGE DE LA MARCHE SUIT LA DISTANCE ([tempsDeMarcheDe]) : sans cela le
  /// moteur de statistiques, qui divise la distance par l'ecart des
  /// horodatages, annoncerait une vitesse absurde.
  ///
  /// ELLE NE RECULE JAMAIS, s'arrete au bout de la trace et y declare l'arrivee
  /// comme le dernier pas l'aurait fait. Rend `false` si rien n'a bouge.
  bool allerA(double distanceM) {
    final enMarcheOuEnPause =
        _etat == EtatDuMarcheur.enMarche || _etat == EtatDuMarcheur.enPause;
    if (!enMarcheOuEnPause || _longueurDeLaTrace <= 0) return false;
    final cible = distanceM.clamp(_distanceM, _longueurDeLaTrace);
    if (cible <= _distanceM) return false;

    _tempsDeMarche += tempsDeMarcheDe(cible - _distanceM);
    _distanceM = cible;
    _emettre();
    if (_distanceM >= _longueurDeLaTrace) {
      _minute?.cancel();
      _minute = null;
      _changerEtat(EtatDuMarcheur.arrive);
    }
    return true;
  }

  /// TERMINE LA MARCHE EN GARDANT LES RELEVES : plus de minuterie, mais les
  /// chiffres restent lisibles.
  ///
  /// A NE PAS CONFONDRE AVEC [arreter], et la difference compte. Quand la
  /// randonnee simulee se termine — arrivee atteinte, « Simuler l'arrivee », ou
  /// fin manuelle — le randonneur va REGARDER sa journee : le journal du jour
  /// lit les releves en memoire, et les jeter a cet instant viderait l'ecran
  /// qu'il vient d'ouvrir. On cesse donc d'avancer sans rien effacer. C'est la
  /// SORTIE DE DEMO qui jette tout, parce que c'est elle qui promet qu'il ne
  /// reste rien.
  ///
  /// Le cycle de vie est relache ici aussi : plus rien n'avance, il n'y a plus
  /// rien a mettre en pause.
  void terminer() {
    _minute?.cancel();
    _minute = null;
    _cycleDeVie?.dispose();
    _cycleDeVie = null;
    // L'arrivee efface la cause de reprise : revenir au premier plan apres
    // une arrivee ne doit RIEN relancer.
    _interrompuParLArrierePlan = false;
    if (_etat == EtatDuMarcheur.enMarche || _etat == EtatDuMarcheur.enPause) {
      _changerEtat(EtatDuMarcheur.arrive);
    }
  }

  /// ARRETE LA MARCHE ET JETTE TOUT : minuterie, releves, cycle de vie.
  ///
  /// Appele par `arreterSimulationDemo`, donc par la sortie de demo. Apres lui
  /// il ne reste RIEN en memoire — c'est la garantie « la demo ne survit a
  /// rien », et [minuterieActive] le prouve.
  void arreter() {
    _minute?.cancel();
    _minute = null;
    _cycleDeVie?.dispose();
    _cycleDeVie = null;
    // Un arret — et donc la sortie de demo — efface la cause de reprise.
    _interrompuParLArrierePlan = false;
    _releves.clear();
    _trace = const <TrackPoint>[];
    _dernierePosition = null;
    _distanceM = 0;
    _longueurDeLaTrace = 0;
    _tempsDeMarche = Duration.zero;
    _sessionId = null;
    _changerEtat(EtatDuMarcheur.arrete);
  }

  /// Ferme le marcheur pour de bon (dispose du provider).
  void fermer() {
    arreter();
    unawaited(_sortie.close());
    unawaited(_etats.close());
  }

  void _armerLaMinuterie() {
    _minute?.cancel();
    _minute = _minuterie(kPeriodeReelle, (_) => _pas());
  }

  /// UN PAS : on avance sur la trace, on emet, et on s'arrete au bout.
  void _pas() {
    if (_etat != EtatDuMarcheur.enMarche) return;
    _distanceM += pasEnMetres;
    _tempsDeMarche += pasDeTempsSimule;
    if (_distanceM >= _longueurDeLaTrace) {
      // LE BOUT DE LA TRACE EST LE BOUT DE LA MARCHE. On pose le dernier
      // releve exactement sur l'arrivee, puis on cesse d'emettre : la detection
      // d'arrivee, elle, a recu les positions comme en vrai et fait son travail
      // par son chemin habituel.
      _distanceM = _longueurDeLaTrace;
      _emettre();
      _minute?.cancel();
      _minute = null;
      _changerEtat(EtatDuMarcheur.arrive);
      return;
    }
    _emettre();
  }

  /// Fabrique le releve de la position courante et le fait entrer dans la
  /// chaine : d'abord la memoire des releves, puis le robinet.
  void _emettre() {
    final point = pointSurLaTrace(_trace, _distanceM);
    final horodatage = _departDeLaMarche.add(_tempsDeMarche);

    _releves.add(
      SessionTrackPoint(
        // Un identifiant d'ordre, comme la cle auto-incrementee de la table :
        // ces lignes ne vont dans aucune table, mais les lectures trient et
        // comparent, et un ordre croissant est ce qu'elles attendent.
        id: _releves.length + 1,
        trailId: _trailId,
        sessionId: _sessionId,
        // LE MEME CALCUL DE JOUR DE MARCHE QU'EN VRAI (socle L3-1) : la
        // fonction est prise telle quelle, elle n'est pas recopiee.
        dayIndex: SessionTrackPointsDao.dayIndexFor(
          _departDeLaMarche,
          horodatage,
        ),
        lat: point.lat,
        lng: point.lng,
        altitude: point.altitude,
        recordedAt: horodatage,
        // UN RELEVE, PAS UN POINT ESTIME : la simulation remplace le GPS, elle
        // ne remplace pas le tampon d'economie de batterie. Les lectures qui ne
        // veulent que les releves reels (`gpsOnly`, lot 671-03) doivent le
        // voir, sinon la barre et le journal n'auraient rien a mesurer.
        source: TrackPointSource.gps.stored,
      ),
    );

    final position = Position(
      latitude: point.lat,
      longitude: point.lng,
      timestamp: horodatage,
      accuracy: 5,
      altitude: point.altitude,
      altitudeAccuracy: 3,
      heading: 0,
      headingAccuracy: 0,
      speed: kVitesseSimuleeKmh / 3.6,
      speedAccuracy: 0.5,
    );
    _dernierePosition = position;
    if (!_sortie.isClosed) _sortie.add(position);
  }
}
