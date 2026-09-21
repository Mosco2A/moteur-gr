import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/features/diploma/domain/diploma_pdf_service.dart';

/// CORRECTIF L5-1 — LE DIPLOME PRODUIT ENFIN UN FICHIER.
///
/// Le service rendait bien les octets du document, mais l'ecran appelait
/// generatePdf SANS affecter son retour : les octets etaient calcules puis
/// jetes, et le message affiche ensuite reprenait le LIBELLE DU BOUTON.
/// Aucune QA visuelle ni aucun persona ne pouvait attraper ca — il fallait
/// lire le code. Ces tests verrouillent l'ecriture reelle.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  late Directory sandbox;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('diploma_file_test_');
  });

  tearDown(() {
    if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
  });

  group('L5-1 — ecriture du diplome sur le disque', () {
    test('savePdf ecrit un fichier NON VIDE, et on peut le relire', () async {
      final bytes = Uint8List.fromList(List<int>.filled(2048, 7));

      final file = await DiplomaPdfService.savePdf(
        bytes: bytes,
        trailId: 'mare-a-mare-centre',
        at: DateTime(2026, 6, 12, 18, 30, 5),
        directory: sandbox,
      );

      expect(file.existsSync(), isTrue,
          reason: 'C est TOUT le correctif : un fichier doit exister');
      expect(file.lengthSync(), 2048);
      expect(file.readAsBytesSync().first, 7);
    });

    test('le PDF reellement genere atterrit sur le disque', () async {
      final data = DiplomaPdfData(
        hikerName: 'Christophe',
        trailName: 'Fra li Monti',
        trailRegion: 'Region Test',
        totalStages: 7,
        totalDistanceKm: 84.0,
        totalElevationGain: 3750,
        startDate: DateTime(2026, 6, 10),
        endDate: DateTime(2026, 6, 16),
        durationDays: 7,
      );
      const labels = DiplomaPdfLabels(
        title: 'DIPLOME',
        subtitle: "Certificat d'accomplissement",
        certifies: 'Certifie que',
        completed: 'a parcouru le',
        stages: '7 etapes',
        distance: '84 km parcourus',
        elevation: '3750 m de denivele positif',
        duration: 'en 7 jours',
        from: 'Du',
        to: 'au',
        issuedOn: 'Delivre le 16 juin 2026',
      );

      final bytes = await DiplomaPdfService.generatePdf(
        data: data,
        labels: labels,
        locale: 'fr_FR',
      );
      final file = await DiplomaPdfService.savePdf(
        bytes: bytes,
        trailId: 'mare-a-mare-centre',
        directory: sandbox,
      );

      expect(file.existsSync(), isTrue);
      // Signature PDF : le fichier ecrit est bien un PDF, pas un octet perdu.
      expect(String.fromCharCodes(file.readAsBytesSync().take(4)), '%PDF');
    });

    test('deux generations ne s ecrasent pas', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final a = await DiplomaPdfService.savePdf(
        bytes: bytes,
        trailId: 'sentier',
        at: DateTime(2026, 6, 12, 18, 30, 5),
        directory: sandbox,
      );
      final b = await DiplomaPdfService.savePdf(
        bytes: bytes,
        trailId: 'sentier',
        at: DateTime(2026, 6, 12, 18, 30, 6),
        directory: sandbox,
      );

      expect(a.path, isNot(b.path));
      expect(a.existsSync() && b.existsSync(), isTrue);
    });
  });

  group('L5-1 — nom de fichier', () {
    test('horodate, en minuscules, sans caractere piege', () {
      final name = DiplomaPdfService.diplomaFileName(
        'Mare a Mare/Centre',
        at: DateTime(2026, 6, 12, 18, 30, 5),
      );

      expect(name, 'diplome-mare-a-mare-centre-20260612-183005.pdf');
      // Un identifiant de sentier venu d'un catalogue distant n'a aucune
      // raison d'etre un nom de fichier valide.
      expect(name.contains('/'), isFalse);
      expect(name.contains(' '), isFalse);
    });
  });
}
