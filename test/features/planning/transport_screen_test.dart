import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/planning/domain/transport_catalog.dart';
import 'package:moteur_gr/features/planning/domain/transport_info.dart';
import 'package:moteur_gr/features/planning/presentation/transport_screen.dart';
import 'package:moteur_gr/features/planning/providers/transport_providers.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// PARITE GR20 (#99460) — ecran TRANSPORT (« Aller & retour », data-driven).
///
/// Clone de l'ecran GR20 `TransportScreen` : 2 onglets aller/retour, endpoints
/// (depart/arrivee) resolus depuis les DONNEES du sentier (etapes :
/// departureName/arrivalName), DIRECTION-AWARE, et contenu (modes, operateurs,
/// horaires, tel/liens) venant du catalogue transport du sentier — PAS de
/// widgets hardcodes par localite. Generique multi-sentiers (#84627), zero
/// hardcode ; fallback gracieux sans donnees.
///
/// Couverture :
///   - resolution des endpoints depuis les etapes, direction-aware (providers) ;
///   - le catalogue Mare a Mare Centre porte les endpoints reels ;
///   - les 2 onglets s'affichent avec les bons libelles (endpoints resolus) ;
///   - le contenu (sections, options, tel/lien) vient des donnees du sentier ;
///   - fallback propre quand le sentier n'a pas de donnees transport ;
///   - la carte HUB « Transport » ouvre l'ecran, navigation aller/retour OK.
void main() {
  const trailId = 'test-trail';

  setUpAll(() {
    LocaleSettings.setLocaleRaw('fr');
  });

  // --- Fixtures ------------------------------------------------------------

  /// Config de test bi-directionnelle (sens de reference = 'NS').
  const testConfig = TrailConfig(
    id: trailId,
    name: 'Test',
    displayName: 'Test Trail',
    tagline: 't',
    totalStages: 3,
    totalDistanceKm: 30,
    totalElevationGain: 1000,
    region: 'Test',
    country: 'Test',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/test.gpx',
    directions: ['NS', 'SN'],
  );

  StageModel stage(int n, String dep, String arr) => StageModel(
        trailId: trailId,
        stageNumber: n,
        name: '$dep - $arr',
        distanceKm: 10,
        elevationGainM: 400,
        elevationLossM: 300,
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
        departureName: dep,
        arrivalName: arr,
      );

  // 3 etapes : Alpha -> Beta -> Gamma -> Delta (endpoints = Alpha / Delta).
  final testStages = [
    stage(1, 'Alpha', 'Beta'),
    stage(2, 'Beta', 'Gamma'),
    stage(3, 'Gamma', 'Delta'),
  ];

  /// Donnees transport de test rattachees au sentier de test (les 2 sens du
  /// endpoint de depart Alpha et d'arrivee Delta).
  const testTransport = TrailTransport(
    trailId: trailId,
    endpoints: [
      EndpointTransport(
        endpointName: 'Alpha',
        role: TransportRole.arrival,
        intro: 'Intro rejoindre Alpha',
        sections: [
          TransportSection(
            title: 'Depuis la gare',
            mode: TransportModeKind.train,
            options: [
              TransportOption(
                mode: TransportModeKind.train,
                title: 'Train vers Alpha',
                description: 'Ligne de test',
                price: '10 EUR',
                schedule: '08h00',
                contact: '+33123456789',
                contactLabel: 'Gare Alpha',
                url: 'https://example.org/train',
              ),
            ],
          ),
        ],
        advices: ['Conseil Alpha 1'],
      ),
      EndpointTransport(
        endpointName: 'Delta',
        role: TransportRole.departure,
        intro: 'Intro repartir Delta',
        sections: [
          TransportSection(
            title: 'Vers la ville',
            mode: TransportModeKind.bus,
            options: [
              TransportOption(
                mode: TransportModeKind.bus,
                title: 'Bus depuis Delta',
                description: 'Retour ville',
                price: '5 EUR',
                schedule: '17h00',
                contact: '+33987654321',
                contactLabel: 'Bus Delta',
              ),
            ],
          ),
        ],
        advices: ['Conseil Delta 1'],
      ),
    ],
  );

  List<Override> baseOverrides({
    List<StageModel>? stages,
    TrailTransport? transport = testTransport,
    String? direction,
  }) =>
      [
        trailConfigProvider.overrideWithValue(testConfig),
        stagesProvider(trailId)
            .overrideWith((ref) => Future.value(stages ?? testStages)),
        trailTransportProvider(trailId).overrideWithValue(transport),
        if (direction != null)
          selectedDirectionProvider.overrideWith((ref) => direction),
      ];

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int maxFrames = 40,
  }) async {
    for (var i = 0; i < maxFrames; i++) {
      if (tester.widgetList(finder).isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpUntilGone(
    WidgetTester tester,
    Finder finder, {
    int maxFrames = 40,
  }) async {
    for (var i = 0; i < maxFrames; i++) {
      if (tester.widgetList(finder).isEmpty) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Widget wrap({required List<Override> overrides}) {
    final router = GoRouter(
      initialLocation: '/t',
      routes: [
        GoRoute(
          path: '/t',
          builder: (_, __) => const TransportScreen(trailId: trailId),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  // --- Resolution des endpoints (providers, direction-aware) ---------------

  group('resolution des endpoints (direction-aware)', () {
    test('sens de reference (NS) : depart = 1re etape, arrivee = derniere', () {
      final container = ProviderContainer(overrides: baseOverrides());
      addTearDown(container.dispose);
      // Declenche le chargement des etapes (FutureProvider).
      container.read(stagesProvider(trailId));
      // Le provider d'endpoints lit la valeur chargee : on relit apres settle.
      return Future<void>.delayed(const Duration(milliseconds: 50), () {
        final ep = container.read(transportEndpointsProvider(trailId));
        expect(ep, isNotNull);
        expect(ep!.departure, 'Alpha');
        expect(ep.arrival, 'Delta');
      });
    });

    test('sens inverse (SN) : depart et arrivee sont echanges', () {
      final container =
          ProviderContainer(overrides: baseOverrides(direction: 'SN'));
      addTearDown(container.dispose);
      container.read(stagesProvider(trailId));
      return Future<void>.delayed(const Duration(milliseconds: 50), () {
        final ep = container.read(transportEndpointsProvider(trailId));
        expect(ep, isNotNull);
        // En sens inverse, on part de Delta (arrivee de la derniere etape) et on
        // arrive a Alpha (depart de la premiere etape).
        expect(ep!.departure, 'Delta');
        expect(ep.arrival, 'Alpha');
      });
    });

    test('repli sur le nom d\'etape si departureName/arrivalName manquent', () {
      final poor = [
        const StageModel(
          trailId: trailId,
          stageNumber: 1,
          name: 'Etape unique',
          distanceKm: 10,
          elevationGainM: 100,
          elevationLossM: 100,
          startLat: 0,
          startLng: 0,
          endLat: 0,
          endLng: 0,
        ),
      ];
      final container =
          ProviderContainer(overrides: baseOverrides(stages: poor));
      addTearDown(container.dispose);
      container.read(stagesProvider(trailId));
      return Future<void>.delayed(const Duration(milliseconds: 50), () {
        final ep = container.read(transportEndpointsProvider(trailId));
        expect(ep, isNotNull);
        // Sans endpoints nommes, on retombe sur le nom de l'etape (pas de crash,
        // aucun lieu invente).
        expect(ep!.departure, 'Etape unique');
        expect(ep.arrival, 'Etape unique');
      });
    });
  });

  // --- Catalogue Mare a Mare Centre (donnees reelles) ----------------------

  group('catalogue Mare a Mare Centre', () {
    test('porte les endpoints reels du sentier (Ghisonaccia / Porticcio)', () {
      final data = TransportCatalog.forTrail('mare-a-mare-centre');
      expect(data, isNotNull);
      // Aller vers Ghisonaccia (depart) et retour depuis Porticcio (arrivee)
      // existent (parite GR20 : 2 onglets renseignes).
      expect(
        data!.forEndpoint('Ghisonaccia', TransportRole.arrival),
        isNotNull,
      );
      expect(
        data.forEndpoint('Porticcio', TransportRole.departure),
        isNotNull,
      );
      // Les 2 autres combinaisons (sens inverse) sont aussi fournies.
      expect(
        data.forEndpoint('Ghisonaccia', TransportRole.departure),
        isNotNull,
      );
      expect(data.forEndpoint('Porticcio', TransportRole.arrival), isNotNull);
    });

    test('chaque onglet MaM a du contenu (sections avec options)', () {
      final data = TransportCatalog.forTrail('mare-a-mare-centre')!;
      for (final ep in data.endpoints) {
        expect(ep.hasContent, isTrue,
            reason: '${ep.endpointName}/${ep.role} doit avoir des options');
      }
    });

    test('un sentier inconnu ne fournit pas de donnees (fallback UI)', () {
      expect(TransportCatalog.forTrail('sentier-inexistant'), isNull);
    });
  });

  // --- Ecran : 2 onglets + contenu data-driven -----------------------------

  group('ecran transport (2 onglets, data-driven)', () {
    testWidgets('affiche 2 onglets aller/retour avec les endpoints resolus',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: baseOverrides()));
      await settle(tester);

      // Onglet ALLER : « Rejoindre Alpha » ; onglet RETOUR : « Repartir de
      // Delta » (endpoints resolus depuis les etapes, sens NS). Le libelle
      // d'onglet ET le titre d'intro portent le meme texte (parite GR20 ou le
      // titre de l'onglet visible se retrouve dans l'en-tete) -> findsWidgets.
      expect(find.text(t.transport.tabJoinNamed(name: 'Alpha')), findsWidgets);
      // L'onglet RETOUR (Delta) est present dans la TabBar (au moins le libelle
      // d'onglet ; son intro n'est montee qu'a l'activation de l'onglet).
      expect(find.text(t.transport.tabLeaveNamed(name: 'Delta')), findsWidgets);
      expect(find.text(t.transport.title), findsOneWidget);
      // Sanity parite : c'est bien un TabBar a 2 onglets.
      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('onglet ALLER : contenu venant des donnees du sentier',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: baseOverrides()));
      await settle(tester);

      // Intro, section, option, prix, contact (donnees du sentier).
      expect(find.text('Intro rejoindre Alpha'), findsOneWidget);
      expect(find.text('Depuis la gare'), findsOneWidget);
      expect(find.text('Train vers Alpha'), findsOneWidget);
      expect(find.text('10 EUR'), findsOneWidget);
      expect(find.text('Gare Alpha'), findsOneWidget);
      // Conseils pratiques (carte commune, titre localise).
      expect(find.text(t.transport.adviceTitle), findsOneWidget);
      expect(find.text('Conseil Alpha 1'), findsOneWidget);
    });

    testWidgets('actions tel + lien presentes sur une option qui les porte',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: baseOverrides()));
      await settle(tester);

      // Contact telephonique cliquable (numero affiche) + bouton site (icone
      // open_in_new) — parite GR20 (facilitateur tel:/url).
      expect(find.text('+33123456789'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });

    testWidgets('bascule sur l\'onglet RETOUR : contenu de l\'arrivee',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: baseOverrides()));
      await settle(tester);

      // Passer a l'onglet « Repartir de Delta ».
      await tester.tap(find.text(t.transport.tabLeaveNamed(name: 'Delta')));
      await settle(tester);

      expect(find.text('Intro repartir Delta'), findsOneWidget);
      expect(find.text('Bus depuis Delta'), findsOneWidget);
      expect(find.text('Conseil Delta 1'), findsOneWidget);
    });

    testWidgets('direction inverse (SN) : les onglets suivent le sens choisi',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: baseOverrides(direction: 'SN')));
      await settle(tester);

      // En sens inverse, on part de Delta et on arrive a Alpha.
      expect(find.text(t.transport.tabJoinNamed(name: 'Delta')), findsWidgets);
      expect(find.text(t.transport.tabLeaveNamed(name: 'Alpha')), findsWidgets);
    });
  });

  // --- Fallback sans donnees -----------------------------------------------

  group('fallback sans donnees transport', () {
    testWidgets('sentier sans donnees : etat informatif propre, pas de crash',
        (tester) async {
      // Endpoints resolus (etapes presentes) mais AUCUNE donnee transport.
      await tester.pumpWidget(
        wrap(overrides: baseOverrides(transport: null)),
      );
      await settle(tester);

      // Les onglets restent presents (titres d'endpoints resolus).
      expect(find.text(t.transport.tabJoinNamed(name: 'Alpha')), findsOneWidget);
      // Le corps affiche l'etat vide (titre generique « bientot disponible »).
      expect(find.text(t.transport.empty.title), findsWidgets);
      // Aucune exception de layout/plugin n'a ete levee.
      expect(tester.takeException(), isNull);
    });
  });

  // --- Navigation depuis le HUB --------------------------------------------

  group('navigation', () {
    testWidgets('la carte HUB « Transport » ouvre l\'ecran, retour sans crash',
        (tester) async {
      // Routeur minimal reproduisant l'entree HUB : une carte
      // `Icons.directions_bus` (comme le HUB) qui `push` vers Transport.
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: InkWell(
                  onTap: () => context.push('/trail/$trailId/transport'),
                  child: const Icon(Icons.directions_bus),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/trail/:id/transport',
            builder: (context, state) => TransportScreen(
              trailId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: baseOverrides(),
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ));
      await settle(tester);

      // Aller : taper la carte HUB (icone directions_bus) ouvre Transport.
      expect(find.byIcon(Icons.directions_bus), findsOneWidget);
      await tester.tap(find.byIcon(Icons.directions_bus));
      await settle(tester);
      await pumpUntil(tester, find.text(t.transport.title));
      expect(find.text(t.transport.title), findsWidgets);

      // Retour : bouton back de l'AppBar (Icons.arrow_back) -> retour au HUB
      // sans crash (pile preservee, jamais context.go qui viderait la pile).
      await pumpUntil(tester, find.byIcon(Icons.arrow_back));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);
      await pumpUntilGone(tester, find.text(t.transport.title));
      expect(find.text(t.transport.title), findsNothing);
      expect(find.byIcon(Icons.directions_bus), findsOneWidget);
    });
  });
}
