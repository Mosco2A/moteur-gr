import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_norms.dart';

void main() {
  group('WalkTestNorms — equations Enright & Sherrill', () {
    test('prediction homme 45 ans 180 cm 80 kg', () {
      // 7.57*180 - 5.02*45 - 1.76*80 - 309 = 1362.6 - 225.9 - 140.8 - 309
      final p = WalkTestNorms.predictedMale(age: 45, heightCm: 180, weightKg: 80);
      expect(p, closeTo(686.9, 0.1));
    });

    test('prediction femme 45 ans 165 cm 60 kg', () {
      // 2.11*165 - 2.29*60 - 5.78*45 + 667 = 348.15 - 137.4 - 260.1 + 667
      final p =
          WalkTestNorms.predictedFemale(age: 45, heightCm: 165, weightKg: 60);
      expect(p, closeTo(617.65, 0.1));
    });

    test('age clampe hors bornes 40-80 (extrapolation prudente)', () {
      final young =
          WalkTestNorms.predictedMale(age: 20, heightCm: 180, weightKg: 80);
      final atFloor =
          WalkTestNorms.predictedMale(age: 40, heightCm: 180, weightKg: 80);
      expect(young, atFloor, reason: 'age < 40 clampe a 40');
    });

    test('sexe non renseigne -> moyenne des deux equations', () {
      const profile = HikerProfile(age: 50, heightCm: 172, weightKg: 70);
      final male =
          WalkTestNorms.predictedMale(age: 50, heightCm: 172, weightKg: 70);
      final female =
          WalkTestNorms.predictedFemale(age: 50, heightCm: 172, weightKg: 70);
      expect(WalkTestNorms.predictedFor(profile), closeTo((male + female) / 2, 0.01));
    });

    test('prediction null si morpho absente', () {
      expect(WalkTestNorms.predictedFor(const HikerProfile(age: 40)), isNull);
      expect(
          WalkTestNorms.predictedFor(
              const HikerProfile(heightCm: 170, weightKg: 65)),
          isNull,
          reason: 'age manquant');
    });
  });

  group('WalkTestNorms — niveaux', () {
    test('seuils de ratio', () {
      expect(WalkTestNorms.levelFromRatio(0.5), WalkTestLevel.low);
      expect(WalkTestNorms.levelFromRatio(0.80), WalkTestLevel.moderate);
      expect(WalkTestNorms.levelFromRatio(1.00), WalkTestLevel.good);
      expect(WalkTestNorms.levelFromRatio(1.20), WalkTestLevel.excellent);
    });

    test('levelFor via ratio quand morpho presente', () {
      // Homme 45/180/80 -> predit ~686.9 m. 620 m -> ratio ~0.903 -> good.
      const profile =
          HikerProfile(age: 45, heightCm: 180, weightKg: 80, sex: HikerSex.male);
      expect(WalkTestNorms.levelFor(profile, 620), WalkTestLevel.good);
      expect(WalkTestNorms.levelFor(profile, 400), WalkTestLevel.low);
    });

    test('levelFor fallback distance absolue quand morpho absente', () {
      const profile = HikerProfile(); // vide
      expect(WalkTestNorms.levelFor(profile, 350), WalkTestLevel.low);
      expect(WalkTestNorms.levelFor(profile, 450), WalkTestLevel.moderate);
      expect(WalkTestNorms.levelFor(profile, 550), WalkTestLevel.good);
      expect(WalkTestNorms.levelFor(profile, 650), WalkTestLevel.excellent);
    });

    test('rang des niveaux ordonne', () {
      expect(WalkTestLevel.rank(WalkTestLevel.low), 0);
      expect(WalkTestLevel.rank(WalkTestLevel.excellent), 3);
      expect(
          WalkTestLevel.rank(WalkTestLevel.good) >
              WalkTestLevel.rank(WalkTestLevel.moderate),
          isTrue);
    });
  });
}
