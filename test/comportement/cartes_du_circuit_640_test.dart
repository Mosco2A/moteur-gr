import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/database.dart' as drift show TrailManifest;
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/map/mbtiles_manager.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/map_downloader.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/features/map/presentation/offline_maps_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/grise_en_demo.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// TACHE 640 — LE TELECHARGEMENT DES CARTES : BUG 9 (IL PLANTE) ET BUG 10
/// (IL PROPOSE DES DEMI-CARTES).
///
/// LES DEUX RETOURS DE CHRISTOPHE DU 30/09, SUR LE BUILD 0.1.3 (7).
///   * DEM-260930-1016, verbatim : « en demo comme en vrai telecharger les
///     cartes plante ».
///   * DEM-260930-1017, verbatim : « Le telechargement doit telecharger les
///     cartes pour le circuit propose. On ne propose pas de demi-Mare a Mare,
///     pas besoin de telecharger de demi-cartes ».
///
/// CE QUE LA MESURE A TROUVE, AVANT D ECRIRE UNE LIGNE.
///
/// 1. LE GESTE QUE CHRISTOPHE A FAIT N ETAIT PAS BRANCHE SUR LE TELECHARGEMENT
///    DES CARTES. La carte du HUB « Cartes hors ligne / Telecharger les cartes
///    du sentier » ouvrait `/trail/:id/packs`, c est-a-dire `PackStoreScreen` —
///    une FACADE que le lot 622 avait deja nommee comme telle dans son bilan :
///    sa source de fichiers etait `UnavailablePackFileSource`, qui LEVE a chaque
///    appel (« source de pack non connectee, pre-Phase 4 »), et son stockage
///    ecrivait sous `documents/packs/<packId>/` alors que la carte lit
///    `documents/mbtiles/<trailId>.mbtiles`. Meme branchee a un serveur, elle
///    aurait rempli un dossier que rien ne regarde. Le geste ne pouvait donc
///    QUE echouer, dans les deux modes.
///
/// 2. LE VRAI TELECHARGEUR N AVAIT AUCUN ECRAN. `MapDownloader` (lot 622)
///    descend UNE carte pour TOUT le circuit, avec poids annonce, progression,
///    reprise et annulation — et `controleurDesCartesProvider` n avait ZERO
///    appelant d interface. Il n etait atteint que par la copie d un sentier
///    depuis le catalogue.
///
/// 3. ET LA OU IL AURAIT FALLU LE BRANCHER, LA CHAINE POUVAIT LEVER. Trois
///    maillons ne rendaient pas un echec, ils le PROPAGEAIENT :
///    `MBTilesManager.descendre` (dossier de documents injoignable, suppression
///    d un partiel impossible, lecture d empreinte en echec),
///    `MapDownloader.examiner`/`descendre` (base, droits, reseau) et
///    `MapsController.start`, dont le `try` n avait pas de `catch`.
///    Depuis un bouton — donc depuis un futur que personne n attend — cela
///    donne une erreur asynchrone non traitee, que `PlatformDispatcher.onError`
///    remonte a Crashlytique comme un plantage FATAL. C est la forme exacte du
///    « ca plante » de Christophe, et c est ce que ce fichier interdit.
///
/// CE FICHIER COMPTE, IL NE DECRIT PAS. Chaque test ci-dessous echoue sur le
/// code du build 7.
void main() {
  late Directory tempDir;
  late AppDatabase db;
  late TrailManifestsDao manifestes;
  late List<String> requetes;
  late Uint8List tuiles;
  late String empreinteDesTuiles;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('cartes_640_');
    PathProviderPlatform.instance = _FauxDossiers(tempDir);
    db = AppDatabase(NativeDatabase.memory());
    manifestes = TrailManifestsDao(db);
    requetes = [];
    tuiles = Uint8List.fromList(
      List<int>.generate(4096, (i) => (i * 7 + 5) % 256),
    );
    empreinteDesTuiles = sha256.convert(tuiles).toString();
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  http.Client serveurDeTuiles() => MockClient((requete) async {
    requetes.add(requete.url.toString());
    return http.Response.bytes(tuiles, HttpStatus.ok);
  });

  Future<void> publier({
    String trailId = 'mare-a-mare-centre',
    String? tilesPath = 'mare_a_mare/tuiles_v1.mbtiles',
    int? tilesSize = 4096,
    String? tilesHash,
  }) async {
    final service = ManifestService(
      dao: manifestes,
      connectivityMonitor: _Reseau(TypesDeLien.wifi),
    );
    await service.saveLocalManifest(
      TrailManifestEntry(
        trailId: trailId,
        dataVersion: HorodatageServeur.annonceParLeServeur(1700000000000)!,
        hash: 'e' * 64,
        filePath: 'mare_a_mare/v1.json',
        fileSize: 2048,
        status: 'active',
        lastUpdated: '2026-09-30T00:00:00Z',
        tilesPath: tilesPath,
        tilesSize: tilesSize,
        tilesHash: tilesHash ?? empreinteDesTuiles,
      ),
    );
  }

  MapDownloader descente({
    bool droitDeRealiser = true,
    TypeDeLien lien = TypesDeLien.wifi,
    MBTilesManager? avecCartes,
    TrailManifestsDao? avecDao,
  }) => MapDownloader(
    maps: avecCartes ?? MBTilesManager(httpClient: serveurDeTuiles()),
    dao: avecDao ?? manifestes,
    monetization: _Droits(droitDeRealiser),
    connectivityMonitor: _Reseau(lien),
  );

  ProviderContainer conteneur({
    required MapDownloader service,
    bool enDemo = false,
  }) {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        mapDownloaderProvider.overrideWithValue(service),
        if (enDemo) enDemoProvider.overrideWithValue(true),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  // =======================================================================
  // BUG 9 — LE GESTE NE PLANTE JAMAIS : IL RAMENE UNE CAUSE NOMMEE
  // =======================================================================
  group('640 / bug 9 — telecharger les cartes ne LEVE jamais', () {
    test('un dossier de documents injoignable rend un ECHEC nomme, pas une '
        'exception qui traverse le transport', () async {
      // LE CAS REEL, ET IL EST BANAL SUR ANDROID : le canal de plateforme de
      // `path_provider` ne repond pas (processus recycle, profil restreint, vue
      // native detruite pendant le telechargement). `getMbtilesPath` etait la
      // PREMIERE ligne de `descendre`, hors de tout filet.
      final maps = MBTilesManager(
        httpClient: serveurDeTuiles(),
        dossierDocuments: () async =>
            throw const FileSystemException('dossier de documents injoignable'),
      );

      final resultat = await maps.descendre(
        trailId: 'mare-a-mare-centre',
        url: 'https://exemple.test/tuiles.mbtiles',
        octetsAttendus: 4096,
        empreinteAttendue: empreinteDesTuiles,
      );

      expect(resultat.reussie, isFalse);
      expect(resultat.echec, MapFailure.stockageIndisponible);
      expect(
        requetes,
        isEmpty,
        reason:
            'aucun octet ne doit voyager quand on ne sait pas ou '
            'l ecrire',
      );
    });

    test('une base injoignable a l examen rend un REFUS nomme, pas une '
        'exception', () async {
      final service = descente(avecDao: _DaoQuiLeve());

      final decision = await service.examiner(
        'mare-a-mare-centre',
        niveau: NiveauDeTelechargement.realiser,
      );

      expect(decision.autorisee, isFalse);
      expect(decision.refus, RefusDeDescente.stockageIndisponible);
    });

    test('LE COEUR DU BUG 9 : le controleur du bouton ne laisse RIEN sortir — '
        'un plantage du transport devient un bilan, et l etat ne reste pas '
        '« en cours »', () async {
      await publier();
      final service = descente(avecDao: _DaoQuiLeve());
      final c = conteneur(service: service);
      final controleur = c.read(
        controleurDesCartesProvider('mare-a-mare-centre').notifier,
      );

      // AVANT CE LOT : `demarrer` relancait l exception (son `try` n avait pas
      // de `catch`). Depuis un bouton, personne ne l attend : elle finissait en
      // erreur asynchrone non traitee, donc en plantage FATAL cote Crashlytique.
      final bilan = await controleur.start(
        niveau: NiveauDeTelechargement.realiser,
      );

      expect(bilan.refusee, isTrue);
      expect(bilan.refus, RefusDeDescente.stockageIndisponible);
      final etat = c.read(controleurDesCartesProvider('mare-a-mare-centre'));
      expect(
        etat.enCours,
        isFalse,
        reason: 'une barre qui n avance plus est pire qu un message',
      );
    });

    test('ET MEME SI LE SERVICE LUI-MEME LEVE : `demarrer` rend un bilan, il ne '
        'relance PAS — c est le `catch` qui manquait a son `try`', () async {
      // LA MESURE EXACTE DU BUG 9. `MapsController.start` avait un
      // `try { ... } finally { ... }` SANS `catch`. Tout ce qui levait sous lui
      // remontait donc a l appelant ; le seul appelant de production etait la
      // copie d un sentier, qui rattrape — mais un BOUTON n attend pas son
      // futur, et l exception devenait une erreur asynchrone non traitee, que
      // `PlatformDispatcher.onError` remonte comme plantage FATAL.
      final c = conteneur(service: _ServiceQuiLeve());
      final controleur = c.read(
        controleurDesCartesProvider('mare-a-mare-centre').notifier,
      );

      final bilan = await controleur.start(
        niveau: NiveauDeTelechargement.realiser,
      );

      expect(bilan.refus, RefusDeDescente.stockageIndisponible);
      expect(
        c.read(controleurDesCartesProvider('mare-a-mare-centre')).enCours,
        isFalse,
      );
    });
  });

  // =======================================================================
  // BUG 10 — UN SEUL GESTE, TOUT LE CIRCUIT
  // =======================================================================
  group('640 / bug 10 — un sentier = UN telechargement, tout le circuit', () {
    test('UN telechargement couvre TOUTES les etapes : il pose le seul fichier '
        'que la carte lit, pour le sentier entier', () async {
      await publier();
      final maps = MBTilesManager(httpClient: serveurDeTuiles());
      final service = descente(avecCartes: maps);
      final c = conteneur(service: service);

      final bilan = await c
          .read(controleurDesCartesProvider('mare-a-mare-centre').notifier)
          .start(niveau: NiveauDeTelechargement.realiser);

      expect(bilan.posee, isTrue);
      // UN SEUL TRANSPORT, UN SEUL FICHIER, ET C EST CELUI QUE LA CARTE OUVRE.
      expect(
        requetes,
        hasLength(1),
        reason: 'pas quatre packs, pas de demi-carte : un geste, un fichier',
      );
      expect(await maps.hasMbtiles('mare-a-mare-centre'), isTrue);
      final pose = File(await maps.getMbtilesPath('mare-a-mare-centre'));
      expect(await pose.length(), 4096);
      // Et il n y a QUE lui : aucun fichier par morceau du circuit.
      final dossier = Directory('${tempDir.path}/mbtiles');
      expect(
        dossier.listSync().whereType<File>().map(
          (f) => f.uri.pathSegments.last,
        ),
        ['mare-a-mare-centre.mbtiles'],
      );
    });

    test('LE DECOUPAGE EN PACKS PARTIELS A DISPARU DU CODE : plus de catalogue '
        'de packs, plus de Nord / Sud / Complet', () {
      // Le lot 634 avait revele que ces quatre noms etaient des noms de SENTIER
      // ecrits en dur dans les cinq fichiers de langue. Christophe a tranche le
      // 30/09 : on ne vend pas un demi-circuit, on ne telecharge pas une
      // demi-carte. Le catalogue de packs ne servait qu a ca ; il part.
      expect(
        Directory('lib/features/packs').existsSync(),
        isFalse,
        reason:
            'la facade de telechargement (PackStoreScreen, PackCatalog, '
            'PackDownloadService, FilePackStorage) est retiree : elle ne '
            'descendait rien et ecrivait dans un dossier que la carte ne lit '
            'pas',
      );

      final coupables = <String>[];
      for (final fichier
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = fichier.readAsStringSync();
        if (source.contains('PackCatalog') ||
            source.contains('PackStoreScreen') ||
            source.contains('PackDownloadService')) {
          coupables.add(fichier.path.replaceAll(r'\', '/'));
        }
      }
      expect(
        coupables,
        isEmpty,
        reason:
            'references restantes vers la facade : '
            '${coupables.join(", ")}',
      );
    });

    test('les quatre noms de pack ont quitte les CINQ langues', () {
      for (final langue in ['fr', 'en', 'de', 'it', 'es']) {
        final source = File('assets/i18n/$langue.i18n.json').readAsStringSync();
        expect(
          source.contains('"packs"'),
          isFalse,
          reason: '$langue porte encore la rubrique des packs partiels',
        );
      }
    });

    test(
      'les libelles des cartes du circuit existent dans les CINQ langues',
      () {
        for (final langue in ['fr', 'en', 'de', 'it', 'es']) {
          final source = File(
            'assets/i18n/$langue.i18n.json',
          ).readAsStringSync();
          expect(
            source.contains('"cartesHorsLigne"'),
            isTrue,
            reason: '$langue n a pas les libelles des cartes hors ligne',
          );
        }
      },
    );
  });

  // =======================================================================
  // L ECRAN : UN BOUTON, LE POIDS, LA PROGRESSION, LA REPRISE, ET AUCUN
  // PLANTAGE
  // =======================================================================
  group('640 — l ecran « Cartes hors ligne »', () {
    /// POURQUOI CE GROUPE PILOTE LE SERVICE AU LIEU DE TELECHARGER POUR DE VRAI.
    ///
    /// LE TEMPS FEINT D UN TEST DE WIDGETS NE FAIT JAMAIS REVENIR UNE
    /// ENTREE-SORTIE REELLE : le depot l a deja mesure et ecrit
    /// (`gestes_579_test.dart`, tache 579). Un `Directory.exists` ou une lecture
    /// Drift lancee depuis un `initState` ne se termine pas sous l horloge du
    /// test, et l ecran reste bloque sur son rond d attente — c est exactement ce
    /// que ces tests ont fait avant qu on le sache.
    ///
    /// Le TRANSPORT REEL est donc couvert sans widgets, plus haut dans ce fichier
    /// (fichier pose, une seule requete, reprise, echecs nommes). Ici on ne
    /// mesure que L ECRAN : ce qu il montre pour chaque reponse du service, et le
    /// fait qu un appui ne leve JAMAIS.
    Future<void> laisserFaire(WidgetTester tester, {int tours = 8}) async {
      for (var i = 0; i < tours; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    Future<void> monter(
      WidgetTester tester, {
      required MapDownloader service,
      bool enDemo = false,
      String trailId = 'mare-a-mare-centre',
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            mapDownloaderProvider.overrideWithValue(service),
            if (enDemo) enDemoProvider.overrideWithValue(true),
          ],
          child: TranslationProvider(
            child: MaterialApp(home: OfflineMapsScreen(trailId: trailId)),
          ),
        ),
      );
      await laisserFaire(tester);
    }

    /// 260 Mo a prendre, rien de deja la : l etat de depart d un randonneur.
    DecisionDeDescente aPrendre({int total = 260000000, int dejaLa = 0}) =>
        DecisionDeDescente(
          trailId: 'mare-a-mare-centre',
          octetsTotal: total,
          octetsDejaLa: dejaLa,
          lien: TypesDeLien.wifi,
        );

    testWidgets('UN SEUL bouton de telechargement, et il annonce le poids de '
        'tout le circuit', (tester) async {
      await monter(tester, service: _DescenteReglee(decision: aPrendre()));

      expect(
        find.byKey(const ValueKey('cartes-telecharger')),
        findsOneWidget,
        reason: 'un geste, pas quatre',
      );
      // Le poids annonce est celui du circuit ENTIER : un seul chiffre.
      expect(find.byKey(const ValueKey('cartes-poids')), findsOneWidget);
      expect(
        find.textContaining('260.0'),
        findsWidgets,
        reason: 'le poids du circuit entier, annonce avant tout transfert',
      );
      // Et AUCUN choix de morceau.
      expect(find.textContaining('Nord'), findsNothing);
      expect(find.textContaining('Sud'), findsNothing);
    });

    testWidgets('BUG 9 — l appui sur le bouton ne plante PAS quand la chaine '
        'LEVE : il affiche la cause', (tester) async {
      // LE CAS DU BUG 9, AU PLUS PRES : le service ne rend pas un echec, il
      // LEVE. Avant ce lot, cette exception traversait le controleur (son `try`
      // n avait pas de `catch`) et ressortait dans le futur d un bouton, que
      // personne n attend — donc en plantage FATAL.
      await monter(
        tester,
        service: _DescenteReglee(decision: aPrendre(), transportQuiLeve: true),
      );

      await tester.tap(find.byKey(const ValueKey('cartes-telecharger')));
      await laisserFaire(tester);

      expect(
        tester.takeException(),
        isNull,
        reason: 'c est exactement le plantage du bug 9',
      );
      expect(
        find.byKey(const ValueKey('cartes-cause')),
        findsOneWidget,
        reason: 'un refus muet est un geste mort',
      );
    });

    testWidgets('le telechargement aboutit et l ecran le DIT', (tester) async {
      final service = _DescenteReglee(
        decision: aPrendre(),
        map: const MapResult(
          trailId: 'mare-a-mare-centre',
          octetsSurLeTelephone: 260000000,
          octetsTransferes: 260000000,
          octetsReprisDuDisque: 0,
        ),
      );
      await monter(tester, service: service);

      await tester.tap(find.byKey(const ValueKey('cartes-telecharger')));
      await laisserFaire(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('cartes-pretes')), findsOneWidget);
      // ET LA SUPPRESSION EXISTE : 260 Mo sans moyen de les rendre n est pas une
      // fonctionnalite complete.
      expect(find.byKey(const ValueKey('cartes-supprimer')), findsOneWidget);
    });

    testWidgets('UNE DESCENTE INTERROMPUE SE REPREND, ET L ECRAN ANNONCE CE '
        'QUI RESTE', (tester) async {
      // 180 des 260 Mo sont deja la.
      await monter(
        tester,
        service: _DescenteReglee(decision: aPrendre(dejaLa: 180000000)),
      );

      expect(
        find.byKey(const ValueKey('cartes-reprise')),
        findsOneWidget,
        reason: 'annoncer 260 Mo sur une reprise a 70 % serait faux',
      );
      // CE QUI VA REELLEMENT VOYAGER, PAS LE POIDS TOTAL.
      expect(
        find.textContaining('80.0'),
        findsWidgets,
        reason: 'ce qui va REELLEMENT voyager, pas le poids total',
      );
      expect(
        find.textContaining('180.0'),
        findsWidgets,
        reason: 'ce qui est deja la se dit AVANT, pas apres',
      );
    });

    testWidgets('UNE CAUSE NOMMEE POUR CHAQUE REFUS, jamais un bouton muet', (
      tester,
    ) async {
      await monter(
        tester,
        service: _DescenteReglee(
          decision: const DecisionDeDescente(
            trailId: 'mare-a-mare-centre',
            octetsTotal: 0,
            octetsDejaLa: 0,
            lien: TypesDeLien.wifi,
            refus: RefusDeDescente.aucuneCartePubliee,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('cartes-cause')), findsOneWidget);
      // ET PAS DE BOUTON QUI NE SERVIRAIT A RIEN : reessayer ne publiera pas une
      // carte qui n existe pas.
      expect(find.byKey(const ValueKey('cartes-telecharger')), findsNothing);
    });

    testWidgets('EN DEMO le bouton est GRISE et dit pourquoi — jamais un '
        'bouton actif qui ne fait rien (regle du bug 14)', (tester) async {
      await monter(
        tester,
        service: _DescenteReglee(decision: aPrendre()),
        enDemo: true,
      );

      expect(find.byKey(const ValueKey('cartes-demo')), findsOneWidget);
      // GRISE, PAS CACHE : le bouton reste visible — il dit ce que l appli sait
      // faire — mais il ne recoit aucun geste. Un bouton actif qui ne fait rien
      // est le defaut exact que Christophe a signale sur le sac (bug 14).
      //
      // INTEGRATION 647 — LE GRISAGE PASSE PAR [GriseEnDemo], ET LA MESURE SUIT.
      // Le lot 640 a ete ecrit AVANT que le lot 638 n arrive : il grisait a la
      // main (`onPressed: null`) et ce test lisait donc `onPressed`. Un bouton
      // Material desactive est MUET — il ne dit pas POURQUOI, et la regle du bug
      // 14 exige les deux. [GriseEnDemo] garde le geste cable mais le rend inerte
      // ET repond quand on insiste. Ce que ce test verifie est donc strictement
      // plus exigeant qu avant, pas moins.
      final bouton = find.byKey(const ValueKey('cartes-telecharger'));
      expect(bouton, findsOneWidget, reason: 'grise, jamais cache');
      expect(
        find.ancestor(of: bouton, matching: find.byType(GriseEnDemo)),
        findsOneWidget,
        reason: 'le bouton est enveloppe par le grisage commun a tout le depot',
      );
      expect(
        find.ancestor(of: bouton, matching: find.byType(IgnorePointer)),
        findsWidgets,
        reason: 'grise = inerte : le bouton ne recoit plus aucun geste',
      );

      // ... ET IL DIT POURQUOI. C est la moitie de la regle que `onPressed: null`
      // ne pouvait pas tenir.
      await tester.tap(bouton, warnIfMissed: false);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('demo-indisponible')),
        findsOneWidget,
        reason: 'un appui sur une fonction grisee doit repondre, pas se taire',
      );
    });
  });
}

/// LE SERVICE DE DESCENTE, PILOTE — et il sait aussi LEVER.
///
/// [transportQuiLeve] est la seule facon de rejouer le bug 9 depuis un ecran : le
/// service ne rend alors pas un echec, il jette. C est ce que faisait le vrai
/// service quand `path_provider` se taisait ou que la base se fermait.
class _DescenteReglee extends Fake implements MapDownloader {
  _DescenteReglee({
    required this.decision,
    this.map,
    this.transportQuiLeve = false,
  });

  final DecisionDeDescente decision;
  final MapResult? map;
  final bool transportQuiLeve;

  @override
  Future<DecisionDeDescente> examiner(
    String trailId, {
    required NiveauDeTelechargement niveau,
    bool confirmeHorsWifi = false,
  }) async {
    if (transportQuiLeve && _dejaDemande) {
      throw StateError('base fermee');
    }
    if (_dejaDemande && map != null) {
      return DecisionDeDescente(
        trailId: trailId,
        octetsTotal: decision.octetsTotal,
        octetsDejaLa: decision.octetsTotal,
        lien: decision.lien,
        refus: RefusDeDescente.dejaLa,
      );
    }
    return decision;
  }

  bool _dejaDemande = false;

  @override
  Future<BilanDeDescente> descendre(
    String trailId, {
    required NiveauDeTelechargement niveau,
    bool confirmeHorsWifi = false,
    void Function(MapProgress)? progression,
    AnnulationDeDescente? annulation,
  }) async {
    _dejaDemande = true;
    if (transportQuiLeve) throw StateError('base fermee');
    return BilanDeDescente(decision: decision, map: map);
  }

  @override
  Future<bool> delete(String trailId) async => true;
}

/// Dossier de documents pilote : les cartes vivent dans un temporaire.
class _FauxDossiers extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FauxDossiers(this.dossier);
  final Directory dossier;

  @override
  Future<String?> getApplicationDocumentsPath() async => dossier.path;
}

class _Reseau extends ConnectivityMonitor {
  _Reseau(this.lien);
  final TypeDeLien lien;

  @override
  Future<TypeDeLien> typeDeLien() async => lien;

  @override
  Future<ConnectivityStatus> checkStatus() async => lien == TypesDeLien.aucun
      ? ConnectivityStatusValues.offline
      : ConnectivityStatusValues.online;
}

class _Droits extends Fake implements MonetizationService {
  _Droits(this.autorise);
  final bool autorise;

  @override
  Future<bool> canRealizeTrail(String trailId) async => autorise;
}

/// LA BASE QUI NE REPOND PLUS. C est le cas d un telephone dont la base est
/// verrouillee ou fermee pendant que le randonneur appuie — et c est ce qui
/// traversait toute la chaine jusqu au plantage.
/// LE SERVICE DE DESCENTE QUI LEVE — le pire cas, et celui qui plantait.
///
/// Il ne rend ni refus ni echec : il jette, comme le faisait la vraie chaine
/// quand `path_provider` se taisait ou que la base se fermait entre l examen et
/// le transport. Le controleur du bouton doit l absorber.
class _ServiceQuiLeve extends Fake implements MapDownloader {
  @override
  Future<BilanDeDescente> descendre(
    String trailId, {
    required NiveauDeTelechargement niveau,
    bool confirmeHorsWifi = false,
    void Function(MapProgress)? progression,
    AnnulationDeDescente? annulation,
  }) async => throw const FileSystemException('espace de stockage injoignable');
}

class _DaoQuiLeve extends Fake implements TrailManifestsDao {
  @override
  Future<drift.TrailManifest?> getByTrailId(String trailId) async =>
      throw StateError('base fermee');
}
