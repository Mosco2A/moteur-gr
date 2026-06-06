// E5.16 -- Tests informations sante LOCAL ONLY.
//
// 2 tests : save+get roundtrip, donnees jamais null apres save.

import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/features/safety/domain/models/health_info.dart';

void main() {
  group('HealthInfo -- model', () {
    test('save+get roundtrip via fromJson/toJson', () {
      // Simuler un save (toJson) puis un get (fromJson)
      const original = HealthInfo(
        bloodType: 'A+',
        allergies: 'Penicilline, arachides',
        treatments: 'Levothyrox 50mg/j',
        doctorContact: 'Dr Dupont 04 95 00 00 00',
        insuranceNumber: '1234567890',
      );

      // Simuler le passage par Drift (toJson -> fromJson)
      final json = original.toJson();
      final restored = HealthInfo.fromJson(json);

      expect(restored, equals(original));
      expect(restored.bloodType, equals('A+'));
      expect(restored.allergies, equals('Penicilline, arachides'));
      expect(restored.treatments, equals('Levothyrox 50mg/j'));
      expect(restored.doctorContact, equals('Dr Dupont 04 95 00 00 00'));
      expect(restored.insuranceNumber, equals('1234567890'));
    });

    test('donnees jamais null apres save -- champs vides = chaines vides', () {
      // Meme un HealthInfo vide doit avoir des chaines vides, pas null
      const emptyInfo = HealthInfo();

      // Verifier que tous les champs sont des chaines vides (pas null)
      expect(emptyInfo.bloodType, isNotNull);
      expect(emptyInfo.allergies, isNotNull);
      expect(emptyInfo.treatments, isNotNull);
      expect(emptyInfo.doctorContact, isNotNull);
      expect(emptyInfo.insuranceNumber, isNotNull);

      // Verifier que les chaines sont vides
      expect(emptyInfo.bloodType, isEmpty);
      expect(emptyInfo.allergies, isEmpty);
      expect(emptyInfo.treatments, isEmpty);
      expect(emptyInfo.doctorContact, isEmpty);
      expect(emptyInfo.insuranceNumber, isEmpty);

      // hasData doit etre false pour un profil vide
      expect(emptyInfo.hasData, isFalse);

      // Apres un roundtrip JSON, les champs restent non-null
      final json = emptyInfo.toJson();
      final restored = HealthInfo.fromJson(json);
      expect(restored.bloodType, isNotNull);
      expect(restored.allergies, isNotNull);
      expect(restored.treatments, isNotNull);
      expect(restored.doctorContact, isNotNull);
      expect(restored.insuranceNumber, isNotNull);

      // Meme avec un JSON partiel (champs manquants), pas de null
      final partial = HealthInfo.fromJson(<String, dynamic>{});
      expect(partial.bloodType, isNotNull);
      expect(partial.allergies, isNotNull);
      expect(partial.treatments, isNotNull);
      expect(partial.doctorContact, isNotNull);
      expect(partial.insuranceNumber, isNotNull);
    });
  });
}
