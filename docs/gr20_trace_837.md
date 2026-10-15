# La trace du GR20, et ce qu elle dit des seize etapes (tache 837)

Mesure du 15/10/2026, Hephaistos. Branche `claude/feat/837-trace-gr20`.
Rien n est fusionne, rien n est publie, aucun fichier de l ancienne
application GR20 n est touche : ce lot ne fait qu AJOUTER une trace et sa
mesure dans StepWays.

## Ce qui est livre

| Fichier | Ce que c est |
|---|---|
| `assets/data/gr20/track.gpx` | La trace, 9 128 points, 9 128 altitudes |
| `assets/data/gr20/releve_osm.json` | De quoi elle est faite : relation, chemins, inversions, ruptures |
| `assets/data/gr20/reperes_osm.json` | Les 169 objets nommes d OpenStreetMap qui la bordent |
| `assets/data/gr20/mesure_etapes.json` | La mesure etape par etape |
| `tool/relever_la_trace_osm.py` | Le procede, rejouable : OSM + EU-DEM 25 m |
| `tool/reperes_osm.py` | Le releve des objets nommes qui bordent une relation |
| `tool/mesurer_les_etapes.py` | La mesure des etapes SUR une trace |
| `tool/coupures_gr20.json` | Les 17 coupures, ancrees sur des objets OSM nommes |

## 1. La trace

Geometrie : relation OpenStreetMap **12484370** « GR 20 Principale »
(`route=hiking`, `network=nwn`, `ref=GR 20`, `wikidata=Q262374`), licence
**ODbL**, creditee dans l en-tete GPX (`<copyright>` + `<link>` vers la
relation). Appels Overpass et opentopodata faits avec une en-tete
`User-Agent` qui identifie l appelant, comme l exige leur politique d usage.

La relation a ete **verifiee complete et continue AVANT usage** :

| | |
|---|---|
| Chemins membres | 161, tous sans role (aucune variante, aucun acces) |
| Enchainement | **0 rupture** — chaque chemin se raccorde au precedent |
| Inversions a appliquer | 98 (un chemin dessine dans l autre sens) |
| Noeuds | 9 128, **tous uniques** — aucun point parcouru deux fois |
| Longueur | **183,585 km** |
| Espacement median | 14,9 m |
| Sens | Calenzana (280 m) vers Conca (254 m), nord vers sud |

Altitudes : modele numerique de terrain **EU-DEM, resolution 25 m**, servi par
`api.opentopodata.org`. **9 128 altitudes sur 9 128 points, aucune manquante.**
C est exactement le robinet qui a altimetrise la trace du Mare a Mare Centre
(tache 761, memoire #101703) — la question « comment l autre trace a-t-elle
ete altimetrisee » avait sa reponse dans cette memoire, et aucun script
n avait ete garde ; il l est maintenant.

Avant : 8 854 points, **29 altitudes (0,33 %)**. Apres : 9 128 points,
**9 128 altitudes (100 %)**.

## 2. Le denivele : trois chiffres, pas un

Un modele a 25 m de resolution echantillonne tous les 15 m tremble. La somme
brute de ses ecarts compte le tremblement comme du relief. Le chiffre depend
donc du filtre, et donner un seul nombre serait cacher ce fait.

Le filtre retenu — moyenne glissante sur 7 points, puis un point sur 7, somme
sans seuil — **a ete calibre, pas choisi** : applique a la trace du Mare a
Mare Centre, il rend **4 263 m** quand le chiffre publie de ce sentier est
**4 274 m** (#101703), soit **0,26 % d ecart**. C est donc le procede qui
reproduit le chiffre de la maison.

| Procede | GR20 D+ | GR20 D- | Mare a Mare D+ (publie 4 274) |
|---|---|---|---|
| **Retenu** (lisse 7, un point sur 7) | **11 602 m** | **11 604 m** | 4 263 m (−0,26 %) |
| Socle de l application (seuil 3 m, sans lissage) | 12 021 m | 11 492 m | 4 111 m (−3,8 %) |
| Brut (aucun filtre) | 15 237 m | 15 262 m | 5 492 m (+28 %) |

Pour memoire, le topo FFRP annonce 12 550 m de D+ et 11 890 m de D-. Le D+
mesure est **7,5 % en dessous** de l annonce, le D- **2,4 % en dessous**.

## 3. Les seize etapes, lues SUR la trace

Les coupures ne sont pas des coordonnees saisies a la main : chacune est un
**objet OpenStreetMap nomme** (refuge, gare, village), projete sur la trace.
Les ecarts a la trace vont de 5 m (Paliri) a 181 m (gare de Vizzavona) —
aucun aberrant, contrairement aux coordonnees de l application ou le refuge
de l Onda tombait a 1 237 m et l auberge de Bavella a 2 518 m du trace.

Les points kilometriques sont ensuite **tries**, et c est le tri qui donne
l ordre reel.

| Rang reel | De → a | PK debut | PK fin | km mesures | km annonces | Ecart | D+ | D- |
|---|---|---|---|---|---|---|---|---|
| 1 | Calenzana → Ortu di u Piobbu | 0,00 | 11,35 | **11,35** | 12,8 | −1,45 (−11,3 %) | 1 453 | 194 |
| 2 | Ortu di u Piobbu → Carozzu | 11,35 | 18,69 | **7,34** | 9,1 | −1,76 (−19,3 %) | 638 | 899 |
| 3 | Carozzu → Ascu-Stagnu (Haut-Asco) | 18,69 | 23,59 | **4,91** | 8,6 | −3,69 (−42,9 %) | 768 | 584 |
| 4 | Ascu-Stagnu → Tighjettu | 23,59 | 32,00 | **8,41** | 8,6 | −0,19 (−2,2 %) | 1 162 | 921 |
| 5 | Tighjettu → Ciottulu di i Mori | 32,00 | 38,37 | **6,37** | 7,0 | −0,63 (−9,0 %) | 660 | 347 |
| 6 | Ciottulu di i Mori → Manganu | 38,37 | 63,39 | **25,02** | 16,0 | **+9,02 (+56,4 %)** | 786 | 1 190 |
| 7 | Manganu → Petra Piana | 63,39 | 71,76 | **8,37** | 10,2 | −1,83 (−17,9 %) | 818 | 523 |
| 8 | Petra Piana → l Onda | 71,76 | 81,59 | **9,83** | 10,7 | −0,87 (−8,1 %) | 438 | 906 |
| 9 | l Onda → **gare de Vizzavona** | 81,59 | **91,80** | **10,20** | 10,7 | −0,50 (−4,7 %) | 668 | 1 121 |
| 10 | Vizzavona → E Capanelle | 91,80 | 105,75 | **13,95** | 15,0 | −1,05 (−7,0 %) | 962 | 292 |
| 11 | E Capanelle → Prati | 105,75 | 123,47 | **17,72** | 13,4 | **+4,32 (+32,2 %)** | 888 | 672 |
| 12 | Prati → Usciolu | 123,47 | 134,37 | **10,90** | 12,3 | −1,40 (−11,4 %) | 652 | 699 |
| 13 | Usciolu → Asinau | 134,37 | 155,10 | **20,73** | 12,8 | **+7,93 (+62,0 %)** | 913 | 1 087 |
| 14 | Asinau → **col de Bavella** | 155,10 | 165,84 | **10,75** | — | voir §4 | 325 | 664 |
| 15 | **col de Bavella → Paliri** | 165,84 | 170,38 | **4,53** | — | voir §4 | 189 | 350 |
| 16 | Paliri → Conca | 170,38 | 183,59 | **13,21** | — | voir §4 | 299 | 1 089 |

Total mesure : **183,585 km**, contre 183,0 km annonces. Le total colle.
**Les etapes, non** : trois d entre elles s ecartent de plus de 30 %, et
l ecart le plus fort atteint +62 %. La raison est ecrite dans le code de
l application lui-meme (`gr20_stages.dart`, en-tete de `gr20Stages`) :

> « on ancre sur le TOTAL fiable : E1→E14 mises a l echelle (x1,069) pour
> porter le total a ~183 km »

Les longueurs annoncees ne sont donc pas des mesures. Ce sont des chiffres de
topo multiplies par un coefficient pour que la somme tombe juste. Toute
recomposition de journees qui s appuierait dessus heriterait de l erreur.

## 4. L ordre des trois dernieres etapes contredit la trace

Sur la trace, l ordre est **Asinau (155,10) → col de Bavella (165,84) →
Paliri (170,38) → Conca (183,59)**. L application declare Asinau → Paliri,
puis Paliri → Bavella, puis Bavella → Conca. Pose sur la trace, son
decoupage donne :

| Etape declaree | Sur la trace | Annonce | Ce que ca veut dire |
|---|---|---|---|
| E14 Asinau → Paliri | +15,28 km | 11,8 km | passe **par** Bavella sans le dire |
| E15 Paliri → col de Bavella | **−4,53 km** | 4,0 km | **marche a reculons** |
| E16 col de Bavella → Conca | +17,74 km | 20,0 km | **repasse par** Paliri |

Le marcheur qui suivrait l application couvrirait **37,55 km** pour une
section qui en fait **28,49 km** : **9,06 km parcourus deux fois**.

## 5. Vizzavona, et les deux moities

**Vizzavona est au point kilometrique 91,80 — soit 50,0 % de la trace.**
Les deux chapitres decides par Christophe le 15/10 (#101927) sont egaux a
**dix metres pres** : 91,80 km au nord, 91,79 km au sud. Ce n est pas un
arrangement, c est une propriete du sentier.

| | Nord, Calenzana → Vizzavona | Sud, Vizzavona → Conca |
|---|---|---|
| Longueur | **91,80 km** (50,0 %) | **91,79 km** (50,0 %) |
| D+ | **7 374 m** | **4 241 m** |
| D− | 6 712 m | 4 916 m |
| Jours a l allure FFRP | **9** (etapes 1 a 9) | **7** (etapes 10 a 16) |

**Le nord porte 1,74 fois le denivele positif du sud pour la meme distance.**
C est la, et pas dans les kilometres, que se lit la difficulte : les deux
moities se vendent a egalite de longueur et ne se marchent pas du tout de la
meme facon.

### Une correction a porter : le nord de l application s arrete a l Onda

`gr20_stages.dart` declare `north = 1 → 8`, commente « jusqu a Vizzavona »,
et `south = 9 → 16`, commente « depuis Vizzavona ». Or **l etape 8 se
termine au refuge de l Onda**, pas a Vizzavona : c est l etape **9** qui
arrive a la gare. Mesure : l Onda est au PK 81,59, soit **10,21 km et une
journee entiere avant Vizzavona**, a 44,4 % de la trace et non a 50 %.

Donc, si la coupe est a Vizzavona et **nulle part ailleurs** (decision du
15/10, confirmee a 17:58), le partage a l allure FFRP est **9 jours au nord
et 7 au sud**, pas 8 et 8. La memoire #101927 annoncait huit etapes de chaque
cote en lisant le commentaire du code ; le commentaire est faux, la mesure
tranche.

Cela ne deplace pas la coupe : le bon point de coupe est bien Vizzavona, et
il tombe a 50,0 % de la trace. Cela corrige seulement le nombre de journees
de chaque cote — et l allure est de toute facon un choix du marcheur
(#101930), les seize etapes n etant qu une allure parmi d autres.

## 6. Ce que je n ai pas fait, et pourquoi

- **Aucun chemin de liaison vers les vallees.** La relation 12484370 ne porte
  que des chemins **sans role** : ni `alternative`, ni `approach`, ni
  `excursion`. Elle ne contient donc aucune descente vers une vallee, et je
  n en ai pas fabrique. Le manque 2 de #101922 reste entier ; il demande
  d autres relations OSM, c est un autre lot.
- **Aucune altitude interpolee.** Le script s arrete et refuse d ecrire si une
  seule altitude manque. Il n a pas eu a s arreter : aucune ne manquait.
- **Aucun fichier de l ancienne application GR20 touche.** `gr20_stages.dart`
  et `gr20_complet_16etapes_NS.gpx` ont ete **lus**, jamais ecrits.
- **Aucune publication, aucune fusion.** Rien n est parti vers Firestore ni
  vers `main`.
