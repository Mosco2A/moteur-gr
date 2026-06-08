# ADR-003 : Riverpod (2.6) plutot que BLoC pour le state management

## Statut

Accepte. Version en production : **Riverpod 2.6** (`flutter_riverpod` ^2.6.0),
providers **manuels** (sans `riverpod_generator`).

> Un upgrade vers **Riverpod v3** est un **lot futur dedie** (decision option
> A). Cet ADR documente l'etat **reel** de `main` : Riverpod 2.6. Les
> fonctionnalites propres a la v3 (ex: persistence offline native, retry auto)
> **ne sont pas** dans le perimetre actuel et ne doivent pas etre invoquees
> comme acquises.

## Contexte

StepWays a besoin d'un state management reactif, testable et concis pour une
app offline-first riche (catalogue, carte, suivi GPS, planning, journal). Le
choix s'est porte entre **BLoC** (events/states explicites) et **Riverpod**.

### Riverpod 2.6 — option retenue

- State reactif base sur des providers composables.
- API concise : `Provider`, `FutureProvider`, `StreamProvider`,
  `NotifierProvider`, `AsyncNotifierProvider`, variantes `.family`.
- Excellente testabilite via `ProviderContainer` + overrides.
- **Providers declares a la main** : pas de `riverpod_generator` / `@riverpod`,
  donc aucune generation de code pour les providers (uniquement Freezed, Drift,
  Slang, json_serializable cote codegen).

### BLoC — option evaluee

- Pattern events/states explicite (`flutter_bloc` + `bloc`).
- Tres structure, bien documente, large communaute.
- Verbeux : events + states + bloc pour chaque feature.
- Persistence/retry a implementer soi-meme (HydratedBloc, middleware).

## Decision

**Adopter Riverpod 2.6 avec des providers manuels** comme socle de state
management de StepWays.

## Raisons

### 1. Concision

Charger et afficher des donnees est court et lisible.

**Riverpod 2.6 (provider manuel) :**
```dart
final stagesProvider =
    FutureProvider.family<List<StageModel>, String>((ref, trailId) async {
  return ref.watch(stageRepositoryProvider).fetchStages(trailId);
});

// Widget
final stages = ref.watch(stagesProvider(trailId));
return stages.when(
  data: (data) => StageList(stages: data),
  loading: () => const LoadingView(),
  error: (e, _) => ErrorView(message: '$e'),
);
```

**BLoC (equivalent) :** events + states + bloc (20+ lignes) + `BlocBuilder`.

### 2. Testabilite

```dart
final container = ProviderContainer(overrides: [
  stageRepositoryProvider.overrideWithValue(FakeStageRepository()),
]);
final stages = await container.read(stagesProvider('test-trail').future);
expect(stages, hasLength(5));
```

C'est le pattern utilise dans toute la suite de tests du projet (overrides
`ProviderScope` / `ProviderContainer`), sans librairie de mock externe.

### 3. Injection de configuration

`main.dart` injecte la config du sentier et le service Firebase via des
overrides de providers — naturel avec Riverpod :

```dart
ProviderScope(
  overrides: [
    trailConfigProvider.overrideWithValue(config),
    firebaseServiceProvider.overrideWithValue(firebaseService),
  ],
  child: const MoteurGrApp(...),
);
```

### 4. Offline gere explicitement (pas "magiquement")

En 2.6, la persistence offline n'est **pas** automatique : elle est geree
explicitement par la couche data (Drift comme source de verite locale, sync
best-effort vers Firestore quand disponible). C'est un choix assume et
testable, pas une dependance a une fonctionnalite de framework.

### 5. Continuite et faible cout cognitif

Riverpod est deja la stack de reference de l'equipe. BLoC imposerait un
changement de paradigme (events/states pour chaque feature) sans benefice net
ici.

## Pourquoi pas (encore) Riverpod v3

- L'upgrade v3 touche la generation, des APIs et le comportement (retry,
  persistence) : c'est un **lot a part entiere**, planifie separement (option
  A retenue).
- Le faire "au passage" risquerait de melanger une migration transverse avec
  des lots fonctionnels. La stack reste donc en **2.6** jusqu'a ce lot dedie.

## Alternatives ecartees

- **BLoC** : robuste mais verbeux ; pas d'avantage decisif vs Riverpod pour ce
  projet ; changement de paradigme.
- **GetX** : trop "magique", anti-patterns frequents, peu adapte au long terme.
- **Provider (vanilla)** : predecesseur de Riverpod, moins de fonctionnalites.

## Consequences

- StepWays utilise Riverpod **2.6** avec des providers **manuels**.
- Pas de `riverpod_generator` : ne pas introduire d'annotation `@riverpod`.
- Tests via `ProviderContainer` / `ProviderScope` + overrides.
- L'offline est gere par la couche data (Drift), pas par le framework de state.
- L'upgrade Riverpod v3 fera l'objet d'un lot dedie ulterieur.
