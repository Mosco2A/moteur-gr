import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/tips/data/tip_cards_loader.dart';
import 'package:moteur_gr/features/tips/domain/models/tip_card.dart';
import 'package:moteur_gr/features/tips/domain/models/tip_theme.dart';
import 'package:moteur_gr/features/tips/presentation/tips_screen.dart';
import 'package:moteur_gr/features/tips/providers/tip_cards_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests des FICHES CONSEILS par THEMES + liens reseau (StepWays LOT 5, C).
///
/// Couvre : le champ `url` (FB/IG) et le repli theme<-categorie du modele, la
/// derivation de theme, le chargement socle+trail, le regroupement par theme,
/// et l'ecran (sections par theme + boutons reseau conditionnels).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TipCard — theme + liens reseau', () {
    test('resolvedTheme derive de la categorie si theme vide', () {
      const c = TipCard(id: 'x', titleFr: 'T', contentFr: 'C', category: 'safety');
      expect(c.resolvedTheme, TipTheme.safety);
    });

    test('theme explicite prime sur la categorie', () {
      const c = TipCard(
        id: 'x',
        titleFr: 'T',
        contentFr: 'C',
        category: 'safety',
        theme: 'refuge',
      );
      expect(c.resolvedTheme, TipTheme.refuge);
    });

    test('hasSocialLinks vrai seulement si une url est renseignee', () {
      const none = TipCard(id: 'a', titleFr: 'T', contentFr: 'C');
      const fb = TipCard(
        id: 'b',
        titleFr: 'T',
        contentFr: 'C',
        urlFacebook: 'https://facebook.com/x',
      );
      expect(none.hasSocialLinks, isFalse);
      expect(fb.hasSocialLinks, isTrue);
    });

    test('serialisation JSON round-trip conserve url + theme', () {
      const c = TipCard(
        id: 'x',
        titleFr: 'T',
        contentFr: 'C',
        theme: 'gear',
        urlFacebook: 'https://facebook.com/x',
        urlInstagram: 'https://instagram.com/x',
      );
      final round = TipCard.fromJson(c.toJson());
      expect(round.theme, 'gear');
      expect(round.urlFacebook, 'https://facebook.com/x');
      expect(round.urlInstagram, 'https://instagram.com/x');
    });
  });

  group('TipCardsLoader (socle + trail)', () {
    test('charge le socle commun (general_tips)', () async {
      final cards = await TipCardsLoader.load(trailTipAssetPaths: const []);
      expect(cards, isNotEmpty);
      // Toutes les fiches du socle portent un theme resolu non vide.
      expect(cards.every((c) => c.resolvedTheme.isNotEmpty), isTrue);
    });

    test('fusionne socle + fiches specifiques du sentier', () async {
      final socle = await TipCardsLoader.load(trailTipAssetPaths: const []);
      final withTrail = await TipCardsLoader.load(
        trailTipAssetPaths: const ['assets/tips/mare_a_mare_tips.json'],
      );
      expect(withTrail.length, greaterThan(socle.length));
      expect(withTrail.any((c) => c.id == 'mam-gestion-eau'), isTrue);
    });
  });

  group('tipCardsByThemeProvider (regroupement)', () {
    test('regroupe par theme et trie les sections', () {
      final container = ProviderContainer(
        overrides: [
          tipCardsProvider.overrideWith((ref) async => const [
                TipCard(id: '1', titleFr: 'A', contentFr: 'c', theme: 'safety'),
                TipCard(id: '2', titleFr: 'B', contentFr: 'c', theme: 'gear'),
                TipCard(id: '3', titleFr: 'C', contentFr: 'c', theme: 'gear'),
              ]),
        ],
      );
      addTearDown(container.dispose);
      // Amorce le FutureProvider.
      container.read(tipCardsProvider);
      // Attendre la resolution async du future override.
      return container.read(tipCardsProvider.future).then((_) {
        final sections = container.read(tipCardsByThemeProvider);
        expect(sections.length, 2);
        // gear avant safety (ordre d'affichage stable).
        expect(sections.first.theme, TipTheme.gear);
        expect(sections.first.cards.length, 2);
        expect(sections[1].theme, TipTheme.safety);
      });
    });
  });

  group('TipsScreen (ecran par themes)', () {
    Widget wrap(List<TipCard> cards) => ProviderScope(
          overrides: [
            tipCardsProvider.overrideWith((ref) async => cards),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/tips',
                routes: [
                  GoRoute(path: '/tips', builder: (_, __) => const TipsScreen()),
                  GoRoute(
                      path: '/my-treks', builder: (_, __) => const SizedBox()),
                ],
              ),
            ),
          ),
        );

    testWidgets('affiche des titres de theme + le bouton reseau si url',
        (tester) async {
      await tester.pumpWidget(wrap(const [
        TipCard(
          id: '1',
          titleFr: 'Dangers du sentier',
          contentFr: 'Contenu danger',
          theme: 'safety',
          urlFacebook: 'https://facebook.com/brand',
        ),
      ]));
      await tester.pumpAndSettle();

      // Titre de theme (Securite, en majuscules dans l'UI).
      expect(find.text(t.tips.themes.safety.toUpperCase()), findsOneWidget);
      // Deplier la fiche -> le bouton Facebook apparait (url presente).
      await tester.tap(find.text('Dangers du sentier'));
      await tester.pumpAndSettle();
      expect(find.text(t.tips.viewOnFacebook), findsOneWidget);
    });

    testWidgets('fiche sans url -> aucun bouton reseau', (tester) async {
      await tester.pumpWidget(wrap(const [
        TipCard(id: '1', titleFr: 'Sans lien', contentFr: 'Contenu', theme: 'gear'),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sans lien'));
      await tester.pumpAndSettle();
      expect(find.text(t.tips.viewOnFacebook), findsNothing);
      expect(find.text(t.tips.viewOnInstagram), findsNothing);
    });

    testWidgets('aucune fiche -> message neutre', (tester) async {
      await tester.pumpWidget(wrap(const []));
      await tester.pumpAndSettle();
      expect(find.text(t.tips.emptyThemed), findsOneWidget);
    });
  });
}
