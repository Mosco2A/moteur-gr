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

  /// NOMBRE DE PERIPLES PAYES sur ce sentier (tache 841). Defaut 0.
  ///
  /// UN ACHAT EGALE UN PERIPLE, et un periple est une marche DATEE. Decision de
  /// Christophe du 16/10 10:09, verbatim : « OUI IL REPAYE ! », qui tranche le
  /// point T1 du design #101920 et confirme le 11/10 : « il est marche une
  /// fois, le refaire c est un autre achat et il faudra le stocker comme un
  /// nouveau periple ».
  ///
  /// POURQUOI UN COMPTEUR A COTE DE [owned], ET PAS A LA PLACE. Les deux droits
  /// ne sont PAS le meme droit, et c'est tout l'equilibre entre les deux
  /// paroles de Christophe. [owned] est le droit sur le CONTENU — la trace,
  /// les etapes, les lieux, les cartes hors ligne — et il est acquis A VIE :
  /// decision du 27/09 (#100698), la propriete n'a aucune echeance. Ce
  /// compteur est le droit de MARCHER une fois de plus, et il se repaie.
  /// Refaire un chapitre dans trois ans n'a donc rien a reverrouiller : on ne
  /// rachete pas le contenu, on achete une marche.
  ///
  /// IL NE REDESCEND JAMAIS, ET AUCUN CODE NE LE DECREMENTE. Un compteur de
  /// periples qui baisse serait un droit retire, c'est-a-dire exactement la
  /// chose que la decision du 27/09 interdit.
  IntColumn get periplesAchetes => integer().withDefault(const Constant(0))();

  /// Origine de l'achat ('none' par defaut, puis 'wallet' / 'store' / ...).
  TextColumn get purchaseSource => text().withDefault(const Constant('none'))();

  /// Date d'achat (null tant que non achete).
  DateTimeColumn get purchasedAt => dateTime().nullable()();

  /// Date de derniere modification (last-write-wins du miroir cloud).
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {trailId};
}
