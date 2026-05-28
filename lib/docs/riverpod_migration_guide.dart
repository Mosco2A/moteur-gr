// ignore_for_file: unused_element, unused_local_variable
// ==========================================================================
// Guide de migration Riverpod 2.x -> 3.x — Moteur GR
// ==========================================================================
//
// Ce fichier documente les 7 patterns de migration necessaires pour passer
// de flutter_riverpod 2.4 a 3.x. Chaque section montre le code AVANT
// (Riverpod 2.4) et APRES (Riverpod 3) avec explications.
//
// Le fichier compile volontairement (dart analyze clean) pour servir
// de reference copier-coller lors de la migration effective.
// ==========================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==========================================================================
// PATTERN 1 — StateNotifierProvider -> NotifierProvider
// ==========================================================================
//
// Riverpod 3 remplace StateNotifier (externe) par Notifier (integre).
// - Plus besoin d'heriter de StateNotifier<T>.
// - Le state est gere via `state` directement dans la classe Notifier.
// - La classe Notifier est auto-disposee si on utilise `autoDispose`.
//
// Cas concret : TrackingProvider du moteur GR.
// --------------------------------------------------------------------------

// --- AVANT (Riverpod 2.4) ---

class _TrackingStateV2 {
  const _TrackingStateV2({this.distanceM = 0, this.recording = false});
  final double distanceM;
  final bool recording;

  _TrackingStateV2 copyWith({double? distanceM, bool? recording}) =>
      _TrackingStateV2(
        distanceM: distanceM ?? this.distanceM,
        recording: recording ?? this.recording,
      );
}

class _TrackingNotifierV2 extends StateNotifier<_TrackingStateV2> {
  _TrackingNotifierV2() : super(const _TrackingStateV2());

  void start() => state = state.copyWith(recording: true);
  void stop() => state = state.copyWith(recording: false, distanceM: 0);
  void addDistance(double m) =>
      state = state.copyWith(distanceM: state.distanceM + m);
}

final _trackingProviderV2 =
    StateNotifierProvider<_TrackingNotifierV2, _TrackingStateV2>(
  (ref) => _TrackingNotifierV2(),
);

// --- APRES (Riverpod 3) ---

class _TrackingStateV3 {
  const _TrackingStateV3({this.distanceM = 0, this.recording = false});
  final double distanceM;
  final bool recording;

  _TrackingStateV3 copyWith({double? distanceM, bool? recording}) =>
      _TrackingStateV3(
        distanceM: distanceM ?? this.distanceM,
        recording: recording ?? this.recording,
      );
}

class _TrackingNotifierV3 extends Notifier<_TrackingStateV3> {
  @override
  _TrackingStateV3 build() => const _TrackingStateV3();

  void start() => state = state.copyWith(recording: true);
  void stop() => state = state.copyWith(recording: false, distanceM: 0);
  void addDistance(double m) =>
      state = state.copyWith(distanceM: state.distanceM + m);
}

final _trackingProviderV3 =
    NotifierProvider<_TrackingNotifierV3, _TrackingStateV3>(
  _TrackingNotifierV3.new,
);

// NOTES MIGRATION :
// - `extends StateNotifier<T>` -> `extends Notifier<T>`
// - Le constructeur `super(initialState)` -> methode `build()` retourne
//   l'etat initial
// - `StateNotifierProvider` -> `NotifierProvider`
// - Le callback `(ref) => ...` -> reference au constructeur `.new`
// - `ref` est accessible via `this.ref` dans le Notifier (pas en parametre)

// ==========================================================================
// PATTERN 2 — StateProvider -> Provider avec Notifier
// ==========================================================================
//
// StateProvider est supprime dans Riverpod 3.
// Remplacer par un Notifier simple pour les etats atomiques.
// --------------------------------------------------------------------------

// --- AVANT (Riverpod 2.4) ---

final _selectedStageIdV2 = StateProvider<int>((ref) => 0);

// Usage V2 : ref.read(_selectedStageIdV2.notifier).state = 3;

// --- APRES (Riverpod 3) ---

class _SelectedStageIdNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int stageId) => state = stageId;
}

final _selectedStageIdV3 =
    NotifierProvider<_SelectedStageIdNotifier, int>(
  _SelectedStageIdNotifier.new,
);

// Usage V3 : ref.read(_selectedStageIdV3.notifier).select(3);
//
// NOTES MIGRATION :
// - StateProvider<T> -> NotifierProvider<XxxNotifier, T>
// - `.notifier).state = x` -> `.notifier).methodeName(x)`
// - Avantage : logique metier explicite via des methodes nommees

// ==========================================================================
// PATTERN 3 — FutureProvider (inchange)
// ==========================================================================
//
// FutureProvider reste identique dans Riverpod 3.
// Aucune migration necessaire.
// --------------------------------------------------------------------------

// --- AVANT (Riverpod 2.4) --- identique a APRES (Riverpod 3)

Future<List<String>> _fetchStages(String trailId) async {
  // Simulation : charger les etapes depuis la DB.
  await Future<void>.delayed(const Duration(milliseconds: 100));
  return ['Etape 1 - Calenzana', 'Etape 2 - Refuge de Ortu'];
}

final _stagesProviderV2 =
    FutureProvider.family<List<String>, String>((ref, trailId) async {
  return _fetchStages(trailId);
});

// --- APRES (Riverpod 3) --- IDENTIQUE

final _stagesProviderV3 =
    FutureProvider.family<List<String>, String>((ref, trailId) async {
  return _fetchStages(trailId);
});

// NOTES :
// - Syntaxe identique entre v2 et v3.
// - Pour des cas complexes (invalidation, mutations), preferer
//   AsyncNotifierProvider (voir pattern AsyncValue plus bas).

// ==========================================================================
// PATTERN 4 — StreamProvider (inchange)
// ==========================================================================
//
// StreamProvider reste identique dans Riverpod 3.
// Aucune migration necessaire.
// --------------------------------------------------------------------------

// --- AVANT (Riverpod 2.4) --- identique a APRES (Riverpod 3)

Stream<double> _positionStream() async* {
  // Simulation : flux GPS.
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield 42.0 + i * 0.001;
  }
}

final _locationStreamV2 = StreamProvider<double>((ref) {
  return _positionStream();
});

// --- APRES (Riverpod 3) --- IDENTIQUE

final _locationStreamV3 = StreamProvider<double>((ref) {
  return _positionStream();
});

// NOTES :
// - Syntaxe identique entre v2 et v3.
// - Pour des streams complexes avec mutations, considerer
//   StreamNotifierProvider.

// ==========================================================================
// PATTERN 5 — ref.watch + select() obligatoire dans build()
// ==========================================================================
//
// Dans Riverpod 3, utiliser `select()` dans les widgets est une bonne
// pratique OBLIGATOIRE pour eviter les rebuilds inutiles.
//
// Regle : dans tout Widget `build()`, ne jamais ecouter un objet entier
// si on n'utilise qu'un seul champ. Utiliser `select()`.
// --------------------------------------------------------------------------

// --- AVANT (Riverpod 2.4) — sans select (rebuild sur tout changement) ---

class _StageDistanceWidgetV2 extends ConsumerWidget {
  const _StageDistanceWidgetV2();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PROBLEME : rebuild a chaque changement de state (recording, speed...)
    final tracking = ref.watch(_trackingProviderV2);
    return Text('${tracking.distanceM.toStringAsFixed(0)} m');
  }
}

// --- APRES (Riverpod 3) — avec select (rebuild uniquement sur distanceM) ---

class _StageDistanceWidgetV3 extends ConsumerWidget {
  const _StageDistanceWidgetV3();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CORRECT : rebuild UNIQUEMENT quand distanceM change
    final distance = ref.watch(
      _trackingProviderV3.select((s) => s.distanceM),
    );
    return Text('${distance.toStringAsFixed(0)} m');
  }
}

// NOTES MIGRATION :
// - `ref.watch(provider)` -> `ref.watch(provider.select((s) => s.champ))`
// - S'applique dans TOUS les build() de widgets
// - Gain de performance significatif sur les ecrans avec beaucoup de
//   donnees (carte, liste d'etapes, tracking en temps reel)
// - select() existe deja en v2 mais devient la norme en v3

// ==========================================================================
// PATTERN 6 — family avec Record (Dart 3 Records)
// ==========================================================================
//
// En Riverpod 2.4, family ne supporte qu'un seul parametre.
// Pour passer plusieurs parametres, on utilisait des tuples ou classes.
//
// Riverpod 3 + Dart 3 : utiliser les Records natifs comme parametre family.
// --------------------------------------------------------------------------

// --- AVANT (Riverpod 2.4) — classe dediee pour multi-params ---

class _PoiFilterParams {
  const _PoiFilterParams(this.trailId, this.category);
  final String trailId;
  final String category;

  @override
  bool operator ==(Object other) =>
      other is _PoiFilterParams &&
      other.trailId == trailId &&
      other.category == category;

  @override
  int get hashCode => Object.hash(trailId, category);
}

final _filteredPoisV2 = FutureProvider.family<List<String>, _PoiFilterParams>(
  (ref, params) async {
    // Filtrer les POI par sentier et categorie.
    return ['POI ${params.trailId} - ${params.category}'];
  },
);

// Usage V2 : ref.watch(_filteredPoisV2(_PoiFilterParams('gr20', 'refuge')));

// --- APRES (Riverpod 3) — Record natif Dart 3 ---

final _filteredPoisV3 =
    FutureProvider.family<List<String>, ({String trailId, String category})>(
  (ref, params) async {
    // Filtrer les POI par sentier et categorie.
    return ['POI ${params.trailId} - ${params.category}'];
  },
);

// Usage V3 :
// ref.watch(_filteredPoisV3((trailId: 'gr20', category: 'refuge')));

// NOTES MIGRATION :
// - Supprimer la classe XxxParams dediee
// - Remplacer par un Record nomme : ({Type champ1, Type champ2})
// - Les Records ont == et hashCode natifs — pas besoin de les implementer
// - Plus lisible, moins de boilerplate, typage garanti

// ==========================================================================
// PATTERN 7 — AsyncValue.when() pour loading / error / data
// ==========================================================================
//
// Pattern identique en v2 et v3 mais renforce comme SEUL pattern
// accepte pour gerer les etats async dans les widgets.
//
// REGLE MOTEUR GR : tout FutureProvider / AsyncNotifierProvider
// DOIT etre consomme via AsyncValue.when() — jamais de .value!
// --------------------------------------------------------------------------

// --- AVANT (Riverpod 2.4) — anti-pattern avec .value! ---

class _StagesListBadV2 extends ConsumerWidget {
  const _StagesListBadV2();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(_stagesProviderV2('gr20'));
    // DANGER : .value! crashe si loading ou erreur
    // final stages = stagesAsync.value!; // NE PAS FAIRE
    return const SizedBox.shrink(); // placeholder
  }
}

// --- APRES (Riverpod 3) — pattern when() obligatoire ---

class _StagesListV3 extends ConsumerWidget {
  const _StagesListV3();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(_stagesProviderV3('gr20'));

    return stagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erreur : $error'),
      ),
      data: (stages) => ListView.builder(
        itemCount: stages.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(stages[index]),
        ),
      ),
    );
  }
}

// NOTES MIGRATION :
// - TOUJOURS utiliser `.when(loading:, error:, data:)` ou `.whenOrNull()`
// - JAMAIS de `.value!` — crashe sur loading/error
// - JAMAIS de `if (asyncValue.hasValue)` sans gerer les autres cas
// - Alternative : `switch (asyncValue)` avec pattern matching Dart 3
//
// Pattern matching alternatif (Dart 3) :
//
//   return switch (stagesAsync) {
//     AsyncData(:final value) => ListView(...),
//     AsyncError(:final error) => Text('$error'),
//     _ => CircularProgressIndicator(),
//   };
//
// Les deux formes sont acceptees dans le moteur GR.

// ==========================================================================
// RESUME — Checklist de migration
// ==========================================================================
//
// [ ] 1. StateNotifierProvider  -> NotifierProvider
//        - StateNotifier<T>     -> Notifier<T> + build()
// [ ] 2. StateProvider          -> NotifierProvider + Notifier simple
// [ ] 3. FutureProvider         -> Inchange (rien a faire)
// [ ] 4. StreamProvider         -> Inchange (rien a faire)
// [ ] 5. ref.watch(provider)    -> ref.watch(provider.select(...))
//        dans tous les build()
// [ ] 6. Classe XxxParams       -> Record Dart 3 ({Type a, Type b})
//        pour family multi-params
// [ ] 7. .value! / hasValue     -> .when(loading:, error:, data:)
//        pour tout AsyncValue
//
// Ordre recommande de migration :
//   1. Commencer par les providers leaf (sans dependances)
//   2. Remonter vers les providers composes
//   3. Finir par les widgets (select + when)
//   4. Lancer `dart analyze` apres chaque fichier migre
// ==========================================================================
