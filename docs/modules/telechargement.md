# Module Téléchargement

> Télécharger le pack complet d'un sentier (données JSON + MBTiles offline).

## Description

Le module téléchargement gère l'acquisition complète des données d'un sentier : métadonnées JSON (étapes, POIs, hébergements) et tuiles cartographiques MBTiles pour le mode offline. Il supporte la reprise après interruption, la vérification par checksum, et le delta download pour les mises à jour.

## Architecture

```
core/
  data/tables/installed_trails_table.dart   -- table Drift InstalledTrails (26 colonnes)
  data/daos/installed_trails_dao.dart       -- DAO CRUD sentiers installés
  models/download_progress.dart             -- modèle progression
  models/delta_update.dart                  -- modèle mise à jour delta
  services/trail_download_service.dart      -- service principal de téléchargement
  services/delta_update_service.dart        -- mises à jour incrémentielles
  services/manifest_service.dart            -- gestion manifests sentier
  map/mbtiles_manager.dart                  -- gestion fichiers MBTiles
features/trail/
  providers/installed_trails_provider.dart  -- InstalledTrailsNotifier (AsyncNotifier)
  providers/download_provider.dart          -- suivi progression téléchargement
  widgets/download_progress_indicator.dart  -- barre de progression
```

## Flux utilisateur

1. Depuis le catalogue ou la démo, tap sur "Télécharger"
2. Barre de progression avec taille en Mo
3. Téléchargement en arrière-plan : données JSON puis MBTiles
4. Vérification checksum à la fin
5. Création automatique d'une entrée `InstalledTrails` en base locale
6. Le sentier apparaît dans "Mes sentiers" du catalogue

## Fichiers concernés

| Fichier | Rôle |
|---|---|
| `installed_trails_table.dart` | Table Drift, 26 colonnes (PK `trailId`) |
| `installed_trails_dao.dart` | CRUD complet + contraintes unicité |
| `trail_download_service.dart` | Téléchargement avec reprise, checksum, retry 3x |
| `delta_update_service.dart` | Mise à jour incrémentielle (E4.11) |
| `download_progress_indicator.dart` | Widget barre de progression |

## API / Providers

- `installedTrailsProvider` -- `AsyncNotifier<List<InstalledTrail>>`
  - Méthodes : `loadAll()`, `install(InstalledTrail)`, `uninstall(trailId)`, `getById(id)`, `countInstalled()`, `updateLastUsed(id)`, `refreshFromDb()`
  - Invalidation : re-fetch depuis DAO après chaque mutation

### Table InstalledTrails (26 colonnes)

| Colonne | Type | Description |
|---|---|---|
| trailId | Text PK | ID unique du sentier |
| trailCode | Text unique | Code court (mare_a_mare, tmb) |
| nameFr/En/De/It/Es | Text | Noms i18n |
| summaryFr/En/De/It/Es | Text? | Résumés courts i18n |
| region | Text | Région (Corse, Alpes...) |
| country | Text | Pays |
| difficulty | Text | facile / modéré / difficile / expert |
| totalDistanceKm | Real | Distance totale en km |
| totalElevationGain | Int | D+ total en mètres |
| estimatedDays | Int | Nombre de jours estimés |
| stagesCount | Int | Nombre d'étapes |
| coverImageUrl | Text? | URL image cover |
| installedAt | Text | Date installation ISO 8601 |
| lastUsedAt | Text? | Dernière utilisation |
| diskSizeBytes | Int | Taille disque en octets |
| isActive | Bool | Sentier actuellement actif |
| installedVersion | Int | Version des données |
| isPurchased | Bool | Réservé monétisation |

## Pièges connus

- **Reprise après interruption** -- Le téléchargement doit supporter la reprise. Vérifier les chunks déjà téléchargés via checksum.
- **Retry 3x** -- En cas d'échec réseau, retenter 3 fois avec backoff exponentiel.
- **Suppression sentier actif interdite** -- Si l'utilisateur tente de supprimer le sentier actif, afficher "Basculez sur un autre sentier avant de supprimer."
- **Dernier sentier** -- Si c'est le dernier sentier installé, la suppression redirige vers `/no-data`.
- **Taille disque** -- Afficher `diskSizeBytes` sur chaque card. Chaque sentier = 10-30 Mo typiquement.
- **Migration v10** -- Les sentiers Phase 4 existants sont réconciliés automatiquement dans `installed_trails` lors de la migration v9->v10.
