import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/stage.dart';
import '../../trail/providers/trail_providers.dart';

/// Identifiant du sentier actif, utilise par [stagesProvider] pour charger les
/// etapes du bon sentier.
///
/// DERIVE du sentier actif ([trailConfigProvider], lui-meme pilote par la
/// selection catalogue) : par defaut il reflete donc le sentier courant. Sans
/// cela il restait a chaine vide et JAMAIS ecrit (#99423 §4.1), d'ou une liste
/// d'etapes toujours vide. Reste un [StateProvider] surchargeable/ecrasable
/// (ex. tests, ou l'amorce qui le reaffirme apres le seed).
final currentTrailIdProvider =
    StateProvider<String>((ref) => ref.watch(trailConfigProvider).id);

/// Provider des etapes du sentier actif.
///
/// Charge les etapes depuis TrailDataProvider (E2.1c) en utilisant
/// le trailId fourni par currentTrailIdProvider.
/// Retourne une liste triee par stageNumber.
final stagesProvider = FutureProvider<List<StageModel>>((ref) async {
  final trailId = ref.watch(currentTrailIdProvider);
  if (trailId.isEmpty) return [];

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
