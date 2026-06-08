# Ajouter un nouveau sentier — Guide complet

Ce guide decrit, etape par etape, l'integration d'un nouveau sentier dans
StepWays. Le moteur etant **generique**, ajouter un sentier ne demande
**aucun code metier** : on fournit une configuration (`TrailConfig`), des
donnees (JSON + GPX), des cartes offline (MBTiles) et des traductions (Slang).

Vue d'ensemble des artefacts a produire :

1. Un `TrailConfig` (couleurs, meta, secours, durees, assets de seed).
2. Un fichier de donnees JSON (meta + itineraires + etapes + POIs).
3. Un trace GPX.
4. Un fichier MBTiles (carte offline).
5. Les chaines de traduction Slang (5 langues) si le sentier ajoute du texte.
6. La declaration des assets dans `pubspec.yaml`.
7. (Optionnel) un manifest distant pour le catalogue/telechargement.

> Convention : un identifiant de sentier en `kebab-case` (ex:
> `mare-a-mare-centre`). Cet `id` relie le `TrailConfig`, les donnees JSON
> (`trailId`) et les eventuels documents distants.

## 1. TrailConfig

Le moteur ne connait aucun sentier : tout vient de
`lib/core/config/trail_config.dart`. Creer une instance pour le nouveau
sentier (par convention, dans `lib/core/config/`, a cote de
`test_trail_config.dart`) :

```dart
const monSentierConfig = TrailConfig(
  id: 'mon-sentier',
  name: 'Mon Sentier',
  displayName: 'Mon Sentier Trail',
  tagline: 'Votre compagnon de trek',
  totalStages: 7,
  totalDistanceKm: 84.0,
  totalElevationGain: 3550,
  region: 'Ma Region',
  country: 'France',
  primaryColorValue: 0xFF2E7D32,
  secondaryColorValue: 0xFF1565C0,
  gpxAssetPath: 'assets/gpx/mon_sentier.gpx',
  availableDurations: [5, 7, 9],
  defaultDuration: 7,
  emergencyNumbers: [
    TrailEmergencyNumber(name: 'Secours montagne', phone: '+33...'),
  ],
  // Racine des assets de seed (le JSON complet du sentier).
  seedAssetsBase: 'assets/data/mon_sentier.json',
  firebaseProjectId: null, // null = mode local (pas de backend)
);
```

Le `112` (urgences europeennes) est gere par le moteur : ne le dupliquez
pas dans `emergencyNumbers` (qui ne sert qu'aux secours **regionaux**).

L'app injecte la config active dans `main.dart` via
`ProviderScope(overrides: [trailConfigProvider.overrideWithValue(config)])`.

## 2. Donnees du sentier (JSON de seed)

Les donnees sont un **fichier JSON unique** charge au premier lancement par
`TrailSeeder` (`lib/core/data/seed/trail_seeder.dart`) et inserees dans Drift
dans l'ordre des cles etrangeres :
`trail_meta -> itineraries -> stages -> accommodations -> pois`.

Le seeder est **generique** : il lit le `trailId` depuis le JSON et ne
contient aucune logique specifique a un sentier. Le chemin du fichier vient
de `TrailConfig.seedAssetsBase`.

Structure attendue (`assets/data/mon_sentier.json`) :

```json
{
  "trail_meta": {
    "id": "mon-sentier",
    "code": "ms",
    "dataVersion": 1,
    "status": "active"
  },
  "itineraries": [
    {
      "id": "ms-ew",
      "trailId": "mon-sentier",
      "code": "EW",
      "nameFr": "...", "nameEn": "...", "nameDe": "...",
      "nameIt": "...", "nameEs": "...",
      "distanceKm": 84.0,
      "elevationGain": 3550,
      "stageCount": 7
    }
  ],
  "stages": [
    {
      "id": "ms-ew-s1",
      "itineraryId": "ms-ew",
      "stageNumber": 1,
      "nameFr": "Depart — Etape 1", "nameEn": "...",
      "startLat": 42.0156, "startLng": 9.4039,
      "endLat": 41.9567, "endLng": 9.2864,
      "distanceKm": 15.0,
      "elevationGain": 850,
      "elevationLoss": 100,
      "durationMinutes": 330,
      "difficulty": "hard"
    }
  ],
  "accommodations": [],
  "pois": [
    {
      "id": "ms-poi-01",
      "stageId": "ms-ew-s1",
      "stageNumber": 1,
      "nameFr": "Gite d'etape", "nameEn": "Guesthouse",
      "descriptionFr": "...", "descriptionEn": "...",
      "type": "shelter",
      "lat": 41.957, "lng": 9.287,
      "altitudeM": 720
    }
  ]
}
```

Points cles :
- Les libelles sont **multilingues inline** (`nameFr`, `nameEn`, ...). Les
  langues non fournies retombent sur la base (fr).
- Chaque `stage` porte ses coordonnees depart/arrivee (profil + carte).
- Chaque `poi` reference son etape (`stageId` / `stageNumber`).

### Types de POI

Le `type` d'un POI est une chaine **extensible** (pas un enum ferme), stylee
par `lib/features/poi/domain/poi_type_config.dart`. Valeurs usuelles :

- `shelter` — refuge / gite (capacite, demi-pension...)
- `water` — point d'eau (source, fontaine)
- `shop` — commerce (epicerie, restaurant)
- `accommodation` — hebergement hors refuge (hotel, camping)
- `viewpoint` — point de vue
- `danger` — zone exposee
- `transport` — bus, navette, taxi

Un type inconnu reste affiche (icone neutre) : le moteur ne casse pas sur une
valeur non prevue.

## 3. Trace GPX

1. Placer le GPX dans `assets/gpx/` (ex: `assets/gpx/mon_sentier.gpx`) et
   renseigner `TrailConfig.gpxAssetPath`.
2. Format : `<trk>` avec des `<trkseg>` et des `<trkpt lat=".." lon="..">`
   portant l'elevation (`<ele>`), necessaire aux profils altimetriques.
3. Le parser GPX du moteur extrait les trackpoints ; la simplification par
   niveau de zoom utilise Douglas-Peucker (`lib/core/geo/`).

```xml
<gpx version="1.1">
  <trk>
    <name>Mon Sentier</name>
    <trkseg>
      <trkpt lat="42.0156" lon="9.4039"><ele>20</ele></trkpt>
      <!-- ... -->
    </trkseg>
  </trk>
</gpx>
```

## 4. Cartes offline (MBTiles)

Le rendu offline utilise `flutter_map` + `flutter_map_mbtiles`. Le MBTiles est
un conteneur SQLite de tuiles par niveau de zoom.

1. **Source** : tuiles OpenStreetMap (ou fournisseur compatible).
2. **Zone** : bounding box du sentier + marge de 5-10 km.
3. **Zooms** : 10 a 16 (bon compromis taille/detail).
4. **Outil** : `tippecanoe`, `mbutil`, ou MapTiler pour produire le `.mbtiles`.
5. **Distribution** : soit embarque dans les assets, soit telecharge depuis
   Firebase Storage par l'ecran catalogue (`flutter_map_mbtiles` ^1.0.4 lit le
   fichier local). Prevoir un indicateur de progression (un GR fait ~200-300 Mo).

## 5. Traductions Slang (5 langues)

Les libelles de **donnees** (etapes, POIs) sont dans le JSON de seed. Les
chaines **d'interface** specifiques au sentier (s'il y en a) passent par Slang.

- Sources : un fichier JSON **par langue** dans `assets/i18n/` :
  `fr.i18n.json` (base), `en.i18n.json`, `de.i18n.json`, `it.i18n.json`,
  `es.i18n.json`.
- Ajouter la cle dans **les 5 fichiers** (sinon fallback sur fr).
- Regenerer le code Slang :

```bash
dart run slang
```

> **Important** : Slang se regenere via la CLI `dart run slang`, **pas** via
> `build_runner` (`slang_build_runner` est desactive dans `build.yaml`). Le code
> genere atterrit dans `lib/i18n/translations.g.dart` (+ un fichier par langue).
> Usage type-safe : `t.<namespace>.<cle>`.

## 6. Declarer les assets (pubspec.yaml)

Ajouter les nouveaux chemins sous `flutter: assets:` :

```yaml
flutter:
  assets:
    - assets/gpx/
    - assets/data/
    - assets/data/mon_sentier/        # si vous regroupez les donnees
    - assets/i18n/
    - assets/tips/
```

Puis `flutter pub get`.

## 7. (Optionnel) Manifest catalogue / telechargement

Si le sentier doit apparaitre dans le **catalogue telechargeable** (backend
Firebase), publier une fiche dans le manifeste distant lu par le catalogue
(`trailId`, version de donnees, taille MBTiles, URLs Storage). En mode local
(sans Firebase), le sentier embarque est seede directement au lancement, sans
manifest.

## Checklist d'integration

- [ ] `TrailConfig` cree (id, couleurs, secours, durees, `seedAssetsBase`,
      `gpxAssetPath`).
- [ ] JSON de seed valide (`trail_meta` + `itineraries` + `stages` + `pois`),
      `trailId` coherent partout.
- [ ] GPX present dans `assets/gpx/` avec elevation sur chaque point.
- [ ] MBTiles genere (zooms 10-16) et distribue (assets ou Storage).
- [ ] Chaines Slang ajoutees dans les 5 langues + `dart run slang`.
- [ ] Assets declares dans `pubspec.yaml` + `flutter pub get`.
- [ ] `dart run build_runner build --delete-conflicting-outputs` (Drift/Freezed).
- [ ] `flutter analyze` clean.
- [ ] `flutter test` au vert (ajouter des fixtures de test pour le sentier si
      vous touchez a la logique).
- [ ] Test manuel : seed -> catalogue -> detail -> carte offline -> navigation.
- [ ] `bash scripts/scan_secrets.sh` : aucun secret, aucune marque/region
      en dur hors des donnees parametriques.

## Rappel : zero hardcoding

Le sentier ne doit exister que dans **ses donnees** (`TrailConfig`, JSON, GPX,
MBTiles, Slang). Aucun `if (trailId == 'mon-sentier')`, aucun nom de region ou
de marque dans le code du moteur. C'est ce qui permet d'ajouter un sentier
sans toucher au coeur — et ce que verifie la gate QA.
