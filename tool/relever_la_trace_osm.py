#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Releve la trace d un sentier depuis sa relation OpenStreetMap, puis l altimetrise.

C est le procede employe pour la trace du Mare a Mare Centre (tache 761, memoire
#101703), qui porte 3 590 altitudes sur 3 590 points : geometrie prise dans la
relation OSM d itineraire, altitudes prises dans le modele numerique de terrain
EU-DEM 25 m servi par api.opentopodata.org. La tache 761 n avait laisse AUCUN
script : ce fichier existe pour que le meme geste soit rejouable a l identique
sur n importe quel sentier, et pour que personne n ait a le redecouvrir.

Usage :
    python tool/relever_la_trace_osm.py --relation 12484370 --nom "GR 20" \
        --slug gr20 --sortie assets/data/gr20/track.gpx --releve releve.json

Limites des services publics, respectees par le script :
  - Overpass : une seule requete, en-tete User-Agent identifiant l appelant.
  - opentopodata.org : 100 points par appel, 1 appel par seconde, 1000 par jour.
    8 800 points = 88 appels, soit environ une minute et demie.

Si une altitude ne peut pas etre obtenue, le script le DIT et refuse d ecrire le
fichier plutot que d interpoler en silence (--tolerer-trous pour forcer, et les
trous sont alors listes nommement et le point reste sans balise <ele>).
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone

OVERPASS = "https://overpass-api.de/api/interpreter"
OPENTOPODATA = "https://api.opentopodata.org/v1/eudem25m"
MODELE = "EU-DEM (resolution 25 m)"
# En-tete d identification exigee par la politique d usage d Overpass et
# recommandee par opentopodata : un appelant joignable, pas un robot anonyme.
UA = "StepWays/1.0 (+https://github.com/Mosco2A/moteur-gr; christophe.mosconi@only1cent.com)"

RAYON_TERRE_M = 6371008.8


def _appel(url, corps=None, essais=4):
    """Un appel HTTP avec en-tete d identification et reprise sur erreur."""
    dernier = None
    for tentative in range(essais):
        entetes = {"User-Agent": UA, "Accept": "application/json"}
        if corps:
            entetes["Content-Type"] = "application/json"
        requete = urllib.request.Request(url, data=corps, headers=entetes)
        try:
            with urllib.request.urlopen(requete, timeout=180) as reponse:
                return json.loads(reponse.read().decode("utf-8"))
        except Exception as err:  # reseau, HTTP, delai
            dernier = err
            time.sleep(2 ** tentative)
    raise SystemExit("ECHEC APPEL %s apres %d essais : %s" % (url, essais, dernier))


def distance_m(a, b):
    """Distance haversine en metres entre deux (lat, lon)."""
    lat1, lon1 = math.radians(a[0]), math.radians(a[1])
    lat2, lon2 = math.radians(b[0]), math.radians(b[1])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return 2 * RAYON_TERRE_M * math.asin(math.sqrt(h))


# --------------------------------------------------------------------------
# 1. La geometrie : la relation OSM, ses chemins dans L ORDRE de la relation
# --------------------------------------------------------------------------

def lire_relation(relation_id):
    requete = (
        "[out:json][timeout:180];"
        "rel(%d);"
        "out body;"
        ">;"
        "out skel qt;" % relation_id
    )
    url = OVERPASS + "?" + urllib.parse.urlencode({"data": requete})
    return _appel(url)


def assembler(donnees, relation_id, roles_ignores=()):
    """Enchaine les chemins membres dans l ordre de la relation.

    Rend la liste des points et un releve de ce qu il a fallu faire pour y
    arriver (inversions, ruptures). Rien n est fabrique : une rupture est
    signalee avec son ecart en metres, jamais comblee.
    """
    elements = donnees.get("elements", [])
    noeuds = dict((e["id"], (e["lat"], e["lon"])) for e in elements if e["type"] == "node")
    chemins = dict((e["id"], e["nodes"]) for e in elements if e["type"] == "way")
    relation = None
    for e in elements:
        if e["type"] == "relation" and e["id"] == relation_id:
            relation = e
            break
    if relation is None:
        raise SystemExit("Relation %d absente de la reponse Overpass." % relation_id)

    tous = [m for m in relation["members"] if m["type"] == "way"]
    membres = [m for m in tous if m.get("role", "") not in roles_ignores]
    roles = {}
    for m in tous:
        cle = m.get("role", "") or "(sans role)"
        roles[cle] = roles.get(cle, 0) + 1

    suite = []
    releve = {
        "relation": relation_id,
        "chemins_membres_total": len(tous),
        "chemins_retenus": len(membres),
        "roles": roles,
        "roles_ignores": list(roles_ignores),
        "chemins_absents": [],
        "inversions": 0,
        "ruptures": [],
        "tags": relation.get("tags", {}),
    }

    for rang, membre in enumerate(membres):
        ids = chemins.get(membre["ref"])
        if not ids:
            releve["chemins_absents"].append(membre["ref"])
            continue
        ids = list(ids)
        if not suite:
            suite = ids
            continue
        if suite[-1] == ids[0]:
            suite.extend(ids[1:])
        elif suite[-1] == ids[-1]:
            releve["inversions"] += 1
            suite.extend(list(reversed(ids))[1:])
        else:
            ecart = distance_m(noeuds[suite[-1]], noeuds[ids[0]])
            ecart_inv = distance_m(noeuds[suite[-1]], noeuds[ids[-1]])
            if ecart_inv < ecart:
                releve["inversions"] += 1
                ids = list(reversed(ids))
                ecart = ecart_inv
            releve["ruptures"].append(
                {"rang": rang, "chemin": membre["ref"], "ecart_m": round(ecart, 1)}
            )
            suite.extend(ids)

    points = [noeuds[i] for i in suite if i in noeuds]
    # On enleve les doublons consecutifs (un noeud partage entre deux chemins).
    propres = []
    for p in points:
        if not propres or propres[-1] != p:
            propres.append(p)
    releve["points"] = len(propres)
    releve["noeuds_uniques"] = len(set(propres))
    return propres, releve


# --------------------------------------------------------------------------
# 2. Les altitudes : EU-DEM 25 m, par paquets de 100, un appel par seconde
# --------------------------------------------------------------------------

def altimetriser(points, paquet=100):
    altitudes = []
    total = (len(points) + paquet - 1) // paquet
    for index in range(0, len(points), paquet):
        tranche = points[index : index + paquet]
        corps = json.dumps(
            {"locations": "|".join("%s,%s" % (lat, lon) for lat, lon in tranche)}
        ).encode("utf-8")
        reponse = _appel(OPENTOPODATA, corps=corps)
        if reponse.get("status") != "OK":
            raise SystemExit("opentopodata a repondu %s" % reponse.get("status"))
        for resultat in reponse["results"]:
            valeur = resultat.get("elevation")
            altitudes.append(None if valeur is None else round(float(valeur), 1))
        sys.stderr.write("  altitudes %d/%d\n" % (index // paquet + 1, total))
        sys.stderr.flush()
        time.sleep(1.05)
    return altitudes


# --------------------------------------------------------------------------
# 3. L ecriture : GPX avec attribution ODbL et lien vers la relation
# --------------------------------------------------------------------------

def ecrire_gpx(chemin, nom, slug, relation_id, points, altitudes, longueur_km, median_m):
    aujourdhui = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    desc = (
        "Trace du sentier %s. Geometrie relevee dans OpenStreetMap "
        "(relation %d, itineraire de randonnee balise), %d points, "
        "espacement median %.0f m, %.3f km. Altitudes issues du modele "
        "numerique de terrain %s."
        % (nom, relation_id, len(points), median_m, longueur_km, MODELE)
    )
    lignes = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<gpx version="1.1" creator="MoteurGR-%s"' % slug,
        '     xmlns="http://www.topografix.com/GPX/1/1"',
        '     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
        '     xsi:schemaLocation="http://www.topografix.com/GPX/1/1',
        '       http://www.topografix.com/GPX/1/1/gpx.xsd">',
        "  <metadata>",
        "    <name>%s</name>" % nom,
        "    <desc>%s</desc>" % desc,
        "    <time>%s</time>" % aujourdhui,
        '    <copyright author="OpenStreetMap contributors">',
        "      <license>https://opendatacommons.org/licenses/odbl/</license>",
        "    </copyright>",
        '    <link href="https://www.openstreetmap.org/relation/%d">' % relation_id,
        "      <text>%s dans OpenStreetMap</text>" % nom,
        "    </link>",
        "  </metadata>",
        "  <trk>",
        "    <name>%s</name>" % slug,
        "    <trkseg>",
    ]
    for (lat, lon), ele in zip(points, altitudes):
        if ele is None:
            lignes.append('      <trkpt lat="%s" lon="%s"/>' % (lat, lon))
        else:
            lignes.append(
                '      <trkpt lat="%s" lon="%s"><ele>%s</ele></trkpt>' % (lat, lon, ele)
            )
    lignes += ["    </trkseg>", "  </trk>", "</gpx>", ""]
    dossier = os.path.dirname(os.path.abspath(chemin))
    if dossier and not os.path.isdir(dossier):
        os.makedirs(dossier)
    with open(chemin, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lignes))


def main():
    arg = argparse.ArgumentParser(description="Releve et altimetrise une trace OSM.")
    arg.add_argument("--relation", type=int, required=True)
    arg.add_argument("--nom", required=True)
    arg.add_argument("--slug", required=True)
    arg.add_argument("--sortie", required=True)
    arg.add_argument("--releve", help="Fichier JSON ou ecrire le releve de l assemblage")
    arg.add_argument(
        "--ignorer-role",
        action="append",
        default=[],
        help="Role de membre a ne pas enchainer (ex. alternative, approach)",
    )
    arg.add_argument("--tolerer-trous", action="store_true")
    arg.add_argument(
        "--depart",
        help="lat,lon du depart voulu : la trace est retournee si elle part de l autre bout",
    )
    arg.add_argument(
        "--geometrie-seule",
        action="store_true",
        help="S arrete apres la geometrie, sans appeler le modele d altitude",
    )
    options = arg.parse_args()

    sys.stderr.write("Relation OSM %d ...\n" % options.relation)
    points, releve = assembler(
        lire_relation(options.relation), options.relation, tuple(options.ignorer_role)
    )
    releve["premier_point"] = points[0]
    releve["dernier_point"] = points[-1]
    if options.depart:
        voulu = tuple(float(x) for x in options.depart.split(","))
        au_debut = distance_m(voulu, points[0])
        a_la_fin = distance_m(voulu, points[-1])
        releve["depart_voulu"] = list(voulu)
        releve["depart_ecart_m"] = round(min(au_debut, a_la_fin), 1)
        releve["retournee"] = a_la_fin < au_debut
        if releve["retournee"]:
            points.reverse()
            sys.stderr.write(
                "  RETOURNEE : le depart voulu est a %.0f m de la fin de la relation "
                "et a %.0f m de son debut.\n" % (a_la_fin, au_debut)
            )
        else:
            sys.stderr.write("  sens conserve, depart a %.0f m du point voulu\n" % au_debut)
    sys.stderr.write(
        "  %d chemins membres (%d retenus), %d points, %d inversions, %d ruptures\n"
        % (
            releve["chemins_membres_total"],
            releve["chemins_retenus"],
            releve["points"],
            releve["inversions"],
            len(releve["ruptures"]),
        )
    )
    sys.stderr.write("  roles : %s\n" % releve["roles"])
    if releve["chemins_absents"]:
        sys.stderr.write("  CHEMINS ABSENTS : %s\n" % releve["chemins_absents"])
    for rupture in releve["ruptures"][:20]:
        sys.stderr.write(
            "  RUPTURE rang %d, ecart %.1f m\n" % (rupture["rang"], rupture["ecart_m"])
        )

    ecarts = [distance_m(points[i], points[i + 1]) for i in range(len(points) - 1)]
    longueur_km = sum(ecarts) / 1000.0
    ecarts_tries = sorted(ecarts)
    median_m = ecarts_tries[len(ecarts_tries) // 2] if ecarts_tries else 0.0
    sys.stderr.write("  %.3f km, espacement median %.1f m\n" % (longueur_km, median_m))
    releve["longueur_km"] = round(longueur_km, 3)
    releve["espacement_median_m"] = round(median_m, 1)

    if options.geometrie_seule:
        if options.releve:
            with open(options.releve, "w", encoding="utf-8") as f:
                json.dump(releve, f, ensure_ascii=False, indent=2)
            sys.stderr.write("Releve : %s\n" % options.releve)
        return

    sys.stderr.write("Altitudes %s ...\n" % MODELE)
    altitudes = altimetriser(points)
    trous = [i for i, a in enumerate(altitudes) if a is None]
    releve["altitudes_obtenues"] = len(altitudes) - len(trous)
    releve["altitudes_manquantes"] = trous

    if trous and not options.tolerer_trous:
        sys.stderr.write(
            "ARRET : %d altitudes n ont pas pu etre obtenues (indices %s...). "
            "Rien n a ete ecrit, rien n a ete interpole.\n" % (len(trous), trous[:20])
        )
        raise SystemExit(2)
    if trous:
        sys.stderr.write("  %d trous TOLERES, points sans <ele> : %s\n" % (len(trous), trous))

    ecrire_gpx(
        options.sortie,
        options.nom,
        options.slug,
        options.relation,
        points,
        altitudes,
        longueur_km,
        median_m,
    )
    sys.stderr.write("Ecrit : %s\n" % options.sortie)
    if options.releve:
        with open(options.releve, "w", encoding="utf-8") as f:
            json.dump(releve, f, ensure_ascii=False, indent=2)
        sys.stderr.write("Releve : %s\n" % options.releve)


if __name__ == "__main__":
    main()
