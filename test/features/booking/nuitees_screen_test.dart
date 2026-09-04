import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/daos/nuitee_selections_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/booking/domain/models/nuitee_type.dart';
import 'package:moteur_gr/features/booking/presentation/nuitees_screen.dart';
import 'package:moteur_gr/features/booking/providers/nuitee_selections_provider.dart';
import 'package:moteur_gr/features/planning/models/planned_day.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/trail/domain/trail_data_provider.dart';
import 'package:moteur_gr/features/trail/providers/trail_providers.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/features/trek/domain/models/stage_accommodation.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// PARITE GR20 (#99460) — ecran NUITEES (assistant « Reserver vos nuits »).
///
/// Clone de l'ecran GR20 `RefugeAssistantScreen` : pour chaque nuit du
/// programme, choix d'un type de nuitee (refuge / gite / bivouac / autre) +
/// etat reserve, persiste en LOCAL (Drift, table nuitee_selections). Alimente
/// par les donnees du sentier (module booking), generique multi-sentiers,
/// fallback gracieux si aucun hebergement.
///
/// Ces tests couvrent, cote StepWays :
///   - la carte HUB « Nuitees » ouvre l'ecran (push, retour propre) ;
///   - type + etat reserve PERSISTES (relecture DB via une nouvelle instance) ;
///   - donnees par sentier (noms d'hebergement issus du data provider) ;
///   - fallback sans donnees (libelle generique + etat vide sans programme) ;
///   - navigation aller/retour sans crash.
void main() {
  const trailId = 'test_trail';

  setUpAll(() {
    // Slang en francais (base_locale) pour resoudre les libelles.
    LocaleSettings.setLocaleRaw('fr');
  });

  // --- Fixtures ------------------------------------------------------------

  /// Etape minimale (seul `stageNumber` importe pour rattacher l'hebergement).
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

  /// Jour de marche (une nuit) portant l'etape d'arrivee [n].
  PlannedDay walkDay(int dayNumber, int stageNumber) =>
      PlannedDay(dayNumber: dayNumber, stages: [stage(stageNumber)]);

  /// Hebergement de test rattache a l'etape [stageNumber].
  StageAccommodation accom(
    int stageNumber, {
    required String nameFr,
    required String type,
    String? phone,
  }) =>
      StageAccommodation(
        id: '$stageNumber-$type',
        stageId: 'stage-$stageNumber',
        stageNumber: stageNumber,
        nameFr: nameFr,
        type: type,
        lat: 0,
        lng: 0,
        phone: phone,
      );

  /// Faux [TrailDataProvider] : ne sert que les hebergements par (trail, etape).
  /// Genericite : aucune donnee en dur dans le moteur, tout vient d'ici.
  TrailDataProvider fakeData(List<StageAccommodation> all) => _FakeTrailData(all);

  /// Fait avancer le temps par petits pas bornes, SANS `pumpAndSettle`
  /// (l'ecran charge des FutureProvider — pas de « repos » garanti).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Pompe (borne) jusqu'a ce que [finder] trouve au moins [minMatches]
  /// widgets, ou jusqu'a [maxFrames] frames. Laisse les FutureProvider se
  /// resoudre sur plusieurs frames sans attendre un repos qui n'arrive pas.
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

  /// Pompe (borne) jusqu'a ce que [finder] ne trouve PLUS aucun widget (fin
  /// d'une transition de pop, par ex.), ou jusqu'a [maxFrames] frames.
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

  /// Overrides communs : DB in-memory, trailId deterministe, programme et
  /// donnees d'hebergement injectes (deterministe, sans I/O asynchrone).
  overrides({
    required AppDatabase db,
    required List<PlannedDay> days,
    required List<StageAccommodation> accommodations,
  }) =>
      [
        databaseProvider.overrideWithValue(db),
        // `trailIdProvider` pilote le sentier actif lu par le notifier de
        // selections (persistance par sentier).
        trailIdProvider.overrideWithValue(trailId),
        // Programme fige (evite tout le pipeline stages/repartition).
        plannedDaysProvider(trailId).overrideWith(
          (ref) => _StaticPlannedDays(ref, days),
        ),
        // Source de donnees du sentier (hebergements par etape).
        trailDataProvider.overrideWithValue(fakeData(accommodations)),
      ];

  /// Enveloppe [child] avec ProviderScope + Translations + un GoRouter minimal.
  Widget wrap({
    required AppDatabase db,
    required List<PlannedDay> days,
    required List<StageAccommodation> accommodations,
    Widget? child,
  }) {
    final router = GoRouter(
      initialLocation: '/n',
      routes: [
        GoRoute(
          path: '/n',
          builder: (_, __) =>
              child ?? const NuiteesScreen(trailId: trailId),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides(db: db, days: days, accommodations: accommodations),
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  // --- Persistance (relecture DB) -----------------------------------------

  group('persistance des selections (Drift)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        trailIdProvider.overrideWithValue(trailId),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('type + etat reserve persistes et relus depuis la DB', () async {
      // Charger le provider (build() lance _load() asynchrone).
      container.read(nuiteeSelectionsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Etat initial : rien de reserve, type par defaut = refuge.
      var state = container.read(nuiteeSelectionsProvider);
      expect(state.isBooked(1), false);
      expect(state.typeFor(1), NuiteeType.refuge);

      // Choisir un type (gite) pour la nuit 1 + reserver.
      await container
          .read(nuiteeSelectionsProvider.notifier)
          .setNuiteeType(1, NuiteeType.gite);
      await container
          .read(nuiteeSelectionsProvider.notifier)
          .toggleBooking(1);

      // Reserver aussi la nuit 2 en bivouac.
      await container
          .read(nuiteeSelectionsProvider.notifier)
          .setNuiteeType(2, NuiteeType.bivouac);
      await container
          .read(nuiteeSelectionsProvider.notifier)
          .toggleBooking(2);

      // Etat en memoire coherent.
      state = container.read(nuiteeSelectionsProvider);
      expect(state.typeFor(1), NuiteeType.gite);
      expect(state.isBooked(1), true);
      expect(state.typeFor(2), NuiteeType.bivouac);
      expect(state.bookedCount, 2);

      // RELECTURE DB directe : les lignes sont bien persistees.
      final dao = NuiteeSelectionsDao(db);
      final rows = await dao.getByTrailId(trailId);
      final row1 = rows.firstWhere((r) => r.dayNumber == 1);
      final row2 = rows.firstWhere((r) => r.dayNumber == 2);
      expect(row1.isBooked, true);
      expect(row1.nuiteeType, NuiteeType.gite.storageKey);
      expect(row2.isBooked, true);
      expect(row2.nuiteeType, NuiteeType.bivouac.storageKey);

      // RELECTURE via un NOUVEAU container (meme DB) : l'etat est rechargle
      // depuis la persistance (offline-first, comme la checklist).
      final container2 = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        trailIdProvider.overrideWithValue(trailId),
      ]);
      addTearDown(container2.dispose);
      container2.read(nuiteeSelectionsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final reloaded = container2.read(nuiteeSelectionsProvider);
      expect(reloaded.typeFor(1), NuiteeType.gite);
      expect(reloaded.isBooked(1), true);
      expect(reloaded.typeFor(2), NuiteeType.bivouac);
      expect(reloaded.isBooked(2), true);
    });

    test('decochage persiste aussi (retour a non reserve)', () async {
      container.read(nuiteeSelectionsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final notifier = container.read(nuiteeSelectionsProvider.notifier);
      await notifier.toggleBooking(1); // reserve
      await notifier.toggleBooking(1); // annule

      expect(container.read(nuiteeSelectionsProvider).isBooked(1), false);

      final dao = NuiteeSelectionsDao(db);
      final rows = await dao.getByTrailId(trailId);
      final row1 = rows.firstWhere((r) => r.dayNumber == 1);
      expect(row1.isBooked, false,
          reason: 'Le decochage doit aussi persister en DB');
    });

    test('les selections sont isolees par sentier', () async {
      // Ecrit sur le sentier actif (test_trail) via le notifier...
      container.read(nuiteeSelectionsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await container
          .read(nuiteeSelectionsProvider.notifier)
          .toggleBooking(1);

      // ... un AUTRE sentier n'a aucune selection (genericite multi-sentiers).
      final dao = NuiteeSelectionsDao(db);
      final otherRows = await dao.getByTrailId('autre_trail');
      expect(otherRows, isEmpty);
      final ownRows = await dao.getByTrailId(trailId);
      expect(ownRows, isNotEmpty);
    });
  });

  // --- Donnees par sentier -------------------------------------------------

  group('donnees par sentier', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    testWidgets('affiche les noms d\'hebergement issus des donnees du sentier',
        (tester) async {
      await tester.pumpWidget(wrap(
        db: db,
        days: [walkDay(1, 1), walkDay(2, 2)],
        accommodations: [
          accom(1, nameFr: 'Refuge de Test', type: 'refuge', phone: '0102030405'),
          accom(2, nameFr: 'Gite du Col', type: 'gite'),
        ],
      ));
      await settle(tester);

      // Titre de l'ecran (Slang) present.
      expect(find.text(t.nuitees.title), findsWidgets);

      // Les noms REELS des hebergements (par etape) s'affichent — donc c'est
      // bien alimente par le data provider du sentier, pas du hardcode.
      await pumpUntil(tester, find.text('Refuge de Test'));
      expect(find.text('Refuge de Test'), findsOneWidget);
      expect(find.text('Gite du Col'), findsOneWidget);

      // Deux nuits (J1 / J2) sont listees.
      expect(find.text('J1'), findsWidgets);
      expect(find.text('J2'), findsWidgets);

      // Une action « Appeler » apparait pour l'hebergement qui a un telephone.
      expect(
        find.textContaining(t.nuitees.card.call.replaceAll('{phone}', '')),
        findsWidgets,
      );
    });
  });

  // --- Fallback sans donnees ----------------------------------------------

  group('fallback sans donnees', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    testWidgets('libelle generique quand le sentier n\'a aucun hebergement',
        (tester) async {
      await tester.pumpWidget(wrap(
        db: db,
        days: [walkDay(1, 1)],
        accommodations: const [], // sentier sans donnees d'hebergement
      ));
      await settle(tester);

      // La nuit est listee (J1) mais avec le libelle generique de repli.
      await pumpUntil(tester, find.text('J1'));
      expect(find.text('J1'), findsWidgets);
      expect(find.text(t.nuitees.card.noPlace), findsWidgets,
          reason: 'Fallback gracieux : libelle generique sans donnees');
    });

    testWidgets('etat vide quand le programme n\'a aucune nuit',
        (tester) async {
      await tester.pumpWidget(wrap(
        db: db,
        days: const [], // aucun jour de marche
        accommodations: const [],
      ));
      await settle(tester);

      // Etat vide (parite GR20 `_buildEmptyState`) : invite a configurer.
      expect(find.text(t.nuitees.empty.title), findsOneWidget);
      expect(find.text(t.nuitees.empty.action), findsOneWidget);
    });

    testWidgets('les jours de repos ne comptent pas comme des nuits',
        (tester) async {
      await tester.pumpWidget(wrap(
        db: db,
        days: [
          walkDay(1, 1),
          const PlannedDay(dayNumber: 2, stages: [], isRestDay: true),
          walkDay(3, 2),
        ],
        accommodations: const [],
      ));
      await settle(tester);
      await pumpUntil(tester, find.text('J1'));

      // Seules les 2 nuits de marche apparaissent (J1, J3) — pas J2 (repos).
      expect(find.text('J1'), findsWidgets);
      expect(find.text('J3'), findsWidgets);
      expect(find.text('J2'), findsNothing);
    });
  });

  // --- Navigation depuis le HUB -------------------------------------------

  group('navigation', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    testWidgets('la carte HUB « Nuitees » ouvre l\'ecran, retour sans crash',
        (tester) async {
      // Routeur minimal reproduisant l'entree HUB : une carte `Icons.cabin`
      // (comme le HUB) qui `push` vers l'ecran Nuitees, puis retour.
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                // Meme geste que la carte HUB reelle (Icons.cabin + push).
                child: InkWell(
                  onTap: () => context.push('/trail/$trailId/nuitees'),
                  child: const Icon(Icons.cabin),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/trail/:id/nuitees',
            builder: (context, state) => NuiteesScreen(
              trailId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: overrides(
          db: db,
          days: [walkDay(1, 1)],
          accommodations: [
            accom(1, nameFr: 'Refuge de Test', type: 'refuge'),
          ],
        ),
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ));
      await settle(tester);

      // Aller : taper la carte HUB (icone cabin) ouvre l'ecran Nuitees.
      expect(find.byIcon(Icons.cabin), findsOneWidget);
      await tester.tap(find.byIcon(Icons.cabin));
      await settle(tester);
      await pumpUntil(tester, find.text(t.nuitees.title));
      expect(find.text(t.nuitees.title), findsWidgets);

      // Retour : bouton back de l'AppBar -> retour au HUB sans crash.
      await pumpUntil(tester, find.byTooltip('Back'));
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      // On attend (borne) la fin de la transition de pop : l'ecran Nuitees a
      // disparu (son titre AppBar n'est plus rendu). NB : `Icons.cabin` sert
      // AUSSI d'icone du type « refuge » DANS l'ecran ; on ne compte donc pas
      // les icones cabin mais on verifie le retour propre par l'absence du
      // titre de l'ecran puis la presence de la carte HUB.
      await pumpUntilGone(tester, find.text(t.nuitees.title));
      expect(find.text(t.nuitees.title), findsNothing);
      expect(find.byIcon(Icons.cabin), findsOneWidget);
    });
  });
}

/// Faux [TrailDataProvider] pour les tests : sert des hebergements en memoire
/// filtres par etape. Aucune donnee en dur cote moteur — tout vient d'ici.
class _FakeTrailData implements TrailDataProvider {
  _FakeTrailData(this._accommodations);

  final List<StageAccommodation> _accommodations;

  @override
  Future<List<StageAccommodation>> getAccommodations(
    String trailId, {
    int? stageNumber,
  }) async {
    if (stageNumber == null) return _accommodations;
    return _accommodations
        .where((a) => a.stageNumber == stageNumber)
        .toList();
  }

  @override
  Future<List<StageModel>> getStages(String trailId) async => const [];

  @override
  Future<List<TrackPoint>> getTrackPoints(String stageId) async => const [];

  @override
  TrailConfig getTrailConfig() => throw UnimplementedError();
}

/// Notifier de programme statique : livre une liste figee de [PlannedDay]
/// (evite le pipeline stages/repartition, deterministe pour les widget tests).
/// Etend [PlannedDaysNotifier] (type exact attendu par `overrideWith`) mais
/// part d'etapes vides, puis force l'etat sur la liste fournie — aucun calcul
/// de repartition, aucune dependance aux etapes reelles.
class _StaticPlannedDays extends PlannedDaysNotifier {
  _StaticPlannedDays(Ref ref, List<PlannedDay> days)
      : super(const [], 1, ref) {
    state = days;
  }
}
