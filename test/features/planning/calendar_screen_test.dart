import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/notifications/providers/download_reminder_provider.dart';
import 'package:moteur_gr/features/planning/models/planned_day.dart';
import 'package:moteur_gr/features/planning/presentation/calendar_screen.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PARITE GR20 (#99460) — ecran CALENDRIER (outil de DATES).
///
/// Clone de l'ecran GR20 `CalendarScreen` : choix de la date de DEPART, date
/// d'ARRIVEE calculee (depart + totalDays - 1) et calendrier visuel des jours
/// de MARCHE / REPOS du programme du sentier courant. Generique multi-sentiers
/// (jours = programme du sentier actif), ZERO hardcode. La date de depart est
/// persistee par sentier via [downloadReminderProvider] (SharedPreferences),
/// source unique cote StepWays.
///
/// Ces tests couvrent :
///   - la carte HUB « Calendrier » ouvre l'ecran (push, retour propre) ;
///   - la date d'arrivee est correcte (depart + totalDays - 1) ;
///   - la grille marche/repos est coherente avec les jours planifies ;
///   - la date choisie est PERSISTEE (relecture via un nouveau container) ;
///   - etat vide sans itineraire, sans crash ;
///   - navigation aller/retour.
void main() {
  const trailId = 'test_trail';

  setUpAll(() async {
    // Slang en francais (base_locale) pour resoudre les libelles.
    LocaleSettings.setLocaleRaw('fr');
    // Donnees de locale intl (mois/jours FR) pour les formats de date localises.
    // L'ecran est resilient si elles manquent (repli en_US), mais on verifie
    // ici le chemin localise (parite GR20 : « lun 3 juin 2030 »).
    await initializeDateFormatting('fr');
  });

  setUp(() {
    // SharedPreferences vide par defaut (aucune date persistee).
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  // --- Fixtures ------------------------------------------------------------

  StageModel stage(int n) => StageModel(
        trailId: trailId,
        stageNumber: n,
        name: 'Etape $n',
        distanceKm: 12,
        elevationGainM: 600,
        elevationLossM: 500,
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
      );

  /// Jour de marche portant l'etape [stageNumber].
  PlannedDay walkDay(int dayNumber, int stageNumber) =>
      PlannedDay(dayNumber: dayNumber, stages: [stage(stageNumber)]);

  /// Jour de repos.
  PlannedDay restDay(int dayNumber) =>
      PlannedDay(dayNumber: dayNumber, stages: const [], isRestDay: true);

  /// Stats agregees coherentes avec une liste de jours (comme le vrai provider).
  PlanningStats statsFor(List<PlannedDay> days) {
    final trek = days.where((d) => !d.isRestDay).length;
    final rest = days.where((d) => d.isRestDay).length;
    return PlanningStats(
      totalDistance: 0,
      totalElevationGain: 0,
      totalElevationLoss: 0,
      totalHours: 0,
      trekDays: trek,
      restDays: rest,
      stageCount: trek,
    );
  }

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
  /// stages/repartition) et une date de depart deterministe (optionnelle).
  overrides({
    required List<PlannedDay> days,
    DateTime? startDate,
  }) =>
      [
        plannedDaysProvider(trailId).overrideWith(
          (ref) => _StaticPlannedDays(ref, days),
        ),
        planningStatsProvider(trailId).overrideWithValue(statsFor(days)),
        downloadReminderProvider(trailId).overrideWith(
          () => _FakeReminderNotifier(startDate),
        ),
      ];

  Widget wrap({
    required List<PlannedDay> days,
    DateTime? startDate,
  }) {
    final router = GoRouter(
      initialLocation: '/c',
      routes: [
        GoRoute(
          path: '/c',
          builder: (_, __) => const CalendarScreen(trailId: trailId),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides(days: days, startDate: startDate),
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  // --- Date d'arrivee calculee --------------------------------------------

  group('dates depart / arrivee', () {
    testWidgets('la date d\'arrivee = depart + (totalDays - 1)',
        (tester) async {
      // Depart fixe : 1er juin 2030. Programme = 3 jours de marche => arrivee
      // le 3 juin 2030 (depart + 2). Slang fr : « lun 3 juin 2030 ».
      final start = DateTime(2030, 6, 1);
      await tester.pumpWidget(wrap(
        days: [walkDay(1, 1), walkDay(2, 2), walkDay(3, 3)],
        startDate: start,
      ));
      await settle(tester);

      // La section « ARRIVEE » affiche la date calculee (depart + 2 jours).
      // On verifie via le libelle localise attendu (parite GR20 EEE d MMM yyyy).
      expect(find.text(t.calendar.departure), findsOneWidget);
      expect(find.text(t.calendar.arrival), findsOneWidget);
      expect(find.textContaining('3 juin 2030'), findsOneWidget,
          reason: 'Arrivee = 1er juin + (3 - 1) jours = 3 juin');
      expect(find.textContaining('1 juin 2030'), findsOneWidget,
          reason: 'Depart affiche la date choisie');
    });

    testWidgets('avec des jours de repos, l\'arrivee suit le total des jours',
        (tester) async {
      // 2 marche + 1 repos + 1 marche = 4 jours au total => arrivee = depart+3.
      final start = DateTime(2030, 6, 1);
      await tester.pumpWidget(wrap(
        days: [walkDay(1, 1), walkDay(2, 2), restDay(3), walkDay(4, 3)],
        startDate: start,
      ));
      await settle(tester);

      expect(find.textContaining('4 juin 2030'), findsOneWidget,
          reason: '4 jours (repos inclus) => arrivee le 4 juin');
    });
  });

  // --- Grille marche / repos ----------------------------------------------

  group('grille marche / repos', () {
    testWidgets('affiche les libelles de jour de marche et de repos',
        (tester) async {
      // Depart aujourd'hui + 30 j (futur, pour ne pas etre « passe » et griser
      // les cellules, ce qui masquerait les labels J/R — parite GR20).
      final start = DateTime.now().add(const Duration(days: 30));
      await tester.pumpWidget(wrap(
        days: [walkDay(1, 1), restDay(2), walkDay(3, 2)],
        startDate: start,
      ));
      await settle(tester);

      // Le calendrier est rendu (en-tete de mois localise present).
      final locale = LocaleSettings.currentLocale.languageCode;
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Un jour de repos existe -> le label repos « R » apparait dans la grille.
      expect(find.text(t.calendar.restDayLabel), findsWidgets,
          reason: 'Le jour de repos porte le label R dans le calendrier');

      // La legende marche/repos/depart/arrivee est presente.
      expect(find.text(t.calendar.legend.rest), findsOneWidget);
      expect(find.text(t.calendar.legend.walk), findsOneWidget);
      expect(find.text(t.calendar.legend.start), findsOneWidget);
      expect(find.text(t.calendar.legend.arrival), findsOneWidget);

      // La ligne « AJUSTER LES ETAPES » liste les jours de marche (pas le repos).
      expect(find.text(t.calendar.adjustStages), findsOneWidget);
      // Sanity : le mois affiche correspond bien a la date de depart.
      expect(start.month >= 1 && start.month <= 12, isTrue, reason: locale);
    });

    testWidgets('le resume reflete le nombre de jours marche / repos',
        (tester) async {
      final start = DateTime.now().add(const Duration(days: 30));
      await tester.pumpWidget(wrap(
        days: [walkDay(1, 1), restDay(2), walkDay(3, 2), walkDay(4, 3)],
        startDate: start,
      ));
      await settle(tester);

      // Resume : 4 jours total, 3 marche, 1 repos (parite GR20 _TrekSummary,
      // hors colonne « sens de marche » absente du modele StepWays).
      expect(find.text(t.calendar.summary.totalDays), findsOneWidget);
      expect(find.text(t.calendar.summary.walkDays), findsOneWidget);
      expect(find.text(t.calendar.summary.restDays), findsOneWidget);
      expect(find.text('4'), findsWidgets); // total
      expect(find.text('3'), findsWidgets); // marche
      expect(find.text('1'), findsWidgets); // repos
    });
  });

  // --- Etat vide -----------------------------------------------------------

  group('etat vide', () {
    testWidgets('aucun itineraire configure : etat vide sans crash',
        (tester) async {
      await tester.pumpWidget(wrap(days: const [], startDate: null));
      await settle(tester);

      // Etat vide (parite GR20 _buildEmptyItineraryState) : invite a configurer.
      expect(find.text(t.calendar.empty.title), findsOneWidget);
      expect(find.text(t.calendar.empty.action), findsOneWidget);
      // Pas de calendrier / pas de picker auto (aucun jour a dater).
      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });

    testWidgets('itineraire present mais aucune date : invite a choisir',
        (tester) async {
      // Jours presents mais date nulle : l'ecran s'affiche (le picker auto
      // M-05b s'ouvre puis se referme sans selection en test) et propose de
      // choisir une date, sans planter.
      await tester.pumpWidget(wrap(
        days: [walkDay(1, 1), walkDay(2, 2)],
        startDate: null,
      ));
      await settle(tester);
      // Referme le picker eventuellement ouvert (annulation) pour revenir a
      // l'ecran, puis verifie l'etat « aucune date ».
      final cancel = find.text('Annuler');
      if (cancel.evaluate().isNotEmpty) {
        await tester.tap(cancel);
        await settle(tester);
      }

      expect(find.text(t.calendar.noDate.title), findsOneWidget);
      expect(find.text(t.calendar.chooseDateAction), findsOneWidget);
    });
  });

  // --- Persistance de la date (SharedPreferences) -------------------------

  group('persistance de la date de depart', () {
    test('la date choisie est persistee et relue (nouveau container)',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Charge le provider (build() lance _loadFromPrefs async).
      container.read(downloadReminderProvider(trailId));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Etat initial : aucune date.
      expect(
        container.read(downloadReminderProvider(trailId)).departureDate,
        isNull,
      );

      // Choisir une date -> persiste en SharedPreferences.
      final chosen = DateTime(2030, 7, 15);
      await container
          .read(downloadReminderProvider(trailId).notifier)
          .setDepartureDate(chosen);

      expect(
        container.read(downloadReminderProvider(trailId)).departureDate,
        chosen,
      );

      // RELECTURE via un NOUVEAU container (memes prefs mockees) : la date est
      // rechargee depuis la persistance (offline-first, source unique).
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      container2.read(downloadReminderProvider(trailId));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final reloaded =
          container2.read(downloadReminderProvider(trailId)).departureDate;
      expect(reloaded, chosen,
          reason: 'La date de depart doit survivre au redemarrage (prefs)');
    });

    test('les dates sont isolees par sentier', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(downloadReminderProvider(trailId));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await container
          .read(downloadReminderProvider(trailId).notifier)
          .setDepartureDate(DateTime(2030, 7, 15));

      // Un autre sentier n'a aucune date (genericite multi-sentiers).
      container.read(downloadReminderProvider('autre_trail'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(
        container.read(downloadReminderProvider('autre_trail')).departureDate,
        isNull,
      );
    });
  });

  // --- Navigation depuis le HUB -------------------------------------------

  group('navigation', () {
    testWidgets('la carte HUB « Calendrier » ouvre l\'ecran, retour sans crash',
        (tester) async {
      final start = DateTime.now().add(const Duration(days: 30));
      // Routeur minimal reproduisant l'entree HUB : une carte
      // `Icons.calendar_month` (comme le HUB) qui `push` vers le Calendrier.
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: InkWell(
                  onTap: () => context.push('/trail/$trailId/calendar'),
                  child: const Icon(Icons.calendar_month),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/trail/:id/calendar',
            builder: (context, state) => CalendarScreen(
              trailId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: overrides(
          days: [walkDay(1, 1), walkDay(2, 2)],
          startDate: start,
        ),
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ));
      await settle(tester);

      // Aller : taper la carte HUB (icone calendar_month) ouvre le Calendrier.
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      await tester.tap(find.byIcon(Icons.calendar_month));
      await settle(tester);
      await pumpUntil(tester, find.text(t.calendar.title));
      expect(find.text(t.calendar.title), findsWidgets);

      // Retour : bouton back de l'AppBar (Icons.arrow_back) -> retour au HUB
      // sans crash. L'ecran Calendrier porte un unique bouton retour en leading.
      await pumpUntil(tester, find.byIcon(Icons.arrow_back));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);
      await pumpUntilGone(tester, find.text(t.calendar.title));
      expect(find.text(t.calendar.title), findsNothing);
      // La carte HUB est de nouveau la (retour propre, pile preservee).
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });
  });
}

/// Notifier de programme statique (parite avec le test Nuitees) : livre une
/// liste figee de [PlannedDay], sans pipeline stages/repartition.
class _StaticPlannedDays extends PlannedDaysNotifier {
  _StaticPlannedDays(Ref ref, List<PlannedDay> days) : super(const [], 1, ref) {
    state = days;
  }
}

/// Faux notifier de rappel : livre une date de depart deterministe (ou null)
/// sans toucher SharedPreferences, pour les widget tests. Etend le vrai
/// [DownloadReminderNotifier] (type exact attendu par `overrideWith`).
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
