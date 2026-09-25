// TACHE 562 (LOT K) — LE COFFRE DE L'OS ECHAPPAIT A L'EFFACEMENT.
//
// POURQUOI CE FICHIER EXISTE. Le LOT J a rendu l'effacement de l'article 17
// complet sur les DEUX etages qu'il connaissait : les tables Drift et les
// SharedPreferences, les deux listes DERIVEES de leur store reel. Restait un
// TROISIEME etage que personne n'avait ouvert : le KEYSTORE DE L'OS
// (`flutter_secure_storage`). Y vivent :
//
//   - `stepways.recovery.code.v1` — le code de reconnexion. Ce code EST la cle
//     du coffre du randonneur : il ouvre son profil, sa fiche de renseignement
//     medical et son solde d'etapes SUR UN AUTRE TELEPHONE. Le laisser derriere
//     un effacement « complet », c'est laisser la cle sur la porte.
//   - `stepways.vault.dataKey.v1` — la cle de chiffrement locale du backup de
//     la fiche sante. `SecureVaultService.deleteLocalDataKey()` existait pour
//     l'effacer... et n'avait, elle aussi, aucun appelant.
//
// CE QUE CES TESTS VERROUILLENT. Non pas « ces deux cles partent » — une liste
// de deux noms s'oublie exactement comme la liste de seize tables du LOT J s'est
// oubliee. Ils verrouillent l'INVERSION : on enumere les exceptions, et TOUT LE
// RESTE du keystore part. Une cle ajoutee demain par un auteur qui ignore ce
// fichier est donc effacee par defaut, pas conservee.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/services/data_retention_service.dart';
import 'package:moteur_gr/core/services/recovery_code_service.dart';
import 'package:moteur_gr/core/services/secure_keystore_eraser.dart';
import 'package:moteur_gr/core/services/secure_vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  const keystore = FlutterSecureStorage();

  /// Cle keystore de la cle de chiffrement du backup sante. Le nom est prive
  /// dans [SecureVaultService] : on le relit ici pour pouvoir l'asserter, la
  /// COUVERTURE ne dependant de toute facon pas de cette liste (voir l'en-tete).
  const vaultDataKey = 'stepways.vault.dataKey.v1';

  /// La cle que personne n'a encore ecrite. Elle tient le role de la cle que le
  /// prochain developpeur ajoutera sans lire ce fichier.
  const cleDeDemain = 'stepways.futur.secret.v1';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(() async {
    await db.close();
  });

  Future<DataRetentionService> buildService() async => DataRetentionService(
        database: db,
        prefs: await SharedPreferences.getInstance(),
      );

  /// Met le keystore dans l'etat d'un randonneur qui a reellement utilise
  /// l'app : un code de reconnexion genere, une cle de coffre creee.
  Future<void> seedKeystoreReel() async {
    await RecoveryCodeService().getOrCreate();
    await SecureVaultService().getOrCreateLocalDataKey();
  }

  group('LOT K — l effacement art 17 atteint le keystore de l OS', () {
    test('le CODE DE RECONNEXION ne survit pas a l effacement', () async {
      await seedKeystoreReel();
      expect(await keystore.read(key: RecoveryCodeService.storageKey),
          isNotNull,
          reason: 'le code doit exister AVANT, sinon le test ne prouve rien');

      final service = await buildService();
      await service.deleteAccountData();

      expect(
        await keystore.read(key: RecoveryCodeService.storageKey),
        isNull,
        reason: 'le code de reconnexion ouvre le coffre du randonneur sur un '
            'autre telephone : il doit partir avec le reste',
      );
    });

    test('la CLE DU COFFRE LOCAL ne survit pas non plus', () async {
      await seedKeystoreReel();
      expect(await keystore.read(key: vaultDataKey), isNotNull);

      final service = await buildService();
      await service.deleteAccountData();

      expect(await keystore.read(key: vaultDataKey), isNull,
          reason: 'la cle qui dechiffre le backup de la fiche sante reste '
              'une donnee du randonneur');
    });

    test('INVERSION : une cle ajoutee DEMAIN part aussi, sans etre nommee '
        'nulle part', () async {
      await seedKeystoreReel();
      await keystore.write(key: cleDeDemain, value: 'valeur-inconnue');

      final service = await buildService();
      await service.deleteAccountData();

      expect(await keystore.read(key: cleDeDemain), isNull,
          reason: 'le defaut doit proteger la personne : une cle non classee '
              'est EFFACEE, jamais conservee');
      expect(await keystore.readAll(), isEmpty,
          reason: 'aucune exception n est declaree : le keystore doit etre vide');
    });

    test('le compte des cles effacees est RENDU (tracabilite)', () async {
      await seedKeystoreReel();
      await keystore.write(key: cleDeDemain, value: 'valeur-inconnue');

      final service = await buildService();
      final report = await service.deleteAccountData();

      expect(report.secureKeysDeleted, 3,
          reason: 'code de reconnexion + cle de coffre + cle de demain');
    });

    test('keystore VIDE : aucune erreur, compte a zero, idempotent', () async {
      final service = await buildService();
      expect((await service.deleteAccountData()).secureKeysDeleted, 0);
      // Rejouer un effacement n efface rien de plus et ne leve pas.
      expect((await service.deleteAccountData()).secureKeysDeleted, 0);
    });
  });

  group('LOT K — la non-recurrence est STRUCTURELLE, pas une liste tenue a jour',
      () {
    test('AUCUNE exception n est declaree, et ce vide est une decision', () {
      expect(SecureKeystoreEraser.preservedKeys, isEmpty,
          reason: 'ajouter une exception ici doit forcer a ecrire sa raison : '
              'rien de ce qui vit dans le keystore n appartient a l appareil, '
              'tout appartient au randonneur');
    });

    test('CHAQUE cle keystore declaree dans lib/ est reellement emportee',
        () async {
      // On ne relit pas une liste ecrite dans ce test : on relit le CODE SOURCE.
      // Tout fichier de lib/ qui parle a `flutter_secure_storage` et y nomme une
      // cle « stepways.* » voit cette cle seedee, puis exigee absente. Un
      // troisieme service qui apparaitrait demain est donc couvert sans que
      // personne ait a penser a modifier ce fichier.
      final cles = <String>{};
      final regexp = RegExp("'(stepways\\.[A-Za-z0-9_.]+)'");
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        if (!source.contains('flutter_secure_storage')) continue;
        for (final m in regexp.allMatches(source)) {
          cles.add(m.group(1)!);
        }
      }

      expect(cles, contains(RecoveryCodeService.storageKey),
          reason: 'le scan du source doit au minimum retrouver le code de '
              'reconnexion, sinon il ne scanne rien');
      expect(cles, contains(vaultDataKey),
          reason: 'la cle du coffre local doit etre vue par le scan');

      FlutterSecureStorage.setMockInitialValues(
        <String, String>{for (final cle in cles) cle: 'valeur'},
      );
      final service = await buildService();
      await service.deleteAccountData();

      for (final cle in cles) {
        expect(await keystore.read(key: cle), isNull,
            reason: '« $cle » est declaree dans lib/ et survit a l effacement');
      }
    });
  });
}
