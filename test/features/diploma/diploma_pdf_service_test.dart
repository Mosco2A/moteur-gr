import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/features/diploma/domain/diploma_pdf_service.dart';

/// Test du service de generation PDF diplome.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('DiplomaPdfService', () {
    test('generatePdf retourne un PDF valide sans erreur', () async {
      final data = DiplomaPdfData(
        hikerName: 'Christophe',
        trailName: 'Fra li Monti',
        trailRegion: 'Corse',
        totalStages: 16,
        totalDistanceKm: 180.0,
        totalElevationGain: 12000,
        startDate: DateTime(2026, 7, 16),
        endDate: DateTime(2026, 7, 30),
        durationDays: 14,
      );

      const labels = DiplomaPdfLabels(
        title: 'DIPLOME',
        subtitle: "Certificat d'accomplissement",
        certifies: 'Certifie que',
        completed: 'a parcouru le',
        stages: '16 etapes',
        distance: '180 km parcourus',
        elevation: '12000 m de denivele positif',
        duration: 'en 14 jours',
        from: 'Du',
        to: 'au',
        issuedOn: 'Delivre le 30 juillet 2026',
      );

      final pdfBytes = await DiplomaPdfService.generatePdf(
        data: data,
        labels: labels,
        locale: 'fr_FR',
      );

      // Le PDF doit etre non vide
      expect(pdfBytes, isNotEmpty);

      // Le PDF doit commencer par le header PDF standard
      expect(pdfBytes[0], 0x25); // %
      expect(pdfBytes[1], 0x50); // P
      expect(pdfBytes[2], 0x44); // D
      expect(pdfBytes[3], 0x46); // F

      // Taille minimale raisonnable pour un PDF A4 paysage
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
