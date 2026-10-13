/// Le dernier chainon : la question « donne-moi ce qui est plus recent que mon
/// repere » part enfin a Firestore, et plus a un double de test.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../data/revision_de_donnee.dart';
import '../firebase/firebase_service.dart';
import '../models/trail_manifest.dart';
import 'trail_record_source.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// LA QUESTION PART ENFIN AU SERVEUR (tache 641).
///
/// CE QUI MANQUAIT, ET C EST LE DERNIER CHAINON. Les lots 605 a 610 ont livre
/// tout le modele : `SourceInterrogeable` pose la question « donne-moi ce qui est
/// plus recent que mon repere » a une base interrogeable, famille par famille,
/// et la pose reste `appliquerRevisions`. Mais la MESURE du 30/09 est sans appel :
/// `SourceInterrogeable` n etait instancie NULLE PART dans `lib/` — seulement dans
/// des tests, contre un double. Le seul point d instanciation de production
/// (`DeltaUpdateService`) retombait sur `SourceFichierEntier`, donc sur un fichier
/// dans Firebase Storage, dont la mesure du meme jour dit qu il repond 403. Rien
/// ne descendait, et rien ne le disait.
///
/// CE FICHIER EST LA REQUETE REELLE, ET RIEN D AUTRE. Il traduit
/// `RequeteParRevision` en une requete Firestore :
/// `collection('trails/{trailId}/{famille}').where('rev', '>', Timestamp)`. C est
/// litteralement ce que la documentation de `SourceInterrogeable` annonce depuis
/// le lot 605 ; aucune logique de revision n est reprise ici, sinon deux endroits
/// decideraient de ce qui est « a prendre ».
///
/// DEUX CONVERSIONS, ET ELLES SONT LE VRAI TRAVAIL DE CE FICHIER.
///
///  1. LE PLANCHER PART EN `Timestamp`, PAS EN CHAINE. Firestore compare les
///     horodatages NATIVEMENT : `where('rev', '>', Timestamp)` se resout cote
///     serveur, donc seuls les enregistrements concernes traversent le reseau.
///     Envoyer une chaine ISO comparerait des textes et rendrait n importe quoi.
///
///  2. CE QUI REMONTE EST APLATI EN JSON PUR. Le pilote Firestore rend des objets
///     `Timestamp`, `GeoPoint`, `DocumentReference` — et `HorodatageServeur`
///     n en connait aucun : il accepte un entier, une chaine ISO, ou la forme
///     `{seconds, nanoseconds}` d un `Timestamp` SERIALISE. Un `Timestamp` laisse
///     tel quel dans la carte ferait rendre `null` a
///     `annonceParLeServeur`, donc rattacher l enregistrement a la revision
///     courante du sentier (#R6) : il redescendrait a CHAQUE passage, en silence,
///     et le modele de revision ne servirait plus a rien. La conversion est donc
///     structurelle, pas cosmetique.
///
/// LE PERIMETRE EST LE SENTIER, ET IL EST DANS LE CHEMIN. `trails/{trailId}/...` :
/// un randonneur qui possede un sentier ne peut pas, par construction, declencher
/// la descente des quarante autres (precision de Christophe, 28/09).
class RequeteFirestoreParRevision {
  RequeteFirestoreParRevision({FirebaseFirestore? firestore})
    : _firestore = firestore;

  FirebaseFirestore? _firestore;

  /// Accesseur paresseux : les tests injectent un faux, la production prend
  /// l instance par defaut au premier appel — jamais a la construction, pour que
  /// creer le service ne demande pas que Firebase soit deja demarre.
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  /// La requete, telle que [SourceInterrogeable] l attend.
  Future<List<Map<String, dynamic>>> call(
    String trailId,
    String famille,
    HorodatageServeur revisionMinimale,
  ) async {
    final instantarien = Timestamp.fromMillisecondsSinceEpoch(
      revisionMinimale.millisecondesEpoch,
    );

    final resultat = await firestore
        .collection('trails')
        .doc(trailId)
        .collection(famille)
        .where(RevisionDeDonnee.champRevision, isGreaterThan: instantarien)
        .get();

    final recus = <Map<String, dynamic>>[];
    for (final document in resultat.docs) {
      recus.add(aplatir(document.data()));
    }

    _log.d(
      '[Firestore] trails/$trailId/$famille rev > '
      '${revisionMinimale.iso8601} : ${recus.length} enregistrement(s).',
    );
    return recus;
  }

  /// APLATIT UNE CARTE FIRESTORE EN JSON PUR.
  ///
  /// Publique parce qu elle est TESTEE SEULE : c est la conversion dont depend
  /// tout le reste, et un `Timestamp` qui passerait au travers ferait redescendre
  /// le sentier entier a chaque passage sans qu aucune erreur ne soit levee.
  static Map<String, dynamic> aplatir(Map<String, dynamic> brut) => {
    for (final entree in brut.entries) entree.key: _valeur(entree.value),
  };

  static Object? _valeur(Object? valeur) {
    if (valeur is Timestamp) {
      // EN MILLISECONDES, ET C EST LA FORME QUE `HorodatageServeur` PREFERE :
      // elle est exacte a la milliseconde, sans passage par un texte a
      // normaliser (« …:00Z » et « …:00.000Z » designent le meme instant et ne se
      // comparent pas pareil — le piege ecarte par la tache 610).
      return valeur.millisecondsSinceEpoch;
    }
    if (valeur is DocumentReference) return valeur.path;
    if (valeur is GeoPoint) {
      return <String, dynamic>{'lat': valeur.latitude, 'lng': valeur.longitude};
    }
    if (valeur is Map) {
      return <String, dynamic>{
        for (final e in valeur.entries) e.key.toString(): _valeur(e.value),
      };
    }
    if (valeur is List) return valeur.map(_valeur).toList();
    return valeur;
  }
}

/// LA LISTE DES SENTIERS DISPONIBLES, LUE EN BASE (tache 641).
///
/// DEMANDE DE CHRISTOPHE DU 30/09 11:52, verbatim : « Je ne vois toujours pas les
/// donnees Mare a Mare dans Firebase, ni demo, ni normal, rien, d ou viennent les
/// infos de l application ». La reponse mesuree etait : des assets embarques et
/// d une constante Dart. La liste distante existait bien (lot 605) mais elle vivait
/// dans un FICHIER de Firebase Storage que personne n avait jamais deposé.
///
/// CE SERVICE LIT LA COLLECTION `trails`, ET IL FERME UNE DETTE NOMMEE. La tache
/// 610 avait laisse ce constat par ecrit (#100746) : « UpdateChecker lit encore
/// l instant du sentier directement dans Firestore (trails/{id}.data_version)
/// alors que la liste publiee le porte deja — DEUX AUTORITES sur la meme valeur
/// [...] a trancher quand la console existera ». La console existe. C est tranche :
/// `trails/{trailId}` EST la liste. `UpdateChecker` et le catalogue lisent
/// desormais le meme document, et il n y a plus qu une autorite.
///
/// LE FICHIER RESTE UN REPLI, IL N EST PLUS LA SOURCE. `TrailDataSource`
/// (Storage) est conserve pour le cas ou Firebase n est pas disponible — mode
/// local, build sans identifiant de projet — et parce que les gros fichiers
/// (tuiles) y vivent. L arbitrage du lot 605 est donc respecte a la lettre :
/// Firestore pour la liste et les donnees structurees, Storage pour les fichiers
/// lourds.
class FirestoreTrailList {
  FirestoreTrailList({
    required this.firebaseService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseService firebaseService;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  /// Version de schema de la liste, la meme que celle du fichier publie.
  static const int versionDeSchema = 2;

  /// Lit la liste des sentiers publies, ou `null` si elle n est pas lisible.
  ///
  /// `null` N EST PAS UNE LISTE VIDE, et la distinction est celle sur laquelle
  /// repose tout le repli du catalogue : `null` veut dire « je n ai pas pu
  /// demander », une liste vide voudrait dire « le serveur dit qu il n y a aucun
  /// sentier ». Confondre les deux ferait disparaitre le catalogue compile du
  /// telephone au premier incident reseau.
  Future<TrailManifest?> lire() async {
    if (!firebaseService.isAvailable) {
      _log.d('[Liste] Firebase indisponible — la liste en base n est pas lue.');
      return null;
    }

    try {
      final resultat = await firestore.collection('trails').get();
      final entrees = <TrailManifestEntry>[];
      for (final document in resultat.docs) {
        final entree = versEntree(document.id, document.data());
        if (entree != null) entrees.add(entree);
      }
      if (entrees.isEmpty) {
        _log.w(
          '[Liste] La collection « trails » ne contient aucune entree lisible. '
          'Publiez un sentier (tool/publier_en_base.py) avant d attendre quoi '
          'que ce soit du catalogue distant.',
        );
      }
      entrees.sort((a, b) => a.trailId.compareTo(b.trailId));
      return TrailManifest(schemaVersion: versionDeSchema, trails: entrees);
    } catch (e) {
      _log.w('[Liste] Lecture de « trails » impossible : $e');
      return null;
    }
  }

  /// Lit l entree d UN sentier, pour une synchronisation ciblee.
  Future<TrailManifestEntry?> lireUn(String trailId) async {
    if (!firebaseService.isAvailable) return null;
    try {
      final document = await firestore.collection('trails').doc(trailId).get();
      final donnees = document.data();
      if (!document.exists || donnees == null) {
        _log.d('[Liste] Aucun document trails/$trailId.');
        return null;
      }
      return versEntree(document.id, donnees);
    } catch (e) {
      _log.w('[Liste] Lecture de trails/$trailId impossible : $e');
      return null;
    }
  }

  /// TRADUIT UN DOCUMENT `trails/{id}` EN ENTREE DE LISTE.
  ///
  /// Le document est ecrit a plat, en `snake_case`, par
  /// `tool/publier_en_base.py` : c est la meme ecriture que le fichier de donnees
  /// publie, et c est deliberé — un troisieme format serait une troisieme
  /// divergence (piege #Z01). La `fiche`, elle, garde ses noms de champs
  /// `camelCase` parce qu elle est la copie litterale de `TrailManifestSheet`, que
  /// `freezed` deserialise.
  ///
  /// RETOURNE `null` PLUTOT QUE DE LEVER. Un document mal forme ne doit pas rendre
  /// TOUT le catalogue illisible : il est ecarte, et la cause est dite.
  static TrailManifestEntry? versEntree(
    String identifiant,
    Map<String, dynamic> brut,
  ) {
    final donnees = RequeteFirestoreParRevision.aplatir(brut);
    try {
      final fiche = donnees['fiche'];
      return TrailManifestEntry(
        trailId: (donnees['trail_id'] as String?) ?? identifiant,
        dataVersion:
            HorodatageServeur.annonceParLeServeur(donnees['data_version']) ??
            HorodatageServeur.origine,
        hash: (donnees['hash'] as String?) ?? '',
        filePath: (donnees['file_path'] as String?) ?? '',
        fileSize: (donnees['file_size'] as num?)?.toInt() ?? 0,
        status: (donnees['status'] as String?) ?? 'active',
        // `lastUpdated` EST DERIVE DE `dataVersion`, JAMAIS RELU SEPAREMENT.
        // C est la dette #X12 de la tache 610, et elle se solde ici : deux noms
        // pour un meme instant, c est deux autorites, et celle qui decide n est
        // pas celle qu un humain lit. Le document porte bien `last_updated` pour
        // la console, mais il n entre pas dans la decision.
        lastUpdated:
            (HorodatageServeur.annonceParLeServeur(donnees['data_version']) ??
                    HorodatageServeur.origine)
                .iso8601,
        fiche: fiche is Map<String, dynamic>
            ? TrailManifestSheet.fromJson(fiche)
            : null,
        tilesPath: donnees['tiles_path'] as String?,
        tilesSize: (donnees['tiles_size'] as num?)?.toInt(),
        tilesHash: donnees['tiles_hash'] as String?,
      );
    } catch (e) {
      _log.w(
        '[Liste] trails/$identifiant ecarte : $e. Le sentier n apparaitra pas au '
        'catalogue distant — mieux vaut une carte absente et DITE qu une carte a '
        'trous.',
      );
      return null;
    }
  }
}

/// La requete par revision branchee sur Firestore.
final requeteFirestoreParRevisionProvider =
    Provider<RequeteFirestoreParRevision>(
      (ref) => RequeteFirestoreParRevision(),
    );

/// LA SOURCE DE DONNEES DE SENTIER EFFECTIVE, ET ELLE SE CHOISIT UNE FOIS.
///
/// Firebase disponible : la source est INTERROGEABLE, le transfert est unitaire,
/// et les familles hors niveau ne sont meme pas demandees — c est la seule
/// economie reelle de transport du modele (tache 616).
///
/// Firebase indisponible (mode local, build sans `STEPWAYS_FIREBASE_PROJECT_ID`) :
/// on retombe sur le FICHIER ENTIER, c est-a-dire le comportement d avant ce lot.
/// Le repli est explicite et journalise : il ne doit pas etre confondu avec un
/// fonctionnement normal, parce qu il suppose un depot dans Storage que personne
/// n alimente aujourd hui.
final trailRecordSourceProvider = Provider<TrailRecordSource>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  if (!firebase.isAvailable) {
    _log.w(
      '[Source] Firebase indisponible : les donnees de sentier retombent sur le '
      'fichier entier (Storage). Aucun sentier n y est publie a ce jour — la '
      'copie embarquee reste le seul contenu.',
    );
    return SourceFichierEntier();
  }
  return SourceInterrogeable(
    ref.watch(requeteFirestoreParRevisionProvider).call,
  );
});

/// La liste des sentiers publies, lue en base.
final firestoreTrailListProvider = Provider<FirestoreTrailList>(
  (ref) =>
      FirestoreTrailList(firebaseService: ref.watch(firebaseServiceProvider)),
);
