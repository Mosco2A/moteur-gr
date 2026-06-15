import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/waypoint_service.dart';
import 'waypoint_providers.dart';

/// Etat des FILTRES de la carte des waypoints (F8A-04, Comment Filtering R1).
///
/// Filtrage facon FarOut : par TYPE (eau/ravitaillement/danger/camp/
/// connectivite/jonction) ET par CONDITION RECENTE (n'afficher que les
/// waypoints ayant un commentaire de condition recent). Immuable.
class WaypointFilterState {
  const WaypointFilterState({
    required this.visibleTypes,
    this.recentConditionOnly = false,
  });

  /// Tous les types visibles par defaut (aucun filtre actif).
  factory WaypointFilterState.all() => WaypointFilterState(
        visibleTypes: WaypointType.values.toSet(),
      );

  /// Types de waypoint actuellement affiches.
  final Set<String> visibleTypes;

  /// Si vrai, ne montrer que les waypoints avec une condition recente
  /// (ex 'eau coule' vs 'eau a sec') — filtre FarOut sur les conditions.
  final bool recentConditionOnly;

  bool isTypeVisible(String type) => visibleTypes.contains(type);

  WaypointFilterState copyWith({
    Set<String>? visibleTypes,
    bool? recentConditionOnly,
  }) {
    return WaypointFilterState(
      visibleTypes: visibleTypes ?? this.visibleTypes,
      recentConditionOnly: recentConditionOnly ?? this.recentConditionOnly,
    );
  }
}

/// Notifier des filtres de la carte des waypoints (F8A-04).
///
/// Pure logique d'etat UI (aucun acces reseau) : bascule la visibilite d'un
/// type, (de)selectionne tout, active le filtre condition recente.
class WaypointFilterNotifier extends StateNotifier<WaypointFilterState> {
  WaypointFilterNotifier() : super(WaypointFilterState.all());

  /// Active/desactive l'affichage d'un type de waypoint.
  void toggleType(String type) {
    final next = Set<String>.from(state.visibleTypes);
    if (next.contains(type)) {
      next.remove(type);
    } else {
      next.add(type);
    }
    state = state.copyWith(visibleTypes: next);
  }

  /// Affiche tous les types.
  void showAll() =>
      state = state.copyWith(visibleTypes: WaypointType.values.toSet());

  /// Masque tous les types.
  void hideAll() => state = state.copyWith(visibleTypes: <String>{});

  /// Bascule le filtre "condition recente uniquement".
  void toggleRecentConditionOnly() => state =
      state.copyWith(recentConditionOnly: !state.recentConditionOnly);
}

/// Provider des filtres de la carte des waypoints (F8A-04).
final waypointFilterProvider =
    StateNotifierProvider<WaypointFilterNotifier, WaypointFilterState>(
  (ref) => WaypointFilterNotifier(),
);

/// Waypoints d'un sentier lus depuis le CACHE LOCAL (offline-first, R3).
///
/// `FutureProvider.family` : aucune logique reseau dans le widget, tout passe
/// par [WaypointService] (lecture cache). Le filtrage par type est applique
/// cote widget a partir de [waypointFilterProvider] (etat UI).
final trailWaypointsProvider =
    FutureProvider.family<List<WaypointView>, String>((ref, trailId) {
  return ref.watch(waypointServiceProvider).waypointsForTrail(trailId);
});

/// Commentaires VISIBLES d'un waypoint (cache local, 'removed' masque, DSA).
///
/// `FutureProvider.family` indexe par waypointId. Lecture offline-first.
final waypointCommentsProvider =
    FutureProvider.family<List<WaypointCommentView>, String>(
        (ref, waypointId) async {
  final rows =
      await ref.watch(waypointServiceProvider).visibleComments(waypointId);
  return rows
      .map((c) => WaypointCommentView(
            texte: c.texte,
            condition: c.condition,
            createdAt: c.createdAt,
            synced: c.syncState == 'synced',
          ))
      .toList(growable: false);
});

/// Vue lisible d'un commentaire de condition pour l'UI (F8A-04).
class WaypointCommentView {
  const WaypointCommentView({
    required this.texte,
    required this.condition,
    required this.createdAt,
    required this.synced,
  });

  final String texte;
  final String? condition;
  final DateTime createdAt;
  final bool synced;
}
