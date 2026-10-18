#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tache 854 : PEUT-ON COUPER LES ETAPES LES PLUS DURES DU GR20 ?

LA QUESTION DE CHRISTOPHE, verbatim le 18/10 10:18 : « tu ne m'a pas dit s'il
etait possible de decouper les etapes les plus dure ».

LE MODELE, PRECISE PAR CHRISTOPHE LE 18/10 11:03, ET C EST LUI QUI FAIT LOI :
« NON si on peut couper des etapes pour rendre le GR20 plus facile et le faire
en 19 Jours on fait!! Mais les etapes du GR restent les etapes du GR. 16 c'et
16, si le gars fait la premiere en 2 fois et bien c'est toujours 16 etape en
17 jours ».

LES DEUX COMPTES NE SE TOUCHENT JAMAIS, ET TOUT EST LA.
  - L ETAPE est la reference FIXE du sentier et l unite de VENTE. Le GR20 en a
    SEIZE et il en aura toujours seize : 16 etapes = 16 EUR (modele #99305),
    quel que soit le nombre de jours.
  - LA JOURNEE est LIBRE. Le marcheur peut faire une etape en DEUX journees,
    grouper plusieurs etapes dans une journee, ou ajouter du repos. Couper une
    journee A L INTERIEUR d une etape est AUTORISE, et c est precisement ce
    qu on cherche pour le mode facile.
  - Faire la premiere etape en deux fois donne donc SEIZE ETAPES EN DIX-SEPT
    JOURS. Le compte d etapes ne bouge jamais, le compte de jours si.

CONSEQUENCE : les trente et une nuits relevees par la tache 838 SONT de bonnes
bornes de journee, et le repartiteur a RAISON de s en servir. Cet outil ne les
conteste pas, il les utilise.

LA LACUNE QU IL COMBLE. La tache 849 a fouille UN SEUL segment, Calenzana vers
l Ortu di u Piobbu, et a conclu qu on n y peut rien dormir a l interieur. Sa
reponse a ete lue comme « on ne peut pas couper », alors qu elle ne portait que
sur la PREMIERE etape. Les quinze autres n ont jamais ete examinees. Et depuis
la tache 852 la pire a CHANGE D IDENTITE : ce n est plus l etape 1 mais
l ETAPE 6, Ciottulu di i Mori vers Manganu, qui ne monte que 786 m mais fait
25,02 km et descend 1 190 m.

CE QU IL MESURE, ET IL N INVENTE AUCUNE DONNEE.
  1. l effort des SEIZE etapes federales, avec la formule de la tache 852 ;
  2. pour CHACUNE des etapes des deux bandes hautes : existe-t-il une nuit
     RELEVEE a son interieur, laquelle, a quel PK, avec ses coordonnees, son
     identifiant OpenStreetMap et son temps d acces DANS LES DEUX SENS ;
  3. ce que CHAQUE coupe donne : les deux demi-journees et leur effort ;
  4. LE RECALCUL : en coupant partout ou l on peut, que devient la journee la
     plus dure, a quelles allures, et le GR20 descend-il a « difficile » avant
     dix-neuf jours ;
  5. et, pour chiffrer ce que couper APPORTE, le meme sentier si l on ne
     coupait JAMAIS a l interieur d une etape (`si_l_on_ne_coupait_jamais`).

LES RESULTATS PRINCIPAUX, POUR QUE PERSONNE N AIT A LES CHERCHER.
  - OUI, LES ETAPES DURES SE COUPENT, ET LA PIRE EN PREMIER : six des dix
    etapes des bandes hautes portent une nuit relevee a l interieur, dont
    l ETAPE 6, qui tombe de 36,45 a 24,93 km-effort en dormant a Castel De
    Vergio — a UNE MINUTE du sentier. Elle quitte la bande du haut.
  - COUPER APPORTE BEAUCOUP A LA JOURNEE DU MARCHEUR : a seize jours, les
    quinze coupures font passer la pire journee de 36,45 a 26,48 km-effort.
  - MAIS CA NE SUFFIT PAS A CHANGER LA BANDE DU SENTIER, et la cause est une
    seule etape : la PREMIERE, 26,48 km-effort, dont la fouille large de la
    849 (couloir de 8 km, aucun seuil de minutes) n a rien trouve a moins de
    6,2 km de sentier et 973 m plus bas. Tant qu elle est la, le GR20 reste
    TRES DIFFICILE de 7 a 31 jours.
  - LE SEUL CHEMIN VERS « DIFFICILE » PASSE DONC PAR LA VARIANTE BONIFATU, qui
    remplace cette premiere etape par deux journees difficiles (19,21 et 18,63
    km-effort, mesure 849) — et avec elle le sentier devient difficile a
    DIX-NEUF JOURS (mesure 852), pas avant.

LES ENTREES SONT CELLES DU PRODUIT, AUCUNE SAISIE A LA MAIN. Les trente et une
nuits relevees et les trente et un segments entre elles viennent de
`assets/data/gr20/nuits_possibles.json` (tache 838, releve OpenStreetMap) ; la
coupe nord/sud vient de `assets/data/gr20/chapitres.json` (tache 839).

LES SEIZE ETAPES FEDERALES NE SONT PAS REDECLAREES ICI : elles sont RECONSTRUITES
depuis le champ `fin_d_etape` des nuits relevees. Une etape federale est le
morceau de sentier entre deux fins d etape consecutives, la tete de sentier
comptant pour la borne zero. C est la seule facon que ce fichier ne puisse pas
dire autre chose que la donnee du produit.

LE REPARTITEUR EST REPLIQUE, PAS APPROXIME : `coupes()` est la transcription de
`lib/domain/repartition_equilibree.dart`, reprise telle quelle de
`tool/effort_des_journees_852.py`. Le test
`test/assets/couper_les_dures_854_test.dart` recalcule les memes verdicts en
Dart par le socle du produit et exige le meme resultat.

CE QUE CET OUTIL NE PEUT PAS DIRE, ET IL FAUT LE LIRE AVANT SES CHIFFRES. Il ne
connait que les couchages DEJA RELEVES par la tache 838, dont le couloir etait
large de 3 km et le seuil d acces de 30 minutes. Pour une etape haute SANS nuit
interieure, « aucune nuit relevee » ne veut donc pas dire « rien n existe » :
il faut le releve large de la tache 849 (couloir de 8 km, aucun seuil de
minutes) pour le conclure, et la 849 ne l a fait que sur la premiere etape.
Les etapes concernees sont NOMMEES dans la sortie sous `a_fouiller_au_large`.

Source des couchages : OpenStreetMap, licence ODbL (releve tache 838).

Usage : python tool/couper_les_etapes_dures_854.py
Sortie : assets/data/gr20/coupes_854.json
"""

from __future__ import annotations

import json
import os

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.dirname(ICI)
NUITS = os.path.join(RACINE, "assets", "data", "gr20", "nuits_possibles.json")
CHAPITRES = os.path.join(RACINE, "assets", "data", "gr20", "chapitres.json")
MESURE = os.path.join(RACINE, "assets", "data", "gr20", "mesure_etapes.json")
SORTIE = os.path.join(RACINE, "assets", "data", "gr20", "coupes_854.json")

# DEUX SOURCES POUR LE MEME SENTIER, ET IL FAUT DIRE LAQUELLE DIT QUOI.
#
# `mesure_etapes.json` (tache 839) mesure chaque etape federale D UN BOUT A
# L AUTRE sur la trace : c est la mesure FAISANT FOI, c est elle que la fiche
# publie et c est elle que la tache 852 a chiffree (etape 6 : 25,020 km,
# D+786, D-1190, soit 36,45 km-effort).
#
# `nuits_possibles.json` (tache 838) mesure les TRENTE ET UN SEGMENTS entre
# nuits relevees. C est la seule source qui connaisse les points
# intermediaires, donc la seule avec laquelle on puisse chiffrer une COUPE.
#
# LA SOMME DES SEGMENTS D UNE ETAPE N EST PAS EXACTEMENT SA MESURE D UN BOUT A
# L AUTRE, et c est normal : le denivele est ANCRE AUX DEUX BOUTS de chaque
# morceau mesure (correction de la 838), donc decouper puis sommer ne rend pas
# le meme D+ que mesurer d un seul trait. L ecart est petit — au plus 0,21
# km-effort sur les seize etapes, sur l etape 10 — ET IL NE CHANGE AUCUNE
# BANDE : les seize etapes tombent dans la meme bande sur les deux bases, ce
# que la sortie verifie et affiche.
#
# CE FICHIER PUBLIE DONC LES DEUX : la mesure faisant foi comme chiffre de
# tete de chaque etape, et la somme des segments comme base de l arithmetique
# des coupes — une coupe se compare a ses propres moities, jamais a un total
# venu d une autre methode.

# ---------------------------------------------------------------------------
# L ECHELLE DE LA TACHE 852, RECOPIEE DEPUIS LE SOCLE DU PRODUIT
# ---------------------------------------------------------------------------
# lib/domain/echelle_de_difficulte.dart : un km-effort vaut un km de plat,
# 100 m de montee valent 1 km de plat, et la descente coute 0,30 de la montee.
COUT_MONTEE_PAR_100M = 1.0
COUT_DESCENTE = 0.30

# Seuils en km-effort (tache 852, calibres sur les deux journees que Christophe
# a classees lui-meme le 17/10 : le seuil des 1 000 m vit dans (24,50 ; 26,46]).
SEUIL_MOYEN = 10.0
SEUIL_DIFFICILE = 17.5
SEUIL_TRES_DIFFICILE = 25.0

# La suite de journees hautes qui fait monter un troncon d un cran (tache 852).
SUITE_QUI_FAIT_MONTER = 4

BANDES = ("facile", "moyen", "difficile", "tres difficile")


def effort_km(km: float, dplus_m: float, dmoins_m: float) -> float:
    """L effort d une journee en KILOMETRES-EFFORT (tache 852)."""
    return (
        km
        + COUT_MONTEE_PAR_100M * dplus_m / 100.0
        + COUT_DESCENTE * dmoins_m / 100.0
    )


def bande(effort: float) -> str:
    """La bande des quatre, bornes inclusives en bas comme « a partir de »."""
    if effort < SEUIL_MOYEN:
        return "facile"
    if effort < SEUIL_DIFFICILE:
        return "moyen"
    if effort < SEUIL_TRES_DIFFICILE:
        return "difficile"
    return "tres difficile"


def est_haute(b: str) -> bool:
    return b in ("difficile", "tres difficile")


# ---------------------------------------------------------------------------
# LE REPARTITEUR DU PRODUIT, TRANSCRIT (lib/domain/repartition_equilibree.dart)
# ---------------------------------------------------------------------------
def coupes(charges: list[float], groupes: int) -> list[int]:
    """Index de DEBUT de chaque groupe : la pire journee la plus legere, puis
    a egalite les journees les plus egales. Transcription du Dart."""
    n = len(charges)
    if n == 0 or groupes <= 0:
        return []
    if groupes >= n:
        return list(range(n))

    prefixe = [0.0] * (n + 1)
    for i in range(n):
        charge = 0.0 if charges[i] < 0 else charges[i]
        prefixe[i + 1] = prefixe[i] + charge

    def somme(debut: int, fin: int) -> float:
        return prefixe[fin] - prefixe[debut]

    cible = prefixe[n] / groupes

    # Temps 1 : minimiser la journee la plus chargee.
    inf = float("inf")
    plafonds = [[inf] * (groupes + 1) for _ in range(n + 1)]
    plafonds[0][0] = 0.0
    for i in range(1, n + 1):
        for j in range(1, min(i, groupes) + 1):
            for p in range(j - 1, i):
                precedent = plafonds[p][j - 1]
                if precedent == inf:
                    continue
                groupe = somme(p, i)
                pire = precedent if precedent > groupe else groupe
                if pire < plafonds[i][j]:
                    plafonds[i][j] = pire
    plafond = plafonds[n][groupes] * (1 + 1e-9)

    # Temps 2 : a plafond egal, minimiser l ecart quadratique a la cible.
    ecarts = [[inf] * (groupes + 1) for _ in range(n + 1)]
    ecarts[0][0] = 0.0
    origines = [[-1] * (groupes + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        for j in range(1, min(i, groupes) + 1):
            for p in range(j - 1, i):
                precedent = ecarts[p][j - 1]
                if precedent == inf:
                    continue
                groupe = somme(p, i)
                if groupe > plafond:
                    continue
                ecart = groupe - cible
                total = precedent + ecart * ecart
                if total < ecarts[i][j]:
                    ecarts[i][j] = total
                    origines[i][j] = p
    if ecarts[n][groupes] == inf:
        return _coupes_regulieres(n, groupes)

    debuts: list[int] = []
    i, j = n, groupes
    while j > 0:
        p = origines[i][j]
        if p < 0:
            return _coupes_regulieres(n, groupes)
        debuts.append(p)
        i, j = p, j - 1
    debuts.reverse()
    return debuts


def _coupes_regulieres(n: int, groupes: int) -> list[int]:
    return [i * n // groupes for i in range(groupes)]


# ---------------------------------------------------------------------------
# LES SEIZE ETAPES FEDERALES, RECONSTRUITES DEPUIS LA DONNEE
# ---------------------------------------------------------------------------
def etapes_federales(nuits: dict, mesure: dict) -> list[dict]:
    """Les seize etapes, chacune avec les segments qui la composent et les
    nuits relevees A SON INTERIEUR.

    Le chiffre de tete de chaque etape est celui de [mesure] (la mesure d un
    bout a l autre, faisant foi) ; la somme des segments est portee a cote
    pour l arithmetique des coupes."""
    liste = nuits["liste"]
    segments = nuits["entre_les_nuits"]
    tete = nuits["tete_de_sentier"]
    par_rang = {e["rang_trace"]: e for e in mesure["etapes"]}

    bornes = [n for n in liste if n.get("fin_d_etape")]
    bornes.sort(key=lambda n: n["fin_d_etape"])

    etapes: list[dict] = []
    pk_debut = 0.0
    nom_debut = tete
    for borne in bornes:
        pk_fin = borne["pk_km"]
        # Les segments de cette etape : ceux dont le depart est dans [debut, fin[
        miens = [
            s
            for s in segments
            if pk_debut - 1e-6 <= s["pk_depart_km"] < pk_fin - 1e-6
        ]
        # Les nuits a l INTERIEUR : strictement entre les deux bornes, et qui
        # ne sont pas elles-memes des fins d etape.
        interieures = [
            n
            for n in liste
            if not n.get("fin_d_etape")
            and pk_debut + 1e-6 < n["pk_km"] < pk_fin - 1e-6
        ]
        km = sum(s["km"] for s in miens)
        dplus = sum(s["dplus_m"] for s in miens)
        dmoins = sum(s["dmoins_m"] for s in miens)
        minutes = sum(s["minutes"] for s in miens)
        eff_segments = effort_km(km, dplus, dmoins)

        # LA MESURE FAISANT FOI (tache 839), celle que la fiche publie.
        foi = par_rang[borne["fin_d_etape"]]
        eff = effort_km(foi["longueur_km"], foi["dplus_m"], foi["dmoins_m"])

        etapes.append(
            {
                "rang": borne["fin_d_etape"],
                "depart": nom_debut,
                "arrivee": borne["nom"],
                "pk_depart_km": round(pk_debut, 3),
                "pk_arrivee_km": round(pk_fin, 3),
                # --- la mesure faisant foi : le chiffre de tete -------------
                "km": foi["longueur_km"],
                "dplus_m": foi["dplus_m"],
                "dmoins_m": foi["dmoins_m"],
                "effort_km": round(eff, 3),
                "bande": bande(eff),
                "source_du_chiffre": "mesure_etapes.json (tache 839)",
                # --- la somme des segments : la base des coupes -------------
                "km_somme_des_segments": round(km, 3),
                "dplus_somme_des_segments_m": dplus,
                "dmoins_somme_des_segments_m": dmoins,
                "effort_km_somme_des_segments": round(eff_segments, 3),
                "bande_somme_des_segments": bande(eff_segments),
                "ecart_des_deux_mesures_km_effort": round(
                    abs(eff - eff_segments), 3
                ),
                "les_deux_mesures_disent_la_meme_bande": bande(eff)
                == bande(eff_segments),
                "minutes": minutes,
                "segments": len(miens),
                "nuits_interieures": [
                    {
                        "nom": n["nom"],
                        "pk_km": n["pk_km"],
                        "altitude_m": n["altitude_m"],
                        "lat": n["lat"],
                        "lon": n["lon"],
                        "osm": n["osm"],
                        "osm_type": n["osm_type"],
                        "lits": n["lits"],
                        "minutes_aller": n["minutes_aller"],
                        "minutes_retour": n["minutes_retour"],
                        "dplus_aller_m": n["dplus_aller_m"],
                        "dmoins_aller_m": n["dmoins_aller_m"],
                        "origine": n["origine"],
                    }
                    for n in interieures
                ],
            }
        )
        pk_debut = pk_fin
        nom_debut = borne["nom"]
    return etapes


def coupe_d_une_etape(etape: dict, nuits: dict) -> dict | None:
    """CE QUE LA MEILLEURE COUPE DONNE : on coupe l etape en deux au point qui
    rend la plus dure des deux moities la plus legere possible, parmi les nuits
    relevees a son interieur. Rend None si aucune nuit n y tombe."""
    interieures = etape["nuits_interieures"]
    if not interieures:
        return None
    segments = nuits["entre_les_nuits"]
    miens = [
        s
        for s in segments
        if etape["pk_depart_km"] - 1e-6
        <= s["pk_depart_km"]
        < etape["pk_arrivee_km"] - 1e-6
    ]

    meilleure = None
    for n in interieures:
        avant = [s for s in miens if s["pk_arrivee_km"] <= n["pk_km"] + 1e-6]
        apres = [s for s in miens if s["pk_depart_km"] >= n["pk_km"] - 1e-6]
        if not avant or not apres:
            continue
        e1 = effort_km(
            sum(s["km"] for s in avant),
            sum(s["dplus_m"] for s in avant),
            sum(s["dmoins_m"] for s in avant),
        )
        e2 = effort_km(
            sum(s["km"] for s in apres),
            sum(s["dplus_m"] for s in apres),
            sum(s["dmoins_m"] for s in apres),
        )
        pire = max(e1, e2)
        candidat = {
            "coupe_a": n["nom"],
            "pk_km": n["pk_km"],
            "lat": n["lat"],
            "lon": n["lon"],
            "osm": n["osm"],
            "minutes_aller": n["minutes_aller"],
            "minutes_retour": n["minutes_retour"],
            "demi_1": {
                "km": round(sum(s["km"] for s in avant), 3),
                "dplus_m": sum(s["dplus_m"] for s in avant),
                "dmoins_m": sum(s["dmoins_m"] for s in avant),
                "effort_km": round(e1, 3),
                "bande": bande(e1),
            },
            "demi_2": {
                "km": round(sum(s["km"] for s in apres), 3),
                "dplus_m": sum(s["dplus_m"] for s in apres),
                "dmoins_m": sum(s["dmoins_m"] for s in apres),
                "effort_km": round(e2, 3),
                "bande": bande(e2),
            },
            "pire_des_deux_km_effort": round(pire, 3),
            "bande_apres_coupe": bande(pire),
            # LE GAIN SE COMPTE SUR LA MEME BASE QUE LES MOITIES : la somme
            # des segments. Comparer deux moities sommees a un total mesure
            # d un bout a l autre melangerait deux methodes et fabriquerait
            # un gain qui n est pas tout a fait le bon.
            "gagne_km_effort": round(
                etape["effort_km_somme_des_segments"] - pire, 3
            ),
            "base_du_gain": "somme des segments (838), les deux cotes",
        }
        if meilleure is None or pire < meilleure["pire_des_deux_km_effort"]:
            meilleure = candidat
    return meilleure


# ---------------------------------------------------------------------------
# LE RECALCUL : LE SENTIER ENTIER, A TOUTES LES ALLURES
# ---------------------------------------------------------------------------
def verdict_d_un_decoupage(journees: list[dict]) -> dict:
    """Le verdict d un troncon : la pire journee donne le plancher, et une
    suite de quatre journees hautes le fait monter d UN cran (tache 852)."""
    bandes = [bande(j["effort_km"]) for j in journees]
    pire = max(journees, key=lambda j: j["effort_km"])
    plancher = bande(pire["effort_km"])

    plus_longue_suite = 0
    courante = 0
    for b in bandes:
        if est_haute(b):
            courante += 1
            plus_longue_suite = max(plus_longue_suite, courante)
        else:
            courante = 0

    verdict = plancher
    if (
        plus_longue_suite >= SUITE_QUI_FAIT_MONTER
        and plancher != "tres difficile"
    ):
        verdict = BANDES[BANDES.index(plancher) + 1]

    return {
        "journees": len(journees),
        "verdict": verdict,
        "plancher": plancher,
        "pire_journee_km_effort": round(pire["effort_km"], 3),
        "pire_journee": "%s -> %s" % (pire["depart"], pire["arrivee"]),
        "pire_km": round(pire["km"], 3),
        "pire_dplus_m": pire["dplus_m"],
        "pire_dmoins_m": pire["dmoins_m"],
        "journees_hautes": sum(1 for b in bandes if est_haute(b)),
        "plus_longue_suite_haute": plus_longue_suite,
    }


def renverser(etapes: list[dict]) -> list[dict]:
    """LE SENS INVERSE : on marche les memes etapes a l envers, donc la montee
    de l une devient la descente de l autre. La distance ne change pas."""
    envers: list[dict] = []
    for e in reversed(etapes):
        envers.append(
            {
                "rang": e["rang"],
                "depart": e["arrivee"],
                "arrivee": e["depart"],
                "km": e["km"],
                # LES DEUX DENIVELES S ECHANGENT, et c est tout le sens
                # inverse : ce qu on montait, on le descend.
                "dplus_m": e["dmoins_m"],
                "dmoins_m": e["dplus_m"],
                "minutes": e["minutes"],
            }
        )
    return envers


def grouper(unites: list[dict], groupes: int) -> list[dict]:
    """Regroupe des unites contigues en `groupes` journees par le repartiteur
    du produit (charge = le temps de marche, modele unique du depot)."""
    charges = [float(u["minutes"]) for u in unites]
    debuts = coupes(charges, groupes)
    journees: list[dict] = []
    for idx, debut in enumerate(debuts):
        fin = debuts[idx + 1] if idx + 1 < len(debuts) else len(unites)
        bloc = unites[debut:fin]
        if not bloc:
            continue
        km = sum(u["km"] for u in bloc)
        dplus = sum(u["dplus_m"] for u in bloc)
        dmoins = sum(u["dmoins_m"] for u in bloc)
        journees.append(
            {
                "depart": bloc[0]["depart"],
                "arrivee": bloc[-1]["arrivee"],
                "km": km,
                "dplus_m": dplus,
                "dmoins_m": dmoins,
                "minutes": sum(u["minutes"] for u in bloc),
                "effort_km": effort_km(km, dplus, dmoins),
            }
        )
    return journees


def main() -> int:
    nuits = json.load(open(NUITS, encoding="utf-8"))
    chap = json.load(open(CHAPITRES, encoding="utf-8"))
    mesure = json.load(open(MESURE, encoding="utf-8"))

    etapes = etapes_federales(nuits, mesure)
    segments = nuits["entre_les_nuits"]

    # --- 1. LES SEIZE ETAPES, LEUR BANDE, ET LEUR COUPE ---------------------
    for e in etapes:
        e["coupe"] = coupe_d_une_etape(e, nuits)

    hautes = [e for e in etapes if est_haute(e["bande"])]
    coupables = [e for e in hautes if e["coupe"] is not None]
    incoupables = [e for e in hautes if e["coupe"] is None]

    # --- 2. LE RECALCUL -----------------------------------------------------
    # LE SENTIER TEL QUE LE PRODUIT LE DECOUPE DEJA : les 31 segments entre
    # nuits relevees, a toutes les allures de 7 a 31 jours. C est l etat des
    # lieux, et il est deja « on coupe partout ou l on peut » — c est tout
    # l interet de la mesure : le produit SAIT deja couper.
    allures = {}
    for n in range(7, len(segments) + 1):
        allures[n] = verdict_d_un_decoupage(grouper(segments, n))

    # L ALLURE A LAQUELLE LE SENTIER TOMBE SOUS « TRES DIFFICILE ».
    premiere_difficile = None
    for n in sorted(allures):
        if allures[n]["verdict"] != "tres difficile":
            premiere_difficile = n
            break

    # =====================================================================
    # LE CONTREFACTUEL : SI L ON NE COUPAIT JAMAIS A L INTERIEUR D UNE ETAPE
    # =====================================================================
    # Ce n est PAS la regle du produit — couper une journee a l interieur
    # d une etape est autorise (Christophe, 18/10 11:03). C est la MESURE DE
    # CE QUE COUPER APPORTE : meme sentier, meme formule, mais en n autorisant
    # une fin de journee QUE sur une fin d etape. L ecart entre les deux jeux
    # de chiffres est exactement le benefice des quinze coupures de la 838.
    #
    # Sur cette base le nombre de journees de marche plafonne a SEIZE, et le
    # plancher est l etape la plus dure : l etape 6, a 36,45 km-effort.
    allures_legales = {}
    for n in range(7, len(etapes) + 1):
        allures_legales[n] = verdict_d_un_decoupage(grouper(etapes, n))

    envers = renverser(etapes)
    allures_legales_envers = {}
    for n in range(7, len(etapes) + 1):
        allures_legales_envers[n] = verdict_d_un_decoupage(grouper(envers, n))

    # LES DEUX CHAPITRES SUR LA BASE LEGALE. Ce sont eux les PRODUITS : le
    # nord porte les etapes 1 a 9, le sud les etapes 10 a 16 (chapitres.json).
    # Leurs allures legales ne peuvent donc pas depasser 9 et 7 journees de
    # marche — ce que les fiches de la 853 annoncent jusqu a QUINZE et SEIZE.
    chapitres_legaux = {}
    for c in chap["chapitres"]:
        miennes = [
            e
            for e in etapes
            if c["premiereEtapeDuSentierMere"]
            <= e["rang"]
            <= c["derniereEtapeDuSentierMere"]
        ]
        par_allure = {}
        for n in range(1, len(miennes) + 1):
            par_allure[n] = verdict_d_un_decoupage(grouper(miennes, n))
        pire = max(miennes, key=lambda e: e["effort_km"])
        chapitres_legaux[c["id"]] = {
            "etapes": len(miennes),
            "journees_de_marche_maximum": len(miennes),
            "plancher_etape": "%s -> %s" % (pire["depart"], pire["arrivee"]),
            "plancher_km_effort": pire["effort_km"],
            "plancher_bande": pire["bande"],
            "allures": par_allure,
        }

    # LE PLANCHER LEGAL : l etape la plus dure, dans chaque sens. C est elle
    # qui minore la journee la plus dure, a toute allure et pour toujours.
    pire_etape = max(etapes, key=lambda e: e["effort_km"])
    pire_etape_envers = max(
        envers, key=lambda e: effort_km(e["km"], e["dplus_m"], e["dmoins_m"])
    )
    plancher_legal_envers = effort_km(
        pire_etape_envers["km"],
        pire_etape_envers["dplus_m"],
        pire_etape_envers["dmoins_m"],
    )

    # LA PREUVE QUE LE PLANCHER EST ATTEINT AVANT SEIZE JOURS ET NE BOUGE
    # PLUS : a partir de quelle allure la pire journee vaut-elle exactement la
    # pire etape ?
    plancher_atteint_a = None
    for n in sorted(allures_legales):
        if (
            abs(
                allures_legales[n]["pire_journee_km_effort"]
                - pire_etape["effort_km"]
            )
            < 0.01
        ):
            plancher_atteint_a = n
            break

    # --- 3. LE PLANCHER : CE QUI NE SE COUPE PAS ---------------------------
    # La plus petite unite que le decoupage sait manipuler est le SEGMENT entre
    # deux nuits relevees. Le plancher du sentier est donc le pire SEGMENT, pas
    # la pire etape federale.
    pire_segment = max(
        segments, key=lambda s: effort_km(s["km"], s["dplus_m"], s["dmoins_m"])
    )
    plancher_eff = effort_km(
        pire_segment["km"], pire_segment["dplus_m"], pire_segment["dmoins_m"]
    )

    sortie = {
        "quoi": (
            "Tache 854 : peut-on couper les etapes les plus dures du GR20 ? "
            "Pour chacune des seize etapes federales, son effort, sa bande, et "
            "s il existe une nuit RELEVEE a son interieur. Puis le recalcul du "
            "sentier entier a toutes les allures."
        ),
        "attribution": nuits["attribution"],
        "methode": {
            "effort": "km + D+/100 + 0,30 x D-/100, en kilometres-effort (852)",
            "seuils_km_effort": {
                "moyen": SEUIL_MOYEN,
                "difficile": SEUIL_DIFFICILE,
                "tres_difficile": SEUIL_TRES_DIFFICILE,
            },
            "suite_qui_fait_monter": SUITE_QUI_FAIT_MONTER,
            "source_des_nuits": (
                "assets/data/gr20/nuits_possibles.json (tache 838, "
                "releve OpenStreetMap ODbL)"
            ),
            "repartiteur": "lib/domain/repartition_equilibree.dart (transcrit)",
            "limite_connue": (
                "Le releve 838 avait un couloir de 3 km et un seuil d acces de "
                "30 min. Pour une etape haute sans nuit interieure, « aucune "
                "nuit relevee » ne vaut pas « rien n existe » : il faut le "
                "releve large de la 849 (8 km, aucun seuil). Voir "
                "a_fouiller_au_large."
            ),
        },
        "etapes_federales": etapes,
        "controle_des_deux_mesures": {
            "quoi": (
                "La mesure d un bout a l autre (839) et la somme des segments "
                "(838) ne tombent pas sur le meme chiffre ; ce controle dit de "
                "combien, et verifie que l ecart ne change AUCUNE bande."
            ),
            "ecart_max_km_effort": max(
                e["ecart_des_deux_mesures_km_effort"] for e in etapes
            ),
            "etape_du_plus_grand_ecart": max(
                etapes, key=lambda e: e["ecart_des_deux_mesures_km_effort"]
            )["rang"],
            "toutes_les_bandes_concordent": all(
                e["les_deux_mesures_disent_la_meme_bande"] for e in etapes
            ),
            "etapes_dont_la_bande_differe": [
                e["rang"]
                for e in etapes
                if not e["les_deux_mesures_disent_la_meme_bande"]
            ],
        },
        "bilan": {
            "etapes": len(etapes),
            "etapes_hautes": len(hautes),
            "hautes_coupables": [e["rang"] for e in coupables],
            "hautes_incoupables": [e["rang"] for e in incoupables],
            "nuits_interieures_relevees": sum(
                len(e["nuits_interieures"]) for e in etapes
            ),
        },
        "a_fouiller_au_large": [
            {
                "rang": e["rang"],
                "etape": "%s -> %s" % (e["depart"], e["arrivee"]),
                "effort_km": e["effort_km"],
                "bande": e["bande"],
                "deja_fouille_par_la_849": e["rang"] == 1,
            }
            for e in incoupables
        ],
        "plancher_du_sentier": {
            "pire_segment": "%s -> %s"
            % (pire_segment["depart"], pire_segment["arrivee"]),
            "km": pire_segment["km"],
            "dplus_m": pire_segment["dplus_m"],
            "dmoins_m": pire_segment["dmoins_m"],
            "effort_km": round(plancher_eff, 3),
            "bande": bande(plancher_eff),
            "pourquoi": (
                "C est la plus petite unite que le decoupage sait manipuler : "
                "aucune nuit relevee ne tombe a son interieur."
            ),
        },
        # --- LE CONTREFACTUEL : CE QUE COUPER APPORTE ----------------------
        "si_l_on_ne_coupait_jamais_dans_une_etape": {
            "avertissement": (
                "CE N EST PAS LA REGLE DU PRODUIT. Couper une journee a "
                "l interieur d une etape est AUTORISE (Christophe, 18/10 "
                "11:03 : « si le gars fait la premiere en 2 fois et bien c est "
                "toujours 16 etape en 17 jours »). Ce jeu de chiffres sert "
                "uniquement a MESURER ce que les quinze coupures apportent."
            ),
            "journees_de_marche_maximum": len(etapes),
            "pourquoi": (
                "Sans coupure interieure, seize etapes donnent au plus seize "
                "journees de marche, et le plancher est l etape la plus dure."
            ),
            "plancher_sens_normal": {
                "etape": "%s -> %s"
                % (pire_etape["depart"], pire_etape["arrivee"]),
                "rang": pire_etape["rang"],
                "km": pire_etape["km"],
                "dplus_m": pire_etape["dplus_m"],
                "dmoins_m": pire_etape["dmoins_m"],
                "effort_km": pire_etape["effort_km"],
                "bande": pire_etape["bande"],
            },
            "plancher_sens_inverse": {
                "etape": "%s -> %s"
                % (pire_etape_envers["depart"], pire_etape_envers["arrivee"]),
                "rang": pire_etape_envers["rang"],
                "km": pire_etape_envers["km"],
                "dplus_m": pire_etape_envers["dplus_m"],
                "dmoins_m": pire_etape_envers["dmoins_m"],
                "effort_km": round(plancher_legal_envers, 3),
                "bande": bande(plancher_legal_envers),
            },
            "plancher_atteint_a_partir_de_jours": plancher_atteint_a,
            "allures_sens_normal": allures_legales,
            "allures_sens_inverse": allures_legales_envers,
            "chapitres": chapitres_legaux,
        },
        # --- LA REGLE DU PRODUIT : ON COUPE OU L ON PEUT -------------------
        "en_coupant_ou_l_on_peut": {
            "quoi": (
                "`DecoupageSurLesNuits` pose les bornes de journee sur les "
                "TRENTE ET UNE nuits relevees : les seize fins d etape ET les "
                "quinze coupures de jour. Une journee peut donc s arreter A "
                "L INTERIEUR d une etape, ce qui est exactement autorise — le "
                "compte d ETAPES reste seize, seul le compte de JOURS monte."
            ),
            "ecrit_dans_la_donnee": nuits["quoi"],
            "bornes_possibles": len(segments),
            "bornes_a_l_interieur_d_une_etape": len(
                [
                    s
                    for s in segments
                    if s["pk_arrivee_km"]
                    not in {
                        n["pk_km"] for n in nuits["liste"] if n.get("fin_d_etape")
                    }
                ]
            ),
            "allures": allures,
            "premiere_allure_non_tres_difficile": premiere_difficile,
            "ce_qui_bloque": (
                "L ETAPE 1, Calenzana vers l Ortu di u Piobbu : 26,48 "
                "km-effort et aucune nuit a son interieur, meme en fouillant "
                "au large (tache 849 : rien a moins de 6,2 km de sentier et "
                "973 m plus bas). Tant qu elle est la, le sentier reste tres "
                "difficile a TOUTES les allures de 7 a 31 jours."
            ),
            "le_seul_chemin_vers_difficile": (
                "La VARIANTE BONIFATU, qui remplace cette premiere etape par "
                "deux journees difficiles (19,21 et 18,63 km-effort, mesure "
                "849). Avec elle le sentier devient difficile a DIX-NEUF "
                "JOURS (mesure 852), pas avant."
            ),
        },
        "chapitres": chap.get("chapitres", chap),
    }

    os.makedirs(os.path.dirname(SORTIE), exist_ok=True)
    with open(SORTIE, "w", encoding="utf-8") as f:
        json.dump(sortie, f, ensure_ascii=False, indent=1)

    # --- LE RENDU LISIBLE ---------------------------------------------------
    print("=== LES SEIZE ETAPES FEDERALES DU GR20, EFFORT ET COUPE ===")
    print(
        "%-4s %-44s %7s %6s %6s %8s %-14s %s"
        % ("rg", "etape", "km", "D+", "D-", "effort", "bande", "nuits int.")
    )
    for e in etapes:
        print(
            "%-4s %-44s %7.3f %6d %6d %8.2f %-14s %d"
            % (
                e["rang"],
                ("%s -> %s" % (e["depart"], e["arrivee"]))[:44],
                e["km"],
                e["dplus_m"],
                e["dmoins_m"],
                e["effort_km"],
                e["bande"],
                len(e["nuits_interieures"]),
            )
        )

    print()
    print("=== LES ETAPES DES DEUX BANDES HAUTES : PEUT-ON Y DORMIR ? ===")
    for e in hautes:
        print()
        print(
            "ETAPE %s  %s -> %s  (%.3f km, D+%d, D-%d, %.2f km-effort, %s)"
            % (
                e["rang"],
                e["depart"],
                e["arrivee"],
                e["km"],
                e["dplus_m"],
                e["dmoins_m"],
                e["effort_km"],
                e["bande"],
            )
        )
        if not e["nuits_interieures"]:
            print(
                "  AUCUNE nuit relevee a l interieur -> CETTE ETAPE NE SE "
                "COUPE PAS (releve 838 ; a fouiller au large)"
            )
            continue
        for n in e["nuits_interieures"]:
            print(
                "  %-38s PK %7.3f  alt %4d m  %s  acces %d/%d min  %s"
                % (
                    n["nom"][:38],
                    n["pk_km"],
                    n["altitude_m"],
                    "%.5f/%.5f" % (n["lat"], n["lon"]),
                    n["minutes_aller"],
                    n["minutes_retour"],
                    n["osm"][0] if n["osm"] else "-",
                )
            )
        c = e["coupe"]
        print(
            "  MEILLEURE COUPE a %s : %.2f + %.2f -> la pire des deux vaut "
            "%.2f km-effort (%s), soit %.2f de gagne"
            % (
                c["coupe_a"],
                c["demi_1"]["effort_km"],
                c["demi_2"]["effort_km"],
                c["pire_des_deux_km_effort"],
                c["bande_apres_coupe"],
                c["gagne_km_effort"],
            )
        )

    print()
    print("=== CONTROLE DES DEUX MESURES ===")
    c2 = sortie["controle_des_deux_mesures"]
    print(
        "Ecart max entre la mesure d un bout a l autre (839) et la somme des "
        "segments (838) : %.2f km-effort (etape %s)"
        % (c2["ecart_max_km_effort"], c2["etape_du_plus_grand_ecart"])
    )
    print(
        "Toutes les bandes concordent : %s%s"
        % (
            "OUI" if c2["toutes_les_bandes_concordent"] else "NON",
            ""
            if c2["toutes_les_bandes_concordent"]
            else " -> etapes %s" % c2["etapes_dont_la_bande_differe"],
        )
    )

    print()
    print("=== LE PLANCHER DU SENTIER ===")
    print(
        "Pire SEGMENT (plus petite unite coupable) : %s"
        % sortie["plancher_du_sentier"]["pire_segment"]
    )
    print(
        "  %.3f km, D+%d, D-%d -> %.2f km-effort, %s"
        % (
            pire_segment["km"],
            pire_segment["dplus_m"],
            pire_segment["dmoins_m"],
            plancher_eff,
            bande(plancher_eff),
        )
    )

    print()
    print("=== LE SENTIER ENTIER, TOUTES LES ALLURES (31 segments) ===")
    print(
        "%-6s %-16s %-16s %8s %-34s %5s %5s"
        % ("jours", "verdict", "plancher", "pire", "pire journee", "haut", "suite")
    )
    for n in sorted(allures):
        a = allures[n]
        print(
            "%-6s %-16s %-16s %8.2f %-34s %5d %5d"
            % (
                n,
                a["verdict"],
                a["plancher"],
                a["pire_journee_km_effort"],
                a["pire_journee"][:34],
                a["journees_hautes"],
                a["plus_longue_suite_haute"],
            )
        )

    print()
    print(
        "PREMIERE ALLURE NON TRES DIFFICILE SUR CETTE BASE : %s"
        % (premiere_difficile if premiere_difficile else "AUCUNE de 7 a 31 jours")
    )
    print()
    print(
        "    %d des %d bornes de journee tombent A L INTERIEUR d une etape, "
        "et c est autorise :"
        % (
            sortie["en_coupant_ou_l_on_peut"]["bornes_a_l_interieur_d_une_etape"],
            len(segments),
        )
    )
    print("    le compte d ETAPES reste seize, seul le compte de JOURS monte.")
    print()
    print("CE QUI BLOQUE : %s" % sortie["en_coupant_ou_l_on_peut"]["ce_qui_bloque"])
    print()
    print(
        "LE SEUL CHEMIN VERS DIFFICILE : %s"
        % sortie["en_coupant_ou_l_on_peut"]["le_seul_chemin_vers_difficile"]
    )

    print()
    print("=" * 74)
    print("CONTREFACTUEL : SI L ON NE COUPAIT JAMAIS DANS UNE ETAPE")
    print("=" * 74)
    print(
        "Ce n est PAS la regle du produit : c est la mesure de ce que les "
        "quinze coupures apportent."
    )
    print()
    print("PLANCHER (l etape la plus dure, elle minore toute journee) :")
    print(
        "  sens normal  : etape %s, %s -> %s"
        % (pire_etape["rang"], pire_etape["depart"], pire_etape["arrivee"])
    )
    print(
        "                 %.3f km, D+%d, D-%d -> %.2f km-effort, %s"
        % (
            pire_etape["km"],
            pire_etape["dplus_m"],
            pire_etape["dmoins_m"],
            pire_etape["effort_km"],
            pire_etape["bande"],
        )
    )
    print(
        "  sens inverse : %s -> %s"
        % (pire_etape_envers["depart"], pire_etape_envers["arrivee"])
    )
    print(
        "                 %.3f km, D+%d, D-%d -> %.2f km-effort, %s"
        % (
            pire_etape_envers["km"],
            pire_etape_envers["dplus_m"],
            pire_etape_envers["dmoins_m"],
            plancher_legal_envers,
            bande(plancher_legal_envers),
        )
    )
    print()
    print(
        "PLANCHER ATTEINT DES %s JOURNEES DE MARCHE, et il ne bouge plus."
        % plancher_atteint_a
    )

    for titre, jeu in (
        ("SENS NORMAL (Calenzana -> Conca)", allures_legales),
        ("SENS INVERSE (Conca -> Calenzana)", allures_legales_envers),
    ):
        print()
        print("--- %s ---" % titre)
        print(
            "%-6s %-16s %8s %-36s %5s %5s"
            % ("jours", "verdict", "pire", "pire journee", "haut", "suite")
        )
        for n in sorted(jeu):
            a = jeu[n]
            marque = " <<<" if n in (7, 9, 12, 16) else ""
            print(
                "%-6s %-16s %8.2f %-36s %5d %5d%s"
                % (
                    n,
                    a["verdict"],
                    a["pire_journee_km_effort"],
                    a["pire_journee"][:36],
                    a["journees_hautes"],
                    a["plus_longue_suite_haute"],
                    marque,
                )
            )

    print()
    print("--- LES DEUX CHAPITRES, LES VRAIS PRODUITS, BASE LEGALE ---")
    for cid, c in chapitres_legaux.items():
        print(
            "%-10s %d etapes -> AU PLUS %d journees de marche. "
            "Plancher %.2f km-effort (%s), %s"
            % (
                cid,
                c["etapes"],
                c["journees_de_marche_maximum"],
                c["plancher_km_effort"],
                c["plancher_bande"],
                c["plancher_etape"],
            )
        )
        for n in sorted(c["allures"]):
            a = c["allures"][n]
            print(
                "   %2d j : %-16s pire %6.2f  %s"
                % (n, a["verdict"], a["pire_journee_km_effort"], a["pire_journee"][:40])
            )

    print()
    print("Ecrit : %s" % SORTIE)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
