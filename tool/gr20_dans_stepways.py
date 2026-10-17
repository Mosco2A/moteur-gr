#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fabrique les donnees StepWays du GR20 EN LES LISANT SUR LA TRACE.

Rien n est saisi a la main ici : chaque longueur, chaque montee, chaque descente
et chaque duree sort de `assets/data/gr20/track.gpx` (relevee en tache 837 sur la
relation OpenStreetMap 12484370, licence ODbL) et des couchages releves en tache
838. Il n y a AUCUN coefficient de mise a l echelle : la tache 837 a mesure que
les longueurs annoncees par l ancienne application venaient d un topo multiplie
par 1,069 pour que la somme tombe juste, au prix d un ecart allant jusqu a 62 %
sur une etape. Ce script est la reponse : on mesure, on ne recale pas.

TROIS CHOSES QU IL FAIT ET QUI NE SE DEVINENT PAS :

 1. L ORDRE DES ETAPES VIENT DE LA TRACE. Les dix-sept coupures (le depart plus
    seize fins d etape) sont des objets OpenStreetMap nommes ; chacune est
    PROJETEE sur la trace, et le tri se fait sur le point kilometrique obtenu.
    C est ce tri qui remet le col de Bavella AVANT Paliri : l ancien decoupage
    les inversait, ce qui faisait parcourir 9,06 km deux fois.

 2. LES BORNES DES DEUX PARCOURS SONT CALCULEES, PAS DECLAREES. Le parcours nord
    s arrete a la coupure qui porte l etiquette de Vizzavona et le parcours sud
    en repart. Le nombre d etapes de chacun est donc COMPTE sur la trace (neuf
    et sept), jamais ecrit : un commentaire qui annoncait huit et huit a fait
    croire pendant des semaines que le nord finissait a Vizzavona alors qu il
    deposait le marcheur au refuge de l Onda, une journee entiere plus tot.

 3. UN SEUL MODELE DE TEMPS DE MARCHE, LE PRUDENT, PARTAGE AVEC L APPLICATION.
    4 km/h a plat, 400 m de montee a l heure, et la descente payee 1,67 s par
    metre. Les trois constantes sont celles de `lib/core/models/stage_duration.dart`
    et le calcul est le meme a la seconde : en montagne on n annonce pas des
    horaires optimistes.

Usage :
    python tool/gr20_dans_stepways.py
    python tool/gr20_dans_stepways.py --verifier   # ne rien ecrire, comparer
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

TRACE = "assets/data/gr20/track.gpx"
COUPURES = "tool/coupures_gr20.json"
COUCHAGES = "assets/data/gr20/couchages_hors_etape.json"

SORTIE_ETAPES = "assets/data/gr20/stages.json"
SORTIE_POIS = "assets/data/gr20/pois.json"
SORTIE_NUITS = "assets/data/gr20/nuits_possibles.json"
SORTIE_SENTIER = "assets/data/gr20.json"

TRAIL_ID = "gr20"
RELATION_OSM = 12484370
ATTRIBUTION = (
    "Trace et couchages : OpenStreetMap, relation %d (GR 20 Principale), "
    "licence ODbL. Altitudes : modele de terrain EU-DEM 25 m via opentopodata."
    % RELATION_OSM
)

# --- LE MODELE DE TEMPS DE MARCHE, UNIQUE (lib/core/models/stage_duration.dart) ---
VITESSE_PLAT_KMH = 4.0
MONTEE_PAR_HEURE_M = 400.0
PLAT_M_PAR_S = VITESSE_PLAT_KMH * 1000.0 / 3600.0
MONTEE_S_PAR_M = 3600.0 / MONTEE_PAR_HEURE_M
DESCENTE_S_PAR_M = 10.0 / 6.0

RAYON_TERRE_M = 6371008.8
FENETRE_LISSAGE = 7
PAS_ECHANTILLON = 7

# La coupure qui partage le sentier en deux parcours. C est une ETIQUETTE de
# `tool/coupures_gr20.json`, pas un rang : le rang est COMPTE apres le tri par
# point kilometrique, justement pour qu aucun chiffre en dur ne puisse mentir.
ETIQUETTE_PARTAGE = "Gare de Vizzavona"


def arrondi(x):
    """Arrondi de Dart (`num.round()`) : la moitie s eloigne de zero."""
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def lire_gpx(chemin):
    """Rend (points, altitudes). Un point sans <ele> rend None, jamais une valeur."""
    with open(chemin, encoding="utf-8") as f:
        texte = f.read()
    points, altitudes = [], []
    motif = re.compile(
        r'<trkpt\s+lat="([-\d.]+)"\s+lon="([-\d.]+)"\s*(?:/>|>\s*(?:<ele>([-\d.]+)</ele>)?)'
    )
    for m in motif.finditer(texte):
        points.append((float(m.group(1)), float(m.group(2))))
        altitudes.append(None if m.group(3) is None else float(m.group(3)))
    return points, altitudes


def distance_m(a, b):
    lat1, lon1 = math.radians(a[0]), math.radians(a[1])
    lat2, lon2 = math.radians(b[0]), math.radians(b[1])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    )
    return 2 * RAYON_TERRE_M * math.asin(math.sqrt(h))


def _plan(point, origine):
    lat0 = math.radians(origine[0])
    x = math.radians(point[1] - origine[1]) * RAYON_TERRE_M * math.cos(lat0)
    y = math.radians(point[0] - origine[0]) * RAYON_TERRE_M
    return x, y


def projeter(repere, points, cumul):
    """Point kilometrique du repere sur la POLYLIGNE, et son ecart a la trace."""
    meilleur = None
    i_proche = min(range(len(points)), key=lambda i: distance_m(repere, points[i]))
    debut = max(0, i_proche - 50)
    fin = min(len(points) - 1, i_proche + 50)
    for i in range(debut, fin):
        a, b = points[i], points[i + 1]
        ax, ay = _plan(a, a)
        bx, by = _plan(b, a)
        px, py = _plan(repere, a)
        dx, dy = bx - ax, by - ay
        norme = dx * dx + dy * dy
        t = (
            0.0
            if norme == 0
            else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / norme))
        )
        qx, qy = ax + t * dx, ay + t * dy
        ecart = math.hypot(px - qx, py - qy)
        if meilleur is None or ecart < meilleur[0]:
            longueur = cumul[i + 1] - cumul[i]
            meilleur = (ecart, cumul[i] + t * longueur, i)
    return {"ecart_m": meilleur[0], "pk_m": meilleur[1], "index": meilleur[2]}


def denivele_maison(altitudes, fenetre=FENETRE_LISSAGE, pas=PAS_ECHANTILLON):
    """Le filtre de la maison, AVEC les deux bouts ancres (tache 838).

    Moyenne glissante sur sept points puis un point sur sept : calibre en tache
    837 sur la trace du Mare a Mare Centre, ou il rend 4 263 m quand le chiffre
    publie de ce sentier est 4 274 m (memoire #101703), soit 0,26 % d ecart.
    La moyenne glissante ecrase les DEUX BOUTS du profil : la tache 838 l a
    mesure sur une montee reguliere de 95 m, dont elle ne rendait que 80 m. Les
    extremites sont donc remises a leur altitude REELLE avant de sommer ;
    l interieur reste lisse. Sur la trace entiere l ecart est de 1 m sur
    11 602 (0,009 %) : la calibration de la 837 tient.
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
    return arrondi(plus), arrondi(moins)


def minutes_de_marche(km, dplus_m, dmoins_m):
    """LE modele de temps de marche, a la seconde pres comme en Dart."""
    secondes = (
        km * 1000.0 / PLAT_M_PAR_S
        + dplus_m * MONTEE_S_PAR_M
        + dmoins_m * DESCENTE_S_PAR_M
    )
    return arrondi(secondes / 60.0)


def difficulte(km, dplus_m):
    """Difficulte DERIVEE des deux mesures, par les seuils du socle.

    Les memes seuils que les sentiers deja embarques : au-dela de 15 km ou de
    1 000 m de montee une journee est `hard`, au-dela de 1 500 m de montee elle
    est `extreme`, en dessous de 8 km et 400 m elle est `easy`. Aucun jugement a
    la main : deux chiffres entrent, un mot sort.
    """
    if dplus_m >= 1500:
        return "extreme"
    if km >= 15.0 or dplus_m >= 1000:
        return "hard"
    if km <= 8.0 and dplus_m <= 400:
        return "easy"
    return "moderate"


def nom_court(nom):
    """« Refuge de Carozzu » -> « Carozzu » : le nom tel qu il se dit en etape.

    L article est GARDE quand il fait partie du nom du lieu (« l'Onda »,
    « i Paliri ») : le retirer donnerait « Onda », que personne ne dit.
    """
    prefixes = (
        ("Refuge de l'", "l'"),
        ("Refuge d'i ", "i "),
        ("Refuge d'", ""),
        ("Refuge de ", ""),
        ("Refuge ", ""),
        ("Gare de ", ""),
    )
    for prefixe, remplacement in prefixes:
        if nom.startswith(prefixe):
            return remplacement + nom[len(prefixe) :]
    return nom


def type_de_poi(type_osm):
    """Le type d un repere, LU de son etiquette OpenStreetMap."""
    if "alpine_hut" in type_osm or "wilderness_hut" in type_osm:
        return "shelter"
    return "info"


def genre_de_couchage(genre_osm):
    """Le genre d un couchage, LU de son etiquette OpenStreetMap."""
    table = {
        "alpine_hut": "refuge",
        "wilderness_hut": "refuge",
        "hut": "refuge",
        "camp_site": "camping",
        "camping": "camping",
        "hotel": "hotel",
        "guest_house": "gite",
        "hostel": "gite",
        "chalet": "gite",
        "auberge": "gite",
        "apartment": "gite",
        "bergerie": "bergerie",
        "shelter": "bivouac",
        "basic_hut": "bivouac",
        "bivouac": "bivouac",
    }
    return table.get(genre_osm, "refuge")


def charger(chemin):
    with open(os.path.join(RACINE, chemin), encoding="utf-8") as f:
        return json.load(f)


def ecrire(chemin, donnee, verifier):
    """Ecrit le JSON, ou le COMPARE a l existant en mode verification."""
    texte = json.dumps(donnee, ensure_ascii=False, indent=2) + "\n"
    complet = os.path.join(RACINE, chemin)
    if verifier:
        if not os.path.exists(complet):
            return "ABSENT   %s" % chemin
        with open(complet, encoding="utf-8") as f:
            return ("IDENTIQUE %s" if f.read() == texte else "DIFFERENT %s") % chemin
    os.makedirs(os.path.dirname(complet), exist_ok=True)
    with open(complet, "w", encoding="utf-8") as f:
        f.write(texte)
    return "ECRIT    %s" % chemin


def mesurer():
    """Toute la mesure, en un seul endroit : rend les etapes et les nuits."""
    points, altitudes = lire_gpx(os.path.join(RACINE, TRACE))
    manquantes = sum(1 for a in altitudes if a is None)
    if manquantes:
        raise SystemExit(
            "REFUS : %d altitudes manquantes sur %d points. La trace doit etre "
            "complete AVANT d etre mesuree." % (manquantes, len(points))
        )
    cumul = [0.0]
    for i in range(1, len(points)):
        cumul.append(cumul[-1] + distance_m(points[i - 1], points[i]))

    coupures = charger(COUPURES)
    for c in coupures:
        p = projeter((c["lat"], c["lon"]), points, cumul)
        c["pk_km"] = round(p["pk_m"] / 1000.0, 3)
        c["ecart_trace_m"] = round(p["ecart_m"], 1)
        c["index"] = p["index"]
        c["altitude_m"] = arrondi(altitudes[p["index"]])
    ordre = sorted(coupures, key=lambda c: c["pk_km"])

    etapes = []
    for n in range(len(ordre) - 1):
        depart, arrivee = ordre[n], ordre[n + 1]
        i, j = depart["index"], arrivee["index"]
        if j <= i:
            j = i + 1
        km = round(arrivee["pk_km"] - depart["pk_km"], 2)
        dplus, dmoins = denivele_maison(altitudes[i : j + 1])
        etapes.append(
            {
                "rang": n + 1,
                "depart": depart,
                "arrivee": arrivee,
                "km": km,
                "dplus": dplus,
                "dmoins": dmoins,
                "minutes": minutes_de_marche(km, dplus, dmoins),
            }
        )

    # Le partage en deux parcours : la coupure PORTEUSE de l etiquette, et son
    # rang COMPTE dans l ordre de la trace.
    rang_partage = None
    for e in etapes:
        if e["arrivee"]["nom"] == ETIQUETTE_PARTAGE:
            rang_partage = e["rang"]
    if rang_partage is None:
        raise SystemExit("REFUS : coupure de partage « %s » absente." % ETIQUETTE_PARTAGE)

    dplus_total, dmoins_total = denivele_maison(altitudes)
    return {
        "points": points,
        "altitudes": altitudes,
        "cumul": cumul,
        "coupures": ordre,
        "etapes": etapes,
        "rang_partage": rang_partage,
        "longueur_km": round(cumul[-1] / 1000.0, 3),
        "dplus_total": dplus_total,
        "dmoins_total": dmoins_total,
    }


def nuits_possibles(mesure):
    """Les nuits ou une journee peut se terminer : fins d etape ET endroits releves.

    Seize fins d etape plus les quinze coupures de jour NOUVELLES de la tache
    838 : trente et une. Les deux tetes de sentier (Calenzana, Conca) n en sont
    pas — on y dort avant de partir et apres etre arrive, pas pendant. Les six
    « vrai lit a la place du dortoir » n en sont pas non plus : ils sont au MEME
    endroit du sentier qu une fin d etape existante, donc ils n ouvrent aucune
    coupure de plus ; ils entrent en revanche dans les couchages.
    """
    releve = charger(COUCHAGES)

    def utilisables(filtre):
        """Les couchages DECLARES, joignables et sous le seuil, qui passent [filtre]."""
        return [
            c
            for c in releve["couchages"]
            if c["classe"] == "declare"
            and c.get("chemin_trace")
            and c.get("sous_le_seuil")
            and filtre(c)
        ]

    def osm_et_lits(couchages):
        """Identifiants OpenStreetMap et lits CONNUS de ces couchages.

        Les lits sont SOMMES comme la tache 838 les a sommes : plusieurs
        etablissements au meme endroit font autant de lits. Un couchage dont
        OpenStreetMap ignore la capacite ne compte pour rien — jamais pour une
        valeur devinee. Zero connu rend `null`, qui se lit « on ne sait pas ».
        """
        ids = sorted({c["osm"] for c in couchages})
        lits = sum(c["lits"] for c in couchages if c.get("lits"))
        return ids, (lits or None)

    def denivele_du_detour(couchages):
        """LE DENIVELE DU DETOUR, dans les deux sens, en metres (tache 853).

        POURQUOI CES QUATRE CHIFFRES SORTENT D ICI ET PAS D AILLEURS. La tache
        838 avait deja mesure le detour vers un couchage hors trace, et elle le
        relevait en MINUTES, separement a l aller et au retour (refuge Laparo :
        10 minutes pour y descendre le soir, 28 pour en remonter le matin). Le
        MEME releve porte le denivele de ce detour — `dplus_aller_m`,
        `dmoins_aller_m`, `dplus_retour_m`, `dmoins_retour_m` — et personne ne
        le ressortait : le decoupage ajoutait les minutes du detour au temps de
        la journee et n ajoutait pas ses metres a son denivele. Une journee qui
        finit au refuge Laparo remonte 126 m le lendemain matin avant d avoir
        avance d un metre sur la trace, et ces 126 m n entraient dans aucun
        chiffre annonce.

        ON PREND LE MAXIMUM QUAND PLUSIEURS COUCHAGES PARTAGENT L ENDROIT. Les
        lits se SOMMENT (deux gites au meme endroit font deux fois les lits), le
        detour NON : le marcheur ne fait le chemin qu une fois. A coordonnees
        egales le detour est le meme, et le maximum protege le cas ou le releve
        differe de quelques metres entre deux etablissements voisins — on
        annonce alors la montee la plus forte, jamais la plus faible.

        Un endroit sans couchage joint rend quatre zeros, exactement comme les
        minutes : aucune valeur devinee.
        """

        def maximum(champ):
            if not couchages:
                return 0
            return max((c.get(champ) or 0) for c in couchages)

        return {
            "dplus_aller_m": maximum("dplus_aller_m"),
            "dmoins_aller_m": maximum("dmoins_aller_m"),
            "dplus_retour_m": maximum("dplus_retour_m"),
            "dmoins_retour_m": maximum("dmoins_retour_m"),
        }

    nuits = []
    for e in mesure["etapes"]:
        arrivee = e["arrivee"]
        ici = utilisables(
            lambda c, nom=arrivee["nom"]: (c.get("deja_une_fin_d_etape") or {}).get(
                "nom"
            )
            == nom
        )
        # CONCA EST LE SEUL CAS, ET IL EST CONNU. La tache 838 n a reconnu un
        # couchage « a cette fin d etape » que sous 150 m ; le gite de Conca est
        # a 197 m, donc il ressortait en tete de sentier. Un repli par la
        # DISTANCE, dite et mesuree, evite la seule nuit sans identifiant.
        if not ici:
            ici = utilisables(
                lambda c, a=arrivee: distance_m((c["lat"], c["lon"]), (a["lat"], a["lon"]))
                <= 250.0
            )
        ids, lits = osm_et_lits(ici)
        nuits.append(
            {
                "nom": arrivee["nom"],
                "osm": ids,
                "osm_type": arrivee.get("type_osm", ""),
                "pk_km": arrivee["pk_km"],
                "altitude_m": arrivee["altitude_m"],
                "lat": arrivee["lat"],
                "lon": arrivee["lon"],
                "minutes_aller": 0,
                "minutes_retour": 0,
                # UNE FIN D ETAPE EST SUR LA TRACE : AUCUN DETOUR, NI EN TEMPS
                # NI EN METRES. Les minutes etaient deja a zero ici depuis la
                # tache 838 ; les metres le sont pour la MEME raison, et c est
                # la coherence qui compte. Le couchage joint plus bas est le
                # BATIMENT voisin de la fin d etape, parfois a une vingtaine de
                # metres de montee ; le modele du depot place la nuit AU point
                # de la trace, et c est ce choix-la qui est porte ici. Le
                # corriger serait changer la definition d une fin d etape, donc
                # un autre lot — pas un effet de bord de celui-ci.
                "dplus_aller_m": 0,
                "dmoins_aller_m": 0,
                "dplus_retour_m": 0,
                "dmoins_retour_m": 0,
                "lits": lits,
                "origine": "fin d etape",
                "fin_d_etape": e["rang"],
            }
        )

    for endroit in releve["endroits_nouveaux"]:
        if not endroit["ce_que_ca_ouvre"].startswith("une coupure de jour"):
            continue
        ici = utilisables(
            lambda c, e=endroit: abs(c["lat"] - e["lat"]) < 1e-6
            and abs(c["lon"] - e["lon"]) < 1e-6
        )
        ids, _ = osm_et_lits(ici)
        nuits.append(
            {
                "nom": endroit["couchages"][0],
                "osm": ids,
                "osm_type": ici[0]["genre"] if ici else "",
                "pk_km": round(endroit["pk_km"], 3),
                "altitude_m": None,
                "lat": endroit["lat"],
                "lon": endroit["lon"],
                "minutes_aller": endroit["minutes_aller"],
                "minutes_retour": endroit["minutes_retour"],
                # LE DETOUR EN METRES, A COTE DU DETOUR EN MINUTES (tache 853).
                # `endroits_nouveaux` ne porte que les minutes ; le denivele est
                # sur le couchage joint par ses coordonnees, c est-a-dire sur
                # `ici`, deja calcule juste au-dessus pour les identifiants.
                **denivele_du_detour(ici),
                "lits": endroit["lits"] or None,
                "origine": "coupure de jour relevee",
                "fin_d_etape": None,
            }
        )

    nuits.sort(key=lambda n: n["pk_km"])
    # L altitude de chaque nuit, LUE sur la trace a son point kilometrique.
    cumul, altitudes = mesure["cumul"], mesure["altitudes"]
    for n in nuits:
        if n["altitude_m"] is not None:
            continue
        cible = n["pk_km"] * 1000.0
        i = min(range(len(cumul)), key=lambda k: abs(cumul[k] - cible))
        n["altitude_m"] = arrondi(altitudes[i])
    return nuits, releve


def couchages_du_sentier(mesure, releve):
    """Les couchages rattaches a leur etape : fins d etape ET endroits nouveaux.

    Chacun garde son identifiant OpenStreetMap dans son id (`gr20-node-123456`),
    et ses lits quand OpenStreetMap les connait. Un lieu-dit NOMME mais non
    etiquete couchage n est pas un lit : la tache 838 les a comptes a part et ils
    ne sont pas repris ici.
    """
    etapes = mesure["etapes"]

    def etape_de(pk_m):
        for e in etapes:
            if e["depart"]["pk_km"] * 1000.0 <= pk_m <= e["arrivee"]["pk_km"] * 1000.0:
                return e["rang"]
        return etapes[-1]["rang"]

    retenus = []
    vus = set()
    for c in releve["couchages"]:
        # DECLARE : OpenStreetMap dit que c est un couchage. Un lieu-dit nomme
        # « Bergerie de ... » est un LIEU-DIT, pas un lit (tache 838).
        if c["classe"] != "declare":
            continue
        if not c.get("nom"):
            continue
        # SANS CHEMIN TRACE, AUCUN TEMPS N A ETE CALCULE : on ne propose pas un
        # lit dont on ne sait pas comment on y va. Seize objets sont dans ce cas.
        if not c.get("chemin_trace") or "pk_m" not in c:
            continue
        # SOUS LE SEUIL : trente minutes de marche dans les DEUX sens.
        if not c.get("sous_le_seuil"):
            continue
        if c["osm"] in vus:
            continue
        vus.add(c["osm"])
        rang = etape_de(c["pk_m"])
        retenus.append(
            {
                "id": "gr20-%s" % c["osm"].replace("/", "-"),
                "stageId": "gr20-s%d" % rang,
                "nameFr": c["nom"],
                "nameEn": c["nom"],
                "nameDe": c["nom"],
                "nameIt": c["nom"],
                "nameEs": c["nom"],
                "type": genre_de_couchage(c["genre"]),
                "lat": c["lat"],
                "lng": c["lon"],
                "capacity": c["lits"],
                "phone": None,
                "email": None,
                "website": None,
                "priceRange": None,
                "bookingUrl": None,
                "address": None,
            }
        )
    retenus.sort(key=lambda a: (a["stageId"], a["nameFr"]))
    return retenus


def main():
    arg = argparse.ArgumentParser(description="Fabrique les donnees GR20 de StepWays.")
    arg.add_argument(
        "--verifier",
        action="store_true",
        help="ne rien ecrire : dire si les fichiers produits sont a jour",
    )
    options = arg.parse_args()

    mesure = mesurer()
    etapes = mesure["etapes"]
    rang_partage = mesure["rang_partage"]
    nuits, releve = nuits_possibles(mesure)
    couchages = couchages_du_sentier(mesure, releve)

    # --- Les seize etapes, au format du socle « donnees externes » ---
    etapes_json = []
    pois_json = []
    for e in etapes:
        depart, arrivee = e["depart"], e["arrivee"]
        da, aa = nom_court(depart["nom"]), nom_court(arrivee["nom"])
        etapes_json.append(
            {
                "id": "gr20-s%d" % e["rang"],
                "trailId": TRAIL_ID,
                "stageNumber": e["rang"],
                "nameFr": "%s - %s" % (da, aa),
                "nameEn": "%s to %s" % (da, aa),
                "departureName": da,
                "arrivalName": aa,
                "distanceKm": e["km"],
                "elevationGainM": e["dplus"],
                "elevationLossM": e["dmoins"],
                "estimatedDurationMinutes": e["minutes"],
                "difficulty": difficulte(e["km"], e["dplus"]),
                "descriptionFr": (
                    "Etape %d du GR20, de %s a %s : %s km, %d m de montee et %d m de "
                    "descente, du point kilometrique %s au point kilometrique %s de la "
                    "trace relevee dans OpenStreetMap. Altitude d arrivee %d m."
                    % (
                        e["rang"],
                        da,
                        aa,
                        ("%.2f" % e["km"]).replace(".", ","),
                        e["dplus"],
                        e["dmoins"],
                        ("%.2f" % depart["pk_km"]).replace(".", ","),
                        ("%.2f" % arrivee["pk_km"]).replace(".", ","),
                        arrivee["altitude_m"],
                    )
                ),
                "descriptionEn": (
                    "Stage %d of the GR20, from %s to %s: %s km, %d m of ascent and "
                    "%d m of descent, from kilometre point %s to kilometre point %s of "
                    "the track surveyed in OpenStreetMap. Arrival altitude %d m."
                    % (
                        e["rang"],
                        da,
                        aa,
                        "%.2f" % e["km"],
                        e["dplus"],
                        e["dmoins"],
                        "%.2f" % depart["pk_km"],
                        "%.2f" % arrivee["pk_km"],
                        arrivee["altitude_m"],
                    )
                ),
                "startLat": depart["lat"],
                "startLng": depart["lon"],
                "endLat": arrivee["lat"],
                "endLng": arrivee["lon"],
            }
        )
        pois_json.append(
            {
                "id": "gr20-poi-%02d" % e["rang"],
                "stageId": "gr20-s%d" % e["rang"],
                "stageNumber": e["rang"],
                "nameFr": arrivee["nom"],
                "nameEn": arrivee["nom"],
                "descriptionFr": (
                    "Fin de l etape %d, au point kilometrique %s de la trace, a %d m "
                    "d altitude. Releve dans OpenStreetMap a %s m de la trace."
                    % (
                        e["rang"],
                        ("%.2f" % arrivee["pk_km"]).replace(".", ","),
                        arrivee["altitude_m"],
                        ("%.0f" % arrivee["ecart_trace_m"]),
                    )
                ),
                "descriptionEn": (
                    "End of stage %d, at kilometre point %s of the track, %d m above "
                    "sea level. Surveyed in OpenStreetMap %s m from the track."
                    % (
                        e["rang"],
                        "%.2f" % arrivee["pk_km"],
                        arrivee["altitude_m"],
                        "%.0f" % arrivee["ecart_trace_m"],
                    )
                ),
                "type": type_de_poi(arrivee.get("type_osm", "")),
                "lat": arrivee["lat"],
                "lng": arrivee["lon"],
                "altitudeM": arrivee["altitude_m"],
                "source": "OpenStreetMap %s" % arrivee.get("type_osm", ""),
            }
        )

    # --- Les trois parcours : l integral, le nord, le sud. Bornes COMPTEES. ---
    nord = [e for e in etapes if e["rang"] <= rang_partage]
    sud = [e for e in etapes if e["rang"] > rang_partage]

    def parcours(code, fr, en, tranche):
        km = round(sum(e["km"] for e in tranche), 2)
        return {
            "id": "gr20-%s" % code.lower(),
            "trailId": TRAIL_ID,
            "code": code,
            "nameFr": fr,
            "nameEn": en,
            "nameDe": fr,
            "nameIt": fr,
            "nameEs": fr,
            "distanceKm": km,
            "elevationGain": sum(e["dplus"] for e in tranche),
            "stageCount": len(tranche),
        }

    itineraires = [
        parcours("NS", "GR20 integral — Calenzana vers Conca", "GR20 end to end — Calenzana to Conca", etapes),
        parcours("NORD", "GR20 Nord — Calenzana vers Vizzavona", "GR20 North — Calenzana to Vizzavona", nord),
        parcours("SUD", "GR20 Sud — Vizzavona vers Conca", "GR20 South — Vizzavona to Conca", sud),
    ]

    sentier = {
        "attribution": ATTRIBUTION,
        "trail_meta": {
            "id": TRAIL_ID,
            "code": "gr20",
            "dataVersion": 1,
            "status": "active",
        },
        "itineraries": itineraires,
        "stages": [
            {
                "id": "gr20-ns-s%d" % e["rang"],
                "itineraryId": "gr20-ns",
                "stageNumber": e["rang"],
                "nameFr": j["nameFr"],
                "nameEn": j["nameEn"],
                "nameDe": j["nameFr"],
                "nameIt": j["nameFr"],
                "nameEs": j["nameFr"],
                "startLat": j["startLat"],
                "startLng": j["startLng"],
                "endLat": j["endLat"],
                "endLng": j["endLng"],
                "distanceKm": j["distanceKm"],
                "elevationGain": j["elevationGainM"],
                "elevationLoss": j["elevationLossM"],
                "durationMinutes": j["estimatedDurationMinutes"],
                "difficulty": j["difficulty"],
            }
            for e, j in zip(etapes, etapes_json)
        ],
        "accommodations": [
            dict(a, stageId="gr20-ns-s%s" % a["stageId"].split("-s")[1])
            for a in couchages
        ],
        "pois": [
            {
                "id": p["id"],
                "stageId": "gr20-ns-s%s" % p["stageId"].split("-s")[1],
                "nameFr": p["nameFr"],
                "nameEn": p["nameEn"],
                "nameDe": p["nameFr"],
                "nameIt": p["nameFr"],
                "nameEs": p["nameFr"],
                "descriptionFr": p["descriptionFr"],
                "descriptionEn": p["descriptionEn"],
                "descriptionDe": p["descriptionFr"],
                "descriptionIt": p["descriptionFr"],
                "descriptionEs": p["descriptionFr"],
                "type": p["type"],
                "lat": p["lat"],
                "lng": p["lng"],
                "elevation": float(p["altitudeM"]),
                "address": None,
                "phone": None,
                "website": None,
            }
            for p in pois_json
        ],
    }

    # --- LES SEGMENTS ENTRE NUITS, MESURES UN A UN SUR LA TRACE ---
    #
    # Une journee de marche est une suite de segments consecutifs, et ses
    # chiffres sont la SOMME de segments mesures : jamais une interpolation
    # entre un depart et une arrivee. C'est la difference exacte avec le
    # decoupage que Christophe a refuse le 29/09 (« il n y a pas de refuge »).
    depart_sentier = mesure["coupures"][0]
    jalons = [
        {
            "nom": depart_sentier["nom"],
            "pk_km": depart_sentier["pk_km"],
            "altitude_m": depart_sentier["altitude_m"],
            "lat": depart_sentier["lat"],
            "lon": depart_sentier["lon"],
            "tete_de_sentier": True,
        }
    ] + nuits
    cumul, altitudes = mesure["cumul"], mesure["altitudes"]

    def index_du_pk(pk_km):
        cible = pk_km * 1000.0
        return min(range(len(cumul)), key=lambda k: abs(cumul[k] - cible))

    segments = []
    for n in range(len(jalons) - 1):
        a, b = jalons[n], jalons[n + 1]
        i, j = index_du_pk(a["pk_km"]), index_du_pk(b["pk_km"])
        if j <= i:
            j = i + 1
        km = round(b["pk_km"] - a["pk_km"], 3)
        dplus, dmoins = denivele_maison(altitudes[i : j + 1])
        segments.append(
            {
                "rang": n + 1,
                "depart": a["nom"],
                "arrivee": b["nom"],
                "pk_depart_km": a["pk_km"],
                "pk_arrivee_km": b["pk_km"],
                "km": km,
                "dplus_m": dplus,
                "dmoins_m": dmoins,
                "minutes": minutes_de_marche(km, dplus, dmoins),
            }
        )

    nuits_fichier = {
        "quoi": (
            "Les nuits ou une journee de GR20 peut se terminer : les seize fins "
            "d etape et les quinze coupures de jour relevees en tache 838. Le "
            "curseur de duree s en sert pour poser une fin de journee ailleurs "
            "qu a une fin d etape, et seulement sur un endroit RELEVE."
        ),
        "attribution": ATTRIBUTION,
        "trailId": TRAIL_ID,
        "trace": TRACE,
        "longueur_km": mesure["longueur_km"],
        "modele_de_temps_de_marche": (
            "%s km/h a plat, %d m de montee par heure, descente payee %.2f s par "
            "metre — lib/core/models/stage_duration.dart"
            % (
                ("%.1f" % VITESSE_PLAT_KMH).replace(".", ","),
                int(MONTEE_PAR_HEURE_M),
                DESCENTE_S_PAR_M,
            )
        ),
        "nuits": len(nuits),
        "dont_fins_d_etape": sum(1 for n in nuits if n["fin_d_etape"] is not None),
        "dont_coupures_relevees": sum(1 for n in nuits if n["fin_d_etape"] is None),
        "tete_de_sentier": depart_sentier["nom"],
        "segments": len(segments),
        "liste": nuits,
        "entre_les_nuits": segments,
    }

    lignes = [
        ecrire(SORTIE_ETAPES, etapes_json, options.verifier),
        ecrire(SORTIE_POIS, pois_json, options.verifier),
        ecrire(SORTIE_NUITS, nuits_fichier, options.verifier),
        ecrire(SORTIE_SENTIER, sentier, options.verifier),
    ]
    for ligne in lignes:
        sys.stderr.write(ligne + "\n")

    sys.stderr.write(
        "\nTrace %.3f km, D+ %d m, D- %d m, %d etapes, partage au rang %d "
        "(nord %d etapes, sud %d etapes), %d nuits, %d couchages.\n"
        % (
            mesure["longueur_km"],
            mesure["dplus_total"],
            mesure["dmoins_total"],
            len(etapes),
            rang_partage,
            len(nord),
            len(sud),
            len(nuits),
            len(couchages),
        )
    )
    if options.verifier and any(l.startswith(("DIFFERENT", "ABSENT")) for l in lignes):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
