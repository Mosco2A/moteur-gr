/// La forme exacte du fichier de sentier, reduite aux enregistrements plus
/// recents que le repere du telephone : la pose n'a pas a changer.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../data/empreinte_de_publication.dart';
import '../data/revision_de_donnee.dart';
import '../models/trail_manifest.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// CE QU IL Y A A PRENDRE, ET CE QUE CELA A COUTE.
///
/// [parFamille] a EXACTEMENT la forme du fichier de donnees d un sentier (sept
/// familles, cf. [MorceauxDeSentier]) : ce n est pas un nouveau format, c est le
/// meme, reduit aux enregistrements plus recents que la revision du telephone.
/// C est ce qui permet a la POSE de rester le code de la tache 605 sans y
/// toucher.
///
/// LES TROIS COMPTEURS SONT LA POUR QU ON PUISSE MESURER L ARBITRAGE, PAS POUR
/// DECORER UN JOURNAL. La decision « Firestore pour les donnees structurees,
/// Storage pour les fichiers lourds » repose sur un fait que le lot 605 a mesure :
/// le modele de revision se comporte a l IDENTIQUE sur les deux, la difference
/// est en OCTETS. Ces compteurs sont precisement ces octets : avec un fichier
/// entier, [transferes] vaut le total publie et [retenus] la part utile ; avec une
/// source interrogeable, les deux sont egaux. Le comportement, lui, ne change pas.
class MorceauxAPrendre {
  const MorceauxAPrendre({
    required this.parFamille,
    required this.transferes,
    required this.retenus,
    this.octetsRecus = 0,
    this.ecartesHorsNiveau = 0,
  });

  /// Rien a prendre : le telephone est deja a jour, ou le niveau ne demande rien.
  const MorceauxAPrendre.rien()
    : parFamille = const {},
      transferes = 0,
      retenus = 0,
      octetsRecus = 0,
      ecartesHorsNiveau = 0;

  /// Les enregistrements a poser, par famille, dans la forme du fichier publie.
  final Map<String, dynamic> parFamille;

  /// Enregistrements qui ont REELLEMENT traverse le reseau.
  final int transferes;

  /// Enregistrements retenus, c est-a-dire plus recents que la revision locale.
  final int retenus;

  /// Octets recus, quand la source peut les compter (0 = inconnu).
  final int octetsRecus;

  /// ENREGISTREMENTS DESCENDUS PUIS ECARTES PARCE QU ILS SONT HORS NIVEAU.
  ///
  /// C EST LE CHIFFRE QUE CHRISTOPHE A DEMANDE (28/09 11:27), ET IL DOIT RESTER
  /// VISIBLE MEME QUAND IL EST GENANT. Sur [SourceFichierEntier] il est non nul
  /// des qu on prepare un sentier dont la trace est publiee : les octets sont
  /// descendus, on ne les ecrit pas, mais ils ont bien traverse le reseau. Le
  /// masquer donnerait l illusion que les niveaux economisent du transport sur ce
  /// transport-la, ce qui est faux. Sur [SourceInterrogeable] il vaut zero, parce
  /// que les familles hors niveau ne sont pas meme interrogees — et c est la la
  /// vraie economie.
  final int ecartesHorsNiveau;

  /// Part inutile du transfert : ce qui est descendu pour rien.
  ///
  /// Elle comprend [ecartesHorsNiveau] : un enregistrement hors niveau est un
  /// enregistrement descendu pour rien, au meme titre qu un enregistrement deja a
  /// jour.
  int get transferesEnTrop => transferes - retenus;
}

/// « DONNE-MOI TOUT CE QUI A UNE REVISION SUPERIEURE A LA MIENNE ».
///
/// C est LA question du modele de Christophe (27/09 20:43), et c est la SEULE que
/// l application pose. Cette interface existe parce que la question a deux
/// reponses possibles selon l endroit ou vivent les donnees, et UNE SEULE
/// consequence sur la suite du code : dans les deux cas la pose est celle de
/// `DeltaUpdateService.appliquerRevisions`, transactionnelle, enregistrement par
/// enregistrement.
///
///  * [SourceFichierEntier] — Firebase Storage, HTTP REST. Le fichier publie
///    descend en entier, le tri par revision se fait a l arrivee.
///  * [SourceInterrogeable] — Firestore. La question part au serveur
///    (`where('rev','>',R)`), et seuls les enregistrements concernes descendent.
///
/// L ARBITRAGE EST TRANCHE ET N EST PAS REOUVERT ICI : Firestore pour la liste et
/// les donnees structurees avec leurs revisions, Storage pour les fichiers lourds
/// (decision du 27/09 20:11). Aucun des deux n est provisionne — les deux
/// implementations sont donc eprouvees contre un DOUBLE, comme le lot 605.
abstract interface class TrailRecordSource {
  /// Les enregistrements de [trailId] dont la revision depasse [revisionLocale].
  ///
  /// [revisionCible] est la revision courante du sentier : elle sert de revision
  /// par defaut aux enregistrements qui n en declarent pas (#R6 de la spec).
  ///
  /// [adresse] localise les donnees. Une source de fichier y lit une URL ; une
  /// source interrogeable peut l ignorer.
  ///
  /// [empreinteAttendue] est l empreinte SHA-256 annoncee par la liste publiee
  /// (`TrailManifestEntry.hash`, #M3). ELLE N EST PAS FACULTATIVE POUR UNE SOURCE
  /// DE FICHIER : c est la seule chose qui distingue un fichier complet d un
  /// fichier tronque mais syntaxiquement valide. Une source interrogeable, qui ne
  /// recoit pas de fichier, ne peut rien en faire et le dit.
  ///
  /// [famillesDemandees] EST LE NIVEAU, TRADUIT EN FAMILLES (tache 616). Il borne
  /// ce que la source a le droit de rendre, et il n est PAS FACULTATIF : un
  /// argument qu on peut omettre pour tout obtenir est exactement la faute que la
  /// tache 607 a nommee a propos de l empreinte. Une liste VIDE signifie « rien » —
  /// c est [NiveauDeTelechargement.regarder] — et une source qui recoit une liste
  /// vide ne doit RIEN DEMANDER AU RESEAU : ni requete, ni telechargement de
  /// fichier. C est la reponse directe a Christophe (28/09 11:27) : celui qui
  /// regarde simplement si un sentier lui plait ne paie aucun transport.
  Future<MorceauxAPrendre> depuisLaRevision(
    String trailId, {
    required String adresse,
    required HorodatageServeur revisionLocale,
    required HorodatageServeur revisionCible,
    required List<String> famillesDemandees,
    String? empreinteAttendue,
  });
}

/// LE TRI PAR REVISION, APPLIQUE A UNE COLLECTION D ENREGISTREMENTS.
///
/// Un seul endroit decide ce qui est « a prendre », que la question ait ete posee
/// au serveur ou tranchee a l arrivee. Un marqueur de suppression est un
/// enregistrement comme un autre de ce point de vue : il porte sa revision, donc
/// il descend quand elle depasse celle du telephone.
class _Tri {
  static List<Map<String, dynamic>> retenus(
    Iterable<Map<String, dynamic>> enregistrements, {
    required HorodatageServeur revisionLocale,
    required HorodatageServeur revisionCible,
  }) {
    return enregistrements
        .where(
          (e) => RevisionDeDonnee.aPrendre(
            e,
            revisionLocale: revisionLocale,
            revisionDuSentier: revisionCible,
          ),
        )
        .toList();
  }

  /// Normalise une valeur brute de famille en liste d enregistrements.
  ///
  /// `trail_meta` est un objet unique, les six autres familles des listes. Une
  /// valeur d un autre type est ignoree — le serveur peut preparer des familles
  /// que cette version de l application ne connait pas (#S10).
  static List<Map<String, dynamic>> enregistrements(dynamic brut) => [
    if (brut is Map<String, dynamic>) brut,
    if (brut is List)
      ...brut.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
  ];
}

/// SOURCE « FICHIER ENTIER » — FIREBASE STORAGE, EN HTTP REST.
///
/// Le fichier de donnees du sentier descend d un bloc, et le tri par revision se
/// fait A L ARRIVEE. Ce n est pas le transfert unitaire idéal, et il ne faut pas
/// le presenter comme tel : ce que cette classe garantit, c est que la POSE est
/// unitaire (seuls les enregistrements plus recents sont ecrits) et que le cout du
/// transfert est MESURE au lieu d etre suppose ([MorceauxAPrendre.transferesEnTrop]).
///
/// LA REPRISE SUR ECHEC RESEAU VIT ICI, et elle vient d ailleurs : c etait la
/// seule chose que `TrailDownloadService` — le SECOND chemin de descente, supprime
/// par la tache 606 — apportait de plus. Trois tentatives avec attente croissante,
/// pour le premier telechargement comme pour une mise a jour, puisque c est
/// desormais le meme chemin. Ce que ce service faisait EN PLUS et qu on ne
/// reprend pas : son insertion famille par famille avec file de reprise, qui est
/// exactement le demi-sentier que la copie atomique interdit (#C1).
///
/// ET DEPUIS LA TACHE 607, C EST ICI QUE L INTEGRITE SE VERIFIE — AVANT LA POSE.
/// La specification annoncait depuis le lot 605 que `hash` garantit que le recu
/// est le publie (#M3, #C4) ; le lot 606 a mesure que PERSONNE ne le calculait ni
/// ne le comparait. Un fichier tronque a la moitie d une liste de points de trace
/// reste du JSON valide : il passait la copie, sa revision locale etait inscrite,
/// et le randonneur partait en montagne avec une trace coupee dont rien ne disait
/// qu elle l etait — et plus aucune raison de retelecharger.
///
/// LE CONTROLE EST A FERMETURE PAR DEFAUT, ET C EST DELIBERE. Pas d empreinte
/// annoncee, ou une empreinte illisible : la copie est REFUSEE, pas « acceptee
/// sans verification ». La raison est dans l histoire recente du depot : le lot
/// 606 a supprime un SECOND chemin de descente des donnees qui ignorait tout le
/// modele de revision, simplement parce qu il avait ete ajoute sans que rien ne
/// l oblige a le respecter. Une verification qu on peut omettre en ne passant pas
/// un argument serait la meme faute, au meme endroit.
class SourceFichierEntier implements TrailRecordSource {
  SourceFichierEntier({
    http.Client? httpClient,
    this.tentatives = 3,
    this.attenteEntreTentatives = const Duration(seconds: 2),
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// Nombre maximum de tentatives de telechargement.
  final int tentatives;

  /// Attente de base entre deux tentatives (multipliee par le rang).
  final Duration attenteEntreTentatives;

  @override
  Future<MorceauxAPrendre> depuisLaRevision(
    String trailId, {
    required String adresse,
    required HorodatageServeur revisionLocale,
    required HorodatageServeur revisionCible,
    required List<String> famillesDemandees,
    String? empreinteAttendue,
  }) async {
    // NIVEAU « REGARDER » : AUCUNE REQUETE RESEAU N EST EMISE (tache 616). C est
    // la reponse la plus directe a Christophe : la fiche du catalogue est deja
    // arrivee avec la liste distante, il n y a rien de plus a chercher pour
    // decider. Le retour a zero est rendu AVANT `_telecharger`, donc avant la
    // moindre connexion.
    if (famillesDemandees.isEmpty) {
      _log.d(
        '[Source fichier] $trailId : niveau « regarder » — aucun transport, '
        '0 enregistrement, 0 octet.',
      );
      return const MorceauxAPrendre.rien();
    }

    final (donnees, octets) = await _telecharger(
      adresse,
      trailId: trailId,
      empreinteAttendue: empreinteAttendue,
    );

    final parFamille = <String, dynamic>{};
    var transferes = 0;
    var retenus = 0;
    var ecartes = 0;

    for (final famille in donnees.keys) {
      final tous = _Tri.enregistrements(donnees[famille]);
      transferes += tous.length;

      // HORS NIVEAU : ECARTE A LA PORTE, PAS TRANSMIS A LA POSE. Sur ce transport
      // les octets sont deja descendus — le fichier est global, c est sa limite,
      // documentee plus haut — mais ils ne sont ni decodes plus loin, ni ecrits,
      // ni comptes comme retenus. Le gaspillage est MESURE
      // ([MorceauxAPrendre.transferesEnTrop]) au lieu d etre suppose, et il
      // disparaitra de lui-meme sur [SourceInterrogeable], qui ne les demande pas.
      if (!famillesDemandees.contains(famille) &&
          MorceauxDeSentier.estConnu(famille)) {
        ecartes += tous.length;
        continue;
      }

      if (!MorceauxDeSentier.estConnu(famille)) {
        // Famille inconnue : journalisee par la pose, pas fatale (#S10). On ne
        // la compte pas comme retenue, mais on la transmet telle quelle pour que
        // la pose la nomme a un seul endroit.
        parFamille[famille] = donnees[famille];
        continue;
      }

      final aPrendre = _Tri.retenus(
        tous,
        revisionLocale: revisionLocale,
        revisionCible: revisionCible,
      );
      if (aPrendre.isEmpty) continue;

      retenus += aPrendre.length;
      parFamille[famille] = famille == MorceauxDeSentier.fiche
          ? aPrendre.first
          : aPrendre;
    }

    _log.d(
      '[Source fichier] $trailId $revisionLocale -> $revisionCible : '
      '$octets octets, $transferes enregistrement(s) descendus, $retenus '
      'retenu(s) — ${transferes - retenus} transfere(s) pour rien, dont '
      '$ecartes hors du niveau demande '
      '(${famillesDemandees.join(", ")}).',
    );

    return MorceauxAPrendre(
      parFamille: parFamille,
      transferes: transferes,
      retenus: retenus,
      octetsRecus: octets,
      ecartesHorsNiveau: ecartes,
    );
  }

  Future<(Map<String, dynamic>, int)> _telecharger(
    String url, {
    required String trailId,
    required String? empreinteAttendue,
  }) async {
    Object? derniereCause;

    for (var tentative = 1; tentative <= tentatives; tentative++) {
      try {
        final reponse = await _httpClient.get(Uri.parse(url));
        if (reponse.statusCode == 200) {
          // L EMPREINTE SE VERIFIE SUR LES OCTETS, ET AVANT LE DECODAGE. Hacher
          // apres un aller-retour par `jsonDecode` verifierait notre propre
          // encodeur et laisserait passer exactement ce qu on veut attraper : un
          // fichier coupe qui se reparse. Et l echec est leve AVANT de rendre
          // quoi que ce soit, donc avant que la pose n ouvre sa transaction :
          // rien n est ecrit, la revision locale ne bouge pas (#C1).
          if (!EmpreinteDePublication.correspond(
            reponse.bodyBytes,
            empreinteAttendue,
          )) {
            throw EmpreinteInvalide(
              trailId: trailId,
              adresse: url,
              attendue: empreinteAttendue,
              obtenue:
                  EmpreinteDePublication.normaliser(empreinteAttendue) == null
                  ? null
                  : EmpreinteDePublication.de(reponse.bodyBytes),
              octets: reponse.bodyBytes.length,
            );
          }
          final corps = jsonDecode(reponse.body) as Map<String, dynamic>;
          return (corps, reponse.bodyBytes.length);
        }
        derniereCause = 'HTTP ${reponse.statusCode}';
      } on EmpreinteInvalide catch (e) {
        // UNE EMPREINTE NON CONFORME NE SE REESSAYE PAS. Ce n est pas un aléa de
        // reseau : le serveur a servi un fichier qui n est pas celui qu il
        // annonce. Trois tentatives donneraient trois fois le meme fichier et
        // masqueraient la cause derriere un message de reseau.
        _log.e('[Source fichier] $e');
        rethrow;
      } catch (e) {
        derniereCause = e;
      }

      if (tentative < tentatives) {
        _log.w(
          '[Source fichier] $url tentative $tentative/$tentatives echouee '
          '($derniereCause) — nouvelle tentative.',
        );
        await Future<void>.delayed(attenteEntreTentatives * tentative);
      }
    }

    // ECHEC FRANC. Rien n est pose, la revision locale n avance pas, le sentier
    // reste « a prendre » : c est la garantie #C1, et elle exige une exception —
    // rendre un lot vide se confondrait avec « deja a jour ».
    throw Exception(
      'Donnees du sentier injoignables apres $tentatives tentative(s) '
      '($url) : $derniereCause',
    );
  }
}

/// UNE REQUETE PAR REVISION, TELLE QUE LA POSERAIT FIRESTORE.
///
/// Rend les enregistrements de [famille] pour [trailId] dont `rev` depasse
/// [revisionMinimale]. C est litteralement
/// `collection('trails/$trailId/$famille').where('rev', '>', revisionMinimale)`,
/// ou `revisionMinimale` part en `Timestamp` : un horodatage se compare
/// NATIVEMENT cote serveur, ce qu un compteur entier ne savait faire qu au prix
/// d une coordination entre producteurs.
/// LE PERIMETRE EST LE SENTIER, ET IL EST DANS LA SIGNATURE : `trailId` est le
/// premier parametre, donc la question ne peut pas partir sur tout le catalogue.
/// Un randonneur qui possede un sentier ne telecharge pas les mises a jour des
/// quarante autres (precision de Christophe, 28/09).
/// Le moteur ne depend PAS de `cloud_firestore` pour cela : la dependance
/// s arrete a cette signature, ce qui permet de l eprouver contre un double
/// aujourd hui — aucun des deux services n est provisionne — et de la brancher le
/// jour ou la console existe, sans toucher a la logique.
typedef RequeteParRevision =
    Future<List<Map<String, dynamic>>> Function(
      String trailId,
      String famille,
      HorodatageServeur revisionMinimale,
    );

/// SOURCE INTERROGEABLE — FIRESTORE : LA QUESTION PART AU SERVEUR.
///
/// LE TRANSFERT DEVIENT UNITAIRE, et c est la seule difference avec
/// [SourceFichierEntier] : la question « qu est-ce qui depasse ma revision ? »
/// est posee au serveur famille par famille, donc SEULS les enregistrements
/// concernes traversent le reseau. Une altitude corrigee fait descendre UNE
/// etape, pas un fichier de sentier.
///
/// CE QUI NE CHANGE PAS — et c est ce que la mesure du lot 605 disait : la suite
/// du code. La pose reste `appliquerRevisions`, transactionnelle, enregistrement
/// par enregistrement, marqueurs de suppression compris. Premiere copie et mise a
/// jour restent LE MEME chemin : a la revision zero, `rev > 0` selectionne tout.
class SourceInterrogeable implements TrailRecordSource {
  const SourceInterrogeable(
    this.interroger, {
    this.familles = MorceauxDeSentier.tous,
  });

  /// La requete par revision, une par famille.
  final RequeteParRevision interroger;

  /// Les familles a interroger, dans l ordre des cles etrangeres.
  final List<String> familles;

  /// L EMPREINTE DE FICHIER N A PAS DE SENS ICI, ET LE DIRE VAUT MIEUX QUE DE
  /// L IGNORER EN SILENCE. Cette source ne recoit pas de fichier : elle recoit des
  /// enregistrements, un par un. Il n y a donc rien dont l empreinte du fichier
  /// publie (#M3) pourrait certifier l integrite. Le controle equivalent sur une
  /// base interrogeable serait d une autre nature — une empreinte par
  /// enregistrement, ou la garantie de transport du service — et il reste a
  /// trancher le jour ou la console existe. `empreinteAttendue` est accepte pour
  /// que les deux sources restent interchangeables, et delibere ment non utilise.
  @override
  Future<MorceauxAPrendre> depuisLaRevision(
    String trailId, {
    required String adresse,
    required HorodatageServeur revisionLocale,
    required HorodatageServeur revisionCible,
    required List<String> famillesDemandees,
    String? empreinteAttendue,
  }) async {
    // LE NIVEAU BORNE LES REQUETES, ET C EST ICI QUE L ECONOMIE EST REELLE (tache
    // 616). Les familles hors niveau ne sont pas filtrees a l arrivee : elles ne
    // sont PAS INTERROGEES. Preparer un sentier ne fait donc descendre aucun point
    // de trace — pas un seul octet — la ou la source de fichier doit encore
    // rapatrier le fichier entier.
    //
    // L INTERSECTION SE FAIT DANS L ORDRE DE [familles], jamais dans celui de
    // l appelant : cet ordre est celui des cles etrangeres, et le perdre ferait
    // echouer un hebergement pose avant son etape.
    final aInterroger = familles
        .where(famillesDemandees.contains)
        .toList(growable: false);

    if (aInterroger.isEmpty) {
      _log.d(
        '[Source interrogeable] $trailId : niveau « regarder » — aucune requete '
        'emise, 0 enregistrement.',
      );
      return const MorceauxAPrendre.rien();
    }

    final parFamille = <String, dynamic>{};
    var transferes = 0;
    var retenus = 0;

    for (final famille in aInterroger) {
      final List<Map<String, dynamic>> recus;
      try {
        recus = await interroger(trailId, famille, revisionLocale);
      } catch (e) {
        // UN ECHEC DE FAMILLE EST UN ECHEC DE SENTIER. Poursuivre donnerait une
        // copie partielle presentee comme complete, et la revision locale
        // avancerait sur des donnees absentes — exactement ce que la garantie
        // #C1 interdit.
        throw Exception(
          'Requete « rev > $revisionLocale » impossible sur « $famille » de '
          '$trailId : $e',
        );
      }

      transferes += recus.length;

      // LE TRI EST REAPPLIQUE A L ARRIVEE, ET CE N EST PAS DE LA DEFIANCE
      // ENVERS LE SERVEUR. Un enregistrement publie SANS `rev` est rattache a la
      // revision courante du sentier (#R6) : une requete serveur sur un champ
      // absent ne peut pas le savoir, alors que la regle, elle, est la meme
      // partout. Un seul endroit decide « a prendre ».
      final aPrendre = _Tri.retenus(
        recus,
        revisionLocale: revisionLocale,
        revisionCible: revisionCible,
      );
      if (aPrendre.isEmpty) continue;

      retenus += aPrendre.length;
      parFamille[famille] = famille == MorceauxDeSentier.fiche
          ? aPrendre.first
          : aPrendre;
    }

    _log.d(
      '[Source interrogeable] $trailId $revisionLocale -> $revisionCible : '
      '$transferes enregistrement(s) descendus, $retenus retenu(s) — le '
      'transfert est unitaire.',
    );

    return MorceauxAPrendre(
      parFamille: parFamille,
      transferes: transferes,
      retenus: retenus,
    );
  }
}
