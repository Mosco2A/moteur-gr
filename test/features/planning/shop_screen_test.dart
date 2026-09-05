import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/planning/domain/shop_catalog.dart';
import 'package:moteur_gr/features/planning/domain/shop_info.dart';
import 'package:moteur_gr/features/planning/presentation/shop_screen.dart';
import 'package:moteur_gr/features/planning/providers/shop_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// PARITE GR20 (#99460) — ecran RAVITAILLEMENT (« Commerces & services par
/// etape », data-driven).
///
/// Clone de l'ecran GR20 `ShopDetailScreen` : filtres par type
/// (epicerie/bar/pharmacie/gaz), alerte « ravitaillement limite » DATA-DRIVEN,
/// liste des commerces groupee par ETAPE, alerte de « gap » (etapes sans
/// commerce), bottom sheet detail — contenu venant du catalogue ravitaillement
/// du sentier ([trailShopsProvider]), PAS de `const gr20Shops` hardcode. Moteur
/// GENERIQUE multi-sentiers (#84627), zero hardcode ; fallback gracieux.
///
/// Couverture :
///   - modele/logique : gap, seuil, supplyStages, filtre (domaine pur) ;
///   - catalogue Mare a Mare Centre : commerces reels des localites du sentier,
///     zero commerce GR20 recopie, honnetete des manques ;
///   - ecran : filtres (selection/deselection filtre la liste), liste groupee
///     par etape, alerte gap, bottom sheet detail (infos + produits) ;
///   - data-driven : aucun commerce en dur dans le moteur (source = catalogue) ;
///   - fallback sans donnees + isolation multi-sentier (par trailId) ;
///   - la carte HUB « Ravitaillement » ouvre l'ecran, retour sans crash.
void main() {
  const trailId = 'test-trail';

  setUpAll(() {
    LocaleSettings.setLocaleRaw('fr');
  });

  // --- Fixtures ------------------------------------------------------------

  Shop shop(
    String name,
    ShopKind type,
    int stage, {
    List<String> products = const ['Alimentation', 'Boissons'],
    String hours = '8h-19h',
    double? lat,
    double? lon,
    String phone = '',
    String? website,
  }) =>
      Shop(
        name: name,
        type: type,
        stageNumber: stage,
        products: products,
        openingHours: hours,
        latitude: lat,
        longitude: lon,
        phone: phone,
        website: website,
      );

  /// Donnees de test : commerces aux etapes 1 et 4 (gap de 3 apres l'etape 1,
  /// au-dela du seuil 2 -> alerte). Un commerce porte tel + site (extension).
  TrailShops testShops({int gapThreshold = 2, String note = 'Note test'}) =>
      TrailShops(
        trailId: trailId,
        gapThreshold: gapThreshold,
        limitedSupplyNote: note,
        shops: [
          shop('Epicerie Alpha', ShopKind.epicerie, 1,
              products: ['Pain', 'Fromage', 'Eau', 'Gaz', 'Cinquieme produit'],
              lat: 42.0, lon: 9.0, phone: '+33123456789',
              website: 'https://example.org/alpha'),
          shop('Pharmacie Alpha', ShopKind.pharmacie, 1),
          shop('Bar Delta', ShopKind.bar, 4, hours: ''),
        ],
      );

  List<Override> overridesWith(TrailShops? data) => [
        trailShopsProvider(trailId).overrideWithValue(data),
        // Filtre par defaut « Tous » (aucun filtre) — etat propre par test.
        shopTypeFilterProvider.overrideWith((ref) => null),
      ];

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int maxFrames = 40,
  }) async {
    for (var i = 0; i < maxFrames; i++) {
      if (tester.widgetList(finder).isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpUntilGone(
    WidgetTester tester,
    Finder finder, {
    int maxFrames = 40,
  }) async {
    for (var i = 0; i < maxFrames; i++) {
      if (tester.widgetList(finder).isEmpty) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Widget wrap({required List<Override> overrides}) {
    final router = GoRouter(
      initialLocation: '/t',
      routes: [
        GoRoute(
          path: '/t',
          builder: (_, __) => const ShopScreen(trailId: trailId),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  // --- Domaine (modele + logique de gap, pur) ------------------------------

  group('modele TrailShops (logique de gap, generique)', () {
    test('supplyStages : etapes uniques triees portant un commerce', () {
      final data = testShops();
      expect(data.supplyStages, [1, 4]);
    });

    test('shopsForStage : filtre par etape', () {
      final data = testShops();
      expect(data.shopsForStage(1).length, 2);
      expect(data.shopsForStage(4).length, 1);
      expect(data.shopsForStage(2), isEmpty);
    });

    test('gapAfter : ecart au prochain point de ravitaillement', () {
      final data = testShops();
      // Apres l'etape 1, le prochain commerce est a l'etape 4 -> gap 3.
      expect(data.gapAfter(1), 3);
      // Apres l'etape 4, plus de commerce -> gap 0 (dernier point).
      expect(data.gapAfter(4), 0);
    });

    test('isGapAlert : alerte si gap > seuil (parite GR20 gap > 2)', () {
      final data = testShops(gapThreshold: 2);
      expect(data.isGapAlert(1), isTrue); // gap 3 > 2
      expect(data.isGapAlert(4), isFalse); // gap 0
      // Seuil configurable : releve a 3 -> plus d'alerte a l'etape 1.
      final relaxed = testShops(gapThreshold: 3);
      expect(relaxed.isGapAlert(1), isFalse); // gap 3 non > 3
    });

    test('un seul commerce : pas d\'alerte, pas de crash', () {
      const data = TrailShops(
        trailId: trailId,
        shops: [Shop(name: 'Unique', type: ShopKind.epicerie, stageNumber: 2)],
      );
      expect(data.gapAfter(2), 0);
      expect(data.isGapAlert(2), isFalse);
      expect(data.supplyStages, [2]);
    });

    test('zero commerce : hasShops faux, listes vides', () {
      const data = TrailShops(trailId: trailId);
      expect(data.hasShops, isFalse);
      expect(data.supplyStages, isEmpty);
      expect(data.gapAfter(1), 0);
    });

    test('fromJson tolerant : type inconnu -> epicerie, GPS absent -> null', () {
      final s = Shop.fromJson({
        'name': 'X',
        'type': 'inconnu',
        'stageNumber': 2,
        'products': ['A'],
      });
      expect(s.type, ShopKind.epicerie);
      expect(s.hasCoordinates, isFalse);
      expect(s.latitude, isNull);
    });
  });

  // --- Catalogue Mare a Mare Centre (donnees reelles, honnetete) -----------

  group('catalogue Mare a Mare Centre', () {
    test('fournit des commerces pour le sentier vitrine', () {
      final data = ShopCatalog.forTrail('mare-a-mare-centre');
      expect(data, isNotNull);
      expect(data!.hasShops, isTrue);
    });

    test('commerces rattaches aux localites-etapes reelles (1..7)', () {
      final data = ShopCatalog.forTrail('mare-a-mare-centre')!;
      // Toutes les etapes portees existent dans le sentier (7 etapes).
      for (final st in data.supplyStages) {
        expect(st, inInclusiveRange(1, 7));
      }
      // Depart (Ghisonaccia, etape 1) et arrivee (Porticcio, etape 7) couverts.
      expect(data.shopsForStage(1), isNotEmpty);
      expect(data.shopsForStage(7), isNotEmpty);
    });

    test('AUCUN commerce corse du GR20 recopie (Calenzana/Vizzavona/Conca...)',
        () {
      final data = ShopCatalog.forTrail('mare-a-mare-centre')!;
      final names = data.shops.map((s) => s.name.toLowerCase()).join(' | ');
      for (final gr20Place in [
        'calenzana',
        'haut-asco',
        'vizzavona',
        'bavella',
        'conca',
        'castel',
      ]) {
        expect(names.contains(gr20Place), isFalse,
            reason: 'ne doit pas contenir le lieu GR20 "$gr20Place"');
      }
    });

    test('honnetete : entrees a completer explicites, pas de GPS 0,0 invente',
        () {
      final data = ShopCatalog.forTrail('mare-a-mare-centre')!;
      // Au moins une entree signale honnetement un manque (« a completer » /
      // « a verifier »), plutot qu'inventer.
      final hasHonestGap = data.shops.any((s) =>
          s.openingHours.toLowerCase().contains('completer') ||
          s.name.toLowerCase().contains('verifier'));
      expect(hasHonestGap, isTrue);
      // Aucune coordonnee (0,0) bidon : soit GPS absent, soit coords plausibles.
      for (final s in data.shops) {
        if (s.hasCoordinates) {
          expect(s.latitude != 0 || s.longitude != 0, isTrue);
        }
      }
    });

    test('un sentier inconnu ne fournit pas de donnees (fallback UI)', () {
      expect(ShopCatalog.forTrail('sentier-inexistant'), isNull);
    });
  });

  // --- Ecran : filtres + liste groupee par etape ---------------------------

  group('ecran ravitaillement (filtres + liste)', () {
    testWidgets('affiche titre, alerte data-driven et cartes commerces',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: overridesWith(testShops())));
      await settle(tester);

      expect(find.text(t.shop.title), findsOneWidget);
      // Alerte « ravitaillement limite » DATA-DRIVEN (note du sentier affichee).
      expect(find.text(t.shop.limitedTitle), findsOneWidget);
      expect(find.text('Note test'), findsOneWidget);
      // Cartes commerces (donnees du sentier).
      expect(find.text('Epicerie Alpha'), findsOneWidget);
      expect(find.text('Pharmacie Alpha'), findsOneWidget);
      expect(find.text('Bar Delta'), findsOneWidget);
    });

    testWidgets('alerte « ravitaillement limite » masquee si pas de note',
        (tester) async {
      await tester.pumpWidget(
        wrap(overrides: overridesWith(testShops(note: ''))),
      );
      await settle(tester);
      // Sans note data-driven, le bandeau d'alerte est masque proprement.
      expect(find.text(t.shop.limitedTitle), findsNothing);
      // Les commerces restent affiches.
      expect(find.text('Epicerie Alpha'), findsOneWidget);
    });

    testWidgets('liste groupee par etape (en-tetes d\'etape presents)',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: overridesWith(testShops())));
      await settle(tester);
      // En-tetes d'etape (regroupement data-driven) : etape 1 et etape 4
      // presents. Le libelle « Etape N » sert AUSSI de badge sur chaque carte
      // (parite GR20), donc findsWidgets (>=1), pas findsOneWidget.
      expect(find.text(t.shop.stageHeader(n: 1)), findsWidgets);
      expect(find.text(t.shop.stageHeader(n: 4)), findsWidgets);

      // Regroupement effectif : en filtrant sur « Pharmacie » (uniquement a
      // l'etape 1), le groupe/en-tete de l'etape 4 disparait entierement.
      await tester.tap(find.text(t.shop.typePharmacie));
      await settle(tester);
      expect(find.text(t.shop.stageHeader(n: 4)), findsNothing);
      expect(find.text(t.shop.stageHeader(n: 1)), findsWidgets);
    });

    testWidgets('filtre par type : selection filtre la liste', (tester) async {
      await tester.pumpWidget(wrap(overrides: overridesWith(testShops())));
      await settle(tester);

      // Taper le filtre « Pharmacie » -> ne reste que la pharmacie.
      await tester.tap(find.text(t.shop.typePharmacie));
      await settle(tester);
      expect(find.text('Pharmacie Alpha'), findsOneWidget);
      expect(find.text('Epicerie Alpha'), findsNothing);
      expect(find.text('Bar Delta'), findsNothing);
    });

    testWidgets('filtre par type : re-taper deselectionne (retour a Tous)',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: overridesWith(testShops())));
      await settle(tester);

      await tester.tap(find.text(t.shop.typePharmacie));
      await settle(tester);
      expect(find.text('Epicerie Alpha'), findsNothing);

      // Re-taper la meme puce -> retour a « Tous » (toggle, parite GR20).
      await tester.tap(find.text(t.shop.typePharmacie));
      await settle(tester);
      expect(find.text('Epicerie Alpha'), findsOneWidget);
      expect(find.text('Bar Delta'), findsOneWidget);
    });

    testWidgets('alerte gap affichee sur une carte au-dela du seuil',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: overridesWith(testShops())));
      await settle(tester);
      // Gap de 3 apres l'etape 1 (> seuil 2) -> texte d'alerte court present.
      expect(find.text(t.shop.gapShort(n: 3)), findsWidgets);
    });
  });

  // --- Bottom sheet detail -------------------------------------------------

  group('bottom sheet detail', () {
    testWidgets('tap sur une carte ouvre le detail (infos + produits complets)',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: overridesWith(testShops())));
      await settle(tester);

      await tester.tap(find.text('Epicerie Alpha'));
      await settle(tester);

      // Sections du detail (parite GR20).
      expect(find.text(t.shop.sectionInfo), findsOneWidget);
      expect(find.text(t.shop.sectionProducts), findsOneWidget);
      // Le 5e produit (non montre dans l'apercu a 4) apparait dans le detail.
      expect(find.text('Cinquieme produit'), findsOneWidget);
      // Champ GPS present (coords fournies pour ce commerce).
      expect(find.text(t.shop.fieldGps), findsOneWidget);
      // Contact tel (extension StepWays) cliquable.
      expect(find.text('+33123456789'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('detail sans GPS : ligne GPS masquee (honnetete #99460)',
        (tester) async {
      // Bar Delta n'a pas de coords ni d'horaire (etape 4, plus bas dans la
      // liste) : on l'amene a l'ecran avant de taper (evite un tap manque).
      await tester.pumpWidget(wrap(overrides: overridesWith(testShops())));
      await settle(tester);

      final card = find.text('Bar Delta');
      await tester.ensureVisible(card);
      await settle(tester);
      await tester.tap(card);
      await settle(tester);
      // Attendre l'ouverture du bottom sheet (section Informations montee).
      await pumpUntil(tester, find.text(t.shop.sectionInfo));

      // Le type reste affiche (info toujours presente).
      expect(find.text(t.shop.fieldType), findsOneWidget);
      // Pas de ligne GPS (coords null -> masquee, pas de 0,0 faux).
      expect(find.text(t.shop.fieldGps), findsNothing);
    });
  });

  // --- Data-driven & isolation multi-sentier -------------------------------

  group('data-driven & multi-sentier', () {
    test('aucun commerce en dur dans le moteur : source = catalogue', () {
      // Le catalogue est la SEULE source ; un id inconnu -> null (pas de defaut
      // hardcode qui fuiterait des commerces).
      expect(ShopCatalog.forTrail('autre-sentier'), isNull);
    });

    test('isolation par trailId : chaque sentier a ses propres donnees', () {
      final mam = ShopCatalog.forTrail('mare-a-mare-centre');
      final other = ShopCatalog.forTrail('inconnu');
      expect(mam, isNotNull);
      expect(other, isNull);
      // Le trailId du catalogue correspond bien au sentier demande.
      expect(mam!.trailId, 'mare-a-mare-centre');
    });
  });

  // --- Fallback sans donnees -----------------------------------------------

  group('fallback sans donnees ravitaillement', () {
    testWidgets('sentier sans donnees : etat informatif propre, pas de crash',
        (tester) async {
      await tester.pumpWidget(wrap(overrides: overridesWith(null)));
      await settle(tester);

      expect(find.text(t.shop.empty.title), findsOneWidget);
      expect(find.text(t.shop.title), findsOneWidget); // AppBar reste
      expect(tester.takeException(), isNull);
    });

    testWidgets('sentier avec liste vide : meme fallback propre',
        (tester) async {
      await tester.pumpWidget(
        wrap(overrides: overridesWith(const TrailShops(trailId: trailId))),
      );
      await settle(tester);
      expect(find.text(t.shop.empty.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // --- Navigation depuis le HUB --------------------------------------------

  group('navigation', () {
    testWidgets(
        'la carte HUB « Ravitaillement » ouvre l\'ecran, retour sans crash',
        (tester) async {
      // Routeur minimal reproduisant l'entree HUB : une carte
      // `Icons.shopping_cart` (comme le HUB) qui `push` vers Ravitaillement.
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: InkWell(
                  onTap: () => context.push('/trail/$trailId/shop'),
                  child: const Icon(Icons.shopping_cart),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/trail/:id/shop',
            builder: (context, state) => ShopScreen(
              trailId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: overridesWith(testShops()),
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ));
      await settle(tester);

      // Aller : taper la carte HUB (icone shopping_cart) ouvre Ravitaillement.
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await settle(tester);
      await pumpUntil(tester, find.text(t.shop.title));
      expect(find.text(t.shop.title), findsWidgets);

      // Retour : bouton back de l'AppBar (Icons.arrow_back) -> retour au HUB
      // sans crash (pile preservee, jamais context.go qui viderait la pile).
      await pumpUntil(tester, find.byIcon(Icons.arrow_back));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);
      await pumpUntilGone(tester, find.text(t.shop.title));
      expect(find.text(t.shop.title), findsNothing);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });
  });
}
