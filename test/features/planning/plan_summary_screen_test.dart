import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/booking/domain/models/nuitee_type.dart';
import 'package:moteur_gr/features/booking/providers/nuitee_selections_provider.dart';
import 'package:moteur_gr/features/notifications/providers/download_reminder_provider.dart';
import 'package:moteur_gr/features/planning/models/planned_day.dart';
import 'package:moteur_gr/features/planning/presentation/plan_summary_screen.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// PARITE GR20 (#99460) — ecran RESUME / SYNTHESE du plan (agregateur).
///
/// Clone de l'ecran GR20 `PlanSummaryScreen` : etat vide + 4 sections
/// (Configuration, Statistiques, Jour par jour, Boutons d'action). AGREGATEUR :
/// aucune donnee inventee, tout vient des providers StepWays deja en place
/// (programme, stats, nuitees, date de depart). Generique multi-sentiers, ZERO
/// hardcode de localite ni de « GR20 ».
///
/// Ces tests couvrent (mandat) :
///   - la carte HUB « Resume » ouvre l'ecran (push, retour propre) ;
///   - etat vide (aucun programme) + CTA « CONFIGURER L'ITINERAIRE » ;
///   - les 3 cartes (config / stats / jour par jour) alimentees par les
///     providers ;
///   - stats agregees coherentes (distance / D+ / duree / compteurs) ;
///   - tuile jour de marche -> detail d'etape (`/stages/:num`) ;
///   - tuile jour de repos -> bottom sheet ;
///   - bouton Partager appelle share_plus (canal plateforme mocke) ;
///   - stubs (PDF / cartes offline) affichent la SnackBar ;
///   - sens de marche pris en compte (D+ inverse en sens retour) ;
///   - fallback sans plan (pas de crash) ;
///   - helpers purs d'agregation (sens de marche).
void main() {
  const trailId = 'test_trail';

  setUpAll(() {
    // Slang en francais (base_locale) pour resoudre les libelles.
    LocaleSettings.setLocaleRaw('fr');
  });

  setUp(() {
    // Reinitialise le sens de marche (StateProvider global) entre les tests.
    _sharedTexts.clear();
  });

  // --- Fixtures ------------------------------------------------------------

  StageModel stage(
    int n, {
    double distanceKm = 12,
    int gain = 600,
    int loss = 500,
    String? departureName,
    String? arrivalName,
  }) =>
      StageModel(
        trailId: trailId,
        stageNumber: n,
        name: 'Etape $n',
        distanceKm: distanceKm,
        elevationGainM: gain,
        elevationLossM: loss,
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
        departureName: departureName,
        arrivalName: arrivalName,
      );

  PlannedDay walkDay(int dayNumber, int stageNumber) =>
      PlannedDay(dayNumber: dayNumber, stages: [stage(stageNumber)]);

  PlannedDay restDay(int dayNumber) =>
      PlannedDay(dayNumber: dayNumber, stages: const [], isRestDay: true);

  /// Stats agregees coherentes avec une liste de jours (comme le vrai provider).
  PlanningStats statsFor(List<PlannedDay> days) {
    var dist = 0.0;
    var gain = 0;
    var loss = 0;
    var hours = 0.0;
    var stages = 0;
    for (final d in days) {
      if (d.isRestDay) continue;
      dist += d.totalDistanceKm;
      gain += d.totalElevationGainM;
      loss += d.totalElevationLossM;
      hours += d.estimatedHours;
      stages += d.stages.length;
    }
    return PlanningStats(
      totalDistance: dist,
      totalElevationGain: gain,
      totalElevationLoss: loss,
      totalHours: hours,
      trekDays: days.where((d) => !d.isRestDay).length,
      restDays: days.where((d) => d.isRestDay).length,
      stageCount: stages,
    );
  }

  /// Agrandit la surface de test pour que tout l'ecran (4 sections + boutons)
  /// tienne sans scroll : les taps ne « ratent » pas des widgets hors ecran et
  /// les valeurs sont toutes rendues. Reinitialise en fin de test.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  /// Recherche une valeur de statistique rendue via [RichText] (les 6 KPI de la
  /// carte Statistiques utilisent RichText, comme GR20). `find.text` ne matche
  /// pas RichText : on inspecte le texte concatene de chaque RichText.
  Finder findStatValue(String value) => find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().replaceAll(' ', ' ').contains(value),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int minMatches = 1,
    int maxFrames = 40,
  }) async {
    for (var i = 0; i < maxFrames; i++) {
      if (tester.widgetList(finder).length >= minMatches) return;
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

  /// Overrides communs : programme + stats figes (evite le pipeline
  /// stages/repartition), date de depart deterministe et selections de nuitees
  /// figees (evite la DB Drift). Le sens de marche eventuel est passe a part.
  overrides({
    required List<PlannedDay> days,
    DateTime? startDate,
    Map<int, NuiteeType> nuiteeTypes = const {},
    String? direction,
  }) =>
      [
        plannedDaysProvider(trailId).overrideWith(
          (ref) => _StaticPlannedDays(ref, days),
        ),
        planningStatsProvider(trailId).overrideWithValue(statsFor(days)),
        downloadReminderProvider(trailId).overrideWith(
          () => _FakeReminderNotifier(startDate),
        ),
        nuiteeSelectionsProvider.overrideWith(
          () => _FakeNuiteeNotifier(nuiteeTypes),
        ),
        if (direction != null)
          selectedDirectionProvider.overrideWith((ref) => direction),
      ];

  Widget wrap({
    required List<PlannedDay> days,
    DateTime? startDate,
    Map<int, NuiteeType> nuiteeTypes = const {},
    String? direction,
  }) {
    final router = GoRouter(
      initialLocation: '/s',
      routes: [
        GoRoute(
          path: '/s',
          builder: (_, __) => const PlanSummaryScreen(trailId: trailId),
        ),
        // Cible du tap « jour de marche » (detail d'etape) : ecran leger pour
        // verifier la navigation sans embarquer le vrai ecran de detail.
        GoRoute(
          path: '/stages/:num',
          builder: (_, state) => Scaffold(
            body: Center(
              child: Text('STAGE ${state.pathParameters['num']}'),
            ),
          ),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides(
        days: days,
        startDate: startDate,
        nuiteeTypes: nuiteeTypes,
        direction: direction,
      ),
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  // --- Etat vide -----------------------------------------------------------

  group('etat vide', () {
    testWidgets('aucun programme : etat vide + CTA configurer', (tester) async {
      await tester.pumpWidget(wrap(days: const []));
      await settle(tester);

      expect(find.text(t.summary.empty.title), findsOneWidget);
      expect(find.text(t.summary.empty.message), findsOneWidget);
      expect(find.text(t.summary.empty.action), findsOneWidget);
      expect(find.byIcon(Icons.summarize), findsOneWidget);
      // Aucune section (pas de « Jour par jour ») en etat vide.
      expect(find.text(t.summary.dayByDay), findsNothing);
    });
  });

  // --- Les 3 cartes alimentees par les providers --------------------------

  group('cartes config / stats / jour par jour', () {
    testWidgets('les 3 sections sont rendues depuis les providers',
        (tester) async {
      useTallSurface(tester);
      final days = [walkDay(1, 1), restDay(2), walkDay(3, 2)];
      await tester.pumpWidget(wrap(
        days: days,
        startDate: DateTime(2030, 6, 1),
      ));
      await settle(tester);

      // Carte Configuration : titre « Mon {sentier} » (displayName du sentier de
      // test) + lignes Direction / Duree / Dates.
      expect(find.textContaining('Mon '), findsWidgets);
      expect(find.text(t.summary.direction), findsOneWidget);
      expect(find.text(t.summary.duration), findsOneWidget);
      expect(find.text(t.summary.startDate), findsOneWidget);
      expect(find.text(t.summary.endDate), findsOneWidget);

      // Carte Statistiques : titre + 6 KPI.
      expect(find.text(t.summary.stats.title), findsOneWidget);
      expect(find.text(t.summary.stats.distance), findsOneWidget);
      expect(find.text(t.summary.stats.elevationGain), findsOneWidget);
      expect(find.text(t.summary.stats.elevationLoss), findsOneWidget);
      expect(find.text(t.summary.stats.duration), findsOneWidget);
      expect(find.text(t.summary.stats.stages), findsOneWidget);
      expect(find.text(t.summary.stats.restDays), findsOneWidget);

      // Section Jour par jour + un jour de repos rendu.
      expect(find.text(t.summary.dayByDay), findsOneWidget);
      expect(find.text(t.summary.restDay), findsOneWidget);
    });

    testWidgets('les stats agregees sont coherentes (distance / etapes / repos)',
        (tester) async {
      // 2 jours de marche (12 km chacun, D+ 600, D- 500) + 1 repos.
      useTallSurface(tester);
      final days = [walkDay(1, 1), walkDay(2, 2), restDay(3)];
      await tester.pumpWidget(wrap(days: days));
      await settle(tester);

      // Distance totale = 24.0 km (RichText de la carte Statistiques).
      expect(findStatValue('24.0'), findsOneWidget);
      // D+ total = 1200 m, D- total = 1000 m.
      expect(findStatValue('1200'), findsOneWidget);
      expect(findStatValue('1000'), findsOneWidget);
      // Etapes = 2, jours de repos = 1 (KPI compteurs, RichText).
      expect(findStatValue('2'), findsWidgets);
      expect(findStatValue('1'), findsWidgets);
    });
  });

  // --- Tuile jour de marche -> detail d'etape -----------------------------

  group('navigation tuile jour de marche', () {
    testWidgets('tap sur un jour de marche ouvre le detail d\'etape',
        (tester) async {
      // Jour 1 porte l'etape 5 -> tap doit pousser /stages/5.
      useTallSurface(tester);
      final days = [
        PlannedDay(dayNumber: 1, stages: [stage(5)]),
        walkDay(2, 6),
      ];
      await tester.pumpWidget(wrap(days: days));
      await settle(tester);

      // La tuile du jour 1 est semantiquement un bouton (a11y).
      final tile = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label
                    ?.contains(t.summary.a11y.dayTile(day: '1')) ??
                false),
      );
      expect(tile, findsOneWidget);
      await tester.tap(tile);
      await settle(tester);

      // La cible de detail d'etape (etape 5) est affichee.
      await pumpUntil(tester, find.text('STAGE 5'));
      expect(find.text('STAGE 5'), findsOneWidget);
    });
  });

  // --- Tuile jour de repos -> bottom sheet --------------------------------

  group('jour de repos', () {
    testWidgets('tap sur un jour de repos ouvre un bottom sheet', (tester) async {
      useTallSurface(tester);
      final days = [walkDay(1, 1), restDay(2)];
      await tester.pumpWidget(wrap(
        days: days,
        startDate: DateTime(2030, 6, 1),
      ));
      await settle(tester);

      await tester.tap(find.text(t.summary.restDay));
      await settle(tester);

      // Le bottom sheet montre le titre « Jour de repos — J2 » et un lieu (type
      // de nuitee, defaut refuge).
      expect(find.text(t.summary.restDayTitle(n: '2')), findsOneWidget);
      expect(
        find.text(t.summary.restDayPlace(place: NuiteeType.refuge.label)),
        findsOneWidget,
      );
    });
  });

  // --- Sens de marche : D+ inverse en sens retour -------------------------

  group('sens de marche', () {
    // Sentier bi-directionnel (NS / SN). Etape : D+ 800, D- 300. Dans le sens de
    // reference (NS = 1er sens du sentier de test) la tuile montre le D+ officiel
    // (+800 m) ; dans le sens inverse (SN), montee et descente s'echangent
    // (+300 m). Deux tests distincts (tree neuf) pour un override propre du
    // StateProvider global de direction.
    final directionalDays = [
      PlannedDay(dayNumber: 1, stages: [stage(1, gain: 800, loss: 300)]),
    ];

    testWidgets('sens aller (NS) : D+ du jour = D+ officiel', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(wrap(days: directionalDays, direction: 'NS'));
      await settle(tester);
      expect(find.text('+800 m'), findsOneWidget,
          reason: 'Sens aller : D+ = elevationGain (800)');
    });

    testWidgets('sens retour (SN) : D+ affiche = D- officiel', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(wrap(days: directionalDays, direction: 'SN'));
      await settle(tester);
      expect(find.text('+300 m'), findsOneWidget,
          reason: 'Sens retour : D+ affiche = D- officiel (300)');
    });
  });

  // --- Boutons d'action : stubs + partage ---------------------------------

  group('boutons d\'action', () {
    testWidgets('le stub Export PDF affiche une SnackBar « bientot »',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(wrap(days: [walkDay(1, 1)]));
      await settle(tester);

      await tester.tap(find.text(t.summary.actions.exportPdf));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(t.summary.actions.exportPdfSoon), findsOneWidget);
    });

    testWidgets('le stub Cartes offline affiche une SnackBar « bientot »',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(wrap(days: [walkDay(1, 1)]));
      await settle(tester);

      await tester.tap(find.text(t.summary.actions.downloadMaps));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(t.summary.actions.downloadMapsSoon), findsOneWidget);
    });

    testWidgets('le bouton Partager appelle share_plus avec le texte du plan',
        (tester) async {
      // Mock du canal plateforme share_plus : capture le texte partage.
      useTallSurface(tester);
      _installShareMock(tester);
      addTearDown(() => _removeShareMock(tester));

      final days = [walkDay(1, 1), restDay(2), walkDay(3, 2)];
      await tester.pumpWidget(wrap(
        days: days,
        startDate: DateTime(2030, 6, 1),
      ));
      await settle(tester);

      await tester.tap(find.text(t.summary.actions.share));
      await settle(tester);

      // share_plus a bien ete invoque une fois, avec un texte non vide contenant
      // le planning jour par jour (parite GR20) et aucun « GR20 » en dur.
      expect(_sharedTexts, hasLength(1));
      final text = _sharedTexts.single;
      expect(text, contains(t.summary.share.planning));
      expect(text, contains('J1'));
      expect(text, contains('J3'));
      expect(text, isNot(contains('GR20')));
    });
  });

  // --- Navigation depuis le HUB -------------------------------------------

  group('navigation HUB', () {
    testWidgets('la carte HUB « Resume » ouvre l\'ecran, retour sans crash',
        (tester) async {
      useTallSurface(tester);
      // Routeur minimal reproduisant l'entree HUB : une carte `Icons.summarize`
      // (comme le HUB) qui `push` vers le Resume.
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: InkWell(
                  onTap: () => context.push('/trail/$trailId/summary'),
                  child: const Icon(Icons.summarize),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/trail/:id/summary',
            builder: (context, state) => PlanSummaryScreen(
              trailId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: overrides(
          days: [walkDay(1, 1), walkDay(2, 2)],
          startDate: DateTime(2030, 6, 1),
        ),
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ));
      await settle(tester);

      // Aller : taper la carte HUB (icone summarize) ouvre le Resume.
      expect(find.byIcon(Icons.summarize), findsOneWidget);
      await tester.tap(find.byIcon(Icons.summarize));
      await settle(tester);
      await pumpUntil(tester, find.text(t.summary.title));
      expect(find.text(t.summary.title), findsWidgets);

      // Retour : bouton back de l'AppBar -> retour au HUB sans crash.
      await pumpUntil(tester, find.byIcon(Icons.arrow_back));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);
      await pumpUntilGone(tester, find.text(t.summary.title));
      expect(find.text(t.summary.title), findsNothing);
      expect(find.byIcon(Icons.summarize), findsOneWidget);
    });
  });

  // --- Helpers purs d'agregation (sens de marche) -------------------------

  group('helpers agregation (fonctions pures)', () {
    test('directionalDayStats echange D+/D- selon le sens', () {
      final day = PlannedDay(
        dayNumber: 1,
        stages: [stage(1, distanceKm: 10, gain: 700, loss: 250)],
      );
      final fwd = directionalDayStats(day, isForward: true);
      expect(fwd.km, 10);
      expect(fwd.gain, 700);
      final back = directionalDayStats(day, isForward: false);
      expect(back.km, 10, reason: 'distance invariante au sens');
      expect(back.gain, 250, reason: 'sens retour : D+ = D- officiel');
    });

    test('directionalStageTitle inverse depart/arrivee et retombe sur le nom',
        () {
      final s = stage(1, departureName: 'A', arrivalName: 'B');
      expect(directionalStageTitle(s, isForward: true), 'A -> B');
      expect(directionalStageTitle(s, isForward: false), 'B -> A');
      // Sentier pauvre (pas de noms d'endpoints) -> repli sur le nom d'etape.
      final poor = stage(2);
      expect(directionalStageTitle(poor, isForward: true), poor.name);
    });
  });
}

// --- Doubles de test ------------------------------------------------------

/// Textes captures par le mock du canal plateforme share_plus.
final List<String> _sharedTexts = <String>[];

/// Installe un mock du canal plateforme share_plus qui capture le texte partage
/// (evite `MissingPluginException` en test et permet de verifier l'appel).
void _installShareMock(WidgetTester tester) {
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (call) async {
      if (call.method == 'share' || call.method == 'shareWithResult') {
        final args = call.arguments;
        if (args is Map && args['text'] is String) {
          _sharedTexts.add(args['text'] as String);
        }
      }
      return 'dev.fluttercommunity.plus/share/success';
    },
  );
}

void _removeShareMock(WidgetTester tester) {
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
}

/// Notifier de programme statique (parite avec les tests Calendrier / Nuitees) :
/// livre une liste figee de [PlannedDay], sans pipeline stages/repartition.
class _StaticPlannedDays extends PlannedDaysNotifier {
  _StaticPlannedDays(Ref ref, List<PlannedDay> days) : super(const [], 1, ref) {
    state = days;
  }
}

/// Faux notifier de rappel : livre une date de depart deterministe (ou null)
/// sans toucher SharedPreferences (parite test Calendrier).
class _FakeReminderNotifier extends DownloadReminderNotifier {
  _FakeReminderNotifier(this._initial) : super('test_trail');

  final DateTime? _initial;

  @override
  DepartureReminderState build() =>
      DepartureReminderState(departureDate: _initial);

  @override
  Future<void> setDepartureDate(DateTime date) async {
    state = state.copyWith(departureDate: date);
  }
}

/// Faux notifier de selections de nuitees : livre des types figes par jour
/// (defaut refuge), sans toucher la DB Drift.
class _FakeNuiteeNotifier extends NuiteeSelectionsNotifier {
  _FakeNuiteeNotifier(this._types);

  final Map<int, NuiteeType> _types;

  @override
  NuiteeSelectionsState build() =>
      NuiteeSelectionsState(bookings: const {}, nuiteeTypes: _types);
}
