import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/pyrenees_trail_config.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/features/trail_selection/presentation/trail_selection_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests F8D-02 : UI selection/bascule de sentier (moteur generique #84627).
///
/// Couvre : la liste reflete le catalogue, le sentier actif est marque (badge +
/// bouton desactive), et selectionner un autre sentier BASCULE la selection —
/// donc la config active ([trailConfigProvider]) qui propage tout le contexte.
void main() {
  Widget wrap({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(
        child: const MaterialApp(home: TrailSelectionScreen()),
      ),
    );
  }

  testWidgets('liste tous les sentiers du catalogue (multi-sentiers)',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trail-selection-list')), findsOneWidget);
    for (final trail in TrailCatalog.all) {
      expect(find.byKey(ValueKey('trail-choice-${trail.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('trail-select-${trail.id}')), findsOneWidget);
    }
  });

  testWidgets('le sentier actif porte le badge + bouton desactive',
      (tester) async {
    // Sentier actif force sur le defaut du catalogue.
    await tester.pumpWidget(wrap(overrides: [
      selectedTrailIdProvider.overrideWith((ref) => testTrailConfig.id),
    ]));
    await tester.pumpAndSettle();

    // Badge « actif » sur le sentier courant, pas sur l'autre.
    expect(find.byKey(ValueKey('trail-current-${testTrailConfig.id}')),
        findsOneWidget);
    expect(find.byKey(ValueKey('trail-current-${pyreneesTrailConfig.id}')),
        findsNothing);

    // Bouton du sentier actif desactive (deja selectionne), l'autre actif.
    final activeBtn = tester.widget<FilledButton>(
      find.byKey(ValueKey('trail-select-${testTrailConfig.id}')),
    );
    final otherBtn = tester.widget<FilledButton>(
      find.byKey(ValueKey('trail-select-${pyreneesTrailConfig.id}')),
    );
    expect(activeBtn.onPressed, isNull);
    expect(otherBtn.onPressed, isNotNull);
  });

  testWidgets('selectionner un autre sentier bascule la config active',
      (tester) async {
    // Container partage pour lire l'etat apres l'action de l'UI.
    final container = ProviderContainer(overrides: [
      selectedTrailIdProvider.overrideWith((ref) => testTrailConfig.id),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: const MaterialApp(home: TrailSelectionScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Etat initial : sentier de test actif.
    expect(container.read(trailConfigProvider).id, testTrailConfig.id);

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
    expect(find.byKey(ValueKey('trail-current-${pyreneesTrailConfig.id}')),
        findsOneWidget);
  });

  testWidgets('re-selectionner le sentier deja actif est un no-op',
      (tester) async {
    final container = ProviderContainer(overrides: [
      selectedTrailIdProvider.overrideWith((ref) => pyreneesTrailConfig.id),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: const MaterialApp(home: TrailSelectionScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Le bouton du sentier actif est desactive : aucun changement possible.
    final activeBtn = tester.widget<FilledButton>(
      find.byKey(ValueKey('trail-select-${pyreneesTrailConfig.id}')),
    );
    expect(activeBtn.onPressed, isNull);
    expect(container.read(selectedTrailIdProvider), pyreneesTrailConfig.id);
  });
}
