import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

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
  });

  /// Rien a prendre : le telephone est deja a jour.
  const MorceauxAPrendre.rien()
      : parFamille = const {},
        transferes = 0,
        retenus = 0,
        octetsRecus = 0;

  /// Les enregistrements a poser, par famille, dans la forme du fichier publie.
  final Map<String, dynamic> parFamille;

  /// Enregistrements qui ont REELLEMENT traverse le reseau.
  final int transferes;

  /// Enregistrements retenus, c est-a-dire plus recents que la revision locale.
  final int retenus;

  /// Octets recus, quand la source peut les compter (0 = inconnu).
  final int octetsRecus;

  /// Part inutile du transfert : ce qui est descendu pour rien.
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
abstract interface class SourceDeDonneesSentier {
  /// Les enregistrements de [trailId] dont la revision depasse [revisionLocale].
  ///
  /// [revisionCible] est la revision courante du sentier : elle sert de revision
  /// par defaut aux enregistrements qui n en declarent pas (#R6 de la spec).
  ///
  /// [adresse] localise les donnees. Une source de fichier y lit une URL ; une
  /// source interrogeable peut l ignorer.
  Future<MorceauxAPrendre> depuisLaRevision(
    String trailId, {
    required String adresse,
    required int revisionLocale,
    required int revisionCible,
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
    required int revisionLocale,
    required int revisionCible,
  }) {
    return enregistrements
        .where((e) => RevisionDeDonnee.aPrendre(
              e,
              revisionLocale: revisionLocale,
              revisionDuSentier: revisionCible,
            ))
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
class SourceFichierEntier implements SourceDeDonneesSentier {
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
    required int revisionLocale,
    required int revisionCible,
  }) async {
    final (donnees, octets) = await _telecharger(adresse);

    final parFamille = <String, dynamic>{};
    var transferes = 0;
    var retenus = 0;

    for (final famille in donnees.keys) {
      final tous = _Tri.enregistrements(donnees[famille]);
      transferes += tous.length;

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
      '[Source fichier] $trailId v$revisionLocale -> v$revisionCible : '
      '$octets octets, $transferes enregistrement(s) descendus, $retenus '
      'retenu(s) — ${transferes - retenus} transfere(s) pour rien.',
    );

    return MorceauxAPrendre(
      parFamille: parFamille,
      transferes: transferes,
      retenus: retenus,
      octetsRecus: octets,
    );
  }

  Future<(Map<String, dynamic>, int)> _telecharger(String url) async {
    Object? derniereCause;

    for (var tentative = 1; tentative <= tentatives; tentative++) {
      try {
        final reponse = await _httpClient.get(Uri.parse(url));
        if (reponse.statusCode == 200) {
          final corps = jsonDecode(reponse.body) as Map<String, dynamic>;
          return (corps, reponse.bodyBytes.length);
        }
        derniereCause = 'HTTP ${reponse.statusCode}';
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
/// `collection('trails/$trailId/$famille').where('rev', '>', revisionMinimale)`.
/// Le moteur ne depend PAS de `cloud_firestore` pour cela : la dependance
/// s arrete a cette signature, ce qui permet de l eprouver contre un double
/// aujourd hui — aucun des deux services n est provisionne — et de la brancher le
/// jour ou la console existe, sans toucher a la logique.
typedef RequeteParRevision = Future<List<Map<String, dynamic>>> Function(
  String trailId,
  String famille,
  int revisionMinimale,
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
class SourceInterrogeable implements SourceDeDonneesSentier {
  const SourceInterrogeable(this.interroger, {this.familles = MorceauxDeSentier.tous});

  /// La requete par revision, une par famille.
  final RequeteParRevision interroger;

  /// Les familles a interroger, dans l ordre des cles etrangeres.
  final List<String> familles;

  @override
  Future<MorceauxAPrendre> depuisLaRevision(
    String trailId, {
    required String adresse,
    required int revisionLocale,
    required int revisionCible,
  }) async {
    final parFamille = <String, dynamic>{};
    var transferes = 0;
    var retenus = 0;

    for (final famille in familles) {
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
      '[Source interrogeable] $trailId v$revisionLocale -> v$revisionCible : '
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
