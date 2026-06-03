// E5.20a -- Tests widget lockscreen enrichi sante + GPS.
//
// 2 tests :
// - Donnees sante incluses dans securityData
// - GPS inclus dans securityData

import 'package:flutter_test/flutter_test.dart';

import 'package:g20_app/features/safety/domain/models/health_info.dart';
import 'package:g20_app/features/safety/data/lockscreen_widget_service.dart';

void main() {
  group('LockscreenSecurityData -- E5.20a', () {
    test('donnees sante incluses dans securityData', () {
      final health = HealthInfo(
        bloodType: 'A+',
        allergies: 'Penicilline',
        treatments: 'Levothyrox 50mg/j',
        doctorContact: 'Dr Dupont',
        insuranceNumber: '123456',
      );

      final data = LockscreenSecurityData(
        healthInfo: health,
        latitude: 42.15,
        longitude: 9.10,
        stageName: 'Haut Asco - Tighjettu',
        stageIndex: 4,
      );

      // Sante presente et valide
      expect(data.hasHealthInfo, isTrue);
      expect(data.healthInfo!.bloodType, equals('A+'));
      expect(data.healthInfo!.allergies, equals('Penicilline'));
      expect(data.healthInfo!.treatments, equals('Levothyrox 50mg/j'));

      // Sans donnees sante => hasHealthInfo false
      const emptyData = LockscreenSecurityData();
      expect(emptyData.hasHealthInfo, isFalse);

      // Avec HealthInfo vide => hasHealthInfo false aussi
      const emptyHealthData = LockscreenSecurityData(
        healthInfo: HealthInfo(),
      );
      expect(emptyHealthData.hasHealthInfo, isFalse);
    });

    test('GPS inclus dans securityData', () {
      final data = LockscreenSecurityData(
        latitude: 42.15234,
        longitude: 9.10567,
        stageName: 'Haut Asco',
        stageIndex: 4,
      );

      // GPS present
      expect(data.hasGpsPosition, isTrue);
      expect(data.latitude, equals(42.15234));
      expect(data.longitude, equals(9.10567));

      // Etape presente
      expect(data.stageName, equals('Haut Asco'));
      expect(data.stageIndex, equals(4));

      // Sans GPS => hasGpsPosition false
      const noGps = LockscreenSecurityData(stageName: 'Haut Asco');
      expect(noGps.hasGpsPosition, isFalse);

      // GPS partiel (latitude seule) => false
      const partialGps = LockscreenSecurityData(latitude: 42.15);
      expect(partialGps.hasGpsPosition, isFalse);
    });
  });
}
