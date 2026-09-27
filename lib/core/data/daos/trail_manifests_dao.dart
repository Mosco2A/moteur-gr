import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trail_manifests_table.dart';

part 'trail_manifests_dao.g.dart';

/// DAO pour les manifestes de sentier.
///
/// Operations CRUD sur la table TrailManifests + detection
/// des mises a jour par comparaison version distante vs locale.
@DriftAccessor(tables: [TrailManifests])
class TrailManifestsDao extends DatabaseAccessor<AppDatabase>
    with _$TrailManifestsDaoMixin {
  TrailManifestsDao(super.db);

  /// Recupere toutes les entrees du manifeste local
  Future<List<TrailManifest>> getAll() {
    return select(trailManifests).get();
  }

  /// Recupere une entree par son trailId
  Future<TrailManifest?> getByTrailId(String trailId) {
    return (select(trailManifests)
          ..where((t) => t.trailId.equals(trailId)))
        .getSingleOrNull();
  }

  /// Insere ou remplace une entree du manifeste
  Future<void> insertOrReplace(TrailManifestsCompanion entry) {
    return into(trailManifests).insertOnConflictUpdate(entry);
  }

  /// Supprime une entree par son trailId
  Future<int> deleteByTrailId(String trailId) {
    return (delete(trailManifests)
          ..where((t) => t.trailId.equals(trailId)))
        .go();
  }

  /// Verifie si un sentier necessite une mise a jour.
  ///
  /// Compare la REVISION COURANTE du sentier (dataVersion) a la revision jusqu ou
  /// ce telephone est a jour (localVersion). Retourne true si :
  /// - Le sentier n'existe pas en local
  /// - localVersion est null (rien n est copie — revision zero)
  /// - dataVersion > localVersion
  ///
  /// CE QUE CETTE METHODE NE DIT PAS (tache 605) : elle ne dit pas QUOI prendre.
  /// Elle repond a « existe-t-il quelque chose de plus recent que ma revision ? »,
  /// ce qui suffit pour declencher la synchronisation ; ce qui descend
  /// effectivement se LIT dans la revision de chaque enregistrement
  /// (`RevisionDeDonnee`), cela ne se deduit pas.
  Future<bool> needsUpdate(String trailId) async {
    final entry = await getByTrailId(trailId);
    if (entry == null) return true;
    if (entry.localVersion == null) return true;
    return entry.dataVersion > entry.localVersion!;
  }

  /// INSCRIT LA REVISION jusqu a laquelle [trailId] est copie sur ce telephone.
  ///
  /// LE DEFAUT QUE CETTE METHODE FERME (mesure de la tache 605, confirmant
  /// Athena). `localVersion` decide s il faut telecharger (cf. [needsUpdate]), et
  /// PERSONNE NE L ECRIVAIT apres une mise a jour reussie. `UpdateDownloader`
  /// recevait pourtant un `TrailManifestsDao` en dependance — champ `dao`, injecte
  /// par son provider — et ne s en servait NULLE PART : le DAO avait ete prevu
  /// pour cette ecriture, qui n a jamais ete faite. Consequence mesurable :
  /// `needsUpdate` restait vrai indefiniment et CHAQUE ouverture retelechargeait
  /// l integralite des donnees du sentier.
  ///
  /// C est un `UPDATE`, pas un `INSERT` : sans ligne de manifeste il n y a aucune
  /// revision a certifier, et la methode ne cree rien (retourne 0). L appel vit
  /// dans la MEME transaction que la pose des donnees — un repere de revision qui
  /// survivrait a un retour arriere des donnees ferait croire le telephone a jour
  /// sur des donnees absentes, ce qui est pire que pas de repere du tout.
  Future<int> inscrireRevision(String trailId, int revision) {
    return (update(trailManifests)..where((t) => t.trailId.equals(trailId)))
        .write(TrailManifestsCompanion(localVersion: Value(revision)));
  }

  /// Oublie la revision locale : le sentier redevient « a telecharger ».
  ///
  /// Remet le repere a zero (null), donc « tout est plus recent que ma revision »
  /// a la prochaine synchronisation. C est ce qui fait qu un sentier supprime puis
  /// repris redescend EN ENTIER, par le meme chemin de code que la premiere copie.
  Future<int> oublierRevision(String trailId) {
    return (update(trailManifests)..where((t) => t.trailId.equals(trailId)))
        .write(const TrailManifestsCompanion(localVersion: Value(null)));
  }
}
