#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Publie les DEUX CHAPITRES du GR20 comme deux SENTIERS COMPLETS (tache 841).

CE QUE CE SCRIPT EST, ET CE QU IL N EST PAS. Il ne mesure RIEN. Toute la mesure
a ete faite par `tool/gr20_dans_stepways.py` en tache 839, sur la trace relevee
en tache 837, et elle vit dans quatre fichiers deja ecrits :
`assets/data/gr20/stages.json`, `pois.json`, `nuits_possibles.json` et
`assets/data/gr20.json`. Ce script les DECOUPE en deux, et c est tout. Un
chiffre de chapitre est donc, par construction, un chiffre de la tache 839 —
jamais une seconde mesure qui pourrait dire autre chose que la premiere.

POURQUOI DECOUPER PLUTOT QUE REMESURER. Deux mesures du meme terrain finissent
toujours par divergier d un metre, puis d un kilometre, et c est exactement le
defaut que la tache 839 a passe sa journee a eteindre (seize longueurs de topo
recalees par un coefficient de 1,069). La seule garantie qui tienne est qu il
n existe QU UNE mesure. Le decoupage la propage ; il ne la refait pas.

OU L ON COUPE, ET C EST LA SEULE CHOSE QUE CHRISTOPHE A TRANCHEE. A VIZZAVONA,
et seulement la. Confirmation du 15/10 17:58, verbatim : « vizzavona pardon,
c'est la que ca se decoupe et seulement la ». La coupe n est pas ecrite ici en
rang d etape : elle est TROUVEE par le nom d arrivee d etape, exactement comme
la tache 839 la trouve par l etiquette de coupure — un rang en dur a deja fait
croire pendant des semaines que le nord s arretait a Vizzavona alors qu il
deposait le marcheur au refuge de l Onda, une journee entiere plus tot.

CE QUE CHAQUE CHAPITRE RECOIT, PARCE QU UN CHAPITRE EST UN SENTIER COMPLET
(regle CH-11 du design #101920) : sa trace, ses etapes RENUMEROTEES a partir de
un, ses reperes, ses nuits, ses couchages, son fichier monolithique. Il ne
PARTAGE rien avec son sentier mere, et surtout pas sa trace : un randonneur qui
achete le nord ne doit pas telecharger le sud, ni le voir sur sa carte.

Usage :
    python tool/gr20_chapitres.py
    python tool/gr20_chapitres.py --verifier   # ne rien ecrire, comparer
"""

from __future__ import annotations

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gr20_dans_stepways import (  # noqa: E402  (le chemin doit etre pose avant)
    ATTRIBUTION,
    RACINE,
    charger,
    distance_m,
    ecrire,
    lire_gpx,
)

TRACE_MERE = "assets/data/gr20/track.gpx"
TRAIL_ID_MERE = "gr20"

SORTIE_MANIFESTE = "assets/data/gr20/chapitres.json"

# LE LIEU DE LA COUPE, PAR SON NOM ET PAS PAR SON RANG. C est le nom d arrivee
# d etape tel que la mesure de la tache 839 l a ecrit dans `stages.json`.
LIEU_DE_LA_COUPE = "Vizzavona"

# LES DEUX CHAPITRES. Tout ce qui est ici est EDITORIAL — un nom, une accroche,
# une couleur — et rien d autre : pas un kilometre, pas une etape, pas un
# denivele. Les chiffres sont tous comptes plus bas.
#
# LE NOM DU PRODUIT EST UNE DONNEE, ET C EST VOLONTAIRE. Le design #101920 pose
# en gate G1 que « GR » n apparait dans aucun nom de produit (la federation
# detient les signes GR et GR de Pays a l INPI, et l article L.713-6 du code de
# la propriete intellectuelle ne couvre que la citation pour indiquer une
# destination, pas le nom du produit vendu). Ces deux noms-ci reprennent ceux
# que la tache 839 a deja ecrits dans la donnee du sentier, et ils contiennent
# « GR20 » : le jour ou Christophe les baptise, cela se change ICI, en une
# ligne, sans toucher une ligne de code ni un test.
CHAPITRES = [
    {
        "id": "gr20-nord",
        "code": "NORD",
        "cote": "nord",
        "nom": "GR20 Nord",
        "accroche": "La moitie nord de la Corse, de Calenzana a Vizzavona",
    },
    {
        "id": "gr20-sud",
        "code": "SUD",
        "cote": "sud",
        "nom": "GR20 Sud",
        "accroche": "La moitie sud de la Corse, de Vizzavona a Conca",
    },
]


def index_le_plus_proche(points, cible):
    """Index du point de trace le plus proche de [cible] (lat, lon)."""
    return min(range(len(points)), key=lambda i: distance_m(points[i], cible))


def tranche_de_trace(points, altitudes, depart, arrivee):
    """La portion de trace entre deux coordonnees, bornes comprises."""
    i = index_le_plus_proche(points, depart)
    j = index_le_plus_proche(points, arrivee)
    if j <= i:
        raise SystemExit(
            "REFUS : la tranche de trace est vide ou inversee (%d -> %d)." % (i, j)
        )
    return points[i : j + 1], altitudes[i : j + 1]


def ecrire_gpx(chemin, nom, points, altitudes, verifier):
    """Ecrit la trace du chapitre au meme format que celle du sentier mere."""
    lignes = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<gpx version="1.1" creator="tool/gr20_chapitres.py" '
        'xmlns="http://www.topografix.com/GPX/1/1">',
        "  <metadata>",
        "    <name>%s</name>" % nom,
        "    <desc>%s</desc>" % ATTRIBUTION,
        "  </metadata>",
        "  <trk>",
        "    <name>%s</name>" % nom,
        "    <trkseg>",
    ]
    for (lat, lon), alt in zip(points, altitudes):
        lignes.append(
            '      <trkpt lat="%.7f" lon="%.7f"><ele>%.1f</ele></trkpt>' % (lat, lon, alt)
        )
    lignes += ["    </trkseg>", "  </trk>", "</gpx>", ""]
    texte = "\n".join(lignes)
    complet = os.path.join(RACINE, chemin)
    if verifier:
        if not os.path.exists(complet):
            return "ABSENT   %s" % chemin
        with open(complet, encoding="utf-8") as f:
            return ("IDENTIQUE %s" if f.read() == texte else "DIFFERENT %s") % chemin
    os.makedirs(os.path.dirname(complet), exist_ok=True)
    with open(complet, "w", encoding="utf-8", newline="\n") as f:
        f.write(texte)
    return "ECRIT    %s" % chemin


def renumeroter(texte, ancien, nouveau):
    """Remplace un numero d etape dans une phrase de description.

    Les descriptions de la tache 839 annoncent « Etape 13 du GR20 » et « Stage
    13 of the GR20 ». Un chapitre renumerote ses etapes a partir de un : la
    phrase doit suivre, sinon l etape 4 du sud se presenterait comme la 13.
    """
    return texte.replace("Etape %d du" % ancien, "Etape %d du" % nouveau).replace(
        "Stage %d of" % ancien, "Stage %d of" % nouveau
    )


def etapes_du_chapitre(etapes_meres, chapitre_id, premier_rang, dernier_rang):
    """Les etapes du chapitre, RENUMEROTEES, et le decalage de point kilometrique."""
    tranche = [
        e for e in etapes_meres if premier_rang <= e["stageNumber"] <= dernier_rang
    ]
    sortie = []
    for n, e in enumerate(tranche, start=1):
        copie = dict(e)
        copie["id"] = "%s-s%d" % (chapitre_id, n)
        copie["trailId"] = chapitre_id
        copie["stageNumber"] = n
        copie["descriptionFr"] = renumeroter(e["descriptionFr"], e["stageNumber"], n)
        copie["descriptionEn"] = renumeroter(e["descriptionEn"], e["stageNumber"], n)
        sortie.append(copie)
    return sortie, tranche


def reperes_du_chapitre(pois_meres, chapitre_id, premier_rang, dernier_rang):
    """Les reperes de fin d etape du chapitre, renumerotes comme ses etapes."""
    sortie = []
    for p in pois_meres:
        rang = p["stageNumber"]
        if not premier_rang <= rang <= dernier_rang:
            continue
        n = rang - premier_rang + 1
        copie = dict(p)
        copie["id"] = "%s-poi-%02d" % (chapitre_id, n)
        copie["stageId"] = "%s-s%d" % (chapitre_id, n)
        copie["stageNumber"] = n
        copie["descriptionFr"] = renumeroter(p["descriptionFr"], rang, n)
        copie["descriptionEn"] = renumeroter(p["descriptionEn"], rang, n)
        sortie.append(copie)
    return sortie


def pk_de_la_fin_detape(nuits_meres, rang):
    """Le point kilometrique MESURE de l arrivee de l etape [rang].

    Lu dans les nuits de la tache 839, qui portent le point kilometrique de
    chaque arrivee d etape tel qu il a ete projete sur la trace.
    """
    for n in nuits_meres["liste"]:
        if n["fin_d_etape"] == rang:
            return n["pk_km"]
    raise SystemExit(
        "REFUS : aucune nuit ne porte la fin de l etape %d. Les bornes d un "
        "chapitre se LISENT sur la mesure, elles ne se devinent pas." % rang
    )


def nuits_du_chapitre(nuits_meres, chapitre, pk_depart, pk_arrivee, premier_rang):
    """Les nuits du chapitre : celles de sa portion de trace, point kilometrique remis a zero.

    LE DEPART N EST PAS UNE NUIT, L ARRIVEE EN EST UNE, et c est exactement la
    convention du sentier mere : la tache 839 compte trente et une nuits dont
    les seize arrivees d etape — Conca comprise — mais pas Calenzana, parce
    qu on dort a Calenzana AVANT de partir. Un chapitre suit la meme regle :
    son point de depart est sa tete de sentier, son arrivee est une nuit.

    LA COUPE DE VIZZAVONA TOMBE DONC DES DEUX COTES COMME IL FAUT, et c est ce
    qui garantit qu aucune nuit ne se perd ni ne se compte deux fois : elle est
    l ARRIVEE du nord (donc une de ses nuits) et le DEPART du sud (donc pas une
    des siennes). Quinze nuits au nord, seize au sud, trente et une en tout —
    le compte du sentier mere, a l unite.
    """
    dedans = [
        n
        for n in nuits_meres["liste"]
        if pk_depart < n["pk_km"] <= pk_arrivee
    ]
    nuits = []
    for n in dedans:
        copie = dict(n)
        copie["pk_km"] = round(n["pk_km"] - pk_depart, 3)
        if n["fin_d_etape"] is not None:
            copie["fin_d_etape"] = n["fin_d_etape"] - premier_rang + 1
        nuits.append(copie)

    # LES SEGMENTS SONT REPRIS DU SENTIER MERE, PAS RECALCULES. Chacun a ete
    # mesure sur la trace en tache 839 ; on garde ceux qui sont entierement
    # dans le chapitre, on les re-range, et on remet leurs points
    # kilometriques a zero. Leur somme doit faire la longueur du chapitre, et
    # un test le verifie.
    segments = []
    for s in nuits_meres["entre_les_nuits"]:
        if s["pk_depart_km"] < pk_depart:
            continue
        if s["pk_arrivee_km"] > pk_arrivee:
            continue
        copie = dict(s)
        copie["rang"] = len(segments) + 1
        copie["pk_depart_km"] = round(s["pk_depart_km"] - pk_depart, 3)
        copie["pk_arrivee_km"] = round(s["pk_arrivee_km"] - pk_depart, 3)
        segments.append(copie)

    return {
        "quoi": (
            "Les nuits ou une journee du chapitre %s peut se terminer. Elles sont "
            "celles du GR20 entier, mesurees en tache 839, restreintes a la "
            "portion de trace de ce chapitre et dont le point kilometrique est "
            "remis a zero a son depart. Aucune nuit n est ajoutee ici, aucune "
            "n est remesuree." % chapitre["nom"]
        ),
        "attribution": nuits_meres["attribution"],
        "trailId": chapitre["id"],
        "trace": "assets/data/%s/track.gpx" % chapitre["id"],
        # LA LONGUEUR DE LA TRACE DU CHAPITRE, ET NON LA SOMME DE SES ETAPES.
        # Les deux ne tombent pas au metre pres — la somme des etapes arrondit
        # chaque etape au centieme de kilometre — et il faut dire laquelle on
        # porte. Ici c est la trace, parce que c est la somme des segments
        # mesures qui doit retomber dessus ; le nombre MONTRE au randonneur est
        # la somme de ses etapes, et il vit dans le manifeste des chapitres.
        "longueur_km": round(pk_arrivee - pk_depart, 3),
        "modele_de_temps_de_marche": nuits_meres["modele_de_temps_de_marche"],
        "nuits": len(nuits),
        "dont_fins_d_etape": sum(1 for n in nuits if n["fin_d_etape"] is not None),
        "dont_coupures_relevees": sum(1 for n in nuits if n["fin_d_etape"] is None),
        "tete_de_sentier": segments[0]["depart"] if segments else None,
        "segments": len(segments),
        "liste": nuits,
        "entre_les_nuits": segments,
    }


def monolithe_du_chapitre(chapitre, mere, etapes, pois, premier_rang, dernier_rang):
    """Le fichier monolithique du chapitre : son parcours, ses etapes, ses couchages.

    LE CHAPITRE A UN SEUL PARCOURS, ET C EST LUI-MEME. Le sentier mere en porte
    trois (l integral, le nord, le sud) parce qu il est un REFERENTIEL ; un
    chapitre publie est un produit, et un produit qui proposerait de choisir
    entre trois parcours dont deux ne sont pas a vendre ne serait pas un
    produit.
    """
    km = round(sum(e["distanceKm"] for e in etapes), 2)
    dplus = sum(e["elevationGainM"] for e in etapes)
    itineraire_id = "%s-ns" % chapitre["id"]

    def rang_local(stage_id):
        """Le rang d etape du sentier mere, ramene au rang du chapitre."""
        return int(stage_id.rsplit("-s", 1)[1]) - premier_rang + 1

    couchages = []
    for c in mere["accommodations"]:
        rang = int(c["stageId"].rsplit("-s", 1)[1])
        if not premier_rang <= rang <= dernier_rang:
            continue
        copie = dict(c)
        copie["id"] = c["id"].replace("gr20-", "%s-" % chapitre["id"], 1)
        copie["stageId"] = "%s-s%d" % (itineraire_id, rang_local(c["stageId"]))
        couchages.append(copie)

    reperes = []
    for p in mere["pois"]:
        rang = int(p["stageId"].rsplit("-s", 1)[1])
        if not premier_rang <= rang <= dernier_rang:
            continue
        copie = dict(p)
        copie["id"] = p["id"].replace("gr20-", "%s-" % chapitre["id"], 1)
        copie["stageId"] = "%s-s%d" % (itineraire_id, rang_local(p["stageId"]))
        reperes.append(copie)

    return {
        "attribution": mere["attribution"],
        "trail_meta": {
            "id": chapitre["id"],
            "code": chapitre["id"],
            "dataVersion": mere["trail_meta"]["dataVersion"],
            "status": "active",
            # LE CHAPITRE DIT DE QUI IL EST LE CHAPITRE. C est la seule chose
            # qu il garde de son sentier mere, et elle ne sert qu a le RANGER :
            # le mere n est pas un produit, il est une numerotation de
            # reference (design #101920, 4.4).
            "parentTrailId": TRAIL_ID_MERE,
        },
        "itineraries": [
            {
                "id": itineraire_id,
                "trailId": chapitre["id"],
                "code": "NS",
                "nameFr": "%s — %s" % (chapitre["nom"], etapes[0]["departureName"]),
                "nameEn": "%s — %s" % (chapitre["nom"], etapes[0]["departureName"]),
                "nameDe": "%s — %s" % (chapitre["nom"], etapes[0]["departureName"]),
                "nameIt": "%s — %s" % (chapitre["nom"], etapes[0]["departureName"]),
                "nameEs": "%s — %s" % (chapitre["nom"], etapes[0]["departureName"]),
                "distanceKm": km,
                "elevationGain": dplus,
                "stageCount": len(etapes),
            }
        ],
        "stages": [
            {
                "id": "%s-s%d" % (itineraire_id, e["stageNumber"]),
                "itineraryId": itineraire_id,
                "stageNumber": e["stageNumber"],
                "nameFr": e["nameFr"],
                "nameEn": e["nameEn"],
                "nameDe": e["nameFr"],
                "nameIt": e["nameFr"],
                "nameEs": e["nameFr"],
                "startLat": e["startLat"],
                "startLng": e["startLng"],
                "endLat": e["endLat"],
                "endLng": e["endLng"],
                "distanceKm": e["distanceKm"],
                "elevationGain": e["elevationGainM"],
                "elevationLoss": e["elevationLossM"],
                "durationMinutes": e["estimatedDurationMinutes"],
                "difficulty": e["difficulty"],
            }
            for e in etapes
        ],
        "accommodations": couchages,
        "pois": reperes,
    }


def main():
    arg = argparse.ArgumentParser(
        description="Publie les deux chapitres du GR20 comme deux sentiers complets."
    )
    arg.add_argument(
        "--verifier",
        action="store_true",
        help="ne rien ecrire : dire si les fichiers produits sont a jour",
    )
    options = arg.parse_args()

    etapes_meres = charger("assets/data/gr20/stages.json")
    pois_meres = charger("assets/data/gr20/pois.json")
    nuits_meres = charger("assets/data/gr20/nuits_possibles.json")
    mere = charger("assets/data/gr20.json")
    points, altitudes = lire_gpx(os.path.join(RACINE, TRACE_MERE))
    if any(a is None for a in altitudes):
        raise SystemExit("REFUS : la trace mere porte des altitudes manquantes.")

    # --- OU L ON COUPE : TROUVE PAR LE NOM, JAMAIS ECRIT EN RANG ---
    rangs_de_la_coupe = [
        e["stageNumber"]
        for e in etapes_meres
        if LIEU_DE_LA_COUPE in e["arrivalName"]
    ]
    if len(rangs_de_la_coupe) != 1:
        raise SystemExit(
            "REFUS : « %s » doit etre l arrivee d EXACTEMENT une etape, trouve %d."
            % (LIEU_DE_LA_COUPE, len(rangs_de_la_coupe))
        )
    rang_de_la_coupe = rangs_de_la_coupe[0]
    dernier_rang_du_sentier = max(e["stageNumber"] for e in etapes_meres)

    bornes = {
        "NORD": (1, rang_de_la_coupe),
        "SUD": (rang_de_la_coupe + 1, dernier_rang_du_sentier),
    }

    lignes = []
    manifeste = []
    for chapitre in CHAPITRES:
        premier, dernier = bornes[chapitre["code"]]
        etapes, tranche_mere = etapes_du_chapitre(
            etapes_meres, chapitre["id"], premier, dernier
        )
        if not etapes:
            raise SystemExit("REFUS : chapitre %s sans etape." % chapitre["id"])
        reperes = reperes_du_chapitre(pois_meres, chapitre["id"], premier, dernier)

        # LA TRANCHE DE TRACE : du depart de la premiere etape a l arrivee de
        # la derniere, bornes retrouvees sur la trace par leurs coordonnees.
        pts, alts = tranche_de_trace(
            points,
            altitudes,
            (etapes[0]["startLat"], etapes[0]["startLng"]),
            (etapes[-1]["endLat"], etapes[-1]["endLng"]),
        )

        # LES BORNES DU CHAPITRE SUR LA TRACE MERE, LUES DANS LES NUITS DEJA
        # MESUREES ET JAMAIS RECALCULEES EN SOMMANT.
        #
        # LA PREMIERE VERSION DE CE SCRIPT LES SOMMAIT, ET ELLE PERDAIT SIX
        # KILOMETRES. Additionner les longueurs d etape — chacune arrondie au
        # centieme de kilometre — donne 91,80 km au nord la ou la trace en
        # mesure 91,797 : trois metres d ecart, et c est tout ce qu il faut
        # pour que le premier segment du sud, qui part du point kilometrique
        # 91,797, tombe JUSTE EN DEHORS d un chapitre declare commencer a
        # 91,800. Mesure du defaut : les segments du sud sommaient 85,717 km
        # pour un chapitre de 91,79 km. Les points kilometriques ne se
        # recalculent pas, ils se LISENT la ou ils ont ete mesures.
        pk_depart = 0.0 if premier == 1 else pk_de_la_fin_detape(
            nuits_meres, premier - 1
        )
        pk_arrivee = pk_de_la_fin_detape(nuits_meres, dernier)
        nuits = nuits_du_chapitre(
            nuits_meres, chapitre, pk_depart, pk_arrivee, premier
        )
        monolithe = monolithe_du_chapitre(
            chapitre, mere, etapes, reperes, premier, dernier
        )

        base = "assets/data/%s" % chapitre["id"]
        lignes.append(
            ecrire_gpx(
                "%s/track.gpx" % base,
                chapitre["nom"],
                pts,
                alts,
                options.verifier,
            )
        )
        lignes.append(ecrire("%s/stages.json" % base, etapes, options.verifier))
        lignes.append(ecrire("%s/pois.json" % base, reperes, options.verifier))
        lignes.append(
            ecrire("%s/nuits_possibles.json" % base, nuits, options.verifier)
        )
        lignes.append(
            ecrire("assets/data/%s.json" % chapitre["id"], monolithe, options.verifier)
        )

        km = round(sum(e["distanceKm"] for e in etapes), 2)
        manifeste.append(
            {
                "id": chapitre["id"],
                "parentTrailId": TRAIL_ID_MERE,
                "code": chapitre["code"],
                "nom": chapitre["nom"],
                "accroche": chapitre["accroche"],
                "depart": etapes[0]["departureName"],
                "arrivee": etapes[-1]["arrivalName"],
                "premiereEtapeDuSentierMere": premier,
                "derniereEtapeDuSentierMere": dernier,
                "etapes": len(etapes),
                "distanceKm": km,
                "deniveleM": sum(e["elevationGainM"] for e in etapes),
                "descenteM": sum(e["elevationLossM"] for e in etapes),
                "minutesDeMarche": sum(e["estimatedDurationMinutes"] for e in etapes),
                "pkDepartDansLeSentierMere": pk_depart,
                "pkArriveeDansLeSentierMere": pk_arrivee,
                "pointsDeTrace": len(pts),
                "nuits": nuits["nuits"],
                "prixEnEtapes": len(etapes),
            }
        )

    total_etapes = sum(c["etapes"] for c in manifeste)
    if total_etapes != dernier_rang_du_sentier:
        raise SystemExit(
            "REFUS : les chapitres comptent %d etapes, le sentier en a %d. Un "
            "chapitre ne partage AUCUNE journee avec son voisin (regle CH-9)."
            % (total_etapes, dernier_rang_du_sentier)
        )

    fichier = {
        "quoi": (
            "Les chapitres du GR20, l unite de VENTE de StepWays. Un chapitre est "
            "publie comme un sentier COMPLET (regle CH-11 du design #101920) : son "
            "nom, sa trace, ses etapes, ses lieux, son prix. Le sentier mere n est "
            "plus un produit : il est une numerotation de reference."
        ),
        "decide_par": (
            "Christophe, 15/10 17:45 (« on achete le sentier seulement si il n y a "
            "pas de chapitres. Sinon par exemple pour le GR20 on peut acheter "
            "chapitre 1, chapitre 2, chapitre 1 and 2 ») et 15/10 17:58 "
            "(« vizzavona pardon, c'est la que ca se decoupe et seulement la »)."
        ),
        "attribution": ATTRIBUTION,
        "parentTrailId": TRAIL_ID_MERE,
        "lieuDeLaCoupe": LIEU_DE_LA_COUPE,
        "etapeDArriveeDeLaCoupe": rang_de_la_coupe,
        "etapesDuSentierMere": dernier_rang_du_sentier,
        "origineDesChiffres": (
            "tache 839 — assets/data/gr20/stages.json, pois.json, "
            "nuits_possibles.json et assets/data/gr20.json. Ce fichier DECOUPE "
            "ces mesures, il n en refait aucune."
        ),
        "prixEnEtapes": (
            "Le prix d un chapitre EST son nombre d etapes. Acheter les deux "
            "chapitres coute la SOMME de leurs etapes, prelevee sur la cagnotte : "
            "aucun lot n est a construire en boutique."
        ),
        "chapitres": manifeste,
    }
    lignes.append(ecrire(SORTIE_MANIFESTE, fichier, options.verifier))

    for ligne in lignes:
        sys.stderr.write(ligne + "\n")
    sys.stderr.write(
        "\nCoupe a %s (arrivee de l etape %d sur %d). %s\n"
        % (
            LIEU_DE_LA_COUPE,
            rang_de_la_coupe,
            dernier_rang_du_sentier,
            "  ".join(
                "%s : %d etapes, %.2f km, D+ %d m, %d points de trace, %d nuits"
                % (
                    c["id"],
                    c["etapes"],
                    c["distanceKm"],
                    c["deniveleM"],
                    c["pointsDeTrace"],
                    c["nuits"],
                )
                for c in manifeste
            ),
        )
    )
    if options.verifier and any(
        l.startswith(("DIFFERENT", "ABSENT")) for l in lignes
    ):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
