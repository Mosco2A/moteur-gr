# Ajouter un nouveau sentier -- Guide complet

Ce guide documente la procedure pour integrer un nouveau sentier dans l'application Fra li Monti. Le processus couvre l'import du trace GPS, la creation des points d'interet, les traductions, les cartes offline et le deploiement Firebase.

## 1. Import du trace GPX

### Format attendu

Le fichier GPX doit contenir :
- Un `<trk>` (track) avec un `<name>` explicite
- Des `<trkseg>` (segments) correspondant aux etapes
- Des `<trkpt>` (trackpoints) avec latitude, longitude et elevation

```xml
<gpx version="1.1">
  <trk>
    <name>GR20 Complet Nord-Sud</name>
    <trkseg>
      <trkpt lat="42.5078" lon="8.8303"><ele>1020</ele></trkpt>
      ...
    </trkseg>
  </trk>
</gpx>
```

### Procedure d'import

1. Placer le fichier GPX dans `assets/gpx/` avec un nom descriptif (ex: `mare_a_mare_nord.gpx`)
2. Declarer le fichier dans `pubspec.yaml` sous `flutter: assets:`
3. Le parser `lib/features/trek/data/gpx_parser.dart` extrait automatiquement les trackpoints
4. Verifier que l'elevation est presente sur chaque point (necessaire pour les profils altimetriques)

### Decoupage en etapes

Chaque sentier est decoupe en etapes. Pour le GR20 :
- 16 etapes standard (Nord vers Sud)
- Variantes possibles (7, 9, 12, 14 jours)

Le decoupage est defini dans les donnees statiques (`assets/data/`) avec pour chaque etape :
- Nom de depart et d'arrivee
- Distance (km)
- Denivele positif et negatif (m)
- Duree estimee
- Difficulte (1-5)
- Coordonnees du point de depart et d'arrivee

## 2. Points d'interet (POIs)

### Types de POI

| Type | Description | Icone |
|---|---|---|
| `refuge` | Refuge de montagne (gardienne, capacite, reservations) | Maison |
| `water` | Point d'eau (source, fontaine, riviere) | Goutte |
| `shop` | Commerce (epicerie, restaurant) | Panier |
| `accommodation` | Hebergement hors refuge (gite, hotel, camping) | Lit |
| `viewpoint` | Point de vue remarquable | Jumelles |
| `danger` | Zone dangereuse (passage expose, neige tardive) | Triangle |
| `transport` | Arret de bus, navette, taxi | Bus |

### Structure d'un POI

Chaque POI est stocke dans Firestore sous `pois/{trail_id}/{poi_id}` avec :
- `name` : nom affiche
- `type` : enum parmi les types ci-dessus
- `latitude`, `longitude` : coordonnees GPS
- `elevation` : altitude en metres
- `description` : texte descriptif
- `stageIndex` : numero de l'etape associee
- `photos` : liste d'URLs Firebase Storage
- `metadata` : champs specifiques au type (capacite refuge, horaires commerce, etc.)

### Ajout de POIs

1. Preparer les donnees dans un fichier JSON structure
2. Upload vers Firestore via un script d'import ou manuellement dans la console Firebase
3. Les images associees vont dans Firebase Storage sous `pois/{trail_id}/`

## 3. Traductions

L'application utilise Flutter Localizations avec les fichiers ARB.

### Fichiers ARB

Les fichiers de traduction sont dans `lib/l10n/` :
- `app_fr.arb` -- francais (langue par defaut)
- `app_en.arb` -- anglais

### Ajouter des traductions pour un sentier

Pour chaque nouveau sentier, ajouter dans les fichiers ARB :
- Nom du sentier
- Noms des etapes
- Descriptions des refuges et POIs
- Conseils specifiques au sentier

Exemple dans `app_fr.arb` :
```json
{
  "trailGr20Name": "GR20 - Fra li Monti",
  "trailGr20Description": "Traversee de la Corse du Nord au Sud",
  "stageGr20_1_name": "Calenzana - Ortu di u Piobbu",
  "stageGr20_1_description": "Premiere etape, montee raide depuis Calenzana"
}
```

Apres modification des ARB, regenerer le code :
```bash
flutter gen-l10n
```

## 4. Cartes offline (MBTiles)

### Pourquoi MBTiles

L'application utilise `flutter_map` avec `flutter_map_mbtiles` pour le rendu offline des cartes. Le format MBTiles est un conteneur SQLite qui stocke les tuiles de carte par niveau de zoom.

### Generation des tuiles

1. **Source** : utiliser des tuiles OpenStreetMap ou un fournisseur compatible
2. **Zone** : definir le bounding box du sentier + marge de 5-10 km
3. **Niveaux de zoom** : generer les niveaux 10 a 16 (bon compromis taille/detail)
4. **Outil** : `tippecanoe`, `mbutil`, ou `MapTiler` pour generer le fichier `.mbtiles`

### Integration

1. Placer le fichier `.mbtiles` sur Firebase Storage sous `maps/{trail_id}/`
2. L'ecran `OfflineDownloadScreen` permet a l'utilisateur de telecharger les tuiles
3. Le fichier est stocke localement via `path_provider` dans le dossier documents de l'app
4. `flutter_map_mbtiles ^1.0.4` lit directement le fichier local

### Taille estimee

Pour le GR20 complet (zooms 10-16) : environ 200-300 Mo.
Prevoir un indicateur de progression et permettre le telechargement par etape.

## 5. Manifest trail (fiche sentier)

Chaque sentier a un document Firestore dans `trails/{trail_id}` :

```
trails/gr20:
  name: "GR20 - Fra li Monti"
  country: "France"
  region: "Corse"
  totalDistance: 180
  totalElevationGain: 12000
  totalStages: 16
  difficulty: 5
  duration:
    min: 7
    max: 16
    recommended: 14
  startPoint:
    lat: 42.5078
    lon: 8.8303
    name: "Calenzana"
  endPoint:
    lat: 41.7374
    lon: 9.3492
    name: "Conca"
  mbtilesUrl: "gs://gr20-app.appspot.com/maps/gr20/gr20.mbtiles"
  mbtilesSize: 280000000
  gpxAsset: "assets/gpx/gr20_complet_16etapes_NS.gpx"
  available: true
  premium: false
  createdAt: <timestamp>
  updatedAt: <timestamp>
```

## 6. Upload Firebase

### Checklist deploiement

- [ ] Fichier GPX dans `assets/gpx/` et declare dans `pubspec.yaml`
- [ ] POIs crees dans Firestore `pois/{trail_id}/`
- [ ] Images POIs uploadees dans Storage `pois/{trail_id}/`
- [ ] Traductions ARB mises a jour + `flutter gen-l10n`
- [ ] Fichier MBTiles genere et uploade dans Storage `maps/{trail_id}/`
- [ ] Document trail cree dans Firestore `trails/{trail_id}`
- [ ] Etapes creees dans Firestore `trails/{trail_id}/stages/`
- [ ] Test complet sur emulateur (import GPX, navigation, POIs, cartes offline)
- [ ] `flutter analyze` clean
- [ ] Tests unitaires passes

### Ordre des operations

1. Creer le document `trails/{trail_id}` dans Firestore
2. Creer les documents `trails/{trail_id}/stages/{stage_index}`
3. Creer les POIs dans `pois/{trail_id}/`
4. Uploader les images dans Storage
5. Uploader le fichier MBTiles dans Storage
6. Ajouter le GPX dans les assets et rebuild
7. Mettre a jour les traductions
8. Tester en mode offline complet
