# Module Analytics + Monétisation

> Firebase Analytics, Crashlytics, modèle économique.

## Description

**Analytics** : suivi des événements clés par sentier via Firebase Analytics (install, switch, demo_view, uninstall, stage_complete...). Crashlytics pour le suivi des crashs avec breadcrumbs. User properties pour la segmentation.

**Monétisation** : modèle gratuit + premium par achat unique par sentier. Le champ `isPurchased` est réservé dans les modèles mais NON utilisé dans E5.1. L'étape monétisation dédiée viendra plus tard.

## Architecture

```
core/firebase/
  firebase_service.dart                 -- Service Firebase (Analytics + Crashlytics)
```

Analytics et Crashlytics sont transversaux : ils n'ont pas de dossier feature dédié. Ils sont injectés via le `FirebaseService` et appelés depuis les providers des autres modules.

## Événements Analytics

| Événement | Paramètres | Déclencheur |
|---|---|---|
| `trail_install` | trailId, trailCode | Téléchargement terminé |
| `trail_uninstall` | trailId | Suppression sentier |
| `trail_switch` | fromTrailId, toTrailId | Basculement sentier |
| `demo_view` | trailId | Entrée mode démo |
| `stage_complete` | trailId, stageId, durationMin | Étape terminée |
| `journal_entry` | trailId, hasPhotos | Ajout entrée journal |
| `planning_create` | trailId, nbDays | Création planning |
| `weather_check` | trailId, stageId | Consultation météo |

## User Properties

- `installed_trails_count` -- nombre de sentiers installés
- `active_trail` -- code du sentier actif
- `auth_type` -- anonyme / google / apple
- `app_language` -- langue de l'app

## Fichiers concernés

| Fichier | Rôle |
|---|---|
| `firebase_service.dart` | Analytics events, Crashlytics breadcrumbs, user properties |

## API / Providers

- `FirebaseService` -- classe singleton, méthodes statiques
  - `logEvent(name, params)`, `setUserProperty(name, value)`, `recordError(error, stack)`
  - Crashlytics : `log(message)` pour breadcrumbs

## Monétisation (réservé)

Le champ `isPurchased` est présent dans :
- `InstalledTrail.isPurchased` (bool, default false)
- `TrailConfig.isPurchased` (bool, default false)
- `TrailMeta.isPurchased` (bool, default false)
- `CatalogEntry.isPurchased` (bool, default false)

Modèle prévu : gratuit + premium par achat unique par sentier. Détails dans une étape dédiée (pas E5.1).

## Pièges connus

- **isPurchased inutilisé** -- Ne PAS brancher de logique sur ce champ dans E5.1. Il est juste présent dans les modèles.
- **Crashlytics breadcrumbs** -- Ajouter des breadcrumbs aux points clés (changement étape, sync, switch sentier) pour faciliter le debug.
- **Retention funnel** -- Configurer dans la console Firebase : install -> first_stage -> half_trail -> complete.
- **RGPD** -- Les analytics Firebase sont conformes RGPD si le consentement est géré (bandeau cookies/consentement au premier lancement).
