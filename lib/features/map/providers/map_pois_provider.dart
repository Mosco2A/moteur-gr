import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/poi.dart';
import '../../trail/providers/pois_provider.dart';

/// Provider des types de POI actuellement actifs (visibles sur la carte).
///
/// Tous les types sont actifs par defaut (ensemble vide = tous visibles).
/// L'utilisateur peut desactiver/reactiver chaque type via la barre de filtres.
final activePoiTypesProvider =
    StateProvider<Set<String>?>((ref) => null);

/// Provider de la liste filtree des POIs a afficher sur la carte.
///
/// Charge les POIs du sentier via poisProvider,
/// puis filtre selon les types actifs dans activePoiTypesProvider.
final mapPoisProvider =
    FutureProvider.family<List<PoiModel>, String>((ref, trailId) async {
  final allPois = await ref.watch(poisProvider(trailId).future);
  final activeTypes = ref.watch(activePoiTypesProvider);

  // null = tous visibles (pas de filtre)
  if (activeTypes == null) return allPois;

  return allPois.where((poi) => activeTypes.contains(poi.type)).toList();
});

/// Provider des types de POI presents dans les donnees du sentier.
///
/// Utilise par la barre de filtres pour n'afficher que les chips pertinents.
final availablePoiTypesProvider =
    FutureProvider.family<Set<String>, String>((ref, trailId) async {
  final allPois = await ref.watch(poisProvider(trailId).future);
  return allPois.map((poi) => poi.type).toSet();
});
