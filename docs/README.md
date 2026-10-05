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
`com.only1cent.stepways`.

## Stack technique

Versions reelles (source : `pubspec.yaml` / `pubspec.lock`).

- **Framework** — Flutter / Dart, SDK `>= 3.8.0 < 4.0.0`
- **State management** — **Riverpod 3.3.2** (`flutter_riverpod` ^3.3.2),
  providers **manuels** (pas de generator)
- **Navigation** — GoRouter ^13.0.0
- **Cartes offline** — flutter_map ^8.2.0 + flutter_map_mbtiles ^1.0.4
- **GPS** — geolocator ^11.0.0 + gpx ^2.2.0
- **Stockage local** — **Drift** ^2.22.1 (SQLite type-safe)
- **Modeles immuables** — **Freezed** ^3.2.5 + json_serializable ^6.7.0
- **i18n** — **Slang** ^4.15.0 (type-safe, 5 langues)
- **Backend** — Firebase (Auth, Firestore, Storage, Analytics, Crashlytics),
  `firebase_core` ^3.8.0
- **Monorepo** — Melos ^6.3.2 + Pub Workspaces
- **Tests** — flutter_test (SDK)

> **Riverpod 3.3.2.** La migration vers Riverpod 3 (INC-1) est faite : bump
> de version, API legacy conservees (`StateProvider`/`StateNotifierProvider`
> via `legacy.dart`), retry automatique neutralise au `ProviderScope` racine —
> voir le commentaire de `pubspec.yaml` et `docs/ADR/003-riverpod-over-bloc.md`.

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

## Outillage

### UN SEUL `pub get` A LA FOIS PAR MACHINE

**La regle, et elle n'est pas negociable : sur une machine qui porte plusieurs
arbres de travail du depot, un seul `pub get` tourne a la fois.** Le cache pub
est **partage** par tous les arbres (`%LOCALAPPDATA%\Pub\Cache` sous Windows,
`~/.pub-cache` ailleurs) : deux resolutions concurrentes ecrivent dans les memes
dossiers.

**Ce que ca coute quand on l'oublie — mesure du 05/10/2026 (memoires #101275,
#101276).** Deux `flutter pub get` ont tourne en parallele dans deux arbres a
13:24:55. Resultat : **29 dossiers de paquets existaient mais etaient vides** —
`cloud_firestore`, `share_plus`, `firebase_core`, `connectivity_plus`,
`battery_plus`, `device_info_plus`, `package_info_plus`, `printing`,
`sqlite3_flutter_libs` et vingt autres, tous horodates a la meme seconde.

**Et voici le piege, celui qui coute une demi-journee** : `pub get` decide qu'un
paquet est deja installe **en regardant si son dossier existe**. Un dossier vide
passe donc pour un paquet installe, et ne se retelecharge **jamais**. La
resolution reste cassee **en silence, pour tous les arbres de la machine**.
Facture constatee : **219 fausses erreurs** de `flutter analyze` (« Target of URI
doesn't exist: package:cloud_firestore/cloud_firestore.dart », « Undefined name
Share / Timestamp / ConnectivityResult ») sur un depot parfaitement sain, et deux
agents partis chercher une regression qui n'existait pas.

**Comment tenir la regle.** `tool/pub_cache_sain.py` pose un verrou de fichier
**dans le cache qu'il protege** : deux arbres qui partagent le cache partagent le
verrou par construction, et un arbre qui a son propre `PUB_CACHE` n'attend
personne. Les appels concurrents **attendent leur tour**, ils n'echouent pas.

```bash
# A la place de `flutter pub get` quand la machine peut etre occupee
python tool/pub_cache_sain.py --pub-get

# Toute autre commande qui touche au cache, serialisee de la meme facon
python tool/pub_cache_sain.py --sous-verrou dart pub get

# Mesurer sans rien toucher / reparer un cache deja abime
python tool/pub_cache_sain.py --mesurer
python tool/pub_cache_sain.py --purger [--simuler]
```

**La purge est le filet, le verrou est la regle.** `--purger` efface les dossiers
de `hosted/<hote>/` **qui n'ont pas de `pubspec.yaml` a leur racine**, et rien
d'autre : ni un paquet complet, ni un fichier, ni le cache `git/`. Chaque
suppression est journalisee avec ce que le dossier contenait. Elle repare donc un
cache abime par un appelant qui n'est **pas** passe par le verrou — a commencer
par `flutter test` et `flutter build`, qui lancent un `pub get` implicite dont
personne ne controle le moment.

Le pilote de la recette persona (`tool/run_persona.ps1`) lance cette purge **a
son reveil**, avant le pre-build qui appelle Gradle (donc `pub get`) ;
`-SansControleCachePub` la coupe, en le disant. La garde
`test/outillage/cache_pub_sain_695_test.dart` eprouve la purge sur un faux cache
et verifie que le verrou n'est pas decoratif.

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
