import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/shared/widgets/stage_number_badge.dart';

/// Tests E5.5a — Hero transition sur le numero d'etape (liste -> detail).
///
/// Verifie que [StageNumberBadge] :
///  - expose un Hero avec un tag stable derive du numero d'etape ;
///  - declenche bien une animation Hero lors d'une navigation push
///    (presence de deux Hero — source + vol — pendant la transition) ;
///  - peut desactiver le Hero ([animate] = false).
void main() {
  group('StageNumberBadge', () {
    testWidgets('rend le numero et un Hero avec le bon tag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StageNumberBadge(number: 7)),
        ),
      );

      expect(find.text('7'), findsOneWidget);

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, StageNumberBadge.heroTagFor(7));
      expect(hero.tag, 'stage-number-7');
    });

    testWidgets('animate: false -> aucun Hero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageNumberBadge(number: 7, animate: false),
          ),
        ),
      );

      expect(find.byType(Hero), findsNothing);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('anime la transition liste -> detail (Hero en vol)',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();

      // Ecran "detail" : meme badge, meme tag -> cible du vol Hero.
      Widget detail() => const Scaffold(
            body: Center(child: StageNumberBadge(number: 3, size: 64)),
          );

      // Ecran "liste" : badge tappable qui pousse le detail.
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => detail()),
                  ),
                  child: const StageNumberBadge(number: 3),
                ),
              ),
            ),
          ),
        ),
      );

      // Au repos : un seul Hero (celui de la liste).
      expect(find.byType(Hero), findsOneWidget);

      // Declenche la navigation.
      await tester.tap(find.byType(StageNumberBadge));
      await tester.pump(); // demarre la transition
      await tester.pump(const Duration(milliseconds: 100)); // mi-vol

      // Pendant le vol, Flutter monte un Hero supplementaire dans l'overlay
      // -> au moins deux Hero a l'ecran : preuve de l'animation Hero.
      expect(
        find.byType(Hero).evaluate().length,
        greaterThanOrEqualTo(2),
        reason: 'un Hero en vol doit etre present pendant la transition',
      );

      // Fin de transition : le detail est affiche, un seul Hero subsiste.
      await tester.pumpAndSettle();
      expect(find.byType(Hero), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}
