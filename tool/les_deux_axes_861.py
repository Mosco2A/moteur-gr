#!/usr/bin/env python3
"""LES DEUX AXES, EFFORT ET RAIDEUR, MESURES UNE SECONDE FOIS.

Tache 861. Remplace `note_sur_vingt_860.py` : la jauge unique calee sur les
DECILES D'UN CORPUS a ete retiree, et deux axes la remplacent.

  AXE EFFORT  : l'indice 858 (descente comprise, exposant 1,08), gradue sur
                les QUATRE SEUILS PUBLIES du bareme francais de randonnee.
                Un seul repere depend encore de nous, celui du 20.
  AXE RAIDEUR : le denivele positif par kilometre DE CARTE, divise par dix,
                plafonne a vingt. Les quatre bandes publiees de l'IMBA
                tombent alors exactement sur 5, 10, 15 et 20.

POURQUOI DEUX AXES. Le releve des methodes publiees du monde a rendu un
resultat qui condamnait la recherche d'une note unique : PERSONNE NE RESOUT LA
DIFFICULTE D'UNE JOURNEE DANS UN CHIFFRE UNIQUE. MIDE quatre axes, FFRandonnee
trois, Komoot deux, SAC et CAI cotent la technique separement. Le seul chiffre
unique qui internalise la concentration est l'IBP, et sa formule est secrete.

POURQUOI CE FICHIER EXISTE A COTE DU CODE DART. Doctrine du depot : un calcul
qui compte se mesure DEUX FOIS, independamment, et les deux mesures doivent
concorder. Sa sortie est `assets/data/gr20/axes_861.json`, que le test Dart
relit ligne par ligne.

Usage:
    python tool/les_deux_axes_861.py --sortie assets/data/gr20/axes_861.json
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.dirname(ICI)

_spec = importlib.util.spec_from_file_location(
    "indice_858", os.path.join(ICI, "indice_du_terrain_858.py")
)
I858 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(I858)

# --- AXE EFFORT : les quatre seuils publies, figes le 20/10/2026 -----------
DATE_DU_CALAGE = "20/10/2026"
SOURCE_DES_SEUILS = (
    "Bareme francais commun de randonnee (comites departementaux, "
    "Randonner Malin, Decathlon, cdfpi.fr)"
)
INDICE_6KM_200M = 8.69
INDICE_12KM_450M = 18.80
INDICE_18KM_750M = 30.16
INDICE_DU_DERNIER_SEUIL_PUBLIE = 41.86
INDICE_DU_VINGT = 87.49
ETAPE_DU_VINGT = "Griesalp - Hohturli - Kandersteg (Via Alpina 1, Suisse)"
INDICE_FRONTIERE_ALLTRAILS = 17.80
PALIERS_EFFORT = [
    (0.0, 0.0),
    (INDICE_6KM_200M, 4.0),
    (INDICE_12KM_450M, 8.0),
    (INDICE_18KM_750M, 12.0),
    (INDICE_DU_DERNIER_SEUIL_PUBLIE, 16.0),
    (INDICE_DU_VINGT, 20.0),
]

# --- AXE RAIDEUR : les quatre bandes de l'IMBA ----------------------------
SOURCE_DES_BANDES = (
    "Bandes de pente moyenne de l IMBA (parks.act.gov.au, scouting.org) - "
    "SEUILS VENUS DU VTT, PAS DE LA RANDONNEE"
)
BANDES_IMBA = {"vert": 50.0, "bleu": 100.0, "noir": 150.0, "double_noir": 200.0}
METRES_PAR_KM_PAR_POINT = 10.0
RAIDEUR_MAX = 20.0


def effort(indice: float) -> float:
    """LA NOTE D'EFFORT. Elle ne prend que l'indice."""
    if indice <= 0:
        return 0.0
    if indice >= INDICE_DU_VINGT:
        return 20.0
    bas_i, bas_n = PALIERS_EFFORT[0]
    for haut_i, haut_n in PALIERS_EFFORT[1:]:
        if indice <= haut_i:
            return bas_n + (haut_n - bas_n) * (indice - bas_i) / (haut_i - bas_i)
        bas_i, bas_n = haut_i, haut_n
    return 20.0


def metres_par_km(dplus_m: float, km_de_carte: float) -> float:
    """LE CHIFFRE BRUT DE LA RAIDEUR, sur le kilometrage DE CARTE.

    Une pente moyenne est une denivelee sur une distance HORIZONTALE. Mesuree
    sur la longueur inclinee, une vraie pente de 20 % sort a 196 m/km et les
    bandes de l'IMBA ne tombent plus sur des notes rondes.
    """
    return 0.0 if km_de_carte <= 0 else dplus_m / km_de_carte


def raideur(dplus_m: float, km_de_carte: float) -> float:
    """LA NOTE DE RAIDEUR, plafonnee a vingt."""
    return min(RAIDEUR_MAX, metres_par_km(dplus_m, km_de_carte) / METRES_PAR_KM_PAR_POINT)


def decouper(unites: int, groupes: int, charge) -> list[int]:
    """Minimise la pire journee a l'EFFORT, puis MAXIMISE la plus petite."""
    if unites <= 0 or groupes <= 0:
        return []
    if groupes >= unites:
        return list(range(unites))
    inf = float("inf")
    gardees: dict[tuple[int, int], float] = {}

    def c(p: int, i: int) -> float:
        if (p, i) not in gardees:
            gardees[(p, i)] = charge(p, i)
        return gardees[(p, i)]

    plafonds = [[inf] * (groupes + 1) for _ in range(unites + 1)]
    plafonds[0][0] = 0.0
    for j in range(1, groupes + 1):
        for i in range(j, unites + 1):
            for p in range(j - 1, i):
                prec = plafonds[p][j - 1]
                if prec == inf:
                    continue
                pire = max(prec, c(p, i))
                if pire < plafonds[i][j]:
                    plafonds[i][j] = pire
    plafond = plafonds[unites][groupes] * (1 + 1e-9)

    planchers = [[-inf] * (groupes + 1) for _ in range(unites + 1)]
    origines = [[-1] * (groupes + 1) for _ in range(unites + 1)]
    planchers[0][0] = inf
    for j in range(1, groupes + 1):
        for i in range(j, unites + 1):
            for p in range(j - 1, i):
                prec = planchers[p][j - 1]
                if prec == -inf:
                    continue
                g = c(p, i)
                if g > plafond:
                    continue
                plus_petite = min(prec, g)
                if plus_petite > planchers[i][j]:
                    planchers[i][j] = plus_petite
                    origines[i][j] = p
    debuts: list[int] = []
    i, j = unites, groupes
    while j > 0:
        p = origines[i][j]
        if p < 0:
            return list(range(groupes))
        debuts.append(p)
        i, j = p, j - 1
    return list(reversed(debuts))


def lectures(efforts: list[float], raideurs: list[float]) -> dict:
    """LES LECTURES D'UN PLAN. Journee dure = au-dessus de la journee TYPE.

    LES JOURNEES DURES SE COMPTENT SUR L'EFFORT : le repartiteur equilibre a
    l'effort, donc « dure » doit designer la grandeur qu'il a optimisee.
    """
    type_ = sum(efforts) / len(efforts)
    dures = [e > type_ for e in efforts]
    plus_long = courant = 0
    for d in dures:
        courant = courant + 1 if d else 0
        plus_long = max(plus_long, courant)
    return {
        "nombre_de_jours": len(efforts),
        "pire_journee": round(max(efforts), 2),
        "journee_type": round(type_, 2),
        "journees_dures": sum(dures),
        "plus_long_enchainement": plus_long,
        "pire_journee_en_raideur": round(max(raideurs), 2),
        "journee_type_en_raideur": round(sum(raideurs) / len(raideurs), 2),
    }


def deux_axes(m: dict) -> dict:
    """Les deux notes et le chiffre brut d'un morceau mesure."""
    par_km = metres_par_km(m["dplus_m"], m["km_de_carte"])
    return {
        "indice": round(m["indice"], 2),
        "effort": round(effort(m["indice"]), 2),
        "raideur": round(raideur(m["dplus_m"], m["km_de_carte"]), 2),
        "metres_par_km": round(par_km, 1),
        "effort_ecrete": m["indice"] > INDICE_DU_VINGT,
        "raideur_ecretee": par_km > BANDES_IMBA["double_noir"],
        "plus_grosse_montee_m": round(m["plus_grosse_montee_m"]),
        "km_de_carte": round(m["km_de_carte"], 2),
        "km_de_trajet": round(m["km_de_trajet"], 2),
        "dplus_m": round(m["dplus_m"]),
    }


def plan(dossier: str, jours: int, a_l_envers: bool) -> dict | None:
    chemin = os.path.join(RACINE, "assets/data", dossier)
    segments, longueur_m, _ = I858.profil(os.path.join(chemin, "track.gpx"))
    with open(os.path.join(chemin, "nuits_possibles.json"), encoding="utf-8") as f:
        nuits = json.load(f)
    liste = sorted(nuits.get("liste", []), key=lambda n: n["pk_km"])
    bornes = [0.0] + [n["pk_km"] for n in liste]
    noms = ["(tete)"] + [n["nom"] for n in liste]
    if a_l_envers:
        segments = I858.inverser(segments, longueur_m)
        bornes = [longueur_m / 1000.0 - b for b in reversed(bornes)]
        noms = list(reversed(noms))
    unites = len(bornes) - 1
    gardees: dict[tuple[int, int], dict] = {}

    def mesure(p: int, i: int) -> dict:
        if (p, i) not in gardees:
            gardees[(p, i)] = I858.indice(
                I858.tranche(segments, bornes[p] * 1000.0, bornes[i] * 1000.0)
            )
        return gardees[(p, i)]

    debuts = decouper(unites, min(jours, unites), lambda p, i: mesure(p, i)["indice"])
    if not debuts:
        return None
    fins = debuts[1:] + [unites]
    journees = []
    for rang, (d, f) in enumerate(zip(debuts, fins), start=1):
        axes = deux_axes(mesure(d, f))
        axes.update({"rang": rang, "depart": noms[d], "arrivee": noms[f]})
        journees.append(axes)
    return {
        "produit": dossier,
        "sens": "inverse" if a_l_envers else "trace",
        "jours_demandes": jours,
        "lectures": lectures(
            [j["effort"] for j in journees], [j["raideur"] for j in journees]
        ),
        "journees": journees,
    }


def main() -> int:
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--sortie", required=True)
    options = arg.parse_args()

    segments, _longueur_m, _ = I858.profil(
        os.path.join(RACINE, "assets/data/gr20/track.gpx")
    )
    with open(
        os.path.join(RACINE, "assets/data/gr20/mesure_etapes.json"), encoding="utf-8"
    ) as f:
        mesure_etapes = json.load(f)

    etapes = []
    somme_absolue = somme_indices = 0.0
    for e in mesure_etapes["etapes"]:
        m = I858.indice(
            I858.tranche(
                segments, e["pk_depart_km"] * 1000.0, e["pk_arrivee_km"] * 1000.0
            )
        )
        axes = deux_axes(m)
        axes.update(
            {"rang": e["rang_trace"], "depart": e["depart"], "arrivee": e["arrivee"]}
        )
        etapes.append(axes)
        somme_absolue += abs(m["majoration_de_continuite"])
        somme_indices += m["indice"]

    # LE MUR THEORIQUE : 300 M EN UN KILOMETRE. Il est dans la sortie parce
    # qu'il est LA demonstration des deux axes - bas en effort, au plafond en
    # raideur. Aucun axe unique ne pouvait dire ca.
    mur = deux_axes(I858.indice([(0.0, 1000.0, 300.0)]))

    plans = []
    for dossier in ("gr20", "gr20-nord", "gr20-sud"):
        for a_l_envers in (False, True):
            for jours in (5, 7, 8):
                p = plan(dossier, jours, a_l_envers)
                if p is not None:
                    plans.append(p)

    resultat = {
        "quoi": (
            "LES DEUX AXES des journees du GR20 et de ses deux chapitres. "
            "UNE JOURNEE A DEUX NOTES, effort et raideur ; UN TRONCON ET UN "
            "SENTIER N'EN ONT AUCUNE, ils portent des lectures prises sur "
            "leurs journees. On ne somme jamais."
        ),
        "tache": 861,
        "pourquoi_deux_axes": (
            "Personne au monde ne resout la difficulte d'une journee dans un "
            "chiffre unique : MIDE quatre axes, FFRandonnee trois, Komoot "
            "deux, SAC et CAI cotent la technique separement de l'effort. Le "
            "seul chiffre unique qui internalise la concentration est l'IBP, "
            "et sa formule n'est pas publique."
        ),
        "loi": {
            "beta": I858.BETA,
            "denivele_de_reference_m": I858.D_REF_M,
            "fondation_de_l_exposant": (
                "Riegel : 1,06 elite, 1,08 a 1,10 recreatif ; forme en loi de "
                "puissance fondee par Drake, Finke et Ferguson 2023. RESERVE : "
                "les exposants publies portent sur la DUREE d'un effort "
                "entier, pas sur la HAUTEUR d'une cote - analogie assumee."
            ),
            "part_assumee_pct": round(100 * somme_absolue / somme_indices, 2),
        },
        "axe_effort": {
            "figee_le": DATE_DU_CALAGE,
            "source_des_seuils": SOURCE_DES_SEUILS,
            "paliers": [[i, n] for i, n in PALIERS_EFFORT],
            "indice_du_dernier_seuil_publie": INDICE_DU_DERNIER_SEUIL_PUBLIE,
            "indice_du_vingt": INDICE_DU_VINGT,
            "etape_du_vingt": ETAPE_DU_VINGT,
            "controle_croise_alltrails": {
                "frontiere_alltrails_11km_450m": INDICE_FRONTIERE_ALLTRAILS,
                "frontiere_francaise_12km_450m": INDICE_12KM_450M,
                "ecart_pct": round(
                    100
                    * abs(INDICE_12KM_450M - INDICE_FRONTIERE_ALLTRAILS)
                    / INDICE_12KM_450M,
                    1,
                ),
            },
            "part_de_l_echelle_qui_depend_de_nous_pct": round(
                100 * (20.0 - 16.0) / 20.0, 1
            ),
        },
        "axe_raideur": {
            "figee_le": DATE_DU_CALAGE,
            "source_des_bandes": SOURCE_DES_BANDES,
            "bandes_imba_m_par_km": BANDES_IMBA,
            "metres_par_km_par_point_de_note": METRES_PAR_KM_PAR_POINT,
            "kilometrage": (
                "CELUI DE LA CARTE, pas la longueur de trajet : une pente "
                "moyenne est une denivelee sur une distance HORIZONTALE. Sur "
                "la longueur inclinee, une vraie pente de 20 % sort a "
                "196 m/km et les quatre bandes de l'IMBA ne tombent plus sur "
                "5, 10, 15 et 20 mais sur 4,99, 9,95, 14,83 et 19,61."
            ),
            "reserve": (
                "CES SEUILS VIENNENT DU VTT, PAS DE LA RANDONNEE. La pente "
                "moyenne est la meme grandeur physique quel que soit l'engin, "
                "mais aucune federation de randonnee n'en publie. Seul indice "
                "convergent : les sources francaises disent qu'une pente "
                "jusqu'a 10 a 15 % ne pose pas de probleme majeur a pied, ce "
                "qui tombe sur la frontiere bleu/noir de l'IMBA."
            ),
            "ce_que_cet_axe_ne_voit_pas": (
                "LES MURS. La pente moyenne melange la montee et le plat : "
                "cet axe dit « ca monte beaucoup pour la distance », pas « il "
                "y a un mur dedans ». C'est pour cela que la plus grosse "
                "montee continue reste affichee a cote, comme un FAIT."
            ),
        },
        "bandes_imba_reproduites": {
            nom: round(raideur(m, 1.0), 2) for nom, m in BANDES_IMBA.items()
        },
        "mur_de_300m_en_1km": mur,
        "etapes_officielles": etapes,
        "plans": plans,
    }

    with open(options.sortie, "w", encoding="utf-8") as f:
        json.dump(resultat, f, ensure_ascii=False, indent=1)
        f.write("\n")

    sys.stderr.write(
        "Etape 1 : indice %.2f, effort %.2f, raideur %.2f (%.1f m/km)\n"
        % (
            etapes[0]["indice"],
            etapes[0]["effort"],
            etapes[0]["raideur"],
            etapes[0]["metres_par_km"],
        )
    )
    sys.stderr.write(
        "Mur 300 m / 1 km : effort %.2f, raideur %.2f\n"
        % (mur["effort"], mur["raideur"])
    )
    for p in plans:
        if p["produit"] == "gr20" and p["sens"] == "trace":
            sys.stderr.write(
                "GR20 trace %d j : pire effort %.2f, type %.2f, "
                "pire raideur %.2f\n"
                % (
                    p["jours_demandes"],
                    p["lectures"]["pire_journee"],
                    p["lectures"]["journee_type"],
                    p["lectures"]["pire_journee_en_raideur"],
                )
            )
            if p["jours_demandes"] == 7:
                for j in p["journees"]:
                    sys.stderr.write(
                        "   jour %d : effort %.2f raideur %.2f (%.1f m/km)\n"
                        % (j["rang"], j["effort"], j["raideur"], j["metres_par_km"])
                    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
