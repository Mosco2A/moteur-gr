import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/poi.dart';
import '../../trail/providers/pois_provider.dart';

/// Notifier pour les types de POI actuellement actifs (visibles sur la carte).
///
/// Tous les types sont actifs par defaut.
/// L'utilisateur peut desactiver/reactiver chaque type via la barre de filtres.
class ActivePoiTypesNotifier extends Notifier<Set<PoiType>> {
  @override
  Set<PoiType> build() => PoiType.values.toSet();

  void toggle(PoiType type) {
    if (state.contains(type)) {
      state = Set.from(state)..remove(type);
    } else {
      state = Set.from(state)..add(type);
    }
  }

  void setAll() => state = PoiType.values.toSet();
  void clearAll() => state = {};
}

final activePoiTypesProvider =
    NotifierProvider<ActivePoiTypesNotifier, Set<PoiType>>(
        ActivePoiTypesNotifier.new);

/// Provider de la liste filtree des POIs a afficher sur la carte.
///
/// Charge les POIs du sentier via poisProvider,
/// puis filtre selon les types actifs dans activePoiTypesProvider.
final mapPoisProvider =
    FutureProvider.family<List<PoiModel>, String>((ref, trailId) async {
  final allPois = await ref.watch(poisProvider(trailId).future);
  final activeTypes = ref.watch(activePoiTypesProvider);

  return allPois.where((poi) => activeTypes.contains(poi.type)).toList();
});

/// Provider des types de POI presents dans les donnees du sentier.
///
/// Utilise par la barre de filtres pour n'afficher que les chips pertinents.
final availablePoiTypesProvider =
    FutureProvider.family<Set<PoiType>, String>((ref, trailId) async {
  final allPois = await ref.watch(poisProvider(trailId).future);
  return allPois.map((poi) => poi.type).toSet();
});
