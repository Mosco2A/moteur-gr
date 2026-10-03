/// Les points de depart et d'arrivee viennent des DONNEES des etapes et
/// changent avec le sens de marche : rien n'est ecrit en dur.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/stage_row.dart';
import '../../trail/trail_facade.dart' show stagesProvider;
import '../../trek/providers/gps_providers.dart';
import '../domain/transport_catalog.dart';
import '../domain/transport_info.dart';
import 'lieux_en_base_provider.dart';

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
String _departureOf(StageModel s) => s.departureName?.trim().isNotEmpty == true
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
final transportEndpointsProvider = Provider.family<TransportEndpoints?, String>((
  ref,
  trailId,
) {
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
  final forward = config.directions.isNotEmpty ? config.directions.first : 'NS';
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
  final arrival = isForward
      ? _arrivalOf(officialLast)
      : _departureOf(officialFirst);

  return TransportEndpoints(departure: departure, arrival: arrival);
});

/// Donnees TRANSPORT du sentier [trailId] — LA BASE D'ABORD (tache 641).
///
/// CE QUI ETAIT CASSE, ET C'EST LE BUG 12 PUIS LE BUG 17. Ce provider ne lisait
/// que [TransportCatalog], une constante Dart de 280 lignes derriere un
/// `switch (trailId)`. Consequences mesurees le 30/09 :
///
///  * tout sentier autre que `mare-a-mare-centre` — dont le sentier de
///    demonstration, qui porte un identifiant DIFFERENT — obtenait `null`, donc
///    l'ecran annoncait « Aucune information de transport pour ce sentier » ;
///  * le contenu lui-meme etait truffe de « a completer » : pas un exploitant
///    nomme, pas un horaire, pas un tarif. Et deux informations y etaient
///    FAUSSES — le telephone de l'aeroport d'Ajaccio, et un « autocar
///    Ajaccio-Ghisonaccia via Vizzavona » qu'aucune source ne confirme ;
///  * corriger un horaire demandait de republier l'application.
///
/// LA BASE GAGNE MAINTENANT. Les lieux de transport sont publies dans
/// `trails/{id}/pois` avec un type prefixe `transport_`, ils portent leur
/// exploitant, leur telephone, leur site officiel, leur adresse et leur point
/// GPS, et chaque enregistrement cite sa source. Le catalogue compile reste en
/// dernier recours pour les sentiers pas encore publies.
///
/// LES NOMS D'ENDPOINT VIENNENT DES ETAPES, comme avant : le modele
/// `TrailTransport` indexe par NOM de lieu, et c'est
/// [transportEndpointsProvider] qui les resout, direction-aware. Tant qu'ils ne
/// sont pas connus (etapes non chargees), on ne peut pas construire la version
/// en base — on rend alors le compile, et le provider se recalculera.
final trailTransportProvider = Provider.family<TrailTransport?, String>((
  ref,
  trailId,
) {
  final endpoints = ref.watch(transportEndpointsProvider(trailId));
  if (endpoints != null && endpoints.hasNames) {
    final enBase = ref.watch(
      transportEnBaseProvider((
        trailId: trailId,
        depart: endpoints.departure,
        arrivee: endpoints.arrival,
      )),
    );
    if (enBase != null) return enBase;
  }
  return TransportCatalog.forTrail(trailId);
});
