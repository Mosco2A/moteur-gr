// Test miroir de `lib/features/trek/providers/podometre_providers.dart` (lot
// 671-02) : le seul endroit ou lire le podometre, et l'etat de l'estime.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/podometre_permission_service.dart';
import 'package:moteur_gr/features/trek/data/podometre_preferences.dart';
import 'package:moteur_gr/features/trek/domain/accumulateur_de_pas.dart';
import 'package:moteur_gr/features/trek/domain/longueur_de_pas.dart';
import 'package:moteur_gr/features/trek/providers/podometre_providers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('671-02 — l estime est-elle possible, et sinon pourquoi', () {
    test('l autorisation d abord, puis ce que l isolate de fond a vu', () {
      const possible = EstimateReadiness.possible;
      expect(estimateReadinessOf(PodometerAccess.granted, null), possible);
      expect(estimateReadinessOf(PodometerAccess.granted, possible), possible);
      expect(
        estimateReadinessOf(
          PodometerAccess.granted,
          EstimateReadiness.streamError,
        ),
        EstimateReadiness.streamError,
      );
      expect(
        estimateReadinessOf(
          PodometerAccess.granted,
          EstimateReadiness.podometerUnavailable,
        ),
        EstimateReadiness.podometerUnavailable,
      );
      for (final refus in [
        PodometerAccess.denied,
        PodometerAccess.permanentlyDenied,
      ]) {
        expect(
          estimateReadinessOf(refus, possible),
          EstimateReadiness.permissionRefused,
        );
      }
      expect(
        estimateReadinessOf(PodometerAccess.unavailable, possible),
        EstimateReadiness.podometerUnavailable,
      );
    });
  });

  group('671-02 — le provider du podometre', () {
    ProviderContainer conteneur(PermissionStatus statut) {
      final c = ProviderContainer(
        overrides: [
          podometerPermissionServiceProvider.overrideWithValue(
            PodometerPermissionService(readStatus: () async => statut),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'accorde : le compte consolide, la longueur et la dispersion',
      () async {
        SharedPreferences.setMockInitialValues({
          kPrefsStepsReadiness: 'possible',
          kPrefsStepsTotal: 4321,
          kPrefsStrideWindow: ['0.70', '0.74'],
        });
        final PodometerState etat = await conteneur(
          PermissionStatus.granted,
        ).read(podometerProvider.future);
        expect(etat.steps, 4321);
        expect(etat.strideMeters, closeTo(0.72, 1e-9));
        expect(etat.strideSpreadPercent, closeTo(5.56, 0.01));
        expect(etat.access, PodometerAccess.granted);
        expect(etat.readiness, EstimateReadiness.possible);
      },
    );

    test(
      'refuse : aucun compte, la longueur de depart, et la raison',
      () async {
        SharedPreferences.setMockInitialValues({kPrefsStepsTotal: 4321});
        final PodometerState etat = await conteneur(
          PermissionStatus.denied,
        ).read(podometerProvider.future);
        expect(etat.steps, isNull);
        expect(etat.strideMeters, kStrideDefaultMeters);
        expect(etat.strideSpreadPercent, isNull);
        expect(etat.readiness, EstimateReadiness.permissionRefused);
      },
    );
  });
}
