#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Mesure les etapes SUR la trace : ordre reel, longueur, denivele, point kilometrique.

Aucune mise a l echelle, aucun chiffre de topo : tout vient de la trace passee
en parametre. Les coupures sont des objets OpenStreetMap nommes (voir
tool/reperes_osm.py) : le script projette chacun sur la trace, en deduit son
point kilometrique, puis TRIE PAR POINT KILOMETRIQUE. L ordre rendu est donc
celui de la trace, pas celui qu on croyait.

TROIS DENIVELES PAR ETAPE, ET C EST VOULU. Un modele de terrain a 25 m de
resolution echantillonne tous les 15 m tremble : la somme brute de ses ecarts
compte le tremblement comme du relief. Le chiffre depend donc du filtre, et
cacher ce fait derriere un seul nombre serait mentir.
  - "mesure" : moyenne glissante sur 7 points, puis un point sur 7, somme sans
    seuil. CE FILTRE A ETE CALIBRE, pas choisi : applique a la trace du Mare a
    Mare Centre il rend D+ 4 263 m quand le chiffre publie de ce sentier est
    4 274 m (memoire #101703), soit 0,26 % d ecart. C est donc le procede qui
    reproduit le chiffre de la maison, et c est celui que je retiens.
  - "socle"  : ce que calculerait l application telle qu elle est aujourd hui
    (computeTrackStatsOn : ecart entre deux points consecutifs, jete sous
    GeoUtils.elevationNoiseThresholdM = 3 m). Donne a titre de comparaison :
    sur une trace dense ce calcul sous-compte, defaut deja releve en #101703.
  - "brut"   : somme de tous les ecarts du modele, sans filtre. Borne haute.

Usage :
    python tool/mesurer_les_etapes.py --trace assets/data/gr20/track.gpx \
        --coupures tool/coupures_gr20.json --sortie mesure.json
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys

RAYON_TERRE_M = 6371008.8
SEUIL_BRUIT_M = 3.0  # GeoUtils.elevationNoiseThresholdM
FENETRE_LISSAGE = 7  # memoire #101703 : "profil EU-DEM lisse sur 7 points"
PAS_ECHANTILLON = 7  # un point sur 7 apres lissage : calibre sur le Mare a Mare


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
    h = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return 2 * RAYON_TERRE_M * math.asin(math.sqrt(h))


def _plan(point, origine):
    """Projection plane locale en metres autour d origine : suffisante a 10 km."""
    lat0 = math.radians(origine[0])
    x = math.radians(point[1] - origine[1]) * RAYON_TERRE_M * math.cos(lat0)
    y = math.radians(point[0] - origine[0]) * RAYON_TERRE_M
    return x, y


def projeter(repere, points, cumul):
    """Point kilometrique du repere et son ecart a la trace, projete sur les segments.

    On cherche le point le plus proche sur la POLYLIGNE, pas le sommet le plus
    proche : sur un segment de 15 m l ecart est minime, mais le geste est le bon
    et il reste juste si la trace s eclaircit.
    """
    meilleur = None
    # Pre-selection grossiere : le sommet le plus proche, puis ses voisins.
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
        t = 0.0 if norme == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / norme))
        qx, qy = ax + t * dx, ay + t * dy
        ecart = math.hypot(px - qx, py - qy)
        if meilleur is None or ecart < meilleur[0]:
            longueur = cumul[i + 1] - cumul[i]
            meilleur = (ecart, cumul[i] + t * longueur, i)
    return {"ecart_m": meilleur[0], "pk_m": meilleur[1], "index": meilleur[2]}


def lisser(altitudes, fenetre):
    """Moyenne glissante centree ; un trou (None) interrompt le lissage pour ce point."""
    demi = fenetre // 2
    lisses = []
    for i in range(len(altitudes)):
        tranche = [
            a
            for a in altitudes[max(0, i - demi) : min(len(altitudes), i + demi + 1)]
            if a is not None
        ]
        lisses.append(None if not tranche else sum(tranche) / len(tranche))
    return lisses


def denivele(altitudes, seuil):
    gain = perte = 0.0
    manquants = 0
    for i in range(1, len(altitudes)):
        a, b = altitudes[i - 1], altitudes[i]
        if a is None or b is None:
            manquants += 1
            continue
        d = b - a
        if abs(d) >= seuil:
            if d > 0:
                gain += d
            else:
                perte += -d
    return gain, perte, manquants


def main():
    arg = argparse.ArgumentParser(description="Mesure les etapes sur la trace.")
    arg.add_argument("--trace", required=True)
    arg.add_argument("--coupures", required=True, help="JSON : liste de reperes nommes")
    arg.add_argument("--sortie", required=True)
    options = arg.parse_args()

    points, altitudes = lire_gpx(options.trace)
    cumul = [0.0]
    for i in range(1, len(points)):
        cumul.append(cumul[-1] + distance_m(points[i - 1], points[i]))
    sys.stderr.write(
        "Trace : %d points, %d altitudes, %.3f km\n"
        % (len(points), sum(1 for a in altitudes if a is not None), cumul[-1] / 1000.0)
    )

    lisses = lisser(altitudes, FENETRE_LISSAGE)

    with open(options.coupures, encoding="utf-8") as f:
        coupures = json.load(f)

    # 1. Chaque coupure projetee sur la trace, puis TRIEE PAR POINT KILOMETRIQUE.
    for c in coupures:
        p = projeter((c["lat"], c["lon"]), points, cumul)
        c.update(
            {
                "pk_km": round(p["pk_m"] / 1000.0, 3),
                "ecart_trace_m": round(p["ecart_m"], 1),
                "index": p["index"],
                "altitude_trace_m": lisses[p["index"]],
            }
        )
    ordre_trace = sorted(coupures, key=lambda c: c["pk_km"])

    # 2. Les tranches entre coupures consecutives, dans l ordre de la trace.
    etapes = []
    for n in range(len(ordre_trace) - 1):
        depart, arrivee = ordre_trace[n], ordre_trace[n + 1]
        i, j = depart["index"], arrivee["index"]
        if j <= i:
            j = i + 1
        longueur_km = (arrivee["pk_km"] - depart["pk_km"])
        gain_m, perte_m, trous = denivele(lisses[i : j + 1 : PAS_ECHANTILLON], 0.0)
        gain_s, perte_s, _ = denivele(altitudes[i : j + 1], SEUIL_BRUIT_M)
        gain_b, perte_b, _ = denivele(altitudes[i : j + 1], 0.0)
        tranche = [a for a in altitudes[i : j + 1] if a is not None]
        etapes.append(
            {
                "rang_trace": n + 1,
                "depart": depart["nom"],
                "arrivee": arrivee["nom"],
                "etiquette_app": arrivee.get("etape_app"),
                "pk_depart_km": depart["pk_km"],
                "pk_arrivee_km": arrivee["pk_km"],
                "longueur_km": round(longueur_km, 2),
                "dplus_m": round(gain_m),
                "dmoins_m": round(perte_m),
                "dplus_socle_m": round(gain_s),
                "dmoins_socle_m": round(perte_s),
                "dplus_brut_m": round(gain_b),
                "dmoins_brut_m": round(perte_b),
                "altitude_min_m": round(min(tranche), 1) if tranche else None,
                "altitude_max_m": round(max(tranche), 1) if tranche else None,
                "altitudes_absentes": trous,
            }
        )

    gain_total_m, perte_total_m, _ = denivele(lisses[::PAS_ECHANTILLON], 0.0)
    gain_total_s, perte_total_s, _ = denivele(altitudes, SEUIL_BRUIT_M)
    gain_total_b, perte_total_b, _ = denivele(altitudes, 0.0)

    resultat = {
        "trace": options.trace,
        "points": len(points),
        "altitudes": sum(1 for a in altitudes if a is not None),
        "longueur_totale_km": round(cumul[-1] / 1000.0, 3),
        "methode_denivele": (
            "moyenne glissante sur %d points, puis un point sur %d, somme sans seuil ; "
            "calibree sur la trace du Mare a Mare Centre (rend 4263 m quand le chiffre "
            "publie de ce sentier est 4274 m, memoire #101703)"
            % (FENETRE_LISSAGE, PAS_ECHANTILLON)
        ),
        "dplus_total_m": round(gain_total_m),
        "dmoins_total_m": round(perte_total_m),
        "dplus_total_socle_m": round(gain_total_s),
        "dmoins_total_socle_m": round(perte_total_s),
        "dplus_total_brut_m": round(gain_total_b),
        "dmoins_total_brut_m": round(perte_total_b),
        "coupures_dans_l_ordre_de_la_trace": [
            {
                "nom": c["nom"],
                "etape_app": c.get("etape_app"),
                "pk_km": c["pk_km"],
                "ecart_trace_m": c["ecart_trace_m"],
                "altitude_trace_m": round(c["altitude_trace_m"], 1)
                if c["altitude_trace_m"] is not None
                else None,
                "osm": c.get("type_osm"),
            }
            for c in ordre_trace
        ],
        "etapes": etapes,
    }
    with open(options.sortie, "w", encoding="utf-8") as f:
        json.dump(resultat, f, ensure_ascii=False, indent=2)
    sys.stderr.write("Mesure : %s\n" % options.sortie)


if __name__ == "__main__":
    main()
