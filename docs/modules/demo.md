# Module Démo

> Aperçu gratuit d'un sentier sans téléchargement.

## Description

Le mode démo permet à l'utilisateur de découvrir un sentier avant de le télécharger. Il affiche une carte avec la trace complète, un aperçu de 3 étapes et 5 POIs, ainsi que la description longue i18n. Les fonctionnalités GPS, tracking, journal, planning et diplôme sont bloquées avec un cadenas.

## Architecture

```
features/trail/
  presentation/
    trail_demo_screen.dart       <-- écran aperçu démo
  providers/
    demo_mode_provider.dart      <-- DemoModeProvider (FamilyNotifier)
```

## Flux utilisateur

1. Depuis le catalogue, tap sur "Aperçu Démo" d'un sentier disponible
2. Navigation vers `/catalog/demo/:id`
3. Le `DemoModeProvider` charge les données preview depuis `TrailMeta`
4. Affichage : carte preview + description + 3 étapes + 5 POIs
5. Bandeau bas : "Télécharger ce sentier (XX Mo)" avec bouton
6. Features bloquées affichent un cadenas + message incitatif
7. Bouton retour ou téléchargement pour quitter le mode démo

## Fichiers concernés

| Fichier | Rôle |
|---|---|
| `trail_demo_screen.dart` | Écran complet : carte, description, étapes, POIs, bandeau |
| `demo_mode_provider.dart` | `FamilyNotifier<DemoState, String>` par trailId |

## API / Providers

- `demoModeProvider(trailId)` — `FamilyNotifier<DemoState, String>`
  - `DemoState` : `isDemo`, `trailId`, `previewStages` (List, max 3), `previewPois` (List, max 5), `mapBounds`
  - Méthodes : `enterDemo(trailId)`, `exitDemo()`

### Données chargées en démo

- 3 premières étapes du sentier
- 5 premiers POIs
- Bounds de la carte (vue d'ensemble de la trace)
- Description longue i18n

### Features bloquées en mode démo

- GPS / géolocalisation
- Tracking (enregistrement de la rando)
- Journal (notes + photos)
- Planning (répartition jours)
- Diplôme fin de trek

## Pièges connus

- **Données insuffisantes** — Si `TrailMeta` n'a pas assez d'étapes ou de POIs, le mode démo peut être vide. Vérifier `demoAvailable` dans `TrailMeta`. Si false ou données insuffisantes, masquer le bouton démo dans le catalogue.
- **Fallback "Aperçu indisponible"** — Toujours afficher un message explicite si la démo ne peut pas se charger.
- **Pas de téléchargement en démo** — Le mode démo ne télécharge aucune donnée localement (ni JSON ni MBTiles). Tout vient du cache catalogue.
