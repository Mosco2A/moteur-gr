#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tache 849 : que devient le plancher du GR20 si l on insere une nuit trouvee ?

La partie UN de la tache 849 a cherche, dans un couloir de 8 km et sans aucun
seuil de minutes, tout endroit ou dormir entre Calenzana et le refuge de l Ortu
di u Piobbu. Cet outil prend chaque trouvaille qui COUPE vraiment le premier
segment et repond a la seule question qui compte pour la fiche de vente : si on
dort la, la pire journee du sentier descend-elle sous 1 455 m ?

CE QU IL MESURE, ET IL NE L ESTIME PAS. Le premier segment est coupe en DEUX au
point kilometrique ou le sentier d acces quitte la trace — ce point est une
mesure de la partie UN, pas un choix. Les deux moities sont mesurees sur la
trace avec EXACTEMENT le filtre de denivele de la 839 (moyenne glissante sur
sept points, un point sur sept, les deux bouts ancres sur l altitude reelle),
donc leurs chiffres sont comparables au 1 455 m qu elles doivent remplacer. Un
controle le verifie : la somme des deux moities doit redonner le segment entier
a quelques metres pres, et l ecart est ECRIT.

LE DETOUR EST COMPTE DANS LA JOURNEE, comme la 839 l a etabli : on descend
dormir le soir, on remonte le matin. C est precisement ce qui fait la decision
ici, parce que le couchage trouve est EN VALLEE : y descendre coute peu et en
remonter coute cher, et un seul chiffre moyen aurait cache l essentiel.

Le fichier rendu a la forme de `nuits_possibles.json` : il est relu par le test
Dart `test/assets/sens_de_marche_849_test.dart`, qui fait tourner dessus LA
repartition du depot. Aucun chiffre de ce fichier n est saisi a la main.

Usage :
  python tool/inserer_une_nuit_849.py \
      --trace assets/data/gr20/track.gpx \
      --nuits assets/data/gr20/nuits_possibles.json \
      --trouvailles assets/data/gr20/nuits_premier_segment_849.json \
      --sortie assets/data/gr20/nuits_avec_insertion_849.json
"""

import argparse
import json
import math
import os
import sys
import xml.etree.ElementTree as ET

FENETRE_LISSAGE = 7
PAS_ECHANTILLON = 7
VITESSE_PLAT_KMH = 4.0
MONTEE_PAR_HEURE_M = 400.0
PLAT_M_PAR_S = VITESSE_PLAT_KMH * 1000.0 / 3600.0
MONTEE_S_PAR_M = 3600.0 / MONTEE_PAR_HEURE_M
DESCENTE_S_PAR_M = 10.0 / 6.0
RAYON_TERRE_M = 6371008.8


def arrondi(x):
    return int(round(x))


def distance_m(a, b):
    lat1, lon1 = math.radians(a[0]), math.radians(a[1])
    lat2, lon2 = math.radians(b[0]), math.radians(b[1])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    )
    return 2 * RAYON_TERRE_M * math.asin(math.sqrt(h))


def lire_gpx(chemin):
    arbre = ET.parse(chemin)
    ns = {"g": "http://www.topografix.com/GPX/1/1"}
    points, altitudes = [], []
    for pt in arbre.getroot().iterfind(".//g:trkpt", ns):
        ele = pt.find("g:ele", ns)
        points.append((float(pt.get("lat")), float(pt.get("lon"))))
        altitudes.append(None if ele is None else float(ele.text))
    return points, altitudes


def denivele_maison(altitudes, fenetre=FENETRE_LISSAGE, pas=PAS_ECHANTILLON):
    """Le filtre de la 839, a l identique : lisse dedans, ancre aux deux bouts."""
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
    secondes = (
        km * 1000.0 / PLAT_M_PAR_S
        + dplus_m * MONTEE_S_PAR_M
        + dmoins_m * DESCENTE_S_PAR_M
    )
    return arrondi(secondes / 60.0)


def main():
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--trace", required=True)
    arg.add_argument("--nuits", required=True)
    arg.add_argument("--trouvailles", required=True)
    arg.add_argument("--sortie", required=True)
    options = arg.parse_args()

    points, altitudes = lire_gpx(options.trace)
    if sum(1 for a in altitudes if a is None):
        raise SystemExit("REFUS : la trace porte des altitudes manquantes.")
    cumul = [0.0]
    for i in range(1, len(points)):
        cumul.append(cumul[-1] + distance_m(points[i - 1], points[i]))

    def index_du_pk(pk_m):
        return min(range(len(cumul)), key=lambda k: abs(cumul[k] - pk_m))

    nuits = json.load(open(options.nuits, encoding="utf-8"))
    trouve = json.load(open(options.trouvailles, encoding="utf-8"))
    segment1 = nuits["entre_les_nuits"][0]
    pk_fin = segment1["pk_arrivee_km"] * 1000.0

    # CONTROLE : le segment entier, remesure ici, doit redonner le chiffre
    # de la 839. Sans ce controle, une moitie mesuree autrement ne voudrait
    # rien dire.
    i0, i1 = index_du_pk(0.0), index_du_pk(pk_fin)
    dplus_entier, dmoins_entier = denivele_maison(altitudes[i0 : i1 + 1])
    print("CONTROLE DU SEGMENT ENTIER")
    print(
        "  la 839 dit D+%d / D-%d ; remesure ici D+%d / D-%d"
        % (segment1["dplus_m"], segment1["dmoins_m"], dplus_entier, dmoins_entier)
    )
    if abs(dplus_entier - segment1["dplus_m"]) > 2:
        raise SystemExit(
            "REFUS : la remesure du segment entier s ecarte de la 839 de %d m."
            % abs(dplus_entier - segment1["dplus_m"])
        )
    print("  ecart de %d m : la mesure est la meme. On peut couper." % abs(dplus_entier - segment1["dplus_m"]))
    print()

    candidats = trouve["coupures_trouvees"]
    if not candidats:
        print("Aucune trouvaille ne coupe le premier segment : rien a inserer.")
        return

    print("CE QUE CHAQUE TROUVAILLE DONNE SI L ON DORT LA")
    print("=" * 100)
    rendus = []
    for c in candidats:
        pk = c["pk_m"]
        ic = index_du_pk(pk)
        km_avant = round(pk / 1000.0, 3)
        km_apres = round((pk_fin - pk) / 1000.0, 3)
        dplus_a, dmoins_a = denivele_maison(altitudes[i0 : ic + 1])
        dplus_b, dmoins_b = denivele_maison(altitudes[ic : i1 + 1])
        ecart = (dplus_a + dplus_b) - dplus_entier

        # LA JOURNEE REELLE, DETOUR COMPRIS. Jour 1 : la premiere moitie de la
        # trace, PUIS la descente au couchage. Jour 2 : la REMONTEE depuis le
        # couchage, PUIS la seconde moitie.
        j1_dplus = dplus_a + c["dplus_aller_m"]
        j1_dmoins = dmoins_a + c["dmoins_aller_m"]
        j2_dplus = c["dplus_retour_m"] + dplus_b
        j2_dmoins = c["dmoins_retour_m"] + dmoins_b
        j1_min = minutes_de_marche(km_avant, dplus_a, dmoins_a) + c["minutes_aller"]
        j2_min = c["minutes_retour"] + minutes_de_marche(km_apres, dplus_b, dmoins_b)
        pire = max(j1_dplus, j2_dplus)

        print()
        print("%s  [%s, %s]" % (c["nom"], c["classe"], c["genre_en_clair"]))
        print("  quitte la trace au PK %.3f km | detour %d min aller / %d min retour"
              % (km_avant, c["minutes_aller"], c["minutes_retour"]))
        print("  la trace coupee  : %.3f km D+%d D-%d  ||  %.3f km D+%d D-%d   (somme des D+ : %d, ecart %+d m)"
              % (km_avant, dplus_a, dmoins_a, km_apres, dplus_b, dmoins_b, dplus_a + dplus_b, ecart))
        print("  JOURNEE 1 (trace + descente au couchage) : D+%d  D-%d  %d min"
              % (j1_dplus, j1_dmoins, j1_min))
        print("  JOURNEE 2 (remontee + trace)             : D+%d  D-%d  %d min"
              % (j2_dplus, j2_dmoins, j2_min))
        print("  >>> la plus dure des deux : D+%d m  (le segment entier pesait %d m)"
              % (pire, dplus_entier))
        if pire < dplus_entier:
            print("      soit %d m de MOINS sur la journee la plus dure." % (dplus_entier - pire))
        else:
            print("      soit %d m de PLUS : dormir la ne soulage RIEN." % (pire - dplus_entier))
        rendus.append(
            {
                "nom": c["nom"],
                "osm": c["osm"],
                "classe": c["classe"],
                "genre_en_clair": c["genre_en_clair"],
                "lat": c["lat"],
                "lon": c["lon"],
                "lits": c["lits"],
                "pk_km": km_avant,
                "minutes_aller": c["minutes_aller"],
                "minutes_retour": c["minutes_retour"],
                "trace_avant": {"km": km_avant, "dplus_m": dplus_a, "dmoins_m": dmoins_a},
                "trace_apres": {"km": km_apres, "dplus_m": dplus_b, "dmoins_m": dmoins_b},
                "ecart_de_coupe_m": ecart,
                "journee_1": {"dplus_m": j1_dplus, "dmoins_m": j1_dmoins, "minutes": j1_min},
                "journee_2": {"dplus_m": j2_dplus, "dmoins_m": j2_dmoins, "minutes": j2_min},
                "pire_des_deux_dplus_m": pire,
                "gain_sur_le_plancher_m": dplus_entier - pire,
            }
        )

    # LA MEILLEURE TROUVAILLE : celle qui fait le plus descendre la journee la
    # plus dure, a egalite celle dont le detour coute le moins. On ne retient
    # que les couchages DECLARES par OpenStreetMap — un batiment nomme
    # « bergerie » sans etiquette de couchage n est pas un lit (regle 838).
    declares = [r for r in rendus if r["classe"] == "declare"]
    meilleure = None
    if declares:
        meilleure = sorted(
            declares,
            key=lambda r: (-r["gain_sur_le_plancher_m"], r["minutes_aller"] + r["minutes_retour"]),
        )[0]

    print()
    print("=" * 100)
    if meilleure is None:
        print("AUCUNE trouvaille DECLAREE ne coupe le segment : le plancher de 1 455 m tient.")
    else:
        print("LA MEILLEURE TROUVAILLE DECLAREE : %s" % meilleure["nom"])
        print(
            "  elle fait passer la journee la plus dure du premier segment de %d m a %d m."
            % (dplus_entier, meilleure["pire_des_deux_dplus_m"])
        )
        print(
            "  COUT : %d min de detour (%d aller + %d retour), dont %d m a REMONTER le matin."
            % (
                meilleure["minutes_aller"] + meilleure["minutes_retour"],
                meilleure["minutes_aller"],
                meilleure["minutes_retour"],
                meilleure["journee_2"]["dplus_m"] - meilleure["trace_apres"]["dplus_m"],
            )
        )

    # Le fichier relu par le test Dart : le sentier AVEC la meilleure
    # trouvaille inseree, au format de `nuits_possibles.json`.
    if meilleure is not None:
        sortie = json.loads(json.dumps(nuits))
        nouvelle_nuit = {
            "nom": meilleure["nom"],
            "osm": [meilleure["osm"]],
            "osm_type": meilleure["genre_en_clair"],
            "pk_km": meilleure["pk_km"],
            "altitude_m": arrondi(altitudes[index_du_pk(meilleure["pk_km"] * 1000.0)]),
            "lat": meilleure["lat"],
            "lon": meilleure["lon"],
            "minutes_aller": meilleure["minutes_aller"],
            "minutes_retour": meilleure["minutes_retour"],
            "lits": meilleure["lits"],
            "origine": "trouvaille de la tache 849 dans le premier segment",
            "fin_d_etape": None,
        }
        sortie["liste"] = [nouvelle_nuit] + sortie["liste"]
        seg = sortie["entre_les_nuits"]
        a = {
            "rang": 1,
            "depart": segment1["depart"],
            "arrivee": meilleure["nom"],
            "pk_depart_km": 0.0,
            "pk_arrivee_km": meilleure["pk_km"],
            "km": meilleure["trace_avant"]["km"],
            "dplus_m": meilleure["trace_avant"]["dplus_m"],
            "dmoins_m": meilleure["trace_avant"]["dmoins_m"],
            "minutes": minutes_de_marche(
                meilleure["trace_avant"]["km"],
                meilleure["trace_avant"]["dplus_m"],
                meilleure["trace_avant"]["dmoins_m"],
            ),
        }
        b = {
            "rang": 2,
            "depart": meilleure["nom"],
            "arrivee": segment1["arrivee"],
            "pk_depart_km": meilleure["pk_km"],
            "pk_arrivee_km": segment1["pk_arrivee_km"],
            "km": meilleure["trace_apres"]["km"],
            "dplus_m": meilleure["trace_apres"]["dplus_m"],
            "dmoins_m": meilleure["trace_apres"]["dmoins_m"],
            "minutes": minutes_de_marche(
                meilleure["trace_apres"]["km"],
                meilleure["trace_apres"]["dplus_m"],
                meilleure["trace_apres"]["dmoins_m"],
            ),
        }
        reste = []
        for s in seg[1:]:
            s = dict(s)
            s["rang"] = len(reste) + 3
            reste.append(s)
        sortie["entre_les_nuits"] = [a, b] + reste
        sortie["nuits"] = len(sortie["liste"])
        sortie["segments"] = len(sortie["entre_les_nuits"])
        sortie["quoi"] = (
            "Les nuits du GR20 AVEC la trouvaille de la tache 849 inseree dans le "
            "premier segment (%s). Fichier de MESURE : il sert a repondre a la "
            "question « et si on dormait la ? », il n est pas la donnee du produit."
            % meilleure["nom"]
        )
        sortie["insertion_849"] = meilleure
        with open(options.sortie, "w", encoding="utf-8") as f:
            json.dump(sortie, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print()
        print("Ecrit dans %s (%d nuits, %d segments)"
              % (options.sortie, sortie["nuits"], sortie["segments"]))

    # Et le detail de chaque candidat, pour la trace.
    detail = os.path.join(os.path.dirname(options.sortie), "insertions_849_detail.json")
    with open(detail, "w", encoding="utf-8") as f:
        json.dump(
            {
                "quoi": (
                    "Ce que devient la journee la plus dure du premier segment du GR20 "
                    "si l on dort a chacune des trouvailles de la tache 849."
                ),
                "tache": 849,
                "segment_entier": {
                    "km": segment1["km"],
                    "dplus_m": dplus_entier,
                    "dmoins_m": dmoins_entier,
                },
                "candidats": rendus,
            },
            f,
            ensure_ascii=False,
            indent=2,
        )
        f.write("\n")
    print("Detail de tous les candidats dans %s" % detail)


if __name__ == "__main__":
    main()
