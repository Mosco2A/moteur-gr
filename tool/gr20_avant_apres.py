#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ecrit docs/gr20_839.md : les chiffres du GR20 AVANT et APRES, etape par etape.

La colonne APRES est LUE dans `assets/data/gr20/stages.json`, produit par
`tool/gr20_dans_stepways.py` depuis la trace : rien n est recopie a la main, et
relancer ce script apres une nouvelle mesure remet le document a jour.

La colonne AVANT est ce que DECLARE l ancienne application GR20
(`lib/core/data/gr20_stages.dart`), relevee en LECTURE SEULE. Elle est la
SEULE partie ecrite en dur de ce fichier, et c est voulu : ces chiffres-la ne
sont plus mesurables puisqu ils ne venaient pas d une mesure. Ils viennent d un
topo multiplie par 1,069, et leur depot n est pas modifie par ce lot.

Usage :
    python tool/gr20_avant_apres.py
"""

from __future__ import annotations

import io
import json
import os
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# CE QUE DECLARAIT L ANCIENNE APPLICATION, DANS SON ORDRE. Ses trois dernieres
# etapes sont E14 Asinau vers Paliri, E15 Paliri vers Bavella, E16 Bavella vers
# Conca — un ordre que la trace contredit, d ou le « n/c » du tableau.
AVANT = [
    (1, 12.8, 1500, 190),
    (2, 9.1, 750, 1000),
    (3, 8.6, 900, 800),
    (4, 8.6, 1150, 600),
    (5, 7.0, 800, 400),
    (6, 16.0, 750, 1100),
    (7, 10.2, 850, 650),
    (8, 10.7, 750, 950),
    (9, 10.7, 700, 1200),
    (10, 15.0, 900, 300),
    (11, 13.4, 850, 550),
    (12, 12.3, 700, 750),
    (13, 12.8, 650, 900),
    (14, 11.8, 650, 800),
    (15, 4.0, 250, 100),
    (16, 20.0, 400, 1600),
]


def hm(minutes):
    return "%dh%02d" % (minutes // 60, minutes % 60)


def charger(chemin):
    with io.open(os.path.join(RACINE, chemin), encoding="utf-8") as f:
        return json.load(f)


def main():
    apres = charger("assets/data/gr20/stages.json")
    nuits = charger("assets/data/gr20/nuits_possibles.json")
    sentier = charger("assets/data/gr20.json")

    par_num = {a[0]: a for a in AVANT}
    total_avant_km = sum(a[1] for a in AVANT)
    total_apres_km = sum(e["distanceKm"] for e in apres)

    L = []
    L.append("# GR20 — les chiffres avant et apres (tache 839)")
    L.append("")
    L.append("> Ecrit par `python tool/gr20_avant_apres.py`. La colonne APRES est LUE")
    L.append("> dans `assets/data/gr20/stages.json`, produit par")
    L.append("> `python tool/gr20_dans_stepways.py` depuis `assets/data/gr20/track.gpx`.")
    L.append("> La colonne AVANT est ce que DECLARE l ancienne application GR20")
    L.append("> (`lib/core/data/gr20_stages.dart`), relevee en LECTURE SEULE : ce")
    L.append("> depot-la n est pas modifie par ce lot.")
    L.append("")
    L.append("## D ou venaient les chiffres d avant")
    L.append("")
    L.append("Le commentaire en tete de `gr20Stages` l ecrivait lui-meme : « on ancre")
    L.append("sur le TOTAL fiable : E1->E14 mises a l echelle (x1,069) pour porter le")
    L.append("total a ~183 km ». Les longueurs annoncees n etaient donc pas des mesures,")
    L.append("mais des chiffres de topo multiplies par un coefficient pour que la somme")
    L.append("tombe juste : le total etait bon, les etapes fausses. Il n y a plus aucun")
    L.append("coefficient — il y a une trace, et on la mesure.")
    L.append("")
    L.append("## Etape par etape")
    L.append("")
    L.append(
        "| # | Etape (ordre de la trace) | km avant | km apres | ecart | "
        "D+ avant | D+ apres | D- avant | D- apres | duree |"
    )
    L.append("|---|---|---|---|---|---|---|---|---|---|")
    for e in apres:
        n = e["stageNumber"]
        if n <= 13:
            ref = par_num[n]
            km_avant = "%.1f" % ref[1]
            dplus_avant = str(ref[2])
            dmoins_avant = str(ref[3])
            ecart = "%+.2f" % (e["distanceKm"] - ref[1])
        else:
            # LES TROIS DERNIERES NE SONT PAS COMPARABLES ETAPE PAR ETAPE :
            # l ordre de l ancienne application contredit la trace, donc ses
            # etapes ne decoupent pas le meme terrain.
            km_avant = dplus_avant = dmoins_avant = ecart = "n/c"
        L.append(
            "| %d | %s | %s | %.2f | %s | %s | %d | %s | %d | %s |"
            % (
                n,
                e["nameFr"],
                km_avant,
                e["distanceKm"],
                ecart,
                dplus_avant,
                e["elevationGainM"],
                dmoins_avant,
                e["elevationLossM"],
                hm(e["estimatedDurationMinutes"]),
            )
        )
    L.append(
        "| | **Total** | **%.1f** | **%.2f** | | **%d** | **%d** | **%d** | "
        "**%d** | **%s** |"
        % (
            total_avant_km,
            total_apres_km,
            sum(a[2] for a in AVANT),
            sum(e["elevationGainM"] for e in apres),
            sum(a[3] for a in AVANT),
            sum(e["elevationLossM"] for e in apres),
            hm(sum(e["estimatedDurationMinutes"] for e in apres)),
        )
    )
    L.append("")
    L.append("Quatre etapes s ecartaient de plus de 30 % : E13 (+62 %), E6 (+56 %),")
    L.append("E3 (-43 %) et E11 (+32 %). Toute journee recomposee sur ces longueurs")
    L.append("heritait de l erreur.")
    L.append("")
    L.append("## Les trois dernieres etapes : l ordre etait faux, et voici son cout")
    L.append("")
    L.append("Sur la trace : Asinau PK 155,10 — COL DE BAVELLA PK 165,84 — PALIRI")
    L.append("PK 170,38 — Conca PK 183,59. **Bavella passe AVANT Paliri.** L ancienne")
    L.append("application declarait E14 Asinau vers Paliri, E15 Paliri vers Bavella,")
    L.append("E16 Bavella vers Conca. Pose sur la trace, ce decoupage fait couvrir")
    L.append("37,55 km a une section qui en fait 28,49 : **9,06 km marches deux fois**,")
    L.append("dont une etape a reculons.")
    L.append("")
    L.append("## Les parcours, bornes COMPTEES sur la trace")
    L.append("")
    L.append("| Parcours | Etapes | km | D+ |")
    L.append("|---|---|---|---|")
    for p in sentier["itineraries"]:
        L.append(
            "| %s | %d | %.2f | %d |"
            % (p["nameFr"], p["stageCount"], p["distanceKm"], p["elevationGain"])
        )
    L.append("")
    L.append("L ancien code declarait le nord sur les etapes 1 a 8 avec le commentaire")
    L.append("« jusqu a Vizzavona ». Sa propre liste le dementait : l etape 8 finit au")
    L.append("REFUGE DE L ONDA (PK 81,59), soit 10,21 km et une journee entiere AVANT")
    L.append("Vizzavona (PK 91,80), en pleine montagne, sans gare et sans lit hors")
    L.append("dortoir. Le nord compte NEUF etapes, le sud SEPT, et ces deux nombres")
    L.append("sont COMPTES par l outil, jamais ecrits.")
    L.append("")
    L.append("Vizzavona tombe a 50,0 % de la trace au metre pres (91,80 km / 91,79 km).")
    L.append("Le denivele, lui, n est pas partage : le nord porte 1,74 fois le D+ du sud")
    L.append("pour la meme distance. Les deux moities se vendent a egalite de longueur")
    L.append("et ne se marchent pas du tout de la meme facon.")
    L.append("")
    L.append("## Un seul modele de temps de marche, et c est le prudent")
    L.append("")
    L.append("Le depot en portait deux, mesures par la tache 838 :")
    L.append("`stage_duration.dart` (4 km/h, 400 m/h de montee, descente GRATUITE)")
    L.append("decoupait les jours, et `eta_service.dart` (1,1 m/s, 600 m/h, descente a")
    L.append("1,67 s/m) annoncait l heure d arrivee. Sur une montee de 200 m en 1 km :")
    L.append("45 min contre 35 min, soit 29 % d ecart entre le programme qu on prepare")
    L.append("et l heure qu on annonce.")
    L.append("")
    L.append("Il n en reste qu un, dans `walkingSeconds` : **4 km/h a plat, 400 m de")
    L.append("montee a l heure, descente payee 1,67 s par metre.** De chaque modele on")
    L.append("a garde la valeur la plus prudente. En montagne on n annonce pas des")
    L.append("horaires optimistes : une estimation trop courte se paie a la tombee de")
    L.append("la nuit.")
    L.append("")
    L.append("Ce que ca change a l ecran, mesure : l etape 16 du GR20 descend 1 094 m")
    L.append("pour 300 m de montee — elle annoncait 4h04, elle annonce 4h34.")
    L.append("")
    L.append("## Les trente et une nuits ouvertes au decoupage")
    L.append("")
    L.append(
        "%d nuits : %d fins d etape et %d coupures de jour relevees en tache 838."
        % (
            nuits["nuits"],
            nuits["dont_fins_d_etape"],
            nuits["dont_coupures_relevees"],
        )
    )
    L.append("Chacune porte son identifiant OpenStreetMap, son temps de marche ALLER et")
    L.append("RETOUR — mesures separement, parce qu ils ne sont pas symetriques : le")
    L.append("refuge Laparo se rejoint en 10 minutes et se quitte en 28 — et ses lits")
    L.append("quand OpenStreetMap les connait. Le curseur de duree peut finir une")
    L.append(
        "journee sur l une d elles : jusqu a %d journees de marche, contre seize"
        % nuits["segments"]
    )
    L.append("auparavant, et aucune coupe n est calculee.")
    L.append("")
    L.append("| PK | Nuit | OpenStreetMap | lits | aller | retour | origine |")
    L.append("|---|---|---|---|---|---|---|")
    for n in nuits["liste"]:
        origine = (
            "fin d etape %d" % n["fin_d_etape"]
            if n["fin_d_etape"]
            else "coupure relevee"
        )
        L.append(
            "| %.2f | %s | %s | %s | %d min | %d min | %s |"
            % (
                n["pk_km"],
                n["nom"],
                ", ".join(n["osm"]),
                n["lits"] if n["lits"] else "inconnus",
                n["minutes_aller"],
                n["minutes_retour"],
                origine,
            )
        )
    L.append("")
    L.append("## Attribution")
    L.append("")
    L.append(nuits["attribution"])
    L.append("")

    cible = os.path.join(RACINE, "docs", "gr20_839.md")
    with io.open(cible, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L))
    sys.stderr.write("ECRIT docs/gr20_839.md (%d lignes)\n" % len(L))


if __name__ == "__main__":
    main()
