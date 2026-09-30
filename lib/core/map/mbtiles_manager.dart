import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../data/empreinte_de_publication.dart';
import '../error/error_handler.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// CE QUI SE PASSE PENDANT UNE DESCENTE DE CARTE, VU DU RANDONNEUR.
///
/// Consigne de Christophe pour la tache 622 : « ce qui descend, son poids, et un
/// moyen d annuler ». Les trois sont des VALEURS, pas des journaux : un ecran ne
/// peut afficher que ce qu on lui rend.
class ProgressionDeCarte {
  const ProgressionDeCarte({
    required this.trailId,
    required this.octetsRecus,
    required this.octetsTotal,
  });

  final String trailId;

  /// Octets presents sur le telephone, REPRISE COMPRISE.
  ///
  /// C est bien « ou en est le fichier », pas « combien a voyage pendant cet
  /// appel » : un randonneur qui reprend une descente a 70 % doit voir 70 %, pas
  /// zero.
  final int octetsRecus;

  /// Poids total annonce par la liste distante (`TrailManifestEntry.tilesSize`).
  final int octetsTotal;

  /// Avancement dans [0..1]. Zero si le total est inconnu — jamais une division
  /// par zero, jamais un pourcentage invente.
  double get fraction =>
      octetsTotal <= 0 ? 0 : (octetsRecus / octetsTotal).clamp(0, 1);

  /// Le poids TEL QU ON LE DIT A UN RANDONNEUR, en megaoctets.
  ///
  /// Mega = 1 000 000 octets, pas 1 048 576 : c est l unite des forfaits mobiles
  /// et des magasins d applications. Un ecart de 5 % sur 260 Mo, c est 13 Mo que
  /// le randonneur croirait avoir en trop.
  static double enMegaoctets(int octets) => octets / 1000000;

  @override
  String toString() =>
      '[$trailId] ${enMegaoctets(octetsRecus).toStringAsFixed(1)}'
      ' / ${enMegaoctets(octetsTotal).toStringAsFixed(1)} Mo';
}

/// POURQUOI UNE DESCENTE DE CARTE S EST ARRETEE. Jamais un booleen.
///
/// Chaque cause commande une SUITE DIFFERENTE, et c est la raison d etre de cette
/// enumeration : ce qui reste sur le telephone n est pas le meme selon la cause, et
/// ce que l ecran doit proposer au randonneur non plus.
enum EchecDeCarte {
  /// Le transport a echoue (coupure, serveur, code HTTP inattendu).
  ///
  /// LE FICHIER PARTIEL EST CONSERVE : c est exactement le cas ou la reprise
  /// existe. Un randonneur en bord de couverture ne doit pas recommencer 260 Mo
  /// parce qu un tunnel a coupe la liaison.
  reseau,

  /// Les octets recus ne correspondent PAS a l empreinte annoncee.
  ///
  /// LE FICHIER PARTIEL EST DETRUIT, et c est le seul cas ou on detruit. Reprendre
  /// une descente dont le contenu est faux ne pourra JAMAIS produire la bonne
  /// empreinte : on repart de zero au prochain essai. Un `.mbtiles` est une base
  /// SQLite — une carte fausse ne se voit qu au premier carreau manquant, en
  /// montagne, sans reseau.
  empreinteInvalide,

  /// Le serveur n a pas rendu le nombre d octets annonce par la liste.
  ///
  /// Distinct de [empreinteInvalide] parce que la CAUSE est ailleurs : la liste
  /// distante et le fichier publie ne concordent pas. Le partiel est detruit pour
  /// la meme raison — sa longueur ne sera jamais la bonne.
  tailleInattendue,

  /// Plus de place sur le telephone.
  ///
  /// LE PARTIEL EST CONSERVE : liberer de la place puis reprendre est le geste
  /// naturel, et il ne doit pas coûter un second transport complet.
  plusDePlace,

  /// L ecriture locale a echoue pour une autre raison (permission, support
  /// retire). Le partiel est conserve : la cause peut disparaitre.
  ecritureImpossible,

  /// LE TELEPHONE NE REND PAS SON ESPACE DE STOCKAGE (tache 640, bug 9).
  ///
  /// C est le cas ou l on ne sait meme pas OU ecrire : `path_provider` ne repond
  /// pas (canal de plateforme absent, processus recycle, profil restreint), ou la
  /// creation du dossier `mbtiles` echoue. Il est distinct de
  /// [ecritureImpossible] parce que RIEN n a ete tente : aucune connexion n est
  /// ouverte, aucun octet n est ecrit, et il n y a donc aucun partiel a garder.
  ///
  /// POURQUOI CETTE CAUSE EXISTE MAINTENANT. Avant la tache 640 ce cas ne
  /// produisait pas un echec : il LEVAIT. `getMbtilesPath` etait la premiere
  /// ligne de [MBTilesManager.descendre], hors de tout filet ; l exception
  /// traversait [DescenteDesCartes] puis le controleur (dont le `try` n avait pas
  /// de `catch`) et ressortait dans un futur que personne n attend — donc en
  /// erreur asynchrone non traitee, remontee comme un plantage FATAL. C est la
  /// forme exacte du retour de Christophe du 30/09 : « en demo comme en vrai
  /// telecharger les cartes plante ».
  stockageIndisponible,

  /// Le randonneur a annule.
  ///
  /// LE PARTIEL EST CONSERVE, et c est ce qui distingue une annulation d un refus :
  /// annuler ne doit pas punir. Le fichier definitif, lui, n a jamais existe.
  annulee,
}

/// CE QU UNE DESCENTE DE CARTE A REELLEMENT FAIT. Mesure, pas suppose.
class ResultatDeCarte {
  const ResultatDeCarte({
    required this.trailId,
    required this.octetsSurLeTelephone,
    required this.octetsTransferes,
    required this.octetsReprisDuDisque,
    this.echec,
  });

  final String trailId;

  /// Taille du fichier a l arrivee (definitif si [reussie], partiel sinon).
  final int octetsSurLeTelephone;

  /// Octets qui ont REELLEMENT voyage pendant cet appel.
  ///
  /// C est le chiffre du forfait du randonneur, et il est la pour etre verifie :
  /// une reprise qui retelechargerait tout se verrait ici, pas dans un journal.
  final int octetsTransferes;

  /// Octets qui etaient DEJA la et n ont pas ete redemandes (reprise).
  final int octetsReprisDuDisque;

  /// Pourquoi ca s est arrete, ou `null` si la carte est posee.
  final EchecDeCarte? echec;

  bool get reussie => echec == null;

  /// Vrai si cet appel a repris une descente commencee avant lui.
  bool get estUneReprise => octetsReprisDuDisque > 0;
}

/// LE MOYEN D ANNULER, ET IL EST EXPLICITE.
///
/// Un jeton passe a la descente plutot qu une methode `annuler()` sur le
/// gestionnaire : le gestionnaire est un SINGLETON partage (un provider), et une
/// annulation portee par lui arreterait la descente de n importe quel sentier. Le
/// jeton, lui, appartient au geste qui l a cree.
class AnnulationDeDescente {
  bool _demandee = false;

  /// Vrai des que [annuler] a ete appele.
  bool get demandee => _demandee;

  /// Demande l arret. Idempotent, et sans effet apres la fin de la descente.
  void annuler() => _demandee = true;
}

/// Gestionnaire des fichiers de cartes hors ligne (`.mbtiles`) d un sentier.
///
/// LES FICHIERS VIVENT DANS `documents/mbtiles/{trailId}.mbtiles`, et cet
/// emplacement n est pas un detail : c est LA ou la carte les lit
/// (`OfflineTileProvider` -> `MbTilesTileProvider.fromPath`). Un second stockage de
/// tuiles a existe dans le depot — le stockage du magasin de packs, sous
/// `documents/packs/` — et il etait deconnecte de la carte : ce qu il aurait
/// telecharge n aurait JAMAIS ete affiche. Il a ete RETIRE par la tache 640, avec
/// le magasin qu il servait (bugs 9 et 10 du test de Christophe du 30/09).
///
/// CE QUE CETTE CLASSE FAISAIT AVANT LA TACHE 622, ET POURQUOI C ETAIT
/// INUTILISABLE. `downloadMbtiles` tenait en six lignes : `_httpClient.get(url)`
/// puis `file.writeAsBytes(response.bodyBytes)`. Trois defauts fatals, et le
/// premier suffisait :
///
///  1. `response.bodyBytes` CHARGE TOUT LE FICHIER EN MEMOIRE. Le chiffrage de la
///     tache 608 mesure 260 Mo de tuiles en z10-16 pour un sentier : sur un
///     telephone d entree de gamme, c est la mort du processus, pas un
///     ralentissement.
///  2. AUCUNE REPRISE. Une coupure a 95 % recommencait 260 Mo depuis zero — sur
///     une liaison de montagne, la descente n aboutissait jamais.
///  3. ECRITURE DIRECTEMENT SUR LE NOM DEFINITIF, SANS VERIFICATION. Une coupure
///     laissait un `.mbtiles` a moitie ecrit, que `hasMbtiles` declarait present et
///     que la carte ouvrait comme une base SQLite valide. Le randonneur partait
///     avec une carte qui echouerait au premier carreau manquant, en montagne.
///
/// LA FORME ACTUELLE EST CELLE DU RESTE DU DEPOT : transport en FLUX, ecriture dans
/// un fichier `.partiel`, reprise par en-tete `Range`, empreinte SHA-256 verifiee
/// AVANT que le fichier ne prenne son nom definitif — le meme ordre que
/// `SourceFichierEntier` (tache 607), pour la meme raison : « un fichier tronque
/// mais syntaxiquement valide passait la copie ».
class MBTilesManager {
  MBTilesManager({
    http.Client? httpClient,
    Future<Directory> Function()? dossierDocuments,
    IOSink Function(File fichier, {required bool enAjout})? ouvrirEnEcriture,
  }) : _httpClient = httpClient ?? http.Client(),
       _dossierDocuments = dossierDocuments ?? getApplicationDocumentsDirectory,
       _ouvrirEnEcriture = ouvrirEnEcriture ?? _ouvertureParDefaut;

  final http.Client _httpClient;
  final Future<Directory> Function() _dossierDocuments;

  /// COMMENT ON OUVRE LE FICHIER EN ECRITURE — INJECTABLE, ET PAS PAR CONFORT.
  ///
  /// « Que se passe-t-il quand la place manque sur le telephone ? » est une
  /// question de la consigne, et une reponse non mesuree ne vaut rien. Un disque
  /// plein ne se simule pas sur la machine d un developpeur ; une ouverture
  /// injectable, si. Le test de ce lot fournit un puits qui leve `ENOSPC` apres
  /// quelques milliers d octets, et VERIFIE qu aucun `.mbtiles` definitif
  /// n apparait.
  final IOSink Function(File fichier, {required bool enAjout})
  _ouvrirEnEcriture;

  static IOSink _ouvertureParDefaut(File fichier, {required bool enAjout}) =>
      fichier.openWrite(mode: enAjout ? FileMode.append : FileMode.write);

  /// Sous-dossier de stockage des MBTiles dans le repertoire documents.
  static const _mbtilesDir = 'mbtiles';

  /// SUFFIXE DU FICHIER EN COURS DE DESCENTE.
  ///
  /// IL NE FINIT PAS PAR `.mbtiles`, ET C EST LA GARDE ENTIERE. `hasMbtiles`
  /// interroge le nom definitif et [listDownloaded] filtre sur `.mbtiles` : une
  /// descente en cours ou abandonnee est donc INVISIBLE pour la carte, qui repasse
  /// proprement en ligne au lieu d ouvrir une base SQLite tronquee.
  static const suffixePartiel = '.partiel';

  /// Nombre d octets entre deux notifications de progression.
  ///
  /// Rendre la main a chaque morceau HTTP (quelques kilooctets) ferait des
  /// dizaines de milliers d appels sur 260 Mo — un ecran ne se redessine pas 30 000
  /// fois. Un demi-megaoctet donne ~520 points sur un sentier complet, soit une
  /// barre fluide pour un cout nul.
  static const int pasDeProgression = 512 * 1024;

  /// Retourne le repertoire de stockage des MBTiles.
  /// Cree le dossier s'il n'existe pas.
  Future<Directory> _getMbtilesDirectory() async {
    final documentsDir = await _dossierDocuments();
    final mbtilesDir = Directory('${documentsDir.path}/$_mbtilesDir');
    if (!await mbtilesDir.exists()) {
      await mbtilesDir.create(recursive: true);
    }
    return mbtilesDir;
  }

  /// Retourne le chemin local du fichier .mbtiles pour un sentier.
  Future<String> getMbtilesPath(String trailId) async {
    final dir = await _getMbtilesDirectory();
    return '${dir.path}/$trailId.mbtiles';
  }

  /// Chemin du fichier EN COURS de descente pour un sentier.
  Future<String> cheminPartiel(String trailId) async =>
      '${await getMbtilesPath(trailId)}$suffixePartiel';

  /// OCTETS DEJA DESCENDUS ET REPRENABLES pour [trailId]. Zero si rien.
  ///
  /// Sert a l ecran autant qu a la reprise : « 180 Mo sur 260 deja la » est une
  /// information que le randonneur doit avoir AVANT de decider de reprendre sur son
  /// partage de connexion.
  Future<int> octetsDejaDescendus(String trailId) async {
    final partiel = File(await cheminPartiel(trailId));
    if (!await partiel.exists()) return 0;
    return partiel.length();
  }

  /// DESCEND LA CARTE HORS LIGNE DE [trailId], EN FLUX, AVEC REPRISE ET
  /// VERIFICATION.
  ///
  /// [octetsAttendus] et [empreinteAttendue] viennent de la liste distante
  /// (`TrailManifestEntry.tilesSize` / `tilesHash`) et ne sont PAS facultatifs —
  /// meme raison que `empreinteAttendue` dans `SourceFichierEntier` depuis la tache
  /// 607 : un controle a fermeture par defaut, parce qu une carte fausse ne se
  /// decouvre qu au pire moment.
  ///
  /// L ORDRE DES OPERATIONS EST LA GARANTIE, ET IL SE LIT DANS LE CODE :
  ///
  ///  1. ce qui est deja la est MESURE (`.partiel`), jamais suppose ;
  ///  2. le reste est demande en `Range` et ECRIT AU FUR ET A MESURE — rien ne
  ///     transite par la memoire au-dela d un morceau HTTP ;
  ///  3. la LONGUEUR est verifiee, puis l EMPREINTE, sur le fichier ferme ;
  ///  4. et SEULEMENT ALORS le fichier prend son nom definitif.
  ///
  /// Un arret a n importe quelle etape laisse donc, au pire, un `.partiel` que la
  /// carte ignore. Le nom `{trailId}.mbtiles` ne designe jamais qu une carte
  /// complete et verifiee.
  ///
  /// CE QUE CETTE METHODE NE DECIDE PAS. Elle ne regarde ni le niveau de
  /// telechargement, ni le droit de realiser, ni le type de reseau : c est le
  /// travail de [DescenteDesCartes] (`descente_des_cartes.dart`), seul appelant de
  /// cette methode en production. Un transport qui decide des droits est un
  /// transport qu on ne peut plus tester, et deux endroits qui decident du meme
  /// droit finissent par ne plus etre d accord.
  /// CETTE METHODE NE LEVE JAMAIS (tache 640, bug 9). Elle rend toujours un
  /// [ResultatDeCarte] : une carte posee, ou un [EchecDeCarte] NOMME.
  ///
  /// Le filet ci-dessous est le DERNIER, pas le premier : chaque maillon du
  /// transport classe deja sa propre panne. Il est la pour ce qu on n a pas
  /// prevu — un canal de plateforme qui disparait, un support retire en cours de
  /// route — parce qu une exception qui sort d ici sort dans un futur que
  /// personne n attend, et devient un plantage au lieu d un message.
  Future<ResultatDeCarte> descendre({
    required String trailId,
    required String url,
    required int octetsAttendus,
    required String empreinteAttendue,
    void Function(ProgressionDeCarte)? progression,
    AnnulationDeDescente? annulation,
  }) async {
    try {
      return await _descendre(
        trailId: trailId,
        url: url,
        octetsAttendus: octetsAttendus,
        empreinteAttendue: empreinteAttendue,
        progression: progression,
        annulation: annulation,
      );
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context:
            'MBTilesManager.descendre($trailId) — panne imprevue du '
            'transport des tuiles',
      );
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: 0,
        octetsTransferes: 0,
        octetsReprisDuDisque: 0,
        echec: EchecDeCarte.stockageIndisponible,
      );
    }
  }

  Future<ResultatDeCarte> _descendre({
    required String trailId,
    required String url,
    required int octetsAttendus,
    required String empreinteAttendue,
    void Function(ProgressionDeCarte)? progression,
    AnnulationDeDescente? annulation,
  }) async {
    // OU ECRIRE EST LA PREMIERE QUESTION, ET ELLE PEUT ECHOUER (tache 640).
    // `path_provider` passe par un canal de plateforme : il repond par une
    // exception quand la vue native n est plus la, et la creation du dossier
    // echoue sur un support plein ou en lecture seule. Aucune connexion n est
    // encore ouverte — c est donc un refus a cout nul, jamais un plantage.
    final String cheminFinal;
    try {
      cheminFinal = await getMbtilesPath(trailId);
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context:
            'MBTilesManager.descendre($trailId) — le telephone ne rend pas '
            'son espace de stockage',
      );
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: 0,
        octetsTransferes: 0,
        octetsReprisDuDisque: 0,
        echec: EchecDeCarte.stockageIndisponible,
      );
    }
    final partiel = File('$cheminFinal$suffixePartiel');

    var deja = await _tailleSure(partiel);

    // UN PARTIEL PLUS GROS QUE LE FICHIER ANNONCE NE PEUT PAS ETRE LE BON. C est
    // le cas d une carte REPUBLIEE pendant qu une descente dormait : reprendre
    // dessus produirait un fichier de la bonne taille au contenu melange, dont
    // seule l empreinte dirait le mal — apres 260 Mo de transport. On repart.
    if (deja > octetsAttendus) {
      _log.w(
        '[MBTilesManager] $trailId : le fichier en cours ($deja octets) depasse '
        'la taille annoncee ($octetsAttendus) — la carte a ete republiee depuis. '
        'Descente reprise depuis zero.',
      );
      // LA SUPPRESSION EST TENTEE, PAS EXIGEE (tache 640). Si elle echoue, on ne
      // plante pas pour autant : l ouverture en mode ecriture (et non en ajout,
      // puisque `deja` retombe a zero) tronque le fichier de toute facon.
      await _supprimerSiPresent(partiel);
      deja = 0;
    }

    // DEJA COMPLET : ON NE RETELECHARGE RIEN, ON VERIFIE ET ON POSE. Le cas arrive
    // apres une coupure survenue entre le dernier octet et le renommage.
    if (deja == octetsAttendus && octetsAttendus > 0) {
      _log.d(
        '[MBTilesManager] $trailId : les $octetsAttendus octets sont deja la — '
        'verification et pose, aucun transport.',
      );
      progression?.call(
        ProgressionDeCarte(
          trailId: trailId,
          octetsRecus: deja,
          octetsTotal: octetsAttendus,
        ),
      );
      return _verifierEtPoser(
        trailId: trailId,
        partiel: partiel,
        cheminFinal: cheminFinal,
        octetsAttendus: octetsAttendus,
        empreinteAttendue: empreinteAttendue,
        octetsTransferes: 0,
        octetsReprisDuDisque: deja,
      );
    }

    if (annulation?.demandee ?? false) {
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: deja,
        octetsTransferes: 0,
        octetsReprisDuDisque: deja,
        echec: EchecDeCarte.annulee,
      );
    }

    final requete = http.Request('GET', Uri.parse(url));
    if (deja > 0) {
      // LA REPRISE EST UNE DEMANDE, PAS UNE ESPERANCE : on demande la suite, et on
      // VERIFIE que le serveur l a comprise (206). Un serveur qui ignore l en-tete
      // rend 200 et tout le fichier — on recommence alors depuis zero, ce qui est
      // correct, mais on le DIT : c est la difference entre une reprise qui marche
      // et une reprise qu on croit avoir.
      requete.headers['Range'] = 'bytes=$deja-';
    }

    http.StreamedResponse reponse;
    try {
      reponse = await _httpClient.send(requete);
    } on Object catch (e) {
      _log.w('[MBTilesManager] $trailId : transport injoignable — $e');
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: deja,
        octetsTransferes: 0,
        octetsReprisDuDisque: deja,
        echec: EchecDeCarte.reseau,
      );
    }

    var enAjout = deja > 0;
    if (deja > 0 && reponse.statusCode == HttpStatus.ok) {
      _log.w(
        '[MBTilesManager] $trailId : le serveur a ignore la reprise (HTTP 200 sur '
        'une demande Range) — les $deja octets deja la sont reecrits depuis zero.',
      );
      enAjout = false;
      deja = 0;
    } else if (deja > 0 && reponse.statusCode != HttpStatus.partialContent) {
      _log.w(
        '[MBTilesManager] $trailId : HTTP ${reponse.statusCode} sur la reprise.',
      );
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: deja,
        octetsTransferes: 0,
        octetsReprisDuDisque: deja,
        echec: EchecDeCarte.reseau,
      );
    } else if (deja == 0 && reponse.statusCode != HttpStatus.ok) {
      _log.w('[MBTilesManager] $trailId : HTTP ${reponse.statusCode}.');
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: 0,
        octetsTransferes: 0,
        octetsReprisDuDisque: 0,
        echec: EchecDeCarte.reseau,
      );
    }

    final reprisDuDisque = deja;
    var surLeTelephone = deja;
    var transferes = 0;
    var dernierPointAnnonce = deja;

    final puits = _ouvrirEnEcriture(partiel, enAjout: enAjout);
    EchecDeCarte? echec;

    try {
      await for (final morceau in reponse.stream) {
        if (annulation?.demandee ?? false) {
          echec = EchecDeCarte.annulee;
          break;
        }
        puits.add(morceau);
        // `IOSink.add` est asynchrone par nature : sans ce point de synchronisation
        // sur un flux plus rapide que le disque, les morceaux s empilent en memoire
        // — on retomberait dans le defaut que ce lot corrige, par une autre porte.
        await puits.flush();
        surLeTelephone += morceau.length;
        transferes += morceau.length;
        if (surLeTelephone - dernierPointAnnonce >= pasDeProgression) {
          dernierPointAnnonce = surLeTelephone;
          progression?.call(
            ProgressionDeCarte(
              trailId: trailId,
              octetsRecus: surLeTelephone,
              octetsTotal: octetsAttendus,
            ),
          );
        }
      }
    } on FileSystemException catch (e) {
      echec = _classerEchecDEcriture(e);
      _log.e(
        '[MBTilesManager] $trailId : ecriture interrompue apres $surLeTelephone '
        'octets (${echec.name}) — $e',
      );
    } on Object catch (e) {
      echec = EchecDeCarte.reseau;
      _log.w(
        '[MBTilesManager] $trailId : transport interrompu apres $surLeTelephone '
        'octets — $e',
      );
    } finally {
      // LE PUITS SE FERME DANS TOUS LES CAS, ET SON ECHEC NE DOIT PAS MASQUER LA
      // CAUSE PREMIERE. Un disque plein leve souvent DEUX fois : a l ecriture, puis
      // a la fermeture. C est la premiere qui explique.
      try {
        await puits.close();
      } on Object catch (e) {
        _log.w(
          '[MBTilesManager] $trailId : fermeture du fichier en echec — $e',
        );
      }
    }

    if (echec != null) {
      // LE PARTIEL RESTE — c est ce qui rend la reprise possible. Le fichier
      // definitif, lui, n a jamais existe : la carte continue de repondre
      // « pas de carte » et repasse en ligne, au lieu d ouvrir une base tronquee.
      final taille = await _tailleSure(partiel);
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: taille,
        octetsTransferes: transferes,
        octetsReprisDuDisque: reprisDuDisque,
        echec: echec,
      );
    }

    progression?.call(
      ProgressionDeCarte(
        trailId: trailId,
        octetsRecus: surLeTelephone,
        octetsTotal: octetsAttendus,
      ),
    );

    return _verifierEtPoser(
      trailId: trailId,
      partiel: partiel,
      cheminFinal: cheminFinal,
      octetsAttendus: octetsAttendus,
      empreinteAttendue: empreinteAttendue,
      octetsTransferes: transferes,
      octetsReprisDuDisque: reprisDuDisque,
    );
  }

  /// VERIFIE LA LONGUEUR PUIS L EMPREINTE, ET NE RENOMME QU APRES.
  ///
  /// L ordre compte : comparer deux entiers coute un appel systeme, relire 260 Mo
  /// pour les hacher coute des secondes. Un fichier de la mauvaise taille est
  /// forcement faux — inutile de le hacher pour l apprendre.
  Future<ResultatDeCarte> _verifierEtPoser({
    required String trailId,
    required File partiel,
    required String cheminFinal,
    required int octetsAttendus,
    required String empreinteAttendue,
    required int octetsTransferes,
    required int octetsReprisDuDisque,
  }) async {
    final taille = await _tailleSure(partiel);

    if (taille != octetsAttendus) {
      _log.e(
        '[MBTilesManager] $trailId : $taille octets recus pour $octetsAttendus '
        'annonces par la liste distante. La carte n est PAS posee, et le fichier '
        'en cours est detruit : sa longueur ne deviendra jamais la bonne.',
      );
      await _supprimerSiPresent(partiel);
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: 0,
        octetsTransferes: octetsTransferes,
        octetsReprisDuDisque: octetsReprisDuDisque,
        echec: EchecDeCarte.tailleInattendue,
      );
    }

    // LA REGLE DE COMPARAISON N EST PAS REECRITE ICI. `EmpreinteDePublication`
    // porte deja la seule definition du depot — prefixes toleres, casse, longueur —
    // et son refus est le bon : une empreinte annoncee ILLISIBLE ne correspond
    // JAMAIS, elle ne vaut pas « pas de verification ». Une seconde regle de
    // comparaison, c est la porte par laquelle un descripteur fantaisiste
    // desactiverait le controle sans que personne s en apercoive.
    // LIRE 260 Mo PEUT ECHOUER, ET CE N EST PAS UNE RAISON DE PLANTER (tache
    // 640). Un support retire, un fichier verrouille par le systeme : on ne sait
    // alors PAS si la carte est bonne, et une carte dont on ne sait rien ne se
    // pose pas. Le partiel est garde : la lecture pourra reussir plus tard.
    final String empreinte;
    try {
      empreinte = await _empreinteDuFichier(partiel);
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'MBTilesManager.verifier($trailId) — empreinte illisible',
      );
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: taille,
        octetsTransferes: octetsTransferes,
        octetsReprisDuDisque: octetsReprisDuDisque,
        echec: EchecDeCarte.ecritureImpossible,
      );
    }
    if (EmpreinteDePublication.normaliser(empreinteAttendue) != empreinte) {
      _log.e(
        '[MBTilesManager] $trailId : empreinte $empreinte, attendue '
        '$empreinteAttendue. La carte n est PAS posee et le fichier en cours est '
        'DETRUIT — reprendre dessus ne pourrait jamais produire la bonne '
        'empreinte. Un .mbtiles faux est une base SQLite qui s ouvre et qui '
        'echoue au premier carreau manquant, en montagne.',
      );
      await _supprimerSiPresent(partiel);
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: 0,
        octetsTransferes: octetsTransferes,
        octetsReprisDuDisque: octetsReprisDuDisque,
        echec: EchecDeCarte.empreinteInvalide,
      );
    }

    // LE RENOMMAGE EST LE DERNIER GESTE, ET IL EST ATOMIQUE sur un meme systeme de
    // fichiers. C est lui qui fait passer la carte de « invisible » a « utilisable
    // » sans etat intermediaire. L ancienne carte est retiree juste avant, parce
    // que `rename` sur une cible existante echoue sur certaines plateformes ; si le
    // renommage echouait la, le fichier verifie serait toujours la, sous son nom
    // partiel, et la descente suivante le poserait sans retransporter un octet.
    final definitif = File(cheminFinal);
    await _supprimerSiPresent(definitif);
    try {
      await partiel.rename(cheminFinal);
    } on Object catch (e) {
      final echec = e is FileSystemException
          ? _classerEchecDEcriture(e)
          : EchecDeCarte.ecritureImpossible;
      _log.e('[MBTilesManager] $trailId : pose de la carte impossible — $e');
      return ResultatDeCarte(
        trailId: trailId,
        octetsSurLeTelephone: taille,
        octetsTransferes: octetsTransferes,
        octetsReprisDuDisque: octetsReprisDuDisque,
        echec: echec,
      );
    }

    _log.d(
      '[MBTilesManager] $trailId : carte posee, '
      '${ProgressionDeCarte.enMegaoctets(taille).toStringAsFixed(1)} Mo '
      '(${ProgressionDeCarte.enMegaoctets(octetsTransferes).toStringAsFixed(1)} Mo '
      'transferes, '
      '${ProgressionDeCarte.enMegaoctets(octetsReprisDuDisque).toStringAsFixed(1)} '
      'Mo repris du disque).',
    );

    return ResultatDeCarte(
      trailId: trailId,
      octetsSurLeTelephone: taille,
      octetsTransferes: octetsTransferes,
      octetsReprisDuDisque: octetsReprisDuDisque,
    );
  }

  /// EMPREINTE SHA-256 DU FICHIER, LU EN FLUX.
  ///
  /// `readAsBytes` puis `sha256.convert` serait une ligne de moins et ramenerait le
  /// defaut que ce lot corrige : 260 Mo en memoire pour verifier 260 Mo sur disque.
  Future<String> _empreinteDuFichier(File fichier) async {
    final collecteur = _CollecteurDEmpreinte();
    final conversion = sha256.startChunkedConversion(collecteur);
    await for (final morceau in fichier.openRead()) {
      conversion.add(morceau);
    }
    conversion.close();
    return collecteur.valeur.toString();
  }

  /// DISQUE PLEIN OU AUTRE CHOSE ? La distinction commande ce qu on dit au
  /// randonneur : « libere de la place » n a de sens que si c est vrai.
  ///
  /// Le code d erreur est celui du systeme : 28 (`ENOSPC`) sur Android, iOS et
  /// Linux, 112 (`ERROR_DISK_FULL`) sur Windows. Le message est examine en dernier
  /// recours, parce que certains supports remontent 0 sans code utile.
  static EchecDeCarte _classerEchecDEcriture(FileSystemException e) {
    final code = e.osError?.errorCode;
    if (code == 28 || code == 112) return EchecDeCarte.plusDePlace;
    final message = (e.osError?.message ?? e.message).toLowerCase();
    if (message.contains('no space') ||
        message.contains('disk full') ||
        message.contains('espace')) {
      return EchecDeCarte.plusDePlace;
    }
    return EchecDeCarte.ecritureImpossible;
  }

  /// TAILLE D UN FICHIER, SANS JAMAIS LEVER (tache 640). Zero si absent OU
  /// illisible.
  ///
  /// « Illisible » est traite comme « absent » a dessein : la seule decision que
  /// cette valeur commande est « peut-on reprendre ? », et on ne reprend pas sur
  /// un fichier qu on ne sait pas mesurer. Le pire cas est donc un transport
  /// complet au lieu d une reprise — jamais une carte fausse, jamais un plantage.
  Future<int> _tailleSure(File fichier) async {
    try {
      return await fichier.exists() ? await fichier.length() : 0;
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'MBTilesManager — taille illisible pour ${fichier.path}',
      );
      return 0;
    }
  }

  /// SUPPRESSION TENTEE, JAMAIS EXIGEE (tache 640).
  ///
  /// Les trois appelants de cette methode l utilisent pour FAIRE DE LA PLACE ou
  /// pour retirer un fichier dont on vient d etablir qu il est faux. Aucun n a
  /// besoin d une garantie : si la suppression echoue, l ecriture suivante
  /// tronque, et une verification suivante refusera de nouveau la carte fausse.
  /// Une exception ici, en revanche, sortait de tout le chemin et plantait.
  Future<void> _supprimerSiPresent(File fichier) async {
    try {
      if (await fichier.exists()) {
        await fichier.delete();
      }
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'MBTilesManager — suppression impossible de ${fichier.path}',
      );
    }
  }

  /// Supprime le fichier .mbtiles local pour le sentier [trailId].
  ///
  /// Ne fait rien si le fichier n'existe pas. LE FICHIER EN COURS DE DESCENTE PART
  /// AVEC LUI : garder un partiel apres une suppression volontaire ferait
  /// reapparaitre la carte a la reprise suivante, sans que personne l ait demandee.
  ///
  /// AUCUN CODE DE PRODUCTION N APPELLE ENCORE CETTE METHODE, et c est un manque
  /// MESURE, pas un oubli de ce lot : le §6 du modele economique prevoit qu un
  /// sentier REALISE libere ses grosses tuiles (trace et carnet gardes a vie). Ce
  /// menage n existe nulle part — il est signale dans le bilan de la tache 622, pas
  /// improvise ici.
  Future<void> deleteMbtiles(String trailId) async {
    final path = await getMbtilesPath(trailId);
    await _supprimerSiPresent(File(path));
    await _supprimerSiPresent(File('$path$suffixePartiel'));
    _log.d('[MBTilesManager] MBTiles supprime: $path');
  }

  /// Verifie si un fichier .mbtiles COMPLET existe localement pour le sentier.
  ///
  /// Un fichier en cours de descente repond NON : il porte le suffixe
  /// [suffixePartiel] et n existe pas sous ce nom. C est ce qui empeche la carte
  /// d ouvrir une base SQLite tronquee.
  Future<bool> hasMbtiles(String trailId) async {
    final path = await getMbtilesPath(trailId);
    return File(path).exists();
  }

  /// Liste les identifiants de sentiers ayant un fichier .mbtiles local.
  ///
  /// Parcourt le dossier mbtiles et extrait les trailIds
  /// depuis les noms de fichier ({trailId}.mbtiles). Les descentes en cours
  /// (`.mbtiles.partiel`) n y figurent pas : elles ne sont pas des cartes.
  Future<List<String>> listDownloaded() async {
    final dir = await _getMbtilesDirectory();
    if (!await dir.exists()) return [];

    final entities = await dir.list().toList();
    final trailIds = <String>[];

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.mbtiles')) {
        // Extraire le trailId du nom de fichier
        final fileName = entity.uri.pathSegments.last;
        final trailId = fileName.replaceAll('.mbtiles', '');
        trailIds.add(trailId);
      }
    }

    return trailIds;
  }
}

/// Recueille l empreinte rendue par la conversion par morceaux.
///
/// `AccumulatorSink` de `package:convert` ferait la meme chose, mais `convert`
/// n est pas une dependance DECLAREE de ce projet : l importer directement serait
/// une dependance implicite, que l analyse signale a juste titre.
class _CollecteurDEmpreinte implements Sink<Digest> {
  Digest? valeur;

  @override
  void add(Digest data) => valeur = data;

  @override
  void close() {}
}

/// Provider singleton du gestionnaire MBTiles.
final mbtilesManagerProvider = Provider<MBTilesManager>((ref) {
  return MBTilesManager();
});
