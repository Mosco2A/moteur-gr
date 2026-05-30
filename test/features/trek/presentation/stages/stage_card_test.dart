import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/presentation/stages/stage_card.dart';

/// Tests du widget StageCard (Phase 2 E2.4b).
///
/// Verifie que StageCard affiche les informations correctes :
/// numero, nom i18n, distance, denivele, duree, et callback onTap.
void main() {
  /// Stage de test avec toutes les valeurs remplies.
  const testStage = Stage(
    id: 'stage-1',
    nameFr: 'Col de Vergio',
    nameEn: 'Vergio Pass',
    nameDe: 'Vergio-Pass',
    nameIt: 'Passo di Vergio',
    nameEs: 'Collado de Vergio',
    distance: 14.5,
    elevationGain: 850,
    elevationLoss: 620,
    estimatedDurationSeconds: 19800, // 5h30
    orderIndex: 3,
    startLat: 42.28,
    startLng: 9.07,
    endLat: 42.30,
    endLng: 9.10,
  );

  /// Helper pour wrapper un widget avec MaterialApp + locale.
  Widget buildApp({
    required Widget child,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );
  }

  group('StageCard E2.4b', () {
    testWidgets('affiche numero, nom, distance, D+ et duree', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildApp(
          child: StageCard(
            stage: testStage,
            onTap: () => tapped = true,
          ),
        ),
      );

      // Numero dans le CircleAvatar
      expect(find.text('3'), findsOneWidget);

      // Nom anglais (locale par defaut = en)
      expect(find.text('Vergio Pass'), findsOneWidget);

      // Sous-titre : distance + D+ + duree
      expect(find.text('14.5 km  D+ 850 m  5h30'), findsOneWidget);

      // Chevron de navigation
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Tap fonctionne — cibler le StageCard directement
      await tester.tap(find.byType(StageCard));
      expect(tapped, isTrue);
    });

    testWidgets('affiche le nom francais quand locale fr et fallback',
        (tester) async {
      // Stage sans traduction anglaise — fallback nameFr
      const stageFrOnly = Stage(
        id: 'stage-fr',
        nameFr: 'Col de Vergio',
        distance: 14.5,
        elevationGain: 850,
        elevationLoss: 620,
        orderIndex: 3,
        startLat: 42.28,
        startLng: 9.07,
        endLat: 42.30,
        endLng: 9.10,
      );

      await tester.pumpWidget(
        buildApp(
          child: StageCard(
            stage: stageFrOnly,
            onTap: () {},
          ),
        ),
      );

      // Locale en mais nameEn vide → fallback nameFr
      expect(find.text('Col de Vergio'), findsOneWidget);
    });

    testWidgets('fallback nameFr si traduction vide', (tester) async {
      const stageNoEn = Stage(
        id: 'stage-2',
        nameFr: 'Refuge de Manganu',
        nameEn: '', // vide
        distance: 12.0,
        elevationGain: 600,
        elevationLoss: 400,
        orderIndex: 5,
        startLat: 42.15,
        startLng: 9.05,
        endLat: 42.18,
        endLng: 9.08,
      );

      await tester.pumpWidget(
        buildApp(
          locale: const Locale('en'),
          child: StageCard(
            stage: stageNoEn,
            onTap: () {},
          ),
        ),
      );

      // Doit afficher le nom francais en fallback
      expect(find.text('Refuge de Manganu'), findsOneWidget);
    });

    testWidgets('sous-titre sans duree quand estimatedDurationSeconds = 0',
        (tester) async {
      const stageNoDuration = Stage(
        id: 'stage-3',
        nameFr: 'Etape courte',
        nameEn: 'Short stage',
        distance: 8.0,
        elevationGain: 300,
        elevationLoss: 200,
        orderIndex: 1,
        startLat: 42.0,
        startLng: 9.0,
        endLat: 42.05,
        endLng: 9.05,
      );

      await tester.pumpWidget(
        buildApp(
          child: StageCard(
            stage: stageNoDuration,
            onTap: () {},
          ),
        ),
      );

      // Sous-titre sans duree
      expect(find.text('8.0 km  D+ 300 m'), findsOneWidget);
    });
  });
}
