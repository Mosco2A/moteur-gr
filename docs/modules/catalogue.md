# Module Catalogue

> Parcourir, rechercher et filtrer les sentiers disponibles.

## Description

Le catalogue est le point d'entrée de l'application. Il affiche tous les sentiers disponibles (depuis Firestore) et les sentiers déjà installés localement. L'utilisateur peut parcourir les fiches, filtrer par difficulté, rechercher par nom, et accéder soit au mode démo soit au téléchargement.

## Architecture

```
features/trail/
  presentation/
    trail_catalog_screen.dart    <-- écran principal du catalogue
    trail_list_screen.dart       <-- liste des sentiers installés
  providers/
    catalog_provider.dart        <-- CatalogNotifier (AsyncNotifier)
    download_provider.dart       <-- gestion téléchargement
  widgets/
    trail_catalog_card.dart      <-- carte sentier avec cover 16:9
    difficulty_badge.dart        <-- badge difficulté coloré
```

## Flux utilisateur

1. L'utilisateur arrive sur `/catalog`
2. Le `CatalogNotifier` charge la liste depuis Firestore (ou cache local)
3. Affichage en deux sections : **Mes sentiers** (installés) et **Disponibles**
4. Chips de filtrage : Tous / Facile / Modéré / Difficile / Expert
5. Barre de recherche par nom (filtre local)
6. Tap sur un sentier installé -> ouvre le sentier
7. Tap sur un sentier disponible -> écran démo ou téléchargement

## Fichiers concernés

| Fichier | Rôle |
|---|---|
| `trail_catalog_screen.dart` | Écran principal, sections, recherche, filtres |
| `catalog_provider.dart` | `CatalogNotifier` AsyncNotifier, fetch Firestore, cache |
| `trail_catalog_card.dart` | Card avec cover 16:9, summary i18n, stats, badge |
| `difficulty_badge.dart` | Badge coloré selon la difficulté |

## API / Providers

- `catalogProvider` — `AsyncNotifier<List<CatalogEntry>>` — liste complète des sentiers
- `installedTrailsProvider` — `AsyncNotifier<List<InstalledTrail>>` — sentiers installés localement
- `activeTrailProvider` — `Notifier<String?>` — ID du sentier actif

### Modèle CatalogEntry (champs enrichis)

- Noms i18n : `nameFr`, `nameEn`, `nameDe`, `nameIt`, `nameEs`
- Résumés i18n : `summaryFr` à `summaryEs` (2-3 lignes accroche)
- Descriptions i18n : `descriptionFr` à `descriptionEs` (fiche détaillée)
- Stats : `totalDistanceKm`, `totalElevationGain`, `estimatedDays`, `stagesCount`
- Métadonnées : `coverImageUrl`, `region`, `country`, `difficulty`
- Drapeaux : `demoAvailable` (défaut true), `isPurchased` (réservé monétisation)

## Pièges connus

- **Performance images** — Les covers 16:9 peuvent ralentir le scroll si 20+ sentiers. Utiliser `CachedNetworkImage` avec placeholder. Thumbnail pré-calculé côté serveur (400x225px max).
- **Pagination** — Pagination lazy à prévoir dès 20 items.
- **i18n fallback** — Si le résumé dans la langue courante est null, fallback sur le français, puis l'anglais.
- **Offline** — Le catalogue doit fonctionner offline (cache local des métadonnées). Seules les images peuvent manquer.
