# ADR-003 : Riverpod 3 plutot que BLoC pour le state management

## Statut

Accepte (historique -- l'app GR20 utilise Riverpod 2, le Moteur GR adopte Riverpod 3)

## Contexte

L'application GR20 utilise Riverpod 2 avec `riverpod_generator` pour le state management. Pour le Moteur GR, le choix du state management a ete reevalue entre BLoC (popular dans l'ecosysteme Flutter) et Riverpod 3 (evolution naturelle de la stack existante).

### Riverpod 2 -- utilisation actuelle GR20

- State management reactif base sur les providers
- Code generation via `riverpod_generator`
- Providers: `Provider`, `FutureProvider`, `StreamProvider`, `NotifierProvider`
- Pas de persistence offline native

### Riverpod 3 -- choix pour le Moteur GR

- Evolution majeure avec persistence offline native
- Retry automatique sur erreur reseau
- Meilleure integration avec `build_runner`
- API simplifiee pour les mutations

### BLoC -- alternative evaluee

- Pattern events/states explicite
- `flutter_bloc` + `bloc` packages
- Populaire dans les projets enterprise
- Separation stricte logique/presentation

## Decision

**Adopter Riverpod 3 pour le Moteur GR** pour sa persistence offline native, sa concision et la continuite avec la stack GR20 existante.

## Raisons

### 1. Persistence offline native

Riverpod 3 integre nativement la persistence des providers, critique pour une app de randonnee utilisee sans reseau :

```dart
@riverpod
class StagesNotifier extends _$StagesNotifier {
  @override
  Future<List<Stage>> build() async {
    // Riverpod 3 : le cache persiste automatiquement entre les sessions
    // Pas besoin de gerer manuellement Hive/SharedPreferences
    return await ref.watch(stageRepositoryProvider).fetchStages();
  }
}
```

Avec BLoC, la persistence offline necessite un Hydrated BLoC ou une couche de cache manuelle supplementaire.

### 2. Retry automatique

Riverpod 3 propose un mecanisme de retry natif pour les providers qui echouent (reseau indisponible) :

```dart
@riverpod
Future<WeatherData> weather(WeatherRef ref) async {
  // Riverpod 3 : retry automatique avec backoff exponentiel
  // quand le reseau revient
  return await ref.watch(weatherServiceProvider).fetchForecast();
}
```

BLoC necessite d'implementer manuellement la logique de retry dans chaque Bloc ou via un middleware.

### 3. Moins de boilerplate

Comparaison directe pour un cas d'utilisation typique (charger et afficher les etapes) :

**Riverpod 3** (avec code generation) :
```dart
// Provider -- 5 lignes
@riverpod
Future<List<Stage>> stages(StagesRef ref) async {
  final repo = ref.watch(stageRepositoryProvider);
  return await repo.fetchStages();
}

// Widget -- lecture directe
final stages = ref.watch(stagesProvider);
return stages.when(
  data: (data) => StageList(stages: data),
  loading: () => const LoadingIndicator(),
  error: (err, _) => ErrorDisplay(error: err),
);
```

**BLoC** (equivalent) :
```dart
// Events
abstract class StagesEvent {}
class LoadStages extends StagesEvent {}

// States
abstract class StagesState {}
class StagesLoading extends StagesState {}
class StagesLoaded extends StagesState {
  final List<Stage> stages;
  StagesLoaded(this.stages);
}
class StagesError extends StagesState {
  final String message;
  StagesError(this.message);
}

// Bloc -- 20+ lignes
class StagesBloc extends Bloc<StagesEvent, StagesState> {
  final StageRepository repository;
  StagesBloc(this.repository) : super(StagesLoading()) {
    on<LoadStages>((event, emit) async {
      emit(StagesLoading());
      try {
        final stages = await repository.fetchStages();
        emit(StagesLoaded(stages));
      } catch (e) {
        emit(StagesError(e.toString()));
      }
    });
  }
}

// Widget -- BlocBuilder
BlocBuilder<StagesBloc, StagesState>(
  builder: (context, state) {
    if (state is StagesLoaded) return StageList(stages: state.stages);
    if (state is StagesError) return ErrorDisplay(error: state.message);
    return const LoadingIndicator();
  },
);
```

### 4. Testabilite

Riverpod facilite le testing via `ProviderContainer` et les overrides :

```dart
test('stages provider returns data', () async {
  final container = ProviderContainer(
    overrides: [
      stageRepositoryProvider.overrideWithValue(MockStageRepository()),
    ],
  );
  final stages = await container.read(stagesProvider.future);
  expect(stages, hasLength(16));
});
```

BLoC est testable aussi (via `blocTest`), mais necessite plus de setup et la creation explicite des events.

### 5. Continuite de la stack

L'equipe connait deja Riverpod 2 (utilise dans le GR20). Passer a Riverpod 3 est une evolution naturelle, pas un changement de paradigme. Adopter BLoC necessiterait de reapprendre un pattern completement different et de maintenir deux approches de state management dans l'ecosysteme.

## Alternatives evaluees

### BLoC

**Pour** : separation stricte events/states, bien documente, large communaute.
**Contre** : verbose (events + states + bloc pour chaque feature), pas de persistence native, pas de retry natif, changement de paradigme pour l'equipe.

### GetX

Ecarte immediatement : trop magique, anti-patterns courants, pas adapte aux projets maintenables a long terme.

### Provider (vanilla)

Ecarte : predecessor de Riverpod, moins de fonctionnalites, migration vers Riverpod deja faite.

## Consequences

- Le Moteur GR utilise Riverpod 3 exclusivement
- L'app GR20 reste sur Riverpod 2 (migration possible mais non prioritaire)
- Tous les providers utilisent `riverpod_generator` (pas de providers manuels)
- La persistence offline est geree nativement par Riverpod 3
- Le retry reseau est automatique pour tous les providers async
- Les tests utilisent `ProviderContainer` avec overrides
