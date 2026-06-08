# Contribuer a StepWays (moteur_gr)

## Conventions de code

### Langage

- Code source : **anglais** (classes, variables, fonctions).
- Commentaires : **francais** (descriptions, TODOs, doc inline).
- Messages de commit : **anglais ou francais court** au format Conventional
  Commits (voir plus bas).

### Analyse statique

Le code doit passer `flutter analyze` **sans warning ni erreur** avant tout
commit. Les regles sont dans `analysis_options.yaml` a la racine.

```bash
flutter analyze
```

### Formatage

```bash
dart format lib/ test/
```

### Ordre des imports

1. `dart:` (SDK) ;
2. `package:flutter/` ;
3. `package:` (dependances tierces) ;
4. imports relatifs du projet.

### Providers Riverpod — **manuels**

Le projet utilise **Riverpod 2.6** avec des providers **declares a la main**.
Il n'y a **pas** de `riverpod_generator` / `@riverpod` : aucune generation de
code pour les providers.

```dart
// BON — provider manuel
final stagesProvider =
    FutureProvider.family<List<StageModel>, String>((ref, trailId) async {
  final repo = ref.watch(stageRepositoryProvider);
  return repo.fetchStages(trailId);
});

// Etat mutable : NotifierProvider / AsyncNotifierProvider
final catalogStateProvider =
    AsyncNotifierProvider<CatalogNotifier, CatalogState>(CatalogNotifier.new);

// A NE PAS FAIRE : pas d'annotation @riverpod (pas de generator dans ce projet)
```

### Modeles Freezed

Les modeles de donnees utilisent **Freezed 3.x** + `json_serializable`. Apres
ajout/modif d'un modele, regenerer :

```bash
dart run build_runner build --delete-conflicting-outputs
```

### i18n Slang — `dart run slang`

Zero texte en dur destine a l'utilisateur : tout passe par Slang
(`t.<namespace>.<cle>`). Sources = 1 JSON par langue dans `assets/i18n/`
(`fr.i18n.json` base + `en/de/it/es`). Toute nouvelle cle doit exister dans
**les 5 langues**. Regeneration :

```bash
dart run slang   # PAS build_runner — slang_build_runner est desactive (build.yaml)
```

### Firebase optionnel

Le moteur tourne sans backend si `TrailConfig.firebaseProjectId` est `null`.
Toujours verifier `FirebaseService.isAvailable` avant un acces cloud, et
prevoir l'etat degrade (`CloudUnavailableNotice`).

### Accessibilite

Cibler WCAG AA (contraste texte >= 4.5:1). Utiliser `WcagContrast`
(`lib/core/a11y/`) pour valider, `grisTexteSecondaire` sur fond sombre et
`grisGranite` sur fond clair. Ajouter les `Semantics` / labels Slang sur les
controles importants.

## Conventional Commits

Format :

```
<type>(<scope>): <description courte>

<corps optionnel>
```

Types utilises :

- `feat` — nouvelle fonctionnalite
- `fix` — correction de bug
- `chore` — maintenance, dependances, config
- `refactor` — refactoring sans changement fonctionnel
- `test` — ajout/modif de tests
- `docs` — documentation
- `style` — formatage
- `perf` — performance
- `ci` — CI/CD (Codemagic)

Scopes courants : `auth`, `planning`, `trek`, `trail`, `group`, `poi`,
`weather`, `journal`, `diploma`, `share`, `safety`, `tracking`, `core`,
`shared`, `map`, `theme`, `firebase`, `i18n`, ou un identifiant d'etape
(ex: `E5.5`).

Exemples :

```
feat(trek): suivi GPS temps reel avec service en arriere-plan
fix(auth): zero PII pour les sessions anonymes
feat(E5.5): polish UX — Hero etape + haptics + theme clair/sombre
docs(readme): aligner la stack reelle (Riverpod 2.6, Slang CLI)
```

## Workflow de branche

### Nommage

```
claude/<type>/<description-ou-etape>
```

Exemples : `claude/feat/E5.15-sos-button`,
`claude/fix/267-anti-fantomes-users`,
`claude/feat/E5-consolidation-polish-docs-security`.

### Regles

- **1 branche = 1 tache/etape**.
- **Jamais de push direct sur `main`** : seul l'orchestrateur fusionne sur
  `main`, apres gate QA verte. Les contributeurs poussent sur leur branche.
- **Branche a jour** depuis `main` avant la fusion.
- **Commits** : identite git du **contributeur** (l'agent de dev — Vulcain
  pour StepWays), jamais l'orchestrateur.
- Pas de tag dans ce repo (aucun tag defini).

## Pull Requests / livraison

### Contenu

1. Titre au format Conventional Commit.
2. Description : contexte, ce qui change, pourquoi.
3. Tests : lesquels ajoutes/modifies.
4. Captures si changement UI.

### Checklist avant livraison

- [ ] `flutter analyze` — zero warning.
- [ ] `flutter test` — tout au vert, **aucun test supprime ni skippe**.
- [ ] Code genere a jour (`dart run build_runner build`, `dart run slang`).
- [ ] Pas de `print()` / `debugPrint()` residuel.
- [ ] Traductions Slang a jour (5 langues) si texte modifie.
- [ ] Aucune donnee sensible (cles, tokens) — `bash scripts/scan_secrets.sh`.
- [ ] Aucune marque/region/sentier en dur (hors donnees parametriques).

### Gates de livraison

Toute livraison passe par des gates obligatoires :

1. **QA** : `flutter analyze` + `flutter test` (+ tests emulateur Firestore le
   cas echeant).
2. **Conformite** : respect du process + rapport.
3. **Build** : AAB Android + IPA iOS, uniquement apres QA + conformite OK.

## Tests

### Organisation

`test/` est le miroir de `lib/` : `test/core/`, `test/features/<feature>/`,
`test/shared/`, `test/i18n/`.

### Types

- **Unitaire** — `flutter_test` : services, modeles, calculs, providers
  (via `ProviderContainer` + overrides).
- **Widget** — `flutter_test` : ecrans et widgets isoles
  (`ProviderScope(overrides: [...])` + `pumpWidget`).
- **Emulateur Firestore** — regles de securite (`firestore-tests/`).

> Le projet n'utilise pas `mocktail` ni `patrol` : on s'appuie sur
> `flutter_test`, les overrides Riverpod et des fakes/fixtures locaux.

### Commandes

```bash
# Tous les tests
flutter test

# Un fichier
flutter test test/features/trek/...

# Avec couverture
flutter test --coverage
```

### Pattern de test (widget + Riverpod)

```dart
testWidgets('affiche le detail d\'etape', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        stagesProvider('test-trail')
            .overrideWith((ref) => Future.value([testStage])),
      ],
      child: const MaterialApp(
        home: StageDetailScreen(trailId: 'test-trail', stageNumber: 1),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Premiere etape'), findsOneWidget);
});
```
