import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/stage.dart';
import 'trail_providers.dart';

/// Identifiant du sentier actif (selectionne par l'utilisateur).
///
/// Utilise par stagesProvider pour charger les etapes du bon sentier.
/// Modifiable via ref.read(currentTrailIdProvider.notifier).state = 'gr10'.
final currentTrailIdProvider = StateProvider<String>((ref) => '');

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
