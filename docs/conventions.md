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
  domain/                   -- Modèles et règles lus par PLUSIEURS features
                               (Stage, TrackPoint, TrekSession, PlannedDay...)
                               Voie A, décision de Christophe du 02/10/2026.
                               Ne dépend d'aucune feature. AU-DESSUS de core/
                               et de shared/ : le métier lit le socle, jamais
                               l'inverse (ARB-645-05-c, 03/10/2026 ; voir la
                               règle 11).
  core/                     -- Socle technique partagé
    config/                 -- TrailConfig, TestTrailConfig
    constants/              -- Constantes globales
    data/                   -- Drift (database, tables, DAOs, seed)
    engine/                 -- TrailEngine
    firebase/               -- Firebase service
    geo/                    -- GPX, géo, projection
    map/                    -- MBTiles, tuiles offline
    models/                 -- Modèles Freezed du socle (adossés à Drift) ;
                               ceux que plusieurs features lisent vivent
                               dans lib/domain/
    network/                -- Connectivité
    providers/              -- Providers globaux
    routing/                -- GoRouter. Seule exception à la règle 9 :
                               le routeur connaît les écrans de toutes
                               les features (ARB-645-05-a).
    services/               -- Services métier (sync, download)
    theme/                  -- Thème Material
  features/                 -- Modules fonctionnels
    <feature>/
      <feature>_facade.dart -- SEULE porte d'entrée de la feature pour ses
                               voisines : re-exporte (export ... show) ce
                               qu'elles ont le droit de lire. Tout le reste
                               de la feature est privé (ARB-645-05-b ;
                               voir la règle 10).
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
  shared/                   -- Partagé par plusieurs features
    poi/                    -- Vocabulaire visuel des points d'intérêt
                               (PoiTypeConfig, PoiTypeLabel) : une icône,
                               une couleur et un libellé par type
    services/               -- Services partagés
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
9. **Le socle ne remonte jamais vers une feature** -- Un fichier de `core/`, `shared/` ou `domain/` n'importe pas depuis `lib/features/`. **Une seule exception, décision ARB-645-05-a du 03/10/2026 : `lib/core/routing/app_router.dart` a le droit d'importer les écrans de toutes les features, parce qu'un routeur connaît tous les écrans par construction.** Il est à ce titre exclu du comptage de la garde `test/structurel/couches_respectees_645_test.dart` ; tout autre fichier du socle y reste compté.
10. **Une feature ne lit une autre feature que par sa façade** -- Toute feature lue par ses voisines expose UN fichier unique, `lib/features/<feature>/<feature>_facade.dart`, qui re-exporte explicitement (`export ... show`) les seuls symboles que les autres ont le droit de lire ; tout le reste — `providers/`, `data/`, `domain/`, `presentation/` — est privé. Un import qui vise l'intérieur d'une voisine soude la paire et promeut un détail d'implémentation au rang d'interface : on ne touche plus à l'une sans ouvrir l'autre. **Décision ARB-645-05-b du 03/10/2026** ; la garde `test/structurel/couches_respectees_645_test.dart` compte ces imports, et vérifie du même geste qu'une façade ne re-exporte QUE sa propre feature — sans quoi la porte blanchirait les croisements qu'elle existe pour rendre visibles.
11. **Le socle ne connaît pas le métier** -- `lib/domain/` est AU-DESSUS de `core/` et de `shared/` : le métier a le droit de lire le socle, le socle ne remonte jamais vers le métier. Un fichier de `core/` ou de `shared/` qui importe `lib/domain/` ferme un cycle que rien ne mesurait jusqu'au 03/10/2026, parce que l'audit rangeait `core`, `shared` et `domain` dans un seul sac appelé « le socle ». **Décision ARB-645-05-c du 03/10/2026** ; ce plafond est à **zéro** et non à un nombre toléré : ce qui n'est pas du métier DESCEND dans le socle (le seuil de bruit de l'altimètre est parti dans `GeoUtils`), ce qui en est MONTE dans `lib/domain/` (la politique de minimisation RGPD, le mapping Drift des sessions de trek).
12. **Pas de `part` hors code généré** -- Une bibliothèque = un fichier avec ses propres imports. `part` et `part of` sont réservés au code généré (`.g.dart`, `.freezed.dart`) ; aucun fichier écrit à la main ne se scinde en morceaux qui partagent leurs membres privés. Un fichier trop long se découpe en vraies bibliothèques : un symbole privé lu par un seul fichier reste privé dans ce fichier ; lu par plusieurs fichiers de la même feature, il devient public dans un fichier de la feature (la façade de la règle 10 ne le ré-exporte pas) ; un widget privé devient une classe nommée qui reçoit ses données et ses callbacks en paramètres nommés. **Décision de Christophe du 03/10/2026** (« Moi je veux que se soit propre et aux normes »), qui refuse la convention des fichiers `part` introduite par le lot 645-06 (vague 2) ; la garde `test/structurel/pas_de_part_645_test.dart` exige ZÉRO `part` ou `part of` écrit à la main dans `lib/`, `test/`, `tool/` et `integration_test/`.

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
