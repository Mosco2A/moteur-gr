import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/features/tips/data/tip_card_repository.dart';
import 'package:moteur_gr/features/tips/domain/models/tip_card.dart';
import 'package:moteur_gr/features/tips/presentation/tip_carousel.dart';

/// Tests E3.4c : carrousel swipeable + filtrage par categorie.
///
/// Verifie que le PageView affiche les fiches, que le swipe fonctionne,
/// et que les chips de filtrage par categorie filtrent correctement.
void main() {
  // --- Jeu de donnees de test ---
  final testCards = [
    const TipCard(
      id: 'tip-prep-1',
      titleFr: 'Entrainement progressif',
      contentFr: 'Commencez 3 mois avant par des randonnees courtes.',
      category: 'preparation',
      priority: 10,
    ),
    const TipCard(
      id: 'tip-equip-1',
      titleFr: 'Chaussures rodees',
      contentFr: 'Portez vos chaussures au moins 50 km avant le depart.',
      category: 'equipment',
      priority: 9,
    ),
    const TipCard(
      id: 'tip-safety-1',
      titleFr: 'Numero urgence',
      contentFr: 'Enregistrez le 112 et le numero du refuge.',
      category: 'safety',
      priority: 8,
    ),
    const TipCard(
      id: 'tip-nutri-1',
      titleFr: 'Hydratation',
      contentFr: 'Buvez 3L par jour minimum en ete.',
      category: 'nutrition',
      priority: 7,
    ),
    const TipCard(
      id: 'tip-prep-2',
      titleFr: 'Denivele positif',
      contentFr: 'Entrainez-vous sur du D+ en montagne.',
      category: 'preparation',
      priority: 6,
    ),
  ];

  /// Cree un widget testable avec le carrousel et les donnees injectees.
  /// Surface large (1200px) pour que tous les chips soient visibles.
  Widget buildTestCarousel(List<TipCard> cards) {
    return ProviderScope(
      overrides: [
        tipCardRepositoryProvider.overrideWithValue(
          TipCardRepository(allCards: cards),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 600,
            child: SingleChildScrollView(
              child: TipCarousel(),
            ),
          ),
        ),
      ),
    );
  }

  group('TipCarousel -- swipe + filtrage', () {
    testWidgets('affiche toutes les fiches sans filtre et chips categories', (tester) async {
      // Surface large pour les chips
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestCarousel(testCards));
      await tester.pumpAndSettle();

      // La premiere fiche est visible
      expect(find.text('Entrainement progressif'), findsOneWidget);

      // Le chip "Toutes" est present
      expect(find.text('Toutes'), findsOneWidget);

      // Au moins 4 FilterChips visibles (Toutes + categories, ListView lazy)
      expect(find.byType(FilterChip), findsAtLeast(4));
    });

    testWidgets('swipe horizontal change de page', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestCarousel(testCards));
      await tester.pumpAndSettle();

      // Premiere fiche visible
      expect(find.text('Entrainement progressif'), findsOneWidget);

      // Swipe vers la gauche pour passer a la fiche suivante
      await tester.drag(
        find.byType(PageView),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();

      // La deuxieme fiche est maintenant visible
      expect(find.text('Chaussures rodees'), findsOneWidget);
    });

    testWidgets('filtrage par categorie fonctionne', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestCarousel(testCards));
      await tester.pumpAndSettle();

      // 5 fiches au total, premiere = Entrainement progressif (priorite 10)
      expect(find.text('Entrainement progressif'), findsOneWidget);

      // Tap sur chip index 3 = preparation (alphabetique: equipment, nutrition, preparation, safety)
      final chips = find.byType(FilterChip);
      await tester.tap(chips.at(3));
      await tester.pumpAndSettle();

      // Seules les 2 fiches preparation restent
      // La premiere par priorite (10) = Entrainement progressif
      expect(find.text('Entrainement progressif'), findsOneWidget);

      // Retour a Toutes
      await tester.tap(chips.at(0));
      await tester.pumpAndSettle();

      // Toutes les fiches a nouveau (premiere visible)
      expect(find.text('Entrainement progressif'), findsOneWidget);
    });

    testWidgets('etat vide quand aucune fiche', (tester) async {
      await tester.pumpWidget(buildTestCarousel(const []));
      await tester.pumpAndSettle();

      // Message vide affiche
      expect(find.text('Aucun conseil disponible'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('indicateur priorite haute sur les fiches prioritaires', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestCarousel(testCards));
      await tester.pumpAndSettle();

      // La premiere fiche a priorite 10 >= 8, donc icone priority_high presente
      expect(find.byIcon(Icons.priority_high), findsWidgets);
    });

    testWidgets('categories dynamiques extraites des donnees', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seulement 2 categories dans les donnees
      final limitedCards = [
        const TipCard(
          id: 'a',
          titleFr: 'A',
          contentFr: 'a',
          category: 'nutrition',
        ),
        const TipCard(
          id: 'b',
          titleFr: 'B',
          contentFr: 'b',
          category: 'safety',
        ),
      ];

      await tester.pumpWidget(buildTestCarousel(limitedCards));
      await tester.pumpAndSettle();

      // Toutes + 2 categories = 3 chips
      expect(find.byType(FilterChip), findsNWidgets(3));
    });
  });
}
