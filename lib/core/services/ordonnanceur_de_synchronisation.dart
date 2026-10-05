/// Ce qui REVEILLE la synchronisation — retour du reseau, puis toutes les
/// quatre heures : avant, deux horloges existaient sans appelant.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/trail_data_source.dart';
import '../data/daos/trail_manifests_dao.dart';
import '../models/niveau_de_telechargement.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';
import 'descente_des_droits.dart';
import 'update_downloader.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// CE QUI REVEILLE LA SYNCHRONISATION — ET RIEN NE LA REVEILLAIT.
///
/// DEMANDE DE CHRISTOPHE DU 28/09 09:32, verbatim : « quand l appli recupere du
/// reseau (et ensuite toutes les 4 heures par exemple) elle vient verifier toutes
/// les donnees superieures a sa date de MAJ ».
///
/// LE DEFAUT EST MESURE, PAS SUPPOSE, et il a ete signale par la tache 610 sans
/// etre ferme : `UpdateDownloader.scheduleBackgroundDownload` existe depuis la
/// tache E4.11c et N EST APPELE PAR AUCUN CODE DE PRODUCTION. Toute la mecanique
/// etait la — detection d ecart, transport, pose atomique, notification — mais
/// aucune horloge et aucun evenement ne la declenchaient. Un sentier ne se mettait
/// a jour que si le randonneur rouvrait l ecran du catalogue et appuyait lui-meme.
/// Une mise a jour que personne ne declenche n est pas une mise a jour.
///
/// LES DEUX REVEILS SONT CEUX DE CHRISTOPHE, ET ILS SONT DIFFERENTS PAR NATURE.
///
///  1. LE RETOUR DU RESEAU. C est un EVENEMENT, et c est le plus utile des deux :
///     un randonneur qui redescend d un col retrouve la 4G et doit recevoir ce qui
///     a ete publie pendant qu il marchait. Il est pris sur
///     [ConnectivityMonitor.onStatusChange], qui rend deja un flux debounce a 5
///     secondes — un reseau qui clignote en bord de couverture ne declenche donc pas
///     dix passes.
///
///  2. LES QUATRE HEURES. C est une CADENCE, et elle rattrape le cas ou le reseau
///     n a jamais ete perdu : sans elle, une application restee ouverte et connectee
///     ne verrait jamais rien arriver.
///
/// CE QUE CET ORDONNANCEUR NE FAIT PAS, ET C EST LA GARDE LA PLUS IMPORTANTE DU
/// LOT : IL NE CHANGE JAMAIS LE NIVEAU D UN SENTIER. Chaque sentier est resynchronise
/// au niveau ou il est DEJA descendu (`trail_manifests.niveauLocal`). Reveiller la
/// cadence ne doit pas faire descendre la trace et ses points sur un sentier que le
/// randonneur a seulement prepare — ce serait exactement la demande du 28/09 11:27
/// violee par la porte de derriere, et sans qu il l ait demande : 260 Mo de tuiles
/// et une trace de 10 000 points arrivant tout seuls, toutes les quatre heures.
/// Monter de niveau est un GESTE du randonneur, jamais une consequence d une horloge.
///
/// SON PERIMETRE EST CELUI DES SENTIERS TELECHARGES (`getTelecharges`), pas du
/// catalogue. Le filtre vient de la tache 610 et il tient : la lecture du catalogue
/// ecrit une ligne par sentier PUBLIE, et sans ce filtre un randonneur qui a copie
/// un sentier sur quarante publies en synchroniserait quarante.
class OrdonnanceurDeSynchronisation {
  OrdonnanceurDeSynchronisation({
    required this.downloader,
    required this.dao,
    required this.connectivityMonitor,
    required this.urlManifeste,
    this.cadence = cadenceParDefaut,
    this.descendreLesDroits,
    this.poserLHorloge = Timer.periodic,
  });

  /// LA CADENCE DE CHRISTOPHE : QUATRE HEURES.
  ///
  /// « toutes les 4 heures par exemple ». Le « par exemple » est une invitation a
  /// choisir, pas une approximation a laisser flottante : la valeur vit ici, en un
  /// seul endroit, et se change sans toucher a la mecanique.
  static const Duration cadenceParDefaut = Duration(hours: 4);

  final UpdateDownloader downloader;
  final TrailManifestsDao dao;
  final ConnectivityMonitor connectivityMonitor;

  /// Adresse de la liste distante. Injectee pour que les tests ne devinent pas.
  final String urlManifeste;

  /// Intervalle de la cadence periodique.
  final Duration cadence;

  /// LA DESCENTE DES DROITS, SI ELLE EST BRANCHEE (tache 631).
  ///
  /// UN RAPPEL ET PAS LE SERVICE : l ordonnanceur n a aucune raison de connaitre
  /// Firestore, ni le compte-etapes, ni les droits. Il sait seulement QUAND
  /// reveiller, et c est deja tout ce qu on lui demande. Le branchement se fait
  /// dans son provider.
  ///
  /// POURQUOI ICI ET PAS DANS UN SECOND ORDONNANCEUR. Les deux reveils qui
  /// comptent — le retour du reseau et la cadence — sont deja armes ici, avec
  /// leur verrou d unicite et leur garde hors ligne. En ecrire un second
  /// donnerait deux horloges a tenir d accord, pour exactement les memes deux
  /// evenements.
  final Future<Object?> Function()? descendreLesDroits;

  /// COMMENT L'HORLOGE PERIODIQUE EST POSEE. `Timer.periodic` en production.
  ///
  /// POURQUOI CE POINT D'INJECTION EXISTE, ET C'EST UNE AFFAIRE DE MESURE, PAS
  /// DE CONFORT (tache 695, kaizen #101267). Le test de la cadence ne pouvait
  /// pas observer l'horloge : il la laissait battre pour de vrai, dormait un
  /// budget en TEMPS REEL, puis affirmait qu'une passe avait eu lieu. Mesure du
  /// 05/10 pendant le build 10 : `expect(avant, greaterThanOrEqualTo(1))` a rendu
  /// `Actual: <0>` — le minuteur de 25 ms n'avait pas encore fini UNE passe au
  /// bout de 80 ms de sommeil, parce que la machine etait occupee. Le test
  /// mesurait donc la vitesse de la machine de fabrication, pas le reveil de la
  /// synchronisation : rouge environ une fois sur trois, et pour une raison qui
  /// n'apprend rien.
  ///
  /// ET IL PERMET DE PROUVER UN NEGATIF, CE QU'AUCUNE ATTENTE NE PERMET. « Apres
  /// `stop()`, l'horloge ne bat plus » se demontrait en dormant et en esperant :
  /// avec ce point d'injection, le test REJOUE le battement apres l'arret et
  /// exige qu'il ne se passe rien. C'est plus dur que l'ancienne version, pas
  /// moins.
  ///
  /// LA PRODUCTION N'EST PAS TOUCHEE : la valeur par defaut EST
  /// `Timer.periodic`, et une garde verifie qu'elle le reste (sinon le reveil
  /// de la cadence ne serait plus branche sur une vraie horloge).
  final Timer Function(Duration, void Function(Timer)) poserLHorloge;

  Timer? _horloge;
  StreamSubscription<ConnectivityStatus>? _ecouteReseau;

  /// UNE SEULE PASSE A LA FOIS, ET CE VERROU N EST PAS DECORATIF.
  ///
  /// Les deux reveils peuvent tomber ensemble : le randonneur retrouve le reseau a
  /// l instant ou les quatre heures echoient. Deux passes concurrentes ouvriraient
  /// deux transactions sur les memes tables et pourraient inscrire deux reperes
  /// pour un seul jeu de donnees.
  bool _enCours = false;

  /// Vrai quand une passe de synchronisation est en train de tourner.
  bool get enCours => _enCours;

  /// Nombre de passes REELLEMENT executees depuis le demarrage.
  ///
  /// Mesure, pas decoration : c est ce qui permet a un test d affirmer qu un reseau
  /// qui clignote ne declenche pas dix passes, et qu un passage HORS ligne n en
  /// declenche aucune.
  int get passesExecutees => _passesExecutees;
  int _passesExecutees = 0;

  /// Vrai si l ordonnanceur est demarre.
  bool get demarre => _horloge != null || _ecouteReseau != null;

  /// BRANCHE LES DEUX REVEILS. Idempotent : un second appel ne double rien.
  ///
  /// IL NE SYNCHRONISE PAS AU DEMARRAGE, et c est un choix. Le lancement de
  /// l application est le moment ou tout se dispute le reseau et le processeur
  /// (base, Firebase, catalogue, publicite) ; y ajouter le transport des donnees de
  /// tous les sentiers copies ralentirait le premier ecran pour un gain nul — la
  /// premiere echeance arrive de toute facon, et le retour du reseau est un
  /// evenement plus pertinent qu un demarrage.
  void start() {
    if (demarre) {
      _log.d('[Ordonnanceur] Deja demarre — second appel ignore.');
      return;
    }

    _horloge = poserLHorloge(cadence, (_) => _passer('cadence'));

    _ecouteReseau = connectivityMonitor.onStatusChange.listen(
      (statut) {
        // SEUL LE RETOUR EN LIGNE DECLENCHE. Un passage hors ligne est
        // l evenement inverse : lancer une passe a ce moment-la ne ferait que
        // produire un echec de transport et des journaux trompeurs.
        if (statut == ConnectivityStatusValues.online) {
          _passer('retour du reseau');
        }
      },
      onError: (Object e) =>
          _log.w('[Ordonnanceur] Flux de connectivite en erreur : $e'),
    );

    // LA DESCENTE DES DROITS PART TOUT DE SUITE, ET ELLE EST LA SEULE (tache
    // 631). Le commentaire de cette methode explique pourquoi le transport des
    // SENTIERS n a rien a faire au demarrage : il se dispute le reseau avec
    // tout le reste pour un gain nul. La descente des droits est l exact
    // contraire — trois petits documents, et c est ce que le randonneur attend
    // en ouvrant l application apres un achat. Non attendue : le premier ecran
    // ne l attend pas.
    unawaited(_descendreLesDroits('demarrage'));

    _log.d(
      '[Ordonnanceur] Demarre : retour du reseau + cadence de '
      '${cadence.inHours} h. Perimetre : les sentiers TELECHARGES, chacun a son '
      'propre niveau.',
    );
  }

  /// Arrete les deux reveils. Idempotent.
  ///
  /// Une passe deja en cours n est PAS interrompue : elle tient une transaction, et
  /// l abandonner en cours de route est precisement ce que la copie atomique
  /// interdit. Elle finira, puis rien ne la relancera.
  Future<void> stop() async {
    _horloge?.cancel();
    _horloge = null;
    await _ecouteReseau?.cancel();
    _ecouteReseau = null;
    _log.d('[Ordonnanceur] Arrete.');
  }

  /// UNE PASSE : CHAQUE SENTIER TELECHARGE, A SON NIVEAU.
  ///
  /// Publique pour que les tests puissent la declencher sans attendre quatre
  /// heures ni simuler une carte SIM — et parce qu un geste « verifier
  /// maintenant » dans l interface s y branchera sans ajouter de chemin.
  Future<List<UpdateDownloadResult>> passer([String cause = 'appel direct']) =>
      _passer(cause);

  /// Une passe de descente des droits, isolee du reste.
  ///
  /// SON ECHEC NE FAIT PAS ECHOUER LA PASSE. Ne pas avoir pu relire ses droits
  /// n est pas une raison pour ne pas mettre a jour ses sentiers, et encore
  /// moins pour tuer l ordonnanceur.
  Future<void> _descendreLesDroits(String cause) async {
    final descente = descendreLesDroits;
    if (descente == null) return;
    try {
      final resultat = await descente();
      _log.d('[Ordonnanceur] Descente des droits ($cause) : $resultat');
    } catch (e) {
      _log.w('[Ordonnanceur] Descente des droits ($cause) en echec : $e');
    }
  }

  Future<List<UpdateDownloadResult>> _passer(String cause) async {
    // LE VERROU SE POSE AVANT LE PREMIER `await`, ET C EST TOUT L INTERET.
    //
    // DEFAUT MESURE PAR LE TEST DE CE LOT, PAS SUPPOSE. Une premiere version
    // interrogeait la connectivite d abord et ne posait le verrou qu ensuite :
    // deux passes lancees au meme instant franchissaient TOUTES LES DEUX le
    // `if (_enCours)` avant que l une ait pu lever le drapeau, parce que
    // `checkStatus()` rend la main a la boucle d evenements. Le cas n est pas
    // theorique — c est precisement le scenario que Christophe a demande : le
    // randonneur retrouve le reseau a l instant ou les quatre heures echoient, et
    // les deux reveils tombent ensemble. Deux passes concurrentes ouvriraient deux
    // transactions sur les memes tables et pourraient inscrire deux reperes pour un
    // seul jeu de donnees.
    if (_enCours) {
      _log.d(
        '[Ordonnanceur] Passe ($cause) ignoree : une synchronisation tourne '
        'deja.',
      );
      return const [];
    }
    _enCours = true;

    try {
      final statut = await connectivityMonitor.checkStatus();
      if (statut == ConnectivityStatusValues.offline) {
        _log.d('[Ordonnanceur] Passe ($cause) ignoree : hors ligne.');
        return const [];
      }

      // LES DROITS D ABORD, ET SANS DEPENDRE DES SENTIERS (tache 631). Placee
      // ici, AVANT le compteur et avant le « aucun sentier telecharge, rien a
      // verifier » : un randonneur qui vient d acheter n a peut-etre encore
      // copie aucun sentier, et c est justement le moment ou ses droits doivent
      // descendre.
      await _descendreLesDroits(cause);

      _passesExecutees++;
      final telecharges = await dao.getTelecharges();
      if (telecharges.isEmpty) {
        _log.d(
          '[Ordonnanceur] Passe ($cause) : aucun sentier telecharge, rien a '
          'verifier.',
        );
        return const [];
      }

      // LE NIVEAU DE CHAQUE SENTIER EST RELU EN BASE, JAMAIS SUPPOSE. C est ce qui
      // garantit qu un sentier prepare reste prepare : la cadence ne porte pas de
      // niveau a elle.
      final niveaux = <String, NiveauDeTelechargement>{};
      for (final ligne in telecharges) {
        niveaux[ligne.trailId] =
            NiveauDeTelechargement.depuisLeCode(ligne.niveauLocal) ??
            NiveauDeTelechargement.regarder;
      }

      _log.d(
        '[Ordonnanceur] Passe ($cause) sur ${telecharges.length} sentier(s) '
        'telecharge(s) : '
        '${niveaux.entries.map((e) => "${e.key}=${e.value.code}").join(", ")}',
      );

      // ON PASSE PAR `scheduleBackgroundDownload`, PAS PAR `downloadAllUpdates`.
      //
      // C est LA methode que la tache 610 avait signalee comme existante et jamais
      // appelee, et c est elle qui porte le point d injection du travail en
      // arriere-plan ([BackgroundTaskRunner]). L appeler directement par-dessous
      // laisserait cette abstraction morte une seconde fois : le jour ou un
      // runner workmanager est injecte, c est ici que la cadence doit en
      // beneficier, sans qu on ait a recabler l ordonnanceur.
      //
      // LE `await` N EST PAS COSMETIQUE, ET SON ABSENCE VIDAIT LES DEUX GARDES DE
      // CETTE METHODE (tache 620, warning `unawaited_return_in_try_block` leve par
      // la machine de fabrication). `scheduleBackgroundDownload` est une methode
      // `async` qui attend REELLEMENT la fin du transport ; la rendre sans
      // l attendre faisait sortir du `try` a l instant ou le transport DEMARRE, et
      // non quand il finit. Deux consequences, toutes deux mesurables :
      //
      //  1. LE `finally` LIBERAIT `_enCours` PENDANT LE TRANSPORT. Le verrou juste
      //     au-dessus se documente « une seule passe a la fois, et ce verrou n est
      //     pas decoratif » — il l etait pourtant des que les deux reveils ne
      //     tombaient pas dans le MEME tour de boucle d evenements : le retour du
      //     reseau a l instant T et l echeance a T+1 ms trouvaient le drapeau deja
      //     rabaisse et ouvraient la seconde transaction que ce verrou existe pour
      //     interdire. Le test « deux passes ne se chevauchent pas » ne le voyait
      //     pas parce qu il lance ses deux passes dans le meme tour.
      //  2. LE `catch` NE RATTRAPAIT RIEN. Une erreur de transport ne passait plus
      //     par le journal ci-dessous ; elle ressortait dans le futur rendu par
      //     `_passer`, que `Timer.periodic` ne regarde pas — donc en erreur
      //     asynchrone non traitee, exactement ce que « une passe qui echoue ne tue
      //     pas l ordonnanceur » promet d empecher.
      return await downloader.scheduleBackgroundDownload(
        manifestUrl: urlManifeste,
        levelByTrail: niveaux,
      );
    } catch (e) {
      // UNE PASSE QUI ECHOUE NE TUE PAS L ORDONNANCEUR. Le prochain retour de
      // reseau ou la prochaine echeance reessaiera. Avaler l erreur sans la DIRE
      // serait la faute inverse : elle est journalisee.
      _log.e('[Ordonnanceur] Passe ($cause) en echec : $e');
      return const [];
    } finally {
      _enCours = false;
    }
  }
}

/// Provider de l ordonnanceur.
///
/// IL N EST PAS AUTO-DEMARRE PAR SA CREATION, et c est deliberé : un provider lu
/// par un test ne doit pas se mettre a battre toutes les quatre heures. Le
/// demarrage est un geste explicite du demarrage de l application
/// ([ordonnanceurDemarreProvider]).
final ordonnanceurDeSynchronisationProvider =
    Provider<OrdonnanceurDeSynchronisation>((ref) {
      final db = ref.watch(databaseProvider);
      final ordonnanceur = OrdonnanceurDeSynchronisation(
        downloader: ref.watch(updateDownloaderProvider),
        dao: TrailManifestsDao(db),
        connectivityMonitor: ref.watch(connectivityMonitorProvider),
        urlManifeste: TrailDataSource.urlManifeste,
        // TACHE 631 — LA DESCENTE DES DROITS SE BRANCHE ICI, et l ordonnanceur
        // n en sait rien d autre que « appelle ca quand tu te reveilles ».
        // `ref.read` DANS le rappel : le service est construit au premier reveil,
        // pas a la creation de l ordonnanceur — il a besoin des preferences, qui
        // sont asynchrones.
        descendreLesDroits: () async {
          final descente = await ref.read(descenteDesDroitsProvider.future);
          return descente.executer();
        },
      );
      ref.onDispose(ordonnanceur.stop);
      return ordonnanceur;
    });

/// LE GESTE QUI REVEILLE LA CADENCE, ET IL N EXISTAIT PAS.
///
/// Observe par `_BootstrapGate` dans `main.dart` — la garde qui vit au-dessus du
/// `Navigator` et ne se demonte jamais. C est la seule place correcte : un
/// ordonnanceur branche depuis un ECRAN s arreterait en changeant d ecran (Riverpod
/// met en pause les abonnements d un ecran qui n est plus a l avant-plan), et une
/// cadence qui s arrete quand on navigue n est pas une cadence.
///
/// IL NE BLOQUE PAS LE DEMARRAGE : il ne rend rien, ne declenche aucune passe a la
/// creation, et se contente d armer l horloge et l ecoute du reseau. Le premier
/// ecran s affiche sans attendre le moindre octet.
/// ET IL NE PEUT PLUS EMPORTER L ECRAN AVEC LUI (tache 637, volet 2).
/// `demarrer()` etait appele NU dans ce `create` : tout ce qu il levait sortait du
/// provider, remontait dans le `ref.watch` que `BootstrapGate` fait de lui, et
/// faisait lever le `build` de la garde qui enveloppe TOUS les ecrans — donc un
/// `ErrorWidget` plein cadre, un rectangle noir en release. Une cadence qui ne
/// s arme pas coûte une cadence ; elle ne doit pas coûter l application.
final ordonnanceurDemarreProvider = Provider<void>((ref) {
  try {
    ref.watch(ordonnanceurDeSynchronisationProvider).start();
  } catch (erreur) {
    _log.d('[Ordonnanceur] Armement abandonne ($erreur).');
  }
});
