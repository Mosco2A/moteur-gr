import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/services/secure_vault_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/features/auth/data/account_vault_service.dart';
import 'package:moteur_gr/features/auth/data/local_auth_service.dart';

/// Tests du coffre COMPTE (profil + solde wallet) — reconnexion code-sur-tel
/// (#99784). Scénario cardinal : sauvegarder sur le tél A, restaurer sur un tél
/// B NEUF avec le même code. Zéro clair dans le blob.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const code = 'MON-CODE-TEST';

  Future<(LocalAuthService, WalletStore, AccountVaultService, AppDatabase)>
      makePhone() async {
    final auth = LocalAuthService();
    await auth.initialize(); // auto-connexion anonyme
    final db = AppDatabase(NativeDatabase.memory());
    final wallet = WalletStore(
      db: db,
      prefs: await SharedPreferences.getInstance(),
    );
    await wallet.load();
    final service = AccountVaultService(
      vault: SecureVaultService(),
      auth: auth,
      wallet: wallet,
    );
    return (auth, wallet, service, db);
  }

  test('export chiffre profil + wallet, restore sur tél B les restaure',
      () async {
    SharedPreferences.setMockInitialValues({});
    final (authA, walletA, serviceA, dbA) = await makePhone();
    addTearDown(dbA.close);

    // Profil + solde sur le tél A.
    await authA.updateDisplayName('Steve');
    await authA.updateAvatarIndex(3);
    await walletA.credit(120);

    final blob = await serviceA.exportWithCode(code);
    expect(blob, isNotNull);
    // Zéro-knowledge : le pseudo n'apparaît pas en clair dans le blob.
    expect(blob!.contains('Steve'), isFalse);

    // --- Tél B : NEUF (prefs vides, DB vide), même code ---
    SharedPreferences.setMockInitialValues({});
    final (authB, walletB, serviceB, dbB) = await makePhone();
    addTearDown(dbB.close);

    // Avant restauration : profil B anonyme sans pseudo, solde 0.
    expect(authB.currentUser?.displayName, isNull);
    expect(walletB.snapshot.balanceSteps, 0);

    await serviceB.restoreWithCode(code, blob);

    // Profil + solde restaurés à l'identique.
    expect(authB.currentUser?.displayName, 'Steve');
    expect(authB.currentUser?.avatarIndex, 3);
    expect(walletB.snapshot.balanceSteps, 120);
  });

  test('includeWallet:false exclut le solde du transfert', () async {
    SharedPreferences.setMockInitialValues({});
    final (authA, walletA, serviceA, dbA) = await makePhone();
    addTearDown(dbA.close);
    await authA.updateDisplayName('Alex');
    await walletA.credit(50);

    final blob = await serviceA.exportWithCode(code, includeWallet: false);
    expect(blob, isNotNull);

    SharedPreferences.setMockInitialValues({});
    final (authB, walletB, serviceB, dbB) = await makePhone();
    addTearDown(dbB.close);
    await serviceB.restoreWithCode(code, blob!);

    // Profil restauré, mais solde inchangé (exclu du blob).
    expect(authB.currentUser?.displayName, 'Alex');
    expect(walletB.snapshot.balanceSteps, 0);
  });

  test('mauvais code -> VaultDecryptException, aucune écriture', () async {
    SharedPreferences.setMockInitialValues({});
    final (authA, walletA, serviceA, dbA) = await makePhone();
    addTearDown(dbA.close);
    await authA.updateDisplayName('Chris');
    final blob = await serviceA.exportWithCode(code);

    SharedPreferences.setMockInitialValues({});
    final (authB, _, serviceB, dbB) = await makePhone();
    addTearDown(dbB.close);

    await expectLater(
      () => serviceB.restoreWithCode('MAUVAIS-CODE', blob!),
      throwsA(isA<VaultDecryptException>()),
    );
    // Le profil B n'a pas été modifié (pas d'écriture partielle).
    expect(authB.currentUser?.displayName, isNull);
  });
}
