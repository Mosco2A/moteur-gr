import 'package:drift/drift.dart';

/// Table du profil randonneur — donnee SENSIBLE (morpho), LOCAL + miroir cloud
/// anonyme (StepWays LOT 4, faisabilite Ph1).
///
/// Un seul profil par utilisateur : une ligne par [userId] (hash SHA-256
/// deterministe cross-device, cf. `anonymous_id_service.dart`, comme le wallet
/// L1). Porte la fiche d'info (1ere page de la faisabilite) :
///   - [age], [heightCm], [weightKg] : morpho SENSIBLE (art. 9 RGPD). L'IMC est
///     CALCULE localement a partir de taille/poids, JAMAIS stocke (donnee
///     derivee, recalculable — on ne persiste que la source).
///   - [sex] : nullable (optionnel ; utile aux normes du test 6 min ATS/Enright).
///   - [countryIso] : code pays ISO 3166-1 alpha-2, separe de la langue.
///   - [updatedAt] : horodatage (last-write-wins du miroir cloud anonyme).
///
/// CONFIDENTIALITE (spec §3.1, FAI-D) : la SOURCE DURABLE est locale
/// (SharedPreferences aujourd'hui, DB volatile en memoire ; Drift = miroir
/// hydrate au boot, comme le wallet). Le miroir cloud (CloudSyncService) est
/// rattache au hash anonyme UNIQUEMENT — ZERO nom, ZERO e-mail. Ce miroir sert
/// aussi la restauration du profil au changement de telephone. Envoi soumis au
/// consentement `ConsentPurpose.healthData` (art. 9, finalite morpho etendue).
///
/// Ajoutee en migration v25.
class HikerProfile extends Table {
  /// Identifiant utilisateur (hash SHA-256 deterministe) — cle primaire.
  /// Avant liaison de compte : cle locale stable (`kHikerLocalUserId`).
  TextColumn get userId => text()();

  /// Age en annees. Declencheur d'un rappel « consultation conseillee » 65+.
  IntColumn get age => integer().withDefault(const Constant(0))();

  /// Taille en centimetres (SENSIBLE). Sert au calcul local de l'IMC.
  IntColumn get heightCm => integer().withDefault(const Constant(0))();

  /// Poids en kilogrammes (SENSIBLE). Sert au calcul local de l'IMC.
  RealColumn get weightKg => real().withDefault(const Constant(0))();

  /// Sexe (nullable, optionnel). Valeurs stables 'female' / 'male' ; null =
  /// non renseigne (les normes du test 6 min retombent alors sur une moyenne).
  TextColumn get sex => text().nullable()();

  /// Code pays ISO 3166-1 alpha-2 (ex. 'FR', 'DE'), separe de la langue.
  TextColumn get countryIso => text().withDefault(const Constant(''))();

  /// Date de derniere modification (last-write-wins du miroir cloud anonyme).
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
