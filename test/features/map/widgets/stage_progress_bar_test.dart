import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/map/widgets/stage_progress_bar.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  Widget buildBar({
    String stageName = 'Etape 1',
    double distanceRemainingKm = 5.3,
    double progressRatio = 0.45,
    bool isOffTrack = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: StageProgressBar(
          stageName: stageName,
          distanceRemainingKm: distanceRemainingKm,
          progressRatio: progressRatio,
          isOffTrack: isOffTrack,
        ),
      ),
    );
  }

  group('StageProgressBar', () {
    testWidgets('affiche le nom de l etape', (tester) async {
      await tester.pumpWidget(buildBar(stageName: 'Etape 3'));
      expect(find.text('Etape 3'), findsOneWidget);
    });

    testWidgets('affiche la distance restante', (tester) async {
      await tester.pumpWidget(buildBar(distanceRemainingKm: 7.2));
      expect(find.text(t.map.stageRemaining(km: '7.2')), findsOneWidget);
    });

    testWidgets('affiche le pourcentage', (tester) async {
      await tester.pumpWidget(buildBar(progressRatio: 0.65));
      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('affiche indicateur hors trace', (tester) async {
      await tester.pumpWidget(buildBar(isOffTrack: true));
      expect(find.text(t.map.offTrackChip), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('cache indicateur hors trace quand sur le trace',
        (tester) async {
      await tester.pumpWidget(buildBar(isOffTrack: false));
      expect(find.text(t.map.offTrackChip), findsNothing);
    });

    testWidgets('contient un LinearProgressIndicator', (tester) async {
      await tester.pumpWidget(buildBar());
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('le pourcentage a 0 pourcent affiche 0%', (tester) async {
      await tester.pumpWidget(buildBar(progressRatio: 0.0));
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('le pourcentage a 100 pourcent affiche 100%', (tester) async {
      await tester.pumpWidget(buildBar(progressRatio: 1.0));
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
