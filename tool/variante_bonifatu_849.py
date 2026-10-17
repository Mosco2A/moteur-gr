#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tache 849 : la VARIANTE par Bonifatu, mesuree comme un itineraire et non comme un detour.

POURQUOI CET OUTIL EXISTE, ET C EST UNE CORRECTION DE MA PROPRE MESURE. Le
releve de la partie UN cherche, pour chaque couchage, le plus court chemin
DEPUIS LA TRACE : il traite donc Bonifatu comme un DETOUR, et il le trouve en
quittant la trace au PK 8,748 km pour descendre 973 m en vallee. C est juste
pour la question « combien coute un aller-retour depuis le sentier », et c est
FAUX pour la facon dont on dort reellement a Bonifatu.

Les topoguides decrivent autre chose : on ne descend pas du GR20 pour aller a
Bonifatu, on y va DIRECTEMENT depuis Calenzana par un autre sentier (le Tra
Mare e Monti), puis on remonte sur le GR20 par le chemin de Melaghja. Ce n est
pas un detour, c est une VARIANTE : deux itineraires differents entre les deux
memes points. L outil mesure donc les deux troncons de cette variante comme des
itineraires a part entiere, avec le meme filtre de denivele et le meme modele
de temps de marche que tout le reste du depot.

CE QUE CA PERMET DE DIRE, ET C EST LE COEUR DE LA QUESTION POSEE. La partie UN
montre que dormir a Bonifatu EN DETOUR fait a peine descendre la journee la
plus dure (1 455 m a 1 315 m). Si la variante, elle, partage vraiment la montee
en deux, alors le plancher du sentier n est plus celui de la trace — et il faut
le dire. Si elle ne la partage pas davantage, il faut le dire aussi. Dans les
deux cas le chiffre tranche, pas l intuition.

LIMITE ASSUMEE ET ECRITE : le plus court chemin est minimise en METRES sur le
reseau pieton d OpenStreetMap, pas en minutes, et `access=private` / `foot=no`
ne sont pas filtres (meme limite que la tache 838). Le reseau releve est celui
du cache de la partie UN : 8 km autour du premier segment.

Usage :
  python tool/variante_bonifatu_849.py --cache <cache de la partie UN> \
      --sortie assets/data/gr20/variante_bonifatu_849.json
"""

import argparse
import heapq
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import couchages_du_couloir as c838  # noqa: E402

# Les trois points de la variante. Calenzana et l Ortu di u Piobbu sont pris
# sur la trace mesuree (tache 837) ; l Auberge de la Foret est le noeud
# OpenStreetMap trouve par la partie UN.
CALENZANA = (42.5081535, 8.8548477)
AUBERGE_BONIFATU = (42.442205, 8.854176)
ORTU_DI_U_PIOBBU = (42.4652, 8.90688)

VITESSE_PLAT_KMH = 4.0
MONTEE_S_PAR_M = 3600.0 / 400.0
DESCENTE_S_PAR_M = 10.0 / 6.0


def minutes_de_marche(metres, dplus, dmoins):
    secondes = (
        metres / (VITESSE_PLAT_KMH * 1000.0 / 3600.0)
        + dplus * MONTEE_S_PAR_M
        + dmoins * DESCENTE_S_PAR_M
    )
    return int(round(secondes / 60.0))


def dijkstra(graphe, depart, arrivee):
    """Le plus court chemin en METRES entre deux noeuds du reseau pieton."""
    dist = {depart: 0.0}
    parent = {}
    vus = set()
    tas = [(0.0, depart)]
    while tas:
        d, n = heapq.heappop(tas)
        if n in vus:
            continue
        vus.add(n)
        if n == arrivee:
            break
        for voisin, poids in graphe.get(n, ()):
            nd = d + poids
            if nd < dist.get(voisin, float("inf")):
                dist[voisin] = nd
                parent[voisin] = n
                heapq.heappush(tas, (nd, voisin))
    if arrivee not in dist:
        return None, None
    suite = [arrivee]
    while suite[-1] != depart:
        suite.append(parent[suite[-1]])
    suite.reverse()
    return dist[arrivee], suite


def main():
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--cache", required=True)
    arg.add_argument("--sortie", required=True)
    options = arg.parse_args()

    brut = c838.charger(os.path.join(options.cache, "reseau_brut.json"))
    noeuds = {}
    aretes = {}
    for e in brut.get("elements", []):
        if e["type"] == "node":
            noeuds[e["id"]] = (e["lat"], e["lon"])
    for e in brut.get("elements", []):
        if e["type"] != "way":
            continue
        ids = e.get("nodes", [])
        for a, b in zip(ids, ids[1:]):
            if a != b:
                aretes[(a, b) if a < b else (b, a)] = e["id"]
    graphe = c838.construire_graphe(noeuds, aretes)
    index = c838.grille_des_noeuds(noeuds, graphe)
    sys.stderr.write(
        "reseau : %d noeuds, %d aretes, %d noeuds relies\n"
        % (len(noeuds), len(aretes), len(graphe))
    )

    def noeud_le_plus_proche(point, nom):
        n, ecart = c838.raccord({"lat": point[0], "lon": point[1]}, noeuds, index)
        if n is None:
            raise SystemExit("REFUS : aucun noeud de reseau pres de %s." % nom)
        sys.stderr.write("  %s -> noeud %d a %.1f m\n" % (nom, n, ecart))
        return n, ecart

    n_cal, e_cal = noeud_le_plus_proche(CALENZANA, "Calenzana")
    n_bon, e_bon = noeud_le_plus_proche(AUBERGE_BONIFATU, "Auberge de la Foret")
    n_ortu, e_ortu = noeud_le_plus_proche(ORTU_DI_U_PIOBBU, "Ortu di u Piobbu")

    troncons = [
        ("Calenzana vers l Auberge de la Foret (Bonifatu)", n_cal, n_bon),
        ("Auberge de la Foret vers le refuge de l Ortu di u Piobbu", n_bon, n_ortu),
        ("Calenzana vers l Ortu di u Piobbu par le reseau (controle)", n_cal, n_ortu),
    ]

    a_demander = []
    echantillons = {}
    mesures = []
    for nom, a, b in troncons:
        metres, suite = dijkstra(graphe, a, b)
        if metres is None:
            sys.stderr.write("  AUCUN CHEMIN : %s\n" % nom)
            mesures.append({"nom": nom, "chemin": False})
            continue
        geo = [noeuds[n] for n in suite]
        ech = c838.reechantillonner(geo, 15.0)
        echantillons[nom] = ech
        a_demander.extend(ech)
        mesures.append(
            {"nom": nom, "chemin": True, "metres": round(metres, 1), "noeuds": len(suite)}
        )
        sys.stderr.write("  %s : %.0f m de sentier\n" % (nom, metres))

    cache_alt = c838.altimetriser(
        a_demander, os.path.join(options.cache, "altitudes_cache.json")
    )

    print()
    print("=" * 92)
    print("TACHE 849 — LA VARIANTE PAR BONIFATU, MESUREE COMME UN ITINERAIRE")
    print("=" * 92)
    print("Minimisation en METRES sur le reseau pieton OpenStreetMap ; filtre de")
    print("denivele de la 838 (lisse dedans, les deux bouts ancres) ; modele de")
    print("temps de marche unique du depot (la descente coute).")
    print()
    for m in mesures:
        if not m.get("chemin"):
            print("%-58s : AUCUN CHEMIN TRACE" % m["nom"][:58])
            continue
        ech = echantillons[m["nom"]]
        alts = [cache_alt.get("%.5f,%.5f" % (lat, lon)) for lat, lon in ech]
        manquantes = sum(1 for a in alts if a is None)
        dplus, dmoins = c838.denivele_maison(alts, ancrer=True)
        minutes = minutes_de_marche(m["metres"], dplus, dmoins)
        m.update(
            {
                "dplus_m": dplus,
                "dmoins_m": dmoins,
                "minutes": minutes,
                "altitudes_manquantes": manquantes,
                "altitude_depart_m": None if alts[0] is None else round(alts[0]),
                "altitude_arrivee_m": None if alts[-1] is None else round(alts[-1]),
            }
        )
        print(
            "%-58s : %6.3f km  D+%5d  D-%5d  %s  (%s m -> %s m)"
            % (
                m["nom"][:58],
                m["metres"] / 1000.0,
                dplus,
                dmoins,
                c838.en_clair(minutes),
                m["altitude_depart_m"],
                m["altitude_arrivee_m"],
            )
        )
        if manquantes:
            print("    ATTENTION : %d altitudes manquantes sur ce troncon." % manquantes)

    deux = [m for m in mesures[:2] if m.get("chemin")]
    verdict = None
    if len(deux) == 2:
        pire = max(m["dplus_m"] for m in deux)
        print()
        print("LA VARIANTE EN DEUX JOURNEES :")
        print("  journee 1 : %s" % deux[0]["nom"])
        print("              %.3f km, D+%d m, %s" % (deux[0]["metres"] / 1000.0, deux[0]["dplus_m"], c838.en_clair(deux[0]["minutes"])))
        print("  journee 2 : %s" % deux[1]["nom"])
        print("              %.3f km, D+%d m, %s" % (deux[1]["metres"] / 1000.0, deux[1]["dplus_m"], c838.en_clair(deux[1]["minutes"])))
        print()
        print("  >>> la plus dure des deux journees : D+%d m" % pire)
        print("      le premier segment du GR20 pese 1455 m dans une seule journee.")
        if pire >= 1500:
            verdict = "expert"
        elif pire >= 1000:
            verdict = "tres difficile"
        elif pire >= 700:
            verdict = "difficile"
        elif pire >= 400:
            verdict = "moyen"
        else:
            verdict = "facile"
        print("      verdict sur l echelle de Christophe : %s" % verdict.upper())
        print(
            "      gain sur la journee la plus dure : %d m"
            % (1455 - pire)
        )

    sortie = {
        "quoi": (
            "La variante par Bonifatu mesuree comme un ITINERAIRE (deux troncons du "
            "reseau pieton), et non comme un detour depuis la trace du GR20. Corrige "
            "la lecture de la partie UN, qui cherchait le plus court chemin DEPUIS LA "
            "TRACE et descendait donc 973 m depuis le PK 8,748 km."
        ),
        "tache": 849,
        "source": "OpenStreetMap, licence ODbL",
        "modele_terrain": c838.MODELE_TERRAIN,
        "limites": [
            "le plus court chemin est minimise en METRES, pas en minutes",
            "access=private et foot=no ne sont pas filtres",
            "le reseau est celui du couloir de 8 km de la partie UN",
        ],
        "points": {
            "calenzana": {"lat": CALENZANA[0], "lon": CALENZANA[1], "raccord_m": round(e_cal, 1)},
            "auberge_de_la_foret": {
                "lat": AUBERGE_BONIFATU[0],
                "lon": AUBERGE_BONIFATU[1],
                "raccord_m": round(e_bon, 1),
                "osm": "node/6431758926",
            },
            "ortu_di_u_piobbu": {
                "lat": ORTU_DI_U_PIOBBU[0],
                "lon": ORTU_DI_U_PIOBBU[1],
                "raccord_m": round(e_ortu, 1),
            },
        },
        "troncons": mesures,
        "pire_journee_de_la_variante_dplus_m": (
            None if len(deux) != 2 else max(m["dplus_m"] for m in deux)
        ),
        "verdict_de_la_variante": verdict,
        "segment_du_gr20_remplace": {"km": 11.349, "dplus_m": 1455, "dmoins_m": 194},
    }
    c838.sauver(options.sortie, sortie)
    print()
    print("Ecrit dans %s" % options.sortie)


if __name__ == "__main__":
    main()
