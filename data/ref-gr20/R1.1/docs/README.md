# Fra li Monti (GR20) -- Architecture & Guide de demarrage

## Presentation

Application mobile Flutter d'accompagnement des randonneurs sur le GR20 (Corse).
Couvre les trois phases du trek : **AVANT** (planification), **PENDANT** (navigation GPS offline), **APRES** (bilan et diplome).

Nom interne : `g20_app`
Nom public : **Fra li Monti**

## Stack technique

| Couche | Technologie | Version |
|---|---|---|
| Framework | Flutter / Dart | SDK >=3.2.0 <4.0.0 |
| State management | Riverpod 2 (riverpod_generator) | ^2.4.0 |
| Backend | Firebase (Auth, Firestore, Storage, Crashlytics) | Core ^3.8.0 |
| Cartes | flutter_map + flutter_map_mbtiles | ^6.1.0 / ^1.0.4 |
| Navigation | GoRouter 13 | ^13.0.0 |
| Stockage local | Hive (cache) + sqflite (track GPS) | ^2.2.3 / ^2.3.0 |
| Modeles | Freezed + json_serializable | ^2.4.0 / ^6.7.0 |
| Code gen | build_runner + riverpod_generator | ^2.4.0 / ^2.3.0 |
| i18n | intl (Flutter Localizations) | ^0.20.2 |
| Tests | flutter_test, mocktail, patrol | ^1.0.0 / ^3.3.0 |

## Lancer le projet

### Prerequis

- Flutter SDK >=3.2.0
- Dart SDK inclus avec Flutter
- Un emulateur Android ou simulateur iOS (ou appareil physique)
- Compte Firebase configure (projet `gr20-app`)

### Installation

```bash
# Cloner le repo
git clone git@github.com:Mosco2A/gr20.git
cd gr20

# Installer les dependances
flutter pub get

# Generer le code (Freezed, Riverpod, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Lancer sur emulateur/device
flutter run
```

### Commandes utiles

```bash
# Analyse statique (doit etre clean avant tout commit)
flutter analyze

# Lancer les tests unitaires
flutter test

# Lancer les tests d'integration
flutter test integration_test/

# Build release Android (AAB obligatoire pour Play Store)
flutter build appbundle --release

# Build release iOS
flutter build ipa --release
```

## Structure des dossiers

```
app/
  lib/
    main.dart                  # Point d'entree -- Firebase init, Hive init, ProviderScope
    firebase_options.dart      # Config Firebase generee (flutterfire configure)
    core/
      constants/               # AppConstants (16 etapes, 180 km, durees), HiveBoxes
      data/                    # RemoteDataService (config distante)
      errors/                  # Gestion d'erreurs centralisee
      network/                 # Connectivity, offline detection
      routing/                 # GoRouter -- AppRoutes, AppRouter, redirects auth
      theme/                   # AppTheme -- vert maquis #2D5016, bleu mediterranee #1565C0
      utils/                   # Utilitaires transverses
    features/
      auth/                    # Authentification (Firebase Auth, Google, Apple, anonyme)
        data/                  #   Services auth
        domain/                #   Modeles user
        presentation/          #   LoginScreen, OnboardingScreen, ProfileSetupScreen
        providers/             #   authProvider, autoAuthProvider, isDemoModeProvider
      planning/                # Phase AVANT -- planification du trek
        data/                  #   Services planification, itineraire
        domain/                #   Modeles etape, refuge, itineraire
        presentation/          #   HomeScreen, FeasibilityScreen, CalendarScreen, GearChecklist
        providers/             #   Providers planification
      trek/                    # Phase PENDANT -- navigation GPS, suivi en temps reel
        data/                  #   GPSTracker, GpxParser, TrekService, BackgroundGpsService
        domain/                #   Modeles trek, track points
        presentation/          #   MapNavigationScreen, ActiveStageScreen, RefugeDetailScreen
        providers/             #   Providers trek, session, stage detection
      group/                   # Gestion de groupe -- localisation partagee
        data/                  #   GroupSyncService
        domain/                #   Modeles groupe
        presentation/          #   GroupLocationScreen, GroupManagementScreen
        providers/             #   Providers groupe
        services/              #   Services groupe temps reel
      poi/                     # Points d'interet -- meteo, commerces, hebergements
        data/                  #   WeatherApiService (Open-Meteo), POI services
        presentation/          #   WeatherScreen, ShopDetailScreen, AccommodationScreen
        providers/             #   Providers POI
      after/                   # Phase APRES -- bilan, diplome
        data/                  #   Services recap, diplome PDF
        domain/                #   Modeles recap
        presentation/          #   AdventureRecapScreen, DiplomaScreen, GpxImportScreen
        providers/             #   Providers apres-trek
      feedback/                # Retours utilisateur / testeurs
        data/                  #   TesterMessageService
        domain/                #   Modeles feedback
        presentation/          #   Ecrans feedback
        providers/             #   Providers feedback
      settings/                # Parametres -- profil, premium, preferences
        data/                  #   Services parametres
        domain/                #   Modeles parametres
        presentation/          #   ProfileScreen, PremiumScreen
        providers/             #   Providers parametres
    shared/
      repositories/            # Repositories partages (Firestore, Hive)
      services/                # Services transverses (PremiumService, etc.)
      widgets/                 # Widgets reutilisables (PremiumGate, etc.)
    l10n/
      generated/               # Fichiers de localisation generes
  assets/
    data/                      # Donnees statiques (etapes, refuges)
    fonts/                     # Montserrat, OpenSans
    gpx/                       # Trace GPX du GR20 complet (16 etapes N->S)
    icons/                     # Icone app, splash
    images/                    # Images UI
  test/
    core/                      # Tests unitaires core
    features/                  # Tests par feature
    widget_test.dart           # Test widget racine
```

## Architecture

### Feature-based

Chaque fonctionnalite est isolee dans `lib/features/<feature>/` avec 4 sous-dossiers :
- `data/` -- services, API calls, acces Firestore/Hive
- `domain/` -- modeles (Freezed), entites metier
- `presentation/` -- screens, widgets
- `providers/` -- Riverpod providers (generes via riverpod_generator)

### Offline-first

80% du GR20 est sans reseau. L'app fonctionne en mode offline par defaut :
- **Cartes** : tuiles MBTiles pre-telechargees via `flutter_map_mbtiles`
- **Donnees** : cache Hive local, sync Firebase quand reseau disponible
- **GPS** : tracking continu via `geolocator` + `sqflite` pour les track points
- **Firestore** : `includeMetadataChanges: true` + filtrage `isFromCache`

### Authentification

Trois modes d'auth supportes :
1. **Google Sign-In** -- auth principale
2. **Apple Sign-In** -- obligatoire iOS (App Store requirement)
3. **Anonyme** -- mode decouverte, pas d'ecriture Firestore tant que profil non complete

### Theme

Palette Material 3 inspiree du maquis corse :
- Vert maquis : `#2D5016` (couleur principale)
- Bleu mediterranee : `#1565C0` (accents)
- Orange terre : `#E65100` (alertes, urgences)
- Dark theme par defaut (`AppTheme.darkTheme`)

## Donnees GR20

- 16 etapes (Nord vers Sud, de Calenzana a Conca)
- 180 km de distance totale
- 12 000 m de denivele positif cumule
- Durees proposees : 7, 9, 12, 14 ou 16 jours
- Trace GPX : `assets/gpx/gr20_complet_16etapes_NS.gpx`

## Firebase

- Projet : `gr20-app`
- Android package : `com.only1cent.g20_app`
- iOS bundle : `com.only1cent.g20App`
- Collections principales : `users/`, `treks/`, `groups/`, `pois/`
- Crashlytics : conditionnel RGPD (consentement utilisateur requis via SharedPreferences)
- Config : `firebase_options.dart` genere par `flutterfire configure`

## Pieges connus

1. **Open-Meteo** : l'API Meteo-France ne supporte PAS `precipitation_probability_max` ni `uv_index_max` (erreur HTTP 400). Utiliser les champs standards uniquement.
2. **flutter_map_mbtiles** : utiliser `^1.0.4` (la version `^0.3.0` n'existe pas sur pub.dev).
3. **Riverpod** : toujours utiliser `riverpod_generator` pour les providers, jamais de providers manuels.
4. **Firebase snapshots** : toujours `includeMetadataChanges: true` + filtrer les snapshots ou `isFromCache == true` pour eviter les donnees fantomes.
5. **Build Android** : AAB obligatoire (APK refuse en production depuis 2024). Cibler API 35 (Android 15).
6. **iOS** : cibler iPadOS 26 SDK (Xcode 26+). Dark Mode et Dynamic Type requis.
7. **ANR Android** : `main()` fait le strict minimum avant `runApp()`. Tout est differe apres le premier frame via `postFrameCallback` / `FutureProvider` (fix B62).
8. **RGPD Crashlytics** : `setCrashlyticsCollectionEnabled()` conditionne par le consentement utilisateur (fix B83).
