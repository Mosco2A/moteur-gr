// Test miroir de `lib/features/trek/data/calibration_du_pas.dart` (lot
// 671-02) : la calibration ne mesure que sur un podometre utilisable, et
// n'ecrit que ce qu'elle accepte.
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/calibration_du_pas.dart';
import 'package:moteur_gr/features/trek/data/podometre_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pas(int total) async =>
      (await SharedPreferences.getInstance()).setInt(kPrefsStepsTotal, total);

  test('sans podometre utilisable, aucun intervalle n est ferme', () async {
    SharedPreferences.setMockInitialValues({
      kPrefsStepsReadiness: 'autorisation_refusee',
      kPrefsStepsTotal: 100,
    });
    final calibration = StrideCalibrationFeed(PodometerStore());
    expect(await calibration.observe(0), isNull);
    await pas(500);
    expect(await calibration.observe(280), isNull);
  });

  test('un intervalle rejete n ecrit rien au point de calibration', () async {
    SharedPreferences.setMockInitialValues({
      kPrefsStepsReadiness: 'possible',
      kPrefsStepsTotal: 100,
    });
    final calibration = StrideCalibrationFeed(PodometerStore());
    await calibration.observe(0);
    await pas(130);
    final sort = await calibration.observe(5000);
    expect(sort?.accepted, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(kPrefsStrideWindow), isNull);
  });

  test('apres un arret, l intervalle repart de la position suivante', () async {
    SharedPreferences.setMockInitialValues({
      kPrefsStepsReadiness: 'possible',
      kPrefsStepsTotal: 100,
    });
    final calibration = StrideCalibrationFeed(PodometerStore());
    await calibration.observe(0);
    calibration.reset();
    await pas(500);
    expect(await calibration.observe(1000), isNull);
    await pas(900);
    expect((await calibration.observe(1280))?.accepted, isTrue);
  });
}
