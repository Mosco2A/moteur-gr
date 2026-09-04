import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/stage.dart';
import '../../trail/providers/stages_provider.dart';
import '../../trek/providers/gps_providers.dart';
import '../domain/transport_catalog.dart';
import '../domain/transport_info.dart';

/// Endpoints (depart / arrivee) resolus du sentier, DIRECTION-AWARE (parite GR20
/// `_resolveEndpoints`).
///
/// GR20 hardcode le couple depart/arrivee par (parcours, direction). Cote
/// StepWays le moteur reste GENERIQUE : les noms d'endpoints viennent des
/// DONNEES du sentier — les etapes portent `departureName` (point de depart de
/// l'etape) et `arrivalName` (point d'arrivee), socle « donnees externes »
/// fusionne. On resout :
///   * DEPART du trek  = `departureName` de la PREMIERE etape dans le sens de
///     marche ;
///   * ARRIVEE du trek = `arrivalName` de la DERNIERE etape dans le sens de
///     marche.
///
/// Le sens de marche suit la meme regle que le moteur de fin de trek
/// ([currentTrekPlanProvider] / `TrekPlan.fromStages`) : ordre officiel des
/// etapes (croissant par `stageNumber`) si la direction choisie est le 1er sens
/// declare par le sentier ([TrailConfig.directions].first), sinon ordre inverse.
/// Zero code de direction en dur : c'est l'ordre du parcours qui porte le sens.
class TransportEndpoints {
  const TransportEndpoints({required this.departure, required this.arrival});

  /// Nom du point de DEPART du trek (dans le sens de marche courant).
  final String departure;

  /// Nom du point d'ARRIVEE du trek (dans le sens de marche courant).
  final String arrival;

  /// Vrai si au moins un endpoint a un nom exploitable.
  bool get hasNames => departure.isNotEmpty || arrival.isNotEmpty;
}

/// Repli sur le nom d'etape quand `departureName`/`arrivalName` manque (sentier
/// pauvre) : garantit un libelle d'onglet non vide, sans inventer de lieu.
String _departureOf(StageModel s) =>
    s.departureName?.trim().isNotEmpty == true
        ? s.departureName!.trim()
        : s.name.trim();

String _arrivalOf(StageModel s) => s.arrivalName?.trim().isNotEmpty == true
    ? s.arrivalName!.trim()
    : s.name.trim();

/// Resout les endpoints depart/arrivee du sentier [trailId], direction-aware.
///
/// Retourne `null` tant que les etapes ne sont pas chargees (l'ecran affiche un
/// etat de chargement / fallback). Parametre par `trailId` (family) pour rester
/// coherent avec [stagesProvider] et le scope multi-sentiers.
final transportEndpointsProvider =
    Provider.family<TransportEndpoints?, String>((ref, trailId) {
  // Etapes du sentier (socle : departureName / arrivalName). AsyncValue -> on
  // n'a besoin que de la valeur chargee.
  final stages = ref.watch(stagesProvider(trailId)).value;
  if (stages == null || stages.isEmpty) return null;

  // Ordre officiel : croissant par numero d'etape (source unique de l'ordre,
  // comme TrekPlan.fromStages). officialFirst = etape 1, officialLast = derniere.
  final ordered = [...stages]
    ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
  final officialFirst = ordered.first;
  final officialLast = ordered.last;

  // Sens de marche : 1er sens declare par le sentier = ordre croissant de
  // reference ; toute autre direction choisie parcourt le sentier a rebours.
  final config = ref.watch(trailConfigProvider);
  final forward =
      config.directions.isNotEmpty ? config.directions.first : 'NS';
  final selected = ref.watch(selectedDirectionProvider) ?? forward;
  final isForward = selected == forward;

  // Endpoints DIRECTION-AWARE (parite GR20 `_resolveEndpoints`), sans code de
  // direction en dur : c'est l'ordre officiel + le sens qui decident quel NOM
  // lire, sur quelle etape.
  //  * sens de reference : on part du departureName de l'etape 1 et on arrive a
  //    l'arrivalName de la derniere etape ;
  //  * sens inverse : on parcourt le sentier a rebours, donc on PART de la ou il
  //    finit normalement (arrivalName de la derniere etape) et on ARRIVE la ou
  //    il commence normalement (departureName de l'etape 1).
  final departure = isForward
      ? _departureOf(officialFirst)
      : _arrivalOf(officialLast);
  final arrival =
      isForward ? _arrivalOf(officialLast) : _departureOf(officialFirst);

  return TransportEndpoints(departure: departure, arrival: arrival);
});

/// Donnees TRANSPORT du sentier [trailId] (catalogue embarque, offline).
///
/// Simple lecture du [TransportCatalog] (data-driven, genericite #84627).
/// Retourne `null` si le sentier ne fournit pas de donnees transport -> l'ecran
/// affiche un fallback informatif propre (pas de crash). Family par `trailId`.
final trailTransportProvider =
    Provider.family<TrailTransport?, String>((ref, trailId) {
  return TransportCatalog.forTrail(trailId);
});
