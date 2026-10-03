/// Le sentier ACTIF, source de verite de la bascule : l'interface ecrit ici et
/// toute la configuration en derive.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../features/trail/providers/trail_catalog_provider.dart';
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
/// LE BRANCHEMENT ANNONCE ICI EST FAIT (tache 605, MUR N1). Le commentaire de ce
/// provider promettait depuis la Phase 4 qu'« un futur catalogue distant se
/// branchera ici par simple override, sans changer l'UI ». Il rendait en fait
/// `TrailCatalog.all` — le catalogue COMPILE — et tout le chainage distant ecrit
/// a cote (`ManifestService`, `catalogStateProvider`, `UpdateDownloader`) n'avait
/// AUCUN consommateur. Un sentier decrit a distance ne pouvait donc arriver chez
/// un randonneur que par une republication au magasin, ce qui contredit le
/// principe fondateur du produit (Christophe, 27/09 19:57).
///
/// La promesse est tenue, et l'UI n'a effectivement pas change : les quatre
/// lecteurs de ce provider — ecran catalogue, ecran de selection, droits d'acces,
/// « Mes treks » — recoivent desormais le catalogue EFFECTIF, resolu dans
/// l'ordre distant > dernier distant recu > compile
/// ([catalogueSentiersProvider]). L'acces reste SYNCHRONE et la liste n'est
/// jamais vide : le catalogue compile est le plancher, rendu immediatement.
final availableTrailsProvider = Provider<List<TrailConfig>>(
  (ref) => ref.watch(catalogueSentiersProvider).sentiers,
);

/// Sentier ACTIF resolu depuis la selection + le catalogue.
///
/// Resout l'[selectedTrailIdProvider] vers une [TrailConfig] connue, avec repli
/// sur le sentier par defaut si l'id est invalide.
/// C'est ce provider que [trailConfigProvider] consomme par defaut — le moteur
/// reste generique et ne plante jamais sur une selection obsolete.
///
/// IL RESOUT DANS LE CATALOGUE EFFECTIF, PAS SEULEMENT DANS LE COMPILE
/// (tache 605). Il appelait `TrailCatalog.resolveOrDefault`, qui ne connait que
/// les sentiers embarques : un randonneur qui choisissait un sentier venu du
/// distant etait silencieusement RAMENE sur le sentier par defaut, et tout le
/// moteur (theme, etapes, secours) suivait le mauvais sentier. Le repli sur le
/// defaut est conserve pour une selection devenue invalide — c'est ce qui evite
/// de planter sur un sentier retire.
final resolvedTrailConfigProvider = Provider<TrailConfig>((ref) {
  final id = ref.watch(selectedTrailIdProvider);
  final catalogue = ref.watch(availableTrailsProvider);
  for (final sentier in catalogue) {
    if (sentier.id == id) return sentier;
  }
  return catalogue.isNotEmpty ? catalogue.first : TrailCatalog.defaultTrail;
});
