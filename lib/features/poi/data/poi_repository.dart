import '../../../core/data/daos/pois_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/models/poi.dart';

/// Repository pour les points d'interet.
///
/// Fournit un acces type String aux POIs, sans enum PoiType.
/// Filtre par stage ou par type (String extensible).
class PoiRepository {
  PoiRepository({required AppDatabase db}) : _dao = PoisDao(db);

  final PoisDao _dao;

  /// Recupere les POI d'une etape specifique
  Future<List<PoiModel>> getByStage(String trailId, int stageNumber) async {
    final rows = await _dao.getByStage(trailId, stageNumber);
    return rows.map(PoiModel.fromDb).toList();
  }

  /// Recupere les POI par type (String extensible)
  Future<List<PoiModel>> getByType(String trailId, String type) async {
    final rows = await _dao.getByTrailId(trailId);
    return rows
        .map(PoiModel.fromDb)
        .where((poi) => poi.type == type)
        .toList();
  }

  /// Recupere tous les POI d'un sentier
  Future<List<PoiModel>> getAll(String trailId) async {
    final rows = await _dao.getByTrailId(trailId);
    return rows.map(PoiModel.fromDb).toList();
  }
}
