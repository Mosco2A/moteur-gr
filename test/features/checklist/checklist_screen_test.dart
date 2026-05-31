import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';
import 'package:moteur_gr/features/checklist/providers/checklist_provider.dart';

/// Tests E3.2b : checklist screen (cochage persiste + affichage categories).
///
/// On teste la persistence du cochage via le provider/DB in-memory
/// et le regroupement par categories.
void main() {
  group('E3.2b ChecklistScreen', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(const TrailConfig(
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
        )),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('cochage persiste en DB apres toggle', () async {
      // Charger le provider (initialise depuis le template)
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Verifier etat initial : rien de coche
      var state = container.read(checklistProvider);
      expect(state.checkedCount, 0);

      // Cocher un item
      await container.read(checklistProvider.notifier).toggle('backpack');
      state = container.read(checklistProvider);
      expect(state.checkedCount, 1);

      // Verifier la persistence en DB directement
      final dao = ChecklistDao(db);
      final dbItems = await dao.getByTrailId('test_trail');
      final backpackDb = dbItems.firstWhere((i) => i.itemId == 'backpack');
      expect(backpackDb.isChecked, true,
          reason: 'Le cochage doit etre persiste en DB via Drift');

      // Cocher un deuxieme item
      await container.read(checklistProvider.notifier).toggle('sleepingBag');

      // Verifier en DB
      final dbItems2 = await dao.getByTrailId('test_trail');
      final sleepingBagDb = dbItems2.firstWhere(
        (i) => i.itemId == 'sleepingBag',
      );
      expect(sleepingBagDb.isChecked, true);

      // Decocher le premier item — doit aussi persister
      await container.read(checklistProvider.notifier).toggle('backpack');
      final dbItems3 = await dao.getByTrailId('test_trail');
      final backpackDb3 = dbItems3.firstWhere((i) => i.itemId == 'backpack');
      expect(backpackDb3.isChecked, false,
          reason: 'Le decochage doit aussi persister en DB');
    });

    test('items sont groupes par les 6 categories du template', () async {
      // Charger le provider
      container.read(checklistProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final state = container.read(checklistProvider);

      // Verifier que chaque categorie du template a au moins un item
      for (final category in checklistCategories) {
        final categoryItems = state.items
            .where((i) => i.template.category == category)
            .toList();
        expect(
          categoryItems,
          isNotEmpty,
          reason: 'La categorie "$category" doit contenir au moins 1 item',
        );
      }

      // Verifier le nombre total de categories representees
      final distinctCategories = state.items
          .map((i) => i.template.category)
          .toSet();
      expect(
        distinctCategories.length,
        checklistCategories.length,
        reason: 'Les 6 categories doivent toutes etre presentes',
      );

      // Verifier les compteurs par categorie via le provider family
      for (final category in checklistCategories) {
        final categoryItems = container.read(
          checklistByCategoryProvider(category),
        );
        expect(
          categoryItems.isNotEmpty,
          true,
          reason: 'checklistByCategoryProvider("$category") doit renvoyer des items',
        );
      }
    });
  });
}
