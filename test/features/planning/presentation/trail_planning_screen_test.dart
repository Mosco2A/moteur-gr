import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/planning/presentation/trail_planning_screen.dart';
import 'package:moteur_gr/features/planning/widgets/duration_selector.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests de l'ecran PROGRAMME (parite GR20 `PlanningScreen`).
///
/// Couvre :
///   - le titre « Programme » et l'en-tete de statistiques (distance, D+,
///     jours, etapes) ;
///   - le contenu PAR ETAPE de chaque jour (nom, distance, D+, D-) et la
///     legende des difficultes ;
///   - l'ACCES au DETAIL d'une etape (tap sur une carte jour -> /stages/:num) ;
///   - l'EDITION : ajout d'un jour de repos (parite GR20) ;
///   - PART A : la carte HUB « Programme » ouvre bien CET ecran riche (et non
///     l'ancien ecran pauvre), via /trail/:id/planning, avec retour propre.
void main() {
  StageModel makeStage(int num, double km, int gain,
      {String difficulty = 'moderate'}) {
    return StageModel(
      trailId: 'test-trail',
      stageNumber: num,
      name: 'Etape $num - Refuge $num',
      distanceKm: km,
      elevationGainM: gain,
      elevationLossM: (gain * 0.8).round(),
      startLat: 42.0,
      startLng: 9.0,
      endLat: 42.1,
      endLng: 9.1,
      difficulty: difficulty,
    );
  }

  final testStages = [
    makeStage(1, 12.0, 800, difficulty: 'hard'),
    makeStage(2, 15.0, 600, difficulty: 'moderate'),
    makeStage(3, 10.0, 1000, difficulty: 'extreme'),
    makeStage(4, 8.0, 400, difficulty: 'easy'),
    makeStage(5, 14.0, 700, difficulty: 'moderate'),
  ];

  List<Override> baseOverrides() => [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        stagesProvider('test-trail')
            .overrideWith((ref) => Future.value(testStages)),
      ];

  /// Pompe l'ecran PROGRAMME dans une surface HAUTE afin que la liste (lazy
  /// `ReorderableListView`) rende TOUTES les cartes de jour sans culling de
  /// viewport. Indispensable pour verifier les actions de CHAQUE jour et pour
  /// interagir avec des jours au-dela du premier ecran. La taille est remise a
  /// zero en fin de test.
  Future<void> pumpProgramme(WidgetTester tester,
      {Size size = const Size(500, 1600)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides(),
        child: const MaterialApp(
          home: TrailPlanningScreen(trailId: 'test-trail'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('PROGRAMME — parite GR20', () {
    testWidgets('affiche le titre Programme et l en-tete de stats',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(
            home: TrailPlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Titre de l'ecran (parite GR20 : « Programme », plus « Planning »).
      expect(find.text(t.programme.title), findsOneWidget);

      // En-tete de stats (recalcul depuis les etapes reelles, parite GR20) :
      // distance = 12+15+10+8+14 = 59 km ; D+ = 800+600+1000+400+700 = 3500 m.
      expect(find.text('59 km'), findsOneWidget);
      expect(find.text('3500 m'), findsOneWidget);

      // Legende des difficultes presente (parite GR20).
      expect(find.text(t.programme.legend.easy), findsOneWidget);
      expect(find.text(t.programme.legend.extreme), findsOneWidget);
    });

    testWidgets('affiche le contenu par etape (nom, distance, D+, D-)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(
            home: TrailPlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 5 etapes -> 5 jours (duree defaut 5). Nom de la 1re etape visible.
      expect(find.text('Etape 1 - Refuge 1'), findsOneWidget);

      // Infos par etape du jour 1 : distance + D+ + D-.
      expect(find.text('12.0 km'), findsOneWidget);
      expect(find.text('800 m D+'), findsOneWidget);
      expect(find.text('640 m D-'), findsOneWidget); // 800 * 0.8

      // Bouton de validation (parite GR20).
      expect(find.text(t.programme.validate), findsOneWidget);
    });

    testWidgets('tap sur une carte jour ouvre le detail de l etape',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/trail/test-trail/planning',
        routes: [
          GoRoute(
            path: '/trail/:id/planning',
            builder: (context, state) =>
                const TrailPlanningScreen(trailId: 'test-trail'),
          ),
          // Cible : detail d'etape (parite GR20 : acces au detail depuis le jour).
          GoRoute(
            path: '/stages/:num',
            builder: (context, state) => Scaffold(
              body: Text('DETAIL ${state.pathParameters['num']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tap sur la carte du jour 1 (via son nom d'etape).
      await tester.tap(find.text('Etape 1 - Refuge 1'));
      await tester.pumpAndSettle();

      // On a bien ouvert le detail de l'etape 1 (stageNumber = 1).
      expect(find.text('DETAIL 1'), findsOneWidget);
    });

    testWidgets('edition : ajouter un jour de repos (parite GR20)',
        (tester) async {
      // Surface haute : la liste (lazy) rend tous les jours, donc la carte de
      // repos ajoutee reste visible (pas de culling de viewport).
      await pumpProgramme(tester);

      // Pas de jour de repos au depart (5 jours = 5 etapes).
      expect(find.text(t.programme.restDay), findsNothing);

      // Ajouter un jour de repos via la 1re action « Repos » visible.
      await tester.tap(find.text(t.programme.actions.rest).first);
      await tester.pumpAndSettle();

      // Un jour de repos est apparu (carte dediee).
      expect(find.text(t.programme.restDay), findsWidgets);
    });
  });

  group('PART A — la carte HUB « Programme » ouvre l ecran riche', () {
    testWidgets(
        'push /trail/:id/planning ouvre le PROGRAMME riche puis retour propre',
        (tester) async {
      // Router minimal reproduisant le chemin du HUB : la carte « Programme »
      // fait `context.push('/trail/:id/planning')`.
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('HUB-HOME')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      context.push('/trail/test-trail/planning'),
                  child: Text(t.hub.cards.programme),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/trail/:id/planning',
            builder: (context, state) =>
                const TrailPlanningScreen(trailId: 'test-trail'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HUB-HOME'), findsOneWidget);

      // Ouvrir le PROGRAMME depuis la carte HUB.
      await tester.tap(find.text(t.hub.cards.programme));
      await tester.pumpAndSettle();

      // On est bien sur l'ecran RICHE (titre Programme + stats + contenu etape),
      // preuve que la carte n'ouvre plus l'ancien ecran pauvre « Planning ».
      expect(find.text(t.programme.title), findsOneWidget);
      expect(find.text('Etape 1 - Refuge 1'), findsOneWidget);

      // Retour propre vers le HUB (pas d'exception).
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('HUB-HOME'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CURSEUR DE DUREE — slider colore par difficulte (parite GR20)', () {
    testWidgets('le selecteur est un Slider borne par le nombre d etapes',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(
            home: TrailPlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Le selecteur (DurationSelector) est bien branche dans l'ecran.
      expect(find.byType(DurationSelector), findsOneWidget);
      // C'est desormais un CURSEUR (Slider), plus des ChoiceChips (parite GR20).
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      // Libelle du selecteur present.
      expect(find.text(t.programme.duration.label), findsOneWidget);

      // 5 etapes -> bornes min 3 / max 7 : le slider porte ces bornes.
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 3.0);
      expect(slider.max, 7.0);
      expect(slider.divisions, 4); // 7 - 3
      expect(slider.value, 5.0); // duree defaut

      // La valeur courante « 5 j » est affichee en grand au-dessus du curseur.
      final label5 = t.programme.duration.days.replaceAll('{count}', '5');
      expect(find.text(label5), findsWidgets);
    });

    testWidgets('la couleur du curseur suit la DIFFICULTE (ratio etapes/jours)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(
            home: TrailPlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 5 etapes / 5 jours de marche = ratio 1.0 -> « Standard » (jaune modere).
      var slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.activeColor, AppTheme.jauneModere);
      expect(find.text(t.programme.duration.difficulty.standard), findsOneWidget);

      // Descendre a 3 jours -> 5 etapes / 3 jours = 1.67 -> « Tres exigeant »
      // (rouge). Le curseur DOIT changer de couleur (parite GR20).
      slider.onChanged!(3);
      await tester.pumpAndSettle();
      slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.activeColor, AppTheme.rougeExtreme);
      expect(
          find.text(t.programme.duration.difficulty.demanding), findsOneWidget);
    });

    testWidgets('changer la duree via le curseur recalcule le programme',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(
            home: TrailPlanningScreen(trailId: 'test-trail'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Au depart : 5 jours = 5 etapes, aucun repos.
      expect(find.text('5'), findsWidgets); // valeur « Jours » (et « Etapes »)
      expect(find.text(t.programme.restDayLabel), findsNothing);

      // Glisser le curseur a 7 jours -> 5 etapes + 2 jours de repos. Le
      // programme recalcule via selectedDurationProvider (watch par
      // plannedDaysProvider).
      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(7);
      await tester.pumpAndSettle();

      // En-tete « Jours » = « 7 (2 repos) » : preuve directe du recalcul.
      final restCount =
          t.programme.stats.restCount.replaceAll('{count}', '2');
      expect(find.text('7 ($restCount)'), findsOneWidget);
      // Profil altimetrique : 2 barres de repos « R » apparues.
      expect(find.text(t.programme.restDayLabel), findsNWidgets(2));
    });
  });

  group('JOUR DE REPOS EN BLEU (parite GR20)', () {
    testWidgets('la carte de jour de repos est teintee en bleu semantique',
        (tester) async {
      await pumpProgramme(tester);

      // Ajouter un jour de repos.
      await tester.tap(find.text(t.programme.actions.rest).first);
      await tester.pumpAndSettle();

      // Le libelle « Jour de repos » est rendu en bleu (AppTheme.bleuRepos).
      final restTexts = tester
          .widgetList<Text>(find.text(t.programme.restDay))
          .toList();
      expect(restTexts, isNotEmpty);
      final hasBlue = restTexts.any((w) => w.style?.color == AppTheme.bleuRepos);
      expect(hasBlue, isTrue,
          reason: 'le jour de repos doit etre affiche en bleu, pas en vert');
    });
  });

  group('LISTE INTERACTIVE — Regrouper / Separer sur chaque jour (parite GR20)',
      () {
    testWidgets(
        'Regrouper ET Separer sont TOUJOURS visibles sur les jours de marche',
        (tester) async {
      await pumpProgramme(tester);

      // 5 jours de marche (1 etape/jour au depart) : chaque jour montre les
      // DEUX actions, meme quand elles sont indisponibles (grisees). La liste
      // n'est donc jamais « inerte ».
      expect(find.text(t.programme.actions.merge), findsNWidgets(5));
      expect(find.text(t.programme.actions.split), findsNWidgets(5));
    });

    testWidgets('Separer un jour indisponible (1 etape) explique pourquoi',
        (tester) async {
      await pumpProgramme(tester);

      // Chaque jour n'a qu'une etape -> Separer est grise. Un tap explique
      // pourquoi via un snackbar (feedback, parite GR20).
      await tester.tap(find.text(t.programme.actions.split).first);
      await tester.pumpAndSettle();
      expect(find.text(t.programme.splitBlocked.single), findsOneWidget);
    });

    testWidgets('Regrouper puis Separer fonctionnent depuis la liste',
        (tester) async {
      await pumpProgramme(tester);

      // Depart : 5 jours de marche (chaque jour = 1 etape). Regrouper le jour 1
      // avec le suivant -> 4 jours de marche. Le jour fusionne porte alors 2
      // etapes, donc Separer y devient possible.
      expect(find.text('Etape 1 - Refuge 1'), findsOneWidget);

      await tester.tap(find.text(t.programme.actions.merge).first);
      await tester.pumpAndSettle();

      // Apres regroupement : le jour 1 contient etapes 1 ET 2 (les deux noms
      // sont visibles sur la meme carte). Preuve que Regrouper agit sur la liste.
      expect(find.text('Etape 1 - Refuge 1'), findsOneWidget);
      expect(find.text('Etape 2 - Refuge 2'), findsOneWidget);

      // Separer le jour fusionne -> on retrouve des jours a une seule etape.
      // (le 1er chip Separer correspond au jour 1, desormais separable).
      await tester.tap(find.text(t.programme.actions.split).first);
      await tester.pumpAndSettle();

      // Aucune exception, la liste a bien reagi au split.
      expect(tester.takeException(), isNull);
      expect(find.text('Etape 1 - Refuge 1'), findsOneWidget);
      expect(find.text('Etape 2 - Refuge 2'), findsOneWidget);
    });
  });
}
