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

  // --- Retour Chris #7 (tache 553) : la coche ne verrouille plus rien --------
  //
  // Mot pour mot : « reservation nuitee, on ne peut pas revenir a gite », puis,
  // interroge sur la coche : « NON OK = c'est bon ! ».
  //
  // Les puces de type etaient DESACTIVEES des que la nuit etait cochee, et la
  // seule explication tenait dans un `Tooltip` qui ne s'affiche pas sur mobile.
  // La coche dit « cette nuit est reglee », pas « cette nuit est verrouillee » :
  // le refuge se remplit, il faut passer en gite, et c'est precisement la que le
  // verrou tombait. Il n'y a plus de verrou — et la coche SURVIT au changement.
  group('retour Chris #7 — une nuit COCHEE reste modifiable', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    testWidgets('on revient a « gite » sans decocher, et la nuit reste cochee',
        (tester) async {
      await tester.pumpWidget(wrap(
        db: db,
        days: [walkDay(1, 1)],
        accommodations: [
          accom(1, nameFr: 'Refuge de Test', type: 'refuge'),
          accom(1, nameFr: 'Gite du Col', type: 'gite'),
        ],
      ));
      await settle(tester);
      await pumpUntil(tester, find.text('J1'));

      final refugeChip = find.text(t.nuitees.types.refuge);
      final giteChip = find.text(t.nuitees.types.gite);
      expect(refugeChip, findsWidgets);
      expect(giteChip, findsWidgets);

      final dao = NuiteeSelectionsDao(db);

      // 1. On coche la nuit (« c'est bon »). Le tap sur la carte bascule l'etat.
      await tester.tap(find.text('J1').first);
      await settle(tester);
      var rows = await dao.getByTrailId(trailId);
      expect(rows.single.isBooked, isTrue,
          reason: 'la nuit est cochee — c est l etat de depart du probleme');

      // 2. LE GESTE QUI ETAIT IMPOSSIBLE : changer le type alors que la nuit est
      //    cochee. Avant, la puce etait grisee et `onTap` valait null : ce tap ne
      //    faisait RIEN.
      await tester.tap(giteChip.last);
      await settle(tester);

      rows = await dao.getByTrailId(trailId);
      expect(rows.single.nuiteeType, NuiteeType.gite.storageKey,
          reason: 'on doit pouvoir revenir a gite sans rien decocher');

      // 3. ET LA COCHE SURVIT : changer le type n'annule pas la reservation
      //    (`setNuiteeType` et `toggleBooking` ecrivent deux champs distincts).
      expect(rows.single.isBooked, isTrue,
          reason: 'changer le type ne doit pas decocher la nuit');

      // 4. Le retour en arriere marche dans les deux sens.
      await tester.tap(refugeChip.last);
      await settle(tester);
      rows = await dao.getByTrailId(trailId);
      expect(rows.single.nuiteeType, NuiteeType.refuge.storageKey);
      expect(rows.single.isBooked, isTrue);
    });

    testWidgets('plus aucune puce grisee ni indice invisible sur une nuit cochee',
        (tester) async {
      await tester.pumpWidget(wrap(
        db: db,
        days: [walkDay(1, 1)],
        accommodations: [
          accom(1, nameFr: 'Refuge de Test', type: 'refuge'),
          accom(1, nameFr: 'Gite du Col', type: 'gite'),
        ],
      ));
      await settle(tester);
      await pumpUntil(tester, find.text('J1'));

      await tester.tap(find.text('J1').first);
      await settle(tester);

      // L'attenuation a 35 % des puces non selectionnees a disparu : plus rien
      // dans la carte ne fait croire a un verrou.
      final opacites = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((o) => o.opacity < 1.0);
      expect(opacites, isEmpty,
          reason: 'aucune puce de type ne doit plus etre grisee');

      // Et le `Tooltip` « decochez pour changer le type » — qui ne s'affichait
      // jamais sur mobile — n'est plus monte nulle part.
      expect(find.byTooltip(t.nuitees.card.lockedHint), findsNothing);
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

    // R5 (retour Chris, LOT L10) — INVERSION ASSUMEE DE L'ATTENTE PRECEDENTE.
    // Ce test verrouillait « les jours de repos ne comptent pas comme des
    // nuits » : c'etait le BUG. Un jour de repos, on dort quand meme — GR20 le
    // comptabilise (jour precedent a `nightCount` 2). L'ancien filtre faisait
    // donc perdre une nuit au randonneur sur son planning de reservation.
    testWidgets('la nuit du JOUR DE REPOS est comptee (parite GR20)',
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

      // Les 3 nuits apparaissent, J2 (repos) COMPRISE.
      expect(find.text('J1'), findsWidgets);
      expect(find.text('J2'), findsWidgets,
          reason: 'La nuit du jour de repos ne doit plus disparaitre');
      expect(find.text('J3'), findsWidgets);

      // Et elle est explicitement identifiee comme un jour de repos (sinon deux
      // lignes afficheraient le meme hebergement sans explication).
      expect(find.text(t.programme.restDay), findsWidgets);
    });

    // L7-2 — LA NUIT DE LA VEILLE DU DEPART EXISTE A L ECRAN.
    // Elle manquait a l assistant : on arrive la veille au point de depart et
    // on y dort, mais cette nuit-la n apparaissait nulle part dans la liste
    // des nuits a reserver.
    testWidgets('la nuit N0 (veille du depart) ouvre la liste et se dit',
        (tester) async {
      await tester.pumpWidget(wrap(
        db: db,
        days: [walkDay(1, 1), walkDay(2, 2)],
        accommodations: const [],
      ));
      await settle(tester);
      await pumpUntil(tester, find.text('J1'));

      // Badge propre : pas un « J0 », qui ne voudrait rien dire.
      expect(find.text(t.nuitees.card.eveBadge), findsWidgets);
      expect(find.text('J0'), findsNothing);
      // Et elle est nommee, sinon la premiere ligne ressemblerait a une nuit
      // de marche sans hebergement renseigne.
      expect(find.text(t.nuitees.card.eveOfDeparture), findsWidgets);
      // Les nuits des jours de marche restent la.
      expect(find.text('J1'), findsWidgets);
      expect(find.text('J2'), findsWidgets);
    });

    test('buildNuiteeSlots : un repos herite du lieu du dernier jour marche',
        () {
      final slots = buildNuiteeSlots([
        walkDay(1, 1),
        const PlannedDay(dayNumber: 2, stages: [], isRestDay: true),
        walkDay(3, 2),
      ]);

      // L7-2 : la liste ouvre sur la nuit N0 (veille du depart), puis les
      // 3 jours -> 3 nuits, la nuit du repos comprise. Total 4.
      expect(slots.length, 4);
      expect(slots[0].isEveOfDeparture, isTrue);
      expect(slots[1].stageNumber, 1);
      // Le repos dort au MEME endroit que la veille : etape d'arrivee du J1.
      expect(slots[2].day.isRestDay, isTrue);
      expect(slots[2].stageNumber, 1);
      expect(slots[3].stageNumber, 2);
    });

    test('buildNuiteeSlots : un repos en tete de programme ne plante pas', () {
      final slots = buildNuiteeSlots([
        const PlannedDay(dayNumber: 1, stages: [], isRestDay: true),
        walkDay(2, 1),
      ]);

      // Nuit N0 en tete (L7-2), puis les deux jours du programme.
      expect(slots.length, 3);
      expect(slots[0].isEveOfDeparture, isTrue);
      // Aucun jour marche avant -> pas d'etape connue, repli gracieux sur 0
      // (l'ecran affichera le libelle generique d'hebergement).
      expect(slots[1].stageNumber, 0);
      expect(slots[2].stageNumber, 1);
    });

    // --- Correctif L7-2 : la nuit de la veille du depart ------------------
    test('buildNuiteeSlots : la nuit N0 ouvre la liste et ne depend d aucune '
        'etape', () {
      final slots = buildNuiteeSlots([walkDay(1, 1), walkDay(2, 2)]);

      expect(slots.length, 3, reason: '2 jours de marche + la veille');
      final n0 = slots.first;
      expect(n0.isEveOfDeparture, isTrue);
      expect(n0.day.dayNumber, kEveOfDepartureDayNumber);
      expect(n0.day.isRestDay, isFalse);
      // On dort au DEPART de la premiere etape, pas a son arrivee : aucune
      // etape n est rattachee, l ecran affiche son libelle generique plutot
      // que de proposer le mauvais village.
      expect(n0.stageNumber, 0);
      // Les nuits suivantes restent celles des jours de marche.
      expect(slots[1].isEveOfDeparture, isFalse);
      expect(slots[1].stageNumber, 1);
      expect(slots[2].stageNumber, 2);
    });

    test('buildNuiteeSlots : aucun programme, aucune nuit — pas meme la N0',
        () {
      expect(buildNuiteeSlots(const []), isEmpty);
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

      // Retour : bouton back de l'AppHeader (Ph5/L6b — tooltip Slang `nav.back`,
      // « Retour » en locale par defaut fr) -> retour au HUB sans crash.
      await pumpUntil(tester, find.byTooltip(t.nav.back));
      await tester.tap(find.byTooltip(t.nav.back));
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
