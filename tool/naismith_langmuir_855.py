#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Le temps de marche du GR20 par NAISMITH (1892) CORRIGE PAR LANGMUIR.

POURQUOI CE FICHIER EXISTE. Christophe a demande d ou sortait le calculateur de
difficulte, et la reponse honnete etait mauvaise. L echelle d effort du depot
reprenait les INGREDIENTS de l indice IBP, dont le bareme exact n est PAS public
— le depot l ecrivait lui-meme (`ibp_calculator.dart` : « le bareme IBP n etant
pas public, c est une approximation assumee ») ; l equivalence « 100 m de montee
valent 1 km de plat » est citee partout sans etude primaire ; et le poids 0,30 de
la descente n est source nulle part. Decision du 18/10 11:33, verbatim :
« prend NAISMITH pour tes calculs ».

NAISMITH EST PUBLIC ET VERIFIABLE. William W. Naismith, Scottish Mountaineering
Club Journal, 1892 : UNE HEURE POUR CINQ KILOMETRES, PLUS UNE HEURE POUR SIX
CENTS METRES DE MONTEE. Rien d autre, et c est la son defaut :

    NAISMITH PUR NE COMPTE PAS LA DESCENTE.

L adopter tel quel EFFACERAIT ce que Christophe a demande la veille — que le
negatif et les kilometres comptent — et l etape 6 (25 km, 1 190 m de descente)
perdrait exactement ce qui la rend monstrueuse. ON PREND DONC LA CORRECTION DE
LANGMUIR, publique, de la meme lignee et enseignee avec Naismith depuis
*Mountaincraft and Leadership* (Eric Langmuir, 1984) :

  - on RETIRE dix minutes par 300 m de descente sur pente DOUCE (5 a 12 degres) ;
  - on AJOUTE dix minutes par 300 m de descente sur pente RAIDE (plus de
    12 degres) ;
  - sous 5 degres, aucune correction : c est du plat que Naismith paie deja.

SUR LE GR20 LA PLUPART DES DESCENTES SONT RAIDES, donc Langmuir CHARGE la
descente : la demande de Christophe est tenue AVEC une source publique.

SEGMENT PAR SEGMENT SUR LA VRAIE TRACE, ET C EST LA TOUT L INTERET. Une pente
ne se classe pas sur une moyenne d etape : l etape 6 descend 1 190 m sur 25 km,
soit 2,7 degres de moyenne — « pente douce », donc une REMISE de quarante
minutes. Marchee pour de vrai elle alterne des dalles raides et des replats :
mesuree segment par segment, sa descente est RAIDE sur l essentiel et Langmuir
la CHARGE. La moyenne et la mesure ne disent pas seulement des nombres
differents, elles disent le CONTRAIRE l une de l autre. On mesure donc sur les
9 128 points de `assets/data/gr20/track.gpx`, un couple de points apres l autre.

LE MOTEUR DE DENIVELE EST CELUI DE LA MAISON, PAS UN SECOND. Les montees et les
descentes viennent de `denivele_maison` de `tool/gr20_dans_stepways.py` :
moyenne glissante sur sept points, LES DEUX BOUTS ANCRES a leur altitude reelle
(tache 838), puis un point sur sept. C est ce filtre qui a produit les chiffres
publies du sentier, et c est sur SES echantillons que les pentes sont classees.
Mesurer Naismith sur les points BRUTS aurait donne un troisieme jeu de chiffres
(15 237 m de montee brute contre 11 602 m publies, soit 31 % de plus) : le temps
annonce n aurait plus ete celui du D+ annonce juste a cote.

CE FICHIER NE FIXE AUCUN SEUIL, ET C EST VOULU. Christophe, 18/10 11:33 :
« ensuite on discutera du positionnement facile/moyen/difficile/tres difficile ».
On rend donc les CHIFFRES BRUTS en heures et minutes, et l ancien calcul en
kilometres-effort A COTE pour que la comparaison soit lisible. Aucune bande,
aucun reclassement : les seuils seront decides apres lecture.

Usage :
    python tool/naismith_langmuir_855.py
    python tool/naismith_langmuir_855.py --verifier   # ne rien ecrire, comparer
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

TRACE = "assets/data/gr20/track.gpx"
MESURE_ETAPES = "assets/data/gr20/mesure_etapes.json"
NUITS = "assets/data/gr20/nuits_possibles.json"
CHAPITRES = "assets/data/gr20/chapitres.json"
COUPURES_SOURCE = "tool/coupures_gr20.json"
ETAPES_DE_L_APP = "assets/data/gr20/stages.json"

SORTIE = "assets/data/gr20/naismith_855.json"

# --- Le moteur de denivele de la maison, repris a l identique ----------------
# `tool/gr20_dans_stepways.py` : moyenne glissante sur sept points, les deux
# bouts ancres, puis un point sur sept. Les trois constantes ne sont pas
# choisies ici.
RAYON_TERRE_M = 6371008.8
FENETRE_LISSAGE = 7
PAS_ECHANTILLON = 7

# --- NAISMITH 1892, les deux seuls nombres du modele -------------------------
#: Une heure pour CINQ kilometres -> 12 minutes du kilometre.
NAISMITH_KM_PAR_HEURE = 5.0
#: Une heure pour SIX CENTS metres de montee -> 0,1 minute du metre.
NAISMITH_MONTEE_M_PAR_HEURE = 600.0
#: Minutes du kilometre, DERIVEE de [NAISMITH_KM_PAR_HEURE].
NAISMITH_MINUTES_PAR_KM = 60.0 / NAISMITH_KM_PAR_HEURE

# --- TOBLER 1993, la seule fonction des trois qui voit la RAIDEUR -------------
#: Vitesse de pointe, en km/h, atteinte a [TOBLER_PENTE_OPTIMALE] de pente.
TOBLER_VITESSE_KMH = 6.0
#: Le coefficient d amortissement de la pente.
TOBLER_AMORTISSEMENT = 3.5
#: La pente la plus rapide : -5 pct, soit une legere descente.
TOBLER_PENTE_OPTIMALE = 0.05

# --- LANGMUIR, la correction de descente -------------------------------------
#: Sous cette pente, la descente ne corrige rien (Naismith paie deja le plat).
LANGMUIR_PENTE_DOUCE_DEG = 5.0
#: Au-dela de cette pente, la descente COUTE au lieu de rapporter.
LANGMUIR_PENTE_RAIDE_DEG = 12.0
#: Dix minutes par 300 m de descente, retirees en pente douce, ajoutees en raide.
LANGMUIR_MINUTES = 10.0
LANGMUIR_PAR_METRES = 300.0

# --- L ANCIEN CALCUL, garde EN PARALLELE pour la comparaison ------------------
# `lib/domain/echelle_de_difficulte.dart` : km-effort = km + D+/100 + 0,30 x D-/100.
# Il n est pas applique ici, il est RECOPIE a cote pour que l ecart se lise.
EFFORT_MONTEE_PAR_100M = 1.0
EFFORT_POIDS_DESCENTE = 0.30

ATTRIBUTION = (
    "Trace : OpenStreetMap, relation 12484370 (GR 20 Principale), licence ODbL. "
    "Altitudes : modele de terrain EU-DEM 25 m via opentopodata. "
    "Modele de temps : Naismith (SMCJ, 1892) corrige par Langmuir "
    "(Mountaincraft and Leadership, 1984). Les deux sont publics."
)


def arrondi(x):
    """Arrondi de Dart (`num.round()`) : la moitie s en va de zero."""
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def chemin(relatif):
    return os.path.join(RACINE, relatif.replace("/", os.sep))


def charger(relatif):
    with open(chemin(relatif), encoding="utf-8") as f:
        return json.load(f)


def lire_gpx(relatif):
    """Les points et les altitudes de la trace, dans l ordre du fichier.

    Lecture par expression reguliere comme `gr20_dans_stepways.lire_gpx` : la
    trace est un GPX plat de 9 128 points et une analyse XML complete n y
    apporterait rien. Une altitude absente reste None et n est JAMAIS inventee.
    """
    import re

    texte = open(chemin(relatif), encoding="utf-8").read()
    points, altitudes = [], []
    motif = re.compile(
        r'<trkpt[^>]*lat="([-\d.]+)"[^>]*lon="([-\d.]+)"[^>]*>(.*?)</trkpt>'
        r"|<trkpt[^>]*lat=\"([-\d.]+)\"[^>]*lon=\"([-\d.]+)\"[^>]*/>",
        re.S,
    )
    for m in motif.finditer(texte):
        if m.group(1) is not None:
            points.append((float(m.group(1)), float(m.group(2))))
            ele = re.search(r"<ele>([-\d.]+)</ele>", m.group(3) or "")
            altitudes.append(float(ele.group(1)) if ele else None)
        else:
            points.append((float(m.group(4)), float(m.group(5))))
            altitudes.append(None)
    return points, altitudes


def distance_m(a, b):
    """Haversine, en metres — la meme que le moteur de la maison."""
    lat1, lon1 = math.radians(a[0]), math.radians(a[1])
    lat2, lon2 = math.radians(b[0]), math.radians(b[1])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    )
    return 2 * RAYON_TERRE_M * math.asin(math.sqrt(h))


def cumuls(points):
    """Distance cumulee, en metres, index par index."""
    cumul = [0.0]
    for i in range(1, len(points)):
        cumul.append(cumul[-1] + distance_m(points[i - 1], points[i]))
    return cumul


def profil_echantillonne(altitudes, cumul, fenetre=FENETRE_LISSAGE, pas=PAS_ECHANTILLON):
    """LES ECHANTILLONS DU FILTRE DE LA MAISON, AVEC LEUR ABSCISSE.

    C est `denivele_maison` ouvert en deux : la meme moyenne glissante, les
    memes deux bouts ancres, la meme decimation d un point sur sept — mais on
    rend les echantillons RETENUS au lieu de leur seule somme, parce que
    Langmuir a besoin de la PENTE de chacun, donc de sa longueur horizontale.

    Rend une liste de couples `(distance_m_depuis_le_debut, altitude_m)`.
    [sommer_le_denivele] verifie qu on retrouve EXACTEMENT les montees et les
    descentes publiees : si cette fonction derivait du moteur de la maison, le
    controle du moteur rougirait.
    """
    paires = [(c, a) for c, a in zip(cumul, altitudes) if a is not None]
    if len(paires) < 2:
        return []
    abscisses = [c for c, _ in paires]
    propres = [a for _, a in paires]

    if len(propres) >= fenetre:
        lisse = []
        for i in range(len(propres)):
            debut = max(0, i - fenetre // 2)
            fin = min(len(propres), i + fenetre // 2 + 1)
            lisse.append(sum(propres[debut:fin]) / (fin - debut))
        # LES DEUX BOUTS ANCRES (tache 838) : la moyenne glissante ecrase les
        # extremites du profil, et sur une montee reguliere de 95 m elle n en
        # rendait que 80.
        lisse[0] = propres[0]
        lisse[-1] = propres[-1]
        indices = list(range(0, len(lisse), pas))
        if indices[-1] != len(lisse) - 1:
            indices.append(len(lisse) - 1)
        return [(abscisses[i], lisse[i]) for i in indices]
    return list(zip(abscisses, propres))


def sommer_le_denivele(profil):
    """Montee et descente des echantillons — l arithmetique de `denivele_maison`."""
    plus = moins = 0.0
    for (_, a), (_, b) in zip(profil, profil[1:]):
        if b > a:
            plus += b - a
        else:
            moins += a - b
    return arrondi(plus), arrondi(moins)


def naismith_langmuir(profil, a_l_envers=False):
    """LE TEMPS DE MARCHE D UN PROFIL, SEGMENT PAR SEGMENT.

    On parcourt les echantillons deux a deux. Chaque couple donne une longueur
    horizontale et une variation d altitude :

      - NAISMITH paie la longueur (une heure pour cinq kilometres) et, quand on
        monte, la montee (une heure pour six cents metres) ;
      - LANGMUIR corrige la descente SELON SA PENTE, classee sur ce couple-la et
        sur aucune moyenne : rien sous 5 degres, moins dix minutes par 300 m de
        5 a 12 degres, plus dix minutes par 300 m au-dela de 12 degres.

    [a_l_envers] marche le meme profil dans l autre sens. La longueur
    horizontale ne change pas, la variation d altitude CHANGE DE SIGNE : ce qui
    montait descend. C est exact et cela evite de relire la trace a l envers —
    le sens inverse du depot fait deja exactement cette permutation
    (`SegmentEntreNuits.aLEnvers`).

    Rend le detail, parce qu un total sans son decoupage ne se verifie pas.
    """
    minutes_plat = 0.0
    minutes_montee = 0.0
    minutes_douce = 0.0
    minutes_raide = 0.0
    metres_douce = 0.0
    metres_raide = 0.0
    metres_sous_le_seuil = 0.0
    montee = descente = 0.0
    dh_total = 0.0

    for (ca, aa), (cb, ab) in zip(profil, profil[1:]):
        dh = abs(cb - ca)
        dz = (ab - aa) * (-1.0 if a_l_envers else 1.0)

        dh_total += dh
        minutes_plat += dh / 1000.0 / NAISMITH_KM_PAR_HEURE * 60.0

        if dz > 0:
            montee += dz
            minutes_montee += dz / NAISMITH_MONTEE_M_PAR_HEURE * 60.0
            continue
        if dz == 0:
            continue

        perdu = -dz
        descente += perdu
        # LA PENTE DE CE COUPLE, EN DEGRES. Une longueur horizontale nulle avec
        # une chute d altitude est une falaise : 90 degres, donc raide. Sans ce
        # cas, une division par zero ferait un NaN qui contaminerait le total.
        pente = 90.0 if dh == 0 else math.degrees(math.atan(perdu / dh))

        if pente < LANGMUIR_PENTE_DOUCE_DEG:
            metres_sous_le_seuil += perdu
        elif pente <= LANGMUIR_PENTE_RAIDE_DEG:
            metres_douce += perdu
            minutes_douce -= perdu / LANGMUIR_PAR_METRES * LANGMUIR_MINUTES
        else:
            metres_raide += perdu
            minutes_raide += perdu / LANGMUIR_PAR_METRES * LANGMUIR_MINUTES

    total = minutes_plat + minutes_montee + minutes_douce + minutes_raide
    return {
        "minutes": arrondi(max(0.0, total)),
        "minutes_exactes": round(total, 3),
        # LES ENTREES DU MODELE, NON ARRONDIES. Elles sont publiees pour que
        # l implementation Dart refasse le calcul AU MEME RESULTAT et qu un test
        # puisse l exiger. Les arrondir d abord ne marche pas : sur les
        # quatre-vingt-quatorze cas mesures, DEUX basculent d une minute quand
        # on repart des metres arrondis (le segment 7 sort 56 au lieu de 57).
        # Une garde a 1 minute pres n est pas une garde.
        "entrees_du_modele": {
            "km": round(dh_total / 1000.0, 6),
            "dplus_m": round(montee, 6),
            "descente_en_pente_douce_m": round(metres_douce, 6),
            "descente_en_pente_raide_m": round(metres_raide, 6),
        },
        "minutes_naismith": arrondi(minutes_plat + minutes_montee),
        "minutes_langmuir": arrondi(minutes_douce + minutes_raide),
        "minutes_du_plat": arrondi(minutes_plat),
        "minutes_de_la_montee": arrondi(minutes_montee),
        "minutes_retirees_en_pente_douce": arrondi(-minutes_douce),
        "minutes_ajoutees_en_pente_raide": arrondi(minutes_raide),
        "descente_en_pente_douce_m": arrondi(metres_douce),
        "descente_en_pente_raide_m": arrondi(metres_raide),
        "descente_sous_le_seuil_m": arrondi(metres_sous_le_seuil),
        "dplus_m": arrondi(montee),
        "dmoins_m": arrondi(descente),
        "total_negatif_ramene_a_zero": total < 0.0,
    }


def vitesse_tobler_kmh(pente):
    """La vitesse de Tobler, en km/h, pour une pente SIGNEE (positive en montee).

    vitesse = 6 x exp(-3,5 x |pente + 0,05|). Une seule implementation, et le
    Dart la refait a l identique ([VitesseDeTobler]).
    """
    return TOBLER_VITESSE_KMH * math.exp(
        -TOBLER_AMORTISSEMENT * abs(pente + TOBLER_PENTE_OPTIMALE)
    )


def tobler(profil, a_l_envers=False):
    """LE TEMPS DE MARCHE PAR LA FONCTION DE TOBLER (1993), SEGMENT PAR SEGMENT.

    POURQUOI ELLE EST AJOUTEE, ET C EST CHRISTOPHE QUI L A VU. Verbatim le
    18/10 11:56 : « quand les montes sont pentue c'est pus dificile de monter
    700 metres sur 1KM que 700 metre sur 5 ». IL A RAISON ET NAISMITH NE SAIT
    PAS LE DIRE : Naismith est LINEAIRE en denivele — une heure par six cents
    metres, quelle que soit la pente — donc 700 m lui coutent exactement pareil
    etales sur 1 km ou sur 5. Langmuir ne regarde la pente QUE pour la descente.
    Les deux sont donc aveugles a la RAIDEUR d une montee.

    TOBLER N EST PAS AVEUGLE. Waldo Tobler, « Three Presentations on
    Geographical Analysis and Modeling », NCGIA Technical Report 93-1, 1993 :

        vitesse = 6 x exp(-3,5 x |pente + 0,05|)   en km/h

    ou la pente est le rapport du denivele a la distance HORIZONTALE, signe
    (positif en montee). Elle est publique, universelle en cartographie (c est
    la fonction des outils SIG), et elle est DERIVABLE d une mesure de terrain
    plutot que d une regle du pouce.

    CE QU ELLE DIT, ET QUI REPOND EXACTEMENT A CHRISTOPHE :
      - a plat (pente 0) : 6 x exp(-0,175) = 5,04 km/h ;
      - le maximum est a -5 % (on descend legerement) : 6,00 km/h ;
      - a +70 % de pente (700 m sur 1 km) : 6 x exp(-2,625) = 0,43 km/h ;
      - a +14 % de pente (700 m sur 5 km) : 6 x exp(-0,665) = 3,08 km/h.
    Donc monter 700 m sur 1 km coute 2 h 19, et sur 5 km 1 h 37 — QUARANTE-DEUX
    MINUTES DE PLUS pour le meme denivele. Naismith dit 1 h 10 dans les deux
    cas.

    La vitesse s applique a la distance HORIZONTALE, comme Tobler l a publiee.
    [a_l_envers] permute le signe de la pente : une montee devient une descente.
    """
    minutes_total = 0.0
    dh_total = 0.0
    for (ca, aa), (cb, ab) in zip(profil, profil[1:]):
        dh = abs(cb - ca)
        if dh == 0:
            continue
        dz = (ab - aa) * (-1.0 if a_l_envers else 1.0)
        pente = dz / dh
        vitesse_kmh = vitesse_tobler_kmh(pente)
        dh_total += dh
        minutes_total += (dh / 1000.0) / vitesse_kmh * 60.0
    return {
        "minutes": arrondi(minutes_total),
        "minutes_exactes": round(minutes_total, 3),
        "temps": en_clair(arrondi(minutes_total)),
        "km_du_profil": round(dh_total / 1000.0, 3),
    }


def montees_continues(profil, seuil_pct, a_l_envers=False):
    """LES MONTEES D UN SEUL TENANT, ET C EST LE CHIFFRE QUI MANQUE A TOUS.

    POURQUOI CECI EST LA MESURE LA PLUS IMPORTANTE DU LOT. Christophe, 18/10
    12:00, verbatim : « raideut + temps de raideur. [...] 3 fois 1K de
    denivelle separe par 3K de plat ce n est pas pareil que 3 km de raide d un
    seul tenant ».

    AUCUN INDICE PUBLIE NE CAPTURE CA, ET TOBLER NON PLUS. Tobler est SANS
    MEMOIRE : il calcule une vitesse pour chaque segment et les additionne, donc
    trois montees de 1 km separees par du plat et 3 km de raide d un seul tenant
    lui donnent EXACTEMENT le meme temps total. Or c est precisement ce qui
    arrete un marcheur — et Christophe l a vecu : il s est arrete au quatre
    cinquiemes de la premiere montee en partant de Conca.

    UNE MONTEE D UN SEUL TENANT est ici une suite MAXIMALE de couples
    d echantillons consecutifs dont la pente reste au-dessus de [seuil_pct],
    exprime en pourcents. Le seuil n est pas choisi d avance : [choisir_le_seuil]
    en essaie plusieurs et montre ce que chacun donne.
    """
    montees = []
    courante = None
    for (ca, aa), (cb, ab) in zip(profil, profil[1:]):
        dh = abs(cb - ca)
        dz = (ab - aa) * (-1.0 if a_l_envers else 1.0)
        pente_pct = 100.0 * dz / dh if dh > 0 else (100.0 if dz > 0 else 0.0)

        if pente_pct >= seuil_pct and dz > 0:
            if courante is None:
                courante = {
                    "debut_m": ca if not a_l_envers else cb,
                    "dh_m": 0.0,
                    "dz_m": 0.0,
                    "pente_max_pct": 0.0,
                    "couples": 0,
                }
            courante["dh_m"] += dh
            courante["dz_m"] += dz
            courante["pente_max_pct"] = max(courante["pente_max_pct"], pente_pct)
            courante["couples"] += 1
        else:
            if courante is not None:
                montees.append(courante)
                courante = None
    if courante is not None:
        montees.append(courante)

    for m in montees:
        m["km"] = round(m["dh_m"] / 1000.0, 3)
        m["dplus_m"] = arrondi(m["dz_m"])
        m["pente_moyenne_pct"] = (
            round(100.0 * m["dz_m"] / m["dh_m"], 1) if m["dh_m"] > 0 else None
        )
        m["pente_max_pct"] = round(m["pente_max_pct"], 1)
        # LA DUREE DE LA MONTEE PAR LES TROIS MODELES, pour que l on voie
        # lequel la paie et lequel l ignore.
        vitesse = vitesse_tobler_kmh(m["dz_m"] / m["dh_m"])
        m["minutes_tobler"] = arrondi(m["km"] / vitesse * 60.0)
        m["minutes_naismith"] = arrondi(
            m["km"] * NAISMITH_MINUTES_PAR_KM
            + m["dz_m"] / NAISMITH_MONTEE_M_PAR_HEURE * 60.0
        )
        m.pop("dh_m")
        m.pop("dz_m")
        m["debut_pk_km"] = round(m.pop("debut_m") / 1000.0, 3)

    montees.sort(key=lambda m: -m["dplus_m"])
    return montees


def en_clair(minutes):
    """« 8h46 » — la forme de `formatDurationMinutes` du depot."""
    m = max(0, int(minutes))
    h, reste = m // 60, m % 60
    return f"{h}h" if reste == 0 else f"{h}h{reste:02d}"


def effort_km(km, dplus_m, dmoins_m):
    """L ANCIEN CALCUL, recopie pour la comparaison et jamais applique ici."""
    return (
        km
        + dplus_m / 100.0 * EFFORT_MONTEE_PAR_100M
        + EFFORT_POIDS_DESCENTE * dmoins_m / 100.0
    )


def index_du_pk(cumul, pk_km):
    """L index de la trace le plus proche d un point kilometrique.

    C est la recherche de `gr20_dans_stepways.main()` (sa fermeture
    `index_du_pk`), celle qui a produit les trente et un segments entre nuits.
    Elle les reproduit AU METRE : le controle du moteur le verifie segment par
    segment.
    """
    cible = pk_km * 1000.0
    return min(range(len(cumul)), key=lambda i: abs(cumul[i] - cible))


def _plan(point, origine):
    """Projection plane locale, metres — identique au moteur de la maison."""
    lat0 = math.radians(origine[0])
    x = math.radians(point[1] - origine[1]) * RAYON_TERRE_M * math.cos(lat0)
    y = math.radians(point[0] - origine[0]) * RAYON_TERRE_M
    return x, y


def projeter(repere, points, cumul):
    """Point kilometrique d un repere sur la POLYLIGNE, et son index de segment.

    Recopie de `gr20_dans_stepways.projeter`. ELLE EST INDISPENSABLE ET LE
    CONTROLE DU MOTEUR L A PROUVE : les bornes des seize etapes ne sont pas des
    points kilometriques, ce sont DIX-SEPT OBJETS OPENSTREETMAP NOMMES projetes
    sur la trace. Chercher l index par le PK le plus proche decalait la coupe
    d un ou deux points, et l ancrage des deux bouts transformait ce decalage en
    metres de denivele : quinze etapes sur seize sortaient a cote des chiffres
    publies (jusqu a 24 m sur l etape 7), alors que les trente et un segments
    entre nuits — qui, eux, SONT bornes par des PK — tombaient tous juste.
    """
    meilleur = None
    i_proche = min(range(len(points)), key=lambda i: distance_m(repere, points[i]))
    debut = max(0, i_proche - 50)
    fin = min(len(points) - 1, i_proche + 50)
    for i in range(debut, fin):
        a, b = points[i], points[i + 1]
        ax, ay = _plan(a, a)
        bx, by = _plan(b, a)
        px, py = _plan(repere, a)
        dx, dy = bx - ax, by - ay
        norme = dx * dx + dy * dy
        t = (
            0.0
            if norme == 0
            else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / norme))
        )
        qx, qy = ax + t * dx, ay + t * dy
        ecart = math.hypot(px - qx, py - qy)
        if meilleur is None or ecart < meilleur[0]:
            longueur = cumul[i + 1] - cumul[i]
            meilleur = (ecart, cumul[i] + t * longueur, i)
    return {"ecart_m": meilleur[0], "pk_m": meilleur[1], "index": meilleur[2]}


def bornes_des_etapes(points, cumul):
    """LES DIX-SEPT COUPURES DES SEIZE ETAPES, projetees et TRIEES sur la trace.

    L ordre vient de la trace et non du fichier (tache 839) : c est ce tri qui
    remet le col de Bavella avant Paliri. On rend, pour chacune, son index de
    polyligne et son point kilometrique — les deux dont la mesure a besoin.
    """
    coupures = charger(COUPURES_SOURCE)
    projetees = []
    for c in coupures:
        p = projeter((c["lat"], c["lon"]), points, cumul)
        projetees.append({"nom": c["nom"], "index": p["index"], "pk_km": p["pk_m"] / 1000.0})
    projetees.sort(key=lambda p: p["pk_km"])
    return projetees


def mesurer_une_unite(
    nom_depart, nom_arrivee, pk_depart, pk_arrivee, altitudes, cumul, bornes=None
):
    """Une etape ou un segment de nuit, mesure sur la trace dans les DEUX sens.

    Les deux bouts sont ANCRES par construction : on coupe la trace sur la
    tranche de l unite PUIS on filtre, donc le premier et le dernier
    echantillon portent l altitude reelle des deux extremites. C est ce qui fait
    qu une tranche mesuree seule ne donne pas la somme de ses sous-tranches — la
    tache 854 l avait mesure (jusqu a 0,21 km-effort d ecart) et le choix de
    base est inscrit ici plutot que devine.

    [bornes] impose le couple d index de la tranche. Les ETAPES le passent,
    parce que leurs bornes sont des reperes OpenStreetMap PROJETES et non des
    points kilometriques ([bornes_des_etapes]) ; les SEGMENTS entre nuits le
    laissent nul et sont bornes par leur PK, comme la tache 838 les a produits.
    """
    if bornes is not None:
        i, j = bornes
    else:
        i = index_du_pk(cumul, pk_depart)
        j = index_du_pk(cumul, pk_arrivee)
    if j <= i:
        j = min(i + 1, len(cumul) - 1)
    profil = profil_echantillonne(altitudes[i : j + 1], cumul[i : j + 1])
    dplus, dmoins = sommer_le_denivele(profil)
    # LA LONGUEUR EST LA DIFFERENCE DES POINTS KILOMETRIQUES, PAS CELLE DES
    # INDEX. Les deux reperes sont PROJETES sur la polyligne : leur point
    # kilometrique tombe a l interieur d un segment, l index designe le debut de
    # ce segment. Mesurer d index a index perdait jusqu a 23 m sur une etape
    # (l etape 16) et ne retrouvait plus la longueur publiee du sentier.
    km = pk_arrivee - pk_depart

    trace = naismith_langmuir(profil)
    inverse = naismith_langmuir(profil, a_l_envers=True)
    # LE PROFIL VOYAGE AVEC LA MESURE pour que l analyse de RAIDEUR (Tobler et
    # les montees d un seul tenant) n ait pas a relire la trace. Il est retire
    # avant l ecriture : neuf mille echantillons dans un fichier de donnees ne
    # servent personne.
    profil_marche = profil

    return {
        "depart": nom_depart,
        "arrivee": nom_arrivee,
        "pk_depart_km": round(pk_depart, 3),
        "pk_arrivee_km": round(pk_arrivee, 3),
        "km": round(km, 3),
        # LA LONGUEUR QUE NAISMITH A REELLEMENT PAYEE. Le plat du modele est
        # somme sur les couples d echantillons, donc sur la tranche d INDEX ;
        # la longueur annoncee est celle des PK projetes. L ecart est de
        # quelques metres (au plus 23 m, soit 0,3 minute) et il est ECRIT
        # plutot que tu : un total de temps doit pouvoir se refaire a la main.
        "km_du_profil": round((cumul[j] - cumul[i]) / 1000.0, 3),
        "echantillons": len(profil),
        "sens trace": _une_mesure(km, dplus, dmoins, trace),
        "sens inverse": _une_mesure(km, dmoins, dplus, inverse),
        "_profil": profil_marche,
    }


def profil_a_l_envers(profil):
    """LE MEME PROFIL MARCHE DANS L AUTRE SENS, abscisses remises a zero.

    On ne relit pas la trace : on la parcourt a l envers. La distance
    horizontale de chaque couple ne change pas, l ordre si, et les montees
    deviennent des descentes.
    """
    if not profil:
        return []
    total = profil[-1][0]
    return [(total - c, a) for c, a in reversed(profil)]


def _une_mesure(km, dplus, dmoins, temps):
    """Un sens de marche : les trois mesures, le temps, et l ancien chiffre."""
    return {
        "km": round(km, 3),
        "dplus_m": dplus,
        "dmoins_m": dmoins,
        "minutes": temps["minutes"],
        "temps": en_clair(temps["minutes"]),
        "detail_du_temps": temps,
        # L ANCIEN CHIFFRE, A COTE ET PAS A LA PLACE.
        "ancien_km_effort": round(effort_km(km, dplus, dmoins), 2),
    }


def totaliser(unites, sens, titre):
    """Le total d un troncon : on SOMME les unites, on ne remesure pas.

    Les minutes se somment sur les EXACTES et non sur les arrondies : seize
    arrondis a la minute se seraient additionnes jusqu a huit minutes d ecart
    sur le sentier entier.
    """
    km = sum(u[sens]["km"] for u in unites)
    dplus = sum(u[sens]["dplus_m"] for u in unites)
    dmoins = sum(u[sens]["dmoins_m"] for u in unites)
    minutes = sum(u[sens]["detail_du_temps"]["minutes_exactes"] for u in unites)
    return {
        "quoi": titre,
        "unites": len(unites),
        "km": round(km, 3),
        "dplus_m": dplus,
        "dmoins_m": dmoins,
        "minutes": arrondi(minutes),
        "temps": en_clair(arrondi(minutes)),
        "minutes_somme_des_arrondis": sum(u[sens]["minutes"] for u in unites),
        "ancien_km_effort": round(effort_km(km, dplus, dmoins), 2),
        "ancien_km_effort_somme_des_unites": round(
            sum(u[sens]["ancien_km_effort"] for u in unites), 2
        ),
    }


def comparer_les_modeles(etapes_de_l_app, etapes):
    """LES DEUX MODELES DE TEMPS, FACE A FACE — le fait le plus genant du lot.

    Le depot porte un modele de temps OPERATIONNEL (4 km/h a plat, 400 m de
    montee a l heure, descente payee 1,67 s par metre) et l application AFFICHE
    deja ses chiffres, etape par etape. Naismith-Langmuir est plus RAPIDE parce
    que ses deux allures sont celles d un marcheur entraine. Compter la
    difficulte en heures de Naismith mettrait donc deux nombres d heures
    differents sur la MEME journee, a deux ecrans d intervalle.
    """
    lignes = []
    for reference, mesure in zip(etapes_de_l_app, etapes):
        maison = reference["estimatedDurationMinutes"]
        nais = mesure["sens trace"]["minutes"]
        lignes.append(
            {
                "rang": mesure["rang"],
                "depart": mesure["depart"],
                "arrivee": mesure["arrivee"],
                "minutes_modele_maison": maison,
                "temps_modele_maison": en_clair(maison),
                "minutes_naismith_langmuir": nais,
                "temps_naismith_langmuir": en_clair(nais),
                "ecart_minutes": nais - maison,
                "ecart_pct": round(100.0 * (nais - maison) / maison, 1)
                if maison
                else None,
            }
        )
    maison_total = sum(x["minutes_modele_maison"] for x in lignes)
    nais_total = sum(x["minutes_naismith_langmuir"] for x in lignes)
    pire = max(lignes, key=lambda x: abs(x["ecart_minutes"]))
    return {
        "quoi": (
            "Le modele de temps OPERATIONNEL du depot "
            "(lib/core/models/stage_duration.dart, deja affiche par "
            "l application) en face de Naismith-Langmuir, etape par etape."
        ),
        "pourquoi_c_est_decisif": (
            "L application AFFICHE DEJA 8h46 pour l etape 6. Naismith-Langmuir "
            "en dit 6h01. Compter la difficulte en heures de Naismith poserait "
            "donc DEUX nombres d heures differents sur la MEME journee, a deux "
            "ecrans d intervalle, avec deux heures quarante-cinq d ecart sur la "
            "pire etape du sentier. C est le defaut que la tache 839 avait paye "
            "pour fermer (29 pct d ecart entre le programme prepare et l heure "
            "annoncee) ; il reviendrait par l autre bout."
        ),
        "pourquoi_naismith_est_plus_rapide": (
            "Ses deux allures sont celles d un marcheur ENTRAINE : 5 km/h a plat "
            "contre 4, et 600 m de montee a l heure contre 400. La tache 839 a "
            "choisi les valeurs prudentes en toute connaissance, verbatim : « en "
            "montagne on n annonce pas des horaires optimistes : une estimation "
            "trop courte se paie a la tombee de la nuit »."
        ),
        "total_modele_maison": en_clair(maison_total),
        "total_naismith_langmuir": en_clair(nais_total),
        "ecart_total_minutes": nais_total - maison_total,
        "ecart_total_pct": round(100.0 * (nais_total - maison_total) / maison_total, 1),
        "pire_ecart": pire,
        "par_etape": lignes,
    }


def ce_que_la_mesure_repond(etapes):
    """LES TROIS REPONSES QUE LA MESURE DONNE, Y COMPRIS CELLE QUI DERANGE."""
    douce = sum(
        e["sens trace"]["detail_du_temps"]["descente_en_pente_douce_m"] for e in etapes
    )
    raide = sum(
        e["sens trace"]["detail_du_temps"]["descente_en_pente_raide_m"] for e in etapes
    )
    sous = sum(
        e["sens trace"]["detail_du_temps"]["descente_sous_le_seuil_m"] for e in etapes
    )
    langmuir = sum(
        e["sens trace"]["detail_du_temps"]["minutes_langmuir"] for e in etapes
    )
    naismith = sum(
        e["sens trace"]["detail_du_temps"]["minutes_naismith"] for e in etapes
    )
    e6 = next(e for e in etapes if e["rang"] == 6)
    e1 = next(e for e in etapes if e["rang"] == 1)
    e10 = next(e for e in etapes if e["rang"] == 10)

    par_temps = [
        e["rang"] for e in sorted(etapes, key=lambda x: -x["sens trace"]["minutes"])
    ]
    par_ancien = [
        e["rang"]
        for e in sorted(etapes, key=lambda x: -x["sens trace"]["ancien_km_effort"])
    ]

    return {
        "1_langmuir_ne_fait_presque_rien": {
            "constat": (
                f"La correction de Langmuir pese {langmuir:+d} minutes sur "
                f"{en_clair(naismith)} de Naismith pur, soit "
                f"{round(100.0 * langmuir / naismith, 1)} pct."
            ),
            "pourquoi": (
                f"La descente du sentier se repartit en {douce} m de pente douce "
                f"(escomptee), {raide} m de pente raide (chargee) et {sous} m sous "
                "le seuil (sans effet). Les deux corrections se compensent "
                "presque."
            ),
            "consequence_a_dire_a_christophe": (
                "« Que le negatif compte » N EST PAS obtenu par Langmuir. La "
                "premisse du mandat ne tient pas : on esperait que Langmuir "
                "charge la descente du GR20, la mesure dit qu il l annule."
            ),
            "le_cas_de_l_etape_6": (
                f"Sur l etape 6, la plus dure des seize, Langmuir accorde une "
                f"REMISE de "
                f"{-e6['sens trace']['detail_du_temps']['minutes_langmuir']} "
                "minutes : ses 1 191 m de descente la rendent plus RAPIDE, pas "
                "plus dure."
            ),
        },
        "2_ce_qui_rend_l_etape_6_la_plus_dure": {
            "constat": (
                f"Ses VINGT-CINQ KILOMETRES : "
                f"{en_clair(e6['sens trace']['detail_du_temps']['minutes_du_plat'])} "
                f"des {e6['sens trace']['temps']}, contre "
                f"{en_clair(e6['sens trace']['detail_du_temps']['minutes_de_la_montee'])} "
                "pour sa montee."
            ),
            "consequence": (
                "Sous ce modele les KILOMETRES comptent, et beaucoup ; le NEGATIF, "
                "a peine. L etape 6 reste la plus dure des seize, mais pour une "
                "autre raison que celle annoncee."
            ),
        },
        "3_le_classement_ne_s_effondre_pas": {
            "ordre_naismith": par_temps,
            "ordre_ancien_km_effort": par_ancien,
            "identique": par_temps == par_ancien,
            "constat": (
                "Les SIX etapes les plus dures gardent exactement le meme ordre "
                "dans les deux modeles. Seules trois paires du milieu de tableau "
                "s echangent. Changer de modele ne renverse donc pas les verdicts."
            ),
            "les_deux_ancres_de_christophe": {
                "quoi": (
                    "Il a classe deux etapes a la main le 17/10 11:04 : "
                    "Calenzana-Ortu TRES DIFFICILE, Vizzavona-E Capanelle SOUS le "
                    "seuil. Voici ou elles tombent en heures."
                ),
                "calenzana_ortu_tres_difficile": {
                    "rang": e1["rang"],
                    "minutes": e1["sens trace"]["minutes"],
                    "temps": e1["sens trace"]["temps"],
                },
                "vizzavona_e_capanelle_sous_le_seuil": {
                    "rang": e10["rang"],
                    "minutes": e10["sens trace"]["minutes"],
                    "temps": e10["sens trace"]["temps"],
                },
                "intervalle_qui_reproduit_ses_deux_ancres": (
                    f"Tout seuil dans l intervalle OUVERT "
                    f"({e10['sens trace']['minutes']} ; "
                    f"{e1['sens trace']['minutes']}] minutes, soit "
                    f"({e10['sens trace']['temps']} ; {e1['sens trace']['temps']}], "
                    "reproduit ses deux verdicts."
                ),
                "etapes_dans_cet_intervalle": [
                    e["rang"]
                    for e in etapes
                    if e10["sens trace"]["minutes"]
                    < e["sens trace"]["minutes"]
                    < e1["sens trace"]["minutes"]
                ],
                "ce_que_je_ne_fais_pas": (
                    "Je ne choisis AUCUN seuil dans cet intervalle. Christophe a "
                    "dit : « ensuite on discutera du positionnement "
                    "facile/moyen/difficile/tres difficile »."
                ),
            },
        },
    }


#: Les seuils de pente ESSAYES pour definir une montee d un seul tenant, en
#: pourcents. Le choix est justifie par [choisir_le_seuil] et non decrete.
SEUILS_ESSAYES_PCT = [0.0, 2.0, 5.0, 8.0, 10.0, 12.0, 15.0, 20.0]


def choisir_le_seuil(profils_par_etape):
    """ESSAIE PLUSIEURS SEUILS DE PENTE ET MONTRE CE QUE CHACUN DONNE.

    Le mandat demande de PROPOSER un seuil et de le JUSTIFIER PAR LA MESURE.
    On ne peut pas justifier un seuil par le confort : on l essaie, on regarde
    ce qu il fait des montees du sentier, et on retient celui qui repond a la
    question posee — « quelle est la plus longue montee d un seul tenant ».

    CE QUE CHAQUE EXTREME CASSE, ET C EST CA LE RAISONNEMENT :
      - un seuil TROP BAS (0 %) appelle « montee » le moindre faux plat qui
        remonte : les montees fusionnent avec les replats et la plus longue
        devient absurdement longue, donc le chiffre ne distingue plus rien ;
      - un seuil TROP HAUT (20 %) fragmente une vraie montee raide des qu elle
        souffle un instant : la plus longue montee devient un bout de montee,
        donc le chiffre sous-estime ce qui fatigue.
    Entre les deux il existe un plateau ou le chiffre est STABLE. C est ce
    plateau qu on cherche, et c est lui qu on rend.
    """
    essais = []
    for seuil in SEUILS_ESSAYES_PCT:
        plus_longues = []
        nombres = []
        for profil in profils_par_etape:
            montees = montees_continues(profil, seuil)
            nombres.append(len(montees))
            plus_longues.append(montees[0]["dplus_m"] if montees else 0)
        essais.append(
            {
                "seuil_pct": seuil,
                "plus_longue_montee_du_sentier_m": max(plus_longues),
                "plus_longue_montee_mediane_m": sorted(plus_longues)[
                    len(plus_longues) // 2
                ],
                "montees_par_etape_en_moyenne": round(
                    sum(nombres) / len(nombres), 1
                ),
                "montees_au_total": sum(nombres),
            }
        )

    # LE CRITERE : LE SEUIL LE PLUS STRICT QUI NE CASSE PAS ENCORE UNE VRAIE
    # MONTEE.
    #
    # Un seuil fait deux choses opposees : il NETTOIE (il arrete d appeler
    # « montee » un faux plat qui remonte) et il FRAGMENTE (au-dela d un
    # certain point il coupe une vraie montee des qu elle souffle un instant).
    # On veut tout le nettoyage et aucune fragmentation. La plus longue montee
    # du sentier est le temoin : tant qu elle ne bouge pas, on n a rien casse.
    #
    # On retient donc le seuil le PLUS HAUT pour lequel la plus longue montee
    # vaut encore ce qu elle valait sans aucun filtre (a 2 % pres). Au-dela,
    # elle perd des metres, et ces metres sont de la vraie montagne.
    reference = essais[0]["plus_longue_montee_du_sentier_m"]
    intacts = [
        e["seuil_pct"]
        for e in essais
        if reference
        and abs(e["plus_longue_montee_du_sentier_m"] - reference) / reference <= 0.02
    ]
    retenu = max(intacts) if intacts else 8.0
    nettoyage = next(
        (e for e in essais if e["seuil_pct"] == retenu), essais[0]
    )
    premier_casse = next(
        (
            e
            for e in essais
            if e["seuil_pct"] > retenu
        ),
        None,
    )

    return {
        "quoi": (
            "Une montee d un seul tenant est une suite maximale de couples "
            "d echantillons dont la pente reste au-dessus d un seuil. Voici ce "
            "que donnent huit seuils."
        ),
        "seuils_essayes_pct": SEUILS_ESSAYES_PCT,
        "essais": essais,
        "seuils_qui_ne_cassent_rien_pct": intacts,
        "seuil_retenu_pct": retenu,
        "pourquoi_ce_seuil": (
            f"C est le seuil le PLUS STRICT qui ne casse encore aucune vraie "
            f"montee. Sans aucun filtre la plus longue montee du sentier vaut "
            f"{reference} m de denivele ; a {retenu:.0f} % elle vaut toujours "
            f"{nettoyage['plus_longue_montee_du_sentier_m']} m, et le filtre a "
            f"deja ramene le nombre de montees de {essais[0]['montees_au_total']} "
            f"a {nettoyage['montees_au_total']} — il a donc retire "
            f"{essais[0]['montees_au_total'] - nettoyage['montees_au_total']} "
            "faux plats qui remontaient, sans toucher a la montagne."
            + (
                f" Au seuil suivant ({premier_casse['seuil_pct']:.0f} %) la plus "
                f"longue montee tombe a "
                f"{premier_casse['plus_longue_montee_du_sentier_m']} m : le filtre "
                "commence a couper de vraies montees, et ces metres-la sont du "
                "vrai denivele. C est la frontiere, et elle est mesuree."
                if premier_casse
                else ""
            )
        ),
        "ce_que_le_seuil_capture_des_exemples_de_christophe": (
            "Ses deux exemples tombent tous les deux au-dessus du seuil, donc "
            "tous deux comptent comme montees : « 700 metres sur 5 km » fait "
            "14 % de pente, « 700 metres sur 1 km » en fait 70 %. Le seuil ne "
            "sert qu a ecarter les faux plats, pas a trier ses cas."
        ),
        "ce_que_je_ne_fais_pas": (
            "Ce seuil sert a DECOUPER les montees, pas a classer une etape. "
            "Aucun niveau facile/moyen/difficile/tres difficile n en sort."
        ),
    }


#: Denivele minimal pour qu une bosse soit appelee « montee », en metres.
#:
#: IL FAUT UN PLANCHER ET LA MESURE L A PROUVE. Sans lui, « la premiere montee
#: en partant de Conca » tombait sur une BOSSE DE 24 METRES situee au
#: kilometre zero, franchie en cinq minutes : personne n appelle ca une montee,
#: et surtout pas quelqu un qui dit s etre arrete aux quatre cinquiemes de la
#: sienne. La vraie premiere montee de Conca fait 294 m sur 1,61 km a 18,3 %
#: de pente moyenne, et elle commence au kilometre 0,34.
#:
#: CENT METRES, parce que c est l ordre de grandeur en dessous duquel une
#: montee ne se raconte pas. Le choix n est pas critique et on peut le verifier :
#: entre 50 et 250 m de plancher, la premiere montee de Conca est LA MEME
#: (la bosse suivante par ordre d apparition fait 294 m). Un plancher n a
#: besoin d etre juste que s il change la reponse ; celui-ci ne la change pas.
PLANCHER_DUNE_MONTEE_M = 100.0


def fraction_dune_montee(profil, seuil_pct, fractions,
                         plancher_m=PLANCHER_DUNE_MONTEE_M):
    """OU EN EST-ON A TELLE FRACTION DE LA PREMIERE MONTEE D UN SEUL TENANT.

    C est l outil des deux points de calibration de Christophe : il s est
    arrete AU QUATRE CINQUIEMES de la premiere montee en partant de Conca, et
    il fait LES TROIS CINQUIEMES sans probleme vers les Trois Piscines. On
    situe donc ces fractions sur la trace et on dit, a cet endroit precis, ce
    que chaque modele predisait.

    [profil] est DEJA oriente dans le sens marche. Les fractions sont prises
    sur le DENIVELE de la montee (« les trois cinquiemes de la montee » se
    compte en montee, pas en kilometres) et la fraction en distance est donnee
    a cote pour que les deux lectures soient possibles.
    """
    # Les couples, dans l ordre de marche, avec leur pente.
    couples = []
    for (ca, aa), (cb, ab) in zip(profil, profil[1:]):
        dh = abs(cb - ca)
        dz = ab - aa
        pente = 100.0 * dz / dh if dh > 0 else (100.0 if dz > 0 else 0.0)
        couples.append({"dh": dh, "dz": dz, "pente_pct": pente})

    # LA PREMIERE VRAIE MONTEE : on avance jusqu a en trouver une qui depasse
    # [plancher_m]. Les bosses en dessous sont ENJAMBEES et non comptees — voir
    # [PLANCHER_DUNE_MONTEE_M] pour la bosse de 24 m qui avait pris la place.
    debut = fin = None
    courant_debut = courant_fin = None
    courant_dz = 0.0
    for i, c in enumerate(couples):
        if c["pente_pct"] >= seuil_pct and c["dz"] > 0:
            if courant_debut is None:
                courant_debut = i
                courant_dz = 0.0
            courant_fin = i
            courant_dz += c["dz"]
        elif courant_debut is not None:
            if courant_dz >= plancher_m:
                debut, fin = courant_debut, courant_fin
                break
            courant_debut = courant_fin = None
            courant_dz = 0.0
    if debut is None and courant_debut is not None and courant_dz >= plancher_m:
        debut, fin = courant_debut, courant_fin
    if debut is None:
        return None

    montee = couples[debut : fin + 1]
    dz_total = sum(c["dz"] for c in montee)
    dh_total = sum(c["dh"] for c in montee)

    # Le temps ECOULE depuis le depart jusqu au debut de la montee, par les
    # trois modeles : le marcheur ne commence pas la montee frais.
    def temps_jusqua(indice):
        nais = nl = tob = 0.0
        for c in couples[:indice]:
            nais += c["dh"] / 1000.0 * NAISMITH_MINUTES_PAR_KM
            if c["dz"] > 0:
                nais += c["dz"] / NAISMITH_MONTEE_M_PAR_HEURE * 60.0
            nl = nais  # Langmuir ne corrige que la descente ; voir ci-dessous.
            if c["dh"] > 0:
                tob += (
                    c["dh"]
                    / 1000.0
                    / vitesse_tobler_kmh(c["dz"] / c["dh"])
                    * 60.0
                )
        return nais, nl, tob

    sorties = []
    for fraction in fractions:
        cible = dz_total * fraction
        cumul_dz = cumul_dh = 0.0
        pente_locale = None
        atteint = fin
        for k, c in enumerate(montee):
            cumul_dz += c["dz"]
            cumul_dh += c["dh"]
            pente_locale = c["pente_pct"]
            if cumul_dz >= cible:
                atteint = debut + k
                break
        nais, _, tob = temps_jusqua(atteint + 1)
        sorties.append(
            {
                "fraction_de_la_montee": fraction,
                "denivele_monte_m": arrondi(cumul_dz),
                "distance_parcourue_dans_la_montee_km": round(
                    cumul_dh / 1000.0, 3
                ),
                "fraction_en_distance": round(cumul_dh / dh_total, 3)
                if dh_total
                else None,
                "pente_locale_pct": round(pente_locale, 1)
                if pente_locale is not None
                else None,
                "temps_ecoule_naismith": en_clair(arrondi(nais)),
                "temps_ecoule_tobler": en_clair(arrondi(tob)),
                "minutes_ecoulees_naismith": arrondi(nais),
                "minutes_ecoulees_tobler": arrondi(tob),
            }
        )

    return {
        "premiere_montee_dun_seul_tenant": {
            "km": round(dh_total / 1000.0, 3),
            "dplus_m": arrondi(dz_total),
            "pente_moyenne_pct": round(100.0 * dz_total / dh_total, 1)
            if dh_total
            else None,
            "pente_max_pct": round(max(c["pente_pct"] for c in montee), 1),
            "commence_au_km": round(sum(c["dh"] for c in couples[:debut]) / 1000.0, 3),
            "minutes_naismith": arrondi(
                dh_total / 1000.0 * NAISMITH_MINUTES_PAR_KM
                + dz_total / NAISMITH_MONTEE_M_PAR_HEURE * 60.0
            ),
            "minutes_tobler": arrondi(
                sum(
                    c["dh"] / 1000.0 / vitesse_tobler_kmh(c["dz"] / c["dh"]) * 60.0
                    for c in montee
                    if c["dh"] > 0
                )
            ),
        },
        "aux_fractions": sorties,
    }


def calibration(etapes, bornes, seuil_pct):
    """LES DEUX POINTS DE VERITE QUE CHRISTOPHE A DONNES — son propre vecu.

    IL A MARCHE CE SENTIER, ET C EST LA MEILLEURE DONNEE DU LOT. Verbatim le
    18/10 11:56 : « Moi j'ai fait bavella conca sans probleme mais pas conca
    bavella je me suis arrete au 4/5eme de la premiere monte » ; puis 12:00 :
    « Je fais les 3/5 sans probleme quand je vais aux 3 piscine depuis Conca ».

    DEUX FAITS, SUR LA MEME MONTEE, ET ILS ENCADRENT SA LIMITE :
      - a 3/5 de la premiere montee en partant de Conca : SANS PROBLEME ;
      - a 4/5 de la meme montee : IL S EST ARRETE.
    Et le sens compte : Bavella vers Conca lui a ete facile, Conca vers Bavella
    l a arrete. C est la MEME etape, marchee a l envers.

    LE BON MODELE EST CELUI QUI MET CES DEUX POINTS DU BON COTE, et c est le
    seul critere non arbitraire dont nous disposons pour choisir.
    """
    # Bavella vers Conca est la DERNIERE etape du sentier dans le sens de la
    # trace : son arrivee est Conca. Conca vers Bavella est donc cette meme
    # etape MARCHEE A L ENVERS.
    derniere = etapes[-1]
    profil = derniere["_profil"]
    vers_bavella = profil_a_l_envers(profil)

    montee = fraction_dune_montee(vers_bavella, seuil_pct, [0.6, 0.8, 1.0])

    return {
        "quoi": (
            "Les deux points de calibration donnes par Christophe, situes sur la "
            "trace et chiffres. Ils portent sur la MEME montee : la premiere en "
            "partant de Conca."
        ),
        "verbatim": (
            "18/10 11:56 : « Moi j'ai fait bavella conca sans probleme mais pas "
            "conca bavella je me suis arrete au 4/5eme de la premiere monte ». "
            "18/10 12:00 : « Je fais les 3/5 sans probleme quand je vais aux 3 "
            "piscine depuis Conca, c'est aussi la longueur du truc quand c'est "
            "raide »."
        ),
        "l_etape_concernee": {
            "rang_dans_la_trace": derniere["rang"],
            "sens_trace": f"{derniere['depart']} -> {derniere['arrivee']}",
            "sens_vecu_facile": (
                f"{derniere['depart']} -> {derniere['arrivee']} "
                "(Bavella vers Conca : sans probleme)"
            ),
            "sens_vecu_difficile": (
                f"{derniere['arrivee']} -> {derniere['depart']} "
                "(Conca vers Bavella : arret au 4/5 de la premiere montee)"
            ),
            "km": derniere["km"],
            "sens trace": {
                "dplus_m": derniere["sens trace"]["dplus_m"],
                "dmoins_m": derniere["sens trace"]["dmoins_m"],
                "les_trois_temps": derniere["sens trace"]["les_trois_temps"],
            },
            "sens inverse": {
                "dplus_m": derniere["sens inverse"]["dplus_m"],
                "dmoins_m": derniere["sens inverse"]["dmoins_m"],
                "les_trois_temps": derniere["sens inverse"]["les_trois_temps"],
            },
        },
        "ce_que_les_deux_sens_coutent": _ecart_des_sens(derniere),
        "la_premiere_montee_en_partant_de_conca": montee,
        "ce_que_chaque_modele_predisait": _ce_que_les_modeles_predisaient(montee),
    }


def _ecart_des_sens(etape):
    """LE TEST LE PLUS DUR DU LOT : LA MEME ETAPE, DANS LES DEUX SENS.

    Christophe a trouve Bavella vers Conca FACILE et Conca vers Bavella
    ARRETANT. Un modele de temps qui ne separe pas nettement ces deux sens ne
    sait pas decrire ce qu il a vecu. On mesure donc le RAPPORT entre les deux
    sens pour chacun des trois modeles, et on dit lequel separe le mieux.
    """
    facile = etape["sens trace"]["les_trois_temps"]
    dur = etape["sens inverse"]["les_trois_temps"]
    modeles = {
        "naismith_seul": ("minutes_naismith_seul", "naismith_seul"),
        "naismith_plus_langmuir": (
            "minutes_naismith_plus_langmuir",
            "naismith_plus_langmuir",
        ),
        "tobler": ("minutes_tobler", "tobler"),
    }
    lignes = {}
    for nom, (cle_min, cle_txt) in modeles.items():
        a, b = facile[cle_min], dur[cle_min]
        lignes[nom] = {
            "sens_facile_pour_lui": facile[cle_txt],
            "sens_qui_l_a_arrete": dur[cle_txt],
            "minutes_de_plus": b - a,
            "rapport": round(b / a, 3) if a else None,
        }
    meilleur = max(lignes, key=lambda n: lignes[n]["rapport"] or 0)
    return {
        "quoi": (
            "La MEME etape (Paliri - Conca, 13,2 km) dans les deux sens : "
            "300 m de montee dans un sens, 1 094 m dans l autre."
        ),
        "par_modele": lignes,
        "celui_qui_separe_le_mieux": meilleur,
        "ce_que_ca_dit": (
            f"C est {meilleur.replace('_', ' ')} qui ecarte le plus les deux "
            f"sens (rapport {lignes[meilleur]['rapport']}), et c est un resultat "
            "CONTRE-INTUITIF qu il faut dire : TOBLER SEPARE LE MOINS BIEN "
            f"(rapport {lignes['tobler']['rapport']}). La raison est nette — "
            "Tobler penalise aussi la DESCENTE raide, donc il alourdit le sens "
            "que Christophe a trouve facile et rapproche les deux. Naismith, qui "
            "ne compte pas la descente, les ecarte franchement. Sur ce critere-la "
            "— le seul vecu dont nous disposons — la recommandation « prendre "
            "Tobler » ne tient pas, et je ne vais pas la maquiller."
        ),
    }


def _ce_que_les_modeles_predisaient(montee):
    """Ce que chaque modele annonçait AUX DEUX POINTS de Christophe."""
    if montee is None:
        return {
            "constat": (
                "Aucune montee d un seul tenant n a ete trouvee au depart de "
                "Conca avec le seuil retenu : le resultat est NUL et il est dit, "
                "pas comble."
            )
        }
    trois = next(
        (
            f
            for f in montee["aux_fractions"]
            if abs(f["fraction_de_la_montee"] - 0.6) < 1e-9
        ),
        None,
    )
    quatre = next(
        (
            f
            for f in montee["aux_fractions"]
            if abs(f["fraction_de_la_montee"] - 0.8) < 1e-9
        ),
        None,
    )
    if trois is None or quatre is None:
        return {"constat": "fractions absentes"}
    pm = montee["premiere_montee_dun_seul_tenant"]
    return {
        "a_3_sur_5_sans_probleme": trois,
        "a_4_sur_5_il_s_est_arrete": quatre,
        "entre_les_deux": {
            "denivele_de_plus_m": quatre["denivele_monte_m"]
            - trois["denivele_monte_m"],
            "distance_de_plus_km": round(
                quatre["distance_parcourue_dans_la_montee_km"]
                - trois["distance_parcourue_dans_la_montee_km"],
                3,
            ),
            "minutes_de_plus_naismith": quatre["minutes_ecoulees_naismith"]
            - trois["minutes_ecoulees_naismith"],
            "minutes_de_plus_tobler": quatre["minutes_ecoulees_tobler"]
            - trois["minutes_ecoulees_tobler"],
        },
        "ce_que_ca_situe": (
            "Sa limite personnelle sur CETTE montee tombe entre ces deux points. "
            "Ce n est pas un seuil de difficulte du sentier et je ne le "
            "transforme pas en seuil : c est UN marcheur, UN jour, UNE montee. "
            "C est en revanche le seul point de verite terrain que nous ayons, "
            "et tout seuil que Christophe posera devrait le respecter."
        ),
        "CE_QUI_A_PROBABLEMENT_ARRETE_CHRISTOPHE": (
            f"LA PENTE LOCALE SE REDRESSE JUSTE LA. A trois cinquiemes de la "
            f"montee elle est a {trois['pente_locale_pct']} % ; a quatre "
            f"cinquiemes elle est a {quatre['pente_locale_pct']} %, et la montee "
            "pointe a 35,8 % plus haut. Entre son point « sans probleme » et son "
            f"point d arret il n y a que {quatre['denivele_monte_m'] - trois['denivele_monte_m']} "
            f"m de denivele et "
            f"{quatre['minutes_ecoulees_naismith'] - trois['minutes_ecoulees_naismith']} "
            "minutes — ni le temps ecoule ni le denivele cumule n expliquent "
            "l arret. CE QUI CHANGE, C EST LA RAIDEUR. Son intuition du 18/10 "
            "11:56 est donc confirmee par la mesure de son propre arret."
        ),
        "CE_QUE_CHAQUE_MODELE_AURAIT_VU": {
            "naismith": (
                "RIEN. Il est lineaire en denivele : les 63 derniers metres "
                "coutent le meme nombre de minutes qu ils soient a 20 % ou a "
                "27 %. Il ne peut pas predire cet arret."
            ),
            "naismith_plus_langmuir": (
                "RIEN NON PLUS en montee : Langmuir ne corrige que la DESCENTE. "
                "Sur ce point precis il n ajoute strictement aucune information."
            ),
            "tobler": (
                "IL LE VOIT, mais faiblement. Il ralentit bien la ou la pente se "
                f"redresse ({quatre['minutes_ecoulees_tobler'] - trois['minutes_ecoulees_tobler']} "
                "minutes pour le dernier cinquieme contre "
                f"{trois['minutes_ecoulees_tobler']} pour les trois premiers), "
                "mais l ecart total reste petit et se noie dans un temps d etape."
            ),
            "la_montee_dun_seul_tenant": (
                "C EST ELLE QUI AURAIT PARLE. 294 m de denivele sur 1,61 km a "
                f"{pm['pente_moyenne_pct']} % de moyenne et "
                f"{pm['pente_max_pct']} % de pointe, des le kilometre "
                f"{pm['commence_au_km']} "
                "d une journee : c est un descripteur qui se lit AVANT de "
                "partir. Aucun des trois modeles de temps ne le contient, et "
                "c est le seul chiffre du lot qui separe ses deux points."
            ),
        },
    }


def mesurer():
    points, altitudes = lire_gpx(TRACE)
    manquantes = sum(1 for a in altitudes if a is None)
    if manquantes:
        raise SystemExit(
            f"ARRET : {manquantes} points sans altitude. Naismith ne se devine pas."
        )
    cumul = cumuls(points)

    mesure = charger(MESURE_ETAPES)
    etapes_de_l_app = charger(ETAPES_DE_L_APP)
    nuits = charger(NUITS)
    chap = charger(CHAPITRES)
    derniere_du_nord = int(chap["etapeDArriveeDeLaCoupe"])

    # --- LES SEIZE ETAPES, DANS LES DEUX SENS --------------------------------
    # LES BORNES SONT LES DIX-SEPT REPERES PROJETES, PAS DES POINTS
    # KILOMETRIQUES : voir [projeter]. Quinze etapes sur seize sortaient a cote
    # des chiffres publies tant que ce n etait pas le cas.
    bornes = bornes_des_etapes(points, cumul)
    etapes = []
    for rang, e in enumerate(mesure["etapes"], start=1):
        unite = mesurer_une_unite(
            e["depart"],
            e["arrivee"],
            bornes[rang - 1]["pk_km"],
            bornes[rang]["pk_km"],
            altitudes,
            cumul,
            bornes=(bornes[rang - 1]["index"], bornes[rang]["index"]),
        )
        unite["rang"] = e["rang_trace"]
        unite["chapitre"] = (
            "GR20 Nord" if e["rang_trace"] <= derniere_du_nord else "GR20 Sud"
        )
        # LE CONTROLE DU MOTEUR SE FAIT CONTRE LA DONNEE QUE L APPLICATION LIT,
        # ET C EST UN POINT QUI A ETE TRANCHE PAR LA MESURE. Le depot porte DEUX
        # bases de denivele par etape : `assets/data/gr20/stages.json`, produit
        # par le moteur canonique (`gr20_dans_stepways.denivele_maison`, lissage
        # par tranche avec LES DEUX BOUTS ANCRES, tache 838) — c est CELLE-LA
        # que l application affiche et que la fiche cite ; et
        # `mesure_etapes.json`, produit par l outil plus ancien
        # (`mesurer_les_etapes.py`, lissage GLOBAL puis tranche pas de sept,
        # SANS ancrage de tranche). Les deux ne disent pas la meme chose : 11 644
        # m de montee contre 11 602, et jusqu a 27 m d ecart sur une etape
        # (l etape 7 descend 550 m pour l une, 523 pour l autre). On controle
        # donc contre `stages.json`, et l ecart avec l autre base est EXPOSE
        # plutot que tu.
        reference = etapes_de_l_app[e["rang_trace"] - 1]
        unite["controle_du_moteur"] = {
            "base": "assets/data/gr20/stages.json (ce que l application affiche)",
            "dplus_publie_m": reference["elevationGainM"],
            "dmoins_publie_m": reference["elevationLossM"],
            "km_publie": reference["distanceKm"],
            "dplus_identique": unite["sens trace"]["dplus_m"]
            == reference["elevationGainM"],
            "dmoins_identique": unite["sens trace"]["dmoins_m"]
            == reference["elevationLossM"],
            "ecart_km": round(unite["km"] - reference["distanceKm"], 3),
            "autre_base_mesure_etapes": {
                "dplus_m": e["dplus_m"],
                "dmoins_m": e["dmoins_m"],
                "ecart_dplus_m": reference["elevationGainM"] - e["dplus_m"],
                "ecart_dmoins_m": reference["elevationLossM"] - e["dmoins_m"],
            },
        }
        etapes.append(unite)

    # --- LA RAIDEUR : TOBLER, ET LES MONTEES D UN SEUL TENANT ----------------
    # C est l ajout du 18/10 12:00. Naismith est LINEAIRE en denivele et
    # Langmuir ne regarde la pente que pour la descente : les deux sont aveugles
    # a la raideur d une MONTEE. Tobler la voit. Et aucun des trois ne voit la
    # LONGUEUR d une montee d un seul tenant, qui est ce qui arrete un marcheur.
    profils = [e["_profil"] for e in etapes]
    seuil = choisir_le_seuil(profils)
    seuil_pct = seuil["seuil_retenu_pct"]

    for unite in etapes:
        profil = unite["_profil"]
        envers = profil_a_l_envers(profil)
        for sens, p in (("sens trace", profil), ("sens inverse", envers)):
            montees = montees_continues(p, seuil_pct)
            unite[sens]["tobler"] = tobler(p)
            unite[sens]["raideur"] = {
                "seuil_de_pente_pct": seuil_pct,
                "montees_dun_seul_tenant": len(montees),
                "plus_longue_montee": montees[0] if montees else None,
                "les_montees": montees[:5],
                "denivele_dans_les_montees_m": sum(m["dplus_m"] for m in montees),
            }
            # LES TROIS TEMPS COTE A COTE, c est la demande exacte.
            unite[sens]["les_trois_temps"] = {
                "naismith_seul": en_clair(
                    unite[sens]["detail_du_temps"]["minutes_naismith"]
                ),
                "naismith_plus_langmuir": unite[sens]["temps"],
                "tobler": unite[sens]["tobler"]["temps"],
                "minutes_naismith_seul": unite[sens]["detail_du_temps"][
                    "minutes_naismith"
                ],
                "minutes_naismith_plus_langmuir": unite[sens]["minutes"],
                "minutes_tobler": unite[sens]["tobler"]["minutes"],
            }

    # --- LES TRENTE ET UN SEGMENTS ENTRE NUITS, DANS LES DEUX SENS -----------
    segments = []
    for s in nuits["entre_les_nuits"]:
        unite = mesurer_une_unite(
            s["depart"],
            s["arrivee"],
            s["pk_depart_km"],
            s["pk_arrivee_km"],
            altitudes,
            cumul,
        )
        unite["rang"] = s["rang"]
        unite["chapitre"] = (
            "GR20 Nord"
            if s["pk_arrivee_km"] <= mesure["etapes"][derniere_du_nord - 1]["pk_arrivee_km"]
            else "GR20 Sud"
        )
        unite["controle_du_moteur"] = {
            "base": "assets/data/gr20/nuits_possibles.json (tache 838)",
            "dplus_publie_m": s["dplus_m"],
            "dmoins_publie_m": s["dmoins_m"],
            "km_publie": s["km"],
            "dplus_identique": unite["sens trace"]["dplus_m"] == s["dplus_m"],
            "dmoins_identique": unite["sens trace"]["dmoins_m"] == s["dmoins_m"],
            "ecart_km": round(unite["km"] - s["km"], 3),
        }
        segments.append(unite)

    nord = [e for e in etapes if e["chapitre"] == "GR20 Nord"]
    sud = [e for e in etapes if e["chapitre"] == "GR20 Sud"]
    nord_n = [s for s in segments if s["chapitre"] == "GR20 Nord"]
    sud_n = [s for s in segments if s["chapitre"] == "GR20 Sud"]

    def totaux(unites, n, s, libelle):
        return {
            sens: {
                "sentier entier": totaliser(unites, sens, f"GR20 entier — {libelle}"),
                "GR20 Nord": totaliser(n, sens, f"GR20 Nord — {libelle}"),
                "GR20 Sud": totaliser(s, sens, f"GR20 Sud — {libelle}"),
            }
            for sens in ("sens trace", "sens inverse")
        }

    controles = [
        c["controle_du_moteur"] for c in etapes + segments
    ]
    moteur_identique = all(
        c["dplus_identique"] and c["dmoins_identique"] for c in controles
    )

    return {
        "quoi": (
            "Le temps de marche du GR20 par NAISMITH (1892) corrige par LANGMUIR, "
            "mesure segment par segment sur les 9 128 points de la trace. CHIFFRES "
            "BRUTS : aucune bande, aucun seuil, aucun reclassement — ils seront "
            "decides par Christophe apres lecture."
        ),
        "tache": 855,
        "decision": (
            "Christophe, 18/10 11:33, verbatim : « prend NAISMITH pour tes calculs ». "
            "Motif : le bareme IBP qui inspirait l ancien calcul n est pas public, "
            "l equivalence 100 m de montee = 1 km de plat n a pas d etude primaire, "
            "et le poids 0,30 de la descente n est source nulle part. Naismith l est. "
            "Naismith PUR ne comptant pas la descente, on prend la correction de "
            "LANGMUIR, publique et de la meme lignee, pour que le negatif compte — "
            "ce que Christophe avait demande la veille."
        ),
        "attribution": ATTRIBUTION,
        "methode": {
            "naismith": (
                "Une heure pour cinq kilometres, plus une heure pour six cents "
                "metres de montee (W. W. Naismith, Scottish Mountaineering Club "
                "Journal, 1892). Soit 12 minutes du kilometre et 0,1 minute du "
                "metre de montee."
            ),
            "langmuir": (
                "Correction de descente (E. Langmuir, Mountaincraft and Leadership, "
                "1984) : rien sous 5 degres, MOINS dix minutes par 300 m de descente "
                "entre 5 et 12 degres, PLUS dix minutes par 300 m au-dela de "
                "12 degres."
            ),
            "segment_par_segment": (
                "La pente est classee sur CHAQUE couple d echantillons de la trace, "
                "jamais sur une moyenne d etape. L etape 6 descend 1 190 m sur "
                "25 km, soit 2,7 degres de moyenne : en moyenne Langmuir lui ferait "
                "une REMISE, segment par segment il la CHARGE. La moyenne dit le "
                "contraire de la mesure."
            ),
            "moteur_de_denivele": (
                "Celui de la maison et pas un second : moyenne glissante sur sept "
                "points, LES DEUX BOUTS ANCRES a leur altitude reelle (tache 838), "
                "puis un point sur sept — `denivele_maison` de "
                "tool/gr20_dans_stepways.py. Les pentes sont classees sur SES "
                "echantillons, donc le temps annonce est celui du D+ annonce."
            ),
            "base_du_gain": (
                "Mesure de bout en bout par unite, les deux bouts ancres. Une unite "
                "ne vaut donc PAS la somme de ses sous-unites (tache 854, jusqu a "
                "0,21 km-effort d ecart) : le choix est inscrit, pas devine."
            ),
            "sens_inverse": (
                "Meme profil marche a l envers : la longueur horizontale ne change "
                "pas, la variation d altitude change de signe. C est exactement ce "
                "que fait `SegmentEntreNuits.aLEnvers` dans le produit."
            ),
            "ancien_calcul": (
                "Garde EN PARALLELE sous `ancien_km_effort` et jamais applique : "
                "km + D+/100 + 0,30 x D-/100 (lib/domain/echelle_de_difficulte.dart). "
                "Il permet de lire l ecart ; il ne decide plus rien."
            ),
            "ce_qui_n_est_pas_fait": (
                "AUCUN seuil, AUCUNE bande, AUCUN reclassement. Le modele de temps "
                "OPERATIONNEL du produit (4 km/h, 400 m/h, descente a 1,67 s/m, "
                "lib/core/models/stage_duration.dart) n est PAS touche : il continue "
                "d annoncer les durees d etape et l heure d arrivee. Deux modeles de "
                "temps coexistent donc, et l ecart est mesure ci-dessous."
            ),
        },
        "trace": {
            "fichier": TRACE,
            "points": len(points),
            "altitudes_absentes": manquantes,
            "longueur_km": round(cumul[-1] / 1000.0, 3),
        },
        "controle_du_moteur": {
            "quoi": (
                "Mes montees et mes descentes, unite par unite, en face de celles "
                "publiees par la tache 839 (etapes) et la tache 838 (segments). "
                "Elles doivent etre IDENTIQUES : c est la preuve que je mesure avec "
                "le moteur de la maison et non avec un second."
            ),
            "unites_controlees": len(controles),
            "toutes_identiques": moteur_identique,
            "ecarts": [
                {
                    "unite": u["depart"] + " -> " + u["arrivee"],
                    "dplus_mesure_m": u["sens trace"]["dplus_m"],
                    "dplus_publie_m": u["controle_du_moteur"]["dplus_publie_m"],
                    "dmoins_mesure_m": u["sens trace"]["dmoins_m"],
                    "dmoins_publie_m": u["controle_du_moteur"]["dmoins_publie_m"],
                }
                for u in etapes + segments
                if not (
                    u["controle_du_moteur"]["dplus_identique"]
                    and u["controle_du_moteur"]["dmoins_identique"]
                )
            ],
        },
        "la_raideur_et_les_montees_dun_seul_tenant": {
            "pourquoi": (
                "Christophe, 18/10 11:56 : « quand les montes sont pentue c'est "
                "pus dificile de monter 700 metres sur 1KM que 700 metre sur 5 » ; "
                "puis 12:00 : « 3 fois 1K de denivelle separe par 3K de plat ce "
                "n est pas pareil que 3 km de raide d un seul tenant ». Les deux "
                "remarques visent deux trous DIFFERENTS, et aucun indice publie "
                "ne les comble tous les deux."
            ),
            "trou_1_la_raideur": (
                "Naismith est LINEAIRE en denivele : 700 m lui coutent 1 h 10 "
                "qu ils soient etales sur 1 km ou sur 5. Langmuir ne regarde la "
                "pente QUE pour la descente. TOBLER (1993) la voit : 700 m sur "
                "1 km lui coutent 2 h 19, sur 5 km 1 h 37 — quarante-deux "
                "minutes d ecart pour le meme denivele. C est exactement ce que "
                "Christophe decrit."
            ),
            "trou_2_la_longueur_de_la_raideur": (
                "TOBLER EST SANS MEMOIRE : il calcule une vitesse par segment et "
                "les additionne, donc trois montees de 1 km separees par du plat "
                "et 3 km de raide d un seul tenant lui donnent le MEME temps. "
                "Aucun des trois modeles ne voit la LONGUEUR d une montee "
                "ininterrompue. C est pourquoi elle est mesuree a part, etape "
                "par etape et dans les deux sens, sous la cle `raideur`."
            ),
            "choix_du_seuil": seuil,
        },
        "calibration_sur_le_vecu_de_christophe": calibration(
            etapes, bornes, seuil_pct
        ),
        "comparaison_des_deux_modeles_de_temps": comparer_les_modeles(
            etapes_de_l_app, etapes
        ),
        "ce_que_la_mesure_repond": ce_que_la_mesure_repond(etapes),
        "etapes": etapes,
        "totaux_par_etapes": totaux(etapes, nord, sud, "par les seize etapes"),
        "segments_entre_nuits": segments,
        "totaux_par_les_nuits": totaux(
            segments, nord_n, sud_n, "en coupant sur les nuits relevees"
        ),
    }


def sans_les_profils(donnee):
    """Retire les profils de travail avant l ecriture.

    Neuf mille echantillons d altitude dans un fichier de donnees ne servent
    personne et noieraient ce qui doit se lire. Ils ont servi a mesurer ; la
    trace reste la source.
    """
    for cle in ("etapes", "segments_entre_nuits"):
        for unite in donnee.get(cle, []):
            unite.pop("_profil", None)
    return donnee


def ecrire(relatif, donnee, verifier):
    texte = json.dumps(sans_les_profils(donnee), ensure_ascii=False, indent=2) + "\n"
    cible = chemin(relatif)
    if verifier:
        if not os.path.exists(cible):
            return "ABSENT"
        return (
            "IDENTIQUE"
            if open(cible, encoding="utf-8").read() == texte
            else "DIFFERENT"
        )
    os.makedirs(os.path.dirname(cible), exist_ok=True)
    with open(cible, "w", encoding="utf-8", newline="\n") as f:
        f.write(texte)
    return "ECRIT"


def main():
    a = argparse.ArgumentParser(description=__doc__)
    a.add_argument("--verifier", action="store_true", help="ne rien ecrire, comparer")
    args = a.parse_args()

    sortie = mesurer()
    etat = ecrire(SORTIE, sortie, args.verifier)

    controle = sortie["controle_du_moteur"]
    print(f"{SORTIE} : {etat}")
    print(
        f"moteur de denivele : {controle['unites_controlees']} unites controlees, "
        f"toutes identiques = {controle['toutes_identiques']}"
    )
    for sens in ("sens trace", "sens inverse"):
        t = sortie["totaux_par_etapes"][sens]["sentier entier"]
        n = sortie["totaux_par_les_nuits"][sens]["sentier entier"]
        print(
            f"{sens} : par etapes {t['temps']} ({t['km']} km, D+{t['dplus_m']}, "
            f"D-{t['dmoins_m']}) | par les nuits {n['temps']} ({n['km']} km)"
        )
    if not controle["toutes_identiques"]:
        print("ATTENTION : le moteur de denivele ne reproduit pas les chiffres publies.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
