/// Table de fiche medicale qu'aucun code de production n'alimente plus depuis
/// la tache 613 : la fiche vit dans son propre fichier, hors sauvegarde.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/health_info_table.dart';

part 'health_info_dao.g.dart';

/// DAO pour les operations sur les informations de sante.
///
/// AUCUN CODE DE PRODUCTION N'ECRIT PLUS ICI DEPUIS LA TACHE 613, ET CE N'EST
/// PAS UN OUBLI DE MENAGE. La fiche medicale a quitte la base pour son PROPRE
/// FICHIER, sous le dossier declare exclu de la sauvegarde du telephone (voir
/// `FicheMedicaleFichier`) : la base est devenue durable et doit remonter dans
/// cette sauvegarde pour que la progression et le carnet survivent au changement
/// d'appareil, or un fichier de base ne s'exclut pas table par table.
///
/// CE QUI RESTE, ET POURQUOI. La table est toujours dans le schema (la retirer
/// demanderait une regeneration du code pour un gain nul), la marche de
/// migration v28 la VIDE une fois — au cas ou un binaire intermediaire y aurait
/// ecrit — et ce DAO est ce qui permet de le faire et de VERIFIER qu'elle reste
/// vide (`base_persistante_613_test.dart`). Une porte gardee fermee, pas une
/// porte oubliee ouverte.
///
/// Fournit les methodes CRUD pour la table HealthInfoEntries.
/// Un seul profil sante par telephone (get first, deleteAll + insert).
@DriftAccessor(tables: [HealthInfoEntries])
class HealthInfoDao extends DatabaseAccessor<AppDatabase>
    with _$HealthInfoDaoMixin {
  HealthInfoDao(super.db);

  /// Recupere le premier (et unique) enregistrement sante.
  ///
  /// Retourne null si aucune donnee sauvegardee.
  Future<HealthInfoEntry?> getFirst() async {
    final entries = await select(healthInfoEntries).get();
    if (entries.isEmpty) return null;
    return entries.first;
  }

  /// Insere un nouvel enregistrement sante.
  Future<int> insertEntry(HealthInfoEntriesCompanion entry) {
    return into(healthInfoEntries).insert(entry);
  }

  /// Supprime tous les enregistrements sante.
  Future<int> deleteAll() {
    return delete(healthInfoEntries).go();
  }
}
