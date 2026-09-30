# Cartes hors ligne — fabrication et publication

Ce dossier fabrique le fichier `.mbtiles` qu'un randonneur telecharge avec le
bouton « Telecharger les cartes du circuit », et le publie la ou l'application
va le chercher. Tache 648, sur la chaine livree par le lot 640.

## Ce que la mesure a etabli avant d'ecrire une ligne (30/09)

| Ref | Question | Reponse mesuree | Ou ca se lit |
|---|---|---|---|
| #M01 | Quelle URL l'application telecharge-t-elle ? | `https://firebasestorage.googleapis.com/v0/b/stepways-app.firebasestorage.app/o/<data%2F…>?alt=media` | `TrailDataSource.urlDe` / `urlDonneesSentier` |
| #M02 | D'ou viennent `tilesPath`/`tilesSize`/`tilesHash` ? | de la ligne locale Drift `trail_manifests`, remplie par `ManifestService.saveLocalManifest` depuis l'entree de liste | `descente_des_cartes.dart`, `manifest_service.dart` |
| #M03 | D'ou vient l'entree de liste ? | **1.** collection Firestore `trails` (champs a plat, `snake_case`) — **2.** a defaut `data/manifest.json` du bucket (`camelCase`) | `catalogue_sentiers_provider.dart` (lot 641) |
| #M04 | Quelle empreinte ? | **SHA-256** hexadecimal minuscule, prefixes `sha256-` / `sha256:` toleres | `EmpreinteDePublication` |
| #M05 | Quel format de carte ? | **MBTiles raster** (PNG), `tile_row` en **TMS** | `flutter_map_mbtiles` 1.0.4 → `tmsY = (1 << z) - 1 - y` |
| #M06 | Ou la carte se pose-t-elle sur le telephone ? | `documents/mbtiles/<trailId>.mbtiles` | `MBTilesManager` |
| #M07 | Quelles regles de stockage ? | lecture publique de `data/**`, ecriture interdite | `storage.rules` (racine du depot) |

## La chaine

```
extrait Geofabrik (.osm.pbf, ODbL)
        │  MD5 publie, verifie
        ▼
   Planetiler 0.7.0 (Java 17)     ── tuiles VECTORIELLES, schema OpenMapTiles
        │
        ▼
   rendu.py + mvt.py (Pillow)     ── dessin RASTER, PNG a palette, metatuiles
        │
        ▼
   <sentier>.mbtiles              ── z10-15, TMS, metadata renseignee
        │
        ▼
   publier.py                     ── bucket + Firestore + manifest.json + PREUVE
```

**Pourquoi pas un fond de carte loue.** Le telechargement en masse de
`tile.openstreetmap.org` est interdit par la politique d'usage d'OSM, et les
loueurs interdisent la redistribution d'un fichier hors ligne. L'extrait de
donnees brutes, lui, est sous ODbL : les tuiles qu'on en tire sont une **oeuvre
produite**, redistribuable dans une application payante, avec l'attribution pour
seule obligation. C'est le chiffrage du lot 608 (0 €/mois).

**Pourquoi un moteur de rendu ecrit ici.** La machine de fabrication n'a ni
mapnik, ni GDAL, ni docker, ni QGIS (mesure du 30/09 : seuls Java 17, Node 24 et
Python 3.14 avec Pillow). La voie habituelle (MapLibre GL JS dans un Chromium
sans tete) demanderait un navigateur, du WebGL logiciel, des glyphes et des
sprites servis en local. Planetiler fait le travail difficile (trait de cote,
multipolygones d'eau, generalisation par zoom) ; le dessin tient alors dans
`rendu.py`, qu'on peut relire.

## Fabriquer

```bash
python tool/cartes_hors_ligne/fabriquer.py \
  --trace assets/data/mare_a_mare_centre/track.gpx \
  --sentier mare-a-mare-centre \
  --travail C:/Users/Christophe/stepways_tuiles_648 \
  --extrait corse --date-extrait 260929 \
  --nom "Mare a Mare Centre"
```

* L'**emprise** se lit dans la trace du sentier + 5 km. Jamais tapee a la main.
* L'extrait est **date** (`corse-260929.osm.pbf`) et non `-latest` : le serveur
  de Geofabrik renvoie `-latest.osm.pbf` en 301 vers lui-meme, et un extrait
  date rend la fabrication rejouable a l'identique.
* Sa **somme MD5 publiee est verifiee** : un extrait tronque ferait une carte a
  trous que rien ne signalerait.
* Tout ce qui est gros (`.osm.pbf` 33 Mo, sources auxiliaires de Planetiler
  ~500 Mo, tuiles vectorielles, `.mbtiles`) reste dans `--travail`, **hors
  depot**.

Mesure du 30/09 pour le Mare a Mare Centre : **2 420 tuiles z10-15, 26 955 776
octets (27,0 Mo), 122 s de rendu**. Le chiffrage 608 annoncait 67 Mo sur une
emprise plus large et sans palette.

## Publier

```bash
python tool/cartes_hors_ligne/publier.py \
  --sentier mare-a-mare-centre \
  --fichier C:/.../mare-a-mare-centre.mbtiles \
  --chemin mare_a_mare_centre/tuiles_z10-15_v<horodatage>.mbtiles \
  --manifeste C:/.../manifest.json
```

Le script depose le fichier, ecrit les trois champs **en base** (Firestore
`trails/{id}` : `tiles_path`, `tiles_size`, `tiles_hash`, avec `rev` et
`updated_at` avances) **et** dans le **repli** `data/manifest.json`, puis
**prouve** : il retelecharge par l'URL exacte de l'application, **sans jeton**,
et recalcule taille et empreinte. Il verifie aussi que le serveur accepte un
`Range` (HTTP 206) — c'est ce qui rend la reprise de descente possible.

Aucun secret dans le depot : le jeton vient de `STEPWAYS_GCP_TOKEN` ou de
`gcloud auth application-default print-access-token`.

`publier.py --preuve-seule` rejoue la verification sans rien ecrire.

## Prouver depuis le code de l'application

```bash
STEPWAYS_TEST_RESEAU=1 flutter test test/outillage/cartes_publiees_648_test.dart
```

Ce test ne simule rien : il lit la liste publiee, construit l'adresse avec
`TrailDataSource`, fait descendre le fichier par `MBTilesManager` — le chemin
exact du bouton — et verifie que le `.mbtiles` pose est bien une base SQLite de
la taille annoncee. Il est **saute par defaut** (il telecharge des dizaines de
megaoctets ; un test qui echoue sur une coupure de reseau accuse le code a tort).

## Attribution — obligation ODbL, et elle n'est PAS encore tenue

Les tuiles sont derivees d'OpenStreetMap. L'attribution
`© OpenStreetMap contributors` est due **sur chaque carte affichee**, et elle est
portee par les metadonnees du `.mbtiles` (`attribution`). **Mesure du 30/09 :
aucun ecran de l'application ne l'affiche** — la recherche sur `lib/` ne trouve
la mention nulle part, alors que cinq ecrans posent une carte. C'est le point
#N01 du chiffrage 608, reste ouvert. Il ne fait pas partie de ce lot : il est
signale, pas corrige ici.

## Sources

* Planetiler — <https://github.com/onthegomap/planetiler> (Apache-2.0)
* Schema OpenMapTiles — <https://openmaptiles.org/schema/>
* Specification Mapbox Vector Tile 2.1 —
  <https://github.com/mapbox/vector-tile-spec/blob/master/2.1/README.md>
* Specification MBTiles 1.3 —
  <https://github.com/mapbox/mbtiles-spec/blob/master/1.3/spec.md>
* Extraits Geofabrik — <https://download.geofabrik.de/europe/france.html>
* ODbL / attribution OSM — <https://www.openstreetmap.org/copyright>
* Politique d'usage des tuiles OSM —
  <https://operations.osmfoundation.org/policies/tiles/>
* Noto Sans, licence SIL OFL 1.1 — <https://github.com/google/fonts>
* Natural Earth (domaine public) et water polygons OSM, telecharges par
  Planetiler pour les basses echelles.
