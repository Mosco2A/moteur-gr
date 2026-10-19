#!/usr/bin/env python3
"""LA NOTE SUR VINGT ET LES QUATRE LECTURES, MESUREES UNE SECONDE FOIS.

Tache 860. La loi est celle du bareme 857 avec l'exposant MESURE de la 860
(1,08, Riegel borne basse du recreatif), la jauge sur les RANGS figee le
19/10/2026 sur 106 etapes officielles sourcees, et le decoupage a l'EFFORT en
deux temps lexicographiques (minimiser la pire journee, puis maximiser la plus
petite).

POURQUOI CE FICHIER EXISTE A COTE DU CODE DART. Doctrine du depot : un calcul
qui compte se mesure DEUX FOIS, independamment, et les deux mesures doivent
concorder. Il reprend le profil et l'indice de `indice_du_terrain_858.py` — la
mesure Python de l'indice, deja en place — et il y ajoute ce que la 860 code :
la jauge, l'ecretage, le decoupage a l'effort et les quatre lectures. Sa sortie
est `assets/data/gr20/notes_860.json`, que le test Dart relit ligne par ligne.

CE QUE CE SCRIPT NE FAIT PAS. Aucune bande, aucun mot de niveau. Aucune note de
troncon ni de sentier : on ne somme jamais, on decrit. Aucune couche du
marcheur — ni sac, ni surpoids, ni genoux.

Usage:
    python tool/note_sur_vingt_860.py --sortie assets/data/gr20/notes_860.json
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

# --- LA JAUGE SUR LES RANGS, FIGEE LE 19/10/2026 ---------------------------
DATE_DU_CALAGE = "19/10/2026"
ETAPES_DU_CORPUS = 106
INDICE_DU_ZERO = 6.000
INDICE_DU_VINGT = 87.485
PALIERS = [
    (INDICE_DU_ZERO, 0.0),
    (18.224, 2.0),
    (23.068, 4.0),
    (27.971, 6.0),
    (31.223, 8.0),
    (34.475, 10.0),
    (36.391, 12.0),
    (39.736, 14.0),
    (43.403, 16.0),
    (50.051, 18.0),
    (INDICE_DU_VINGT, 20.0),
]
CORPUS = {
    "GR34 Bretagne, decoupage traileasy.com": 28,
    "GR70 Stevenson, decoupage chamina": 13,
    "Pennine Way, decoupage trailsplits": 16,
    "Etapes plates et longues, source par ligne": 3,
    "Alta Via 1 Dolomites": 11,
    "Walker's Haute Route": 13,
    "Candidats au plafond mondial, fiabilite par ligne": 22,
}
PLAFOND = "Griesalp - Hohturli - Kandersteg (Via Alpina 1, Suisse)"


def note(indice: float) -> float:
    if indice <= INDICE_DU_ZERO:
        return 0.0
    if indice >= INDICE_DU_VINGT:
        return 20.0
    bas_i, bas_n = PALIERS[0]
    for haut_i, haut_n in PALIERS[1:]:
        if indice <= haut_i:
            return bas_n + (haut_n - bas_n) * (indice - bas_i) / (haut_i - bas_i)
        bas_i, bas_n = haut_i, haut_n
    return 20.0


# --- LE DECOUPAGE A L'EFFORT, DEUX TEMPS LEXICOGRAPHIQUES ------------------
def decouper(unites: int, groupes: int, charge) -> list[int]:
    """Minimise la pire journee, puis MAXIMISE la plus petite."""
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


def lectures(notes: list[float]) -> dict:
    """LES QUATRE LECTURES. Journee dure = au-dessus de la journee TYPE."""
    type_ = sum(notes) / len(notes)
    dures = [n > type_ for n in notes]
    plus_long = courant = 0
    for d in dures:
        courant = courant + 1 if d else 0
        plus_long = max(plus_long, courant)
    return {
        "nombre_de_jours": len(notes),
        "pire_journee": round(max(notes), 2),
        "journee_type": round(type_, 2),
        "journees_dures": sum(dures),
        "plus_long_enchainement": plus_long,
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
        m = mesure(d, f)
        journees.append(
            {
                "rang": rang,
                "depart": noms[d],
                "arrivee": noms[f],
                "indice": round(m["indice"], 2),
                "note": round(note(m["indice"]), 2),
                "ecretee": m["indice"] > INDICE_DU_VINGT,
                "plus_grosse_montee_m": round(m["plus_grosse_montee_m"]),
                "km": round(m["km_de_trajet"], 2),
            }
        )
    return {
        "produit": dossier,
        "sens": "inverse" if a_l_envers else "trace",
        "jours_demandes": jours,
        "lectures": lectures([j["note"] for j in journees]),
        "journees": journees,
    }


def main() -> int:
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--sortie", required=True)
    options = arg.parse_args()

    # LES SEIZE ETAPES OFFICIELLES, NOTEES.
    segments, longueur_m, _ = I858.profil(
        os.path.join(RACINE, "assets/data/gr20/track.gpx")
    )
    with open(
        os.path.join(RACINE, "assets/data/gr20/mesure_etapes.json"), encoding="utf-8"
    ) as f:
        mesure_etapes = json.load(f)
    etapes = []
    for e in mesure_etapes["etapes"]:
        m = I858.indice(
            I858.tranche(
                segments, e["pk_depart_km"] * 1000.0, e["pk_arrivee_km"] * 1000.0
            )
        )
        etapes.append(
            {
                "rang": e["rang_trace"],
                "depart": e["depart"],
                "arrivee": e["arrivee"],
                "indice": round(m["indice"], 2),
                "note": round(note(m["indice"]), 2),
                "plus_grosse_montee_m": round(m["plus_grosse_montee_m"]),
                "km": round(m["km_de_trajet"], 2),
            }
        )

    # LA PART ASSUMEE, BRUTE ET NETTE, SUR LES SEIZE ETAPES.
    somme_absolue = somme_nette = somme_indices = 0.0
    for e in mesure_etapes["etapes"]:
        m = I858.indice(
            I858.tranche(
                segments, e["pk_depart_km"] * 1000.0, e["pk_arrivee_km"] * 1000.0
            )
        )
        somme_absolue += abs(m["majoration_de_continuite"])
        somme_nette += m["majoration_de_continuite"]
        somme_indices += m["indice"]

    plans = []
    for dossier in ("gr20", "gr20-nord", "gr20-sud"):
        for a_l_envers in (False, True):
            for jours in (5, 7, 8):
                p = plan(dossier, jours, a_l_envers)
                if p is not None:
                    plans.append(p)

    resultat = {
        "quoi": (
            "La note sur vingt des journees du GR20 et de ses deux chapitres, "
            "et les QUATRE LECTURES de chaque plan. UNE JOURNEE A UNE NOTE ; "
            "UN TRONCON ET UN SENTIER N'EN ONT PAS, ils portent quatre "
            "lectures prises sur leurs journees. On ne somme jamais."
        ),
        "tache": 860,
        "loi": {
            "beta": I858.BETA,
            "denivele_de_reference_m": I858.D_REF_M,
            "fondation_de_l_exposant": (
                "Riegel : 1,06 elite, 1,08 a 1,10 recreatif ; forme en loi de "
                "puissance fondee par Drake, Finke et Ferguson 2023, European "
                "Journal of Applied Physiology. RESERVE : les exposants "
                "publies portent sur la DUREE d'un effort entier, pas sur la "
                "HAUTEUR d'une cote - l'application est une analogie assumee."
            ),
            "part_assumee_brute_pct": round(100 * somme_absolue / somme_indices, 2),
            "part_assumee_nette_pct": round(
                100 * abs(somme_nette) / somme_indices, 2
            ),
        },
        "jauge": {
            "figee_le": DATE_DU_CALAGE,
            "etapes_du_corpus": ETAPES_DU_CORPUS,
            "composition": CORPUS,
            "plafond": PLAFOND,
            "indice_du_zero": INDICE_DU_ZERO,
            "indice_du_vingt": INDICE_DU_VINGT,
            "paliers": [[i, n] for i, n in PALIERS],
            "au_dela_c_est_vingt": True,
        },
        "etapes_officielles_notees": etapes,
        "plans": plans,
    }

    with open(options.sortie, "w", encoding="utf-8") as f:
        json.dump(resultat, f, ensure_ascii=False, indent=1)
        f.write("\n")

    sys.stderr.write(
        "Etape 1 : indice %.2f, note %.2f / 20\n"
        % (etapes[0]["indice"], etapes[0]["note"])
    )
    sys.stderr.write(
        "Part assumee : %.2f %% brute, %.2f %% nette\n"
        % (
            100 * somme_absolue / somme_indices,
            100 * abs(somme_nette) / somme_indices,
        )
    )
    for p in plans:
        if p["produit"] == "gr20" and p["sens"] == "trace":
            sys.stderr.write(
                "GR20 trace %d j : pire %.2f, type %.2f, dures %d, ench %d\n"
                % (
                    p["jours_demandes"],
                    p["lectures"]["pire_journee"],
                    p["lectures"]["journee_type"],
                    p["lectures"]["journees_dures"],
                    p["lectures"]["plus_long_enchainement"],
                )
            )
    return 0


if __name__ == "__main__":
    sys.exit(main())
