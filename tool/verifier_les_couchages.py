#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""QA du releve des couchages (tache 838) : on verifie AVANT de montrer.

Cinq controles, et chacun peut faire echouer le rendu :
  1. les fins d etape sont-elles reconnues et ecartees, une par une ?
  2. les cas connus du GR20 tombent-ils sur des chiffres plausibles ?
  3. les trous : couchages sans chemin, altitudes manquantes, cas limites ;
  4. la coherence des points kilometriques et des doublons d objets OSM ;
  5. le total, et de quoi il est fait.

Usage :
    python tool/verifier_les_couchages.py \
        assets/data/gr20/couchages_hors_etape.json tool/coupures_gr20.json
"""

import json
import math
import sys

RAYON_TERRE_M = 6371008.8

# Les couchages dont la realite du terrain est connue, et qui servent d etalon.
ETALONS = (
    "Vergio", "San Petru", "Ballone", "Matalza", "Basseta", "Croci",
    "Monte d", "Fugone", "Bavella", "Vaccaghja", "Pozzi", "Radule",
    "Capanelle", "Tolla", "Verde",
)


def distance_m(a, b):
    la1, lo1, la2, lo2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    h = (
        math.sin((la2 - la1) / 2) ** 2
        + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    )
    return 2 * RAYON_TERRE_M * math.asin(math.sqrt(h))


def titre(n, texte):
    print()
    print("=" * 78)
    print("QA %d — %s" % (n, texte))
    print("=" * 78)


def main():
    releve = json.load(open(sys.argv[1], encoding="utf-8"))
    coupures = json.load(open(sys.argv[2], encoding="utf-8"))
    lignes = releve["couchages"]

    titre(1, "LES FINS D ETAPE SONT-ELLES RECONNUES ET ECARTEES ?")
    manques = []
    for c in coupures:
        trouves = [
            l for l in lignes
            if l["deja_une_fin_d_etape"] and l["deja_une_fin_d_etape"]["nom"] == c["nom"]
        ]
        if trouves:
            print("  OK   %-42s %s" % (
                c["nom"][:42],
                ", ".join("%s (%.0f m)" % (t["nom"][:30], t["deja_une_fin_d_etape"]["ecart_m"])
                          for t in trouves)))
        else:
            manques.append(c["nom"])
            proches = sorted(
                lignes, key=lambda l: distance_m((c["lat"], c["lon"]), (l["lat"], l["lon"]))
            )[:3]
            print("  VIDE %-42s rien a 150 m ; les plus proches : %s" % (
                c["nom"][:42],
                ", ".join("%s %.0f m" % (p["nom"][:24],
                          distance_m((c["lat"], c["lon"]), (p["lat"], p["lon"])))
                          for p in proches)))
    print("\n  -> %d fins d etape sans couchage reconnu a 150 m : %s"
          % (len(manques), manques))

    titre(2, "LES CAS CONNUS DU GR20, CONTROLE AVEC LA REALITE DU TERRAIN")
    for cle in ETALONS:
        for l in lignes:
            if cle.lower() not in l["nom"].lower():
                continue
            pk = "%.2f" % (l["pk_m"] / 1000.0) if l.get("pk_m") is not None else "   -"
            if l.get("chemin_trace"):
                print("  PK %6s  %-32s %-16s %5d m  aller %3d min  retour %3d min  "
                      "D+ %4d/%4d  %s%s"
                      % (pk, l["nom"][:32], l["genre_en_clair"], l["longueur_totale_m"],
                         l["minutes_aller"], l["minutes_retour"], l["dplus_aller_m"],
                         l["dplus_retour_m"], l["classe"],
                         "  [FIN ETAPE %s]" % l["deja_une_fin_d_etape"]["etape_app"]
                         if l["deja_une_fin_d_etape"] else ""))
            else:
                print("  PK %6s  %-32s %-16s SANS CHEMIN TRACE : %s"
                      % (pk, l["nom"][:32], l["genre_en_clair"], l["pourquoi"][:62]))

    titre(3, "LES TROUS ET LES CAS LIMITES")
    sans = [l for l in lignes if not l.get("chemin_trace")]
    print("  %d couchages sans chemin trace :" % len(sans))
    for l in sorted(sans, key=lambda x: x.get("raccord_ecart_m", 0)):
        print("     %-34s %-16s raccord %7.0f m  %s"
              % (l["nom"][:34], l["genre_en_clair"], l.get("raccord_ecart_m", -1),
                 l["pourquoi"][:56]))
    trous = [l for l in lignes if l.get("altitudes_manquantes")]
    print("  altitudes manquantes : %d itineraires concernes" % len(trous))
    for l in trous:
        print("     %-40s %d manquantes" % (l["nom"][:40], l["altitudes_manquantes"]))
    bords = [
        l for l in lignes
        if l.get("chemin_trace") and not l["sous_le_seuil"]
        and min(l["minutes_aller"], l["minutes_retour"]) <= 30
        < max(l["minutes_aller"], l["minutes_retour"]) <= 40
    ]
    print("  %d couchages hors seuil dans UN SEUL sens (30 < t <= 40) :" % len(bords))
    for l in sorted(bords, key=lambda x: x["pk_m"]):
        print("     PK %6.2f  %-32s aller %3d  retour %3d  (modele 2 : %3d / %3d)"
              % (l["pk_m"] / 1000.0, l["nom"][:32], l["minutes_aller"],
                 l["minutes_retour"], l["minutes_aller_eta"], l["minutes_retour_eta"]))

    titre(4, "COHERENCE DES POINTS KILOMETRIQUES ET DOUBLONS OSM")
    avec = [l for l in lignes if l.get("pk_m") is not None]
    print("  PK min %.3f km, PK max %.3f km, longueur de la trace %.3f km"
          % (min(l["pk_m"] for l in avec) / 1000,
             max(l["pk_m"] for l in avec) / 1000, releve["trace_longueur_km"]))
    hors = [l for l in avec
            if l["pk_m"] < 0 or l["pk_m"] > releve["trace_longueur_km"] * 1000 + 1]
    print("  PK hors trace : %d" % len(hors))
    noms = {}
    for l in lignes:
        noms.setdefault(l["nom"], []).append(l["osm"])
    doublons = dict((k, v) for k, v in noms.items() if len(v) > 1)
    print("  %d noms portes par plusieurs objets OSM :" % len(doublons))
    for k, v in sorted(doublons.items()):
        print("     %-40s %s" % (k[:40], " ".join(v)))

    titre(5, "LE TOTAL, ET DE QUOI IL EST FAIT")
    for cle in ("couchages_releves", "couchages_declares",
                "couchages_nommes_sans_etiquette", "avec_chemin_trace",
                "sans_chemin_trace", "deja_fins_d_etape",
                "sous_le_seuil_hors_etape", "nouvelles_nuits_possibles",
                "dont_coupures_de_jour_nouvelles",
                "dont_un_lit_a_la_place_du_dortoir", "dont_tetes_de_sentier"):
        print("  %-40s %s" % (cle, releve[cle]))
    print("  les deux modeles divergent sur %d couchages :"
          % len(releve["les_deux_modeles_divergent_sur"]))
    for x in releve["les_deux_modeles_divergent_sur"]:
        print("     PK %6.2f %-30s decoupage %3d/%3d  arrivee %3d/%3d  -> passe selon %s"
              % (x["pk_km"], x["nom"][:30], x["decoupage_aller_min"],
                 x["decoupage_retour_min"], x["eta_aller_min"], x["eta_retour_min"],
                 x["modele_qui_passe"]))


if __name__ == "__main__":
    main()
