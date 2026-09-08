import 'package:drift/drift.dart';

/// Table de l'etat sans-pub app-wide (StepWays LOT 1, regle #99404).
///
/// Chaque ligne represente une SOURCE active de suppression des pubs :
///   - abonnement : [source] = 'subscription', [expiresAt] = null tant qu'actif ;
///   - recompense (rewarded) : [source] = 'reward', [expiresAt] = now + 24h.
///
/// Le trek achete N'EST PAS stocke ici : il est derive de
/// [TrekEntitlements.owned] (source unique #99404). [scope] vaut 'global' par
/// defaut (sans-pub app-wide) ; laisse la porte a un scope par sentier plus
/// tard. Entiers + timestamps only, zero nominatif. Ajoutee en migration v24.
class NoAdsState extends Table {
  /// Cle primaire auto-incrementee.
  IntColumn get id => integer().autoIncrement()();

  /// Source du sans-pub ('subscription' | 'reward').
  TextColumn get source => text()();

  /// Portee du sans-pub ('global' par defaut ; extensible par sentier).
  TextColumn get scope => text().withDefault(const Constant('global'))();

  /// Date de debut de la periode sans-pub.
  DateTimeColumn get startedAt => dateTime()();

  /// Date d'expiration : null = abonnement tant qu'actif ; now + 24h = reward.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Date de derniere modification (last-write-wins du miroir cloud).
  DateTimeColumn get updatedAt => dateTime()();
}
