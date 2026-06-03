# Module Navigation

> Carte, tracé GPX, GPS, détection d'étapes, POIs.

## Description

Le module navigation est le coeur du Moteur GR. Il affiche la carte avec la trace du sentier, gère la géolocalisation GPS en temps réel, détecte automatiquement les changements d'étape, et affiche les points d'intérêt (POIs) sur la carte. Tout fonctionne en mode offline grâce aux tuiles MBTiles.

## Architecture

```
core/
  engine/trail_engine.dart              -- TrailEngine, trailConfigProvider
  geo/
    gpx_parser.dart                     -- Parser GPX
    douglas_peucker.dart                -- Simplification trace
    stage_detector.dart                 -- Détection étape (200m, debounce 30s)
    geo_utils.dart                      -- Calculs géo (distance, bearing)
    track_point.dart                    -- Modèle Freezed point GPS
    track_projection.dart               -- Projection sur la trace
  map/
    mbtiles_manager.dart                -- Gestion MBTiles offline
    offline_tile_provider.dart          -- Provider tuiles offline
features/map/
  presentation/trail_map_screen.dart    -- Écran carte principal
  providers/
    gpx_track_provider.dart             -- Trace GPX chargée
    location_provider.dart              -- Position GPS courante
    map_pois_provider.dart              -- POIs filtrés
    offline_map_provider.dart           -- État MBTiles
    simplified_track_provider.dart      -- Trace simplifiée (Douglas-Peucker)
    track_position_provider.dart        -- Position sur la trace
  widgets/
    poi_marker.dart                     -- Marqueur POI sur la carte
    poi_popup.dart                      -- Popup détail POI
    poi_filter_bar.dart                 -- Barre filtres POI
    trail_polyline.dart                 -- Polyline trace sentier
    user_position_marker.dart           -- Marqueur position utilisateur
    stage_progress_bar.dart             -- Barre progression étape
    offline_map_badge.dart              -- Badge mode offline
```

## Flux utilisateur

1. L'utilisateur ouvre un sentier installé -> `/trail/:id`
2. La carte s'affiche avec la trace complète du sentier
3. Les POIs apparaissent comme marqueurs typés (refuge, eau, commerce...)
4. Le GPS se lance et affiche la position en temps réel
5. Le `StageDetector` détecte l'étape courante (rayon 200m, debounce 30s)
6. La progression s'affiche dans la barre d'étape

## Fichiers concernés

| Fichier | Rôle |
|---|---|
| `trail_engine.dart` | TrailEngine, `trailConfigProvider` dérivé de `activeTrailProvider` |
| `trail_map_screen.dart` | Écran carte principal avec flutter_map |
| `gpx_parser.dart` | Parse les fichiers GPX en liste de `TrackPoint` |
| `stage_detector.dart` | Détection changement d'étape par proximité GPS |
| `mbtiles_manager.dart` | Chargement et gestion des tuiles offline |

## API / Providers

- `trailConfigProvider` -- dérivé de `activeTrailProvider`, fournit le `TrailConfig` du sentier actif
- `gpxTrackProvider` -- trace GPX complète du sentier actif
- `locationProvider` -- position GPS courante (stream geolocator)
- `mapPoisProvider` -- POIs filtrés par type et zone visible
- `offlineMapProvider` -- état des tuiles MBTiles (disponible/téléchargé/manquant)
- `simplifiedTrackProvider` -- trace simplifiée par Douglas-Peucker pour le rendu carte
- `trackPositionProvider` -- position projetée sur la trace + distance parcourue

### Modes d'utilisation

- **Mode live** -- GPS actif, position en temps réel, détection étapes
- **Mode consultation** -- GPS inactif, navigation libre sur la carte

## Pièges connus

- **Snap-to-trace** -- La position GPS doit être projetée sur la trace la plus proche (pas affichée brute). Seuil de projection : 200m max.
- **Debounce détection étape** -- 30 secondes minimum entre deux détections pour éviter les faux positifs (randonneur qui hésite au départ d'une étape).
- **MBTiles absent** -- Si le fichier MBTiles n'est pas téléchargé, afficher un fond gris avec message "Carte offline non disponible". Ne pas crasher.
- **Batterie** -- Le GPS consomme beaucoup. Proposer un mode éco (actualisation toutes les 30s au lieu de continue).
- **Refactoring trailConfigProvider** -- CRITIQUE. Tous les modules lisent `trailConfigProvider`. Le refactoring vers `activeTrailProvider` doit être progressif (coexistence puis migration).
