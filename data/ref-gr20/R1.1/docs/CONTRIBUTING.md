# Contribuer au projet Fra li Monti (GR20)

## Conventions de code

### Langage

- Code source : **anglais** (noms de classes, variables, fonctions)
- Commentaires : **francais** (descriptions, TODOs, documentation inline)
- Messages de commit : **anglais** (conventional commits)

### Analyse statique

Avant tout commit, le code doit passer `flutter analyze` sans warning ni erreur :

```bash
flutter analyze
```

Les regles d'analyse sont definies dans `analysis_options.yaml` a la racine du projet.

### Formatage

Le formatage Dart standard est utilise :

```bash
dart format lib/ test/
```

Largeur de ligne par defaut : 80 caracteres.

### Imports

Ordre des imports (convention Dart) :
1. `dart:` (SDK)
2. `package:flutter/` (framework)
3. `package:` (dependances tierces)
4. Imports relatifs du projet (preferer les imports relatifs dans le meme package)

### Providers Riverpod

**OBLIGATION** : utiliser `riverpod_generator` pour tous les providers.

```dart
// BON -- provider genere
@riverpod
Future<List<Stage>> stages(StagesRef ref) async {
  // ...
}

// MAUVAIS -- provider manuel
final stagesProvider = FutureProvider<List<Stage>>((ref) async {
  // ...
});
```

Apres ajout ou modification d'un provider, regenerer le code :
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Modeles Freezed

Tous les modeles de donnees utilisent `freezed` + `json_serializable` :

```dart
@freezed
class Stage with _$Stage {
  const factory Stage({
    required String id,
    required String name,
    required double distance,
    required int elevationGain,
  }) = _Stage;

  factory Stage.fromJson(Map<String, dynamic> json) => _$StageFromJson(json);
}
```

### Firebase Firestore

Pattern obligatoire pour les snapshots temps reel (prevention donnees fantomes) :

```dart
collection
    .snapshots(includeMetadataChanges: true)
    .where((snapshot) => !snapshot.metadata.isFromCache)
    .map((snapshot) => snapshot.docs.map((doc) => Model.fromJson(doc.data())).toList());
```

## Conventional Commits

Tous les messages de commit suivent la convention [Conventional Commits](https://www.conventionalcommits.org/) :

### Format

```
<type>(<scope>): <description courte>

<corps optionnel>
```

### Types

| Type | Utilisation |
|---|---|
| `feat` | Nouvelle fonctionnalite |
| `fix` | Correction de bug |
| `chore` | Maintenance, dependances, config |
| `refactor` | Refactoring sans changement fonctionnel |
| `test` | Ajout ou modification de tests |
| `docs` | Documentation |
| `style` | Formatage, pas de changement logique |
| `perf` | Amelioration de performance |
| `ci` | CI/CD (Codemagic, GitHub Actions) |

### Scopes courants

`auth`, `planning`, `trek`, `group`, `poi`, `after`, `settings`, `core`, `shared`, `map`, `firebase`

### Exemples

```
feat(trek): add real-time GPS tracking with background service
fix(auth): prevent ghost user documents for anonymous sessions
chore(deps): bump flutter_map to ^6.1.0
refactor(planning): extract stage calculation to dedicated service
test(trek): add unit tests for GPX parser
docs(readme): update architecture section
```

## Workflow de branche

### Convention de nommage

```
claude/<type>/<description-courte>
```

Exemples :
- `claude/feat/gps-background-tracking`
- `claude/fix/267-anti-fantomes-users`
- `claude/chore/bump-dependencies`

### Regles

- **1 branche = 1 tache** : chaque branche correspond a une seule US ou fix
- **Jamais de push direct sur `main`** : toujours passer par une PR
- **Branche a jour** : rebase sur `main` avant de merger
- **Branche ephemere** : supprimer apres merge

## Pull Requests

### Contenu obligatoire

1. **Titre** : suit le format conventional commit (`feat(scope): description`)
2. **Description** : contexte, ce qui change, pourquoi
3. **Tests** : quels tests ajoutees ou modifies
4. **Screenshots** : si changement UI

### Checklist avant PR

- [ ] `flutter analyze` -- zero warning
- [ ] `flutter test` -- tous les tests passent
- [ ] Code generation a jour (`dart run build_runner build`)
- [ ] Pas de `print()` ou `debugPrint()` residuels
- [ ] Pas de TODO non documente
- [ ] Traductions ARB a jour si texte modifie
- [ ] Pas de donnees sensibles (cles API, tokens) dans le code

### Gates de livraison (DEC-041)

Toute livraison passe par 3 gates obligatoires :
1. **Gate 1 -- QA** : `flutter analyze` + tests unitaires + tests d'integration
2. **Gate 2 -- Conformite** : respect du process + rapport de livraison
3. **Gate 3 -- Build** : build release Android (AAB) + iOS (IPA), uniquement apres Gate 1+2 PASS

## Tests

### Organisation

```
test/
  core/                    # Tests des utilitaires, constantes, routing
  features/
    auth/                  # Tests auth providers et services
    planning/              # Tests planification
    trek/                  # Tests GPS, GPX parser, trek service
    ...
  widget_test.dart         # Test du widget racine
```

### Types de tests

| Type | Outil | Cible |
|---|---|---|
| Unitaire | `flutter_test` + `mocktail` | Providers, services, modeles |
| Widget | `flutter_test` | Ecrans, widgets isoles |
| Integration | `patrol` | Flux complets (auth -> navigation -> journal) |

### Commandes

```bash
# Tous les tests
flutter test

# Un fichier specifique
flutter test test/features/trek/gpx_parser_test.dart

# Avec couverture
flutter test --coverage
```

### Pattern de test

```dart
void main() {
  group('GpxParser', () {
    test('should parse trackpoints with elevation', () {
      final parser = GpxParser();
      final points = parser.parse(sampleGpxContent);
      expect(points, isNotEmpty);
      expect(points.first.elevation, isNotNull);
    });

    test('should handle missing elevation gracefully', () {
      final parser = GpxParser();
      final points = parser.parse(gpxWithoutElevation);
      expect(points.first.elevation, equals(0));
    });
  });
}
```
