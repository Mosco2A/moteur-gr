// E5.16 — Repository informations sante LOCAL ONLY.
//
// Persistence locale via Drift (table health_info_entries).
// JAMAIS de Firestore. Les donnees medicales restent exclusivement
// sur le telephone. Fournit save/get/delete pour HealthInfoScreen.

import 'package:drift/drift.dart';

import '../../../core/data/database.dart';
import '../../../core/data/tables/health_info_table.dart';
import '../../../core/data/daos/health_info_dao.dart';
import '../domain/models/health_info.dart';

/// Repository LOCAL pour les informations de sante.
///
/// Utilise Drift (table 'health_info_entries') pour stocker
/// les donnees medicales du randonneur. Aucune synchronisation cloud.
///
/// IMPORTANT : ces donnees ne quittent JAMAIS le telephone.
/// Pas de Firestore, pas de Firebase, pas de sync.
class HealthInfoRepository {
  HealthInfoRepository({required this.dao});

  /// DAO Drift pour les operations sur la table health_info.
  final HealthInfoDao dao;

  /// Sauvegarde les informations de sante en local.
  ///
  /// Ecrase les donnees precedentes (un seul profil).
  Future<void> save(HealthInfo info) async {
    // Supprimer l'ancien profil puis inserer le nouveau
    await dao.deleteAll();
    await dao.insertEntry(HealthInfoEntriesCompanion.insert(
      bloodType: info.bloodType,
      allergies: info.allergies,
      treatments: info.treatments,
      doctorContact: info.doctorContact,
      insuranceNumber: info.insuranceNumber,
    ));
  }

  /// Recupere les informations de sante depuis le stockage local.
  ///
  /// Retourne un [HealthInfo] vide (champs '') si aucune donnee
  /// n'a encore ete sauvegardee. Ne retourne JAMAIS null.
  Future<HealthInfo> get() async {
    final entry = await dao.getFirst();

    if (entry == null) return const HealthInfo();

    return HealthInfo(
      bloodType: entry.bloodType,
      allergies: entry.allergies,
      treatments: entry.treatments,
      doctorContact: entry.doctorContact,
      insuranceNumber: entry.insuranceNumber,
    );
  }

  /// Supprime toutes les informations de sante du telephone.
  ///
  /// Utilise en cas de deconnexion ou demande explicite de l'utilisateur.
  Future<void> delete() async {
    await dao.deleteAll();
  }
}
