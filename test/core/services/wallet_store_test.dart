import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests ST2 — `WalletStore`, persistance DUALE du compte-etapes (StepWays
/// LOT 1).
///
/// La DB Drift tourne EN MEMOIRE (volatile) : la source durable est
/// SharedPreferences, Drift en est le miroir. On verifie :
///   - credit / debit (solde + cumuls, garde du solde negatif) ;
///   - le double-ecriture prefs + Drift a chaque mouvement ;
///   - l'hydratation au boot (prefs -> etat + miroir Drift) ;
///   - le round-trip : un solde survit a un "redemarrage" (nouvelle instance
///     sur les memes prefs, DB neuve vide au depart).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<WalletStore> makeStore() async {
    final store = WalletStore(
      db: db,
      prefs: await SharedPreferences.getInstance(),
    );
    addTearDown(store.dispose);
    return store;
  }

  group('ST2 credit / debit', () {
    test('credit augmente le solde et le cumul gagne', () async {
      final store = await makeStore();
      await store.load();

      final snap = await store.credit(11);

      expect(snap.balanceSteps, 11);
      expect(snap.lifetimeEarnedSteps, 11);
      expect(snap.lifetimeSpentSteps, 0);
      expect(store.balanceSteps, 11);
    });

    test('debit diminue le solde et augmente le cumul depense', () async {
      final store = await makeStore();
      await store.load();
      await store.credit(25);

      final snap = await store.debit(10);

      expect(snap.balanceSteps, 15);
      expect(snap.lifetimeEarnedSteps, 25);
      expect(snap.lifetimeSpentSteps, 10);
    });

    test('debit au-dela du solde jette (jamais de solde negatif)', () async {
      final store = await makeStore();
      await store.load();
      await store.credit(5);

      expect(() => store.debit(6), throwsStateError);
      expect(store.balanceSteps, 5, reason: 'solde inchange apres echec');
    });

    test('credit/debit refusent les montants <= 0', () async {
      final store = await makeStore();
      await store.load();

      expect(() => store.credit(0), throwsArgumentError);
      expect(() => store.debit(-3), throwsArgumentError);
    });

    test('watch emet l etat courant puis chaque mouvement', () async {
      final store = await makeStore();
      await store.load();

      final seen = <int>[];
      final sub = store.watch().listen((s) => seen.add(s.balanceSteps));
      await Future<void>.delayed(Duration.zero);

      await store.credit(11);
      await store.debit(1);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen, [0, 11, 10]);
    });
  });

  group('ST2 double-ecriture prefs + Drift', () {
    test('credit ecrit la source durable (prefs) ET le miroir Drift', () async {
      final store = await makeStore();
      await store.load();
      await store.credit(50);

      // Source durable : prefs.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(kWalletBalanceStepsPrefsKey), 50);
      expect(prefs.getInt(kWalletLifetimeEarnedPrefsKey), 50);
      expect(prefs.getInt(kWalletLifetimeSpentPrefsKey), 0);

      // Miroir : Drift.
      final row = await db.walletDao.getByUserId(kWalletLocalUserId);
      expect(row, isNotNull);
      expect(row!.balanceSteps, 50);
      expect(row.lifetimeEarnedSteps, 50);
    });
  });

  group('ST2 hydratation / round-trip', () {
    test('load hydrate l etat ET le miroir Drift depuis les prefs', () async {
      SharedPreferences.setMockInitialValues({
        kWalletBalanceStepsPrefsKey: 30,
        kWalletLifetimeEarnedPrefsKey: 42,
        kWalletLifetimeSpentPrefsKey: 12,
      });
      final store = await makeStore();

      expect(store.isLoaded, isFalse);
      await store.load();

      expect(store.isLoaded, isTrue);
      expect(store.snapshot.balanceSteps, 30);
      expect(store.snapshot.lifetimeEarnedSteps, 42);
      expect(store.snapshot.lifetimeSpentSteps, 12);

      // Le miroir Drift (vide au depart, DB volatile) est aligne.
      final row = await db.walletDao.getByUserId(kWalletLocalUserId);
      expect(row, isNotNull);
      expect(row!.balanceSteps, 30);
    });

    test('round-trip: le solde survit a un redemarrage (prefs = source)',
        () async {
      // Instance 1 : credite, puis "meurt".
      final store1 = await makeStore();
      await store1.load();
      await store1.credit(11);
      await store1.credit(25);
      await store1.debit(6);
      expect(store1.balanceSteps, 30);

      // Simule le redemarrage : DB Drift NEUVE (volatile) mais MEMES prefs.
      await db.close();
      db = AppDatabase(NativeDatabase.memory());
      // Au boot, le miroir Drift est vide.
      expect(await db.walletDao.getByUserId(kWalletLocalUserId), isNull);

      final store2 = await makeStore();
      await store2.load();

      // Le solde est reconstruit depuis les prefs (source durable).
      expect(store2.balanceSteps, 30);
      expect(store2.snapshot.lifetimeEarnedSteps, 36);
      expect(store2.snapshot.lifetimeSpentSteps, 6);
      // Et le miroir Drift a ete re-hydrate.
      final row = await db.walletDao.getByUserId(kWalletLocalUserId);
      expect(row!.balanceSteps, 30);
    });
  });
}
