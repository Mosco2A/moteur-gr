import '../../../core/data/database.dart';
import '../../../core/data/daos/pois_dao.dart';

/// Repository pour les points d'interet (POI).
///
/// Couche d'acces aux donnees via Drift (SQLite local).
/// Expose les requetes metier : par etape, par type, ou tous.
class PoiRepository {
  PoiRepository({required AppDatabase db}) : _dao = PoisDao(db);

  final PoisDao _dao;

  /// Recupere tous les POI d'une etape.
  ///
  /// [trailId] identifiant du sentier, [stageNumber] numero de l'etape.
  Future<List<Poi>> getByStage(String trailId, int stageNumber) {
    return _dao.getByStage(trailId, stageNumber);
  }

  /// Recupere tous les POI d'un type donne pour un sentier.
  ///
  /// [type] est un String libre (ex: 'water', 'refuge', 'shop').
  Future<List<Poi>> getByType(String trailId, String type) async {
    final all = await _dao.getByTrailId(trailId);
    return all.where((poi) => poi.type == type).toList();
  }

  /// Recupere tous les POI d'un sentier.
  Future<List<Poi>> getAll(String trailId) {
    return _dao.getByTrailId(trailId);
  }
}
