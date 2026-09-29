import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meteo_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/data/empreinte_de_publication.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/trace_du_sentier.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';
import 'package:moteur_gr/features/trail/providers/catalogue_sentiers_provider.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';

import '../../tool/publication/publicateur.dart';
import '../../tool/publication/source_de_sentier.dart';

/// TACHE 607 — LE TEST D ACCEPTATION : UN SENTIER INVENTE DE ZERO, FABRIQUE PAR
/// L OUTIL, TRAVERSE TOUTE LA CHAINE JUSQU A L AFFICHAGE DE SA TRACE.
///
/// CE QUI DIFFERE DU TEST D ACCEPTATION DU LOT 606, ET C EST TOUT L OBJET DU LOT.
/// Le lot 606 prouvait qu un sentier decrit a distance est marchable — mais son
/// fichier de donnees etait ECRIT A LA MAIN dans le test. Personne ne savait le
/// fabriquer, donc Christophe ne pouvait PAS ajouter un sentier. Ici, les octets
/// que le double HTTP sert sont EXACTEMENT ceux que `tool/publier_sentier.dart`
/// a produits a partir d un fichier source et d une trace GPX : la chaine est
/// complete de la source de Christophe jusqu au trait sur la carte.
///
/// LE SENTIER EST INVENTE DE ZERO, ET LE DEPOT NE LE CONNAIT PAS. `gr-monts-dore`
/// n est ni dans `TrailCatalog` ni dans les assets : si l outil ne marchait que
/// sur les sentiers deja la, ce test ne passerait pas.
///
/// LES TROIS AUTRES CHOSES QUE CE FICHIER VERROUILLE.
///  1. L EMPREINTE EST VERIFIEE AVANT LA POSE (#X6, laisse ouvert par le lot
///     606). Un fichier tronque mais syntaxiquement valide ne doit RIEN ecrire.
///  2. LA REPUBLICATION NE FAIT DESCENDRE QUE LE MODIFIE, mesure de bout en bout
///     et pas seulement dans l outil.
///  3. UN TELEPHONE TROP EN RETARD REPART DE ZERO (#X5) : au-dela de la fenetre
///     de retention, les marqueurs de suppression ont ete purges, donc appliquer
///     les morceaux laisserait un point d eau tari a vie sur le telephone.
void main() {
  // rootBundle : le secours asset des sentiers embarques est lu pour de vrai.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory bac;
  late String source;
  late String publie;
  late AppDatabase db;
  late TrailManifestsDao manifestes;

  setUp(() {
    bac = Directory.systemTemp.createTempSync('acceptation607');
    source = '${bac.path.replaceAll(r'\', '/')}/source';
    publie = '${bac.path.replaceAll(r'\', '/')}/publie';
    Directory(source).createSync(recursive: true);
    for (final nom in const ['sentier.json', 'trace.gpx']) {
      File('test/fixtures/publication/gr-monts-dore/$nom')
          .copySync('$source/$nom');
    }
    db = AppDatabase(NativeDatabase.memory());
    manifestes = TrailManifestsDao(db);
  });

  tearDown(() async {
    await db.close();
    bac.deleteSync(recursive: true);
  });

  /// CHAQUE PUBLICATION A SON INSTANT (tache 610).
  ///
  /// Depuis que la revision est une DATE, deux publications doivent porter deux
  /// instants distincts et croissants. Le numero de publication devient donc un
  /// NOMBRE DE JOURS depuis un instant de reference FIXE — jamais
  /// `DateTime.now()`, qui ferait dependre le test du jour ou il tourne.
  DateTime horlogeAuJour(int jour) =>
      DateTime.utc(2026, 9, 28).add(Duration(days: jour - 1));

  HorodatageServeur instantAuJour(int jour) =>
      HorodatageServeur.annonceParLeServeur(
          horlogeAuJour(jour).toIso8601String())!;

  Publicateur outil(int jour) =>
      Publicateur(sortie: publie, horloge: horlogeAuJour(jour));

  /// Publie l etat courant de la source et rend l entree de liste produite.
  ///
  /// L entree est aussi CONSERVEE EN BASE, comme le fait la lecture du catalogue
  /// (`_conserver`) : c est cette ligne que la pose met a jour pour inscrire la
  /// revision locale. Sans elle, `inscrireRevision` — un UPDATE — ne touche
  /// aucune ligne et le telephone repart de zero a chaque fois.
  Future<TrailManifestEntry> publier({int jour = 1}) async {
    outil(jour).publier(source);
    final brut = jsonDecode(
      File('$publie/${Publicateur.nomDeLaListe}').readAsStringSync(),
    ) as Map<String, dynamic>;
    final entree = TrailManifest.fromJson(brut)
        .trails
        .firstWhere((e) => e.trailId == 'gr-monts-dore');
    await ManifestService(
      dao: manifestes,
      connectivityMonitor: _FauxReseau(ConnectivityStatusValues.online),
    ).saveLocalManifest(entree);
    return entree;
  }

  void modifierLaSource(void Function(Map<String, dynamic>) changement) {
    final fichier = File('$source/${SourceDeSentier.nomDuFichier}');
    final contenu =
        jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
    changement(contenu);
    fichier.writeAsStringSync(jsonEncode(contenu));
  }

  /// LE DOUBLE SERT LES OCTETS REELLEMENT PRODUITS PAR L OUTIL.
  ///
  /// Pas une re-serialisation : les octets du fichier, tels qu ils seraient
  /// copies dans l espace de stockage. C est ce qui rend la verification
  /// d empreinte significative — un `jsonEncode` de complaisance la validerait
  /// toujours.
  MockClient stockage({List<int>? appels, int? tronquerA}) {
    return MockClient((requete) async {
      appels?.add(1);
      final url = requete.url.toString();
      for (final fichier in _fichiersDe(publie)) {
        final chemin = fichier.substring(publie.length + 1);
        if (!url.contains(Uri.encodeComponent(chemin)) &&
            !url.contains(chemin)) {
          continue;
        }
        var octets = File(fichier).readAsBytesSync();
        if (tronquerA != null && chemin != Publicateur.nomDeLaListe) {
          octets = octets.sublist(0, tronquerA);
        }
        return http.Response.bytes(octets, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      }
      return http.Response('non trouve', 404);
    });
  }

  DeltaUpdateService service({List<int>? appels, int? tronquerA}) =>
      DeltaUpdateService(
        db: db,
        manifestService: ManifestService(
          dao: manifestes,
          connectivityMonitor: _FauxReseau(ConnectivityStatusValues.online),
        ),
        trailManifestsDao: manifestes,
        trailMetaDao: TrailMetaDao(db),
        trailItinerariesDao: TrailItinerariesDao(db),
        trailStagesDao: TrailStagesDao(db),
        trailAccommodationsDao: TrailAccommodationsDao(db),
        trailPoisDao: TrailPoisDao(db),
        trailMeteoDao: TrailMeteoDao(db),
        trailGpxTracksDao: TrailGpxTracksDao(db),
        trailGpxPointsDao: TrailGpxPointsDao(db),
        httpClient: stockage(appels: appels, tronquerA: tronquerA),
      );

  ProviderContainer conteneur({int? tronquerA}) {
    final reseau = _FauxReseau(ConnectivityStatusValues.online);
    return ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      connectivityMonitorProvider.overrideWithValue(reseau),
      manifestServiceProvider.overrideWithValue(ManifestService(
        dao: manifestes,
        connectivityMonitor: reseau,
        httpClient: stockage(),
      )),
      deltaUpdateServiceProvider
          .overrideWith((ref) => service(tronquerA: tronquerA)),
    ]);
  }

  // =========================================================================
  // 1. LE TEST D ACCEPTATION
  // =========================================================================
  group('607 — un sentier FABRIQUE PAR L OUTIL traverse toute la chaine', () {
    test('LE TEST D ACCEPTATION : un sentier invente de zero, publie par '
        '`publier_sentier`, apparait au catalogue, se telecharge, s ouvre, ET '
        'SA TRACE S AFFICHE SUR LA CARTE', () async {
      final entree = await publier();

      // PREMISSE : le depot ne connait pas ce sentier. Sans cela le test ne
      // prouverait rien de l outil.
      expect(TrailCatalog.byId('gr-monts-dore'), isNull);
      expect(entree.dataVersion, instantAuJour(1));
      expect(entree.hash, hasLength(EmpreinteDePublication.longueurHex),
          reason: 'l empreinte est CALCULEE par l outil : avant ce lot, rien ne '
              'la produisait et rien ne la verifiait (#X6)');

      final c = conteneur();
      addTearDown(c.dispose);

      // --- 1. IL APPARAIT AU CATALOGUE ---
      c.read(catalogueSentiersProvider);
      await _laisserLaLectureSeFaire(c);
      final auCatalogue = c
          .read(availableTrailsProvider)
          .where((s) => s.id == 'gr-monts-dore');
      expect(auCatalogue, hasLength(1),
          reason: 'la fiche produite par l outil suffit a peupler le catalogue');
      expect(auCatalogue.single.displayName, 'Tour des Monts Dore');
      expect(auCatalogue.single.region, 'Auvergne');
      expect(auCatalogue.single.gpxAssetPath, isEmpty,
          reason: 'une liste distante ne peut pas inventer un fichier embarque '
              '(#F14) : la trace ne peut venir que de la base');

      // --- 2. IL SE TELECHARGE ---
      await c.read(catalogStateProvider.future);
      await c.read(catalogStateProvider.notifier).downloadTrail('gr-monts-dore',
          niveau: NiveauDeTelechargement.realiser);

      expect(await manifestes.needsUpdate('gr-monts-dore'), isFalse);
      expect(await TrailStagesDao(db).getByItineraryId('montsdore-i1'),
          hasLength(2));
      expect(await TrailPoisDao(db).getByStageId('montsdore-s1'), hasLength(2));
      expect(await TrailAccommodationsDao(db).getByStageId('montsdore-s1'),
          hasLength(1));

      // --- 3. IL S OUVRE ---
      c.read(selectedTrailIdProvider.notifier).state = 'gr-monts-dore';
      expect(c.read(trailConfigProvider).id, 'gr-monts-dore');

      // --- 4. ET SA TRACE S AFFICHE. ELLE VIENT DU .GPX DE LA SOURCE. ---
      final points = await c.read(gpxTrackProvider('gr-monts-dore').future);
      expect(points, hasLength(10),
          reason: 'les dix points du GPX source, passes par l outil, poses en '
              'base, relus par la carte');
      expect(points.first.altitude, 1050.0);
      expect(points.last.altitude, 1260.0);
      expect(points.last.distanceFromStart, greaterThan(0));

      final trace = await c.read(traceDuSentierProvider('gr-monts-dore').future);
      expect(trace.source, SourceDeLaTrace.base);
    });

    test('LA REVISION DE CHAQUE ENREGISTREMENT EST CELLE QUE L OUTIL A ECRITE — '
        'la chaine ne la reinvente pas', () async {
      final entree = await publier();
      await service().synchroniser(
        'gr-monts-dore',
        'https://double/${entree.filePath}',
        niveau: NiveauDeTelechargement.realiser, revisionCible: entree.dataVersion,
        empreinteAttendue: entree.hash,
      );

      expect((await TrailStagesDao(db).getByItineraryId('montsdore-i1'))
          .map((e) => e.rev), everyElement(instantAuJour(1)));
      expect((await TrailGpxPointsDao(db).getAll()).map((p) => p.rev),
          everyElement(instantAuJour(1)));
    });
  });

  // =========================================================================
  // 2. L INTEGRITE — #X6, LAISSE OUVERT PAR LE LOT 606
  // =========================================================================
  group('607 — un fichier dont l empreinte ne correspond pas n ecrit RIEN', () {
    test('UN FICHIER TRONQUE MAIS SYNTAXIQUEMENT VALIDE EST REFUSE : rien en '
        'base, revision locale inchangee, et l echec SE DIT', () async {
      final entree = await publier();
      final octets = File('$publie/${entree.filePath}').readAsBytesSync();

      // On coupe le fichier a un endroit ou il reste du JSON... ou pas : ce qui
      // compte est que l EMPREINTE ne corresponde plus. Le refus intervient
      // AVANT `jsonDecode`, donc avant meme de savoir si le reste se parse.
      final tronque = octets.length - 400;

      await expectLater(
        service(tronquerA: tronque).synchroniser(
          'gr-monts-dore',
          'https://double/${entree.filePath}',
          niveau: NiveauDeTelechargement.realiser, revisionCible: entree.dataVersion,
          empreinteAttendue: entree.hash,
        ),
        throwsA(isA<EmpreinteInvalide>()),
      );

      expect(await TrailStagesDao(db).getByItineraryId('montsdore-i1'), isEmpty,
          reason: 'AVANT CE LOT le champ d empreinte n etait verifie par '
              'PERSONNE : ce fichier passait la copie, sa revision locale etait '
              'inscrite, et le randonneur partait en montagne avec un sentier '
              'incomplet QUI SE CROYAIT COMPLET');
      expect(await TrailGpxPointsDao(db).getAll(), isEmpty);
      expect((await manifestes.getByTrailId('gr-monts-dore'))!.localVersion,
          isNull,
          reason: 'la revision locale n avance pas : le sentier reste « a '
              'prendre » plutot qu a moitie copie (#C1)');
      expect(await manifestes.needsUpdate('gr-monts-dore'), isTrue);
    });

    test('LE REFUS NE SE REESSAYE PAS : un serveur qui sert autre chose que ce '
        'qu il annonce n est pas un aléa de reseau', () async {
      final entree = await publier();
      final appels = <int>[];
      final octets = File('$publie/${entree.filePath}').readAsBytesSync();

      await expectLater(
        service(appels: appels, tronquerA: octets.length - 50).synchroniser(
          'gr-monts-dore',
          'https://double/${entree.filePath}',
          niveau: NiveauDeTelechargement.realiser, revisionCible: entree.dataVersion,
          empreinteAttendue: entree.hash,
        ),
        throwsA(isA<EmpreinteInvalide>()),
      );
      expect(appels, hasLength(1),
          reason: 'trois tentatives donneraient trois fois le meme fichier et '
              'masqueraient la cause derriere un message de reseau');
    });

    test('AUCUNE EMPREINTE ANNONCEE = REFUS, PAS « SANS VERIFICATION ». Le '
        'controle est a fermeture par defaut', () async {
      final entree = await publier();

      for (final annoncee in <String?>[null, '', 'h', 'sha256-pas-une-empreinte']) {
        await expectLater(
          service().synchroniser(
            'gr-monts-dore',
            'https://double/${entree.filePath}',
            niveau: NiveauDeTelechargement.realiser, revisionCible: entree.dataVersion,
            empreinteAttendue: annoncee,
          ),
          throwsA(isA<EmpreinteInvalide>()),
          reason: 'empreinte annoncee « $annoncee » : un editeur qui ecrit '
              'n importe quoi dans `hash` desactiverait sinon le controle sans '
              'que personne ne s en apercoive',
        );
        expect(await TrailStagesDao(db).getByItineraryId('montsdore-i1'),
            isEmpty);
      }
    });

    test('UNE EMPREINTE PREFIXEE `sha256-` EST ACCEPTEE — on ne refuse pas un '
        'depot pour une question de presentation', () async {
      final entree = await publier();
      final bilan = await service().synchroniser(
        'gr-monts-dore',
        'https://double/${entree.filePath}',
        niveau: NiveauDeTelechargement.realiser, revisionCible: entree.dataVersion,
        empreinteAttendue: 'SHA256-${entree.hash.toUpperCase()}',
      );
      expect(bilan.ecrits, 19);
    });
  });

  // =========================================================================
  // 3. LA REPUBLICATION, DE BOUT EN BOUT
  // =========================================================================
  group('607 — republier ne fait redescendre que le modifie', () {
    test('UNE ALTITUDE CORRIGEE DANS LA SOURCE : L OUTIL PUBLIE, ET LE '
        'TELEPHONE N ECRIT QU UNE ETAPE', () async {
      final v1 = await publier();
      await service().synchroniser(
        'gr-monts-dore',
        'https://double/${v1.filePath}',
        niveau: NiveauDeTelechargement.realiser, revisionCible: v1.dataVersion,
        empreinteAttendue: v1.hash,
      );

      modifierLaSource((c) => (c['stages'] as List)[0]['elevation_gain'] = 915);
      final v2 = await publier(jour: 2);
      expect(v2.dataVersion, instantAuJour(2));

      final bilan = await service().synchroniser(
        'gr-monts-dore',
        'https://double/${v2.filePath}',
        niveau: NiveauDeTelechargement.realiser, revisionCible: v2.dataVersion,
        empreinteAttendue: v2.hash,
      );

      expect(bilan.ecrits, 1,
          reason: 'C EST LA PREUVE DE BOUT EN BOUT. Si l outil reincrementait '
              'tout, ce chiffre vaudrait 19 et chaque telephone retelechargerait '
              'le sentier entier pour une altitude corrigee.');
      expect(bilan.famillesTouchees, [MorceauxDeSentier.etapes]);
      expect(
        (await TrailStagesDao(db).getByItineraryId('montsdore-i1'))
            .firstWhere((e) => e.id == 'montsdore-s1')
            .elevationGain,
        915,
      );
      expect((await TrailGpxPointsDao(db).getAll()).map((p) => p.rev),
          everyElement(instantAuJour(1)),
          reason: 'la trace est le gros du volume, et elle n a pas bouge');
    });

    test('UN POI RETIRE DE LA SOURCE DISPARAIT DU TELEPHONE — le marqueur '
        'fabrique par l outil fait son travail', () async {
      final v1 = await publier();
      await service().synchroniser(
        'gr-monts-dore',
        'https://double/${v1.filePath}',
        niveau: NiveauDeTelechargement.realiser, revisionCible: v1.dataVersion,
        empreinteAttendue: v1.hash,
      );
      expect(await TrailPoisDao(db).getByStageId('montsdore-s1'), hasLength(2));

      modifierLaSource((c) =>
          (c['pois'] as List).removeWhere((p) => p['id'] == 'montsdore-p1'));
      final v2 = await publier(jour: 2);

      final bilan = await service().synchroniser(
        'gr-monts-dore',
        'https://double/${v2.filePath}',
        niveau: NiveauDeTelechargement.realiser, revisionCible: v2.dataVersion,
        empreinteAttendue: v2.hash,
      );

      expect(bilan.supprimes, 1);
      expect(
        (await TrailPoisDao(db).getByStageId('montsdore-s1')).map((p) => p.id),
        ['montsdore-p2'],
      );
    });
  });

  // =========================================================================
  // 4. LA COPIE COMPLETE — #X5, LA CONTREPARTIE DE LA RETENTION
  // =========================================================================
  group('607 — un telephone trop en retard repart de zero', () {
    test('AU-DELA DE LA FENETRE DE RETENTION, LA MISE A JOUR PAR MORCEAUX EST '
        'INSUFFISANTE : le POI dont le marqueur a ete purge disparait QUAND '
        'MEME, parce que le sentier est recopie en entier', () async {
      // Revision 1 : le telephone copie tout.
      final v1 = await publier();
      await service().synchroniser(
        'gr-monts-dore',
        'https://double/${v1.filePath}',
        niveau: NiveauDeTelechargement.realiser, revisionCible: v1.dataVersion,
        empreinteAttendue: v1.hash,
      );
      expect(await TrailPoisDao(db).getByStageId('montsdore-s1'), hasLength(2));

      // Jour 2 : un POI disparait cote serveur. Le telephone ne le sait pas.
      modifierLaSource((c) =>
          (c['pois'] as List).removeWhere((p) => p['id'] == 'montsdore-p1'));
      await publier(jour: 2);

      // Puis le serveur vit sa vie pendant plus de trois mois, et le marqueur du
      // jour 2 sort de la fenetre de retention (90 jours depuis la tache 610 —
      // meme regle, meme demonstration, unite de temps au lieu d un compte).
      TrailManifestEntry derniere = v1;
      for (final jour in const [17, 32, 47, 62, 77, 92, 107]) {
        modifierLaSource(
            (c) => (c['stages'] as List)[0]['elevation_gain'] = 800 + jour);
        derniere = await publier(jour: jour);
      }
      expect(derniere.dataVersion, instantAuJour(107));

      final publication = jsonDecode(
        File('$publie/${derniere.filePath}').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(
        (publication['pois'] as List)
            .cast<Map<String, dynamic>>()
            .where((p) => p[RevisionDeDonnee.champSupprime] == true),
        isEmpty,
        reason: 'le marqueur du jour 2 a ete PURGE : le telephone, reste au '
            'jour 1, ne peut plus apprendre cette suppression par morceaux',
      );
      expect(
        RevisionDeDonnee.exigeUneCopieComplete(
          revisionLocale: instantAuJour(1),
          revisionCible: instantAuJour(107),
        ),
        isTrue,
      );

      final bilan = await service().synchroniser(
        'gr-monts-dore',
        'https://double/${derniere.filePath}',
        niveau: NiveauDeTelechargement.realiser, revisionCible: derniere.dataVersion,
        empreinteAttendue: derniere.hash,
      );

      expect(
        (await TrailPoisDao(db).getByStageId('montsdore-s1')).map((p) => p.id),
        ['montsdore-p2'],
        reason: 'SANS LA COPIE COMPLETE, ce POI serait reste A VIE sur le '
            'telephone : sa suppression n a jamais ete transmise et son '
            'marqueur n existe plus. Sur un sentier de montagne, un point d eau '
            'tari qui reste affiche est un risque, pas un defaut de confort.',
      );
      expect(bilan.ecrits, 18,
          reason: 'tout le sentier est repose (19 enregistrements moins le POI '
              'supprime), et c est le prix assume du rattrapage');
      expect(await manifestes.getByTrailId('gr-monts-dore'), isNotNull);
      expect((await manifestes.getByTrailId('gr-monts-dore'))!.localVersion,
          instantAuJour(107));
    });

    test('LA COPIE COMPLETE N EFFACE QUE LE SENTIER CONCERNE — les autres '
        'sentiers deja copies restent entiers', () async {
      // Un autre sentier deja en base, avec ses donnees.
      await TrailMetaDao(db).insertOrReplace(TrailMetaCompanion(
        id: const Value('gr-autre'),
        code: const Value('AUTRE'),
        dataVersion: Value(instantAuJour(1)),
      ));
      await TrailItinerariesDao(db).insertOrReplace(
        const TrailItinerariesCompanion(
          id: Value('autre-i1'),
          trailId: Value('gr-autre'),
          code: Value('AUTRE-NS'),
          nameFr: Value('Autre'),
          nameEn: Value('Other'),
          nameDe: Value('Andere'),
          nameIt: Value('Altro'),
          nameEs: Value('Otro'),
          distanceKm: Value(10),
          elevationGain: Value(100),
          stageCount: Value(1),
        ),
      );

      final v1 = await publier();
      final service1 = service();
      await service1.synchroniser(
        'gr-monts-dore',
        'https://double/${v1.filePath}',
        niveau: NiveauDeTelechargement.realiser, revisionCible: v1.dataVersion,
        empreinteAttendue: v1.hash,
      );

      TrailManifestEntry derniere = v1;
      for (final jour in const [17, 32, 47, 62, 77, 92, 107]) {
        modifierLaSource(
            (c) => (c['stages'] as List)[0]['elevation_gain'] = 800 + jour);
        derniere = await publier(jour: jour);
      }

      await service().synchroniser(
        'gr-monts-dore',
        'https://double/${derniere.filePath}',
        niveau: NiveauDeTelechargement.realiser, revisionCible: derniere.dataVersion,
        empreinteAttendue: derniere.hash,
      );

      expect(await TrailMetaDao(db).getById('gr-autre'), isNotNull,
          reason: 'un DELETE non borne aurait efface les autres sentiers deja '
              'copies sur le telephone — la portee de l effacement est le '
              'sentier, pas la base');
      expect(await TrailItinerariesDao(db).getByTrailId('gr-autre'),
          hasLength(1));
    });
  });
}

class _FauxReseau extends ConnectivityMonitor {
  _FauxReseau(this._statut);
  final ConnectivityStatus _statut;
  @override
  Future<ConnectivityStatus> checkStatus() async => _statut;
  @override
  Stream<ConnectivityStatus> get onStatusChange => Stream.value(_statut);
}

List<String> _fichiersDe(String racine) {
  final dossier = Directory(racine);
  if (!dossier.existsSync()) return const [];
  return dossier
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .toList();
}

/// Laisse la lecture asynchrone du catalogue se terminer.
Future<void> _laisserLaLectureSeFaire(ProviderContainer c) async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
