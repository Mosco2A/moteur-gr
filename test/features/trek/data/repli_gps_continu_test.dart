import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/features/trek/data/repli_gps_continu.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LOT 671-03 — LES TROIS SORTIES DE SECOURS VERS LE GPS CONTINU, ET LE CHOIX
/// MANUEL QUI RESTE MAITRE.
void main() {
  late List<PositionProfile> applied;
  ContinuousGpsFallback fallbackFrom(PositionProfile chosen) {
    applied = [];
    return ContinuousGpsFallback(
      apply: (p) async => applied.add(p),
      chosen: chosen,
    );
  }

  test('hors du trace au premier releve reel qui le dit : la carte, puis le '
      'profil choisi au retour sur le trace', () async {
    final f = fallbackFrom(PositionProfile.batteryFirst);
    expect(
      await f.observe(
        offTrack: false,
        trackLoaded: true,
        estimatePossible: true,
      ),
      isNull,
    );
    expect(applied, isEmpty);
    expect(
      await f.observe(
        offTrack: true,
        trackLoaded: true,
        estimatePossible: true,
      ),
      ContinuousGpsReason.offTrack,
    );
    expect(applied, [PositionProfile.map]);
    // Tant que le releve dit hors trace : rien de plus, ni phrase ni canal.
    expect(await f.observe(offTrack: true), isNull);
    expect(applied, [PositionProfile.map]);
    await f.observe(offTrack: false);
    expect(applied, [PositionProfile.map, PositionProfile.batteryFirst]);
    expect(f.effective, PositionProfile.batteryFirst);
  });

  test(
    'pas de trace charge : la carte, comme avant les lots batterie',
    () async {
      final f = fallbackFrom(PositionProfile.lowBattery);
      expect(await f.observe(trackLoaded: false), ContinuousGpsReason.noTrack);
      expect(applied, [PositionProfile.map]);
      await f.observe(trackLoaded: true);
      expect(applied.last, PositionProfile.lowBattery);
    },
  );

  test('podometre absent, en erreur ou refuse : la carte', () async {
    final f = fallbackFrom(PositionProfile.batteryFirst);
    expect(
      await f.observe(estimatePossible: false),
      ContinuousGpsReason.noStepCounter,
    );
    expect(f.effective, PositionProfile.map);
  });

  test('une condition encore inconnue ne decide rien', () async {
    final f = fallbackFrom(PositionProfile.batteryFirst);
    await f.observe();
    expect(applied, isEmpty);
    expect(f.reasons, isEmpty);
  });

  test('en profil carte deja, une raison ne touche pas au canal et ne dit '
      'rien', () async {
    final f = fallbackFrom(PositionProfile.map);
    expect(await f.observe(offTrack: true, trackLoaded: false), isNull);
    expect(applied, isEmpty);
  });

  test('LE SELECTEUR RESTE MAITRE : un choix manuel hors du trace est garde '
      'tant que le releve reste hors trace, sans bataille en boucle', () async {
    final f = fallbackFrom(PositionProfile.batteryFirst);
    await f.observe(offTrack: true);
    expect(f.effective, PositionProfile.map);
    // Le randonneur choisit lui-meme « batterie d'abord » (deja applique par
    // l'ecran de mesure).
    f.choose(PositionProfile.batteryFirst);
    expect(f.effective, PositionProfile.batteryFirst);
    for (var i = 0; i < 5; i++) {
      expect(await f.observe(offTrack: true), isNull);
    }
    expect(applied, [PositionProfile.map]);
    // La PROCHAINE sortie du trace, elle, repasse en carte.
    await f.observe(offTrack: false);
    expect(await f.observe(offTrack: true), ContinuousGpsReason.offTrack);
    expect(applied.last, PositionProfile.map);
  });

  test('le profil choisi se range a part du profil en vigueur', () async {
    SharedPreferences.setMockInitialValues({});
    expect(
      await readChosenPositionProfile(PositionProfile.map),
      PositionProfile.map,
    );
    await writeChosenPositionProfile(PositionProfile.lowBattery);
    expect(
      await readChosenPositionProfile(PositionProfile.map),
      PositionProfile.lowBattery,
    );
  });
}
