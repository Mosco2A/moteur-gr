# Architecture globale — Moteur GR

> Dernière mise à jour : 27/05/2026 — Athéna

## Présentation

Le Moteur GR est un moteur générique Flutter multi-sentiers. Il transforme n'importe quel sentier de grande randonnée en application mobile complète : carte, navigation GPS, planning, POIs, offline-first. Indépendant de tout sentier spécifique. Premier client : Mare à Mare (Corse).

## Couches architecturales

```
+---------------------------------------------+
|                    UI                        |
|  features/*/presentation/ + widgets/         |
+---------------------------------------------+
|               PROVIDERS                      |
|  features/*/providers/ (Riverpod 3)          |
|  core/providers/ core/engine/                |
+---------------------------------------------+
|               SERVICES                       |
|  core/services/ (sync, download, manifest)   |
|  features/*/domain/ features/*/data/         |
+---------------------------------------------+
|                DATA                          |
|  Drift (SQLite) — core/data/                 |
|  Firebase (Firestore/Auth/Storage)           |
|  Open-Meteo API                              |
+---------------------------------------------+
```

Flux : UI -> Providers -> Services -> Data. Jamais de saut de couche.

## Modules fonctionnels (11)

| Module | Dossier principal | Rôle |
|---|---|---|
| Catalogue | `features/trail/` | Parcourir, rechercher, filtrer les sentiers disponibles |
| Démo | `features/trail/` | Aperçu gratuit d'un sentier sans téléchargement |
| Téléchargement | `core/services/`, `features/trail/` | Télécharger le pack complet (données + MBTiles) |
| Navigation | `features/map/`, `core/geo/`, `core/engine/` | Carte, tracé GPX, GPS, détection d'étapes, POIs |
| Planning | `features/planning/` | Répartition étapes/jours, calcul Munter |
| Journal | `features/journal/` | Notes et photos de trek |
| Météo | `features/weather/` | Prévisions Open-Meteo 7 jours, alertes |
| Sync + Auth | `core/services/`, `features/auth/` | Authentification anonyme/Google/Apple, sync cloud |
| Analytics | `core/firebase/` | Firebase Analytics, Crashlytics |
| Monétisation | (réservé — champ `isPurchased`) | Modèle gratuit + premium, achat unique par sentier |
| Groupe | `features/group/` | Localisation partagée entre trekkeurs |

## Principes fondateurs

1. **Offline-first** — Tout fonctionne sans réseau. Drift (SQLite) est la source de vérité locale. Firebase est le miroir cloud.
2. **Multi-sentier** — Le moteur ne connaît pas les sentiers. Ils sont injectés via `TrailConfig` dérivé de `activeTrailProvider`.
3. **Indépendance GR20** — Jamais de référence au GR20 dans le code. Le GR20 est un client potentiel, pas le moteur.
4. **1 étape = 1 commit = 1 push** — Chaque étape de dev produit un commit atomique poussé immédiatement.

## Flux de données principal

```
Firestore --> trail_download_service --> Drift (tables locales)
                                              |
                                              v
                                     trailConfigProvider
                                              |
                                              v
                              +---------------+---------------+
                              |               |               |
                           carte           planning        journal
                           (map)          (planning)       (journal)
```

La sync fonctionne en mode **last-write-wins** par batch de 20 via `sync_queue`.

## Stack technique

- Flutter/Dart >= 3.10
- Riverpod 3 (providers manuels, pas de code generation)
- Drift (SQLite) — 14 tables, migrations v1 à v10
- Freezed — modèles immutables
- Slang — i18n 5 langues (fr, en, de, it, es)
- GoRouter 13 — routing déclaratif
- flutter_map + MBTiles — cartes offline
- Melos — monorepo tooling
- Firebase (Auth, Firestore, Storage, Analytics, Crashlytics)
- Open-Meteo — API météo gratuite

## Dépendances entre modules

```
catalogue --> démo
catalogue --> téléchargement --> navigation
navigation --> planning
navigation --> journal
navigation --> météo
sync+auth --> tous (transversal)
analytics --> tous (transversal)
groupe --> navigation + sync
```

## Migrations Drift

| Version | Phase | Tables/colonnes ajoutées |
|---|---|---|
| v1 | P1 | stages, pois, user_progress |
| v2 | P2 | user_progress.totalTimeMinutes |
| v3 | P3 | journal_entries |
| v4 | P3 | checklist_items |
| v5 | P3 | weather_cache |
| v6 | P3 | feedback_queue |
| v7 | P4 | trail_manifests |
| v8 | P4 | sync_queue |
| v9 | P5 | installed_trails (26 colonnes) |
| v10 | P5 | trail_meta +25 colonnes i18n/stats, réconciliation |
