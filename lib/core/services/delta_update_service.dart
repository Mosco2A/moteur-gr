import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../data/database.dart' hide TrailManifest;
import '../data/daos/trail_manifests_dao.dart';
import '../data/daos/trail_stages_dao.dart';
import '../data/daos/trail_accommodations_dao.dart';
import '../data/daos/trail_pois_dao.dart';
import '../data/daos/trail_gpx_tracks_dao.dart';
import '../data/daos/trail_gpx_points_dao.dart';
import '../data/daos/trail_itineraries_dao.dart';
import '../data/daos/trail_meta_dao.dart';
import '../data/revision_de_donnee.dart';
import '../models/delta_update.dart';
import '../models/trail_manifest.dart';
import '../providers/database_provider.dart';
import 'manifest_service.dart';
import 'source_de_donnees_sentier.dart';
import 'package:drift/drift.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// COPIE ET MISE A JOUR DES DONNEES D UN SENTIER, PAR REVISION.
///
/// TROIS DECISIONS DE CHRISTOPHE VIVENT DANS CE FICHIER.
///
///  1. LA COPIE COMPLETE SUR LE TELEPHONE (20:11, « il faut la copie du sentier
///     sur le tel »). Le fichier est INTEGRALEMENT rapatrie AVANT la moindre
///     ecriture, puis pose en UNE SEULE TRANSACTION. Une coupure en cours de
///     route ne laisse RIEN en base (retour arriere SQLite) et le sentier reste
///     « a prendre » : jamais un demi-sentier presente comme disponible. Sur le
///     GR20 il n y a pas de reseau — un sentier a moitie copie est un randonneur
///     en difficulte.
///
///  2. UNE SEULE INFO DE VERSION, PORTEE PAR LA DONNEE (20:43). L application ne
///     calcule RIEN : elle lit le numero de chaque enregistrement et prend tout
///     ce qui depasse sa propre revision. Il n y a plus de liste de tables
///     changees, plus de comparaison par famille, plus d inference.
///
///  3. LE REPERE DE REVISION EST REELLEMENT REECRIT. `trail_manifests.localVersion`
///     — la revision jusqu ou le telephone est a jour — est ecrit dans la MEME
///     transaction que les donnees. C etait LE defaut mesure : personne ne
///     l ecrivait, alors que `TrailManifestsDao.needsUpdate` s en sert pour
///     decider s il faut telecharger. Chaque ouverture retelechargeait tout.
///
/// CE QUI A ETE SUPPRIME. `_inferChangedTables(int from, int to)` retournait les
/// sept tables EN DUR sans jamais lire ses deux parametres : le « delta » etait un
/// rechargement integral deguise. Elle n a pas ete renommee ni rendue plus fine —
/// elle a disparu, parce que la question qu elle pretendait resoudre ne se pose
/// plus quand la donnee porte son propre numero.
///
/// UN SEUL CHEMIN DE CODE. Premiere copie et mise a jour ne sont pas deux cas : a
/// la revision zero, tout est plus recent que la revision locale, donc tout
/// descend. Si l on se retrouvait a ecrire deux chemins, c est que le modele
/// serait mauvais.
class DeltaUpdateService {
  DeltaUpdateService({
    required this.db,
    required this.manifestService,
    required this.trailManifestsDao,
    required this.trailMetaDao,
    required this.trailItinerariesDao,
    required this.trailStagesDao,
    required this.trailAccommodationsDao,
    required this.trailPoisDao,
    required this.trailGpxTracksDao,
    required this.trailGpxPointsDao,
    SourceDeDonneesSentier? source,
    http.Client? httpClient,
  }) : source = source ?? SourceFichierEntier(httpClient: httpClient);

  /// La base, pour ouvrir la TRANSACTION qui rend la copie atomique.
  ///
  /// Les DAO ne suffisent pas : chacun ne voit que sa table, et la garantie
  /// demandee par Christophe porte sur l ENSEMBLE des donnees d un sentier.
  final AppDatabase db;

  final ManifestService manifestService;
  final TrailManifestsDao trailManifestsDao;
  final TrailMetaDao trailMetaDao;
  final TrailItinerariesDao trailItinerariesDao;
  final TrailStagesDao trailStagesDao;
  final TrailAccommodationsDao trailAccommodationsDao;
  final TrailPoisDao trailPoisDao;
  final TrailGpxTracksDao trailGpxTracksDao;
  final TrailGpxPointsDao trailGpxPointsDao;

  /// D OU VIENT CE QUI DEPASSE MA REVISION.
  ///
  /// Par defaut [SourceFichierEntier] : un fichier publie dans l espace de
  /// stockage, lu en HTTP REST, trie a l arrivee. Injecter [SourceInterrogeable]
  /// fait partir la question au serveur — le transfert devient unitaire et la
  /// suite du code ne bouge pas.
  final SourceDeDonneesSentier source;

  /// Y a-t-il quelque chose de plus recent que ma revision ?
  ///
  /// C est TOUTE la question. Elle ne dit pas ce qui a change — cela se lit dans
  /// les donnees au moment de les poser, et se rend en [ResultatSynchronisation].
  Future<DeltaUpdate?> checkForUpdates(
    String trailId, {
    required TrailManifest remoteManifest,
  }) async {
    final distant =
        remoteManifest.trails.where((t) => t.trailId == trailId).firstOrNull;
    if (distant == null) return null;

    final locale = await revisionLocale(trailId);
    if (locale >= distant.dataVersion) return null;

    return DeltaUpdate(
      trailId: trailId,
      fromVersion: locale,
      toVersion: distant.dataVersion,
      downloadSize: distant.fileSize,
    );
  }

  /// Revision jusqu ou le telephone est a jour pour [trailId]. Zero si rien.
  Future<int> revisionLocale(String trailId) async {
    final ligne = await trailManifestsDao.getByTrailId(trailId);
    return ligne?.localVersion ?? RevisionDeDonnee.revisionInitiale;
  }

  /// Applique des donnees deja telechargees, EN UNE SEULE TRANSACTION.
  ///
  /// [donnees] est le fichier de donnees du sentier : un objet dont les clefs
  /// sont les sept familles ([MorceauxDeSentier]) et les valeurs les
  /// enregistrements, chacun portant sa revision.
  ///
  /// SEULS LES ENREGISTREMENTS PLUS RECENTS QUE [revisionLocale] SONT POSES, et
  /// ceux qui portent un marqueur de suppression sont RETIRES. C est la seule
  /// regle, et elle s applique identiquement a la premiere copie (revision locale
  /// a zero : tout passe) et a une correction d altitude (une etape passe).
  ///
  /// [revisionCible] est la revision courante du sentier : elle sert de revision
  /// par defaut aux enregistrements qui n en declarent pas (donnees deposees
  /// avant ce modele), et c est elle qui est inscrite comme nouveau repere une
  /// fois tout pose.
  ///
  /// L ORDRE EST IMPOSE, PAS SUBI : les familles sont appliquees dans l ordre des
  /// cles etrangeres ([MorceauxDeSentier.tous]) et non dans l ordre des clefs du
  /// JSON. L ancien code iterait sur `deltaJson.keys` et dependait donc de
  /// l ordre d ecriture du fichier — un hebergement avant son etape echouait.
  Future<ResultatSynchronisation> appliquerRevisions(
    String trailId,
    Map<String, dynamic> donnees, {
    required int revisionLocale,
    required int revisionCible,
    List<String> famillesLimitees = const [],
  }) async {
    final inconnues = donnees.keys
        .where((k) => !MorceauxDeSentier.estConnu(k))
        .toList();
    if (inconnues.isNotEmpty) {
      _log.w(
        '[Revision] $trailId : familles inconnues ignorees '
        '(${inconnues.join(", ")}) — aucune table de ce nom dans cette version '
        'de l application.',
      );
    }

    final familles = MorceauxDeSentier.tous
        .where((f) =>
            donnees[f] != null &&
            (famillesLimitees.isEmpty || famillesLimitees.contains(f)))
        .toList();

    final touchees = <String>[];
    var ecrits = 0;
    var supprimes = 0;

    // LA TRANSACTION, C EST LE POINT 1 DE CHRISTOPHE. Tout passe ou rien ne
    // passe : une exception sur la sixieme famille annule les cinq premieres, et
    // le repere de revision n est pas ecrit — le sentier reste « a prendre » au
    // lieu d etre a moitie copie.
    await db.transaction(() async {
      for (final famille in familles) {
        final bilan = await _appliquerFamille(
          famille,
          donnees[famille],
          revisionLocale: revisionLocale,
          revisionCible: revisionCible,
        );
        if (bilan.ecrits > 0 || bilan.supprimes > 0) touchees.add(famille);
        ecrits += bilan.ecrits;
        supprimes += bilan.supprimes;
      }

      // LE REPERE, ECRIT AVEC LES DONNEES QU IL CERTIFIE. Un repere qui
      // survivrait a un retour arriere des donnees serait pire que pas de repere :
      // le telephone se croirait a jour sur des donnees absentes.
      if (revisionCible > revisionLocale) {
        await trailManifestsDao.inscrireRevision(trailId, revisionCible);
      }
    });

    _log.d(
      '[Revision] $trailId : v$revisionLocale -> v$revisionCible, '
      '$ecrits enregistrement(s) ecrit(s), $supprimes retire(s), '
      'familles touchees : ${touchees.isEmpty ? "aucune" : touchees.join(", ")}',
    );

    return ResultatSynchronisation(
      famillesTouchees: touchees,
      ecrits: ecrits,
      supprimes: supprimes,
      revisionAtteinte: revisionCible > revisionLocale
          ? revisionCible
          : revisionLocale,
    );
  }

  /// DEMANDE CE QUI DEPASSE MA REVISION, PUIS LE POSE. CHEMIN UNIQUE.
  ///
  /// C est le seul chemin de descente des donnees d un sentier : premiere copie,
  /// correction d altitude, suppression d un point d eau passent tous ici. Le
  /// geste « telecharger » du catalogue y passe aussi depuis la tache 606 — il
  /// empruntait jusque-la un SECOND chemin (`TrailDownloadService`) qui ignorait
  /// les revisions, ignorait les marqueurs de suppression et posait famille par
  /// famille hors transaction.
  ///
  /// LE TRANSFERT EST DELEGUE A [source], ET C EST LA TOUT LE LOT 606-X2. « Donne
  /// moi tout ce qui a une revision superieure a la mienne » est une question,
  /// pas un telechargement : sur un fichier entier elle se tranche a l arrivee,
  /// sur une source interrogeable elle part au serveur. La POSE, elle, ne change
  /// pas d une ligne — c est le signe que le modele de revision est le bon.
  ///
  /// LE TRANSFERT EST HORS TRANSACTION, deliberement. Le reseau ne doit jamais
  /// tenir un verrou d ecriture SQLite : sur une liaison de montagne, une
  /// transaction ouverte pendant un transfert bloquerait la base pendant des
  /// minutes.
  Future<ResultatSynchronisation> synchroniser(
    String trailId,
    String urlDonnees, {
    required int revisionCible,
    int? revisionLocaleConnue,
  }) async {
    final locale = revisionLocaleConnue ?? await revisionLocale(trailId);
    final aPrendre = await source.depuisLaRevision(
      trailId,
      adresse: urlDonnees,
      revisionLocale: locale,
      revisionCible: revisionCible,
    );
    return appliquerRevisions(
      trailId,
      aPrendre.parFamille,
      revisionLocale: locale,
      revisionCible: revisionCible,
    );
  }

  /// Applique une famille : ecrit ce qui est plus recent, retire les tombes.
  Future<_Bilan> _appliquerFamille(
    String famille,
    dynamic brut, {
    required int revisionLocale,
    required int revisionCible,
  }) async {
    // `trail_meta` est un objet unique, les six autres des listes.
    final enregistrements = <Map<String, dynamic>>[
      if (brut is Map<String, dynamic>) brut,
      if (brut is List)
        ...brut.map((e) => Map<String, dynamic>.from(e as Map)),
    ];

    var ecrits = 0;
    var supprimes = 0;

    for (final donnee in enregistrements) {
      if (!RevisionDeDonnee.aPrendre(
        donnee,
        revisionLocale: revisionLocale,
        revisionDuSentier: revisionCible,
      )) {
        continue; // Deja a jour sur le telephone : on n y touche pas.
      }

      final rev = RevisionDeDonnee.revisionDe(donnee, defaut: revisionCible);

      if (RevisionDeDonnee.estSupprimee(donnee)) {
        // LE MARQUEUR DE SUPPRESSION, SANS LEQUEL LA CORRECTION NE MARCHE QUE
        // DANS UN SENS. Un numero qui ne fait que monter ne peut pas transmettre
        // une ABSENCE : un point d eau tari, un refuge ferme, un point d interet
        // retire resteraient a vie sur le telephone du randonneur. La donnee
        // redescend donc avec sa revision ET la marque « retire-la ».
        supprimes += await _supprimer(famille, donnee);
        continue;
      }

      await _ecrire(famille, donnee, rev);
      ecrits++;
    }

    return _Bilan(ecrits: ecrits, supprimes: supprimes);
  }

  Future<void> _ecrire(
    String famille,
    Map<String, dynamic> d,
    int rev,
  ) async {
    switch (famille) {
      case MorceauxDeSentier.fiche:
        await trailMetaDao.insertOrReplace(TrailMetaCompanion(
          id: Value(d['id'] as String), code: Value(d['code'] as String),
          dataVersion: Value(d['data_version'] as int? ?? rev),
          lastSync: Value(DateTime.now().toIso8601String()),
          status: Value(d['status'] as String? ?? 'active'),
          rev: Value(rev)));
      case MorceauxDeSentier.itineraires:
        await trailItinerariesDao.insertOrReplace(TrailItinerariesCompanion(
          id: Value(d['id'] as String), trailId: Value(d['trail_id'] as String),
          code: Value(d['code'] as String), nameFr: Value(d['name_fr'] as String),
          nameEn: Value(d['name_en'] as String), nameDe: Value(d['name_de'] as String),
          nameIt: Value(d['name_it'] as String), nameEs: Value(d['name_es'] as String),
          distanceKm: Value((d['distance_km'] as num).toDouble()),
          elevationGain: Value(d['elevation_gain'] as int),
          stageCount: Value(d['stage_count'] as int),
          rev: Value(rev)));
      case MorceauxDeSentier.etapes:
        await trailStagesDao.insertOrReplace(TrailStagesCompanion(
          id: Value(d['id'] as String), itineraryId: Value(d['itinerary_id'] as String),
          stageNumber: Value(d['stage_number'] as int),
          nameFr: Value(d['name_fr'] as String), nameEn: Value(d['name_en'] as String),
          nameDe: Value(d['name_de'] as String), nameIt: Value(d['name_it'] as String),
          nameEs: Value(d['name_es'] as String),
          startLat: Value((d['start_lat'] as num).toDouble()),
          startLng: Value((d['start_lng'] as num).toDouble()),
          endLat: Value((d['end_lat'] as num).toDouble()),
          endLng: Value((d['end_lng'] as num).toDouble()),
          distanceKm: Value((d['distance_km'] as num).toDouble()),
          elevationGain: Value(d['elevation_gain'] as int),
          elevationLoss: Value(d['elevation_loss'] as int),
          durationMinutes: Value(d['duration_minutes'] as int),
          difficulty: Value(d['difficulty'] as String),
          rev: Value(rev)));
      case MorceauxDeSentier.hebergements:
        await trailAccommodationsDao.insertOrReplace(TrailAccommodationsCompanion(
          id: Value(d['id'] as String), stageId: Value(d['stage_id'] as String),
          nameFr: Value(d['name_fr'] as String), nameEn: Value(d['name_en'] as String),
          nameDe: Value(d['name_de'] as String), nameIt: Value(d['name_it'] as String),
          nameEs: Value(d['name_es'] as String), type: Value(d['type'] as String),
          lat: Value((d['lat'] as num).toDouble()), lng: Value((d['lng'] as num).toDouble()),
          phone: Value(d['phone'] as String?), email: Value(d['email'] as String?),
          website: Value(d['website'] as String?), capacity: Value(d['capacity'] as int?),
          priceRange: Value(d['price_range'] as String?),
          bookingUrl: Value(d['booking_url'] as String?),
          rev: Value(rev)));
      case MorceauxDeSentier.pointsDInteret:
        await trailPoisDao.insertOrReplace(TrailPoisCompanion(
          id: Value(d['id'] as String), stageId: Value(d['stage_id'] as String),
          nameFr: Value(d['name_fr'] as String), nameEn: Value(d['name_en'] as String),
          nameDe: Value(d['name_de'] as String), nameIt: Value(d['name_it'] as String),
          nameEs: Value(d['name_es'] as String),
          descriptionFr: Value(d['description_fr'] as String?),
          descriptionEn: Value(d['description_en'] as String?),
          descriptionDe: Value(d['description_de'] as String?),
          descriptionIt: Value(d['description_it'] as String?),
          descriptionEs: Value(d['description_es'] as String?),
          type: Value(d['type'] as String),
          lat: Value((d['lat'] as num).toDouble()),
          lng: Value((d['lng'] as num).toDouble()),
          elevation: Value((d['elevation'] as num?)?.toDouble()),
          rev: Value(rev)));
      case MorceauxDeSentier.traces:
        await trailGpxTracksDao.insertOrReplace(TrailGpxTracksCompanion(
          id: Value(d['id'] as String), itineraryId: Value(d['itinerary_id'] as String),
          name: Value(d['name'] as String), sourceUrl: Value(d['source_url'] as String?),
          rev: Value(rev)));
      case MorceauxDeSentier.pointsDeTrace:
        await trailGpxPointsDao.insertOrReplace(TrailGpxPointsCompanion(
          trackId: Value(d['track_id'] as String),
          lat: Value((d['lat'] as num).toDouble()),
          lng: Value((d['lng'] as num).toDouble()),
          elevation: Value((d['elevation'] as num).toDouble()),
          sequenceIndex: Value(d['sequence_index'] as int),
          rev: Value(rev)));
    }
  }

  /// Retire du telephone l enregistrement designe par un marqueur de suppression.
  ///
  /// UN MARQUEUR N A BESOIN QUE DE SON IDENTITE. Le serveur publie l identifiant,
  /// la revision et la marque — pas la donnee entiere, qui n existe plus.
  ///
  /// Les points de trace font exception et c est une contrainte du schema, pas un
  /// choix : `trail_gpx_points` n a pas d identifiant propre (cle technique
  /// auto-incrementee), son identite reelle est le couple trace + rang. Un
  /// marqueur de suppression de point de trace doit donc porter `track_id` et
  /// `sequence_index`.
  Future<int> _supprimer(String famille, Map<String, dynamic> d) async {
    final id = d['id'] as String?;

    switch (famille) {
      case MorceauxDeSentier.fiche:
        if (id == null) break;
        return (db.delete(db.trailMeta)..where((t) => t.id.equals(id))).go();
      case MorceauxDeSentier.itineraires:
        if (id == null) break;
        return (db.delete(db.trailItineraries)..where((t) => t.id.equals(id)))
            .go();
      case MorceauxDeSentier.etapes:
        if (id == null) break;
        return (db.delete(db.trailStages)..where((t) => t.id.equals(id))).go();
      case MorceauxDeSentier.hebergements:
        if (id == null) break;
        return (db.delete(db.trailAccommodations)
              ..where((t) => t.id.equals(id)))
            .go();
      case MorceauxDeSentier.pointsDInteret:
        if (id == null) break;
        return (db.delete(db.trailPois)..where((t) => t.id.equals(id))).go();
      case MorceauxDeSentier.traces:
        if (id == null) break;
        return (db.delete(db.trailGpxTracks)..where((t) => t.id.equals(id)))
            .go();
      case MorceauxDeSentier.pointsDeTrace:
        final trackId = d['track_id'] as String?;
        final rang = d['sequence_index'] as int?;
        if (trackId == null) break;
        return (db.delete(db.trailGpxPoints)
              ..where((t) => rang == null
                  ? t.trackId.equals(trackId)
                  : t.trackId.equals(trackId) &
                      t.sequenceIndex.equals(rang)))
            .go();
    }

    _log.w(
      '[Revision] Marqueur de suppression inexploitable pour « $famille » : '
      'identite manquante. Un marqueur doit porter l identifiant de la donnee '
      'a retirer (ou track_id + sequence_index pour un point de trace).',
    );
    return 0;
  }
}

class _Bilan {
  const _Bilan({required this.ecrits, required this.supprimes});
  final int ecrits;
  final int supprimes;
}

/// Provider Riverpod pour le service de synchronisation des donnees sentier.
final deltaUpdateServiceProvider = Provider<DeltaUpdateService>((ref) {
  final db = ref.watch(databaseProvider);
  return DeltaUpdateService(db: db,
    manifestService: ref.watch(manifestServiceProvider),
    trailManifestsDao: TrailManifestsDao(db),
    trailMetaDao: TrailMetaDao(db),
    trailItinerariesDao: TrailItinerariesDao(db), trailStagesDao: TrailStagesDao(db),
    trailAccommodationsDao: TrailAccommodationsDao(db), trailPoisDao: TrailPoisDao(db),
    trailGpxTracksDao: TrailGpxTracksDao(db), trailGpxPointsDao: TrailGpxPointsDao(db));
});
