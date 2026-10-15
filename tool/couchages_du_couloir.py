#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Les couchages d un couloir autour d une trace, et le TEMPS DE MARCHE REEL pour y aller.

CE QUE CE SCRIPT REPOND. « Y a-t-il, a moins de trente minutes de marche du
sentier dans un sens comme dans l autre, des solutions de couchage qui ne sont
pas des fins d etape ? » Tache 838.

CE QU IL NE FAIT PAS. Il ne devine aucune distance a vol d oiseau. Un couchage
sans chemin trace jusqu a lui est declare SANS CHEMIN, et aucun temps n est
invente pour lui.

LE GESTE, EN CINQ ETAPES REJOUABLES (chacune sauve son resultat, donc
reprenable) :

  1. releve      : les couchages du couloir dans OpenStreetMap, et les noeuds
                   OSM de la trace elle-meme (pour que le depart du detour soit
                   un objet reel et non une coordonnee approchee).
  2. reseau      : les chemins pietons, sentiers et pistes du couloir. C EST LA
                   CORRECTION D UN CONSTAT DE LA TACHE 837 : la RELATION du GR20
                   ne porte aucun membre d acces, ce qui ne dit RIEN des
                   sentiers alentour. On les interroge donc separement.
  3. itineraires : un itineraire REEL sur ce reseau entre la trace et chaque
                   couchage (Dijkstra multi-source depuis les 9 128 noeuds de la
                   trace, cout = metres horizontaux).
  4. altitudes   : le profil de chaque itineraire, modele de terrain EU-DEM 25 m
                   servi par api.opentopodata.org — le MEME robinet que la trace
                   (tache 761, memoire #101703 ; tache 837).
  5. rendu       : le tableau trie par point kilometrique, et le total des
                   nouvelles nuits possibles.

MODELE DE TEMPS DE MARCHE : celui de l application, pas un modele invente.
`lib/core/models/stage_duration.dart` : « Naismith simplifiee »,
`kWalkingKmPerHour = 4.0` et `kWalkingElevationMPerHour = 400.0`, soit
duree = distance / 4 km/h + denivele positif / 400 m/h. Le denivele NEGATIF ne
compte pas, exactement comme dans l application : c est pourquoi l aller et le
retour d un meme detour ne durent pas le meme temps.

Licence des donnees : OpenStreetMap, ODbL. En-tete User-Agent identifiant
l appelant sur Overpass comme sur opentopodata, politique d usage des deux
services respectee (Overpass : peu de requetes, espacees ; opentopodata :
100 points par appel, un appel par seconde).

Usage :
    python tool/couchages_du_couloir.py --etape tout \
        --trace assets/data/gr20/track.gpx \
        --coupures tool/coupures_gr20.json \
        --cache .cache/838 \
        --sortie assets/data/gr20/couchages_hors_etape.json
"""

from __future__ import annotations

import argparse
import heapq
import json
import math
import os
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

OVERPASS = "https://overpass-api.de/api/interpreter"
# Les miroirs publics d Overpass, documentes sur le wiki OpenStreetMap. Le
# serveur principal a rendu 502 pendant ce releve : on change de miroir plutot
# que de marteler le meme, ce qui est aussi la politesse due au service.
MIROIRS_OVERPASS = (
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
    "https://overpass.osm.jp/api/interpreter",
)
OPENTOPODATA = "https://api.opentopodata.org/v1/eudem25m"
MODELE_TERRAIN = "EU-DEM (resolution 25 m)"
UA = "StepWays/1.0 (+https://github.com/Mosco2A/moteur-gr; christophe.mosconi@only1cent.com)"
RAYON_TERRE_M = 6371008.8

# L APPLICATION POSSEDE DEUX MODELES DE TEMPS DE MARCHE, ET ILS NE DISENT PAS
# LA MEME CHOSE. Les deux sont employes ici, et les deux sont publies : une
# seule des deux reponses serait un choix cache.
#
# MODELE 1 — celui qui DECOUPE LES JOURS. lib/core/models/stage_duration.dart,
# « Naismith simplifiee » : kWalkingKmPerHour = 4.0,
# kWalkingElevationMPerHour = 400.0, donc duree = distance / 4 km/h
# + denivele positif / 400 m/h. La DESCENTE NE COUTE RIEN. C est celui
# qu emploient ItineraryCalculator, PlanningCalculator, PlannedDay, la fiche
# d etape et l ecran d itineraire : c est donc lui qui decide combien de jours
# fait un GR20, et c est a ce titre le modele de tete de ce releve.
VITESSE_PLAT_KMH = 4.0
MONTEE_PAR_HEURE_M = 400.0
NOM_DU_MODELE = (
    "Naismith simplifiee de l application StepWays "
    "(lib/core/models/stage_duration.dart : kWalkingKmPerHour = 4.0, "
    "kWalkingElevationMPerHour = 400.0) : duree = distance / 4 km/h "
    "+ denivele positif / 400 m/h ; le denivele negatif ne compte pas"
)

# MODELE 2 — celui qui ANNONCE L HEURE D ARRIVEE EN MARCHANT.
# lib/features/trek/domain/eta_service.dart, « Naismith raffinee » :
# defaultFlatPaceMps = 1.1 m/s (3,96 km/h), ascentSecondsPerMetre = 3600/600
# (soit 600 m/h de montee, et non 400), descentSecondsPerMetre = 10/6
# (la descente COUTE, environ 1,67 s par metre descendu). Sur un detour qui
# descend en vallee puis remonte, les deux modeles divergent par construction :
# l un ignore la descente, l autre la facture.
ETA_VITESSE_PLAT_MS = 1.1
ETA_MONTEE_S_PAR_M = 3600.0 / 600.0
ETA_DESCENTE_S_PAR_M = 10.0 / 6.0
NOM_DU_MODELE_ETA = (
    "Naismith raffinee de l application StepWays "
    "(lib/features/trek/domain/eta_service.dart : defaultFlatPaceMps = 1.1 m/s, "
    "ascentSecondsPerMetre = 3600/600, descentSecondsPerMetre = 10/6) : "
    "duree = distance / 1,1 m/s + montee x 6 s/m + descente x 1,67 s/m ; "
    "la descente COUTE"
)

RELATION_GR20 = 12484370

# Rayon du couloir interroge, en metres. Trente minutes de marche a plat valent
# 2 km ; on interroge large (3 km) pour que l ECART soit mesure, pas suppose.
RAYON_COULOIR_M = 3000

# Au-dela de cette distance de reseau, on ne cherche plus : 6 km de sentier font
# au mieux 1 h 30 avec le modele de l application, donc trois fois le seuil.
PLAFOND_RESEAU_M = 6000.0

# Un couchage dont le noeud de reseau le plus proche est au-dela de cette
# distance n a PAS de chemin trace jusqu a lui. On l ecrit, on n estime pas.
RACCORD_MAX_M = 60.0

# Deux couchages a moins de cette distance l un de l autre sont le MEME endroit
# de couchage (un village, un hameau, un col) : ils n ajoutent qu une nuit.
MEME_ENDROIT_M = 400.0

# Un couchage a moins de ce nombre de metres d une fin d etape EST cette fin
# d etape (meme objet mal place, ou annexe immediate du refuge).
EST_UNE_FIN_D_ETAPE_M = 150.0

TYPES_TOURISME = (
    "alpine_hut|wilderness_hut|hotel|hostel|guest_house|chalet|apartment"
    "|motel|camp_site|caravan_site"
)

# Les genres de couchage, nommes comme Christophe les nomme.
GENRE_EN_CLAIR = {
    "alpine_hut": "refuge de montagne",
    "wilderness_hut": "refuge non garde",
    "hotel": "hotel",
    "hostel": "auberge",
    "guest_house": "chambre d hotes",
    "chalet": "gite",
    "apartment": "meuble",
    "motel": "motel",
    "camp_site": "camping",
    "caravan_site": "camping-car",
    "shelter": "abri",
    "bergerie": "bergerie",
}


# --------------------------------------------------------------------------
# Outils de base
# --------------------------------------------------------------------------

def distance_m(a, b):
    """Distance haversine en metres entre deux (lat, lon)."""
    lat1, lon1 = math.radians(a[0]), math.radians(a[1])
    lat2, lon2 = math.radians(b[0]), math.radians(b[1])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    )
    return 2 * RAYON_TERRE_M * math.asin(math.sqrt(h))


def _appel(url, corps=None, essais=5, attente_base=3, plafond_attente=120):
    """Un appel HTTP avec en-tete d identification et reprise sur erreur.

    L attente double a chaque echec, plafonnee : c est exactement ce que le
    serveur Overpass public demande dans son propre message de refus
    (« Retry your request using exponential backoff »).
    """
    dernier = None
    for tentative in range(essais):
        entetes = {"User-Agent": UA, "Accept": "application/json"}
        if corps:
            entetes["Content-Type"] = "application/json"
        requete = urllib.request.Request(url, data=corps, headers=entetes)
        try:
            with urllib.request.urlopen(requete, timeout=600) as reponse:
                return json.loads(reponse.read().decode("utf-8"))
        except Exception as err:
            dernier = err
            attente = min(attente_base * (2 ** tentative), plafond_attente)
            sys.stderr.write(
                "  (reprise %d/%d dans %ds : %s)\n" % (tentative + 1, essais, attente, err)
            )
            sys.stderr.flush()
            time.sleep(attente)
    raise SystemExit("ECHEC APPEL apres %d essais : %s" % (essais, dernier))


def overpass(requete):
    """Un appel Overpass, patient, et en changeant de miroir si besoin.

    Le serveur public rend 502 avec ce message quand il est sature : « This
    Overpass API server is currently at capacity. All query workers are busy
    and the request queue is full. Retry your request using exponential
    backoff. » C est arrive au milieu de ce releve. On attend donc longtemps
    plutot que d abandonner, et on ne martele pas : 30 tentatives espacees
    jusqu a deux minutes, soit pres d une heure de patience par requete.
    """
    arguments = urllib.parse.urlencode({"data": requete})
    dernier = None
    for miroir in MIROIRS_OVERPASS:
        try:
            return _appel(miroir + "?" + arguments, essais=30, attente_base=10)
        except SystemExit as err:
            dernier = err
            sys.stderr.write("  (miroir %s epuise, on change)\n" % miroir)
            sys.stderr.flush()
            time.sleep(10)
    raise SystemExit("Aucun miroir Overpass n a repondu : %s" % dernier)


def charger(chemin):
    with open(chemin, "r", encoding="utf-8") as f:
        return json.load(f)


def sauver(chemin, donnees):
    dossier = os.path.dirname(chemin)
    if dossier:
        os.makedirs(dossier, exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(donnees, f, ensure_ascii=False, indent=2)


# --------------------------------------------------------------------------
# La trace : ses points, ses altitudes deja mesurees, ses points kilometriques
# --------------------------------------------------------------------------

def lire_trace_gpx(chemin):
    """Rend la liste des (lat, lon, altitude) de la trace de la tache 837."""
    arbre = ET.parse(chemin)
    ns = {"g": "http://www.topografix.com/GPX/1/1"}
    points = []
    for pt in arbre.getroot().iterfind(".//g:trkpt", ns):
        ele = pt.find("g:ele", ns)
        points.append(
            (
                float(pt.get("lat")),
                float(pt.get("lon")),
                None if ele is None else float(ele.text),
            )
        )
    if not points:
        raise SystemExit("Aucun point de trace lu dans %s" % chemin)
    return points


def points_kilometriques(points):
    """Le point kilometrique cumule de chaque point de la trace."""
    pk = [0.0]
    for index in range(1, len(points)):
        pk.append(
            pk[-1]
            + distance_m(points[index - 1][:2], points[index][:2])
        )
    return pk


# --------------------------------------------------------------------------
# ETAPE 1 : le releve — les couchages du couloir, et les noeuds OSM de la trace
# --------------------------------------------------------------------------

REQUETE_COUCHAGES = """[out:json][timeout:600];
rel(%(rel)d);
way(r)->.w;
(
  nwr(around.w:%(r)d)["tourism"~"^(%(types)s)$"];
  nwr(around.w:%(r)d)["amenity"="shelter"];
  nwr(around.w:%(r)d)["building"~"^(hut|cabin|chalet|farm|farm_auxiliary|bergerie|shed)$"]["name"];
  nwr(around.w:%(r)d)["name"~"[Bb]ergeri"];
  nwr(around.w:%(r)d)["name"~"[Gg](i|î)te"];
  nwr(around.w:%(r)d)["name"~"[Rr]efug"];
);
out center tags;
"""

REQUETE_NOEUDS_TRACE = """[out:json][timeout:300];
rel(%d);
out body;
>;
out skel qt;
"""


def etape_releve(cache, trace_gpx):
    """Les couchages du couloir + les noeuds OSM de la trace, dans l ordre."""
    sys.stderr.write("[1/5] releve Overpass : les couchages du couloir (%d m)\n" % RAYON_COULOIR_M)
    brut = overpass(
        REQUETE_COUCHAGES
        % {"rel": RELATION_GR20, "r": RAYON_COULOIR_M, "types": TYPES_TOURISME}
    )
    sauver(os.path.join(cache, "couchages_brut.json"), brut)
    sys.stderr.write("      %d objets bruts\n" % len(brut.get("elements", [])))

    time.sleep(5)
    sys.stderr.write("[1/5] releve Overpass : les noeuds OSM de la trace\n")
    relation = overpass(REQUETE_NOEUDS_TRACE % RELATION_GR20)
    sauver(os.path.join(cache, "relation_brut.json"), relation)

    noeuds_trace = assembler_noeuds(relation, RELATION_GR20)
    points = lire_trace_gpx(trace_gpx)
    if len(noeuds_trace) != len(points):
        raise SystemExit(
            "La relation rend %d noeuds, la trace de la 837 en porte %d : "
            "la relation a bouge depuis la 837, il faut relever la trace a nouveau."
            % (len(noeuds_trace), len(points))
        )
    pk = points_kilometriques(points)
    ecart_max = 0.0
    trace = []
    for index, (noeud_id, lat, lon) in enumerate(noeuds_trace):
        ecart = distance_m((lat, lon), points[index][:2])
        ecart_max = max(ecart_max, ecart)
        trace.append(
            {
                "i": index,
                "noeud": noeud_id,
                "lat": lat,
                "lon": lon,
                "ele": points[index][2],
                "pk_m": round(pk[index], 1),
            }
        )
    if ecart_max > 1.0:
        raise SystemExit(
            "Les noeuds de la relation s ecartent de la trace de la 837 de %.1f m : "
            "ce ne sont plus les memes points." % ecart_max
        )
    sauver(os.path.join(cache, "trace_noeuds.json"), trace)
    sys.stderr.write(
        "      %d noeuds de trace, ecart max avec la trace 837 = %.2f m\n"
        % (len(trace), ecart_max)
    )
    return trace


def assembler_noeuds(donnees, relation_id):
    """Les noeuds de la relation, dans l ordre, avec leur identifiant OSM.

    Reprend mot pour mot l assemblage de tool/relever_la_trace_osm.py (tache
    837) : meme ordre de membres, memes inversions, meme suppression des
    doublons consecutifs. Doit donc rendre EXACTEMENT les memes points.
    """
    elements = donnees.get("elements", [])
    coord = dict((e["id"], (e["lat"], e["lon"])) for e in elements if e["type"] == "node")
    chemins = dict((e["id"], e["nodes"]) for e in elements if e["type"] == "way")
    relation = None
    for e in elements:
        if e["type"] == "relation" and e["id"] == relation_id:
            relation = e
            break
    if relation is None:
        raise SystemExit("Relation %d absente de la reponse Overpass." % relation_id)

    membres = [m for m in relation["members"] if m["type"] == "way"]
    suite = []
    for membre in membres:
        ids = chemins.get(membre["ref"])
        if not ids:
            continue
        ids = list(ids)
        if not suite:
            suite = ids
            continue
        if suite[-1] == ids[0]:
            suite.extend(ids[1:])
        elif suite[-1] == ids[-1]:
            suite.extend(list(reversed(ids))[1:])
        else:
            ecart = distance_m(coord[suite[-1]], coord[ids[0]])
            ecart_inv = distance_m(coord[suite[-1]], coord[ids[-1]])
            if ecart_inv < ecart:
                ids = list(reversed(ids))
            suite.extend(ids)

    propres = []
    for noeud_id in suite:
        if noeud_id not in coord:
            continue
        if propres and coord[propres[-1]] == coord[noeud_id]:
            continue
        propres.append(noeud_id)
    return [(n, coord[n][0], coord[n][1]) for n in propres]


# --------------------------------------------------------------------------
# Les couchages : lecture des objets bruts, nommage, lits
# --------------------------------------------------------------------------

def lits_connus(tags):
    """Le nombre de lits quand OpenStreetMap le dit, sinon None."""
    for cle in ("beds", "capacity:persons", "capacity", "rooms", "tents"):
        valeur = tags.get(cle)
        if not valeur:
            continue
        chiffres = "".join(c for c in str(valeur) if c.isdigit())
        if chiffres:
            nombre = int(chiffres)
            if cle == "rooms":
                return nombre, "chambres"
            if cle == "tents":
                return nombre, "emplacements"
            return nombre, "lits"
    return None, None


TOURISMES_COUCHAGE = (
    "alpine_hut",
    "wilderness_hut",
    "hotel",
    "hostel",
    "guest_house",
    "chalet",
    "apartment",
    "motel",
    "camp_site",
    "caravan_site",
)

# Un abri de bus ou un abri a pique-nique n est pas un couchage.
ABRIS_SANS_COUCHAGE = (
    "public_transport",
    "picnic_shelter",
    "sun_shelter",
    "field_shelter",
    "gazebo",
)


def classer(tags, type_osm):
    """Trois classes, et la raison en clair. C EST LA REGLE DU RENDU.

    « declare » : OpenStreetMap DIT que l on y dort (tourism=refuge, hotel,
        camping, gite, abri de montagne...). Ce sont les SEULS que je compte
        dans le total des nouvelles nuits.
    « nomme »   : l objet existe et porte un nom de couchage (une bergerie, un
        refuge sans etiquette), mais OpenStreetMap NE DIT PAS que l on y dort.
        Je le mesure et je le montre, je ne le compte pas. C est la difference
        entre ce que la carte affirme et ce que l on espere.
    « hors sujet » : ce n est pas un couchage du tout (une source, une ruine,
        un panneau, un sentier, une relation d itineraire).
    """
    nom = tags.get("name") or ""
    bas = nom.lower()
    tourisme = tags.get("tourism")
    amenite = tags.get("amenity")
    batiment = tags.get("building")

    # --- hors sujet, par ordre de certitude ---
    if type_osm == "relation" and not tourisme:
        return "hors_sujet", None, "relation d itineraire, pas un couchage"
    if tags.get("natural") in ("spring", "water", "peak", "saddle"):
        return "hors_sujet", None, "objet naturel (%s)" % tags["natural"]
    if tags.get("highway"):
        return "hors_sujet", None, "un chemin (highway=%s), pas un couchage" % tags["highway"]
    if tourisme == "information":
        return "hors_sujet", None, "panneau d information"
    if tags.get("historic") in ("ruins",) or batiment == "ruins" or tags.get("ruins") == "yes":
        return "hors_sujet", None, "ruine : on n y dort pas"
    if batiment == "construction" or tags.get("construction"):
        return "hors_sujet", None, "en construction"
    if any(tags.get(c) for c in ("disused:tourism", "abandoned:tourism", "was:tourism")):
        return "hors_sujet", None, "hors service"
    if tourisme in ("camp_pitch",):
        return "hors_sujet", None, "emplacement a l interieur d un camping deja compte"

    # --- declare ---
    if tourisme in TOURISMES_COUCHAGE:
        return "declare", tourisme, "tourism=%s" % tourisme
    if amenite == "shelter":
        if tags.get("shelter_type") in ABRIS_SANS_COUCHAGE:
            return "hors_sujet", None, "abri ou l on ne dort pas (%s)" % tags["shelter_type"]
        return "declare", "shelter", "amenity=shelter%s" % (
            " (%s)" % tags["shelter_type"] if tags.get("shelter_type") else ""
        )

    # --- nomme, mais OSM ne declare aucun couchage ---
    if amenite in ("restaurant", "bar", "fast_food", "pub", "cafe"):
        return (
            "nomme",
            "bergerie" if "bergeri" in bas else "restauration",
            "amenity=%s : on y mange, OpenStreetMap ne dit rien d un couchage" % amenite,
        )
    if "bergeri" in bas:
        if tags.get("place"):
            return (
                "nomme",
                "bergerie",
                "place=%s : un LIEU-DIT nomme bergerie, aucune etiquette de couchage" % tags["place"],
            )
        return (
            "nomme",
            "bergerie",
            "batiment nomme bergerie (building=%s), aucune etiquette de couchage" % (batiment or "absent"),
        )
    if "refug" in bas:
        return "nomme", "alpine_hut", "nom de refuge sans aucune etiquette de couchage"
    if "gite" in bas or "gîte" in bas:
        return "nomme", "chalet", "nom de gite sans aucune etiquette de couchage"
    if batiment in ("hut", "cabin"):
        return "nomme", "shelter", "building=%s sans etiquette de couchage" % batiment
    if batiment in ("chalet",):
        return "nomme", "chalet", "building=chalet sans etiquette de couchage"
    return "hors_sujet", None, "aucune etiquette de couchage, aucun nom de couchage"


def couchages_lisibles(brut):
    """Les objets bruts d Overpass, ramenes a trois listes classees."""
    retenus = []
    ecartes = []
    for e in brut.get("elements", []):
        tags = e.get("tags", {})
        nom = tags.get("name") or tags.get("operator")
        if e["type"] == "node":
            lat, lon = e.get("lat"), e.get("lon")
        else:
            centre = e.get("center") or {}
            lat, lon = centre.get("lat"), centre.get("lon")
        if lat is None or lon is None:
            continue
        identifiant = "%s/%s" % (e["type"], e["id"])
        classe, genre, pourquoi = classer(tags, e["type"])
        if classe == "hors_sujet":
            ecartes.append(
                {"osm": identifiant, "nom": nom, "pourquoi": pourquoi}
            )
            continue
        nombre, unite = lits_connus(tags)
        retenus.append(
            {
                "osm": identifiant,
                "nom": nom or "(sans nom dans OpenStreetMap)",
                "anonyme": nom is None,
                "classe": classe,
                "classe_pourquoi": pourquoi,
                "genre": genre,
                "genre_en_clair": GENRE_EN_CLAIR.get(genre, genre),
                "lat": lat,
                "lon": lon,
                "lits": nombre,
                "unite_lits": unite,
                "tags_utiles": dict(
                    (c, tags[c])
                    for c in (
                        "tourism",
                        "amenity",
                        "building",
                        "place",
                        "shelter_type",
                        "beds",
                        "capacity",
                        "capacity:persons",
                        "rooms",
                        "tents",
                        "ele",
                        "website",
                        "phone",
                        "reservation",
                        "operator",
                    )
                    if c in tags
                ),
            }
        )
    return retenus, ecartes


# --------------------------------------------------------------------------
# ETAPE 2 : le reseau — les chemins pietons, sentiers et pistes du couloir
# --------------------------------------------------------------------------

# Ce que l on accepte de marcher. Pas d autoroute, pas de voie rapide : un
# randonneur qui descend dormir en vallee emprunte sentier, piste ou petite
# route, et c est tout.
HIGHWAYS_MARCHABLES = (
    "path|footway|track|bridleway|steps|pedestrian|living_street|residential"
    "|unclassified|service|tertiary|secondary|primary|road|cycleway"
)

REQUETE_RESEAU = """[out:json][timeout:600];
way(around:%(r)d%(points)s)["highway"~"^(%(hw)s)$"];
out body;
>;
out skel qt;
"""


def grappes(couchages, pas_m=4000.0):
    """Regroupe les couchages en grappes geographiques, pour interroger moins."""
    restants = list(couchages)
    lot = []
    while restants:
        tete = restants.pop(0)
        groupe = [tete]
        autres = []
        for c in restants:
            if distance_m((tete["lat"], tete["lon"]), (c["lat"], c["lon"])) <= pas_m:
                groupe.append(c)
            else:
                autres.append(c)
        restants = autres
        lot.append(groupe)
    return lot


def etape_reseau(cache, couchages, rayon_m=4000):
    """Interroge Overpass grappe par grappe, et fusionne en un seul reseau.

    C EST ICI QUE LE CONSTAT DE LA 837 EST CORRIGE. La tache 837 avait etabli
    que la relation 12484370 ne porte AUCUN membre de role « acces » : ses 161
    chemins sont tous le fil principal. Ca ne dit rien des sentiers qui mènent
    AILLEURS. On interroge donc le reseau pieton du couloir pour lui-meme.
    """
    lots = grappes(couchages)
    sys.stderr.write(
        "[2/5] reseau : %d couchages regroupes en %d grappes, rayon %d m\n"
        % (len(couchages), len(lots), rayon_m)
    )
    noeuds = {}
    aretes = {}
    chemins_vus = set()
    for rang, groupe in enumerate(lots, 1):
        fichier = os.path.join(cache, "reseau_%03d.json" % rang)
        if os.path.exists(fichier):
            brut = charger(fichier)
        else:
            points = "".join(",%.6f,%.6f" % (c["lat"], c["lon"]) for c in groupe)
            brut = overpass(
                REQUETE_RESEAU
                % {"r": rayon_m, "points": points, "hw": HIGHWAYS_MARCHABLES}
            )
            sauver(fichier, brut)
            time.sleep(4)
        n_av = len(noeuds)
        for e in brut.get("elements", []):
            if e["type"] == "node":
                noeuds[e["id"]] = (e["lat"], e["lon"])
        for e in brut.get("elements", []):
            if e["type"] != "way" or e["id"] in chemins_vus:
                continue
            chemins_vus.add(e["id"])
            ids = e.get("nodes", [])
            for a, b in zip(ids, ids[1:]):
                if a == b:
                    continue
                cle = (a, b) if a < b else (b, a)
                aretes[cle] = e["id"]
        sys.stderr.write(
            "      grappe %d/%d : %d objets, +%d noeuds (total %d noeuds, %d aretes)\n"
            % (rang, len(lots), len(brut.get("elements", [])), len(noeuds) - n_av, len(noeuds), len(aretes))
        )
        sys.stderr.flush()
    return noeuds, aretes, chemins_vus


# --------------------------------------------------------------------------
# ETAPE 3 : les itineraires — Dijkstra multi-source depuis la trace
# --------------------------------------------------------------------------

def construire_graphe(noeuds, aretes):
    """Liste d adjacence { noeud : [(voisin, metres), ...] }."""
    graphe = {}
    for (a, b) in aretes:
        if a not in noeuds or b not in noeuds:
            continue
        d = distance_m(noeuds[a], noeuds[b])
        graphe.setdefault(a, []).append((b, d))
        graphe.setdefault(b, []).append((a, d))
    return graphe


def dijkstra_depuis_la_trace(graphe, noeuds_trace, plafond_m):
    """Le plus court chemin REEL depuis N IMPORTE QUEL point de la trace.

    Cout = metres horizontaux sur le reseau. Les 9 128 noeuds de la trace
    partent a zero : le chemin trouve quitte donc la trace au bon endroit, et
    `source` dit lequel.
    """
    dist = {}
    source = {}
    parent = {}
    tas = []
    for noeud_id in noeuds_trace:
        if noeud_id in graphe:
            dist[noeud_id] = 0.0
            source[noeud_id] = noeud_id
            parent[noeud_id] = None
            heapq.heappush(tas, (0.0, noeud_id))
    while tas:
        d, n = heapq.heappop(tas)
        if d > dist.get(n, float("inf")) + 1e-9:
            continue
        if d > plafond_m:
            continue
        for voisin, poids in graphe.get(n, ()):
            nd = d + poids
            if nd < dist.get(voisin, float("inf")) - 1e-9 and nd <= plafond_m:
                dist[voisin] = nd
                source[voisin] = source[n]
                parent[voisin] = n
                heapq.heappush(tas, (nd, voisin))
    return dist, source, parent


PAS_GRILLE = 0.005  # environ 550 m de cote : une case suffit pour chercher pres


def grille_des_noeuds(noeuds, graphe):
    """Un index par cases de 0,005 degre, pour ne pas balayer 300 000 noeuds."""
    index = {}
    for noeud_id in graphe:
        lat, lon = noeuds[noeud_id]
        index.setdefault(
            (int(lat / PAS_GRILLE), int(lon / PAS_GRILLE)), []
        ).append(noeud_id)
    return index


def raccord(couchage, noeuds, index):
    """Le noeud de reseau le plus proche du couchage, et sa distance.

    On elargit la recherche case par case jusqu a trouver, et on garde une
    marge d une case de plus pour que le plus proche ne soit pas rate au bord.
    """
    cible = (couchage["lat"], couchage["lon"])
    ci, cj = int(cible[0] / PAS_GRILLE), int(cible[1] / PAS_GRILLE)
    meilleur, meilleure = None, float("inf")
    for anneau in range(0, 20):
        for i in range(ci - anneau, ci + anneau + 1):
            for j in range(cj - anneau, cj + anneau + 1):
                if anneau and max(abs(i - ci), abs(j - cj)) != anneau:
                    continue
                for noeud_id in index.get((i, j), ()):
                    d = distance_m(noeuds[noeud_id], cible)
                    if d < meilleure:
                        meilleur, meilleure = noeud_id, d
        if meilleur is not None and anneau >= 1:
            break
    return meilleur, meilleure


def chemin_remonte(parent, arrivee):
    """La suite de noeuds de la trace jusqu a l arrivee."""
    suite = []
    n = arrivee
    while n is not None:
        suite.append(n)
        n = parent.get(n)
    suite.reverse()
    return suite


# --------------------------------------------------------------------------
# ETAPE 4 : les altitudes des itineraires, et le denivele
# --------------------------------------------------------------------------

def reechantillonner(points, pas_m=15.0):
    """Re-echantillonne une polyligne a pas constant (15 m, comme la trace 837)."""
    if len(points) < 2:
        return list(points)
    sortie = [points[0]]
    reste = 0.0
    for a, b in zip(points, points[1:]):
        segment = distance_m(a, b)
        if segment <= 0:
            continue
        parcouru = pas_m - reste
        while parcouru < segment:
            t = parcouru / segment
            sortie.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
            parcouru += pas_m
        reste = segment - (parcouru - pas_m)
    if distance_m(sortie[-1], points[-1]) > 1.0:
        sortie.append(points[-1])
    return sortie


def altimetriser(points, cache_fichier, paquet=100):
    """Altitudes EU-DEM 25 m, avec un cache sur disque pour ne pas re-appeler."""
    cache = charger(cache_fichier) if os.path.exists(cache_fichier) else {}
    manquants = []
    for lat, lon in points:
        cle = "%.5f,%.5f" % (lat, lon)
        if cle not in cache:
            manquants.append((cle, lat, lon))
    uniques = {}
    for cle, lat, lon in manquants:
        uniques[cle] = (lat, lon)
    a_demander = list(uniques.items())
    total = (len(a_demander) + paquet - 1) // paquet
    sys.stderr.write(
        "[4/5] altitudes : %d points a demander (%d deja en cache), %d appels\n"
        % (len(a_demander), len(cache), total)
    )
    for index in range(0, len(a_demander), paquet):
        tranche = a_demander[index : index + paquet]
        corps = json.dumps(
            {"locations": "|".join("%s,%s" % (lat, lon) for _, (lat, lon) in tranche)}
        ).encode("utf-8")
        reponse = _appel(OPENTOPODATA, corps=corps)
        if reponse.get("status") != "OK":
            raise SystemExit("opentopodata a repondu %s" % reponse.get("status"))
        for (cle, _), resultat in zip(tranche, reponse["results"]):
            valeur = resultat.get("elevation")
            cache[cle] = None if valeur is None else round(float(valeur), 1)
        sauver(cache_fichier, cache)
        sys.stderr.write("      %d/%d\n" % (index // paquet + 1, total))
        sys.stderr.flush()
        time.sleep(1.05)
    return cache


def denivele_maison(altitudes, fenetre=7, pas=7, ancrer=True):
    """Le filtre de la maison : moyenne glissante sur 7 points, puis un sur 7.

    Calibre en tache 837 sur la trace du Mare a Mare Centre : rend 4 263 m
    quand le chiffre publie de ce sentier est 4 274 m (0,26 pour cent d ecart).
    Employe ici sur un echantillonnage a 15 m lui aussi identique, pour que les
    chiffres de la 838 restent comparables a ceux de la 837.

    UNE CORRECTION, ET POURQUOI ELLE ETAIT NECESSAIRE. La moyenne glissante
    ecrase les DEUX BOUTS du profil : sur une montee reguliere de 95 m en 20
    points, le filtre de la 837 ne rend que 80 m, soit 16 pour cent de perdus,
    et toute la perte est aux extremites. Sur une trace de 183 km cette perte
    vaut moins de 0,2 pour cent et ne se voit pas. Sur un detour de 500 m qui
    descend dormir en vallee, elle fait passer un retour de 22 minutes a 19 :
    elle change la reponse. `ancrer` remet donc la PREMIERE et la DERNIERE
    altitude a leur valeur reelle avant de sommer. L interieur du profil est
    lisse exactement comme dans la 837 ; seuls les deux bouts cessent de
    mentir, et le net du detour est alors exact par construction.
    """
    propres = [a for a in altitudes if a is not None]
    if len(propres) < 2:
        return 0, 0
    if len(propres) >= fenetre:
        lisse = []
        for i in range(len(propres)):
            debut = max(0, i - fenetre // 2)
            fin = min(len(propres), i + fenetre // 2 + 1)
            lisse.append(sum(propres[debut:fin]) / (fin - debut))
        if ancrer:
            lisse[0] = propres[0]
            lisse[-1] = propres[-1]
        echantillon = lisse[::pas]
        if echantillon[-1] != lisse[-1]:
            echantillon.append(lisse[-1])
    else:
        echantillon = propres
    plus = moins = 0.0
    for a, b in zip(echantillon, echantillon[1:]):
        if b > a:
            plus += b - a
        else:
            moins += a - b
    return int(round(plus)), int(round(moins))


def denivele_brut(altitudes):
    propres = [a for a in altitudes if a is not None]
    plus = moins = 0.0
    for a, b in zip(propres, propres[1:]):
        if b > a:
            plus += b - a
        else:
            moins += a - b
    return int(round(plus)), int(round(moins))


def minutes_de_marche(distance_m_, denivele_plus_m):
    """MODELE 1 : celui qui decoupe les jours (stage_duration.dart)."""
    heures = (distance_m_ / 1000.0) / VITESSE_PLAT_KMH + denivele_plus_m / MONTEE_PAR_HEURE_M
    return int(round(heures * 60))


def minutes_eta(distance_m_, denivele_plus_m, denivele_moins_m):
    """MODELE 2 : celui qui annonce l heure d arrivee (eta_service.dart)."""
    secondes = (
        distance_m_ / ETA_VITESSE_PLAT_MS
        + denivele_plus_m * ETA_MONTEE_S_PAR_M
        + denivele_moins_m * ETA_DESCENTE_S_PAR_M
    )
    return int(round(secondes / 60.0))


def en_clair(minutes):
    h, m = divmod(max(0, int(minutes)), 60)
    return "%dh%02d" % (h, m) if h else "%d min" % m


# --------------------------------------------------------------------------
# Le programme
# --------------------------------------------------------------------------

def main():
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--trace", required=True)
    arg.add_argument("--coupures", required=True)
    arg.add_argument("--cache", required=True)
    arg.add_argument("--sortie", required=True)
    arg.add_argument(
        "--etape",
        default="tout",
        choices=("releve", "reseau", "itineraires", "altitudes", "rendu", "tout"),
    )
    arg.add_argument("--seuil-minutes", type=int, default=30)
    arg.add_argument("--markdown", default=None, help="le tableau en clair, en plus du JSON")
    options = arg.parse_args()
    os.makedirs(options.cache, exist_ok=True)

    faire = (
        ("releve", "reseau", "itineraires", "altitudes", "rendu")
        if options.etape == "tout"
        else (options.etape,)
    )

    # --- 1. releve ---------------------------------------------------------
    f_trace = os.path.join(options.cache, "trace_noeuds.json")
    if "releve" in faire:
        etape_releve(options.cache, options.trace)
    trace = charger(f_trace)
    brut = charger(os.path.join(options.cache, "couchages_brut.json"))
    couchages, ecartes = couchages_lisibles(brut)
    sys.stderr.write(
        "      %d couchages retenus, %d objets ecartes\n" % (len(couchages), len(ecartes))
    )

    # --- 2. reseau ---------------------------------------------------------
    if "reseau" in faire or "itineraires" in faire:
        noeuds, aretes, chemins = etape_reseau(options.cache, couchages)
        graphe = construire_graphe(noeuds, aretes)
        sys.stderr.write(
            "      reseau : %d chemins, %d noeuds, %d aretes, %d noeuds relies\n"
            % (len(chemins), len(noeuds), len(aretes), len(graphe))
        )

    # --- 3. itineraires ----------------------------------------------------
    f_itin = os.path.join(options.cache, "itineraires.json")
    if "itineraires" in faire:
        par_noeud = dict((t["noeud"], t) for t in trace)
        dans_le_graphe = [n for n in par_noeud if n in graphe]
        sys.stderr.write(
            "[3/5] itineraires : %d des %d noeuds de la trace sont dans le reseau\n"
            % (len(dans_le_graphe), len(trace))
        )
        dist, source, parent = dijkstra_depuis_la_trace(
            graphe, list(par_noeud.keys()), PLAFOND_RESEAU_M
        )
        sys.stderr.write("      %d noeuds atteints sous %d m\n" % (len(dist), PLAFOND_RESEAU_M))
        index = grille_des_noeuds(noeuds, graphe)
        resultats = []
        for rang, c in enumerate(couchages, 1):
            noeud, ecart = raccord(c, noeuds, index)
            fiche = dict(c)
            fiche["raccord_noeud"] = noeud
            fiche["raccord_ecart_m"] = round(ecart, 1)
            if ecart > RACCORD_MAX_M:
                fiche["chemin_trace"] = False
                fiche["pourquoi"] = (
                    "aucun chemin, sentier ni piste d OpenStreetMap ne passe a moins de "
                    "%d m de cet objet (le plus proche est a %.0f m)" % (RACCORD_MAX_M, ecart)
                )
            elif noeud not in dist:
                fiche["chemin_trace"] = False
                fiche["pourquoi"] = (
                    "un chemin existe au pied de l objet mais AUCUNE suite de chemins "
                    "traces ne le relie a la trace du GR20 sous %d m de marche"
                    % PLAFOND_RESEAU_M
                )
            else:
                suite = chemin_remonte(parent, noeud)
                depart = par_noeud[source[noeud]]
                fiche["chemin_trace"] = True
                fiche["longueur_reseau_m"] = round(dist[noeud], 1)
                fiche["pk_m"] = depart["pk_m"]
                fiche["depart_noeud"] = depart["noeud"]
                fiche["depart_lat"] = depart["lat"]
                fiche["depart_lon"] = depart["lon"]
                fiche["depart_ele"] = depart["ele"]
                fiche["noeuds_du_chemin"] = suite
                fiche["geometrie"] = [list(noeuds[n]) for n in suite]
            resultats.append(fiche)
            if rang % 20 == 0:
                sys.stderr.write("      %d/%d raccordes\n" % (rang, len(couchages)))
                sys.stderr.flush()
        sauver(f_itin, {"itineraires": resultats, "ecartes": ecartes})

    # --- 4. altitudes ------------------------------------------------------
    f_profils = os.path.join(options.cache, "profils.json")
    if "altitudes" in faire:
        itin = charger(f_itin)["itineraires"]
        a_demander = []
        echantillons = {}
        for c in itin:
            if not c.get("chemin_trace"):
                continue
            geo = [tuple(p) for p in c["geometrie"]]
            # Le dernier metre : du noeud de raccord a l objet lui-meme.
            if c["raccord_ecart_m"] > 1.0:
                geo.append((c["lat"], c["lon"]))
            ech = reechantillonner(geo, 15.0)
            echantillons[c["osm"]] = ech
            a_demander.extend(ech)
        cache_alt = altimetriser(
            a_demander, os.path.join(options.cache, "altitudes_cache.json")
        )
        profils = {}
        for osm, ech in echantillons.items():
            alts = [cache_alt.get("%.5f,%.5f" % (lat, lon)) for lat, lon in ech]
            profils[osm] = {
                "points": len(ech),
                "altitudes": alts,
                "manquantes": sum(1 for a in alts if a is None),
            }
        sauver(f_profils, profils)

    # --- 5. rendu ----------------------------------------------------------
    if "rendu" in faire:
        rendu(options, trace, f_itin, f_profils, ecartes)


def rendu(options, trace, f_itin, f_profils, ecartes):
    itin = charger(f_itin)["itineraires"]
    profils = charger(f_profils)
    coupures = charger(options.coupures)

    lignes = []
    for c in itin:
        fiche = dict(c)
        fiche.pop("noeuds_du_chemin", None)
        fiche.pop("geometrie", None)

        # Est-ce deja une fin d etape ?
        deja = None
        for coupure in coupures:
            d = distance_m((c["lat"], c["lon"]), (coupure["lat"], coupure["lon"]))
            if d <= EST_UNE_FIN_D_ETAPE_M:
                deja = {
                    "nom": coupure["nom"],
                    "etape_app": coupure["etape_app"],
                    "ecart_m": round(d, 1),
                }
                break
        fiche["deja_une_fin_d_etape"] = deja

        if c.get("chemin_trace"):
            profil = profils.get(c["osm"], {})
            alts = profil.get("altitudes", [])
            d_plus, d_moins = denivele_maison(alts)
            b_plus, b_moins = denivele_brut(alts)
            longueur = c["longueur_reseau_m"] + (
                c["raccord_ecart_m"] if c["raccord_ecart_m"] > 1.0 else 0.0
            )
            fiche["longueur_totale_m"] = round(longueur, 1)
            fiche["altitudes_manquantes"] = profil.get("manquantes", 0)
            fiche["dplus_aller_m"] = d_plus
            fiche["dmoins_aller_m"] = d_moins
            fiche["dplus_retour_m"] = d_moins
            fiche["dmoins_retour_m"] = d_plus
            fiche["dplus_aller_brut_m"] = b_plus
            fiche["dmoins_aller_brut_m"] = b_moins
            fiche["minutes_aller"] = minutes_de_marche(longueur, d_plus)
            fiche["minutes_retour"] = minutes_de_marche(longueur, d_moins)
            fiche["minutes_aller_brut"] = minutes_de_marche(longueur, b_plus)
            fiche["minutes_retour_brut"] = minutes_de_marche(longueur, b_moins)
            fiche["minutes_aller_eta"] = minutes_eta(longueur, d_plus, d_moins)
            fiche["minutes_retour_eta"] = minutes_eta(longueur, d_moins, d_plus)
            fiche["sous_le_seuil"] = (
                fiche["minutes_aller"] <= options.seuil_minutes
                and fiche["minutes_retour"] <= options.seuil_minutes
            )
            fiche["sous_le_seuil_brut"] = (
                fiche["minutes_aller_brut"] <= options.seuil_minutes
                and fiche["minutes_retour_brut"] <= options.seuil_minutes
            )
            fiche["sous_le_seuil_eta"] = (
                fiche["minutes_aller_eta"] <= options.seuil_minutes
                and fiche["minutes_retour_eta"] <= options.seuil_minutes
            )
        else:
            fiche["sous_le_seuil"] = False
            fiche["sous_le_seuil_brut"] = False
            fiche["sous_le_seuil_eta"] = False
        lignes.append(fiche)

    lignes.sort(key=lambda l: (l.get("pk_m") is None, l.get("pk_m") or 0.0, l["nom"]))

    # Les nouvelles nuits : un couchage DECLARE par OpenStreetMap, sous le
    # seuil, qui n est pas deja une fin d etape. Deux couchages au MEME endroit
    # ne font qu une nuit de plus.
    gagnants = [
        l
        for l in lignes
        if l["sous_le_seuil"]
        and not l["deja_une_fin_d_etape"]
        and l["classe"] == "declare"
    ]
    endroits = []
    for l in gagnants:
        place = None
        for e in endroits:
            if distance_m((l["lat"], l["lon"]), (e["lat"], e["lon"])) <= MEME_ENDROIT_M:
                place = e
                break
        if place is None:
            endroits.append(
                {
                    "lat": l["lat"],
                    "lon": l["lon"],
                    "pk_km": round(l["pk_m"] / 1000.0, 3),
                    "couchages": [l["nom"]],
                    "genres": [l["genre_en_clair"]],
                    "lits": l["lits"] or 0,
                    "minutes_aller": l["minutes_aller"],
                    "minutes_retour": l["minutes_retour"],
                }
            )
        else:
            place["couchages"].append(l["nom"])
            place["genres"].append(l["genre_en_clair"])
            place["lits"] += l["lits"] or 0
            place["minutes_aller"] = min(place["minutes_aller"], l["minutes_aller"])
            place["minutes_retour"] = min(place["minutes_retour"], l["minutes_retour"])

    # LA NUANCE QUI COMPTE POUR LA VENTE. Un couchage a 300 m de point
    # kilometrique d un refuge de fin d etape n ouvre pas un nouveau DECOUPAGE :
    # il offre un vrai lit a la place du dortoir, au meme endroit du sentier.
    # Un couchage loin de toute fin d etape, lui, ouvre une coupure de jour qui
    # n existait pas. Les deux se vendent, mais pas la meme chose.
    pk_des_fins = []
    for coupure in coupures:
        meilleur = min(
            trace, key=lambda t: distance_m((t["lat"], t["lon"]), (coupure["lat"], coupure["lon"]))
        )
        pk_des_fins.append((meilleur["pk_m"], coupure["nom"], coupure["etape_app"]))
    for e in endroits:
        pk_m, nom_fin, etape_fin = min(
            pk_des_fins, key=lambda p: abs(e["pk_km"] * 1000.0 - p[0])
        )
        ecart = abs(e["pk_km"] * 1000.0 - pk_m)
        e["fin_d_etape_la_plus_proche"] = nom_fin
        e["ecart_pk_a_cette_fin_d_etape_km"] = round(ecart / 1000.0, 3)
        if ecart > 1000.0:
            e["ce_que_ca_ouvre"] = "une coupure de jour NOUVELLE"
        elif etape_fin in ("depart", "fin E16"):
            e["ce_que_ca_ouvre"] = "une tete de sentier, pas une nuit sur le sentier"
        else:
            e["ce_que_ca_ouvre"] = "un vrai lit a la place du dortoir, au meme endroit du sentier"
    # La meme lecture, reportee sur CHAQUE couchage, pour que la colonne
    # « statut » du tableau ne dise pas « nouvelle nuit » d un hotel de
    # Calenzana, qui est le depart du sentier et pas une nuit de plus.
    for l in lignes:
        l["ce_que_ca_ouvre"] = None
        if not (l["sous_le_seuil"] and not l["deja_une_fin_d_etape"]
                and l["classe"] == "declare"):
            continue
        for e in endroits:
            if distance_m((l["lat"], l["lon"]), (e["lat"], e["lon"])) <= MEME_ENDROIT_M:
                l["ce_que_ca_ouvre"] = e["ce_que_ca_ouvre"]
                break

    coupures_nouvelles = [
        e for e in endroits if e["ce_que_ca_ouvre"] == "une coupure de jour NOUVELLE"
    ]
    tetes_de_sentier = [
        e for e in endroits if e["ce_que_ca_ouvre"].startswith("une tete")
    ]
    lits_a_la_place_du_dortoir = [
        e for e in endroits if e["ce_que_ca_ouvre"].startswith("un vrai lit")
    ]

    sortie = {
        "quoi": "Les couchages du couloir du GR20 qui ne sont pas des fins d etape, "
        "avec le temps de marche REEL pour les rejoindre et en revenir",
        "tache": 838,
        "trace_socle": options.trace,
        "trace_points": len(trace),
        "trace_longueur_km": round((trace[-1]["pk_m"]) / 1000.0, 3),
        "source": "OpenStreetMap, relation %d, licence ODbL" % RELATION_GR20,
        "modele_terrain": MODELE_TERRAIN,
        "modele_temps_de_marche": NOM_DU_MODELE,
        "modele_temps_de_marche_2": NOM_DU_MODELE_ETA,
        "les_deux_modeles_divergent_sur": [
            {
                "nom": l["nom"],
                "osm": l["osm"],
                "pk_km": round(l["pk_m"] / 1000.0, 3),
                "modele_qui_passe": "decoupage des jours" if l["sous_le_seuil"] else "heure d arrivee",
                "decoupage_aller_min": l["minutes_aller"],
                "decoupage_retour_min": l["minutes_retour"],
                "eta_aller_min": l["minutes_aller_eta"],
                "eta_retour_min": l["minutes_retour_eta"],
            }
            for l in lignes
            if l.get("chemin_trace") and l["sous_le_seuil"] != l["sous_le_seuil_eta"]
        ],
        "seuil_minutes": options.seuil_minutes,
        "rayon_couloir_m": RAYON_COULOIR_M,
        "plafond_reseau_m": PLAFOND_RESEAU_M,
        "raccord_max_m": RACCORD_MAX_M,
        "couchages_releves": len(lignes),
        "couchages_declares": sum(1 for l in lignes if l["classe"] == "declare"),
        "couchages_nommes_sans_etiquette": sum(1 for l in lignes if l["classe"] == "nomme"),
        "avec_chemin_trace": sum(1 for l in lignes if l.get("chemin_trace")),
        "sans_chemin_trace": sum(1 for l in lignes if not l.get("chemin_trace")),
        "deja_fins_d_etape": sum(1 for l in lignes if l["deja_une_fin_d_etape"]),
        "sous_le_seuil_hors_etape": len(gagnants),
        "nouvelles_nuits_possibles": len(endroits),
        "dont_coupures_de_jour_nouvelles": len(coupures_nouvelles),
        "dont_un_lit_a_la_place_du_dortoir": len(lits_a_la_place_du_dortoir),
        "dont_tetes_de_sentier": len(tetes_de_sentier),
        "endroits_nouveaux": endroits,
        "objets_ecartes": ecartes,
        "couchages": lignes,
    }
    sauver(options.sortie, sortie)
    if options.markdown:
        ecrire_markdown(options.markdown, sortie, options.seuil_minutes)
    sys.stderr.write(
        "[5/5] %s ecrit : %d couchages, %d sous le seuil hors etape, "
        "%d nouveaux endroits de couchage (%d coupures nouvelles, %d lits a la "
        "place du dortoir)\n"
        % (
            options.sortie,
            len(lignes),
            len(gagnants),
            len(endroits),
            len(coupures_nouvelles),
            len(lits_a_la_place_du_dortoir),
        )
    )


def ecrire_markdown(chemin, sortie, seuil):
    """Le tableau trie par point kilometrique, tel que la tache le demande."""
    l = []
    a = l.append
    a("# Les couchages a moins de %d minutes du GR20 qui ne sont pas des fins d etape" % seuil)
    a("")
    a("Tache 838. Socle : la trace de la tache 837 (%d points, %s km)."
      % (sortie["trace_points"], sortie["trace_longueur_km"]))
    a("")
    a("- Source : %s" % sortie["source"])
    a("- Modele de terrain : %s" % sortie["modele_terrain"])
    a("- Modele de temps de marche EMPLOYE DANS LE TABLEAU : %s" % sortie["modele_temps_de_marche"])
    a("- Second modele de l application, calcule a cote : %s" % sortie["modele_temps_de_marche_2"])
    a("- Couloir interroge : %d m autour de la trace ; itineraire plafonne a %d m de marche"
      % (sortie["rayon_couloir_m"], int(sortie["plafond_reseau_m"])))
    a("- Seuil de Christophe : %d minutes DANS CHAQUE SENS" % seuil)
    a("")
    a("| PK | Nom | Type | Lits | Aller | Retour | D+ aller | D+ retour | Chemin trace | OSM | Statut |")
    a("|---|---|---|---|---|---|---|---|---|---|---|")
    for c in sortie["couchages"]:
        pk = "%.2f" % (c["pk_m"] / 1000.0) if c.get("pk_m") is not None else "-"
        lits = (
            "%d %s" % (c["lits"], c["unite_lits"]) if c.get("lits") else "inconnu"
        )
        if c.get("chemin_trace"):
            aller = en_clair(c["minutes_aller"])
            retour = en_clair(c["minutes_retour"])
            dplus = "%d m" % c["dplus_aller_m"]
            dret = "%d m" % c["dplus_retour_m"]
            chemin_trace = "oui"
        else:
            aller = retour = dplus = dret = "-"
            chemin_trace = "NON"
        if c["deja_une_fin_d_etape"]:
            statut = "deja fin d etape (%s)" % c["deja_une_fin_d_etape"]["etape_app"]
        elif not c.get("chemin_trace"):
            statut = "sans chemin trace"
        elif c["classe"] == "nomme":
            statut = "nomme, aucun couchage declare dans OSM"
        elif c["sous_le_seuil"]:
            ouvre = c.get("ce_que_ca_ouvre") or ""
            if ouvre.startswith("une coupure"):
                statut = "NOUVELLE NUIT — coupure de jour nouvelle"
            elif ouvre.startswith("une tete"):
                statut = "tete de sentier, pas une nuit de plus"
            elif ouvre.startswith("un vrai lit"):
                statut = "NOUVELLE NUIT — un lit au lieu du dortoir"
            else:
                statut = "NOUVELLE NUIT"
        else:
            statut = "au-dela du seuil"
        a(
            "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |"
            % (pk, c["nom"], c["genre_en_clair"], lits, aller, retour, dplus, dret,
               chemin_trace, c["osm"], statut)
        )
    a("")
    a("## Le total")
    a("")
    a("- Couchages releves dans le couloir : %d (%d declares par OpenStreetMap, "
      "%d nommes sans etiquette de couchage)"
      % (sortie["couchages_releves"], sortie["couchages_declares"],
         sortie["couchages_nommes_sans_etiquette"]))
    a("- Avec un chemin trace jusqu a eux : %d ; SANS chemin trace : %d"
      % (sortie["avec_chemin_trace"], sortie["sans_chemin_trace"]))
    a("- Deja des fins d etape : %d" % sortie["deja_fins_d_etape"])
    a("- **Nouvelles nuits possibles : %d**" % sortie["nouvelles_nuits_possibles"])
    a("  - dont coupures de jour NOUVELLES : %d" % sortie["dont_coupures_de_jour_nouvelles"])
    a("  - dont un lit a la place du dortoir au meme endroit : %d"
      % sortie["dont_un_lit_a_la_place_du_dortoir"])
    a("  - dont des tetes de sentier (Calenzana, Conca) : %d" % sortie["dont_tetes_de_sentier"])
    a("")
    a("## Les nouveaux endroits de couchage, un par un")
    a("")
    a("| PK | Ce que ca ouvre | Fin d etape la plus proche | Ecart PK | Couchages | Lits | Aller | Retour |")
    a("|---|---|---|---|---|---|---|---|")
    for e in sorted(sortie["endroits_nouveaux"], key=lambda x: x["pk_km"]):
        a(
            "| %.2f | %s | %s | %.2f km | %s | %s | %s | %s |"
            % (e["pk_km"], e["ce_que_ca_ouvre"], e["fin_d_etape_la_plus_proche"],
               e["ecart_pk_a_cette_fin_d_etape_km"], " + ".join(e["couchages"]),
               e["lits"] or "inconnu", en_clair(e["minutes_aller"]),
               en_clair(e["minutes_retour"]))
        )
    a("")
    a("## Les deux modeles de l application, et ou ils se contredisent")
    a("")
    if not sortie["les_deux_modeles_divergent_sur"]:
        a("Aucun couchage ne change de cote du seuil selon le modele employe.")
    else:
        a("| Nom | PK | Decoupage aller/retour | Heure d arrivee aller/retour | Qui passe |")
        a("|---|---|---|---|---|")
        for d in sortie["les_deux_modeles_divergent_sur"]:
            a(
                "| %s | %.2f | %s / %s | %s / %s | %s |"
                % (d["nom"], d["pk_km"], en_clair(d["decoupage_aller_min"]),
                   en_clair(d["decoupage_retour_min"]), en_clair(d["eta_aller_min"]),
                   en_clair(d["eta_retour_min"]), d["modele_qui_passe"])
            )
    with open(chemin, "w", encoding="utf-8") as f:
        f.write("\n".join(l) + "\n")


if __name__ == "__main__":
    main()
