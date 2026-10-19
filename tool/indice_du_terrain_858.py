#!/usr/bin/env python3
"""L'INDICE DE TERRAIN, MESURE UNE SECONDE FOIS, EN DEHORS DE L'APPLICATION.

Tache 858. La loi est celle du bareme de la tache 857, tranchee par Christophe
le 18/10/2026 : socle en ENERGIE sur les points MESURES de la Table 2 de Minetti
2002, majoration de continuite d'exposant 1,25 desactivable a 1, couture des
montees a quinze minutes de terrain reposant, et deux couches jamais melangees -
le terrain ici, le sac et la personne plus tard, au-dehors.

POURQUOI CE FICHIER EXISTE A COTE DU CODE DART. Doctrine du depot : un calcul
qui compte se mesure DEUX FOIS, independamment, et les deux mesures doivent
concorder (precedent `tool/effort_des_journees_852.py` contre
`test/assets/effort_et_troncon_852_test.dart`). Ce script ne partage AUCUNE
ligne avec `lib/domain/indice_du_terrain.dart` : il lit la meme trace et doit
rendre les memes nombres. Sa sortie est `assets/data/gr20/indice_858.json`, que
le test Dart relit ligne par ligne.

CE QUE CE SCRIPT NE FAIT PAS. Aucune bande facile/moyen/difficile : Christophe
tranchera les niveaux apres (18/10 19:32). Aucun poids de sac, aucun surpoids,
aucun etat de genou : l'indice decrit le TERRAIN et il est le meme pour tout le
monde.

Usage:
    python tool/indice_du_terrain_858.py \
        --trace assets/data/gr20/track.gpx \
        --etapes assets/data/gr20/mesure_etapes.json \
        --nuits assets/data/gr20/nuits_possibles.json \
        --sortie assets/data/gr20/indice_858.json
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys

RAYON_TERRE_M = 6371008.8
FENETRE_LISSAGE = 7  # ProfilDuTerrain.fenetreDeLissage
PAS_ECHANTILLON = 7  # ProfilDuTerrain.pasDEchantillonnage

# --- LA LOI (LoiDeLIndice) -------------------------------------------------
BETA = 1.08  # tache 860 : exposant mesure (Riegel, borne basse recreatif)
D_REF_M = 550.0
REPIT_MINUTES = 15.0
ALLURE_REPOSANTE_KMH = 4.0
SECONDES_PAR_METRE_DE_DESCENTE = 5.0

# --- LE SOCLE MESURE (FacteurDePenteMinetti) -------------------------------
# Minetti AE et al., J Appl Physiol 93:1039-1046, 2002, Table 2. TREIZE pentes
# mesurees, et treize seulement : 5, 15 et 25 % sont INTERPOLEES.
PENTES_MESUREES = [
    -0.45, -0.40, -0.35, -0.30, -0.20, -0.10, 0.0,
    0.10, 0.20, 0.30, 0.35, 0.40, 0.45,
]
COUTS_MESURES = [
    3.46, 3.23, 2.65, 2.18, 1.30, 0.81, 1.64,
    4.68, 8.07, 11.29, 12.72, 14.75, 17.33,
]
COUT_DU_PLAT = 1.64


def _tangentes() -> list[float]:
    """Fritsch-Carlson : tangente nulle a chaque changement de sens."""
    x, y = PENTES_MESUREES, COUTS_MESURES
    n = len(x)
    h = [x[i + 1] - x[i] for i in range(n - 1)]
    d = [(y[i + 1] - y[i]) / h[i] for i in range(n - 1)]
    m = [0.0] * n
    m[0], m[-1] = d[0], d[-1]
    for i in range(1, n - 1):
        if d[i - 1] * d[i] <= 0:
            continue
        g, dr = 2 * h[i] + h[i - 1], h[i] + 2 * h[i - 1]
        m[i] = (g + dr) / (g / d[i - 1] + dr / d[i])
    return m


TANGENTES = _tangentes()


def cout_j_par_kg_par_m(pente: float) -> float:
    x, y, m = PENTES_MESUREES, COUTS_MESURES, TANGENTES
    if pente <= x[0]:
        return y[0] + m[0] * (pente - x[0])
    if pente >= x[-1]:
        return y[-1] + m[-1] * (pente - x[-1])
    i = 0
    while x[i + 1] < pente:
        i += 1
    h = x[i + 1] - x[i]
    t = (pente - x[i]) / h
    t2, t3 = t * t, t * t * t
    return (
        (2 * t3 - 3 * t2 + 1) * y[i]
        + (t3 - 2 * t2 + t) * h * m[i]
        + (-2 * t3 + 3 * t2) * y[i + 1]
        + (t3 - t2) * h * m[i + 1]
    )


def points_par_km(pente: float) -> float:
    return cout_j_par_kg_par_m(pente) / COUT_DU_PLAT


def terrain_reposant(pente: float) -> bool:
    return cout_j_par_kg_par_m(pente) <= COUT_DU_PLAT


def pente_ou_la_descente_coute_le_plat() -> float:
    """Resolue sur la courbe, jamais recopiee."""
    bas, haut = -0.30, -0.20
    for _ in range(200):
        milieu = (bas + haut) / 2
        if cout_j_par_kg_par_m(milieu) > COUT_DU_PLAT:
            bas = milieu
        else:
            haut = milieu
    return (bas + haut) / 2


# --- LE PROFIL (ProfilDuTerrain) -------------------------------------------
def lire_gpx(chemin: str) -> tuple[list[tuple[float, float]], list[float]]:
    with open(chemin, encoding="utf-8") as f:
        texte = f.read()
    motif = re.compile(
        r'<trkpt\s+lat="([-\d.]+)"\s+lon="([-\d.]+)"\s*'
        r"(?:/>|>\s*(?:<ele>([-\d.]+)</ele>)?)"
    )
    points, altitudes = [], []
    for m in motif.finditer(texte):
        points.append((float(m.group(1)), float(m.group(2))))
        altitudes.append(None if m.group(3) is None else float(m.group(3)))
    return points, altitudes


def distance_m(a, b) -> float:
    lat1, lon1 = math.radians(a[0]), math.radians(a[1])
    lat2, lon2 = math.radians(b[0]), math.radians(b[1])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    )
    return 2 * RAYON_TERRE_M * math.asin(math.sqrt(h))


def lisser(altitudes: list[float], fenetre: int) -> list[float]:
    demi = fenetre // 2
    out = []
    for i in range(len(altitudes)):
        tranche = [
            a
            for a in altitudes[max(0, i - demi) : min(len(altitudes), i + demi + 1)]
            if a is not None
        ]
        out.append(None if not tranche else sum(tranche) / len(tranche))
    return out


def profil(chemin_trace: str):
    """Rend (segments, longueur_totale_m, nb_points).

    Un segment est (pk_debut_m, longueur_m, denivele_m), lissage sur sept
    points puis un point sur sept : la convention qui produit le D+ AFFICHE.
    """
    points, altitudes = lire_gpx(chemin_trace)
    cumul = [0.0]
    for i in range(1, len(points)):
        cumul.append(cumul[-1] + distance_m(points[i - 1], points[i]))
    lisses = lisser(altitudes, FENETRE_LISSAGE)
    segments = []
    for i in range(0, len(points) - PAS_ECHANTILLON, PAS_ECHANTILLON):
        j = i + PAS_ECHANTILLON
        if lisses[i] is None or lisses[j] is None:
            continue
        longueur = cumul[j] - cumul[i]
        if longueur <= 0:
            continue
        segments.append((cumul[i], longueur, lisses[j] - lisses[i]))
    return segments, cumul[-1], len(points)


def tranche(segments, pk_debut_m: float, pk_fin_m: float):
    """Les morceaux entre deux pk, au prorata aux bords, pente inchangee."""
    retenus = []
    for pk, longueur, denivele in segments:
        debut, fin = max(pk, pk_debut_m), min(pk + longueur, pk_fin_m)
        if fin <= debut:
            continue
        part = (fin - debut) / longueur
        retenus.append((debut, longueur * part, denivele * part))
    return retenus


def inverser(segments, longueur_totale_m: float):
    """Le meme terrain marche dans l'autre sens : ordre inverse, pentes
    opposees. Un sentier descendu n'est pas un sentier monte."""
    out = []
    for pk, longueur, denivele in reversed(segments):
        out.append((longueur_totale_m - (pk + longueur), longueur, -denivele))
    return out


# --- L'INDICE (IndiceDuTerrain.calculer) -----------------------------------
def indice(terrain, beta: float = BETA, d_ref: float = D_REF_M,
           repit_minutes: float = REPIT_MINUTES) -> dict:
    socle = majoration = denivele = descente = km_de_trajet = 0.0
    energie_montante = denivele_de_la_montee = repit = 0.0
    montees = 0
    plus_grosse = 0.0

    def fermer():
        nonlocal energie_montante, denivele_de_la_montee, repit
        nonlocal majoration, montees, plus_grosse
        if denivele_de_la_montee > 0:
            majoration += energie_montante * (
                (denivele_de_la_montee / d_ref) ** (beta - 1) - 1
            )
            montees += 1
            plus_grosse = max(plus_grosse, denivele_de_la_montee)
        energie_montante = denivele_de_la_montee = repit = 0.0

    for _pk, longueur, den in terrain:
        pente = den / longueur
        km = math.hypot(longueur, den) / 1000.0
        points = points_par_km(pente) * km
        socle += points
        km_de_trajet += km
        if den > 0:
            denivele += den
            repit = 0.0
            energie_montante += points
            denivele_de_la_montee += den
            continue
        descente -= den
        if not terrain_reposant(pente):
            continue
        repit += km / ALLURE_REPOSANTE_KMH * 60.0 + (
            -den * SECONDES_PAR_METRE_DE_DESCENTE / 60.0
        )
        if repit >= repit_minutes:
            fermer()
    fermer()
    return {
        "socle_mesure": socle,
        "majoration_de_continuite": majoration,
        "indice": socle + majoration,
        "montees_continues": montees,
        "plus_grosse_montee_m": plus_grosse,
        "dplus_m": denivele,
        "dmoins_m": descente,
        "km_de_trajet": km_de_trajet,
    }


def arrondir(d: dict) -> dict:
    return {
        "socle_mesure": round(d["socle_mesure"], 2),
        "majoration_de_continuite": round(d["majoration_de_continuite"], 2),
        "indice": round(d["indice"], 2),
        "montees_continues": d["montees_continues"],
        "plus_grosse_montee_m": round(d["plus_grosse_montee_m"]),
        "dplus_m": round(d["dplus_m"]),
        "dmoins_m": round(d["dmoins_m"]),
        "km_de_trajet": round(d["km_de_trajet"], 3),
    }


def main() -> int:
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--trace", required=True)
    arg.add_argument("--etapes", required=True)
    arg.add_argument("--nuits", required=True)
    arg.add_argument("--sortie", required=True)
    options = arg.parse_args()

    segments, longueur_m, nb_points = profil(options.trace)
    sys.stderr.write(
        "Profil : %d points de trace, %d morceaux, %.3f km\n"
        % (nb_points, len(segments), longueur_m / 1000.0)
    )
    inverses = inverser(segments, longueur_m)

    with open(options.etapes, encoding="utf-8") as f:
        mesure = json.load(f)
    with open(options.nuits, encoding="utf-8") as f:
        nuits = json.load(f)

    # LES SEIZE ETAPES, DANS LES DEUX SENS.
    etapes_sens_trace, etapes_sens_inverse = [], []
    for e in mesure["etapes"]:
        debut_m, fin_m = e["pk_depart_km"] * 1000.0, e["pk_arrivee_km"] * 1000.0
        au_trace = indice(tranche(segments, debut_m, fin_m))
        etapes_sens_trace.append(
            {
                "rang": e["rang_trace"],
                "depart": e["depart"],
                "arrivee": e["arrivee"],
                "pk_depart_km": e["pk_depart_km"],
                "pk_arrivee_km": e["pk_arrivee_km"],
                **arrondir(au_trace),
            }
        )
        # Le meme troncon marche a l'envers : ses bornes se comptent depuis
        # l'autre bout du sentier.
        a_l_envers = indice(
            tranche(inverses, longueur_m - fin_m, longueur_m - debut_m)
        )
        etapes_sens_inverse.append(
            {
                "rang": e["rang_trace"],
                "depart": e["arrivee"],
                "arrivee": e["depart"],
                **arrondir(a_l_envers),
            }
        )

    tout_au_trace = indice(tranche(segments, 0.0, longueur_m))
    tout_a_l_envers = indice(tranche(inverses, 0.0, longueur_m))
    somme_trace = sum(e["indice"] for e in etapes_sens_trace)
    somme_inverse = sum(e["indice"] for e in etapes_sens_inverse)

    # L'ADDITIVITE : exacte sur le socle partout, exacte aux frontieres de
    # montee, SOUS-ADDITIVE a l'interieur d'une montee - et c'est voulu.
    pires_ecarts_du_socle = 0.0
    for k in range(1, 160):
        coupe = longueur_m * k / 160.0
        a = indice(tranche(segments, 0.0, coupe))
        b = indice(tranche(segments, coupe, longueur_m))
        ecart = abs(a["socle_mesure"] + b["socle_mesure"] - tout_au_trace["socle_mesure"])
        pires_ecarts_du_socle = max(pires_ecarts_du_socle, ecart)

    # Le cas reel : la frontiere de l'Ortu di u Piobbu tombe DANS la premiere
    # montee continue du sentier.
    e1, e2 = mesure["etapes"][0], mesure["etapes"][1]
    d_un_trait = indice(
        tranche(segments, e1["pk_depart_km"] * 1000.0, e2["pk_arrivee_km"] * 1000.0)
    )
    en_deux = (
        indice(tranche(segments, e1["pk_depart_km"] * 1000.0, e1["pk_arrivee_km"] * 1000.0))["indice"]
        + indice(tranche(segments, e2["pk_depart_km"] * 1000.0, e2["pk_arrivee_km"] * 1000.0))["indice"]
    )

    # LA MAJORATION S'ETEINT A BETA = 1, et le reste est le socle mesure.
    sans_part_assumee = indice(tranche(segments, 0.0, longueur_m), beta=1.0)

    # CHAQUE SEGMENT ENTRE DEUX NUITS RELEVEES : c'est ce que l'ecran additionne
    # pour une allure quelconque.
    pk_des_nuits = [(n["nom"], n["pk_km"]) for n in nuits.get("liste", [])]
    pk_des_nuits.sort(key=lambda t: t[1])
    segments_entre_nuits = []
    precedent_nom, precedent_pk = nuits.get("tete_de_sentier", "depart"), 0.0
    for nom, pk in pk_des_nuits:
        if pk <= precedent_pk:
            continue
        m = indice(tranche(segments, precedent_pk * 1000.0, pk * 1000.0))
        segments_entre_nuits.append(
            {
                "rang": len(segments_entre_nuits) + 1,
                "depart": precedent_nom,
                "arrivee": nom,
                "pk_depart_km": precedent_pk,
                "pk_arrivee_km": pk,
                **arrondir(m),
            }
        )
        precedent_nom, precedent_pk = nom, pk

    resultat = {
        "quoi": (
            "L'indice de terrain du GR20, mesure sur sa trace. UN POINT = UN "
            "KILOMETRE DE PLAT. L'indice decrit le TERRAIN seulement : ni sac, "
            "ni surpoids, ni genoux - cette seconde couche multipliera cet "
            "indice plus tard, au-dehors. AUCUNE bande de niveau n'est posee."
        ),
        "tache": 858,
        "loi": {
            "bareme": "tache 857, arbitrages de Christophe du 18/10/2026",
            "source_du_socle": (
                "Minetti AE, Moia C, Roi GS, Susta D, Ferretti G. Energy cost "
                "of walking and running at extreme uphill and downhill slopes. "
                "J Appl Physiol 93:1039-1046, 2002, Table 2"
            ),
            "pentes_mesurees": PENTES_MESUREES,
            "pentes_interpolees_citees_par_le_mandat": [0.05, 0.15, 0.25],
            "beta": BETA,
            "denivele_de_reference_m": D_REF_M,
            "repit_qui_coupe_une_montee_minutes": REPIT_MINUTES,
            "allure_sur_terrain_reposant_kmh": ALLURE_REPOSANTE_KMH,
            "secondes_par_metre_de_descente": SECONDES_PAR_METRE_DE_DESCENTE,
            "pente_ou_la_descente_coute_le_plat": round(
                pente_ou_la_descente_coute_le_plat(), 4
            ),
        },
        "profil": {
            "trace": options.trace,
            "points_de_trace": nb_points,
            "morceaux": len(segments),
            "longueur_km": round(longueur_m / 1000.0, 3),
            "longueur_profilee_km": round(
                (segments[-1][0] + segments[-1][1]) / 1000.0, 3
            ),
            "queue_non_profilee_m": round(
                longueur_m - (segments[-1][0] + segments[-1][1])
            ),
            "fenetre_de_lissage": FENETRE_LISSAGE,
            "pas_d_echantillonnage": PAS_ECHANTILLON,
            "ecart_au_denivele_publie": {
                "pourquoi": (
                    "mesure_etapes.json RE-CALE son echantillonnage au depart "
                    "de CHAQUE etape ; l'indice echantillonne le sentier UNE "
                    "fois, ce qui est exactement ce qui rend son socle "
                    "additif. Les deux D+ totaux concordent au metre ; une "
                    "etape peut s'ecarter de quelques metres."
                ),
                "total_m": round(
                    indice(tranche(segments, 0.0, longueur_m))["dplus_m"]
                    - mesure["dplus_total_m"],
                    1,
                ),
                "pire_etape_m": round(
                    max(
                        abs(
                            indice(
                                tranche(
                                    segments,
                                    e["pk_depart_km"] * 1000.0,
                                    e["pk_arrivee_km"] * 1000.0,
                                )
                            )["dplus_m"]
                            - e["dplus_m"]
                        )
                        for e in mesure["etapes"]
                    ),
                    1,
                ),
            },
        },
        "points_par_km_de_trajet": {
            f"{round(p * 100)}": round(points_par_km(p), 4)
            for p in [
                -0.45, -0.40, -0.35, -0.30, -0.25, -0.20, -0.15, -0.10,
                -0.05, 0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35,
                0.40, 0.45,
            ]
        },
        "etapes_sens_trace": etapes_sens_trace,
        "etapes_sens_inverse": etapes_sens_inverse,
        "segments_entre_nuits": segments_entre_nuits,
        "totaux": {
            "sens_trace": {
                "somme_des_16_etapes": round(somme_trace, 2),
                "d_un_seul_tenant": arrondir(tout_au_trace),
            },
            "sens_inverse": {
                "somme_des_16_etapes": round(somme_inverse, 2),
                "d_un_seul_tenant": arrondir(tout_a_l_envers),
            },
            "prix_du_decoupage_pct": round(
                100 * (tout_au_trace["indice"] - somme_trace) / tout_au_trace["indice"],
                2,
            ),
        },
        "additivite": {
            "socle_pire_ecart_sur_160_coupures_points": pires_ecarts_du_socle,
            "cas_reel_ortu_di_u_piobbu": {
                "en_une_journee": round(d_un_trait["indice"], 2),
                "en_deux_journees": round(en_deux, 2),
                "deficit_pct": round(
                    100 * (d_un_trait["indice"] - en_deux) / d_un_trait["indice"], 2
                ),
            },
        },
        "sans_part_assumee_beta_1": arrondir(sans_part_assumee),
    }

    with open(options.sortie, "w", encoding="utf-8") as f:
        json.dump(resultat, f, ensure_ascii=False, indent=1)
        f.write("\n")

    sys.stderr.write(
        "Sens trace   : socle %.1f  majoration %+.1f  indice %.1f  (16 etapes)\n"
        % (
            sum(e["socle_mesure"] for e in etapes_sens_trace),
            sum(e["majoration_de_continuite"] for e in etapes_sens_trace),
            somme_trace,
        )
    )
    sys.stderr.write(
        "Sens inverse : indice %.1f  (16 etapes)\n" % somme_inverse
    )
    sys.stderr.write(
        "D un seul tenant : %.1f points, %d montees continues, la plus grosse "
        "%d m\n"
        % (
            tout_au_trace["indice"],
            tout_au_trace["montees_continues"],
            round(tout_au_trace["plus_grosse_montee_m"]),
        )
    )
    sys.stderr.write(
        "Beta = 1 : indice %.1f = socle %.1f (part assumee eteinte)\n"
        % (sans_part_assumee["indice"], sans_part_assumee["socle_mesure"])
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
