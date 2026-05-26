import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/trail/widgets/difficulty_badge.dart';

/// Tests du widget DifficultyBadge.
///
/// Vérifie que chaque niveau de difficulté affiche
/// le bon libellé et la bonne couleur.
void main() {
  group('DifficultyBadge', () {
    Widget buildBadge(String difficulty) {
      return MaterialApp(
        home: Scaffold(body: DifficultyBadge(difficulty: difficulty)),
      );
    }

    testWidgets('affiche "Facile" pour easy', (tester) async {
      await tester.pumpWidget(buildBadge('easy'));
      expect(find.text('Facile'), findsOneWidget);
    });

    testWidgets('affiche "Modéré" pour moderate', (tester) async {
      await tester.pumpWidget(buildBadge('moderate'));
      expect(find.text('Modéré'), findsOneWidget);
    });

    testWidgets('affiche "Difficile" pour hard', (tester) async {
      await tester.pumpWidget(buildBadge('hard'));
      expect(find.text('Difficile'), findsOneWidget);
    });

    testWidgets('affiche "Expert" pour expert', (tester) async {
      await tester.pumpWidget(buildBadge('expert'));
      expect(find.text('Expert'), findsOneWidget);
    });

    test('colorFor retourne vert pour easy', () {
      expect(DifficultyBadge.colorFor('easy'), AppTheme.vertFacile);
    });

    test('colorFor retourne orange pour moderate', () {
      expect(DifficultyBadge.colorFor('moderate'), AppTheme.orangeDifficile);
    });

    test('colorFor retourne rouge pour hard', () {
      expect(DifficultyBadge.colorFor('hard'), AppTheme.rougeExtreme);
    });

    test('colorFor retourne violet pour expert', () {
      expect(
        DifficultyBadge.colorFor('expert'),
        const Color(0xFF7B1FA2),
      );
    });

    test('colorFor retourne gris pour valeur inconnue', () {
      expect(DifficultyBadge.colorFor('unknown'), AppTheme.grisGranite);
    });

    testWidgets('affiche la valeur brute pour difficulté inconnue',
        (tester) async {
      await tester.pumpWidget(buildBadge('extreme'));
      expect(find.text('extreme'), findsOneWidget);
    });
  });
}
