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

## Publicité — ce que Christophe doit fournir (tâche 595, V1 PUB)

**Aucune clé AdMob réelle ne vit dans ce dépôt, et un test l'interdit**
(`test/comportement/pub_v1_595_test.dart`, groupe B3). Les seules valeurs
présentes sont les identifiants de **TEST publics de Google** (compte
`ca-app-pub-3940256099942544`), documentés et libres d'usage : un build sans
injection reste donc fonctionnel et n'affiche que des publicités de test.

Pour une V1 **vendable**, quatre valeurs sont à récupérer dans la console AdMob
et à injecter **au build**. Chacune retombe, à défaut, sur son équivalent de
test Google.

- **#P01 — App ID Android.** Propriété gradle `-PADMOB_APP_ID_ANDROID=…` (ou
  une ligne dans `~/.gradle/gradle.properties`, hors dépôt), ou variable
  d'environnement `ADMOB_APP_ID_ANDROID`. Alimente le `manifestPlaceholder`
  `admobAppId` lu par `AndroidManifest.xml`.
- **#P02 — App ID iOS.** Réglage de build `ADMOB_APP_ID_IOS`, défini dans
  `ios/Flutter/Debug.xcconfig` et `Release.xcconfig` et surchargeable en CI
  (`xcodebuild … ADMOB_APP_ID_IOS=…`). Lu par `GADApplicationIdentifier` dans
  `Info.plist`.
- **#P03 — Ad-unit bannière.** `--dart-define=ADMOB_BANNER_ANDROID=…` et
  `--dart-define=ADMOB_BANNER_IOS=…`.
- **#P04 — Ad-unit récompensée.** `--dart-define=ADMOB_REWARDED_ANDROID=…` et
  `--dart-define=ADMOB_REWARDED_IOS=…`.

Ces valeurs se déposent dans un groupe de variables **Codemagic** (ou
l'équivalent CI), jamais dans un fichier versionné.

**Conséquence voulue et à connaître** : tant qu'aucun ad-unit de production
n'est injecté (`AdConfig.hasProductionUnits == false`), le formulaire de
consentement publicitaire (CMP/UMP) n'est **pas** demandé — on ne pose pas une
question RGPD pour une régie qui n'est pas branchée. Dans l'EEE, un build de
test sans consentement déjà enregistré n'affiche donc **aucune** bannière.
C'est assumé : mieux vaut pas de bannière en recette qu'un formulaire natif
par-dessus la carte.

**iOS, deux points de conformité déjà posés** : `SKAdNetworkItems` ne déclare
que Google (la seule régie branchée — à allonger seulement si une autre est
réellement utilisée) et `NSUserTrackingUsageDescription` porte le texte ATT.
Sans cette clé, la demande de suivi est impossible et la revue App Store
rejette le binaire.

**Où la bannière s'affiche, et où elle ne s'affiche jamais** : cockpit de
préparation (`HubScreen`, hors phase rando) et catalogue
(`TrailCatalogScreen`). **Jamais** sur le chemin du secours — aucun écran SOS
ne porte de publicité ni de paywall, et deux tests structurels le verrouillent.

## Pièges connus

- **isPurchased inutilisé** -- Ne PAS brancher de logique sur ce champ dans E5.1. Il est juste présent dans les modèles.
- **Canal de plateforme muet = 6 s de minuteur** -- Dans un test, les canaux du SDK Google Mobile Ads ne sont branchés à personne : `MissingPluginException` est levée à un endroit que le SDK n'attrape pas, ni le callback de succès ni celui d'échec ne sont appelés, et seul le garde-fou de 6 s d'`AdsConsentService` rend la main. Tout test qui monte un écran porteur d'un emplacement publicitaire doit appeler `brancherAucuneRegiePub()` (`test/structurel/regie_pub_absente.dart`). C'était la cause du seul rouge que le dépôt portait (`purchase_gate_widget_test`).
- **Crashlytics breadcrumbs** -- Ajouter des breadcrumbs aux points clés (changement étape, sync, switch sentier) pour faciliter le debug.
- **Retention funnel** -- Configurer dans la console Firebase : install -> first_stage -> half_trail -> complete.
- **RGPD** -- Les analytics Firebase sont conformes RGPD si le consentement est géré (bandeau cookies/consentement au premier lancement).
