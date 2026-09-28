import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import '../providers/database_provider.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Cle SharedPreferences : solde courant du compte-etapes, en etapes.
const kWalletBalanceStepsPrefsKey = 'wallet.balanceSteps';

/// Cle SharedPreferences : total cumule d'etapes GAGNEES (duree de vie).
const kWalletLifetimeEarnedPrefsKey = 'wallet.lifetimeEarned';

/// Cle SharedPreferences : total cumule d'etapes DEPENSEES (duree de vie).
const kWalletLifetimeSpentPrefsKey = 'wallet.lifetimeSpent';

/// Identifiant utilisateur LOCAL du wallet tant qu'aucun compte n'est lie.
///
/// La table Drift [WalletBalance] est un singleton par `userId` (hash SHA-256
/// deterministe, cf. `anonymous_id_service.dart`). Avant liaison de compte, on
/// utilise cette cle locale stable — le miroir cloud non nominatif (A5) et la
/// bascule vers le hash reel sont branches en ST8 (hors LOT 1 ST2/ST3).
const kWalletLocalUserId = 'local';

/// Instantane immuable du solde du compte-etapes.
///
/// Entiers uniquement (zero nominatif, miroir cloud non nominatif A5) :
/// solde courant + compteurs cumules de vie.
class WalletSnapshot {
  const WalletSnapshot({
    required this.balanceSteps,
    required this.lifetimeEarnedSteps,
    required this.lifetimeSpentSteps,
  });

  /// Solde vide (etat initial avant tout credit).
  const WalletSnapshot.empty()
      : balanceSteps = 0,
        lifetimeEarnedSteps = 0,
        lifetimeSpentSteps = 0;

  /// Solde courant du compte-etapes, en etapes.
  final int balanceSteps;

  /// Total cumule d'etapes GAGNEES sur la duree de vie du compte.
  final int lifetimeEarnedSteps;

  /// Total cumule d'etapes DEPENSEES sur la duree de vie du compte.
  final int lifetimeSpentSteps;

  @override
  bool operator ==(Object other) =>
      other is WalletSnapshot &&
      other.balanceSteps == balanceSteps &&
      other.lifetimeEarnedSteps == lifetimeEarnedSteps &&
      other.lifetimeSpentSteps == lifetimeSpentSteps;

  @override
  int get hashCode =>
      Object.hash(balanceSteps, lifetimeEarnedSteps, lifetimeSpentSteps);

  @override
  String toString() => 'WalletSnapshot(balance: $balanceSteps, '
      'earned: $lifetimeEarnedSteps, spent: $lifetimeSpentSteps)';
}

/// Couche de persistance DUALE du compte-etapes (StepWays LOT 1, ST2).
///
/// POURQUOI une double persistance — ET LA RAISON D'ORIGINE N'EXISTE PLUS
/// (tache 613). Ce commentaire disait que la base Drift tournait EN MEMOIRE
/// (`NativeDatabase.memory()`, VOLATILE) et qu'un solde pose en Drift seul
/// disparaitrait au redemarrage. C'ETAIT VRAI, ET C'EST CE CONSTAT QUI A FAIT
/// TROUVER LE DEFAUT : la base etait bien volatile EN PRODUCTION. Elle vit
/// desormais dans un fichier.
///
/// LA SOURCE DURABLE RESTE SharedPreferences (3 cles entieres) et Drift
/// ([WalletBalance]) en reste le MIROIR canonique, hydrate au boot par [load].
/// On ne renverse pas ce montage dans le meme lot que la persistance : le solde
/// est de l'argent, et les deux etages sont aujourd'hui ECRITS ENSEMBLE a chaque
/// mouvement, donc d'accord entre eux. Le miroir est devenu redondant, il n'est
/// pas devenu faux. Sa suppression est un point OUVERT, pas un oubli.
///
/// LA NUANCE QUI COMPTE, ET IL NE FAUT PAS LA PERDRE : c'est bien pour cela que
/// le solde SURVIVAIT deja a une fermeture avant la tache 613. Ce que la base
/// volatile emportait, c'etait la progression, le journal, la fiche medicale et
/// les sentiers telecharges — pas la cagnotte, qui etait sauvee par ce
/// contournement. Et les achats faits au magasin n'ont jamais rien risque : la
/// transaction est chez Google ou Apple, la restauration les ramene.
///
/// Ecritures : [credit] / [debit] mettent a jour prefs ET Drift dans la meme
/// operation (+ `updatedAt`), puis emettent le nouveau solde sur [watch].
/// Regles metier fines (offline, complement store, quoteResume) = ST4
/// (`MonetizationService`) ; ici, uniquement la persistance du solde.
class WalletStore {
  WalletStore({
    required AppDatabase db,
    SharedPreferences? prefs,
    String userId = kWalletLocalUserId,
  })  : _db = db,
        _prefs = prefs,
        _userId = userId;

  final AppDatabase _db;
  SharedPreferences? _prefs;
  final String _userId;

  final _controller = StreamController<WalletSnapshot>.broadcast();
  WalletSnapshot _snapshot = const WalletSnapshot.empty();
  bool _loaded = false;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Solde courant en memoire (0 tant que [load] n'a pas ete appele).
  WalletSnapshot get snapshot => _snapshot;

  /// Solde courant en etapes (raccourci sur [snapshot]).
  int get balanceSteps => _snapshot.balanceSteps;

  /// Vrai une fois l'etat durable charge et Drift hydrate.
  bool get isLoaded => _loaded;

  /// Observe le solde. Emet immediatement l'etat courant, puis a chaque
  /// [credit] / [debit].
  Stream<WalletSnapshot> watch() async* {
    yield _snapshot;
    yield* _controller.stream;
  }

  /// Hydrate l'etat depuis la SOURCE DURABLE (prefs) et met a jour le MIROIR
  /// Drift (a appeler au boot). Idempotent.
  ///
  /// Drift est (re)ecrit a partir des prefs a chaque demarrage — les prefs font
  /// foi. Cela restait vrai apres la tache 613 : la base est durable, mais elle
  /// n'est pas devenue la source du solde pour autant, et reecrire le miroir au
  /// boot le garde aligne sans rien risquer.
  Future<void> load() async {
    final prefs = await _preferences;
    _snapshot = WalletSnapshot(
      balanceSteps: prefs.getInt(kWalletBalanceStepsPrefsKey) ?? 0,
      lifetimeEarnedSteps: prefs.getInt(kWalletLifetimeEarnedPrefsKey) ?? 0,
      lifetimeSpentSteps: prefs.getInt(kWalletLifetimeSpentPrefsKey) ?? 0,
    );
    await _mirrorToDrift();
    _loaded = true;
    _controller.add(_snapshot);
    _log.d('[WalletStore] Hydrate: $_snapshot');
  }

  /// Cree [amount] etapes au solde (gain). [amount] doit etre > 0.
  ///
  /// Ecrit prefs ET Drift, incremente le cumul GAGNE, emet le nouveau solde.
  Future<WalletSnapshot> credit(int amount) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'doit etre strictement > 0');
    }
    await _apply(
      balanceSteps: _snapshot.balanceSteps + amount,
      lifetimeEarnedSteps: _snapshot.lifetimeEarnedSteps + amount,
      lifetimeSpentSteps: _snapshot.lifetimeSpentSteps,
    );
    _log.d('[WalletStore] +$amount etapes -> solde ${_snapshot.balanceSteps}');
    return _snapshot;
  }

  /// Debite [amount] etapes du solde (depense). [amount] doit etre > 0 et
  /// <= solde courant (jamais de solde negatif).
  ///
  /// Ecrit prefs ET Drift, incremente le cumul DEPENSE, emet le nouveau solde.
  Future<WalletSnapshot> debit(int amount) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'doit etre strictement > 0');
    }
    if (amount > _snapshot.balanceSteps) {
      throw StateError(
        'Solde insuffisant: debit $amount > solde ${_snapshot.balanceSteps}',
      );
    }
    await _apply(
      balanceSteps: _snapshot.balanceSteps - amount,
      lifetimeEarnedSteps: _snapshot.lifetimeEarnedSteps,
      lifetimeSpentSteps: _snapshot.lifetimeSpentSteps + amount,
    );
    _log.d('[WalletStore] -$amount etapes -> solde ${_snapshot.balanceSteps}');
    return _snapshot;
  }

  /// RESTAURE un solde complet depuis le coffre de reconnexion (StepWays —
  /// modele code-sur-tel, #99784). Ecrit le [snapshot] tel quel (solde + cumuls)
  /// vers la source durable (prefs) ET le miroir Drift, puis emet.
  ///
  /// A distinguer de [credit]/[debit] (deltas metier) : ici on POSE un etat
  /// complet venu d'un autre appareil via le coffre chiffre. Idempotent.
  Future<void> restoreSnapshot(WalletSnapshot snapshot) async {
    await _apply(
      balanceSteps: snapshot.balanceSteps,
      lifetimeEarnedSteps: snapshot.lifetimeEarnedSteps,
      lifetimeSpentSteps: snapshot.lifetimeSpentSteps,
    );
    _loaded = true;
    _log.d('[WalletStore] Restaure depuis coffre: $_snapshot');
  }

  /// Ecrit un nouvel etat vers prefs ET Drift, met a jour le cache et emet.
  Future<void> _apply({
    required int balanceSteps,
    required int lifetimeEarnedSteps,
    required int lifetimeSpentSteps,
  }) async {
    _snapshot = WalletSnapshot(
      balanceSteps: balanceSteps,
      lifetimeEarnedSteps: lifetimeEarnedSteps,
      lifetimeSpentSteps: lifetimeSpentSteps,
    );
    final prefs = await _preferences;
    await prefs.setInt(kWalletBalanceStepsPrefsKey, balanceSteps);
    await prefs.setInt(kWalletLifetimeEarnedPrefsKey, lifetimeEarnedSteps);
    await prefs.setInt(kWalletLifetimeSpentPrefsKey, lifetimeSpentSteps);
    await _mirrorToDrift();
    _controller.add(_snapshot);
  }

  /// Reflete l'etat courant dans le miroir Drift (upsert + `updatedAt`).
  Future<void> _mirrorToDrift() async {
    await _db.walletDao.upsert(
      WalletBalanceCompanion.insert(
        userId: _userId,
        balanceSteps: Value(_snapshot.balanceSteps),
        lifetimeEarnedSteps: Value(_snapshot.lifetimeEarnedSteps),
        lifetimeSpentSteps: Value(_snapshot.lifetimeSpentSteps),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Libere le stream (a appeler au dispose du provider).
  void dispose() {
    _controller.close();
  }
}

/// Provider Riverpod du [WalletStore].
///
/// Branche sur la meme instance Drift que le reste de l'app
/// ([databaseProvider]). L'appel de [WalletStore.load] au boot (hydratation
/// prefs -> Drift) est cable en ST5 (`app_bootstrap_provider`).
final walletStoreProvider = Provider<WalletStore>((ref) {
  final db = ref.watch(databaseProvider);
  final store = WalletStore(db: db);
  ref.onDispose(store.dispose);
  return store;
});
