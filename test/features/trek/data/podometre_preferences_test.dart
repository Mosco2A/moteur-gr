// Test miroir de `lib/features/trek/data/podometre_preferences.dart` (lot
// 671-02) : le canal du podometre entre l'isolate de fond et l'interface.
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/podometre_preferences.dart';
import 'package:moteur_gr/features/trek/domain/accumulateur_de_pas.dart';
import 'package:moteur_gr/features/trek/domain/longueur_de_pas.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'le total d une session se relit pour la MEME session seulement',
    () async {
      final canal = PodometerStore();
      final pas = StepAccumulator()
        ..add(2000)
        ..add(2250);
      await canal.saveSteps('s1', pas);

      final meme = await canal.restoreSteps('s1');
      expect(meme.total, 250);
      expect(meme.lastRaw, 2250);
      expect(await canal.readSteps(), 250);
      expect((await canal.restoreSteps('s2')).total, isNull);
      expect((await canal.restoreSteps('')).total, isNull);
    },
  );

  test('l etat du flux et la calibration font l aller-retour', () async {
    final canal = PodometerStore();
    expect(await canal.readReadiness(), isNull);
    await canal.saveReadiness(EstimateReadiness.permissionRefused);
    expect(await canal.readReadiness(), EstimateReadiness.permissionRefused);

    await canal.saveStride(StrideCalibration([0.66, 0.70]));
    final lue = await canal.readStride();
    expect(lue.accepted, [0.66, 0.70]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(kPrefsStrideWindow), ['0.6600', '0.7000']);
  });

  test('des preferences illisibles ne levent jamais : valeurs absentes et '
      'valeur de depart', () async {
    final canal = PodometerStore(
      preferences: () async => throw StateError('stockage perdu'),
    );
    expect(await canal.readSteps(), isNull);
    expect(await canal.readReadiness(), isNull);
    expect((await canal.readStride()).meters, kStrideDefaultMeters);
    expect((await canal.restoreSteps('s1')).total, isNull);
    await canal.saveSteps('s1', StepAccumulator()..add(3));
    await canal.saveStride(StrideCalibration([0.7]));
  });

  test('le rythme d ecriture pendant la marche est de dix secondes', () {
    expect(kStepsSavePeriod, const Duration(seconds: 10));
  });
}
