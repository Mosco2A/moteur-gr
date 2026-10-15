# Les couchages a moins de trente minutes du GR20 qui ne sont pas des fins d etape (tache 838)

Mesure du 15/10/2026, Hephaistos. Branche `claude/feat/838-couchages-hors-etape`,
partie de `claude/feat/837-trace-gr20`. **Lecture seule sur l application** :
aucun fichier Dart n est touche, `pubspec.yaml` n est pas modifie, rien n est
fusionne, rien n est publie. Ce lot n AJOUTE qu un outil et sa mesure.

Demande de Christophe, 15/10 18:30, verbatim : « Il faut regarder s il y a
d autres solution de couchage qui ne sont pas des etapes et a moins de 30
minutes dans un sens comme dans l autre du trace ».

## Ce qui est livre

| Fichier | Ce que c est |
|---|---|
| `tool/couchages_du_couloir.py` | Le procede, rejouable sur n importe quelle trace |
| `assets/data/gr20/couchages_hors_etape.json` | La mesure complete, couchage par couchage |
| `docs/gr20_couchages_hors_etape.md` | Le tableau en clair, genere par l outil |
| `docs/gr20_couchages_838.md` | Ce document : la methode, et ce qu elle a trouve |

## 1. Le socle, et il a ete verifie avant usage

La trace de la tache 837 : `assets/data/gr20/track.gpx`, **9 128 points,
9 128 altitudes, 183,585 km**, relation OpenStreetMap **12484370**
« GR 20 Principale », licence **ODbL**.

Les points de la trace ne suffisaient pas : il fallait leur **identifiant de
noeud OSM**, pour que le depart de chaque detour soit un objet reel et non une
coordonnee approchee. La relation a donc ete relevee a nouveau et reassemblee
avec le MEME code d assemblage que la 837 (meme ordre de membres, memes 98
inversions, meme suppression des doublons consecutifs).

**Controle : 9 128 noeuds, et un ecart maximum de 0,00 m avec la trace de la
837.** Le script refuse de continuer si le compte differe ou si l ecart depasse
1 m — autrement dit, si la relation avait bouge depuis la 837, le releve se
serait arrete au lieu de melanger deux traces.

## 2. Le constat de la 837 qui demandait a etre corrige

La tache 837 avait etabli que la relation 12484370 porte **161 chemins membres,
tous sans role** : aucune variante, **aucun acces**. C est vrai, et c est vrai
de la RELATION. Ca ne dit **rien** des sentiers alentour, et la tache 838 avait
raison de le pointer.

Verification faite, OpenStreetMap porte bien les acces — ailleurs. Le releve
des couchages a ramene, au passage, **dix relations d itineraire d acces** que
la relation du GR20 ne mentionne pas :

| Relation OSM | Nom |
|---|---|
| `relation/5275556` | Liaison Zicavo - Refuge de Matalza |
| `relation/10047691` | Liaison Isolaccio - Refuge de Prati |
| `relation/10047731` | Liaison Solaro - Refuge d'Asinao |
| `relation/10117790` | Chemin de Melaghja - Refuge D'Ortu di u Piobbu |
| `relation/10117791` | Chemin de Pinzu a Stramba - Refuge D'Ortu di u Piobbu |
| `relation/13793261` | Col de Bavella <-> Refuge de Paliri |
| `relation/17144985` | Boucle de la bergerie de la Scanciatella |
| `relation/17835976` | Variante Liaison Aitone - Refuge de Puscaghia |
| `relation/19457682` | Liaison Bonifatu - Refuge de Carrozzu |
| `relation/19523218` | Liaison Catastaghju - GR20 Refuge d'Usciolu |

Ces relations ne sont pas la source employee pour le calcul : elles ne couvrent
qu une poignee de refuges. Le calcul interroge **le reseau pieton du couloir
pour lui-meme** — chemins, sentiers, pistes, escaliers, voies pietonnes et
petites routes — independamment de toute relation d itineraire. Les dix
relations ci-dessus sont la preuve que la question etait bonne, pas la reponse.

## 3. Le procede, en cinq etapes rejouables

`tool/couchages_du_couloir.py`, chaque etape sauvant son resultat :

1. **releve** — les couchages dans un couloir de **3 000 m** autour de la
   trace, et les noeuds OSM de la trace.
2. **reseau** — le reseau marchable dans un rayon de **4 000 m** autour de
   chaque couchage, interroge grappe par grappe.
3. **itineraires** — **Dijkstra multi-source** depuis les 9 128 noeuds de la
   trace, cout = metres horizontaux, plafond **6 000 m** de marche.
4. **altitudes** — le profil de chaque itineraire, re-echantillonne a **15 m**
   (le pas de la trace 837), altitudes du modele **EU-DEM 25 m** servi par
   `api.opentopodata.org` — le meme robinet que la trace (tache 761, memoire
   #101703 ; tache 837).
5. **rendu** — le tableau trie par point kilometrique, et le total.

**Pourquoi un couloir de 3 km alors que le seuil est de 30 minutes.** Trente
minutes a 4 km/h sans la moindre montee valent **2,0 km**. Un couchage a plus
de 2 km de marche est donc hors seuil par construction. Interroger a 3 km de
distance a vol d oiseau garantit qu aucun candidat possible n est manque : le
couloir est large de moitie en plus que ce que le seuil peut atteindre.

## 4. Le modele de temps de marche : l application en a DEUX, et ils se contredisent

La tache demandait de nommer le modele employe et de reutiliser celui de
l application. **L application en possede deux, et ils ne donnent pas le meme
chiffre.** Les deux sont calcules ici, les deux sont publies.

| | Modele 1 — celui qui decoupe les jours | Modele 2 — celui qui annonce l heure d arrivee |
|---|---|---|
| Fichier | `lib/core/models/stage_duration.dart` | `lib/features/trek/domain/eta_service.dart` |
| Nom dans le code | « Naismith simplifiee » | « Naismith raffinee » |
| A plat | `kWalkingKmPerHour = 4.0` | `defaultFlatPaceMps = 1.1` (3,96 km/h) |
| Montee | `kWalkingElevationMPerHour = 400.0` | `ascentSecondsPerMetre = 3600/600` (600 m/h) |
| Descente | **ne coute rien** | `descentSecondsPerMetre = 10/6` (~1,67 s/m) |
| Qui l emploie | `ItineraryCalculator`, `PlanningCalculator`, `PlannedDay`, la fiche d etape, l ecran d itineraire | l ETA temps reel pendant la marche |

**Le tableau emploie le modele 1**, et c est un choix qui s explique : c est lui
qui decide combien de jours fait un GR20 dans l application, donc lui qui decide
si un couchage ouvre une nuit. Le modele 2 est calcule a cote, et le JSON nomme
chaque couchage pour lequel les deux modeles ne tombent pas du meme cote du
seuil de trente minutes.

**Pourquoi l aller et le retour ne durent pas le meme temps.** Les deux modeles
facturent la montee plus cher que la descente (le modele 1 ne facture meme pas
la descente du tout). Un couchage en contrebas du sentier se rejoint donc vite
et se quitte lentement ; un couchage au-dessus, l inverse. Le denivele de
chaque sens est donne dans le tableau.

## 5. Le denivele, et une correction au filtre de la 837

La 837 avait **calibre** son filtre de denivele, pas choisi : « moyenne
glissante sur 7 points, puis un point sur 7, somme sans seuil » rend 4 263 m sur
la trace du Mare a Mare Centre quand le chiffre publie de ce sentier est
4 274 m, soit 0,26 % d ecart.

Applique tel quel a un detour de quelques centaines de metres, **ce filtre
mentait** : la moyenne glissante ecrase les deux bouts du profil. Mesure :
sur une montee reguliere de 95 m repartie en 20 points, le filtre de la 837 ne
rend que **80 m** — 16 % de perdus, et toute la perte est aux extremites. Sur
183 km cette perte vaut moins de 0,2 % et ne se voit pas ; sur un detour de
500 m qui descend dormir en vallee, elle fait passer un retour de 22 minutes a
19. Elle change la reponse.

Le filtre employe ici est donc celui de la 837 **avec les deux extremites
ancrees sur l altitude reelle**. L interieur du profil est lisse exactement
comme dans la 837 ; seuls les deux bouts cessent de mentir, et le net du detour
devient exact par construction.

**La correction a ete verifiee sur la trace complete du GR20, pour s assurer
qu elle ne casse pas la calibration de la 837** :

| | D+ | D- |
|---|---|---|
| Filtre 837 a l identique, en une passe | 11 602 m | 11 623 m |
| Filtre 837 avec les extremites ancrees | **11 603 m** | 11 628 m |
| Ecart | **+0,009 %** | +0,04 % |
| Chiffre publie par la 837 (somme des 16 etapes) | 11 602 m | 11 604 m |

La calibration tient. L ecart de 19 m sur le D- entre ma passe unique et le
chiffre de la 837 vient de ce que la 837 mesure **etape par etape** : le
lissage et la decimation repartent a chaque coupure, ce qui n est ni plus juste
ni moins juste, seulement decoupe autrement.

## 6. Trois classes, parce que la carte et l espoir ne disent pas la meme chose

Le releve brut d OpenStreetMap melange des couchages, des noms de lieux et des
ruines. Chaque objet est donc classe, et la classe est ecrite dans le JSON :

- **declare** — OpenStreetMap DIT que l on y dort : `tourism=alpine_hut`,
  `wilderness_hut`, `hotel`, `hostel`, `guest_house`, `chalet`, `apartment`,
  `motel`, `camp_site`, `caravan_site`, ou `amenity=shelter`. **Ce sont les
  seuls comptes dans le total des nouvelles nuits.**
- **nomme** — l objet existe et porte un nom de couchage (une bergerie, un
  refuge) mais **aucune etiquette de couchage**. Le cas le plus frequent est le
  `place=locality` nomme « Bergerie de ... » : c est un **lieu-dit**, pas un
  lit. Mesure et montre, **jamais compte**.
- **hors sujet** — ce n est pas un couchage : une source, une ruine, un
  panneau, un sentier, une relation d itineraire. Ecarte, et nomme dans le JSON
  avec la raison.

## 7. Quand aucun chemin ne mene au couchage, c est ecrit

La tache l exigeait noir sur blanc, et le script l applique sans exception :

- si **aucun** chemin, sentier ni piste d OpenStreetMap ne passe a moins de
  **60 m** de l objet, le couchage est marque `chemin_trace: false` avec la
  distance reelle du chemin le plus proche ;
- si un chemin existe au pied de l objet mais qu **aucune suite de chemins
  traces** ne le relie a la trace du GR20 sous 6 km de marche, c est ecrit
  aussi, et differemment — c est le symptome d une coupure de topologie dans
  OpenStreetMap, pas d une absence de sentier.

Dans les deux cas, **aucun temps n est calcule**. Pas d estimation a vol
d oiseau, pas de distance deguisee en duree.

## 8. Ce que la mesure a trouve

### Le compte

| | |
|---|---|
| Objets ramenes du couloir par Overpass | 171 |
| Ecartes parce que ce n est pas un couchage | 24 |
| Couchages retenus | **147** — 104 **declares**, 43 **nommes** sans etiquette |
| Avec un chemin trace jusqu a eux | **131** |
| **Sans chemin trace** | **16** — aucun temps calcule pour eux |
| Deja des fins d etape (ecartes du total) | **41** |
| Sous les 30 minutes dans les deux sens, hors fin d etape | 35 |
| **Nouvelles nuits possibles (endroits distincts)** | **23** |
| dont **coupures de jour NOUVELLES** | **15** |
| dont un vrai lit a la place du dortoir, au meme endroit | 6 |
| dont tetes de sentier (Calenzana, Conca) | 2 |

**Le chiffre qui compte pour la vente est 15.** C est le nombre d endroits ou
l on peut dormir, a moins de trente minutes dans chaque sens, et qui ouvrent une
coupure de jour que les seize etapes de l application n offrent pas. Les 6
autres ne changent pas le decoupage : ils remplacent un dortoir par un lit au
meme endroit du sentier, ce qui se vend aussi mais pas de la meme facon. Les 2
derniers sont Calenzana et Conca, les deux bouts : on y dort avant de partir et
apres etre arrive, pas « sur » le GR20.

### Les quinze coupures nouvelles, par point kilometrique

| PK | Ou | Lits (OSM) | Aller | Retour | Quelle etape ca coupe |
|---|---|---|---|---|---|
| 33,17 | Bergerie de Ballone | inconnu | 0 min | 1 min | E5 (6,37 km) |
| 43,49 | Bergeries de Radule (camping) | 150 pers. | 0 min | 0 min | **E6 (25,02 km)** |
| 46,77 | Castel de Vergio (hotel + refuge + camping) | 29 | 1 min | 1 min | **E6 (25,02 km)** |
| 61,34 | Bergeries de Vaccaghia + Bivouac de Vaccaghja | inconnu | 0 min | 0 min | **E6 (25,02 km)** |
| 77,90 | Bergerie de Tolla (camping) | 20 | 1 min | 1 min | E8 (9,83 km) |
| 89,16 | Hotel + Gite Monte d'Oro, La Halte du Prince | 40 | 22 min | 16 min | E9 (10,20 km) |
| 97,87 | Bivouac de Bocca Palmente | inconnu | 0 min | 0 min | **E10 (13,95 km)** |
| 98,44 | Bergeries d'Alzeta | inconnu | 1 min | 0 min | **E10 (13,95 km)** |
| 103,87 | Bergeries de Scarpaccedie | inconnu | 2 min | 1 min | **E10 (13,95 km)** |
| 113,99 | Bergerie de Gialgone | inconnu | 4 min | 2 min | **E11 (17,72 km)** |
| 118,66 | Relais San Petru di Verde + bivouac (Col de Verde) | 50 | 0 min | 0 min | **E11 (17,72 km)** |
| 129,26 | Refuge Laparo | 6 | 10 min | 28 min | E12 (10,90 km) |
| 143,52 | Bergeries de Basseta | inconnu | 1 min | 1 min | **E13 (20,73 km)** |
| 145,24 | Refuge de Matalza | inconnu | 1 min | 1 min | **E13 (20,73 km)** |
| 148,24 | Bergerie I Croci | inconnu | 0 min | 0 min | **E13 (20,73 km)** |

**Le resultat le plus utile n est pas le total, c est ou il tombe.** Les cinq
etapes les plus longues du GR20 portent **douze** des quinze coupures
nouvelles :

| Etape | Longueur | Coupures nouvelles qu elle contient |
|---|---|---|
| **E6** Ciottulu di i Mori -> Manganu | **25,02 km** | **3** — Radule (0 min), Castel de Vergio (1 min), Vaccaghja (0 min) |
| **E13** Usciolu -> Asinau | **20,73 km** | **3** — Basseta (1 min), Matalza (1 min), I Croci (0 min) |
| **E11** E Capanelle -> Prati | **17,72 km** | **2** — Gialgone (4 min), Col de Verde (0 min) |
| **E10** Vizzavona -> E Capanelle | **13,95 km** | **3** — Bocca Palmente (0 min), Alzeta (1 min), Scarpaccedie (2 min) |
| **E12** Prati -> Usciolu | **10,90 km** | **1** — Refuge Laparo (10 min aller, 28 min retour) |

Ce ne sont pas des detours. **Treize des quinze coupures sont a cinq minutes ou
moins DANS LES DEUX SENS**, douze sont a deux minutes ou moins a l aller, et
**six sont a zero minute** — la trace passe devant. Ce sont des couchages que le
decoupage en seize etapes ignore alors qu il les longe. Castel de Vergio
(29 lits, hotel + refuge + camping reunis) tombe a 8,4 km de Ciottulu dans une
etape de 25 km ; Basseta, Matalza et I Croci s egrainent au milieu de l etape de
20,7 km.

**Deux coupures seulement coutent vraiment de la marche** : l hotel et le gite
Monte d'Oro a Vizzavona (22 min aller, 16 min retour, 40 lits) et le Refuge
Laparo (10 min a l aller mais **28 minutes de remontee** — c est l asymetrie la
plus forte du releve, et elle ne se voit QUE parce que les deux sens ont ete
calcules separement).

### Les six lits a la place du dortoir

| PK | Ou | Lits | Aller | Retour | Au lieu de |
|---|---|---|---|---|---|
| 18,83 | abri sans nom (`node/13069064777`) | inconnu | 2 min | 10 min | Carozzu |
| 62,64 | Bergerie de Lenze (`amenity=shelter`) | inconnu | 24 min | 18 min | Manganu |
| 91,99 | Casa Alta | inconnu | 13 min | 16 min | Vizzavona |
| 91,99 | U Castellu | inconnu | 3 min | 2 min | Vizzavona |
| 155,10 | Bergerie d'Asinau | 20 | 5 min | 18 min | Asinau |
| 166,08 | Auberge du col de la Bavella | inconnu | 0 min | 1 min | Bavella |

### Les seize couchages SANS CHEMIN TRACE : aucun temps n a ete invente

Dix sont des lieux-dits « Bergerie de ... » (classe **nomme**), six portent une
etiquette de couchage. Pour aucun des seize, le calcul ne rend un temps.

| Nom | Chemin le plus proche de l objet | Ce qui manque |
|---|---|---|
| bergerie ciutare (`abri`) | 8 m | rien ne relie ce chemin au GR20 sous 6 km |
| Bergeries de Matone | 8 m | idem |
| Bergerie de Paratelle | 8 m | idem |
| Bergerie de Manica | 10 m | idem |
| **Chalet U Renosu** (`gite`) | 11 m | idem |
| Bergeries de Rimugeto | 42 m | idem |
| Bergeries de Monte Lati | 44 m | idem |
| **Gite de Cavu** (`gite`) | 72 m | aucun chemin a moins de 60 m de l objet |
| Bergerie de Giovannaccia | 76 m | idem |
| Bergeries de Gialicatapiano | 105 m | idem |
| **Chalet Manuella** (`gite`) | 107 m | idem |
| Bergerie de Petra Tilleri | 274 m | idem |
| Bergeries de Biciancola | 359 m | idem |
| Bergerie Coltu | 451 m | idem |
| **Bergerie de Livru** (`refuge non garde`) | 645 m | idem |
| Bergeries de Betulliccia | 920 m | idem |

Les sept premiers de cette liste ont **un chemin a leurs pieds** mais aucune
suite de chemins traces qui le relie au GR20 : c est la signature d une
**coupure de topologie dans OpenStreetMap**, pas d une absence de sentier sur le
terrain. Quatre d entre eux sont des couchages etiquetes (Chalet U Renosu, Gite
de Cavu, Chalet Manuella, Bergerie de Livru) : **ce sont les quatre endroits ou
la reponse « je ne sais pas » coute quelque chose**, et ou une verification de
terrain ou une correction d OpenStreetMap vaudrait le detour.

### Le seul cas ou les deux modeles de l application se contredisent

`node/3018297906`, un **abri sous roche** (`shelter_type=rock_shelter`) sans nom,
au PK **165,43** (juste avant le col de Bavella), 512 m de sentier et **175 m de
montee** :

| | Aller | Retour | Verdict |
|---|---|---|---|
| Modele 1, celui qui decoupe les jours | **34 min** | 8 min | **hors seuil** |
| Modele 2, celui qui annonce l heure d arrivee | 25 min | 13 min | **dans le seuil** |

Un seul couchage sur 131 bascule selon le modele, et c est un abri sous roche
sans lit : **le total de 15 ne depend donc pas du modele choisi.** C est le
controle qui compte, et il est bon.

### Le controle des fins d etape, une par une

Les **17 coupures** de la tache 837 ont ete recherchees dans le releve. **16 sur
17** ont au moins un couchage reconnu a moins de 150 m, souvent plusieurs (le
refuge, son aire de bivouac, et parfois un hotel). Le dix-septieme est **Conca**,
dont le couchage le plus proche (`Gite d'Etape La Tonnelle`) est a **197 m** du
noeud du village : il passe au-dessus du seuil de 150 m et ressort donc comme
« tete de sentier », ce qui est la bonne lecture. **Aucune fin d etape n a ete
comptee par erreur comme une nuit nouvelle.**

### Trois controles de plausibilite sur le terrain connu

| Attendu | Mesure |
|---|---|
| Castel de Vergio est sur le GR20 | PK 46,77, **71 a 107 m** de sentier, 1 a 2 min |
| Le Relais San Petru di Verde est au Col de Verde, sur le GR20 | PK 118,66, **11 m**, 0 min |
| La Bergerie de Ballone est juste sous Tighjettu | PK 33,17, **11 m**, 0 min / 1 min |

Et un controle sur la structure : **9 128 des 9 128 noeuds de la trace sont
presents dans le reseau releve**, donc aucune portion du GR20 n a ete oubliee
par les 29 requetes. **78 705 noeuds** du reseau sont atteints a moins de 6 km de
marche de la trace. **Zero altitude manquante** sur les 131 itineraires.

## 9. Les limites, dites avant qu on les trouve

- **`access=private` et `foot=no` ne sont pas filtres.** Un itineraire peut
  donc emprunter une piste privee. Sur les detours retenus la question se pose
  peu (sentiers de montagne et petites routes de village), mais elle n est pas
  tranchee par le calcul.
- **Le cout du Dijkstra est le metre horizontal, pas la minute.** L itineraire
  retenu est donc le plus COURT, pas le plus RAPIDE : un chemin legerement plus
  long mais plat pourrait etre plus rapide. Le temps est ensuite calcule sur
  l itineraire trouve, avec son vrai profil.
- **Le nombre de lits vient d OpenStreetMap et y est souvent absent.** Quand il
  manque, le tableau ecrit « inconnu » et ne devine pas.
- **Le reseau a ete releve dans un rayon de 4 km autour de chaque couchage.**
  Un itineraire qui s eloignerait de plus de 4 km du couchage pour y revenir
  serait tronque — mais un tel detour depasse de loin les trente minutes.
- **Le serveur Overpass public a sature au milieu du releve** (« This Overpass
  API server is currently at capacity »). Le script attend et reprend avec un
  repli exponentiel, comme le serveur le demande lui-meme, et chaque grappe
  relevee est mise en cache : le releve est reprenable, jamais a refaire en
  entier.
