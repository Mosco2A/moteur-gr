import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/eta_service.dart';
import 'package:moteur_gr/features/trek/presentation/eta_widget.dart';
import 'package:moteur_gr/features/trek/providers/eta_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

EtaInput _input({bool degraded = false}) => EtaInput(
      distanceToWaypointM: 1100,
      ascentToWaypointM: 0,
      descentToWaypointM: 0,
      distanceToStageEndM: 5500,
      ascentToStageEndM: 0,
      descentToStageEndM: 0,
      observedPaceMps: 1.1,
      gpsDegraded: degraded,
    );

/// Tests widget de l'affichage ETA (F6B-02).
///
/// Vérifie : rien affiché sans estimation, affichage des deux ETA + libellés,
/// et l'indicateur de confiance basse en GPS dégradé.
void main() {
  Widget wrap(ProviderContainer container) => UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: const MaterialApp(home: Scaffold(body: EtaWidget())),
        ),
      );

  testWidgets('rien affiché tant qu aucune estimation', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNothing);
  });

  testWidgets('affiche le titre, les deux ETA et la confiance fiable',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Seed une estimation via le contrôleur (événement).
    container
        .read(etaControllerProvider.notifier)
        .onEvent(_input(), now: DateTime(2026, 6, 14, 8));

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text(t.eta.title), findsOneWidget);
    expect(find.text(t.eta.toNextWaypoint), findsOneWidget);
    expect(find.text(t.eta.toStageEnd), findsOneWidget);
    expect(find.text(t.eta.confidenceHigh), findsOneWidget);
  });

  testWidgets('affiche la confiance basse quand GPS dégradé', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(etaControllerProvider.notifier)
        .onEvent(_input(degraded: true), now: DateTime(2026, 6, 14, 8));

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text(t.eta.confidenceLow), findsOneWidget);
  });
}
