import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/weather/domain/fire_risk.dart';
import 'package:moteur_gr/features/weather/domain/fire_risk_catalog.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';
import 'package:moteur_gr/features/weather/presentation/fire_risk_screen.dart';
import 'package:moteur_gr/features/weather/providers/fire_risk_providers.dart';
import 'package:moteur_gr/features/weather/providers/weather_providers.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// PARITE GR20 (#99460) — ecran RISQUE INCENDIE (« Risques & alertes »,
/// data-driven).
///
/// Clone de l'ecran GR20 `FireRiskScreen` : niveaux de risque (0-5) DERIVES de la
/// meteo (socle meteo StepWays reutilise + calcul `calculateFireRiskLevel`
/// identique GR20), agreges par etape et TRIES decroissant (filtre niveau >= 1) ;
/// reglementation (periode/region/URL/message) et secours regionaux venant de la
/// DONNEE du sentier (catalogue incendie + `TrailConfig.emergencyNumbers`), sans
/// aucune localite en dur dans le moteur ; i18n Slang 5 langues ; a11y sur
/// numeros/lien. Fallback informatif si aucune donnee meteo.
///
/// Couverture :
///   - calcul du niveau derive de la meteo : bornes/mapping (parite GR20) ;
///   - catalogue Mare a Mare Centre : reglementation data-driven honnete ;
///   - agregation par etape + tri decroissant + filtre niveau >= 1 (providers) ;
///   - numeros universels 18/112 + secours regional de la config (data-driven) ;
///   - ecran : sections, legende, badges, detail par jour, no-risk, tel/lien ;
///   - fallback sans donnees meteo (ecran informatif propre) ;
///   - la carte HUB « Incendie » ouvre l'ecran, navigation retour sans crash.
void main() {
  const trailId = 'test-trail';

  setUpAll(() {
    LocaleSettings.setLocaleRaw('fr');
  });

  // --- Fixtures ------------------------------------------------------------

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
    emergencyNumbers: [
      TrailEmergencyNumber(name: 'Secours test regional', phone: '+33123456789'),
    ],
  );

  StageModel stage(int n, String name) => StageModel(
        trailId: trailId,
        stageNumber: n,
        name: name,
        distanceKm: 10,
        elevationGainM: 400,
        elevationLossM: 300,
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
      );

  final testStages = [
    stage(1, 'Etape Alpha'),
    stage(2, 'Etape Beta'),
    stage(3, 'Etape Gamma'),
  ];

  /// Construit une prevision 3 jours a temperatures donnees (les autres facteurs
  /// neutres : vent faible, pas de pluie) pour piloter le niveau derive.
  WeatherForecast forecastAt(List<double> tempsMax) => WeatherForecast(
        latitude: 0,
        longitude: 0,
        days: [
          for (var i = 0; i < tempsMax.length; i++)
            DayForecast(
              date: DateTime(2026, 7, 15).add(Duration(days: i)),
              temperatureMax: tempsMax[i],
              temperatureMin: 15,
              precipitationMm: 0,
              windSpeedKmh: 5,
              uvIndex: 8,
              weatherCode: 0,
              precipitationProbabilityMax: 0,
            ),
        ],
      );

  /// Override d'une etape meteo par un etat fixe (parite : le socle meteo est la
  /// source ; ici on injecte une prevision deterministe pour tester l'agregation
  /// du risque sans DB ni reseau).
  Override weatherOverride(int stageNumber, WeatherForecast? forecast) {
    final params =
        WeatherStageParams(trailId: trailId, stageNumber: stageNumber);
    return stageWeatherProvider(params).overrideWith(
      () => _FixedWeatherNotifier(
        WeatherState(forecast: forecast, isLoading: false),
      ),
    );
  }

  List<Override> baseOverrides({
    List<StageModel>? stages,
    Map<int, WeatherForecast?>? forecasts,
  }) {
    final fc = forecasts ??
        {
          // Alpha : 27 C -> niveau 1 (Faible). Beta : 36 C -> niveau 3 (Eleve).
          // Gamma : 20 C -> niveau 0 (pas de risque, ne remonte pas).
          1: forecastAt([27, 26, 24]),
          2: forecastAt([36, 34, 30]),
          3: forecastAt([20, 19, 18]),
        };
    return [
      trailConfigProvider.overrideWithValue(testConfig),
      stagesProvider(trailId)
          .overrideWith((ref) => Future.value(stages ?? testStages)),
      for (final entry in fc.entries) weatherOverride(entry.key, entry.value),
    ];
  }

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
          builder: (_, __) => const FireRiskScreen(trailId: trailId),
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

  // --- Calcul du niveau derive de la meteo (parite GR20) -------------------

  group('calculateFireRiskLevel (derive meteo, parite GR20)', () {
    test('pluie recente (> 5 mm) => niveau 0 (sol humide)', () {
      expect(
        calculateFireRiskLevel(
          temperatureMax: 40,
          windSpeedKmh: 50,
          precipitationMm: 6,
        ),
        0,
      );
    });

    test('forte proba de pluie (> 70 %) => niveau 0 (air humide)', () {
      expect(
        calculateFireRiskLevel(
          temperatureMax: 40,
          windSpeedKmh: 50,
          precipitationMm: 0,
          precipitationProbability: 80,
        ),
        0,
      );
    });

    test('temperature moderee (27 C), sec, peu de vent => niveau 1', () {
      expect(
        calculateFireRiskLevel(
          temperatureMax: 27,
          windSpeedKmh: 5,
          precipitationMm: 0,
        ),
        1,
      );
    });

    test('canicule (36 C) + vent fort (45 km/h), sec => niveau eleve borne', () {
      // 36 C (>= 35 => +3) + 45 km/h (>= 40 => +2) = 5, borne a 5 (Extreme).
      final level = calculateFireRiskLevel(
        temperatureMax: 36,
        windSpeedKmh: 45,
        precipitationMm: 0,
      );
      expect(level, 5);
    });

    test('resultat toujours borne dans [0..5]', () {
      for (final temp in [0.0, 20.0, 25.0, 30.0, 35.0, 45.0]) {
        for (final wind in [0.0, 25.0, 40.0, 100.0]) {
          final level = calculateFireRiskLevel(
            temperatureMax: temp,
            windSpeedKmh: wind,
            precipitationMm: 0,
          );
          expect(level, inInclusiveRange(0, 5));
        }
      }
    });

    test('proba de pluie manquante (null) traitee comme 0 (pas d\'attenuation)',
        () {
      // 30 C (+2), pas de pluie, proba null -> aucune attenuation -> niveau 2.
      expect(
        calculateFireRiskLevel(
          temperatureMax: 30,
          windSpeedKmh: 5,
          precipitationMm: 0,
          precipitationProbability: null,
        ),
        2,
      );
    });
  });

  // --- Catalogue reglementation (data-driven, honnete) ---------------------

  group('catalogue reglementation incendie', () {
    test('Mare a Mare Centre porte une reglementation Corse data-driven', () {
      final data = FireRiskCatalog.forTrail('mare-a-mare-centre');
      expect(data, isNotNull);
      final reg = data!.regulation;
      expect(reg.hasContent, isTrue);
      expect(reg.regionLabel, 'Corse');
      expect(reg.hasMessage, isTrue);
      expect(reg.hasDecreeUrl, isTrue);
      // Periode estivale (juin-septembre) portee par la DONNEE, pas le moteur.
      expect(reg.periodStartMonth, 6);
      expect(reg.periodEndMonth, 9);
      // Lien officiel (carte de risque Corse), verifiable.
      expect(reg.decreeUrl, contains('risque-prevention-incendie.fr'));
    });

    test('un sentier inconnu ne fournit pas de reglementation (section masquee)',
        () {
      expect(FireRiskCatalog.forTrail('sentier-inexistant'), isNull);
    });
  });

  // --- Agregation par etape (providers) ------------------------------------

  group('agregation du risque par etape (providers)', () {
    test('etapes a risque triees decroissant + filtre niveau >= 1', () {
      final container = ProviderContainer(overrides: baseOverrides());
      addTearDown(container.dispose);
      container.read(stagesProvider(trailId));
      return Future<void>.delayed(const Duration(milliseconds: 50), () {
        final state = container.read(trailFireRiskProvider(trailId));
        expect(state.hasAnyForecast, isTrue);
        final risky = state.stagesAtRisk;
        // Gamma (niveau 0) est exclue ; Alpha (1) et Beta (3) restent.
        expect(risky.map((s) => s.stageNumber), [2, 1]);
        // Tri decroissant : Beta (niveau max 3) avant Alpha (niveau max 1).
        expect(risky.first.maxLevel, 3);
        expect(risky.last.maxLevel, 1);
      });
    });

    test('niveaux par jour derives de la meteo de chaque etape', () {
      final container = ProviderContainer(overrides: baseOverrides());
      addTearDown(container.dispose);
      container.read(stagesProvider(trailId));
      return Future<void>.delayed(const Duration(milliseconds: 50), () {
        final state = container.read(trailFireRiskProvider(trailId));
        final beta = state.stages.firstWhere((s) => s.stageNumber == 2);
        // 3 jours de prevision -> 3 niveaux par jour (parite GR20 detail/jour).
        expect(beta.days.length, 3);
        expect(beta.maxLevel, 3); // 36 C sec => niveau 3.
      });
    });

    test('aucune etape a risque quand toute la meteo est fraiche/humide', () {
      final container = ProviderContainer(
        overrides: baseOverrides(forecasts: {
          1: forecastAt([18, 17, 16]),
          2: forecastAt([19, 18, 17]),
          3: forecastAt([20, 19, 18]),
        }),
      );
      addTearDown(container.dispose);
      container.read(stagesProvider(trailId));
      return Future<void>.delayed(const Duration(milliseconds: 50), () {
        final state = container.read(trailFireRiskProvider(trailId));
        expect(state.hasAnyForecast, isTrue);
        expect(state.stagesAtRisk, isEmpty);
      });
    });

    test('pas de prevision => hasAnyForecast faux (fallback UI)', () {
      final container = ProviderContainer(
        overrides: baseOverrides(forecasts: {1: null, 2: null, 3: null}),
      );
      addTearDown(container.dispose);
      container.read(stagesProvider(trailId));
      return Future<void>.delayed(const Duration(milliseconds: 50), () {
        final state = container.read(trailFireRiskProvider(trailId));
        expect(state.hasAnyForecast, isFalse);
        expect(state.stagesAtRisk, isEmpty);
      });
    });
  });

  // --- Numeros d'urgence (data-driven : universels + regionaux) ------------

  group('numeros d\'urgence (data-driven)', () {
    test('18/112 universels (moteur) + secours regional (config)', () {
      final container = ProviderContainer(overrides: baseOverrides());
      addTearDown(container.dispose);
      final numbers = container.read(fireEmergencyNumbersProvider(trailId));
      // 18 (pompiers) + 112 (europeen) universels + 1 secours regional config.
      expect(numbers.length, 3);
      expect(numbers[0].phone, '18');
      expect(numbers[0].isUniversal, isTrue);
      expect(numbers[1].phone, '112');
      expect(numbers[1].isUniversal, isTrue);
      // Regional : vient de la DONNEE du sentier (jamais invente).
      expect(numbers[2].phone, '+33123456789');
      expect(numbers[2].isUniversal, isFalse);
      expect(numbers[2].labelData, 'Secours test regional');
    });
  });

  // --- Ecran : sections + contenu data-driven ------------------------------

  group('ecran risque incendie', () {
    testWidgets('affiche les sections cle (titre, legende, numeros)',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: baseOverrides()));
      await settle(tester);

      expect(find.text(t.fireRisk.title), findsWidgets);
      // Bandeau source FWI (transparence).
      expect(find.text(t.fireRisk.fwiSource), findsOneWidget);
      // Legende + section risque par etape + numeros utiles.
      expect(find.text(t.fireRisk.levelsTitle), findsOneWidget);
      expect(find.text(t.fireRisk.stagesTitle), findsOneWidget);
      expect(find.text(t.fireRisk.numbersTitle), findsOneWidget);
      // 5 libelles de legende (Faible -> Extreme).
      expect(find.text(t.fireRisk.level.low), findsWidgets);
      expect(find.text(t.fireRisk.level.extreme), findsWidgets);
    });

    testWidgets('etapes a risque affichees, triees, avec badge etape',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: baseOverrides()));
      await settle(tester);

      // Beta (niveau 3) et Alpha (niveau 1) sont a risque ; Gamma (0) exclue.
      expect(find.text('Etape Beta'), findsOneWidget);
      expect(find.text('Etape Alpha'), findsOneWidget);
      expect(find.text('Etape Gamma'), findsNothing);
      // Badges d'etape (E2 pour Beta, E1 pour Alpha).
      expect(find.text(t.fireRisk.stageBadge(number: 2)), findsOneWidget);
      expect(find.text(t.fireRisk.stageBadge(number: 1)), findsOneWidget);
    });

    testWidgets('numeros d\'urgence tappables affiches (18/112 + regional)',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: baseOverrides()));
      await settle(tester);

      expect(find.text('18'), findsOneWidget);
      expect(find.text('112'), findsOneWidget);
      expect(find.text('+33123456789'), findsOneWidget);
      // Libelles universels traduits via Slang + secours regional (donnee).
      expect(find.text(t.fireRisk.number.firefighters), findsOneWidget);
      expect(find.text('Secours test regional'), findsOneWidget);
    });

    testWidgets(
        'section reglementation rendue (data-driven) avec message + lien',
        (tester) async {
      // Injecte une reglementation de sentier (data-driven) : la section doit
      // s'afficher avec son titre, son message et le lien vers les arretes.
      const reg = FireRegulation(
        regionLabel: 'Testland',
        periodStartMonth: 6,
        periodEndMonth: 9,
        message: 'Message reglementaire de test.',
        decreeUrl: 'https://example.org/arretes',
      );
      await tester.pumpWidget(wrap(
        overrides: [
          ...baseOverrides(),
          trailFireRegulationProvider(trailId).overrideWithValue(reg),
        ],
      ));
      await settle(tester);

      expect(find.text(t.fireRisk.regulation.title), findsOneWidget);
      expect(find.text('Message reglementaire de test.'), findsOneWidget);
      // Lien vers les arretes (libelle traduit + icone open_in_new, parite GR20).
      expect(find.text(t.fireRisk.regulation.decreeLink), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('section reglementation masquee quand le sentier n\'en a pas',
        (tester) async {
      // test-trail n'a pas d'entree au catalogue -> section masquee proprement.
      await tester.pumpWidget(wrap(overrides: baseOverrides()));
      await settle(tester);
      expect(find.text(t.fireRisk.regulation.title), findsNothing);
    });

    testWidgets('detail par jour affiche un niveau par jour de prevision',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: baseOverrides()));
      await settle(tester);

      // Beta a 3 jours de prevision -> plusieurs pastilles « Niv. X » (detail
      // par jour, parite GR20). Au moins un badge de niveau visible.
      expect(find.byIcon(Icons.local_fire_department), findsWidgets);
      expect(find.textContaining('Niv.'), findsWidgets);
    });

    testWidgets('etat « aucun risque » quand aucune etape a risque',
        (tester) async {
      await tester.pumpWidget(wrap(
        overrides: baseOverrides(forecasts: {
          1: forecastAt([18, 17, 16]),
          2: forecastAt([19, 18, 17]),
          3: forecastAt([20, 19, 18]),
        }),
      ));
      await settle(tester);

      expect(find.text(t.fireRisk.noRisk), findsOneWidget);
    });

    testWidgets('sans donnee meteo : fallback informatif propre, pas de crash',
        (tester) async {
      await tester.pumpWidget(wrap(
        overrides: baseOverrides(forecasts: {1: null, 2: null, 3: null}),
      ));
      await settle(tester);

      expect(find.text(t.fireRisk.empty.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // --- Navigation depuis le HUB --------------------------------------------

  group('navigation HUB', () {
    testWidgets('la carte HUB « Incendie » ouvre l\'ecran, retour sans crash',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: InkWell(
                  onTap: () => context.push('/trail/$trailId/fire-risk'),
                  child: const Icon(Icons.local_fire_department),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/trail/:id/fire-risk',
            builder: (context, state) => FireRiskScreen(
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

      // Aller : taper la carte HUB (icone local_fire_department) ouvre l'ecran.
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      await tester.tap(find.byIcon(Icons.local_fire_department));
      await settle(tester);
      await pumpUntil(tester, find.text(t.fireRisk.title));
      expect(find.text(t.fireRisk.title), findsWidgets);

      // Retour : bouton back de l'AppBar -> retour au HUB sans crash (pile
      // preservee, jamais context.go qui viderait la pile).
      await pumpUntil(tester, find.byIcon(Icons.arrow_back));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);
      await pumpUntilGone(tester, find.text(t.fireRisk.title));
      expect(find.text(t.fireRisk.title), findsNothing);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });
  });
}

/// Notifier de test : renvoie un [WeatherState] fixe (aucune DB/reseau).
///
/// Le socle meteo est la source du risque (parite GR20) ; pour tester
/// l'agregation on injecte une prevision deterministe via override du provider
/// d'etape, sans monter le repository reel.
class _FixedWeatherNotifier extends StageWeatherNotifier {
  _FixedWeatherNotifier(this._fixed)
      : super(const WeatherStageParams(trailId: 'test-trail', stageNumber: 0));

  final WeatherState _fixed;

  @override
  WeatherState build() => _fixed;
}
