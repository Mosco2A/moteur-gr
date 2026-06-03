import 'package:drift/drift.dart';

/// Table des informations de sante du randonneur — LOCAL ONLY.
///
/// Un seul enregistrement par telephone (profil unique).
/// Ces donnees ne quittent JAMAIS le telephone.
/// Ajoutee en migration v10 (E5.16).
class HealthInfoEntries extends Table {
  /// Cle primaire auto-incrementee
  IntColumn get id => integer().autoIncrement()();

  /// Groupe sanguin (ex: 'A+', 'O-', 'AB+')
  TextColumn get bloodType => text().withDefault(const Constant(''))();

  /// Allergies connues (texte libre)
  TextColumn get allergies => text().withDefault(const Constant(''))();

  /// Traitements en cours (texte libre)
  TextColumn get treatments => text().withDefault(const Constant(''))();

  /// Contact du medecin traitant (nom + telephone)
  TextColumn get doctorContact => text().withDefault(const Constant(''))();

  /// Numero d'assurance / mutuelle / carte europeenne
  TextColumn get insuranceNumber => text().withDefault(const Constant(''))();
}
