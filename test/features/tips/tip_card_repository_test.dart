import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/tips/domain/models/tip_card.dart';
import 'package:moteur_gr/features/tips/data/tip_card_repository.dart';
import 'package:moteur_gr/features/tips/data/tip_category_config.dart';

/// Tests E3.4a : filtrage saison + fallback categorie inconnue.
void main() {
  // --- Jeu de donnees de test ---
  final testCards = [
    const TipCard(
      id: 'tip-summer-bleu',
      titleFr: 'Conseil ete Sentier Bleu',
      contentFr: 'Boire 3L par jour minimum.',
      scope: 'sentier-bleu',
      season: 'summer',
      category: 'nutrition',
      priority: 10,
      minAltitudeM: 1500,
    ),
    const TipCard(
      id: 'tip-winter-all',
      titleFr: 'Conseil hiver general',
      contentFr: 'Emporter des crampons.',
      scope: 'all',
      season: 'winter',
      category: 'equipment',
      priority: 8,
    ),
    const TipCard(
      id: 'tip-all-all',
      titleFr: 'Conseil universel',
      contentFr: 'Toujours prevenir quelqu un.',
      scope: 'all',
      season: 'all',
      category: 'safety',
      priority: 5,
    ),
    const TipCard(
      id: 'tip-summer-mare',
      titleFr: 'Conseil ete Mare a Mare',
      contentFr: 'Les sources sont rares en ete.',
      scope: 'mare_a_mare',
      season: 'summer',
      category: 'nutrition',
      priority: 7,
    ),
    const TipCard(
      id: 'tip-altitude-high',
      titleFr: 'Conseil haute altitude',
      contentFr: 'Attention au mal des montagnes.',
      scope: 'all',
      season: 'all',
      category: 'safety',
      priority: 9,
      minAltitudeM: 2000,
    ),
  ];

  group('TipCardRepository -- filtrage saison', () {
    late TipCardRepository repo;

    setUp(() {
      repo = TipCardRepository(allCards: testCards);
    });

    test('filtre saison summer retourne uniquement les fiches ete et all', () {
      final results = repo.filterCards(currentSeason: 'summer');

      // Doit contenir : tip-summer-bleu, tip-all-all, tip-summer-mare, tip-altitude-high
      // Ne doit PAS contenir : tip-winter-all
      expect(results.length, 4);
      expect(
        results.any((c) => c.id == 'tip-winter-all'),
        false,
        reason: 'Les fiches hiver ne doivent pas apparaitre en ete',
      );
      expect(
        results.any((c) => c.id == 'tip-summer-bleu'),
        true,
        reason: 'Les fiches ete doivent apparaitre',
      );
      expect(
        results.any((c) => c.id == 'tip-all-all'),
        true,
        reason: 'Les fiches all-season doivent toujours apparaitre',
      );
    });

    test('filtre saison winter retourne uniquement les fiches hiver et all', () {
      final results = repo.filterCards(currentSeason: 'winter');

      // Doit contenir : tip-winter-all, tip-all-all, tip-altitude-high
      // Ne doit PAS contenir : tip-summer-bleu, tip-summer-mare
      expect(results.length, 3);
      expect(
        results.any((c) => c.id == 'tip-summer-bleu'),
        false,
      );
      expect(
        results.any((c) => c.id == 'tip-summer-mare'),
        false,
      );
      expect(
        results.any((c) => c.id == 'tip-winter-all'),
        true,
      );
    });

    test('filtre scope + saison combine correctement', () {
      final results = repo.filterCards(
        trailScope: 'sentier-bleu',
        currentSeason: 'summer',
      );

      // scope sentier-bleu + season summer : tip-summer-bleu, tip-all-all, tip-altitude-high
      // tip-summer-mare exclu (scope mare_a_mare)
      // tip-winter-all exclu (season winter)
      expect(results.length, 3);
      expect(results.any((c) => c.id == 'tip-summer-mare'), false);
      expect(results.any((c) => c.id == 'tip-winter-all'), false);
    });

    test('filtre altitude exclut les fiches sous le seuil', () {
      final results = repo.filterCards(currentAltitudeM: 1800);

      // tip-altitude-high (min 2000) exclu car 1800 < 2000
      // tip-summer-bleu (min 1500) inclus car 1800 >= 1500
      // Les 3 autres sans minAltitudeM inclus
      expect(results.length, 4);
      expect(results.any((c) => c.id == 'tip-altitude-high'), false);
      expect(results.any((c) => c.id == 'tip-summer-bleu'), true);
    });

    test('sans filtre retourne tout trie par priorite decroissante', () {
      final results = repo.filterCards();

      expect(results.length, 5);
      // Ordre attendu par priorite : 10, 9, 8, 7, 5
      expect(results[0].priority, 10);
      expect(results[1].priority, 9);
      expect(results[2].priority, 8);
      expect(results[3].priority, 7);
      expect(results[4].priority, 5);
    });

    test('filterByCategory retourne uniquement la categorie demandee', () {
      final results = repo.filterByCategory('nutrition');

      expect(results.length, 2);
      expect(results.every((c) => c.category == 'nutrition'), true);
    });
  });

  group('TipCategoryConfig -- fallback categorie inconnue', () {
    test('categorie connue retourne la bonne config', () {
      final config = TipCategoryConfig.getConfig('safety');

      expect(config.labelKey, 'tipCategorySafety');
      expect(config.icon, 'health_and_safety');
    });

    test('categorie inconnue retourne le fallback general', () {
      final config = TipCategoryConfig.getConfig('categorie_inexistante');

      expect(config.labelKey, 'tipCategoryGeneral');
      expect(config.icon, 'info');
    });

    test('categorie vide retourne le fallback general', () {
      final config = TipCategoryConfig.getConfig('');

      expect(config.labelKey, 'tipCategoryGeneral');
      expect(config.icon, 'info');
    });

    test('isKnown retourne true pour categorie connue', () {
      expect(TipCategoryConfig.isKnown('preparation'), true);
      expect(TipCategoryConfig.isKnown('equipment'), true);
    });

    test('isKnown retourne false pour categorie inconnue', () {
      expect(TipCategoryConfig.isKnown('unknown_category'), false);
      expect(TipCategoryConfig.isKnown(''), false);
    });

    test('knownCategories contient les 6 categories de base', () {
      final known = TipCategoryConfig.knownCategories;

      expect(known, contains('preparation'));
      expect(known, contains('equipment'));
      expect(known, contains('nutrition'));
      expect(known, contains('safety'));
      expect(known, contains('nature'));
      expect(known, contains('recovery'));
      expect(known.length, 6);
    });
  });
}
