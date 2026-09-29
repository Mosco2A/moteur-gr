import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trail_meteo_table.dart';

part 'trail_meteo_dao.g.dart';

/// DAO de la meteo deposee par le serveur (lot 625).
///
/// AUCUNE DE CES METHODES NE TOUCHE AU RESEAU, et c est le point du lot : la
/// lecture de la meteo est devenue une lecture de base, exactement comme celle des
/// etapes ou des points d interet.
@DriftAccessor(tables: [TrailMeteo])
class TrailMeteoDao extends DatabaseAccessor<AppDatabase>
    with _$TrailMeteoDaoMixin {
  TrailMeteoDao(super.db);

  /// LE BULLETIN D UNE ETAPE — LA SEULE LECTURE DONT L AFFICHAGE A BESOIN.
  ///
  /// Rend `null` quand le serveur n a encore rien depose pour cette etape. **Ce
  /// `null` est une reponse, pas une panne** : l ecran doit dire qu il n a pas
  /// encore recu de bulletin, jamais en inventer un.
  Future<TrailMeteoData?> pourEtape(String trailId, int stageNumber) {
    return (select(trailMeteo)
          ..where((t) =>
              t.trailId.equals(trailId) & t.stageNumber.equals(stageNumber)))
        .getSingleOrNull();
  }

  /// Tous les bulletins d un sentier, par numero d etape croissant.
  Future<List<TrailMeteoData>> pourSentier(String trailId) {
    return (select(trailMeteo)
          ..where((t) => t.trailId.equals(trailId))
          ..orderBy([(t) => OrderingTerm.asc(t.stageNumber)]))
        .get();
  }

  /// Insere ou remplace un bulletin.
  ///
  /// L ECRITURE EST IDEMPOTENTE, ET LE MODELE EN DEPEND. La borne du serveur
  /// (#K4 de la conception 611) fait volontairement relire des enregistrements
  /// deja recus : relire est gratuit, sauter est definitif. Un `insertOnConflictUpdate`
  /// sur l identite publiee est exactement ce que cela demande.
  Future<void> insertOrReplace(TrailMeteoCompanion entry) {
    return into(trailMeteo).insertOnConflictUpdate(entry);
  }

  /// Retire un bulletin par son identite publiee (marqueur de suppression).
  Future<int> deleteById(String id) {
    return (delete(trailMeteo)..where((t) => t.id.equals(id))).go();
  }

  /// Retire tous les bulletins d un sentier.
  ///
  /// Sert la remise a zero d un sentier trop en retard pour que les marqueurs de
  /// suppression aient ete conserves cote serveur
  /// ([RevisionDeDonnee.exigeUneCopieComplete]) : la meteo doit partir avec le
  /// reste du sentier, dans la meme transaction.
  Future<int> deleteByTrailId(String trailId) {
    return (delete(trailMeteo)..where((t) => t.trailId.equals(trailId))).go();
  }
}
