import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';

void main() {
  group('HikerProfile — IMC calcule local', () {
    test('IMC nul si taille ou poids manquant', () {
      expect(const HikerProfile(heightCm: 0, weightKg: 70).bmi, isNull);
      expect(const HikerProfile(heightCm: 175, weightKg: 0).bmi, isNull);
      expect(HikerProfile.empty.bmi, isNull);
    });

    test('IMC = poids / taille^2 (m)', () {
      // 70 kg, 1.75 m -> 22.857...
      final bmi = const HikerProfile(heightCm: 175, weightKg: 70).bmi!;
      expect(bmi, closeTo(22.857, 0.01));
    });

    test('categories OMS', () {
      expect(const HikerProfile(heightCm: 180, weightKg: 55).bmiCategory,
          'underweight'); // 16.98
      expect(const HikerProfile(heightCm: 175, weightKg: 70).bmiCategory,
          'normal'); // 22.86
      expect(const HikerProfile(heightCm: 175, weightKg: 85).bmiCategory,
          'overweight'); // 27.76
      expect(const HikerProfile(heightCm: 170, weightKg: 95).bmiCategory,
          'obese'); // 32.87
    });

    test('isEmpty (aucune donnee), hasMorphology (taille+poids)', () {
      expect(HikerProfile.empty.isEmpty, isTrue);
      // age seul = une donnee saisie -> plus "empty" (mais pas de morpho).
      expect(const HikerProfile(age: 40).isEmpty, isFalse);
      expect(const HikerProfile(age: 40).hasMorphology, isFalse);
      expect(const HikerProfile(heightCm: 175, weightKg: 70).hasMorphology,
          isTrue);
      expect(const HikerProfile(heightCm: 175).hasMorphology, isFalse);
    });

    test('rappel senior a partir de 65 ans', () {
      expect(const HikerProfile(age: 64).needsSeniorHealthReminder, isFalse);
      expect(const HikerProfile(age: 65).needsSeniorHealthReminder, isTrue);
      expect(const HikerProfile(age: 70).needsSeniorHealthReminder, isTrue);
    });

    test('serialisation JSON round-trip (miroir cloud / prefs)', () {
      final profile = HikerProfile(
        age: 42,
        heightCm: 178,
        weightKg: 74.5,
        sex: HikerSex.male,
        countryIso: 'FR',
        updatedAt: DateTime(2026, 9, 11),
      );
      final restored = HikerProfile.fromJson(profile.toJson());
      expect(restored, profile);
      // L'IMC n'est pas serialise (getter) : recalcule identique.
      expect(restored.bmi, profile.bmi);
    });
  });
}
