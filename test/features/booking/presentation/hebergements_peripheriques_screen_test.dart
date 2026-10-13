import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/booking/domain/models/hebergement_peripherique.dart';
import 'package:moteur_gr/features/booking/presentation/hebergements_peripheriques_screen.dart';
import 'package:moteur_gr/features/booking/providers/hebergement_peripherique_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_card.dart';

/// Lanceur de deeplink factice : enregistre les URLs ouvertes (pas de réseau).
class _FakeDeeplinkLauncher implements DeeplinkLauncher {
  final List<String> opened = [];
  bool result = true;

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return result;
  }
}

/// Hebergement de test PORTANT un lien profond.
///
/// IL EST ECRIT ICI, ET PLUS LU DANS LA DONNEE DE PRODUCTION (lot 645-08). Les
/// trois hebergements de demonstration portaient `https://example.org/...` et
/// les tests du bouton s'appuyaient dessus : ils gardaient donc un bouton qui
/// n'envoyait le randonneur nulle part. Le comportement facilitateur reste
/// couvert en entier — avec ce fixtures-ci — et le rendu SANS lien, qui est
/// desormais celui de la donnee livree, a sa propre verification.
const _avecLien = HebergementPeripherique(
  id: 'hp-test',
  nom: 'Gite de test',
  type: HebergementType.gite,
  latitude: 42.12,
  longitude: 9.05,
  distanceAllerRetourKm: 3.6,
  deeplinkUrl: 'https://exemple-prestataire.test/gite',
);

/// Tests widget de l'écran des hébergements périphériques (F6D-02).
///
/// Vérifie : la liste des hébergements et leur détour A/R, le bandeau
/// facilitateur (pas de réservation in-app), que le bouton OUVRE un deeplink
/// sortant (rôle de facilitateur, #84100) sans réservation interne QUAND le
/// lien existe, et qu'il n'y a NI bouton NI ligne vide quand il n'existe pas.
void main() {
  late _FakeDeeplinkLauncher fakeLauncher;

  setUp(() => fakeLauncher = _FakeDeeplinkLauncher());

  // AppHeader (Ph5/L6c) utilise GoRouter -> GoRouter minimal (+ /my-treks).
  Widget wrap({List<HebergementPeripherique>? hebergements}) => ProviderScope(
    overrides: [
      deeplinkLauncherProvider.overrideWithValue(fakeLauncher),
      if (hebergements != null)
        hebergementsPeripheriquesProvider(
          'test-trail',
        ).overrideWithValue(hebergements),
    ],
    child: TranslationProvider(
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/hebergements',
          routes: [
            GoRoute(
              path: '/hebergements',
              builder: (_, __) =>
                  const HebergementsPeripheriquesScreen(trailId: 'test-trail'),
            ),
            GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
          ],
        ),
      ),
    ),
  );

  group('HebergementsPeripheriquesScreen', () {
    testWidgets('affiche le titre et le bandeau facilitateur', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(t.hebergement.title), findsWidgets);
      expect(find.text(t.hebergement.facilitatorNote), findsOneWidget);
    });

    // ATTENTE VOLONTAIREMENT INVERSEE PAR LE LOT 645-08 (voie V2). Elle
    // s'achevait sur `expect(find.text(t.hebergement.openSite), findsWidgets)`
    // — un bouton par hebergement — et elle etait verte grace aux trois
    // `example.org` de la donnee de demonstration. La donnee livree ne porte
    // plus de lien : il ne doit donc plus y avoir UN SEUL bouton, ni le blanc
    // qui le precedait.
    testWidgets('liste les hébergements avec leur détour A/R, et sans bouton '
        'puisque la donnee livree ne porte aucun lien', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Au moins une carte d'hébergement présente.
      // SW-SKIN-L3e : les Card Material ont ete unifiees en AppCard.
      expect(find.byType(AppCard), findsWidgets);
      // Le détour A/R formaté apparaît (ex. 2.4 km).
      expect(find.text(t.hebergement.detourAR(km: '2.4')), findsOneWidget);
      // ET RIEN APRES LUI : pas de bouton, pas de tiret, pas de « non
      // renseigne ». La carte s'arrete sur le detour.
      expect(find.text(t.hebergement.openSite), findsNothing);
    });

    testWidgets('sans lien profond, la carte s arrete apres le detour : ni '
        'bouton, ni espace reserve', (tester) async {
      const sansLien = HebergementPeripherique(
        id: 'hp-sans-lien',
        nom: 'Refuge sans site',
        type: HebergementType.refuge,
        latitude: 42.15,
        longitude: 9.08,
        distanceAllerRetourKm: 4.2,
      );
      await tester.pumpWidget(wrap(hebergements: const [sansLien]));
      await tester.pumpAndSettle();

      // L'hebergement est bien la, avec son detour.
      expect(find.text('Refuge sans site'), findsOneWidget);
      expect(find.text(t.hebergement.detourAR(km: '4.2')), findsOneWidget);

      // Et apres lui, RIEN. On mesure l'absence du bouton ET l'absence du
      // blanc qui l'espacait : le dernier enfant de la colonne de la carte
      // est le detour, pas un SizedBox orphelin.
      expect(find.text(t.hebergement.openSite), findsNothing);
      expect(sansLien.hasDeeplink, isFalse);

      final colonne = tester.widget<Column>(
        find.descendant(
          of: find.byKey(const ValueKey('hebergement-hp-sans-lien')),
          matching: find.byType(Column),
        ),
      );
      expect(
        colonne.children.last,
        isNot(isA<SizedBox>()),
        reason:
            'VOIE V2 : un champ absent n affiche RIEN — pas meme l espace '
            'qui etait reserve au bouton',
      );
    });

    testWidgets('le bouton ouvre un deeplink sortant (facilitateur) quand le '
        'lien existe', (tester) async {
      await tester.pumpWidget(wrap(hebergements: const [_avecLien]));
      await tester.pumpAndSettle();

      expect(find.text(t.hebergement.openSite), findsOneWidget);
      await tester.tap(find.text(t.hebergement.openSite));
      await tester.pumpAndSettle();

      // Un deeplink a été ouvert (URL sortante), aucune réservation interne.
      expect(fakeLauncher.opened, [_avecLien.deeplinkUrl]);
    });

    testWidgets('affiche un message si le lien ne peut pas être ouvert', (
      tester,
    ) async {
      fakeLauncher.result = false;
      await tester.pumpWidget(wrap(hebergements: const [_avecLien]));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.hebergement.openSite));
      await tester.pump(); // laisse apparaître la SnackBar

      expect(find.text(t.hebergement.cannotOpen), findsOneWidget);
    });
  });
}
