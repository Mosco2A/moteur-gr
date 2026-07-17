import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/data/database.dart';
import 'weather_providers.dart' show stagesDaoProvider;

/// Étape de référence hors trek (préparation / HUB au repos) — D-3.
///
/// Il n'existe pas de notion « étape du jour » hors GPS live
/// (`currentStageIdProvider` est piloté par le tracking). Pour la tuile HUB et
/// l'ouverture de l'écran météo au repos, on affiche par défaut **l'étape 1**.
/// Provider mutable : un futur cadrage (dernière étape planifiée/consultée)
/// pourra le surcharger sans toucher aux widgets consommateurs.
final referenceStageNumberProvider = StateProvider<int>((ref) => 1);

/// Liste des étapes d'un sentier donné (triées par numéro).
///
/// Chargée directement via [StagesDao] à partir d'un `trailId` explicite
/// (celui de la route météo), sans dépendre de `currentTrailIdProvider`.
/// Sert la vue « Toutes les étapes » de l'écran météo.
final trailStagesProvider =
    FutureProvider.family<List<Stage>, String>((ref, trailId) async {
  if (trailId.isEmpty) return const [];
  final dao = ref.watch(stagesDaoProvider);
  return dao.getByTrailId(trailId);
});
