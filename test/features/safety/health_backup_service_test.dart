import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/health_info_dao.dart';
import 'package:moteur_gr/core/services/secure_vault_service.dart';
import 'package:moteur_gr/features/safety/data/health_backup_service.dart';
import 'package:moteur_gr/features/safety/data/health_info_repository.dart';
import 'package:moteur_gr/features/safety/domain/models/health_info.dart';

/// Tests du backup CHIFFRÉ de la fiche santé (StepWays L7, gap C).
///
/// Scénario cardinal : chiffrer sur le tél A, restaurer sur un tél B NEUF
/// (base vide) via le CODE de reconnexion. Zéro clair, art. 9.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleInfo = HealthInfo(
    bloodType: 'O-',
    allergies: 'Pénicilline, arachides',
    treatments: 'Levothyrox 50mg/j',
    doctorContact: 'Dr Dupont 04 95 00 00 00',
    insuranceNumber: '1234567890',
  );

  late AppDatabase dbA;
  late HealthInfoRepository repoA;
  late HealthBackupService serviceA;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    dbA = AppDatabase(NativeDatabase.memory());
    repoA = HealthInfoRepository(dao: HealthInfoDao(dbA));
    serviceA = HealthBackupService(
      vault: SecureVaultService(),
      healthRepository: repoA,
    );
  });

  tearDown(() async {
    await dbA.close();
  });

  group('HealthBackupService — backup via code (cross-device)', () {
    test('exportWithCode chiffre, restoreWithCode sur tél B restaure',
        () async {
      await repoA.save(sampleInfo);

      final blob = await serviceA.exportWithCode('MON-CODE-1234');
      expect(blob, isNotNull);
      // Zéro-knowledge : aucune donnée sensible en clair dans le blob.
      expect(blob!.contains('Levothyrox'), isFalse);
      expect(blob.contains('Pénicilline'), isFalse);
      expect(blob.contains('O-'), isFalse);

      // Tél B : base NEUVE (vide), même code.
      final dbB = AppDatabase(NativeDatabase.memory());
      addTearDown(dbB.close);
      final repoB = HealthInfoRepository(dao: HealthInfoDao(dbB));
      final serviceB = HealthBackupService(
        vault: SecureVaultService(),
        healthRepository: repoB,
      );

      // Avant restauration : le tél B n'a rien.
      expect((await repoB.get()).hasData, isFalse);

      final restored = await serviceB.restoreWithCode('MON-CODE-1234', blob);
      expect(restored, sampleInfo);
      // Persisté en local sur le tél B.
      expect(await repoB.get(), sampleInfo);
    });

    test('mauvais code sur tél B => échec, AUCUNE écriture locale', () async {
      await repoA.save(sampleInfo);
      final blob = await serviceA.exportWithCode('BON-CODE');
      expect(blob, isNotNull);

      final dbB = AppDatabase(NativeDatabase.memory());
      addTearDown(dbB.close);
      final repoB = HealthInfoRepository(dao: HealthInfoDao(dbB));
      final serviceB = HealthBackupService(
        vault: SecureVaultService(),
        healthRepository: repoB,
      );

      await expectLater(
        serviceB.restoreWithCode('MAUVAIS-CODE', blob!),
        throwsA(isA<VaultDecryptException>()),
      );
      // La fiche du tél B n'a PAS été touchée.
      expect((await repoB.get()).hasData, isFalse);
    });

    test('aucune fiche => exportWithCode retourne null', () async {
      final blob = await serviceA.exportWithCode('CODE');
      expect(blob, isNull);
    });

    test('blob sans sel => VaultDecryptException', () async {
      await expectLater(
        serviceA.restoreWithCode('CODE', '{"v":1,"algo":"x","nonce":"AA==","mac":"AA==","ct":"AA=="}'),
        throwsA(isA<VaultDecryptException>()),
      );
    });
  });

  group('HealthBackupService — cloud absent (graceful no-op)', () {
    test('backupToCloud sans transport => false', () async {
      await repoA.save(sampleInfo);
      // serviceA est construit SANS cloudSync.
      expect(await serviceA.backupToCloud('hash-anon', 'CODE'), isFalse);
    });

    test('restoreFromCloud sans transport => null', () async {
      expect(await serviceA.restoreFromCloud('hash-anon', 'CODE'), isNull);
    });
  });

  group('HealthBackupService — backup local (même appareil)', () {
    test('exportWithLocalKey puis restoreWithLocalKey (même keystore)',
        () async {
      await repoA.save(sampleInfo);
      final blob = await serviceA.exportWithLocalKey();
      expect(blob, isNotNull);
      expect(blob!.contains('Levothyrox'), isFalse);

      // Efface la fiche locale puis restaure depuis le blob (même clé keystore).
      await repoA.delete();
      expect((await repoA.get()).hasData, isFalse);

      final restored = await serviceA.restoreWithLocalKey(blob);
      expect(restored, sampleInfo);
    });
  });
}
