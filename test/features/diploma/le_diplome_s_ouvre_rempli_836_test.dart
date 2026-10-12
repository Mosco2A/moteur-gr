/// LA GARDE DU DIPLOME QUI S'OUVRE REMPLI, ET DE SA TRACE SUR UNE CARTE (836).
///
/// ---------------------------------------------------------------------------
/// CE QUI A ETE SIGNALE
/// ---------------------------------------------------------------------------
///
/// A l'ouverture du diplome, Christophe ne voyait que deux manques : « Aucune
/// photo dans le journal » et « Trace non disponible ». L'ecran de la
/// RECOMPENSE s'ouvrait donc sur ce qu'il n'avait pas.
///
/// ---------------------------------------------------------------------------
/// DEUX CAUSES DISTINCTES, ET AUCUNE N'ETAIT UN DEFAUT D'AFFICHAGE
/// ---------------------------------------------------------------------------
///
/// (1) LE CERTIFICAT ETAIT DERRIERE UN `if`. Il n'etait ni absent ni casse :
///     `_generateDiploma` remettait son etat a `null` tant que le champ du nom
///     etait vide, et RIEN ne l'appelait a l'ouverture. Le certificat
///     n'existait donc qu'apres la premiere frappe. Il est desormais DERIVE de
///     ses entrees a chaque image, avec un nom EN ATTENTE tant que rien n'est
///     tape — un diplome se reconnait a sa forme bien avant de porter un nom.
///
/// (2) « TRACE NON DISPONIBLE » DISAIT VRAI, ET C'EST CE QUI REND LE DEFAUT
///     INTERESSANT. Le carnet, au meme instant, dessinait une trace. La
///     demonstration ne pose RIEN en base — promesse de la tache 634, tenue par
///     quatre barrieres — donc `session_track_points` est VIDE ; or
///     `sessionTraceProvider` ne lisait QUE la base. La tache 810 avait deja
///     branche la matiere fabriquee sur le recapitulatif ; le diplome avait ete
///     oublie.
///
/// ET LA TRACE EST MAINTENANT SUR UNE CARTE, des deux cotes. Elle etait
/// dessinee a nu par un `CustomPainter`, sans aucune tuile : une trace sans
/// terrain ne se lit pas.
///
/// ---------------------------------------------------------------------------
/// CE QUE CETTE GARDE MESURE
/// ---------------------------------------------------------------------------
///
/// Pour le certificat : qu'il soit LA avant toute frappe, et que les deux
/// sorties qui ECRIVENT UN FICHIER restent, elles, interdites sans nom reel —
/// un PDF nomme « Ton nom apparaitra ici » serait un faux diplome pose dans les
/// fichiers du telephone.
///
/// Pour la trace : que la carte ouvre SUR LA TRACE. C'est la mesure qui compte,
/// et pas la simple presence d'une carte : une `FlutterMap` sans
/// `initialCenter` ouvre sur le point par defaut du paquet, demande ses
/// tuiles LA, et n'en
/// redemande jamais — le fond reste gris pour toujours sur une vignette sans
/// geste. On verifie donc que le centre d'ouverture tombe DANS les bornes de la
/// trace.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/map/fond_de_carte.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/demo_mode_service.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/domain/trek_session.dart';
// L'extension qui porte `upsertSession` sur le DAO des sessions.
import 'package:moteur_gr/domain/trek_session_mapping.dart';
import 'package:moteur_gr/features/after/after_facade.dart'
    show traceFabriqueeDeDemoProvider;
import 'package:moteur_gr/features/diploma/presentation/diploma_screen.dart';
import 'package:moteur_gr/features/diploma/providers/session_trace_provider.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';

/// La hauteur du cadre : celle d'un telephone courant. C'est la PLIURE —
/// ce qui tombe au-dela demande un geste pour etre vu.
const double _hauteurDeLEcran = 844;

void main() {
  const trailId = 'test-trail-diploma-836';

  const config = TrailConfig(
    id: trailId,
    name: 'Test Trail',
    displayName: 'Test Trail',
    tagline: 'tagline',
    totalStages: 4,
    totalDistanceKm: 40.0,
    totalElevationGain: 2000,
    region: 'Region',
    country: 'France',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/test.gpx',
    defaultDuration: 4,
    availableDurations: [2, 4, 6],
  );

  late AppDatabase db;

  StagesCompanion etape(int n) => StagesCompanion(
    trailId: const Value(trailId),
    stageNumber: Value(n),
    name: Value('Etape $n'),
    distanceKm: const Value(10.0),
    elevationGainM: const Value(500),
    elevationLossM: const Value(400),
    description: const Value('desc'),
    startLat: const Value(42.0),
    startLng: const Value(9.0),
    endLat: const Value(42.1),
    endLng: const Value(9.1),
    difficulty: const Value('moderate'),
  );

  SessionTrackPoint point(int id, double lat, double lng) => SessionTrackPoint(
    id: id,
    trailId: trailId,
    lat: lat,
    lng: lng,
    altitude: 1000,
    recordedAt: DateTime.utc(2026, 6, 1, 8, id),
  );

  /// Une trace courte mais reelle, en Corse : deux points suffisent a cadrer.
  final trace = <SessionTrackPoint>[
    point(1, 42.00, 9.00),
    point(2, 42.05, 9.06),
    point(3, 42.10, 9.12),
  ];

  setUpAll(() async {
    LocaleSettings.setLocaleRaw('fr');
    await initializeDateFormatting('fr_FR');
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Monte le diplome DEVERROUILLE (parcours entierement marche).
  Future<void> monteLeDiplome(
    WidgetTester tester, {
    List<SessionTrackPoint>? traceRendue,
  }) async {
    tester.view.physicalSize = const Size(390, _hauteurDeLEcran);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await db.stagesDao.insertAll([etape(1), etape(2), etape(3), etape(4)]);
    await db.trekSessionsDao.upsertSession(
      TrekSession(
        id: 'sess-836',
        trailId: trailId,
        startedAt: DateTime.utc(2026, 6, 15),
        finishedAt: DateTime.utc(2026, 6, 18),
        status: 'completed',
        completedStages: const ['1', '2', '3', '4'],
        parcoursFullyWalked: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(config),
          currentTrailIdProvider.overrideWith((ref) => trailId),
          demoModeServiceProvider.overrideWithValue(DemoModeService()),
          if (traceRendue != null)
            sessionTraceProvider.overrideWith((ref) async => traceRendue),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/diploma',
            routes: [
              GoRoute(
                path: '/diploma',
                builder: (_, __) => const DiplomaScreen(),
              ),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
  }

  group('LE DIPLOME S OUVRE REMPLI (836)', () {
    testWidgets('a l ouverture, SANS avoir rien tape, le certificat est '
        'affiche avec un nom en attente', (tester) async {
      await monteLeDiplome(tester, traceRendue: trace);

      // LE CERTIFICAT EST LA. Son titre et le nom en attente le prouvent : ce
      // sont deux textes qui n'existent QUE dans l'apercu.
      expect(
        find.text(t.diploma.pdfTitle),
        findsOneWidget,
        reason:
            'LE CERTIFICAT N EST PAS AFFICHE A L OUVERTURE. C est le defaut '
            'de la tache 836 : l apercu etait derriere un `if` que seule une '
            'frappe au clavier ouvrait.',
      );
      // LE NOM EN ATTENTE EST DANS LA PHRASE DU CERTIFICAT (« Certifie que
      // ... a parcouru le ... »), pas dans un texte a part : on le cherche donc
      // par CONTENU.
      // ET IL EST DANS LE PREMIER ECRAN, ce qui est le vrai sujet.
      //
      // RENDRE LE CERTIFICAT NE SUFFISAIT PAS, et c'est la mesure qui l'a dit.
      // Sorti de son `if`, l'apercu existait des l'ouverture — mais il tombait
      // a 1 182 points du haut sur un ecran de 844, soit 338 points SOUS LA
      // PLIURE : trois blocs de recapitulatif le precedaient. Christophe aurait
      // donc toujours ouvert l'ecran sur « Aucune photo dans le journal ». La
      // recompense est passee devant son recapitulatif, et le haut du
      // certificat est descendu de 1 182 a 286 points.
      //
      // ON MESURE LA PLIURE, PAS UN RANG. Exiger « le certificat est le
      // troisieme enfant » serait verrouiller une mise en page ; exiger qu'il
      // soit VISIBLE sans defiler verrouille ce que Christophe a demande.
      final hautDuCertificat = tester
          .getRect(find.text(t.diploma.pdfTitle))
          .top;
      expect(
        hautDuCertificat,
        lessThan(_hauteurDeLEcran),
        reason:
            'LE CERTIFICAT EST SOUS LA PLIURE : son haut tombe a '
            '${hautDuCertificat.toStringAsFixed(0)} points sur un ecran de '
            '$_hauteurDeLEcran, donc l ecran de la recompense s ouvre encore '
            'sur autre chose que la recompense. C est le defaut de la tache '
            '836, pas seulement l apercu manquant.',
      );
      expect(
        find.textContaining(t.diploma.namePending),
        findsOneWidget,
        reason:
            'le nom EN ATTENTE n est pas ecrit sur le certificat : sans lui, '
            'la ligne du nom serait vide et le diplome aurait l air casse',
      );
    });

    testWidgets('les deux sorties qui ECRIVENT UN FICHIER restent interdites '
        'tant qu aucun nom n est tape', (tester) async {
      await monteLeDiplome(tester, traceRendue: trace);

      AppButton boutonDe(String libelle) => tester.widget<AppButton>(
        find.ancestor(of: find.text(libelle), matching: find.byType(AppButton)),
      );

      expect(
        boutonDe(t.diploma.downloadPdf).onPressed,
        isNull,
        reason:
            'un PDF portant le nom EN ATTENTE serait un faux diplome pose '
            'dans les fichiers du telephone',
      );
      expect(boutonDe(t.diploma.shareDiploma).onPressed, isNull);

      // UNE FOIS LE NOM TAPE, les deux sorties s'ouvrent.
      await tester.enterText(find.byType(TextField), 'Christophe');
      await tester.pumpAndSettle();

      expect(
        boutonDe(t.diploma.downloadPdf).onPressed,
        isNotNull,
        reason:
            'avec un nom reel, le diplome doit pouvoir sortir en PDF — sinon '
            'la correction aurait casse la fonction',
      );
      expect(boutonDe(t.diploma.shareDiploma).onPressed, isNotNull);
      expect(
        find.text('Christophe'),
        findsWidgets,
        reason: 'le nom tape remplace le nom en attente sur le certificat',
      );
    });
  });

  group('LA TRACE DU DIPLOME EST SUR UNE CARTE (836)', () {
    testWidgets('la trace est posee sur un fond de carte, et la carte OUVRE '
        'sur la trace', (tester) async {
      await monteLeDiplome(tester, traceRendue: trace);

      expect(
        find.text(t.diploma.recapNoMap),
        findsNothing,
        reason:
            'le diplome annonce « Trace non disponible » alors qu une trace '
            'de trois points lui est fournie',
      );

      final carte = find.byType(FlutterMap);
      expect(
        carte,
        findsOneWidget,
        reason:
            'LA TRACE N EST PAS SUR UNE CARTE : elle etait dessinee a nu par '
            'un CustomPainter, sans aucune tuile',
      );
      expect(
        find.descendant(of: carte, matching: find.byType(FondDeCarte)),
        findsOneWidget,
        reason:
            'le fond doit passer par FondDeCarte, seul endroit autorise a '
            'batir une couche de tuiles (garde fond_de_carte_decide)',
      );

      // LA MESURE QUI COMPTE : le centre d'ouverture tombe DANS la trace. Une
      // carte sans `initialCenter` ouvre sur le point par defaut du paquet,
      // demande ses tuiles la-bas, et n'en redemande jamais.
      final options = tester.widget<FlutterMap>(carte).options;
      final centre = options.initialCenter;
      final latMin = trace.map((p) => p.lat).reduce((a, b) => a < b ? a : b);
      final latMax = trace.map((p) => p.lat).reduce((a, b) => a > b ? a : b);
      final lngMin = trace.map((p) => p.lng).reduce((a, b) => a < b ? a : b);
      final lngMax = trace.map((p) => p.lng).reduce((a, b) => a > b ? a : b);

      expect(
        centre.latitude >= latMin && centre.latitude <= latMax,
        isTrue,
        reason:
            'LA CARTE N OUVRE PAS SUR LA TRACE : centre en '
            '${centre.latitude}, alors que la trace va de $latMin a $latMax. '
            'Les tuiles seront demandees ailleurs, et le flux d evenements de '
            'flutter_map etant sans rejeu, le fond restera gris.',
      );
      expect(
        centre.longitude >= lngMin && centre.longitude <= lngMax,
        isTrue,
        reason:
            'LA CARTE N OUVRE PAS SUR LA TRACE : centre en '
            '${centre.longitude}, alors que la trace va de $lngMin a $lngMax.',
      );
      expect(
        options.initialZoom,
        greaterThan(0),
        reason:
            'sans zoom d ouverture, flutter_map retombe sur son zoom par '
            'defaut et demande une fournee de tuiles pour rien',
      );
    });

    testWidgets('EN DEMONSTRATION, la trace vient de la matiere fabriquee — '
        'la base reste vide', (tester) async {
      // LE CAS EXACT DU DEFAUT : base VIDE (promesse de la demonstration) et
      // matiere fabriquee disponible. Avant ce lot, le provider ne lisait que
      // la base et rendait une liste vide, d'ou « Trace non disponible ».
      final conteneur = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(config),
          enDemoProvider.overrideWithValue(true),
          traceFabriqueeDeDemoProvider.overrideWith((ref) async => trace),
        ],
      );
      addTearDown(conteneur.dispose);

      final rendue = await conteneur.read(sessionTraceProvider.future);

      expect(
        rendue.length,
        trace.length,
        reason:
            'EN DEMONSTRATION LE DIPLOME NE VOIT TOUJOURS PAS DE TRACE. La '
            'base est vide par promesse (tache 634) : le provider doit '
            'retomber sur la matiere fabriquee, comme le fait deja le '
            'recapitulatif depuis la tache 810.',
      );
    });

    testWidgets('HORS demonstration, la trace vient bien de la BASE', (
      tester,
    ) async {
      // LE REVERS DE LA BRANCHE, sans quoi on aurait pu brancher la matiere
      // fabriquee partout et casser le vrai parcours.
      final conteneur = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(config),
          enDemoProvider.overrideWithValue(false),
          traceFabriqueeDeDemoProvider.overrideWith((ref) async => trace),
        ],
      );
      addTearDown(conteneur.dispose);

      final rendue = await conteneur.read(sessionTraceProvider.future);

      expect(
        rendue,
        isEmpty,
        reason:
            'hors demonstration, la base est la seule source : la matiere '
            'fabriquee ne doit JAMAIS se substituer a une vraie trace.',
      );
    });
  });
}
