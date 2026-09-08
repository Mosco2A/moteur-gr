import 'package:drift/drift.dart';

/// Table du solde du compte-etapes (StepWays LOT 1, wallet).
///
/// Singleton par utilisateur : une ligne par [userId] (hash SHA-256
/// deterministe cross-device, cf. `anonymous_id_service.dart`). Porte le solde
/// courant en etapes ([balanceSteps]) et les compteurs cumules de vie
/// ([lifetimeEarnedSteps] / [lifetimeSpentSteps]) — entiers uniquement, zero
/// nominatif (miroir cloud non nominatif, A5).
///
/// Schema CANONIQUE : la persistance durable reste SharedPreferences aujourd'hui
/// (DB volatile en memoire), Drift est hydrate au boot depuis les prefs
/// (couche `WalletStore`, ST2). Ajoutee en migration v24.
class WalletBalance extends Table {
  /// Identifiant utilisateur (hash SHA-256 deterministe) — cle primaire.
  TextColumn get userId => text()();

  /// Solde courant du compte-etapes, en etapes. Defaut 0.
  IntColumn get balanceSteps => integer().withDefault(const Constant(0))();

  /// Total cumule d'etapes GAGNEES sur la duree de vie du compte. Defaut 0.
  IntColumn get lifetimeEarnedSteps =>
      integer().withDefault(const Constant(0))();

  /// Total cumule d'etapes DEPENSEES sur la duree de vie du compte. Defaut 0.
  IntColumn get lifetimeSpentSteps =>
      integer().withDefault(const Constant(0))();

  /// Date de derniere modification (last-write-wins du miroir cloud).
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
