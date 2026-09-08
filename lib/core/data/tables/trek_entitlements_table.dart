import 'package:drift/drift.dart';

/// Table des droits d'acces par sentier (StepWays LOT 1, wallet).
///
/// Une ligne par [trailId] : etat d'acquisition du trek. [owned] n'est pose
/// qu'a confirmation store (achat complet). [acquiredStages] / [totalStages]
/// tracent l'avancement de l'acquisition etape par etape ;
/// [consumedComplementSteps] est la base de rachat a la reprise (abandon/
/// reprise, quoteResume). [purchaseSource] distingue l'origine ('none' par
/// defaut, puis 'wallet' / 'store' / ...).
///
/// Miroir cloud non nominatif (A5) : entiers + timestamps only. La regle
/// sans-pub #99404 derive de `owned` (le trek achete N'EST PAS stocke dans
/// NoAdsState). Ajoutee en migration v24.
class TrekEntitlements extends Table {
  /// Identifiant du sentier (ex: 'gr20') — cle primaire.
  TextColumn get trailId => text()();

  /// Le trek est-il POSSEDE (achat confirme par le store) ? Defaut false.
  BoolColumn get owned => boolean().withDefault(const Constant(false))();

  /// Nombre d'etapes deja acquises pour ce trek. Defaut 0.
  IntColumn get acquiredStages => integer().withDefault(const Constant(0))();

  /// Nombre total d'etapes du trek (0 tant qu'inconnu). Defaut 0.
  IntColumn get totalStages => integer().withDefault(const Constant(0))();

  /// Etapes de complement store deja consommees — base du rachat a la reprise
  /// (abandon/reprise, quoteResume). Defaut 0.
  IntColumn get consumedComplementSteps =>
      integer().withDefault(const Constant(0))();

  /// Origine de l'achat ('none' par defaut, puis 'wallet' / 'store' / ...).
  TextColumn get purchaseSource =>
      text().withDefault(const Constant('none'))();

  /// Date d'achat (null tant que non achete).
  DateTimeColumn get purchasedAt => dateTime().nullable()();

  /// Date de derniere modification (last-write-wins du miroir cloud).
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {trailId};
}
