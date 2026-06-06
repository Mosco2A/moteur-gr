import '../domain/models/tip_card.dart';

/// Repository pour les fiches conseils contextualisees.
///
/// Filtre les TipCard selon le sentier (scope), la date (season)
/// et l altitude courante. Tri par priorite decroissante.
/// Aucune dependance vers poi/, trek/, after/, planning/, feedback/.
class TipCardRepository {
  TipCardRepository({
    required List<TipCard> allCards,
  }) : _allCards = allCards;

  final List<TipCard> _allCards;

  /// Filtre les fiches conseils pertinentes pour le contexte donne.
  ///
  /// [trailScope] : identifiant du sentier (gr10, tmb, ...) ou null pour tous.
  /// [currentSeason] : saison courante (summer, winter, ...) ou null pour toutes.
  /// [currentAltitudeM] : altitude courante en metres ou null pour ignorer le filtre altitude.
  /// Retourne les fiches triees par priorite decroissante.
  List<TipCard> filterCards({
    String? trailScope,
    String? currentSeason,
    int? currentAltitudeM,
  }) {
    var filtered = _allCards.where((card) {
      // Filtre scope : accepte si scope == all ou correspond au sentier
      if (trailScope != null &&
          card.scope != 'all' &&
          card.scope != trailScope) {
        return false;
      }

      // Filtre saison : accepte si season == all ou correspond a la saison
      if (currentSeason != null &&
          card.season != 'all' &&
          card.season != currentSeason) {
        return false;
      }

      // Filtre altitude : accepte si pas de min ou altitude >= min
      if (currentAltitudeM != null && card.minAltitudeM != null) {
        if (currentAltitudeM < card.minAltitudeM!) {
          return false;
        }
      }

      return true;
    }).toList();

    // Tri par priorite decroissante
    filtered.sort((a, b) => b.priority.compareTo(a.priority));

    return filtered;
  }

  /// Filtre les fiches par categorie.
  ///
  /// [category] : categorie recherchee (String extensible).
  /// Applique ensuite les memes filtres contextuels.
  List<TipCard> filterByCategory(
    String category, {
    String? trailScope,
    String? currentSeason,
    int? currentAltitudeM,
  }) {
    final byCategory = _allCards.where((card) => card.category == category).toList();
    final subRepo = TipCardRepository(allCards: byCategory);
    return subRepo.filterCards(
      trailScope: trailScope,
      currentSeason: currentSeason,
      currentAltitudeM: currentAltitudeM,
    );
  }

  /// Retourne toutes les categories distinctes presentes.
  Set<String> get availableCategories =>
      _allCards.map((card) => card.category).toSet();

  /// Nombre total de fiches.
  int get totalCount => _allCards.length;
}
