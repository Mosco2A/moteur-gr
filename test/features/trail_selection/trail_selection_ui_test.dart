import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/config/pyrenees_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/trail_selection/presentation/trail_selection_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';

/// Tests F8D-02 : UI selection/bascule de sentier (moteur generique #84627).
///
/// Couvre : la liste reflete le catalogue, le sentier actif est marque (badge +
/// bouton desactive), et selectionner un autre sentier BASCULE la selection —
/// donc la config active ([trailConfigProvider]) qui propage tout le contexte.

/// AppHeader (Ph5/L6d) utilise GoRouter -> heberge l'ecran dans un GoRouter
/// minimal (+ /my-treks pour l'accueil contextuel du bouton Accueil).
Widget _hostTrailSelection() => MaterialApp.router(
  routerConfig: GoRouter(
    initialLocation: '/trail-selection',
    routes: [
      GoRoute(
        path: '/trail-selection',
        builder: (_, __) => const TrailSelectionScreen(),
      ),
      GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
    ],
  ),
);

void main() {
  /// LA LISTE DES SENTIERS EST PLUS LONGUE DEPUIS LA TACHE 601 : le catalogue
  /// porte une entree de plus (le sentier de demonstration GRATUIT). Un ListView
  /// ne CONSTRUIT pas ce qui est hors champ, et les dernieres cartes semblaient
  /// donc absentes. On donne au test une fenetre assez haute pour porter tout le
  /// catalogue : la question posee ici est « la liste montre-t-elle TOUS les
  /// sentiers », pas « combien en tient-il sur un ecran de telephone ».
  void fenetreHaute(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Widget wrap({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(child: _hostTrailSelection()),
    );
  }

  testWidgets('liste tous les sentiers du catalogue (multi-sentiers)', (
    tester,
  ) async {
    fenetreHaute(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trail-selection-list')), findsOneWidget);
    final actif = TrailCatalog.defaultTrail.id;
    for (final trail in TrailCatalog.all) {
      expect(find.byKey(ValueKey('trail-choice-${trail.id}')), findsOneWidget);
      // TACHE 638 — LE SENTIER ACTIF N A PLUS DE BOUTON. Il portait un bouton
      // DESACTIVE qui repetait la pastille « actif » posee au-dessus, et qui
      // laissait dans l arbre une zone inerte : le balayage « aucun geste mort »
      // (tache 573) finissait par la taper en croyant taper un geste vivant. Un
      // etat n est pas une commande.
      expect(
        find.byKey(ValueKey('trail-select-${trail.id}')),
        trail.id == actif ? findsNothing : findsOneWidget,
        reason: trail.id == actif
            ? 'le sentier ACTIF n a rien a changer : pas de bouton'
            : 'chaque autre sentier garde son bouton de bascule',
      );
    }
  });

  testWidgets('le sentier actif porte le badge, et AUCUN bouton', (
    tester,
  ) async {
    fenetreHaute(tester);
    // Sentier actif force sur le defaut du catalogue.
    //
    // TACHE 793 — IL ETAIT FORCE SUR LE SENTIER FICTIF, dont le commentaire
    // disait deja « le defaut du catalogue » alors qu'il ne l'etait pas. Retire
    // du catalogue, il n'a plus de ligne dans la liste : le badge « actif »
    // n'aurait ete trouve nulle part. Les deux temoins sont desormais les deux
    // sentiers REELS du catalogue, et l'opposition testee — l'actif porte le
    // badge et aucun bouton, l'autre garde son bouton vivant — est intacte.
    await tester.pumpWidget(
      wrap(
        overrides: [
          selectedTrailIdProvider.overrideWith(
            (ref) => mareAMareCentreTrailConfig.id,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Badge « actif » sur le sentier courant, pas sur l'autre.
    expect(
      find.byKey(ValueKey('trail-current-${mareAMareCentreTrailConfig.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('trail-current-${pyreneesTrailConfig.id}')),
      findsNothing,
    );

    // TACHE 638 — LE SENTIER ACTIF N A PLUS DE BOUTON DU TOUT, et l autre garde
    // le sien, actif. Avant, le sentier actif portait un bouton DESACTIVE : un
    // etat deja dit par la pastille, double d une zone inerte dans l arbre que
    // le balayage « aucun geste mort » finissait par taper.
    expect(
      find.byKey(ValueKey('trail-select-${mareAMareCentreTrailConfig.id}')),
      findsNothing,
      reason: 'rien a changer sur le sentier deja actif',
    );
    final otherBtn = tester.widget<AppButton>(
      find.byKey(ValueKey('trail-select-${pyreneesTrailConfig.id}')),
    );
    expect(otherBtn.onPressed, isNotNull);
  });

  testWidgets('selectionner un autre sentier bascule la config active', (
    tester,
  ) async {
    fenetreHaute(tester);
    // Container partage pour lire l'etat apres l'action de l'UI.
    final container = ProviderContainer(
      overrides: [
        selectedTrailIdProvider.overrideWith(
          (ref) => mareAMareCentreTrailConfig.id,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(child: _hostTrailSelection()),
      ),
    );
    await tester.pumpAndSettle();

    // Etat initial : sentier de test actif.
    expect(
      container.read(trailConfigProvider).id,
      mareAMareCentreTrailConfig.id,
    );

    // Bascule vers le sentier Pyrenees (1er hors Corse).
    await tester.tap(
      find.byKey(ValueKey('trail-select-${pyreneesTrailConfig.id}')),
    );
    await tester.pumpAndSettle();

    // La selection ET la config active ont bascule -> propagation a toute l'app.
    expect(container.read(selectedTrailIdProvider), pyreneesTrailConfig.id);
    expect(container.read(trailConfigProvider).id, pyreneesTrailConfig.id);
    expect(container.read(trailIdProvider), pyreneesTrailConfig.id);

    // Le badge « actif » a suivi (Pyrenees maintenant marque).
    await tester.pump();
    expect(
      find.byKey(ValueKey('trail-current-${pyreneesTrailConfig.id}')),
      findsOneWidget,
    );
  });

  testWidgets('le sentier deja actif n offre AUCUN geste a re-jouer', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        selectedTrailIdProvider.overrideWith((ref) => pyreneesTrailConfig.id),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(child: _hostTrailSelection()),
      ),
    );
    await tester.pumpAndSettle();

    // TACHE 638 — LE GESTE N EXISTE PLUS, donc il ne peut plus etre inerte.
    // C est la garantie la plus forte du « no-op » qu on puisse donner : au lieu
    // d un bouton desactive qu on peut encore designer, il n y a rien a designer.
    // Le garde-fou du moteur reste en place par ailleurs (`_selectTrail` sort
    // immediatement si le sentier est deja actif) : la porte est fermee des DEUX
    // cotes, a l ecran et dans le code.
    expect(
      find.byKey(ValueKey('trail-select-${pyreneesTrailConfig.id}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('trail-current-${pyreneesTrailConfig.id}')),
      findsOneWidget,
      reason: 'et l etat actif se VOIT, par la pastille',
    );
    expect(container.read(selectedTrailIdProvider), pyreneesTrailConfig.id);
  });
}
