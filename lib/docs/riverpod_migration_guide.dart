// ignore_for_file: unused_element

/// Guide de migration Riverpod 2.x -> 3.x pour le Moteur GR.
///
/// Ce fichier documente les 7 patterns de migration obligatoires
/// lors du passage de Riverpod 2.4/2.6 vers Riverpod 3.x.
/// Chaque pattern montre le code AVANT (2.x) et APRES (3.x).
///
/// Reference: https://riverpod.dev/docs/migration/from_state_notifier
library riverpod_migration_guide;

// ---------------------------------------------------------------------------
// PATTERN 1 : StateNotifierProvider -> NotifierProvider
// ---------------------------------------------------------------------------
//
// AVANT (Riverpod 2.x):
//
//   class CounterNotifier extends StateNotifier<int> {
//     CounterNotifier() : super(0);
//     void increment() => state++;
//   }
//
//   final counterProvider = StateNotifierProvider<CounterNotifier, int>(
//     (ref) => CounterNotifier(),
//   );
//
// APRES (Riverpod 3.x):
//
//   @riverpod
//   class Counter extends _$Counter {
//     @override
//     int build() => 0;
//     void increment() => state++;
//   }
//
// NOTES:
//   - StateNotifier est deprecie dans Riverpod 3.
//   - Utiliser @riverpod avec code generation (riverpod_generator).
//   - La methode build() remplace le constructeur super(initialValue).
//   - Le state est accessible directement (pas de ref.notifier necessaire).

// ---------------------------------------------------------------------------
// PATTERN 2 : StateProvider -> Provider avec Notifier
// ---------------------------------------------------------------------------
//
// AVANT (Riverpod 2.x):
//
//   final filterProvider = StateProvider<String>((ref) => 'all');
//
//   // Usage: ref.read(filterProvider.notifier).state = 'active';
//
// APRES (Riverpod 3.x):
//
//   @riverpod
//   class Filter extends _$Filter {
//     @override
//     String build() => 'all';
//     void set(String value) => state = value;
//   }
//
// NOTES:
//   - StateProvider est deprecie dans Riverpod 3.
//   - Remplacer par un Notifier simple avec build() + setter explicite.
//   - Plus lisible et testable qu'un StateProvider nu.

// ---------------------------------------------------------------------------
// PATTERN 3 : FutureProvider (inchange)
// ---------------------------------------------------------------------------
//
// AVANT (Riverpod 2.x):
//
//   final userProvider = FutureProvider<User>((ref) async {
//     final repo = ref.watch(userRepoProvider);
//     return repo.fetchUser();
//   });
//
// APRES (Riverpod 3.x):
//
//   @riverpod
//   Future<User> user(Ref ref) async {
//     final repo = ref.watch(userRepoProvider);
//     return repo.fetchUser();
//   }
//
// NOTES:
//   - FutureProvider reste supporte dans Riverpod 3.
//   - La syntaxe code-gen avec @riverpod est recommandee mais pas
//     obligatoire pour les providers simples sans mutation.
//   - Le type de retour Future<T> suffit pour generer un FutureProvider.

// ---------------------------------------------------------------------------
// PATTERN 4 : StreamProvider (inchange)
// ---------------------------------------------------------------------------
//
// AVANT (Riverpod 2.x):
//
//   final positionStreamProvider = StreamProvider<Position>((ref) {
//     return Geolocator.getPositionStream();
//   });
//
// APRES (Riverpod 3.x):
//
//   @riverpod
//   Stream<Position> positionStream(Ref ref) {
//     return Geolocator.getPositionStream();
//   }
//
// NOTES:
//   - StreamProvider reste supporte dans Riverpod 3.
//   - La syntaxe code-gen avec @riverpod est recommandee.
//   - Le type de retour Stream<T> suffit pour generer un StreamProvider.

// ---------------------------------------------------------------------------
// PATTERN 5 : ref.watch select() obligatoire dans build()
// ---------------------------------------------------------------------------
//
// AVANT (Riverpod 2.x):
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final user = ref.watch(userProvider);
//     // Rebuild a chaque changement de user, meme si on n'utilise que le nom
//     return Text(user.name);
//   }
//
// APRES (Riverpod 3.x):
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final name = ref.watch(userProvider.select((u) => u.name));
//     // Rebuild UNIQUEMENT quand le nom change
//     return Text(name);
//   }
//
// NOTES:
//   - select() existait deja en 2.x mais est desormais la bonne pratique
//     obligatoire dans build() pour eviter les rebuilds inutiles.
//   - Chaque ref.watch dans build() DOIT utiliser select() sauf si
//     l'integralite de l'etat est necessaire.
//   - Gain de performance significatif sur les ecrans avec beaucoup
//     de providers (carte, liste d'etapes).

// ---------------------------------------------------------------------------
// PATTERN 6 : family avec Record (Dart 3)
// ---------------------------------------------------------------------------
//
// AVANT (Riverpod 2.x):
//
//   final stageProvider = FutureProvider.family<Stage, String>((ref, id) {
//     return ref.watch(dbProvider).getStage(id);
//   });
//
//   // Plusieurs parametres = passer un objet ou un Map
//   final trackProvider = FutureProvider.family<Track, Map<String, dynamic>>(
//     (ref, params) {
//       final trailId = params['trailId'] as String;
//       final zoom = params['zoom'] as int;
//       return ref.watch(trackRepoProvider).get(trailId, zoom);
//     },
//   );
//
// APRES (Riverpod 3.x):
//
//   @riverpod
//   Future<Stage> stage(Ref ref, String id) async {
//     return ref.watch(dbProvider).getStage(id);
//   }
//
//   // Plusieurs parametres = Record Dart 3 (genere automatiquement)
//   @riverpod
//   Future<Track> track(
//     Ref ref, {
//     required String trailId,
//     required int zoom,
//   }) async {
//     return ref.watch(trackRepoProvider).get(trailId, zoom);
//   }
//
// NOTES:
//   - Riverpod 3 + code-gen gere les parametres multiples nativement
//     via les Records Dart 3 (pas de Map ni d'objet wrapper).
//   - Les named parameters sont recommandes pour la lisibilite.
//   - Le code genere cree automatiquement le family avec hashCode/==.

// ---------------------------------------------------------------------------
// PATTERN 7 : AsyncValue.when() pour loading/error/data
// ---------------------------------------------------------------------------
//
// AVANT (Riverpod 2.x):
//
//   final asyncData = ref.watch(someProvider);
//   if (asyncData is AsyncLoading) return CircularProgressIndicator();
//   if (asyncData is AsyncError) return Text('Erreur: ${asyncData.error}');
//   final data = asyncData.value!;
//   return DataWidget(data: data);
//
// APRES (Riverpod 3.x):
//
//   final asyncData = ref.watch(someProvider);
//   return asyncData.when(
//     loading: () => const CircularProgressIndicator(),
//     error: (error, stack) => ErrorView(
//       message: error.toString(),
//       onRetry: () => ref.invalidate(someProvider),
//     ),
//     data: (data) => DataWidget(data: data),
//   );
//
// NOTES:
//   - AsyncValue.when() est le pattern recommande depuis Riverpod 2.x
//     et reste inchange en 3.x.
//   - TOUJOURS utiliser when() plutot que des checks manuels de type.
//   - Utiliser ref.invalidate() pour le retry (pas ref.refresh()).
//   - skipLoadingOnRefresh et skipLoadingOnReload controlent le
//     comportement du loading lors des rafraichissements.
//   - Combiner avec ErrorView (lib/core/ui/error_view.dart) pour un
//     affichage homogene des erreurs dans toute l'app.
