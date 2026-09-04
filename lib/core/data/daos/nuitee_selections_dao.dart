import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/nuitee_selections_table.dart';

part 'nuitee_selections_dao.g.dart';

/// DAO pour les selections de nuitees (PARITE GR20 « Reserver vos nuits »).
///
/// Operations CRUD sur la table NuiteeSelections, filtrees par sentier.
/// Persistance locale (Drift) de l'etat par nuit : type + reserve.
@DriftAccessor(tables: [NuiteeSelections])
class NuiteeSelectionsDao extends DatabaseAccessor<AppDatabase>
    with _$NuiteeSelectionsDaoMixin {
  NuiteeSelectionsDao(super.db);

  /// Recupere toutes les selections de nuitees pour un sentier.
  Future<List<NuiteeSelection>> getByTrailId(String trailId) {
    return (select(nuiteeSelections)
          ..where((t) => t.trailId.equals(trailId))
          ..orderBy([(t) => OrderingTerm.asc(t.dayNumber)]))
        .get();
  }

  /// Enregistre l'etat reserve d'une nuit (upsert par trailId + dayNumber).
  Future<void> setBooked(String trailId, int dayNumber, bool isBooked) async {
    await _upsert(
      trailId,
      dayNumber,
      NuiteeSelectionsCompanion(
        isBooked: Value(isBooked),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Enregistre le type de nuitee d'une nuit (upsert par trailId + dayNumber).
  Future<void> setType(String trailId, int dayNumber, String nuiteeType) async {
    await _upsert(
      trailId,
      dayNumber,
      NuiteeSelectionsCompanion(
        nuiteeType: Value(nuiteeType),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Upsert par (trailId, dayNumber) : met a jour la ligne existante ou
  /// l'insere. Preserve les colonnes non fournies (partial companion).
  Future<void> _upsert(
    String trailId,
    int dayNumber,
    NuiteeSelectionsCompanion patch,
  ) async {
    final existing = await (select(nuiteeSelections)
          ..where((t) =>
              t.trailId.equals(trailId) & t.dayNumber.equals(dayNumber)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(nuiteeSelections)
            ..where((t) => t.id.equals(existing.id)))
          .write(patch);
    } else {
      await into(nuiteeSelections).insert(
        patch.copyWith(
          trailId: Value(trailId),
          dayNumber: Value(dayNumber),
        ),
      );
    }
  }

  /// Supprime toutes les selections d'un sentier (reset).
  Future<int> deleteByTrailId(String trailId) {
    return (delete(nuiteeSelections)..where((t) => t.trailId.equals(trailId)))
        .go();
  }
}
