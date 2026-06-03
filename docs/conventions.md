# Conventions, contribution et changelog

> Règles de développement et guide du contributeur.

## Conventions de nommage

| Type | Convention | Exemple |
|---|---|---|
| Fichiers Dart | snake_case | `trail_catalog_screen.dart` |
| Classes | PascalCase | `TrailCatalogScreen` |
| Variables/fonctions | camelCase | `trailConfigProvider` |
| Tables Drift | snake_case | `installed_trails` |
| Colonnes Drift | camelCase | `totalDistanceKm` |
| Routes GoRouter | kebab-case | `/catalog/demo/:id` |
| Clés i18n | camelCase | `trailCatalog.title` |

## Structure des dossiers

```
lib/
  core/                     -- Socle technique partagé
    config/                 -- TrailConfig, TestTrailConfig
    constants/              -- Constantes globales
    data/                   -- Drift (database, tables, DAOs, seed)
    engine/                 -- TrailEngine
    firebase/               -- Firebase service
    geo/                    -- GPX, géo, projection
    map/                    -- MBTiles, tuiles offline
    models/                 -- Modèles Freezed partagés
    network/                -- Connectivité
    providers/              -- Providers globaux
    routing/                -- GoRouter
    services/               -- Services métier (sync, download)
    theme/                  -- Thème Material
  features/                 -- Modules fonctionnels
    auth/                   -- Authentification
    checklist/              -- Checklist matériel
    diploma/                -- Diplôme fin de trek
    feasibility/            -- Questionnaire faisabilité
    feedback/               -- Feedback in-app
    group/                  -- Localisation partagée
    journal/                -- Journal de trek
    map/                    -- Carte et navigation
    notifications/          -- Notifications locales
    planning/               -- Planning jours/étapes
    settings/               -- Paramètres
    share/                  -- Share cards
    tips/                   -- Fiches conseils
    tracking/               -- Enregistrement rando
    trail/                  -- Catalogue, démo, sentiers
    weather/                -- Météo
  shared/                   -- Widgets partagés
    widgets/                -- AppButton, AppCard, EmptyState...
```

## Règles obligatoires

1. **Freezed obligatoire** -- Tout modèle de données utilise `@freezed`. Pas de classes mutables.
2. **Couverture 80%%** -- Chaque module doit avoir au minimum 80%% de couverture de tests.
3. **1 étape = 1 commit = 1 push** -- Chaque étape de développement produit un commit atomique poussé immédiatement sur la branche.
4. **i18n 5 langues** -- Français, anglais, allemand, italien, espagnol. Via Slang.
5. **Code en anglais** -- Noms de classes, variables, fonctions en anglais. Commentaires en français.
6. **flutter analyze** -- Zéro warning avant chaque commit.
7. **Offline-first** -- Toute feature doit fonctionner sans réseau.
8. **Pas de référence GR20** -- Le moteur est générique. Jamais de mention du GR20 dans le code.

## Commandes utiles

```bash
# Lancer les tests
flutter test

# Analyser le code
flutter analyze

# Générer le code Freezed/Drift
dart run build_runner build --delete-conflicting-outputs

# Générer les traductions Slang
dart run slang

# Lancer l'app en debug
flutter run
```

## Prérequis

- Flutter >= 3.10
- Dart >= 3.0
- Android Studio ou VS Code
- Un émulateur Android ou appareil physique
- Xcode (pour iOS)

## Workflow de contribution

1. Lire le CLAUDE.md du projet
2. Lire la spec de l'étape concernée en base mémoire
3. Créer la branche `claude/feat/xxx`
4. Implémenter en suivant les conventions
5. `flutter analyze` -- zéro warning
6. `flutter test` -- tous les tests passent
7. Commit + push immédiat
8. PR vers main

## Changelog

Le changelog est géré par phase et étape :

- **Phase 0** : Setup initial (repo, stack, i18n)
- **Phase 1** : Squelette technique (Drift, Freezed, Riverpod, GoRouter)
- **Phase 2** : Le moteur (carte, navigation, GPS, planning, tracking)
- **Phase 3** : Features utilisateur (journal, checklist, météo, partage...)
- **Phase 4** : Cloud + vraies données (Firebase, Mare à Mare, sync)
- **Phase 5** : Finitions + publication (multi-sentier, stores, analytics, polish)
