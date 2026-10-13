/// Liste de ce qu'un sentier doit contenir, et repere de revision pose apres
/// copie — sans ce repere, tout se retelechargerait a chaque ouverture.
library;

import 'package:drift/drift.dart';

import '../../models/niveau_de_telechargement.dart';
import '../database.dart';
import '../revision_de_donnee.dart';
import '../tables/trail_manifests_table.dart';

part 'trail_manifests_dao.g.dart';

/// LE REPERE N A PAS PU ETRE POSE — DONC LA COPIE N EST PAS COMPLETE.
///
/// Levee quand `inscrireRevision` ne trouve aucune ligne de liste locale a mettre
/// a jour. Elle vit dans la transaction de la pose, donc elle l annule : mieux
/// vaut un sentier « a prendre » qu un sentier pose sans repere, qui se
/// retelechargerait entierement a chaque ouverture sans que rien ne le dise.
class RepereNonInscriptible implements Exception {
  const RepereNonInscriptible(this.trailId);

  final String trailId;

  @override
  String toString() =>
      'Repere de synchronisation non inscriptible pour « $trailId » : aucune '
      'ligne dans `trail_manifests`. La copie est annulee — un repere absent '
      'ferait retelecharger tout le sentier a chaque ouverture, en silence.';
}

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

  /// LES SENTIERS TELECHARGES SUR CE TELEPHONE — ceux dont il a une copie.
  ///
  /// LE PERIMETRE DE CHRISTOPHE, 28/09 : « on telecharge tout ce qui concerne SES
  /// sentiers ». Pas le catalogue, SES sentiers. Et la distinction n est pas
  /// theorique : [getAll] rend une ligne par sentier PUBLIE, parce que la lecture
  /// du catalogue les conserve toutes pour survivre au hors-ligne. Sur quarante
  /// sentiers publies, un randonneur qui en a copie un seul aurait vu la mise a
  /// jour periodique en telecharger quarante.
  ///
  /// LE CRITERE EST `localVersion` NON NUL, c est-a-dire « une copie a reellement
  /// ete posee ici au moins une fois ». C est le meme fait que l ecran lit pour
  /// dire « telecharge », et il n y en a pas deux.
  ///
  /// CETTE METHODE S APPELAIT `getPossedes`, ET LE NOM ETAIT FAUX (tache 616).
  /// « Posseder » a un sens precis et DEJA PRIS dans ce depot : le DROIT de
  /// realiser, acquis par achat (`ownedTrailIdsProvider`, table
  /// `trek_entitlements`, `TrailAvailability.achete`). Or ce filtre ne lit
  /// aucun droit — il lit la PRESENCE DES DONNEES. Les deux sont deliberement
  /// independants depuis la tache 606 : un sentier gratuit se telecharge sans etre
  /// achete, et un sentier achete peut n etre pas encore telecharge. Un nom qui
  /// melange les deux invite a brancher la mise a jour periodique sur les achats —
  /// ce qui raterait les sentiers gratuits copies, et irait chercher les donnees de
  /// sentiers payes mais absents du telephone.
  ///
  /// LE FILTRE EST DANS LA REQUETE, pas apres la lecture : sur un catalogue qui
  /// grandit, on ne remonte pas quarante lignes pour en garder une.
  Future<List<TrailManifest>> getTelecharges() {
    return (select(
      trailManifests,
    )..where((t) => t.localVersion.isNotNull())).get();
  }

  /// Recupere une entree par son trailId
  Future<TrailManifest?> getByTrailId(String trailId) {
    return (select(
      trailManifests,
    )..where((t) => t.trailId.equals(trailId))).getSingleOrNull();
  }

  /// Insere ou remplace une entree du manifeste
  Future<void> insertOrReplace(TrailManifestsCompanion entry) {
    return into(trailManifests).insertOnConflictUpdate(entry);
  }

  /// Supprime une entree par son trailId
  Future<int> deleteByTrailId(String trailId) {
    return (delete(
      trailManifests,
    )..where((t) => t.trailId.equals(trailId))).go();
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
  /// revision a certifier. L appel vit dans la MEME transaction que la pose des
  /// donnees — un repere qui survivrait a un retour arriere des donnees ferait
  /// croire le telephone a jour sur des donnees absentes, ce qui est pire que pas
  /// de repere du tout.
  ///
  /// ET DEPUIS LA TACHE 610 IL LEVE QUAND L `UPDATE` NE TOUCHE AUCUNE LIGNE (#X10,
  /// laisse ouvert par la tache 607). Le mot de Christophe est « le dernier
  /// timestamp de MAJ COMPLET » : un repere qu on croit pose et qui ne l est pas
  /// est un FAUX SUCCES, pas une petite imperfection. Sans ligne de liste locale,
  /// l `UPDATE` rendait 0 EN SILENCE, la copie etait annoncee reussie, et le
  /// telephone retelechargeait tout le sentier a l ouverture suivante — sans
  /// jamais le dire. Comme l appel vit dans la transaction de la pose, lever ici
  /// annule la copie entiere : le sentier reste « a prendre », ce qui est le seul
  /// etat honnete. Dans la vraie chaine la ligne existe toujours (la lecture du
  /// catalogue l ecrit), donc cette exception ne se declenche que sur un chemin
  /// mal cable — exactement ce qu on veut voir tomber.
  ///
  /// LE NIVEAU VOYAGE AVEC LE REPERE, DANS LA MEME ECRITURE (tache 616). Les deux
  /// faits ne repondent pas a la meme question — [HorodatageServeur] dit JUSQU A
  /// QUAND, [NiveauDeTelechargement] dit JUSQU OU — mais ils sont vrais ou faux
  /// ENSEMBLE : « ce sentier est copie jusqu a l instant T, au niveau N ». Les
  /// ecrire separement autoriserait l etat « a jour jusqu a T, niveau inconnu »,
  /// qui est exactement celui dont on ne peut rien deduire : impossible de savoir
  /// s il faut completer, et la regle de revision refuserait les familles jamais
  /// descendues parce que leur date est anterieure a T.
  Future<int> inscrireRevision(
    String trailId,
    HorodatageServeur revision, {
    required NiveauDeTelechargement niveau,
  }) async {
    final lignes =
        await (update(
          trailManifests,
        )..where((t) => t.trailId.equals(trailId))).write(
          TrailManifestsCompanion(
            localVersion: Value(revision),
            niveauLocal: Value(niveau.code),
          ),
        );
    if (lignes == 0) {
      throw RepereNonInscriptible(trailId);
    }
    return lignes;
  }

  /// JUSQU OU CE SENTIER EST DESCENDU, ou `null` s il n a jamais ete copie.
  ///
  /// UN REPERE POSE SANS NIVEAU LISIBLE REND [NiveauDeTelechargement.regarder], et
  /// ce repli est celui de `depuisLeCode` : ne rien savoir doit faire RECOPIER, pas
  /// faire croire complet. Le cas existe sur une base montee depuis la v28, ou la
  /// colonne vient d apparaitre — mais la v28 a justement remis tous les reperes a
  /// nul, donc en pratique les deux sont nuls ensemble.
  Future<NiveauDeTelechargement?> niveauDe(String trailId) async {
    final ligne = await getByTrailId(trailId);
    if (ligne == null || ligne.localVersion == null) return null;
    return NiveauDeTelechargement.depuisLeCode(ligne.niveauLocal) ??
        NiveauDeTelechargement.regarder;
  }

  /// Oublie la revision locale : le sentier redevient « a telecharger ».
  ///
  /// Remet le repere a zero (null), donc « tout est plus recent que ma revision »
  /// a la prochaine synchronisation. C est ce qui fait qu un sentier supprime puis
  /// repris redescend EN ENTIER, par le meme chemin de code que la premiere copie.
  ///
  /// LE NIVEAU S OUBLIE AVEC LUI (tache 616) : un niveau survivant a la suppression
  /// des donnees dirait « realiser » sur un sentier vide, et la reprise croirait
  /// n avoir qu une mise a jour a faire.
  Future<int> oublierRevision(String trailId) {
    return (update(
      trailManifests,
    )..where((t) => t.trailId.equals(trailId))).write(
      const TrailManifestsCompanion(
        localVersion: Value(null),
        niveauLocal: Value(null),
      ),
    );
  }
}
