import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/stage.dart';
import 'seed_provider.dart';
import 'trail_providers.dart';

/// Surcharge optionnelle de l'identifiant du sentier actif.
///
/// Vide par defaut : dans ce cas, le sentier actif est celui resolu par le
/// moteur ([trailIdProvider], derive de la selection au catalogue). On ne
/// renseigne ce provider que pour FORCER un sentier specifique (tests, cas
/// avances). Auparavant il valait '' sans jamais etre ecrit, ce qui figeait
/// [stagesProvider] (et donc l'onglet Planning) sur une liste vide — bug GO-62.
final currentTrailIdProvider = StateProvider<String>((ref) => '');

/// Identifiant du sentier effectivement utilise par [stagesProvider].
///
/// Priorite a la surcharge explicite [currentTrailIdProvider] si elle est
/// renseignee, sinon le sentier actif du moteur ([trailIdProvider]). Garantit
/// que l'itineraire/planning suit le sentier choisi au catalogue sans cablage
/// manuel supplementaire.
final effectiveTrailIdProvider = Provider<String>((ref) {
  final override = ref.watch(currentTrailIdProvider);
  if (override.isNotEmpty) return override;
  return ref.watch(trailIdProvider);
});

/// Provider des etapes du sentier actif.
///
/// Charge les etapes depuis TrailDataProvider (E2.1c) en utilisant
/// le trailId resolu par [effectiveTrailIdProvider].
/// Retourne une liste triee par stageNumber.
///
/// Attend d'abord [trailSeedProvider] pour garantir le chargement des donnees
/// embarquees (base in-memory seedee au demarrage, bug GO-62).
final stagesProvider = FutureProvider<List<StageModel>>((ref) async {
  final trailId = ref.watch(effectiveTrailIdProvider);
  if (trailId.isEmpty) return [];

  // Garantit le seed des donnees embarquees avant lecture.
  await ref.watch(trailSeedProvider.future);

  final dataProvider = ref.watch(trailDataProvider);
  final stages = await dataProvider.getStages(trailId);

  return List.of(stages)
    ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
});

/// Provider d'une etape par son identifiant (stageNumber en String).
///
/// Parametre : id (String) -- le stageNumber converti en String.
/// Charge toutes les etapes du sentier actif, puis filtre par stageNumber.
/// Leve StateError si l'etape n'existe pas.
final stageByIdProvider =
    FutureProvider.family<StageModel, String>((ref, id) async {
  final stageNumber = int.tryParse(id);
  if (stageNumber == null) {
    throw StateError('ID etape invalide: $id');
  }

  final stages = await ref.watch(stagesProvider.future);
  final match = stages.where((s) => s.stageNumber == stageNumber).firstOrNull;

  if (match == null) {
    throw StateError('Etape $id introuvable');
  }

  return match;
});
