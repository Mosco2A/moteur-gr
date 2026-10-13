import 'package:drift/drift.dart';

/// Table des informations de sante du randonneur — LOCAL ONLY.
///
/// TABLE HERITEE, VIDE PAR CONSTRUCTION DEPUIS LA TACHE 613. La fiche medicale
/// n'est plus rangee ici : elle a son PROPRE FICHIER sous le dossier declare
/// exclu de la sauvegarde du telephone (`HealthInfoFile`). La raison est
/// que la base est devenue durable et doit, elle, remonter dans cette sauvegarde
/// pour que la progression et le carnet suivent le randonneur qui change
/// d'appareil — et qu'un fichier de base ne s'exclut pas table par table. La
/// marche de migration v28 vide cette table une fois ; plus aucun code de
/// production n'y ecrit.
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
