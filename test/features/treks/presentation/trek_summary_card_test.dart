import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_summary.dart';
import 'package:moteur_gr/features/treks/presentation/widgets/trek_summary_card.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// StepWays LOT 2, Phase 4 — [TrekSummaryCard].
///
/// Verifie le badge d'etat (un par [TrekLifecycleState]) et la barre de
/// progression (masquee si termine/vierge), ainsi que le geste de selection.
TrailConfig _config(String id, {int stages = 10}) => TrailConfig(
      id: id,
      name: id,
      displayName: 'Trek $id',
      tagline: 't',
      totalStages: stages,
      totalDistanceKm: 100,
      totalElevationGain: 5000,
      region: 'Corse',
      country: 'France',
      primaryColorValue: 0xFF2E7D32,
      secondaryColorValue: 0xFF1565C0,
      gpxAssetPath: 'assets/gpx/$id.gpx',
    );

void main() {
  Widget wrap(Widget child) => TranslationProvider(
        child: MaterialApp(home: Scaffold(body: child)),
      );

  TrekSummary summary(TrekLifecycleState state) => TrekSummary(
        config: _config('gr20'),
        state: state,
      );

  testWidgets('badge affiche le libelle de chaque etat', (tester) async {
    for (final entry in <TrekLifecycleState, String>{
      TrekLifecycleState.owned: t.myTreks.badge.owned,
      TrekLifecycleState.prepared: t.myTreks.badge.prepared,
      TrekLifecycleState.inProgress: t.myTreks.badge.inProgress,
      TrekLifecycleState.completed: t.myTreks.badge.completed,
    }.entries) {
      await tester.pumpWidget(
        wrap(TrekSummaryCard(summary: summary(entry.key), onTap: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget,
          reason: 'badge attendu pour ${entry.key}');
      expect(find.byKey(ValueKey('trek-state-badge-${entry.key.name}')),
          findsOneWidget);
    }
  });

  testWidgets('titre + region + stats rendus (calque catalogue)',
      (tester) async {
    await tester.pumpWidget(
      wrap(TrekSummaryCard(
        summary: summary(TrekLifecycleState.owned),
        onTap: () {},
      )),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trek gr20'), findsOneWidget);
    expect(find.textContaining('Corse'), findsOneWidget);
    // Cle Slang partagee avec l'ecran de selection (etapes - km).
    expect(
      find.text(t.trailSelection.stagesDistance(stages: 10, km: '100')),
      findsOneWidget,
    );
  });

  testWidgets('barre de progression ABSENTE pour un trek termine',
      (tester) async {
    // completed -> progressFraction = 1.0, mais on masque la barre (badge suffit).
    await tester.pumpWidget(
      wrap(TrekSummaryCard(
        summary: summary(TrekLifecycleState.completed),
        onTap: () {},
      )),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('barre de progression ABSENTE pour un trek vierge (0 %)',
      (tester) async {
    await tester.pumpWidget(
      wrap(TrekSummaryCard(
        summary: summary(TrekLifecycleState.owned),
        onTap: () {},
      )),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('onTap declenche la selection', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrap(TrekSummaryCard(
        summary: summary(TrekLifecycleState.prepared),
        onTap: () => tapped++,
      )),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trek-summary-gr20')));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });
}
