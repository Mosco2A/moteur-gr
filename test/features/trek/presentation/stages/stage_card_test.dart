import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/presentation/stages/stage_card.dart';

/// Tests du widget StageCard.
///
/// Verifie que la carte affiche le numero, le nom i18n,
/// la distance, le denivele positif et la duree estimee.
void main() {
  final testStage = Stage(
    id: 'stage-3',
    nameFr: 'Col de Vergio - Refuge de Manganu',
    nameEn: 'Vergio Pass - Manganu Refuge',
    nameDe: 'Vergio-Pass - Manganu-Huette',
    nameIt: 'Passo di Vergio - Rifugio Manganu',
    nameEs: 'Paso de Vergio - Refugio Manganu',
    distance: 15.2,
    elevationGain: 780,
    elevationLoss: 520,
    estimatedDurationMinutes: 330,
    difficulty: 'moderate',
    orderIndex: 3,
    startLat: 42.2833,
    startLng: 8.9167,
    endLat: 42.2500,
    endLng: 8.9833,
  );

  group('StageCard', () {
    testWidgets('affiche les infos correctes', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: StageCard(
              stage: testStage,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Numero d'ordre dans le CircleAvatar
      expect(find.text('3'), findsOneWidget);

      // Nom en francais (locale fr)
      expect(
        find.text('Col de Vergio - Refuge de Manganu'),
        findsOneWidget,
      );

      // Sous-titre : distance + D+ + duree
      // 15.2 km  .  780 m D+  .  5h30
      expect(find.textContaining('15.2 km'), findsOneWidget);
      expect(find.textContaining('780 m D+'), findsOneWidget);
      expect(find.textContaining('5h30'), findsOneWidget);

      // Tap declenche onTap
      await tester.tap(find.byType(StageCard));
      expect(tapped, isTrue);
    });
  });
}
