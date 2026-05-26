import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/tips/data/tips_data.dart';

/// Tests des fiches conseils trek.
void main() {
  group('tipsCategories', () {
    test('contient 6 categories', () {
      expect(tipsCategories.length, 6);
    });

    test('tous les ids sont uniques', () {
      final ids = tipsCategories.map((c) => c.id).toSet();
      expect(ids.length, tipsCategories.length);
    });

    test('chaque categorie a au moins 3 conseils', () {
      for (final category in tipsCategories) {
        expect(
          category.tips.length,
          greaterThanOrEqualTo(3),
          reason: 'Categorie ${category.id} doit avoir >= 3 conseils',
        );
      }
    });

    test('tous les tips ont des ids uniques globalement', () {
      final allTipIds = <String>{};
      for (final category in tipsCategories) {
        for (final tip in category.tips) {
          expect(
            allTipIds.add(tip.id),
            true,
            reason: 'Tip id duplique: ${tip.id}',
          );
        }
      }
    });

    test('nombre total de conseils est >= 20', () {
      final total =
          tipsCategories.fold<int>(0, (sum, c) => sum + c.tips.length);
      expect(total, greaterThanOrEqualTo(20));
    });

    test('les categories couvrent les sujets attendus', () {
      final ids = tipsCategories.map((c) => c.id).toSet();
      expect(ids, contains('preparation'));
      expect(ids, contains('equipment'));
      expect(ids, contains('nutrition'));
      expect(ids, contains('safety'));
      expect(ids, contains('nature'));
      expect(ids, contains('recovery'));
    });

    test('chaque categorie a un icone valide', () {
      for (final category in tipsCategories) {
        expect(category.icon.isNotEmpty, true,
            reason: 'Categorie ${category.id} sans icone');
      }
    });

    test('chaque tip a un titre et un contenu non vides', () {
      for (final category in tipsCategories) {
        for (final tip in category.tips) {
          expect(tip.titleKey.isNotEmpty, true,
              reason: 'Tip ${tip.id} sans titre');
          expect(tip.contentKey.isNotEmpty, true,
              reason: 'Tip ${tip.id} sans contenu');
        }
      }
    });
  });

  group('TipCategory', () {
    test('constructor initialise les champs', () {
      const cat = TipCategory(
        id: 'test',
        nameKey: 'testName',
        icon: 'testIcon',
        tips: [],
      );
      expect(cat.id, 'test');
      expect(cat.nameKey, 'testName');
      expect(cat.icon, 'testIcon');
      expect(cat.tips, isEmpty);
    });
  });

  group('Tip', () {
    test('constructor initialise les champs', () {
      const tip = Tip(
        id: 'tip1',
        titleKey: 'title',
        contentKey: 'content',
      );
      expect(tip.id, 'tip1');
      expect(tip.titleKey, 'title');
      expect(tip.contentKey, 'content');
    });
  });
}
