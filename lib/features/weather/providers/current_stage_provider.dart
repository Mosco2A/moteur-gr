import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/data/database.dart';
import '../../trek/providers/gps_providers.dart' show currentStageIdProvider;
import 'weather_providers.dart' show stagesDaoProvider;

/// Étape de référence hors trek (préparation / HUB au repos) — D-3.
///
/// Il n'existe pas de notion « étape du jour » hors GPS live
/// (`currentStageIdProvider` est piloté par le tracking). Pour la tuile HUB et
/// l'ouverture de l'écran météo au repos, on affiche par défaut **l'étape 1**.
/// Provider mutable : un futur cadrage (dernière étape planifiée/consultée)
/// pourra le surcharger sans toucher aux widgets consommateurs.
final referenceStageNumberProvider = StateProvider<int>((ref) => 1);

/// Numéro d'étape LOCALISÉ « ici et maintenant » (R18 — bandeau météo/incendie
/// de la phase Randonner).
///
/// R18 : le bandeau du haut en rando doit refléter la météo + le risque
/// incendie de la **position GPS actuelle** du randonneur. Le socle météo
/// StepWays est indexé PAR ÉTAPE (coordonnées résolues dynamiquement depuis
/// Drift) : on localise donc via l'**étape détectée par le GPS**
/// ([currentStageIdProvider] du pipeline `positionStream` -> détection
/// d'étape). C'est la même liaison GPS -> étape que le reste du moteur (aucune
/// nouvelle source météo, coords toujours dynamiques, jamais de localité en
/// dur). Repli sur [referenceStageNumberProvider] (étape 1 par défaut) tant que
/// le GPS n'a pas fixé d'étape (pas de fix, hors trek).
///
/// [currentStageIdProvider] émet un `stageId` = `'${stageNumber}'`
/// (cf. `domainStagesProvider`) ; on le reconvertit en numéro. Un id non
/// numérique (improbable) retombe proprement sur l'étape de référence.
final localizedStageNumberProvider = Provider<int>((ref) {
  final detectedId = ref.watch(
    currentStageIdProvider.select((async) => async.value),
  );
  final parsed = detectedId == null ? null : int.tryParse(detectedId);
  return parsed ?? ref.watch(referenceStageNumberProvider);
});

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
