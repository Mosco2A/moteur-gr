import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';
import 'package:moteur_gr/features/checklist/presentation/checklist_screen.dart';
import 'package:moteur_gr/features/checklist/providers/checklist_provider.dart';
import 'package:moteur_gr/features/checklist/widgets/checklist_weight_banner.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests du VOLET POIDS de la checklist (PARITE GR20 « Materiel & Sac » #99433).
///
/// Verifie l ecart connu reintegre cote StepWays :
///   - le poids par article (persiste depuis le template + editable) ;
///   - le poids TOTAL du sac (somme des articles coches) et le ratio sac/corps ;
///   - la persistence du poids en DB (colonne weightGrams, migration v19).
void main() {
  const testTrail = TrailConfig(
    id: 'test_trail',
    name: 'Test Trail',
    displayName: 'Test',
    tagline: 'Test tagline',
    totalStages: 5,
    totalDistanceKm: 50.0,
    totalElevationGain: 3000,
    region: 'Test Region',
    country: 'France',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/test.gpx',
    defaultDuration: 5,
    availableDurations: [3, 5, 7],
  );

  group('PARITE GR20 — poids du sac (provider + DB)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(testTrail),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('le poids de reference du template est initialise en DB', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Le sac a dos a un poids de reference non nul (parite GR20).
      final backpackTpl = defaultChecklistTemplate
          .firstWhere((i) => i.id == 'backpack');
      expect(backpackTpl.weightGrams, greaterThan(0));

      final dao = ChecklistDao(db);
      final rows = await dao.getByTrailId('test_trail');
      final backpackRow = rows.firstWhere((r) => r.itemId == 'backpack');
      expect(backpackRow.weightGrams, backpackTpl.weightGrams,
          reason: 'Le poids de reference doit etre persiste a l init');
    });

    test('le poids total = somme des articles COCHES', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Rien de coche -> total 0.
      expect(container.read(checklistProvider).checkedWeightGrams, 0);

      // Cocher le sac a dos -> total = son poids.
      await container.read(checklistProvider.notifier).toggle('backpack');
      final backpackWeight = defaultChecklistTemplate
          .firstWhere((i) => i.id == 'backpack')
          .weightGrams;
      expect(container.read(checklistProvider).checkedWeightGrams,
          backpackWeight);

      // Cocher la lampe frontale -> total cumule.
      await container.read(checklistProvider.notifier).toggle('headlamp');
      final headlampWeight = defaultChecklistTemplate
          .firstWhere((i) => i.id == 'headlamp')
          .weightGrams;
      expect(container.read(checklistProvider).checkedWeightGrams,
          backpackWeight + headlampWeight);
    });

    test('editer le poids d un article persiste et recalcule le total',
        () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await container.read(checklistProvider.notifier).toggle('backpack');

      await container
          .read(checklistProvider.notifier)
          .setItemWeight('backpack', 1234);

      // Etat recalcule.
      expect(container.read(checklistProvider).checkedWeightGrams, 1234);

      // Persistence DB.
      final dao = ChecklistDao(db);
      final rows = await dao.getByTrailId('test_trail');
      final backpackRow = rows.firstWhere((r) => r.itemId == 'backpack');
      expect(backpackRow.weightGrams, 1234);
    });

    test('le ratio sac/corps suit le poids corporel', () async {
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await container.read(checklistProvider.notifier).toggle('backpack');
      container.read(checklistProvider.notifier).setBodyWeight(70);

      final state = container.read(checklistProvider);
      final expected = state.checkedWeightKg / 70.0;
      expect(state.backpackRatio, closeTo(expected, 0.0001));
    });
  });

  group('PARITE GR20 — poids du sac (UI ChecklistScreen)', () {
    testWidgets('le volet poids et un chip poids par article sont affiches',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            trailConfigProvider.overrideWithValue(testTrail),
          ],
          // AppHeader (Ph5/L6b) utilise GoRouter -> GoRouter minimal (+ /my-treks).
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/checklist',
                routes: [
                  GoRoute(
                    path: '/checklist',
                    builder: (_, __) => const ChecklistScreen(),
                  ),
                  GoRoute(
                      path: '/my-treks', builder: (_, __) => const SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Le bandeau poids (parite GR20) est present.
      expect(find.byType(ChecklistWeightBanner), findsOneWidget);
      // Libelle « poids corporel » present (saisie du poids corporel).
      expect(find.text(t.checklist.weight.bodyWeight), findsOneWidget);
      // Au moins un chip poids par article (ex : "1.4 kg" pour le sac a dos).
      expect(find.textContaining(t.checklist.weight.kilograms),
          findsWidgets);
    });
  });

  // -------------------------------------------------------------------------
  // RETOUR CHRIS #10 (tache 553) — « dans sac il y a plein de textes qu'on ne
  // voit pas en entier ».
  //
  // Le pire des cinq etait le CONSEIL de la jauge (« Attention genoux !
  // Allegez le sac ») : il partageait sa ligne avec le pourcentage, en
  // `Flexible` flex 2 contre flex 3, sur UNE ligne avec ellipse. Trois
  // cinquiemes de largeur pour une phrase entiere : il etait coupe a tous les
  // coups. C'est tres probablement ce texte que Chris disait ne pas comprendre
  // — un conseil ampute n'est plus un conseil, c'est un debut de phrase.
  // -------------------------------------------------------------------------
  group('retour Chris #10 — les textes du Sac se lisent en entier', () {
    /// Rend la jauge SEULE, sur une largeur de telephone etroit (360 px), avec
    /// un ratio qui declenche le conseil le plus long.
    Future<void> pumpGauge(WidgetTester tester, double ratio) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: ChecklistWeightGauge(
                backpackRatio: ratio,
                loadBaseKg: 70,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('le CONSEIL de la jauge n est plus coupe, et il est sous la '
        'jauge en pleine largeur', (tester) async {
      // 22 % de la base de charge -> conseil « Attention genoux ! ... ».
      await pumpGauge(tester, 0.22);

      final conseil = find.byKey(const ValueKey('checklist-gauge-advice'));
      expect(conseil, findsOneWidget);

      // 1. PLUS DE PLAFOND D'UNE LIGNE, PLUS D'ELLIPSE : structurellement, ce
      //    texte ne peut plus etre ampute.
      final widget = tester.widget<Text>(conseil);
      expect(widget.maxLines, isNull,
          reason: 'un conseil ne se limite pas a une ligne');
      expect(widget.overflow, anyOf(isNull, TextOverflow.visible, TextOverflow.clip),
          reason: 'plus aucune ellipse sur le conseil');

      // 2. ET DANS LES FAITS, A 360 px, RIEN N'EST TRONQUE.
      final paragraphe = tester.renderObject<RenderParagraph>(conseil);
      expect(paragraphe.didExceedMaxLines, isFalse);

      // 3. IL N'EST PLUS COINCE A DROITE DU POURCENTAGE : il commence au meme
      //    bord gauche que lui (donc pleine largeur), et il est EN DESSOUS.
      final pct = find.textContaining('%').first;
      expect(tester.getTopLeft(conseil).dx,
          tester.getTopLeft(find.byType(Text).first).dx,
          reason: 'le conseil part du bord gauche, comme le pourcentage');
      expect(tester.getTopLeft(conseil).dy,
          greaterThan(tester.getTopLeft(pct).dy),
          reason: 'le conseil est passe SOUS la jauge, plus a cote du chiffre');
    });

    testWidgets('les reperes 15/20/25 % de la jauge ne sont plus rognes',
        (tester) async {
      await pumpGauge(tester, 0.22);

      // Les reperes sont poses en `Positioned(top: 14)` sous une barre de 12 px :
      // un `Stack` se dimensionne sur ses enfants non positionnes et rogne ce qui
      // depasse. La hauteur reservee (32 px) les contient desormais tous.
      for (final repere in ['15%', '20%', '25%']) {
        final f = find.text(repere);
        expect(f, findsOneWidget);
        final bas = tester.getBottomLeft(f).dy;
        final basDuStack =
            tester.getBottomLeft(find.byType(Stack).first).dy;
        expect(bas, lessThanOrEqualTo(basDuStack),
            reason: '$repere doit tenir dans la hauteur reservee a la jauge');
      }
    });

    testWidgets('le libelle « poids du corps » peut passer sur deux lignes',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());

      tester.view.physicalSize = const Size(360, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            trailConfigProvider.overrideWithValue(testTrail),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/checklist',
                routes: [
                  GoRoute(
                    path: '/checklist',
                    builder: (_, __) => const ChecklistScreen(),
                  ),
                  GoRoute(
                      path: '/my-treks', builder: (_, __) => const SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Il partage sa ligne avec un champ de 120 px et la pastille de ratio :
      // sur 360 px il n'a pas toujours de quoi s'ecrire sur une ligne. Deux
      // lignes lui sont desormais accordees, l'ellipse ne reste qu'en dernier
      // recours.
      final libelle = tester.widget<Text>(
        find.text(t.checklist.weight.bodyWeight),
      );
      expect(libelle.maxLines, 2);
    });
  });
}
