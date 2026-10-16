#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Releve dans OpenStreetMap les objets nommes qui bordent une relation d itineraire.

Sert a ancrer les coupures d etapes sur des objets REELS plutot que sur des
coordonnees saisies a la main. C est le geste de la tache 761 ("les huit points
de coupure sont ancres sur des objets OpenStreetMap nommes").

Usage :
    python tool/reperes_osm.py --relation 12484370 --sortie reperes.json
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.parse
import urllib.request

OVERPASS = "https://overpass-api.de/api/interpreter"
UA = "StepWays/1.0 (+https://github.com/Mosco2A/moteur-gr; christophe.mosconi@only1cent.com)"

REQUETE = """[out:json][timeout:300];
rel(%d);
way(r)->.w;
(
  node(around.w:800)["tourism"~"^(alpine_hut|wilderness_hut|hotel|hostel|guest_house|camp_site|chalet)$"];
  way(around.w:800)["tourism"~"^(alpine_hut|wilderness_hut|hotel|hostel|guest_house|camp_site|chalet)$"];
  node(around.w:1500)["railway"~"^(station|halt)$"];
  node(around.w:600)["natural"="saddle"];
  node(around.w:600)["mountain_pass"="yes"];
  node(around.w:2500)["place"~"^(village|town|hamlet)$"];
);
out center tags;
"""


def main():
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--relation", type=int, required=True)
    arg.add_argument("--sortie", required=True)
    options = arg.parse_args()

    url = OVERPASS + "?" + urllib.parse.urlencode({"data": REQUETE % options.relation})
    requete = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(requete, timeout=300) as reponse:
        donnees = json.loads(reponse.read().decode("utf-8"))

    reperes = []
    for e in donnees.get("elements", []):
        tags = e.get("tags", {})
        nom = tags.get("name")
        if not nom:
            continue
        if e["type"] == "node":
            lat, lon = e.get("lat"), e.get("lon")
        else:
            centre = e.get("center") or {}
            lat, lon = centre.get("lat"), centre.get("lon")
        if lat is None or lon is None:
            continue
        reperes.append(
            {
                "nom": nom,
                "type_osm": "%s/%s" % (e["type"], e["id"]),
                "lat": lat,
                "lon": lon,
                "genre": tags.get("tourism")
                or tags.get("railway")
                or tags.get("place")
                or ("col" if tags.get("natural") == "saddle" or tags.get("mountain_pass") else ""),
                "ele": tags.get("ele"),
            }
        )
    reperes.sort(key=lambda r: r["nom"])
    with open(options.sortie, "w", encoding="utf-8") as f:
        json.dump(reperes, f, ensure_ascii=False, indent=2)
    sys.stderr.write("%d reperes nommes ecrits dans %s\n" % (len(reperes), options.sortie))


if __name__ == "__main__":
    main()
