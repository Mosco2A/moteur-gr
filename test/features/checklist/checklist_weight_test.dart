import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
          child: TranslationProvider(
            child: const MaterialApp(
              home: ChecklistScreen(),
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
}
