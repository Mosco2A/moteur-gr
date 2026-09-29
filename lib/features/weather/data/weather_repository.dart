import 'dart:convert';

import 'package:logger/logger.dart';

import '../../../core/data/daos/trail_meteo_dao.dart';
import '../models/weather_forecast.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// CE QUE LE GESTE « ACTUALISER » A REELLEMENT PRODUIT.
///
/// Quatre issues, et elles sont DISTINCTES A L ECRAN. C est la lecon de la tache
/// 572 (« la mise a jour ne produit rien », verbatim de Christophe) poussee un cran
/// plus loin : il ne suffit plus de distinguer reussi d echoue, parce que le cas le
/// plus frequent n est ni l un ni l autre — c est « le serveur n a rien fabrique de
/// plus recent », et c est une BONNE nouvelle qu un message d echec ferait passer
/// pour une panne.
enum IssueMiseAJourMeteo {
  /// Un bulletin plus recent est arrive et est pose en base.
  recue,

  /// La passe a abouti, le serveur n a rien de plus recent. Rien a faire.
  rienDePlusRecent,

  /// Hors ligne : aucune passe n a pu partir. Ce qui est affiche reste affiche,
  /// avec son age.
  horsLigne,

  /// La passe a echoue (transport, empreinte, donnee refusee).
  echec,
}

/// Resultat NOMME d une demande de mise a jour de la meteo.
class MiseAJourMeteo {
  const MiseAJourMeteo({
    required this.issue,
    this.bulletin,
    this.cause,
  });

  final IssueMiseAJourMeteo issue;

  /// Le bulletin a afficher APRES l operation : le neuf s il est arrive, le dernier
  /// connu sinon. Jamais un ecran vide quand le telephone a quelque chose.
  final WeatherForecast? bulletin;

  /// Cause technique (journal / diagnostic). Jamais affichee brute : l ecran en
  /// tire un message i18n.
  final String? cause;

  /// Vrai si l operation n a pas abouti — l ecran doit le DIRE.
  bool get echoue =>
      issue == IssueMiseAJourMeteo.echec ||
      issue == IssueMiseAJourMeteo.horsLigne;
}

/// LA METEO SE LIT EN BASE. IL N Y A PLUS RIEN A DEMANDER A PERSONNE.
///
/// DECISION DE CHRISTOPHE DU 28/09, verbatim : « Ce n est pas l appli qui demande la
/// meteo mais notre serveur, les infos meteo sont mises sur firebase et quand l appli
/// voit qu il y a des donnees a jour elle les met a jour, comme pour le reste. »
///
/// CE QUE CETTE CLASSE FAISAIT ET NE FAIT PLUS. Elle orchestrait trois choses : un
/// cache avec sa duree de vie, un appel a Open-Meteo, et un repli sur le dernier
/// bulletin connu. Les deux premieres ont disparu — il n y a plus de fournisseur a
/// appeler, donc plus de duree de vie a faire expirer pour decider de le rappeler.
/// La troisieme est devenue la seule et unique lecture : **le dernier bulletin
/// connu EST le bulletin**, et son age est affiche.
///
/// ELLE N A PLUS BESOIN DES COORDONNEES DES ETAPES, ET C EST UN GAIN REEL. L ancienne
/// version lisait `endLat`/`endLng` dans la table `stages` pour construire son appel.
/// Consequence mesuree : un sentier venu du SEUL distant, dont les etapes vivent dans
/// `trail_stages` et pas dans `stages`, n avait aucune meteo et rien ne le disait. Le
/// serveur fabriquant la meteo PAR ETAPE, l application n a plus qu a la lire par
/// (sentier, numero d etape) — ce chemin d echec n existe plus.
class WeatherRepository {
  WeatherRepository({
    required TrailMeteoDao dao,
    required Future<bool> Function() demanderUnePasse,
  })  : _dao = dao,
        _demanderUnePasse = demanderUnePasse;

  final TrailMeteoDao _dao;

  /// DEMANDE UNE PASSE A L ORDONNANCEUR QUI EXISTE DEJA, ET N EN ECRIT PAS UN
  /// SECOND.
  ///
  /// `OrdonnanceurDeSynchronisation.passer` est la methode que le lot 616 a rendue
  /// publique exactement pour cela — son commentaire l annonce : « parce qu un geste
  /// "verifier maintenant" dans l interface s y branchera sans ajouter de chemin ».
  ///
  /// IL REND « LA PASSE A-T-ELLE REELLEMENT TOURNE », ET C EST CE QUI REMPLACE UNE
  /// SECONDE AUTORITE SUR LA CONNECTIVITE. Une premiere version interrogeait le
  /// moniteur de reseau ICI, en plus de l ordonnanceur qui l interroge deja avant
  /// chaque passe : deux sources pour un meme fait, dont la plus silencieuse
  /// gagne — exactement le piege #M7 de la spec 605. L ordonnanceur sait, lui, s il
  /// a tourne (`passesExecutees` ne monte que sur une passe REELLEMENT executee),
  /// et c est la seule chose que le repository ait besoin de savoir.
  ///
  /// CONSEQUENCE VISIBLE, ET ELLE EST VOULUE : le bouton « Actualiser » de l ecran
  /// meteo synchronise TOUT ce qui est telecharge, pas seulement la meteo. Il n y a
  /// plus de mise a jour « de la meteo » : il y a une mise a jour des donnees, dont
  /// la meteo est une famille. C est la phrase de Christophe — « comme pour le
  /// reste » — appliquee jusqu au bouton.
  final Future<bool> Function() _demanderUnePasse;

  /// LE BULLETIN D UNE ETAPE, TEL QUE LE SERVEUR L A FABRIQUE.
  ///
  /// Rend `null` quand le serveur n a encore rien depose pour cette etape sur ce
  /// telephone. **CE `null` EST UNE REPONSE, PAS UNE PANNE**, et l ecran doit le
  /// dire ainsi : « pas encore de bulletin ». Il ne doit surtout pas le combler.
  Future<WeatherForecast?> bulletinDeLEtape({
    required String trailId,
    required int stageNumber,
  }) async {
    try {
      final ligne = await _dao.pourEtape(trailId, stageNumber);
      if (ligne == null) return null;
      return WeatherForecast.depuisLePublie(
        jours: jsonDecode(ligne.joursJson) as List<dynamic>,
        latitude: ligne.latitude,
        longitude: ligne.longitude,
        produiteLe: ligne.produiteLe,
        collecteeLe: ligne.collecteeLe,
        source: ligne.source,
      );
    } catch (e) {
      // UNE LIGNE ILLISIBLE VAUT « PAS DE BULLETIN », JAMAIS UN ECRAN CASSE. Elle
      // est journalisee, et la prochaine passe la remplacera : l ecriture est
      // idempotente, donc le serveur reposera le meme enregistrement des que sa
      // borne repassera devant le repere.
      _log.w('[Meteo] Bulletin illisible pour $trailId/$stageNumber : $e');
      return null;
    }
  }

  /// Tous les bulletins d un sentier, par numero d etape.
  Future<List<WeatherForecast>> bulletinsDuSentier(String trailId) async {
    final lignes = await _dao.pourSentier(trailId);
    final bulletins = <WeatherForecast>[];
    for (final ligne in lignes) {
      final b = await bulletinDeLEtape(
        trailId: ligne.trailId,
        stageNumber: ligne.stageNumber,
      );
      if (b != null) bulletins.add(b);
    }
    return bulletins;
  }

  /// DEMANDE AU SERVEUR CE QU IL A DE PLUS RECENT, PAR L ORDONNANCEUR.
  ///
  /// C est le geste « Actualiser » et le tire-pour-rafraichir. La comparaison qui
  /// decide de l issue porte sur la DATE DE FABRICATION, avant et apres la passe :
  /// c est la seule mesure honnete de « quelque chose de plus recent est arrive ».
  /// Compter les enregistrements ecrits ne dirait rien — la borne du serveur fait
  /// volontairement relire des enregistrements deja connus (#K4).
  Future<MiseAJourMeteo> demanderLaMiseAJour({
    required String trailId,
    required int stageNumber,
  }) async {
    final avant = await bulletinDeLEtape(
      trailId: trailId,
      stageNumber: stageNumber,
    );

    final bool aTourne;
    try {
      aTourne = await _demanderUnePasse();
    } catch (e) {
      return MiseAJourMeteo(
        issue: IssueMiseAJourMeteo.echec,
        bulletin: avant,
        cause: 'passe de synchronisation en echec : $e',
      );
    }

    // LA PASSE N A PAS TOURNE = HORS LIGNE. L ordonnanceur ecarte lui-meme les
    // passes emises sans reseau (« une passe hors ligne ne produirait qu un echec
    // de transport et des journaux trompeurs »), et il ne compte que celles qui
    // ont REELLEMENT eu lieu. On lit donc son verdict au lieu d en rendre un
    // second.
    if (!aTourne) {
      return MiseAJourMeteo(
        issue: IssueMiseAJourMeteo.horsLigne,
        bulletin: avant,
        cause: 'aucune passe de synchronisation n a pu tourner (hors ligne)',
      );
    }

    final apres = await bulletinDeLEtape(
      trailId: trailId,
      stageNumber: stageNumber,
    );

    final aAvance = apres != null &&
        (avant?.produiteLe == null ||
            (apres.produiteLe != null &&
                apres.produiteLe! > avant!.produiteLe!));

    return MiseAJourMeteo(
      issue: aAvance
          ? IssueMiseAJourMeteo.recue
          : IssueMiseAJourMeteo.rienDePlusRecent,
      bulletin: apres ?? avant,
    );
  }
}
