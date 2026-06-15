import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/guides/domain/town_guide.dart';
import 'package:moteur_gr/features/guides/domain/town_guide_catalog.dart';
import 'package:moteur_gr/features/guides/presentation/town_guide_detail_screen.dart';
import 'package:moteur_gr/features/guides/presentation/town_guides_screen.dart';
import 'package:moteur_gr/features/guides/providers/guide_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Lanceur de deeplink factice : enregistre les URL ouvertes, sans toucher au
/// plugin natif url_launcher. Permet de tester le bouton FACILITATEUR (#84100)
/// en mode pur widget. [result] pilote succes/echec d'ouverture.
class _FakeLauncher implements GuideDeeplinkLauncher {
  _FakeLauncher({this.result = true});

  /// Resultat simule d'une ouverture (true = ouverte, false = echec appareil).
  bool result;

  /// URL effectivement demandees a l'ouverture (FACILITATEUR sortant).
  final List<String> opened = [];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return result;
  }
}

/// Resolveur de libelles neutre pour lire le catalogue dans les assertions.
GuideSectionLabels _stubLabels(String categorie) =>
    GuideSectionLabels(titre: 'titre-$categorie', contenu: 'intro-$categorie');

List<TownGuide> _catalogGuides() => TownGuideCatalog.guidesFor(
      _trailId,
      sectionLabelResolver: _stubLabels,
    ).where((g) => g.hasContent).toList();

const _trailId = 'mare_a_mare_centre';

void main() {
  Widget wrap(Widget child, {required GuideDeeplinkLauncher launcher}) {
    return ProviderScope(
      overrides: [
        guideDeeplinkLauncherProvider.overrideWithValue(launcher),
      ],
      child: TranslationProvider(
        child: MaterialApp(home: child),
      ),
    );
  }

  group('TownGuidesScreen — liste offline (R3) + facilitateur (#84100)', () {
    testWidgets('affiche la liste des guides et le bandeau facilitateur',
        (tester) async {
      await tester.pumpWidget(
        wrap(const TownGuidesScreen(trailId: _trailId),
            launcher: _FakeLauncher()),
      );
      await tester.pumpAndSettle();

      // Liste presente + rappel FACILITATEUR (anti resa/paiement in-app).
      expect(find.byKey(const ValueKey('town-guides-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('guides-facilitator-note')),
          findsOneWidget);

      // Une carte par localite porteuse de contenu, rattachee au sentier.
      final guides = _catalogGuides();
      expect(guides, isNotEmpty);
      for (final g in guides) {
        expect(find.byKey(ValueKey('town-guide-card-${g.id}')), findsOneWidget);
      }
    });

    testWidgets('tap sur une localite ouvre le detail du guide', (tester) async {
      await tester.pumpWidget(
        wrap(const TownGuidesScreen(trailId: _trailId),
            launcher: _FakeLauncher()),
      );
      await tester.pumpAndSettle();

      final first = _catalogGuides().first;
      await tester.tap(find.byKey(ValueKey('town-guide-card-${first.id}')));
      await tester.pumpAndSettle();

      // L'ecran de detail du bon guide est affiche.
      expect(find.byKey(ValueKey('town-guide-detail-${first.id}')),
          findsOneWidget);
      expect(find.text(first.nomLieu), findsWidgets);
    });
  });

  group('TownGuideDetailScreen — sections + items (offline)', () {
    testWidgets('affiche toutes les sections pratiques avec leurs items',
        (tester) async {
      // Guide resolu via le catalogue (libelles Slang reels cote UI).
      final ref = _catalogGuides().first;
      await tester.pumpWidget(
        wrap(
          TownGuideDetailScreen(trailId: _trailId, guideId: ref.id),
          launcher: _FakeLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('town-guide-detail-${ref.id}')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('guide-detail-facilitator-note')),
          findsOneWidget);

      // Chaque section porteuse d'items a sa carte + ses items rendus (offline).
      // La ListView est paresseuse : on fait defiler jusqu'a chaque section.
      final expectedSections =
          ref.sections.where((s) => s.items.isNotEmpty).toList();
      expect(expectedSections, isNotEmpty);
      final scrollable = find.descendant(
        of: find.byKey(ValueKey('town-guide-detail-${ref.id}')),
        matching: find.byType(Scrollable),
      );
      for (final s in expectedSections) {
        final sectionFinder =
            find.byKey(ValueKey('guide-section-${s.normalizedCategorie}'));
        await tester.scrollUntilVisible(sectionFinder, 200,
            scrollable: scrollable);
        expect(sectionFinder, findsOneWidget,
            reason: 'section ${s.normalizedCategorie} manquante');
        for (final item in s.items) {
          expect(find.text(item.nom), findsWidgets,
              reason: 'item ${item.nom} manquant');
        }
      }
    });

    testWidgets('guide introuvable -> repli offline explicite', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TownGuideDetailScreen(trailId: _trailId, guideId: 'inexistant'),
          launcher: _FakeLauncher(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('town-guide-detail-empty')),
          findsOneWidget);
    });
  });

  group('Deeplink facilitateur (#84100) — lien SORTANT uniquement', () {
    /// Construit un guide a une section/un item avec lien deeplink controle.
    TownGuide guideWithDeeplink({String? url}) => TownGuide(
          id: 'g-test',
          trailId: _trailId,
          nomLieu: 'Lieu test',
          latitude: 0,
          longitude: 0,
          sections: [
            GuideSection(
              categorie: GuideCategory.hebergement,
              titre: 'Hebergement',
              items: [
                GuideItem(nom: 'Gite test', description: 'desc', deeplinkUrl: url),
              ],
            ),
          ],
        );

    testWidgets('bouton present si lien -> ouvre le site via le launcher',
        (tester) async {
      final launcher = _FakeLauncher(result: true);
      // guide injecte directement (parametre `guide`) : on teste le rendu + lien.
      await tester.pumpWidget(wrap(
        TownGuideDetailScreen(
          trailId: _trailId,
          guideId: 'g-test',
          guide: guideWithDeeplink(url: 'https://example.org/gite'),
        ),
        launcher: launcher,
      ));
      await tester.pumpAndSettle();

      final btn = find.byKey(const ValueKey('guide-deeplink-Gite test'));
      expect(btn, findsOneWidget);

      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Le launcher a recu EXACTEMENT l'URL sortante (facilitateur, pas de resa).
      expect(launcher.opened, ['https://example.org/gite']);
    });

    testWidgets('aucun bouton si l item n a pas de lien', (tester) async {
      final launcher = _FakeLauncher();
      await tester.pumpWidget(wrap(
        TownGuideDetailScreen(
          trailId: _trailId,
          guideId: 'g-test',
          guide: guideWithDeeplink(url: null),
        ),
        launcher: launcher,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guide-deeplink-Gite test')),
          findsNothing);
      expect(launcher.opened, isEmpty);
    });

    testWidgets('echec d ouverture -> message utilisateur (pas de silence)',
        (tester) async {
      final launcher = _FakeLauncher(result: false);
      await tester.pumpWidget(wrap(
        TownGuideDetailScreen(
          trailId: _trailId,
          guideId: 'g-test',
          guide: guideWithDeeplink(url: 'https://example.org/gite'),
        ),
        launcher: launcher,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('guide-deeplink-Gite test')));
      await tester.pump(); // declenche la SnackBar
      await tester.pump(const Duration(milliseconds: 100));

      final t = TranslationProvider.of(
              tester.element(find.byType(TownGuideDetailScreen)))
          .translations;
      expect(find.text(t.guides.cannotOpen), findsOneWidget);
    });
  });
}
