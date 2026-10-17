"""L'EFFORT DES JOURNEES DU GR20, ET LE VERDICT DE CHAQUE TRONCON — LA MESURE.

POURQUOI CET OUTIL EXISTE. La tache 852 change deux choses a la fois : l'effort
d'une journee se calcule desormais sur ses TROIS mesures (distance, montee,
descente) et non sur le seul denivele positif, et le verdict d'un TRONCON part
de sa pire journee puis peut monter d'un cran si les journees dures se suivent
(Christophe, 17/10 17:25, memoire #102180). Changer une regle de classement sans
REMESURER ce qu'elle classe, c'est afficher un mot neuf sur un chiffre ancien.

CE QU'IL MESURE, ET IL N'INVENTE AUCUNE DONNEE.
  - les quatre allures de la fiche (7, 9, 12, 16 jours) DANS LES DEUX SENS ;
  - le sentier entier a toutes les allures de 7 a 31 jours, dans les deux sens ;
  - les deux chapitres, nord et sud, a toutes leurs allures ;
  - la VARIANTE BONIFATU, qui remplace le premier segment du GR20.

LES ENTREES SONT CELLES DU PRODUIT. Les trente et une nuits relevees et les
trente et un segments entre elles viennent de `assets/data/gr20/nuits_possibles
.json` (tache 838) ; la coupe nord/sud vient de `assets/data/gr20/chapitres.json`
(tache 839). Les deux troncons de la variante Bonifatu viennent de la mesure OSM
de la tache 849 (`variante_bonifatu_849.json`, branche claude/feat/849-nuits-e1-
et-sens) : ils sont recopies ici avec leur provenance parce que cette mesure
n'est pas refaisable depuis les donnees embarquees.

LE REPARTITEUR EST REPLIQUE, PAS APPROXIME. `coupes()` ci-dessous est la
transcription de `lib/domain/repartition_equilibree.dart` : meme objectif
lexicographique en deux temps (la journee la plus chargee la plus legere
possible, puis les journees les plus egales), meme charge (le temps de marche du
modele unique du depot). Le test
`test/assets/effort_et_troncon_852_test.dart` recalcule les memes scenarios en
Dart et exige que les deux implementations tombent sur le MEME verdict : deux
calculs independants qui concordent valent mieux qu'un calcul qui s'auto-atteste.

LE SENS INVERSE NE PASSE PAS PAR `DecoupageSurLesNuits`, ET C'EST VOLONTAIRE. La
tache 849 a trouve un defaut la : en sens inverse la derniere journee disparait
en silence, parce qu'elle arrive a Calenzana qui n'est pas une nuit relevee. Ce
defaut n'est pas corrige par ce lot-ci ; on groupe donc les segments
directement, ce qui mesure l'ECHELLE sans mesurer le defaut.

Sortie : assets/data/gr20/effort_852.json
"""

from __future__ import annotations

import json
import os

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.dirname(ICI)
DONNEES = os.path.join(RACINE, "assets", "data", "gr20")
INF = float("inf")

# --- LES BANDES, TELLES QUE `SeuilsDeDifficulte` LES POSE -------------------
BANDES = ("facile", "moyen", "difficile", "tres difficile")
METRES_DE_MONTEE_PAR_KM_DE_PLAT = 100  # BP §A, deja en production
POIDS_DE_LA_DESCENTE = 0.30  # BP §B, deja en production
METRES_DE_MONTEE_PAR_KM_EFFORT = 40  # transposition des seuils de Christophe
SEUILS_KM_EFFORT = (
    400 / METRES_DE_MONTEE_PAR_KM_EFFORT,
    700 / METRES_DE_MONTEE_PAR_KM_EFFORT,
    1000 / METRES_DE_MONTEE_PAR_KM_EFFORT,
)
SUITE_QUI_MONTE_LE_VERDICT = 4  # majorite de la fenetre de 7 jours (Foster)

# --- LE MODELE DE TEMPS DE MARCHE UNIQUE DU DEPOT ---------------------------
# lib/core/models/stage_duration.dart : 4,0 km/h a plat, 400 m de montee par
# heure, descente payee 1,67 s par metre.
KM_PAR_HEURE_A_PLAT = 4.0
METRES_DE_MONTEE_PAR_HEURE = 400.0
SECONDES_PAR_METRE_DE_DESCENTE = 1.67

# --- LA VARIANTE BONIFATU, MESUREE PAR LA TACHE 849 SUR OPENSTREETMAP -------
# Source : tool/variante_bonifatu_849.py, assets/data/gr20/variante_bonifatu_849
# .json (branche claude/feat/849-nuits-e1-et-sens, commit a9ed6887). Licence
# ODbL ; altitudes EU-DEM 25 m. Elle REMPLACE le premier segment du GR20.
VARIANTE_BONIFATU = (
    {
        "depart": "Calenzana",
        "arrivee": "Auberge de la Foret (Bonifatu)",
        "km": 11.7384,
        "dplus_m": 632,
        "dmoins_m": 384,
    },
    {
        "depart": "Auberge de la Foret (Bonifatu)",
        "arrivee": "Refuge de l'Ortu di u Piobbu",
        "km": 7.9521,
        "dplus_m": 1056,
        "dmoins_m": 38,
    },
)


def minutes_de_marche(km: float, dplus_m: int, dmoins_m: int) -> float:
    """Le temps de marche du modele UNIQUE du depot, en minutes."""
    return (
        km / KM_PAR_HEURE_A_PLAT * 60.0
        + dplus_m / METRES_DE_MONTEE_PAR_HEURE * 60.0
        + dmoins_m * SECONDES_PAR_METRE_DE_DESCENTE / 60.0
    )


def effort_km(km: float, dplus_m: int, dmoins_m: int) -> float:
    """L'effort d'une journee, en kilometres-effort."""
    return (
        km
        + dplus_m / METRES_DE_MONTEE_PAR_KM_DE_PLAT
        + POIDS_DE_LA_DESCENTE * dmoins_m / METRES_DE_MONTEE_PAR_KM_DE_PLAT
    )


def bande(effort: float) -> int:
    """Le rang de bande (0..3) d'un effort. Bornes INCLUSIVES EN BAS."""
    for rang, seuil in enumerate(SEUILS_KM_EFFORT):
        if effort < seuil:
            return rang
    return 3


def coupes(charges: list[float], groupes: int) -> list[int]:
    """Replique de `RepartitionEquilibree.coupes` — index de debut de groupe."""
    n = len(charges)
    if n == 0 or groupes <= 0:
        return []
    if groupes >= n:
        return list(range(n))

    prefixe = [0.0] * (n + 1)
    for i, charge in enumerate(charges):
        prefixe[i + 1] = prefixe[i] + max(0.0, charge)

    def somme(debut: int, fin: int) -> float:
        return prefixe[fin] - prefixe[debut]

    cible = prefixe[n] / groupes

    # TEMPS 1 — le plus petit maximum atteignable avec exactement `groupes`.
    plafonds = [[INF] * (groupes + 1) for _ in range(n + 1)]
    plafonds[0][0] = 0.0
    for j in range(1, groupes + 1):
        for i in range(j, n + 1):
            for p in range(j - 1, i):
                precedent = plafonds[p][j - 1]
                if precedent == INF:
                    continue
                pire = max(precedent, somme(p, i))
                if pire < plafonds[i][j]:
                    plafonds[i][j] = pire
    plafond = plafonds[n][groupes] * (1 + 1e-9)

    # TEMPS 2 — a maximum egal, les journees les plus egales.
    ecarts = [[INF] * (groupes + 1) for _ in range(n + 1)]
    origines = [[-1] * (groupes + 1) for _ in range(n + 1)]
    ecarts[0][0] = 0.0
    for j in range(1, groupes + 1):
        for i in range(j, n + 1):
            for p in range(j - 1, i):
                precedent = ecarts[p][j - 1]
                if precedent == INF:
                    continue
                groupe = somme(p, i)
                if groupe > plafond:
                    continue
                total = precedent + (groupe - cible) ** 2
                if total < ecarts[i][j]:
                    ecarts[i][j] = total
                    origines[i][j] = p

    debuts, i, j = [], n, groupes
    while j > 0:
        p = origines[i][j]
        debuts.append(p)
        i, j = p, j - 1
    return list(reversed(debuts))


def journees(segments: list[dict], jours: int) -> list[dict]:
    """Groupe les segments en `jours` journees, equilibrees sur le temps."""
    charges = [
        minutes_de_marche(s["km"], s["dplus_m"], s["dmoins_m"]) for s in segments
    ]
    bornes = coupes(charges, min(jours, len(segments)))
    sortie = []
    for rang, debut in enumerate(bornes):
        fin = bornes[rang + 1] if rang + 1 < len(bornes) else len(segments)
        tranche = segments[debut:fin]
        km = sum(s["km"] for s in tranche)
        dplus = sum(s["dplus_m"] for s in tranche)
        dmoins = sum(s["dmoins_m"] for s in tranche)
        sortie.append(
            {
                "numero": rang + 1,
                "depart": tranche[0]["depart"],
                "arrivee": tranche[-1]["arrivee"],
                "km": round(km, 3),
                "dplus_m": dplus,
                "dmoins_m": dmoins,
                "km_effort": round(effort_km(km, dplus, dmoins), 2),
            }
        )
    return sortie


def verdict_du_troncon(jours_mesures: list[dict]) -> dict:
    """Le plancher, l'accumulation, et le verdict qui en sort."""
    rangs = [bande(j["km_effort"]) for j in jours_mesures]
    plancher = max(rangs)
    hautes = sum(1 for r in rangs if r >= 2)
    suite = plus_longue_suite(rangs)
    monte = suite >= SUITE_QUI_MONTE_LE_VERDICT and plancher < 3
    pire = max(jours_mesures, key=lambda j: j["km_effort"])
    return {
        "journees": len(jours_mesures),
        "pire_journee": pire,
        "plancher": BANDES[plancher],
        "journees_en_bandes_hautes": hautes,
        "plus_longue_suite": suite,
        "verdict_monte_par_l_accumulation": monte,
        "verdict": BANDES[min(3, plancher + 1) if monte else plancher],
    }


def plus_longue_suite(rangs: list[int]) -> int:
    """La plus longue suite de journees consecutives en bandes hautes."""
    plus_longue = courante = 0
    for rang in rangs:
        courante = courante + 1 if rang >= 2 else 0
        plus_longue = max(plus_longue, courante)
    return plus_longue


def charger_les_segments() -> list[dict]:
    with open(
        os.path.join(DONNEES, "nuits_possibles.json"), encoding="utf-8"
    ) as flux:
        donnees = json.load(flux)
    return [
        {
            "depart": s["depart"],
            "arrivee": s["arrivee"],
            "km": s["km"],
            "dplus_m": s["dplus_m"],
            "dmoins_m": s["dmoins_m"],
            "pk_depart_km": s["pk_depart_km"],
            "pk_arrivee_km": s["pk_arrivee_km"],
        }
        for s in donnees["entre_les_nuits"]
    ]


def inverser(segments: list[dict]) -> list[dict]:
    """Le meme sentier marche dans l'autre sens : montee et descente echangent."""
    return [
        {
            "depart": s["arrivee"],
            "arrivee": s["depart"],
            "km": s["km"],
            "dplus_m": s["dmoins_m"],
            "dmoins_m": s["dplus_m"],
            "pk_depart_km": s["pk_arrivee_km"],
            "pk_arrivee_km": s["pk_depart_km"],
        }
        for s in reversed(segments)
    ]


def chapitres(segments: list[dict]) -> dict[str, list[dict]]:
    with open(os.path.join(DONNEES, "chapitres.json"), encoding="utf-8") as flux:
        donnees = json.load(flux)
    sortie = {}
    for chapitre in donnees["chapitres"]:
        debut = chapitre["pkDepartDansLeSentierMere"]
        fin = chapitre["pkArriveeDansLeSentierMere"]
        sortie[chapitre["nom"]] = [
            s
            for s in segments
            if s["pk_depart_km"] >= debut - 0.01 and s["pk_arrivee_km"] <= fin + 0.01
        ]
    return sortie


def avec_la_variante(segments: list[dict]) -> list[dict]:
    """Le GR20 dont le premier segment est remplace par la variante Bonifatu."""
    deux = []
    pk = 0.0
    for troncon in VARIANTE_BONIFATU:
        deux.append(
            {
                "depart": troncon["depart"],
                "arrivee": troncon["arrivee"],
                "km": troncon["km"],
                "dplus_m": troncon["dplus_m"],
                "dmoins_m": troncon["dmoins_m"],
                "pk_depart_km": round(pk, 3),
                "pk_arrivee_km": round(pk + troncon["km"], 3),
            }
        )
        pk += troncon["km"]
    return deux + segments[1:]


def mesurer() -> dict:
    segments = charger_les_segments()
    inverse = inverser(segments)
    variante = avec_la_variante(segments)

    mesure = {
        "quoi": (
            "L'effort des journees du GR20 et le verdict de chaque troncon, sur "
            "les quatre bandes et les deux methodes de la tache 852."
        ),
        "tache": 852,
        "decision": "Christophe, 17/10 17:25 (memoire #102180)",
        "regle_par_journee": (
            "effort (km-effort) = km + D+/%d + %s x D-/%d ; facile sous %s, "
            "moyen jusqu a %s, difficile jusqu a %s, tres difficile au-dela"
            % (
                METRES_DE_MONTEE_PAR_KM_DE_PLAT,
                POIDS_DE_LA_DESCENTE,
                METRES_DE_MONTEE_PAR_KM_DE_PLAT,
                SEUILS_KM_EFFORT[0],
                SEUILS_KM_EFFORT[1],
                SEUILS_KM_EFFORT[2],
            )
        ),
        "regle_par_troncon": (
            "la pire journee donne le plancher ; le verdict monte d un cran "
            "quand %d journees des deux bandes hautes se SUIVENT"
            % SUITE_QUI_MONTE_LE_VERDICT
        ),
        "attribution": (
            "Trace, couchages et coupe nord/sud : OpenStreetMap, relation "
            "12484370 (GR 20 Principale), licence ODbL. Altitudes : EU-DEM "
            "25 m. Variante Bonifatu : mesure de la tache 849."
        ),
        "entrees": {
            "segments_entre_nuits": len(segments),
            "longueur_km": round(sum(s["km"] for s in segments), 3),
            "dplus_total_m": sum(s["dplus_m"] for s in segments),
            "dmoins_total_m": sum(s["dmoins_m"] for s in segments),
        },
        "sentier_entier": {},
        "chapitres": {},
        "variante_bonifatu": {},
    }

    for sens, liste in (("sens trace", segments), ("sens inverse", inverse)):
        mesure["sentier_entier"][sens] = {
            str(jours): verdict_du_troncon(journees(liste, jours))
            for jours in range(7, 32)
        }

    for nom, liste in chapitres(segments).items():
        mesure["chapitres"][nom] = {
            "segments": len(liste),
            "allures": {
                str(jours): verdict_du_troncon(journees(liste, jours))
                for jours in range(5, len(liste) + 1)
            },
        }

    mesure["variante_bonifatu"] = {
        "source": "tache 849, variante_bonifatu_849.json",
        "remplace": {
            "depart": segments[0]["depart"],
            "arrivee": segments[0]["arrivee"],
            "km": segments[0]["km"],
            "dplus_m": segments[0]["dplus_m"],
            "dmoins_m": segments[0]["dmoins_m"],
            "km_effort": round(
                effort_km(
                    segments[0]["km"],
                    segments[0]["dplus_m"],
                    segments[0]["dmoins_m"],
                ),
                2,
            ),
            "bande": BANDES[
                bande(
                    effort_km(
                        segments[0]["km"],
                        segments[0]["dplus_m"],
                        segments[0]["dmoins_m"],
                    )
                )
            ],
        },
        "par": [
            {
                "depart": t["depart"],
                "arrivee": t["arrivee"],
                "km": t["km"],
                "dplus_m": t["dplus_m"],
                "dmoins_m": t["dmoins_m"],
                "km_effort": round(
                    effort_km(t["km"], t["dplus_m"], t["dmoins_m"]), 2
                ),
                "bande": BANDES[
                    bande(effort_km(t["km"], t["dplus_m"], t["dmoins_m"]))
                ],
            }
            for t in VARIANTE_BONIFATU
        ],
        "sentier_entier_avec_la_variante": {
            str(jours): verdict_du_troncon(journees(variante, jours))
            for jours in range(7, 33)
        },
    }

    # LES REPONSES, EN CLAIR, PARCE QU'UNE TABLE NE SE LIT PAS TOUTE SEULE.
    entier = mesure["sentier_entier"]
    mesure["ce_que_la_mesure_dit"] = {
        "le_gr20_est_tres_difficile_a_toutes_les_allures_et_dans_les_deux_sens": (
            all(
                entier[sens][str(j)]["verdict"] == "tres difficile"
                for sens in entier
                for j in range(7, 32)
            )
        ),
        "la_pire_journee_ne_descend_jamais_sous_km_effort": min(
            entier[sens][str(j)]["pire_journee"]["km_effort"]
            for sens in entier
            for j in range(7, 32)
        ),
        "la_variante_bonifatu_change_de_bande": (
            mesure["variante_bonifatu"]["remplace"]["bande"]
            != mesure["variante_bonifatu"]["par"][1]["bande"]
        ),
        "avec_la_variante_le_sentier_devient_difficile_a_partir_de": next(
            (
                jours
                for jours in range(7, 33)
                if mesure["variante_bonifatu"]["sentier_entier_avec_la_variante"][
                    str(jours)
                ]["verdict"]
                != "tres difficile"
            ),
            None,
        ),
    }
    return mesure


if __name__ == "__main__":
    resultat = mesurer()
    chemin = os.path.join(DONNEES, "effort_852.json")
    with open(chemin, "w", encoding="utf-8") as flux:
        json.dump(resultat, flux, ensure_ascii=False, indent=1, sort_keys=False)
        flux.write("\n")
    dit = resultat["ce_que_la_mesure_dit"]
    print("ecrit :", chemin)
    print(
        "GR20 tres difficile partout, deux sens :",
        dit["le_gr20_est_tres_difficile_a_toutes_les_allures_et_dans_les_deux_sens"],
    )
    print(
        "plancher de la pire journee :",
        dit["la_pire_journee_ne_descend_jamais_sous_km_effort"],
        "km-effort",
    )
    print(
        "Bonifatu change de bande :", dit["la_variante_bonifatu_change_de_bande"]
    )
    print(
        "avec la variante, difficile a partir de :",
        dit["avec_la_variante_le_sentier_devient_difficile_a_partir_de"],
        "jours",
    )
