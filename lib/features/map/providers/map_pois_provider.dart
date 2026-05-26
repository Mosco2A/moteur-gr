import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/poi.dart';
import '../../trail/providers/pois_provider.dart';

/// Provider des types de POI actuellement actifs (visibles sur la carte).
///
/// Tous les types sont actifs par défaut.
/// L'utilisateur peut désactiver/réactiver chaque type via la barre de filtres.
final activePoiTypesProvider =
    StateProvider<Set<PoiType>>((ref) => PoiType.values.toSet());

/// Provider de la liste filtrée des POIs à afficher sur la carte.
///
/// Charge les POIs du sentier via poisProvider,
/// puis filtre selon les types actifs dans activePoiTypesProvider.
final mapPoisProvider =
    FutureProvider.family<List<PoiModel>, String>((ref, trailId) async {
  final allPois = await ref.watch(poisProvider(trailId).future);
  final activeTypes = ref.watch(activePoiTypesProvider);

  return allPois.where((poi) => activeTypes.contains(poi.type)).toList();
});

/// Provider des types de POI présents dans les données du sentier.
///
/// Utilisé par la barre de filtres pour n'afficher que les chips pertinents.
final availablePoiTypesProvider =
    FutureProvider.family<Set<PoiType>, String>((ref, trailId) async {
  final allPois = await ref.watch(poisProvider(trailId).future);
  return allPois.map((poi) => poi.type).toSet();
});
