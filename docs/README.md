# StepWays (moteur_gr) — Architecture & Guide de demarrage

## Presentation

**StepWays** est un moteur generique Flutter qui transforme n'importe quel
sentier de randonnee en application mobile complete : catalogue, carte offline,
navigation GPS, planning, points d'interet, journal, diplome.

Le moteur est **agnostique du sentier** : chaque sentier fournit sa propre
configuration (`TrailConfig`) — couleurs, etapes, POIs, secours regionaux,
traductions — et l'app s'y adapte sans code specifique. Le premier sentier
cible (Mare a Mare) est integre de maniere **parametrique** (assets +
`TrailConfig`), jamais code en dur dans le moteur.

> StepWays est un projet **independant**. Le code ne contient aucune reference
> a un sentier, une marque ou une region en dur (verifie en continu, cf.
> `scripts/scan_secrets.sh` et la gate QA).

Nom du package Dart : `moteur_gr`. ApplicationId / namespace :
`com.only1cent.moteur_gr`.

## Stack technique

Versions reelles (source : `pubspec.yaml` / `pubspec.lock`).

- **Framework** — Flutter / Dart, SDK `>= 3.8.0 < 4.0.0`
- **State management** — **Riverpod 2.6** (`flutter_riverpod` ^2.6.0),
  providers **manuels** (pas de generator)
- **Navigation** — GoRouter ^13.0.0
- **Cartes offline** — flutter_map ^8.2.0 + flutter_map_mbtiles ^1.0.4
- **GPS** — geolocator ^11.0.0 + gpx ^2.2.0
- **Stockage local** — **Drift** ^2.22.1 (SQLite type-safe)
- **Modeles immuables** — **Freezed** ^3.2.5 + json_serializable ^6.7.0
- **i18n** — **Slang** ^4.15.0 (type-safe, 5 langues)
- **Backend** — Firebase (Auth, Firestore, Storage, Analytics, Crashlytics),
  Core ^3.8.0
- **Monorepo** — Melos ^6.3.2 + Pub Workspaces
- **Tests** — flutter_test (SDK)

> **Riverpod 2.6, pas v3.** Un upgrade Riverpod v3 est un lot futur dedie
> (decision option A). La stack reelle de `main` est en 2.6 — voir
> `docs/ADR/003-riverpod-over-bloc.md`.

> **Providers manuels.** Les providers sont declares a la main
> (`final xProvider = Provider(...)` / `NotifierProvider` / `FutureProvider`).
> Le projet n'utilise **pas** `riverpod_generator` / `@riverpod` : il n'y a donc
> aucune generation de code pour les providers (uniquement Freezed, Drift,
> Slang, json_serializable).

## Lancer le projet

### Prerequis

- Flutter SDK >= 3.8.0 (canal stable)
- Un emulateur Android ou simulateur iOS (ou un appareil physique)
- Firebase est **optionnel** au demarrage : si `TrailConfig.firebaseProjectId`
  est `null`, le moteur tourne en **mode local** (donnees seedees, pas de
  backend). Voir `docs/firebase-setup.md` pour brancher un vrai projet.

### Installation

```bash
# Cloner le repo
git clone git@github.com:Mosco2A/moteur-gr.git
cd moteur-gr

# Installer les dependances
flutter pub get

# Generer le code (Freezed, Drift, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Generer les traductions Slang (CLI dediee — PAS build_runner, cf. slang.yaml)
dart run slang

# Lancer sur emulateur/device
flutter run
```

### Commandes utiles

```bash
# Analyse statique (doit etre clean avant tout commit)
flutter analyze

# Tests
flutter test

# Build release Android — AAB obligatoire pour le Play Store
flutter build appbundle --release

# Build release iOS
flutter build ipa --release

# Audit securite (deps + secrets) — voir section Securite
bash scripts/security_audit.sh
bash scripts/scan_secrets.sh
```

> **Slang** se regenere avec `dart run slang` (la CLI officielle), **pas** via
> `build_runner`. `slang_build_runner` est volontairement desactive dans
> `build.yaml` (incompatibilite + risque de doublon). Voir l'en-tete de
> `slang.yaml`.

## Structure des dossiers

```
lib/
  main.dart                  # Point d'entree : init Firebase conditionnelle,
                             #   ProviderScope (override TrailConfig +
                             #   FirebaseService), MaterialApp.router
  core/                      # Socle transverse, agnostique du sentier
    a11y/                    #   WcagContrast (audit contraste WCAG)
    analytics/               #   Analytics anonyme (events zero-PII, opt-in)
    config/                  #   TrailConfig, FeatureFlags, follow links
    constants/
    data/                    #   Drift : database, daos/, tables/, seed/
    engine/                  #   TrailEngine + providers coeur (trailConfig...)
    error/                   #   Gestion d'erreurs
    extensions/
    firebase/                #   FirebaseService (mode degrade si non configure)
    geo/                     #   Geometrie (Douglas-Peucker, distances)
    map/                     #   Helpers carte
    models/                  #   Modeles partages (Stage, Poi...)
    network/                 #   Connectivite, offline
    providers/               #   Providers transverses
    routing/                 #   GoRouter (app_router.dart) + app_shell.dart
    services/
    theme/                   #   AppTheme (themes clair + sombre par sentier)
    ui/                      #   Widgets/utilitaires UI (loading, error, haptics)
  features/                  # Une fonctionnalite = un dossier
    after/ auth/ booking/ checklist/ diploma/ feasibility/ feedback/
    goodies/ group/ journal/ map/ more/ notifications/ planning/ poi/
    safety/ settings/ share/ tips/ tracking/ trail/ trek/ weather/
                             #   Chaque feature : data/ domain/ presentation/
                             #   providers/ (+ widgets/ models/ selon le cas)
  shared/
    widgets/                 #   Widgets reutilisables (EmptyState, AppCard,
                             #   StageNumberBadge, PaywallSheet...)
  i18n/                      #   Code Slang GENERE (translations.g.dart + 5 langues)
assets/
  i18n/                      #   Sources de traduction : 1 JSON par langue
                             #   (fr.i18n.json, en, de, it, es)
  data/                      #   Donnees de seed (templates + sentier parametrique)
  gpx/                       #   Traces GPX
  tips/                      #   Fiches conseils
test/                        # Miroir de lib/ (core/, features/, shared/, i18n/)
```

> Le code est a la **racine** dans `lib/` (il n'y a pas de prefixe `app/`).

## Architecture

### Feature-first

Chaque fonctionnalite vit dans `lib/features/<feature>/` avec, selon les
besoins :
- `data/` — services, acces Drift/Firestore, API ;
- `domain/` — modeles (Freezed), entites metier ;
- `presentation/` — ecrans et widgets ;
- `providers/` — providers Riverpod **manuels**.

Le socle commun (carte, Drift, theme, routing, config, a11y) est dans
`lib/core/`.

### Moteur parametrique (`TrailConfig`)

`lib/core/config/trail_config.dart` est le coeur du moteur. Un sentier =
une instance de `TrailConfig` (id, displayName, couleurs, nombre d'etapes,
region, pays, numeros de secours regionaux, durees proposees, projet
Firebase optionnel, assets de seed...). `main.dart` injecte la config active
via `ProviderScope(overrides: [trailConfigProvider.overrideWithValue(...)])`.
`TrailEngine` (`lib/core/engine/`) orchestre le chargement a partir de cette
config. **Aucun sentier n'est code en dur** dans le moteur.

### Offline-first

L'app fonctionne sans reseau par defaut :
- **Cartes** : tuiles MBTiles pre-telechargees (`flutter_map_mbtiles`) ;
- **Donnees** : base **Drift** locale, seedee depuis les assets du sentier ;
- **GPS** : suivi continu via `geolocator`, points stockes dans Drift ;
- **Firebase** : optionnel. Sans `firebaseProjectId`, mode local explicite
  (`CloudUnavailableNotice`) ; avec, sync best-effort quand le reseau revient.

### Theme (clair + sombre, par sentier)

`AppTheme.buildDarkTheme(...)` et `AppTheme.buildLightTheme(...)` construisent
les deux themes Material 3 a partir des couleurs du `TrailConfig`. L'app est
sombre par defaut (`ThemeMode.dark`) ; le pendant clair est cable et teste.
Les tokens de texte secondaire sont distincts selon le fond
(`grisTexteSecondaire` sur sombre, `grisGranite` sur clair) pour garantir le
contraste WCAG AA (>= 4.5:1).

### Authentification

Trois modes : Google Sign-In, Apple Sign-In (requis iOS) et anonyme (mode
decouverte). L'identifiant utilisateur est anonymise (zero PII en clair cote
modeles). Le suivi temps reel partage repose sur un miroir public minimal
Firestore (`follow_sessions_public`) qui ne porte jamais l'identifiant du
trekkeur (les regles `firestore.rules` gardent le document maitre owner-only).

## Donnees sentier

Pour ajouter un sentier complet (GPX, POIs, MBTiles, traductions, manifest,
`TrailConfig`), suivre **`docs/ADD_TRAIL.md`**.

## Securite

- `scripts/security_audit.sh` — audit des dependances (`dart pub outdated`),
  signale les paquets obsoletes/critiques, sort `0` si rien de critique.
- `scripts/scan_secrets.sh` — scan du code (cles/tokens/mots de passe) +
  verification que `.gitignore` exclut bien les secrets
  (`key.properties`, `*.keystore`, `.env`, `google-services.json`,
  `GoogleService-Info.plist`).
- `firestore.rules` — regles Firestore (suivi partage, RGPD) + tests
  emulateur dans `firestore-tests/`.

## Pieges connus

1. **Slang** : se regenere via `dart run slang`, pas `build_runner`
   (`slang_build_runner` desactive dans `build.yaml`). Sources = 1 JSON par
   langue dans `assets/i18n/`.
2. **Riverpod** : providers **manuels** (pas de `@riverpod` / generator).
   Tester via `ProviderContainer` + overrides.
3. **flutter_map v8** : API changee vs v6/v7 (voir
   `lib/docs/flutter_map_v8_changes.dart`).
4. **Firebase optionnel** : `main()` initialise Firebase seulement si
   `firebaseProjectId != null` ; sinon mode local. Toujours verifier
   `FirebaseService.isAvailable` avant un acces cloud.
5. **Build Android** : AAB obligatoire (APK refuse en production). Cibler
   API 35 (Android 15).
6. **iOS** : cibler iPadOS 26 SDK (Xcode 26+), Dark Mode + Dynamic Type.
7. **ANR Android** : `main()` fait le strict minimum avant `runApp()`.
8. **Drift** : base SQLite locale (jamais nommee d'apres un sentier en dur).
9. **Zero texte en dur** : tout texte utilisateur passe par Slang
   (`t.<namespace>.<cle>`).
