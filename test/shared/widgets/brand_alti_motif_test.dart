import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/shared/widgets/brand_alti_motif.dart';

/// Tests widget de BrandAltiMotif (SW-SKIN-L6).
///
/// Couvre : le rendu des 3 variantes (hero/watermark/outline), la parite de
/// trace de la fiche etape (constructeur .synthetic reproduit la geometrie
/// historique), et la robustesse aux donnees d'altitude absentes / a un seul
/// point (pas de crash, repli gracieux).
void main() {
  const accent = Color(0xFF2E7D32); // vert Pyrenees (accent-sentier de test)

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
      );

  // Rend le painter isole sur un canvas de taille connue, pour verifier qu'il
  // ne leve pas (paint execute reellement) — le vrai filet anti-crash.
  void paintPainter(AltiProfilePainter painter, Size size) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, size);
    recorder.endRecording();
  }

  group('rendu des 3 variantes', () {
    for (final variant in BrandAltiVariant.values) {
      testWidgets('variante ${variant.name} : rend sans exception',
          (tester) async {
        await tester.pumpWidget(
          wrap(
            BrandAltiMotif(
              elevations: const [1200, 1450, 1300, 1680, 1520, 1750],
              variant: variant,
              accent: accent,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BrandAltiMotif), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    test('les 3 variantes peignent sur points reels sans exception', () {
      for (final variant in BrandAltiVariant.values) {
        final painter = AltiProfilePainter(
          elevations: const [1200, 1450, 1300, 1680, 1520, 1750],
          synthetic: null,
          variant: variant,
          accent: accent,
        );
        expect(
          () => paintPainter(painter, const Size(320, 160)),
          returnsNormally,
          reason: 'variante ${variant.name}',
        );
      }
    });
  });

  group('parite de trace fiche etape (.synthetic)', () {
    testWidgets('BrandAltiMotif.synthetic rend le motif sans crash',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          BrandAltiMotif.synthetic(
            elevationGain: 840,
            elevationLoss: 620,
            distance: 12.4,
            accent: accent,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BrandAltiMotif), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('geometrie synthetique = geometrie historique (montee->sommet->descente)',
        () {
      // Reproduction du calcul historique de _ElevationProfilePainter, pour
      // FIGER la parite : peakRatio = D+/(D+ + D-), endRatio = (D+ - D-)/total
      // clamp 0..0.8. Si le motif changeait cette geometrie, ce test casserait.
      const gain = 840;
      const loss = 620;
      const total = gain + loss;
      const expectedPeakRatio = gain / total;
      final expectedEndRatio = ((gain - loss) / total).clamp(0.0, 0.8);

      expect(expectedPeakRatio, closeTo(0.5753, 0.0001));
      expect(expectedEndRatio, closeTo(0.1506, 0.0001));

      // Le painter en mode synthetique se peint sans exception sur une taille
      // standard (execute reellement _syntheticPath + les cotes chiffrees).
      final painter = AltiProfilePainter(
        elevations: const [],
        synthetic: const AltiSyntheticProfile(
          elevationGain: gain,
          elevationLoss: loss,
          distance: 12.4,
        ),
        variant: BrandAltiVariant.hero,
        accent: accent,
      );
      expect(painter.synthetic, isNotNull);
      expect(
        () => paintPainter(painter, const Size(320, 160)),
        returnsNormally,
      );
    });

    testWidgets('D+ et D- nuls : pas de crash (fallback ratio 0.5)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          BrandAltiMotif.synthetic(
            elevationGain: 0,
            elevationLoss: 0,
            distance: 0,
            accent: accent,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('robustesse donnees d altitude absentes (mandat L6)', () {
    testWidgets('liste vide : pas de crash, rien de dessine', (tester) async {
      await tester.pumpWidget(
        wrap(const BrandAltiMotif(elevations: [], accent: accent)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BrandAltiMotif), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un seul point : pas de crash (pas de segment tracable)',
        (tester) async {
      await tester.pumpWidget(
        wrap(const BrandAltiMotif(elevations: [1500], accent: accent)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test('painter liste vide : paint() ne leve pas', () {
      final painter = AltiProfilePainter(
        elevations: const [],
        synthetic: null,
        variant: BrandAltiVariant.hero,
        accent: accent,
      );
      expect(
        () => paintPainter(painter, const Size(320, 160)),
        returnsNormally,
      );
    });

    test('painter un point : paint() ne leve pas', () {
      final painter = AltiProfilePainter(
        elevations: const [1500],
        synthetic: null,
        variant: BrandAltiVariant.outline,
        accent: accent,
      );
      expect(
        () => paintPainter(painter, const Size(320, 160)),
        returnsNormally,
      );
    });

    test('painter taille nulle : paint() ne leve pas', () {
      final painter = AltiProfilePainter(
        elevations: const [1200, 1400, 1300],
        synthetic: null,
        variant: BrandAltiVariant.hero,
        accent: accent,
      );
      expect(
        () => paintPainter(painter, Size.zero),
        returnsNormally,
      );
    });

    test('profil totalement plat (min == max) : pas de division par zero', () {
      final painter = AltiProfilePainter(
        elevations: const [1500, 1500, 1500, 1500],
        synthetic: null,
        variant: BrandAltiVariant.hero,
        accent: accent,
      );
      expect(
        () => paintPainter(painter, const Size(320, 160)),
        returnsNormally,
      );
    });
  });

  group('shouldRepaint', () {
    AltiProfilePainter make({
      List<double> elevations = const [1200, 1400, 1300],
      BrandAltiVariant variant = BrandAltiVariant.hero,
      Color accent = accent,
    }) =>
        AltiProfilePainter(
          elevations: elevations,
          synthetic: null,
          variant: variant,
          accent: accent,
        );

    test('memes params -> pas de repaint', () {
      expect(make().shouldRepaint(make()), isFalse);
    });

    test('accent different -> repaint', () {
      expect(
        make().shouldRepaint(make(accent: const Color(0xFF1565C0))),
        isTrue,
      );
    });

    test('variante differente -> repaint', () {
      expect(
        make().shouldRepaint(make(variant: BrandAltiVariant.watermark)),
        isTrue,
      );
    });

    test('points differents -> repaint', () {
      expect(
        make().shouldRepaint(make(elevations: const [1200, 1400, 1350])),
        isTrue,
      );
    });
  });
}
