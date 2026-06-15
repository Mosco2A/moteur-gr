import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trail_catalog.dart';
import 'trail_config.dart';

/// Identifiant du sentier ACTIF, selectionne par l'utilisateur (F8D-01/F8D-02).
///
/// Source de verite de la bascule de sentier (F8D-02) : l'UI de selection ecrit
/// ici, et toute la config active en derive ([trailConfigProvider]). Initialise
/// sur le sentier par defaut du catalogue (jamais une localite hardcodee).
///
/// En P2-P3 l'etat est en memoire (donnees fictives, #84627). La persistance du
/// choix (relancer l'app sur le dernier sentier) sera branchee plus tard sur le
/// stockage local — surchargeable via override pour les tests/persistance.
final selectedTrailIdProvider = StateProvider<String>(
  (ref) => TrailCatalog.defaultTrail.id,
);

/// Liste des sentiers disponibles au catalogue (multi-sentiers, #84627).
///
/// Expose le catalogue a l'UI (selecteur F8D-02) sans qu'elle lise directement
/// la classe statique : un futur catalogue distant (Phase 4) se branchera ici
/// par simple override, sans changer l'UI.
final availableTrailsProvider = Provider<List<TrailConfig>>(
  (ref) => TrailCatalog.all,
);

/// Sentier ACTIF resolu depuis la selection + le catalogue.
///
/// Resout l'[selectedTrailIdProvider] vers une [TrailConfig] connue, avec repli
/// sur le sentier par defaut si l'id est invalide ([TrailCatalog.resolveOrDefault]).
/// C'est ce provider que [trailConfigProvider] consomme par defaut — le moteur
/// reste generique et ne plante jamais sur une selection obsolete.
final resolvedTrailConfigProvider = Provider<TrailConfig>((ref) {
  final id = ref.watch(selectedTrailIdProvider);
  return TrailCatalog.resolveOrDefault(id);
});
