import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/store_subscription_links.dart';
import 'package:moteur_gr/core/config/trail_data_source.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
// `database.dart` expose AUSSI un `TrailManifest` (la ligne Drift). Le modele
// distant est celui de `models/`, comme dans catalog_provider.dart.
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';

/// TACHE 604 — MUR-003 : LE CATALOGUE, SON ADRESSE, ET SON SILENCE.
///
/// Trois choses sont verrouillees ici, et chacune correspond a un defaut
/// MESURE dans le depot avant ce lot :
///
///  1. L ADRESSE ETAIT MORTE, EN DEUX COPIES. `catalog_provider.dart` et
///     `update_downloader.dart` portaient chacun, en dur, une adresse vers
///     `storage.googleapis.com/moteur-gr` — un espace de stockage qui n a
///     jamais existe (404 verifie sur la racine comme sur l objet).
///
///  2. L ECHEC ETAIT AVALE. Quand le manifeste distant echouait, le code
///     retombait sur la base locale et rendait `isOffline: false` sans un mot.
///     A l installation la base locale est VIDE : l ecran recevait donc une
///     liste vide, indistinguable d un catalogue legitimement vide. Personne,
///     ni l utilisateur ni un journal, ne pouvait faire la difference entre
///     « il n y a rien » et « je n ai pas pu regarder ».
///
///  3. L IDENTIFIANT DE PAQUET DIVERGEAIT ENTRE LES DEUX PLATEFORMES, et il
///     est IRREVERSIBLE apres publication au store.
///
/// Le hors-ligne reste NON NEGOCIABLE : un randonneur sans reseau garde son
/// catalogue et ses sentiers deja telecharges.

/// Reseau pilote a la main.
class FakeConnectivityMonitor extends ConnectivityMonitor {
  FakeConnectivityMonitor(this._status);

  final ConnectivityStatus _status;

  @override
  Future<ConnectivityStatus> checkStatus() async => _status;

  @override
  Stream<ConnectivityStatus> get onStatusChange => Stream.value(_status);
}

/// Manifeste distant pilote a la main : `null` = injoignable.
class FakeManifestService extends ManifestService {
  FakeManifestService({
    required super.dao,
    required super.connectivityMonitor,
    required this.reponse,
  });

  final TrailManifest? reponse;
  int appels = 0;

  @override
  Future<TrailManifest?> fetchManifest(String url) async {
    appels++;
    derniereUrl = url;
    return reponse;
  }

  String? derniereUrl;
}

const _entreeDistante = TrailManifestEntry(
  trailId: 'mare-a-mare-centre',
  dataVersion: 4,
  hash: 'hash-v4',
  filePath: 'mare_a_mare_centre/v4.json',
  fileSize: 812_345,
  status: 'active',
  lastUpdated: '2026-09-27T12:00:00Z',
);

void main() {
  // --------------------------------------------------------------------
  // 1. L ADRESSE — UNE SEULE, ET VIVANTE
  // --------------------------------------------------------------------
  group('604 — l adresse des donnees ne pointe plus sur un espace mort', () {
    test('le manifeste est demande a l espace de stockage de StepWays', () {
      final url = CatalogNotifier.defaultManifestUrl;
      expect(url, contains('stepways-app'),
          reason: 'le catalogue doit interroger le projet Firebase de StepWays');
      expect(url, isNot(contains('moteur-gr')),
          reason: 'storage.googleapis.com/moteur-gr n a JAMAIS existe : 404');
      expect(url, contains('manifest.json'));
    });

    test('l adresse morte a disparu du CODE de lib/ — les deux copies', () {
      // Les commentaires de ce lot CITENT volontairement l ancienne valeur pour
      // expliquer ce qui etait casse : on ne balaye donc que le code executable,
      // sinon la documentation du defaut declencherait le test qui le garde.
      final fautifs = <String>[];
      for (final f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final code = f
            .readAsLinesSync()
            .where((l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        if (code.contains('storage.googleapis.com/moteur-gr')) {
          fautifs.add(f.path);
        }
      }
      expect(fautifs, isEmpty,
          reason: 'adresse morte encore en dur dans : ${fautifs.join(", ")}');
    });

    test('une SEULE source de verite, et elle est surchargeable au build', () {
      expect(TrailDataSource.variableDeBuild, 'STEPWAYS_TRAIL_DATA_BUCKET',
          reason: 'le nom doit etre publie pour que Chris ou la CI le passe '
              'sans avoir a le deviner');
      expect(TrailDataSource.bucket, isNotEmpty);
      expect(CatalogNotifier.defaultManifestUrl, TrailDataSource.urlManifeste,
          reason: 'le catalogue ne doit PAS reconstruire l adresse lui-meme');
    });

    test('le chemin est encode — un sous-dossier ne casse pas l URL', () {
      final url = TrailDataSource.urlDe('data/mare_a_mare/v4.json');
      expect(url, contains('data%2Fmare_a_mare%2Fv4.json'),
          reason: 'la forme REST Firebase Storage exige un chemin encode ; une '
              'simple concatenation produisait une URL invalide');
      expect(url, endsWith('?alt=media'));
    });

    test('une URL absolue dans le manifeste est respectee telle quelle', () {
      const ailleurs = 'https://miroir.example.org/sentier/v9.json';
      expect(TrailDataSource.urlDonneesSentier(ailleurs), ailleurs,
          reason: 'servir un sentier depuis un autre hebergeur ne doit pas '
              'exiger de reconstruire le moteur');
    });
  });

  // --------------------------------------------------------------------
  // 2. LE SILENCE — CORRIGE, ET LE HORS-LIGNE PRESERVE
  // --------------------------------------------------------------------
  group('604 — un catalogue qui ne peut pas charger le DIT', () {
    late AppDatabase db;
    late TrailManifestsDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = TrailManifestsDao(db);
    });

    tearDown(() async => db.close());

    ProviderContainer conteneur({
      required ConnectivityStatus reseau,
      required TrailManifest? manifeste,
    }) {
      return ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          connectivityMonitorProvider
              .overrideWithValue(FakeConnectivityMonitor(reseau)),
          manifestServiceProvider.overrideWithValue(
            FakeManifestService(
              dao: dao,
              connectivityMonitor: FakeConnectivityMonitor(reseau),
              reponse: manifeste,
            ),
          ),
        ],
      );
    }

    test('LE DEFAUT REPARE : en ligne, manifeste injoignable, base vide — '
        'l ecran doit EXPLIQUER, pas montrer une liste vide muette', () async {
      final c = conteneur(
        reseau: ConnectivityStatusValues.online,
        manifeste: null, // 404 / espace non provisionne / panne
      );
      addTearDown(c.dispose);

      final etat = await c.read(catalogStateProvider.future);

      expect(etat.entries, isEmpty,
          reason: 'a l installation il n y a rien en local : c est normal');
      expect(etat.echec, CatalogEchec.manifesteInjoignable,
          reason: 'C EST LE POINT DU LOT : avant, echec == null et l ecran '
              'recevait une liste vide sans la moindre explication');
      expect(etat.doitExpliquerAuLieuDeRienMontrer, isTrue,
          reason: 'l ecran doit afficher un message et un bouton reessayer');
      expect(etat.isOffline, isFalse,
          reason: 'le reseau est la : ce n est PAS un probleme de connexion, '
              'et confondre les deux rend le diagnostic impossible');
    });

    test('HORS LIGNE NON NEGOCIABLE : les sentiers deja telecharges restent '
        'la, et rien ne se presente comme une panne', () async {
      await dao.insertOrReplace(const TrailManifestsCompanion(
        trailId: Value('mare-a-mare-centre'),
        dataVersion: Value(4),
        hash: Value('hash-v4'),
        filePath: Value('mare_a_mare_centre/v4.json'),
        fileSize: Value(812345),
        status: Value('active'),
        lastUpdated: Value('2026-09-27T12:00:00Z'),
        localVersion: Value(4),
      ));

      final c = conteneur(
        reseau: ConnectivityStatusValues.offline,
        manifeste: null,
      );
      addTearDown(c.dispose);

      final etat = await c.read(catalogStateProvider.future);

      expect(etat.entries.map((e) => e.trailId), ['mare-a-mare-centre'],
          reason: 'un randonneur sans reseau GARDE ses sentiers telecharges');
      expect(etat.entries.single.localStatus,
          TrailLocalStatusValues.downloaded);
      expect(etat.isOffline, isTrue);
      expect(etat.echec, CatalogEchec.horsLigne,
          reason: 'la cause est nommee pour que l ecran puisse dire « liste non '
              'rafraichie » — mais ce n est pas une panne');
      expect(etat.doitExpliquerAuLieuDeRienMontrer, isFalse,
          reason: 'il y a quelque chose a montrer : pas d ecran d erreur');
    });

    test('hors ligne ET rien de telecharge : la cause est dite, l ecran '
        'explique au lieu de rester muet', () async {
      final c = conteneur(
        reseau: ConnectivityStatusValues.offline,
        manifeste: null,
      );
      addTearDown(c.dispose);

      final etat = await c.read(catalogStateProvider.future);
      expect(etat.entries, isEmpty);
      expect(etat.echec, CatalogEchec.horsLigne);
      expect(etat.doitExpliquerAuLieuDeRienMontrer, isTrue);
    });

    test('manifeste lu : AUCUN echec, et le sentier distant apparait',
        () async {
      final c = conteneur(
        reseau: ConnectivityStatusValues.online,
        manifeste: const TrailManifest(
          schemaVersion: 1,
          trails: [_entreeDistante],
        ),
      );
      addTearDown(c.dispose);

      final etat = await c.read(catalogStateProvider.future);

      expect(etat.echec, isNull,
          reason: 'un succes ne doit pas trainer l echec du chargement '
              'precedent');
      expect(etat.doitExpliquerAuLieuDeRienMontrer, isFalse);
      expect(etat.entries.single.trailId, 'mare-a-mare-centre');
      expect(etat.entries.single.localStatus,
          TrailLocalStatusValues.notDownloaded,
          reason: 'jamais telecharge localement');
    });

    test('un echec laisse ce qui est deja telecharge visible — le repli ne '
        'sacrifie rien', () async {
      await dao.insertOrReplace(const TrailManifestsCompanion(
        trailId: Value('mare-a-mare-centre'),
        dataVersion: Value(4),
        hash: Value('hash-v4'),
        filePath: Value('mare_a_mare_centre/v4.json'),
        fileSize: Value(812345),
        status: Value('active'),
        lastUpdated: Value('2026-09-27T12:00:00Z'),
        localVersion: Value(4),
      ));

      final c = conteneur(
        reseau: ConnectivityStatusValues.online,
        manifeste: null,
      );
      addTearDown(c.dispose);

      final etat = await c.read(catalogStateProvider.future);
      expect(etat.entries.single.trailId, 'mare-a-mare-centre');
      expect(etat.echec, CatalogEchec.manifesteInjoignable);
      expect(etat.doitExpliquerAuLieuDeRienMontrer, isFalse,
          reason: 'il reste quelque chose a montrer : un bandeau suffit');
    });

    test('reessayer est POSSIBLE : refresh relance bien la demande', () async {
      final service = FakeManifestService(
        dao: dao,
        connectivityMonitor:
            FakeConnectivityMonitor(ConnectivityStatusValues.online),
        reponse: null,
      );
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        connectivityMonitorProvider.overrideWithValue(
            FakeConnectivityMonitor(ConnectivityStatusValues.online)),
        manifestServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(c.dispose);

      await c.read(catalogStateProvider.future);
      final apresPremier = service.appels;
      await c.read(catalogStateProvider.notifier).refresh();

      expect(service.appels, greaterThan(apresPremier),
          reason: 'sans cela, le bouton « reessayer » mentirait');
    });
  });

  // --------------------------------------------------------------------
  // 3. L IDENTIFIANT DE PAQUET — IRREVERSIBLE APRES PUBLICATION
  // --------------------------------------------------------------------
  group('604 — l identifiant de paquet store, identique sur les deux '
      'plateformes', () {
    const cible = 'com.only1cent.stepways';

    test('Android : namespace ET applicationId valent la cible', () {
      final gradle =
          File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('namespace = "$cible"'));
      expect(gradle, contains('applicationId = "$cible"'));
      expect(gradle, isNot(contains('com.only1cent.moteur_gr')));
    });

    test('Android : le paquet Kotlin a suivi le renommage', () {
      final dossier =
          Directory('android/app/src/main/kotlin/com/only1cent/stepways');
      expect(dossier.existsSync(), isTrue,
          reason: 'le chemin des sources Kotlin doit refleter le paquet');
      expect(
        Directory('android/app/src/main/kotlin/com/only1cent/moteur_gr')
            .existsSync(),
        isFalse,
      );
      for (final f in dossier.listSync().whereType<File>()) {
        expect(f.readAsStringSync(), contains('package $cible'));
      }
    });

    test('iOS : PRODUCT_BUNDLE_IDENTIFIER vaut la MEME cible qu Android', () {
      final pbx =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      expect(pbx, contains('PRODUCT_BUNDLE_IDENTIFIER = $cible;'));
      expect(pbx, contains('PRODUCT_BUNDLE_IDENTIFIER = $cible.RunnerTests;'));
      expect(pbx, isNot(contains('com.only1cent.moteurGr')),
          reason: 'LES DEUX PLATEFORMES DIVERGEAIENT : moteur_gr sur Android, '
              'moteurGr sur iOS');
    });

    test('iOS : le groupe d application a suivi (widget + entitlements)', () {
      for (final chemin in [
        'ios/Runner/Runner.entitlements',
        'ios/TrekWidget/TrekWidgetExtension.entitlements',
        'ios/TrekWidget/TrekWidget.swift',
      ]) {
        final texte = File(chemin).readAsStringSync();
        expect(texte, contains('group.$cible'), reason: chemin);
        expect(texte, isNot(contains('group.com.only1cent.moteurGr')),
            reason: '$chemin : un groupe d application desaccorde casse le '
                'widget natif silencieusement');
      }
    });

    test('LA RESILIATION EN TROIS CLICS suit le nouvel identifiant', () {
      // Le lien de gestion d abonnement Play est construit sur le nom de
      // paquet. Un identifiant perime = un lien mort = obligation legale de
      // resiliation (article L215-1-1) non tenue.
      expect(StoreSubscriptionLinks.androidPackageName, cible);
    });
  });

  // --------------------------------------------------------------------
  // 4. LA CONFIGURATION FIREBASE EST REELLEMENT LUE AU BUILD
  // --------------------------------------------------------------------
  group('604 — Firebase est branche, pas seulement declare', () {
    test('LE GREFFON SANS LEQUEL RIEN N EST LU est declare', () {
      // `Firebase.initializeApp()` est appele SANS options : il attend les
      // ressources natives produites par ce greffon. Absent, l init echouait a
      // 100 % des demarrages Android — zero rapport de plantage, zero
      // catalogue distant, et aucun message pour le dire.
      final settings = File('android/settings.gradle.kts').readAsStringSync();
      expect(settings, contains('com.google.gms.google-services'));
      expect(settings, contains('com.google.firebase.crashlytics'));

      final app = File('android/app/build.gradle.kts').readAsStringSync();
      expect(app, contains('id("com.google.gms.google-services")'));
      expect(app, contains('id("com.google.firebase.crashlytics")'));
    });

    // LES DEUX FICHIERS DE CONFIGURATION NATIFS NE SONT PAS VERSIONNES, et ce
    // n est pas un oubli : `.gitignore` les exclut explicitement sous
    // « Secrets — NE JAMAIS committer », decision anterieure a ce lot. Les
    // controles ci-dessous verifient donc leur COHERENCE quand ils sont la
    // (poste de developpement, machine de build) sans exiger leur presence —
    // sinon ils passeraient au vert chez moi et au rouge sur un clone neuf,
    // ce qui est pire que pas de test du tout.
    //
    // Si Chris tranche pour le versionnement, retirer les trois lignes de
    // `.gitignore` et remplacer ces deux controles par une exigence de
    // presence : ils sont ecrits pour ca.

    test('quand ils sont presents, les fichiers de configuration natifs '
        'designent bien le projet StepWays et le paquet reel', () {
      final android = File('android/app/google-services.json');
      final ios = File('ios/Runner/GoogleService-Info.plist');

      for (final f in [android, ios]) {
        if (!f.existsSync()) continue;
        final texte = f.readAsStringSync();
        expect(texte, contains('stepways-app'), reason: f.path);
        expect(texte, contains('com.only1cent.stepways'),
            reason: '${f.path} : la configuration doit viser le paquet REEL, '
                'sinon Firebase refuse l application au demarrage');
        expect(texte, isNot(contains('gr20-app')),
            reason: '${f.path} : ZERO mutualisation avec le legacy GR20 '
                '(#326 divorce)');
      }
    });

    test('l espace de stockage annonce par la configuration est celui que le '
        'catalogue interroge', () {
      final android = File('android/app/google-services.json');
      if (!android.existsSync()) return;
      expect(android.readAsStringSync(), contains(TrailDataSource.bucket),
          reason: 'si les deux divergent, le catalogue interroge un espace que '
              'l application n est pas autorisee a lire');
    });

    test('la configuration Firebase reste HORS du depot tant que Chris n a pas '
        'tranche — l invariante 596 est intacte', () {
      // Le depot exclut les trois fichiers. C est cette exclusion qui explique
      // pourquoi `lib/firebase_options.dart` n est pas genere : la meme regle
      // l interdit, et `Firebase.initializeApp()` n en a pas besoin sur les
      // deux plateformes des stores.
      final ignores = File('.gitignore').readAsStringSync();
      expect(ignores, contains('**/google-services.json'));
      expect(ignores, contains('**/GoogleService-Info.plist'));
      expect(ignores, contains('lib/firebase_options.dart'));
      expect(File('lib/firebase_options.dart').existsSync(), isFalse,
          reason: 'genere, il porterait des cles dans lib/ — ce que le '
              'balayage de la tache 596 refuse');
    });
  });
}
