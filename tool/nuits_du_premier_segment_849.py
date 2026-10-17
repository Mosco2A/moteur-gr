#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tache 849, partie UN : ou peut-on dormir entre Calenzana et l Ortu di u Piobbu ?

POURQUOI CET OUTIL EXISTE. La tache 848 a etabli que la pire journee du GR20 ne
descend JAMAIS sous 1 455 m de montee, quel que soit le nombre de jours demande,
de 1 a 31. La cause est une seule : le PREMIER segment du sentier, Calenzana
vers le refuge de l Ortu di u Piobbu, pese 11,349 km et 1 455 m de montee, et
AUCUNE nuit relevee ne tombe a l interieur. C est la plus petite unite que le
decoupage sait manipuler, donc c est le plancher du sentier entier.

Le releve de la tache 838 avait interroge un couloir de 3 KM autour de la trace
et ne gardait que ce qui tombait sous 30 MINUTES de marche. Les deux reglages
etaient bons pour sa question (quelles coupures de jour peut-on ajouter sans
allonger la journee ?), ils sont TROP ETROITS pour celle-ci : ici on veut savoir
s il existe QUOI QUE CE SOIT, meme loin, meme cher en marche, parce qu une nuit
qui coute 40 minutes d acces mais coupe 1 455 m de montee en deux peut valoir la
peine — et c est au chiffre de le dire, pas au reglage de le cacher.

CE QUI CHANGE PAR RAPPORT A LA 838, ET C EST TOUT :
  - le couloir passe de 3 km a 8 km (RAYON_COULOIR_M ci-dessous) ;
  - le plafond de reseau passe de 6 km a 20 km, pour que RIEN ne soit ecarte
    par le plafond : si un endroit est a 14 km de marche, on l ECRIT, on ne le
    fait pas disparaitre ;
  - AUCUN seuil de minutes ne filtre la sortie : tout ce qui est trouve est
    rendu avec son temps d acces dans LES DEUX SENS, et le lecteur juge ;
  - le modele de temps de marche est le modele UNIQUE du depot depuis la 839
    (la descente COUTE), et non plus le « modele 1 » a descente gratuite.

TOUT LE RESTE EST REPRIS TEL QUEL du module de la 838, par import et non par
copie : la distance geodesique, la classification des objets OpenStreetMap
(« declare » / « nomme » / « hors sujet »), le re-echantillonnage a 15 m,
l altimetrie EU-DEM 25 m avec son cache, et le filtre de denivele ANCRE aux
deux bouts (correction mesuree en 838). Les chiffres restent donc comparables a
ceux des taches 837, 838 et 839 : c est la condition pour que la comparaison
avec le plancher de 1 455 m veuille dire quelque chose.

Source : OpenStreetMap, licence ODbL. Terrain : EU-DEM 25 m via opentopodata.

Usage :
  python tool/nuits_du_premier_segment_849.py \
      --trace assets/data/gr20/track.gpx \
      --nuits assets/data/gr20/nuits_possibles.json \
      --cache <dossier de cache> \
      --sortie assets/data/gr20/nuits_premier_segment_849.json \
      [--etape releve|itineraires|altitudes|rendu|tout]
"""

import argparse
import math
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import couchages_du_couloir as c838  # noqa: E402  (le chemin doit etre pose avant)


# --------------------------------------------------------------------------
# Les reglages de CETTE question, et la raison de chacun
# --------------------------------------------------------------------------

# Huit kilometres, parce que la question n est plus « quelle coupure ne coute
# rien » mais « existe-t-il quoi que ce soit ». Bonifatu, que les topoguides
# citent comme la porte de secours de ce versant, est a cette echelle.
RAYON_COULOIR_M = 8000

# Vingt kilometres de reseau : plus de trois fois la 838. Ce n est pas un
# filtre, c est une borne de calcul. Tout ce qui est atteint est rendu avec son
# temps, meme a quatre heures de marche.
PLAFOND_RESEAU_M = 20000.0

# Un couchage dont le noeud de reseau le plus proche est au-dela de cette
# distance n a PAS de chemin trace jusqu a lui. Identique a la 838 : on l ecrit,
# on n estime pas.
RACCORD_MAX_M = 60.0

# Un point de trace et un noeud du reseau a moins de cette distance sont le
# MEME point : c est ainsi que la trace entre dans le graphe pieton.
SNAP_TRACE_M = 25.0

# Un couchage dont le point de depart sur la trace est a moins de cette distance
# d un bout du segment ne COUPE PAS le segment : il est au village de depart ou
# au refuge d arrivee, et la montee de 1 455 m reste entiere.
MARGE_DE_BOUT_M = 300.0

# Le segment a couper, tel que la 839 l a mesure et la 848 l a nomme.
PK_DEPART_M = 0.0
PK_ARRIVEE_M = 11349.0
SEGMENT_DPLUS_M = 1455
SEGMENT_DMOINS_M = 194
SEGMENT_KM = 11.349
SEGMENT_MINUTES = 394

# Le modele de temps de marche UNIQUE du depot depuis la tache 839
# (lib/core/models/stage_duration.dart, walkingSeconds). La descente COUTE.
VITESSE_PLAT_KMH = 4.0
MONTEE_S_PAR_M = 3600.0 / 400.0
DESCENTE_S_PAR_M = 10.0 / 6.0
NOM_DU_MODELE = (
    "modele UNIQUE du depot depuis la tache 839 "
    "(lib/core/models/stage_duration.dart, walkingSeconds) : "
    "4 km/h a plat, 9 s par metre de montee (400 m/h), "
    "1,667 s par metre de descente (10/6) ; la descente COUTE"
)

# Les etiquettes de couchage interrogees. Le jeu de la 838, ELARGI aux formes
# que prend un bivouac en Corse et qu un couloir de 3 km n avait pas besoin de
# chercher : l emplacement de tente, la cabane de berger, le nom « bivouac ».
TYPES_TOURISME = (
    "alpine_hut|wilderness_hut|hotel|hostel|guest_house|chalet|apartment"
    "|motel|camp_site|caravan_site|camp_pitch"
)

REQUETE_COUCHAGES = """[out:json][timeout:900];
(
  nwr(%(bbox)s)["tourism"~"^(%(types)s)$"];
  nwr(%(bbox)s)["amenity"="shelter"];
  nwr(%(bbox)s)["building"~"^(hut|cabin|chalet|farm|farm_auxiliary|bergerie|shed)$"]["name"];
  nwr(%(bbox)s)["name"~"[Bb]ergeri"];
  nwr(%(bbox)s)["name"~"[Gg](i|.)te"];
  nwr(%(bbox)s)["name"~"[Rr]efug"];
  nwr(%(bbox)s)["name"~"[Bb]ivouac"];
  nwr(%(bbox)s)["name"~"[Bb]onifat"];
  nwr(%(bbox)s)["shelter_type"];
);
out center tags;
"""

REQUETE_RESEAU = """[out:json][timeout:900];
way(%(bbox)s)["highway"~"^(%(hw)s)$"];
(._;>;);
out skel qt;
"""

HIGHWAYS_MARCHABLES = (
    "path|footway|track|steps|bridleway|cycleway|pedestrian|living_street"
    "|residential|unclassified|tertiary|secondary|primary|service|road"
)


def minutes_de_marche(distance_m_, dplus_m, dmoins_m):
    """Le modele UNIQUE du depot : la descente coute."""
    secondes = (
        distance_m_ / (VITESSE_PLAT_KMH * 1000.0 / 3600.0)
        + dplus_m * MONTEE_S_PAR_M
        + dmoins_m * DESCENTE_S_PAR_M
    )
    return int(round(secondes / 60.0))


def bbox_du_segment(points, pk, marge_m):
    """La boite du premier segment, elargie de `marge_m` de tous les cotes."""
    dedans = [p for p, k in zip(points, pk) if PK_DEPART_M <= k <= PK_ARRIVEE_M]
    if not dedans:
        raise SystemExit("Aucun point de trace dans le premier segment.")
    lats = [p[0] for p in dedans]
    lons = [p[1] for p in dedans]
    # On elargit en METRES, pas en degres : un degre de longitude vaut moins
    # qu un degre de latitude, en cos(latitude). Sinon la boite serait plus
    # etroite d un cote que de l autre.
    dlat = marge_m / 111320.0
    dlon = marge_m / (111320.0 * math.cos(math.radians(sum(lats) / len(lats))))
    boite = (min(lats) - dlat, min(lons) - dlon, max(lats) + dlat, max(lons) + dlon)
    return boite, dedans


def etape_releve(cache, trace_gpx):
    """Les couchages de la boite elargie, et les points du premier segment."""
    points = c838.lire_trace_gpx(trace_gpx)
    pk = c838.points_kilometriques(points)
    boite, dedans = bbox_du_segment(points, pk, RAYON_COULOIR_M)
    sys.stderr.write(
        "[1/4] le premier segment porte %d points de trace, du PK %.0f m au PK %.0f m\n"
        % (len(dedans), PK_DEPART_M, PK_ARRIVEE_M)
    )
    sys.stderr.write(
        "      boite interrogee (couloir de %d m) : %.5f,%.5f a %.5f,%.5f\n"
        % (RAYON_COULOIR_M, boite[0], boite[1], boite[2], boite[3])
    )
    bbox = "%.6f,%.6f,%.6f,%.6f" % boite

    trace = []
    for index, (p, k) in enumerate(zip(points, pk)):
        if not (PK_DEPART_M <= k <= PK_ARRIVEE_M):
            continue
        trace.append(
            {"i": index, "lat": p[0], "lon": p[1], "ele": p[2], "pk_m": round(k, 1)}
        )
    c838.sauver(os.path.join(cache, "segment1_trace.json"), trace)
    c838.sauver(
        os.path.join(cache, "boite.json"),
        {"lat_min": boite[0], "lon_min": boite[1], "lat_max": boite[2], "lon_max": boite[3]},
    )

    f_brut = os.path.join(cache, "couchages_brut.json")
    if os.path.exists(f_brut):
        sys.stderr.write("      couchages : deja en cache\n")
    else:
        sys.stderr.write("[1/4] releve Overpass : les couchages de la boite\n")
        brut = c838.overpass(REQUETE_COUCHAGES % {"bbox": bbox, "types": TYPES_TOURISME})
        c838.sauver(f_brut, brut)
        sys.stderr.write("      %d objets bruts\n" % len(brut.get("elements", [])))
        time.sleep(4)

    f_reseau = os.path.join(cache, "reseau_brut.json")
    if os.path.exists(f_reseau):
        sys.stderr.write("      reseau : deja en cache\n")
    else:
        sys.stderr.write("[1/4] releve Overpass : le reseau pieton de la boite\n")
        reseau = c838.overpass(REQUETE_RESEAU % {"bbox": bbox, "hw": HIGHWAYS_MARCHABLES})
        c838.sauver(f_reseau, reseau)
        sys.stderr.write("      %d objets de reseau\n" % len(reseau.get("elements", [])))
    return trace, boite


def charger_reseau(cache):
    brut = c838.charger(os.path.join(cache, "reseau_brut.json"))
    noeuds = {}
    aretes = {}
    chemins = set()
    for e in brut.get("elements", []):
        if e["type"] == "node":
            noeuds[e["id"]] = (e["lat"], e["lon"])
    for e in brut.get("elements", []):
        if e["type"] != "way" or e["id"] in chemins:
            continue
        chemins.add(e["id"])
        ids = e.get("nodes", [])
        for a, b in zip(ids, ids[1:]):
            if a == b:
                continue
            cle = (a, b) if a < b else (b, a)
            aretes[cle] = e["id"]
    return noeuds, aretes, chemins


def sources_depuis_la_trace(trace, noeuds, graphe, index):
    """Les noeuds du reseau qui SONT la trace, avec le PK qu ils portent.

    La 838 prenait les identifiants OSM des noeuds de la relation du GR20. Ici
    on raccroche par la GEOMETRIE (25 m), ce qui ne depend plus de l etat de la
    relation et donne le meme resultat : le GR20 est dans le reseau pieton,
    puisque ses chemins sont des highway=path.
    """
    par_noeud = {}
    attrapes = 0
    for t in trace:
        noeud, ecart = c838.raccord({"lat": t["lat"], "lon": t["lon"]}, noeuds, index)
        if noeud is None or ecart > SNAP_TRACE_M:
            continue
        attrapes += 1
        ancien = par_noeud.get(noeud)
        if ancien is None or ecart < ancien["ecart_m"]:
            par_noeud[noeud] = {
                "noeud": noeud,
                "lat": noeuds[noeud][0],
                "lon": noeuds[noeud][1],
                "ele": t["ele"],
                "pk_m": t["pk_m"],
                "ecart_m": round(ecart, 1),
            }
    sys.stderr.write(
        "      %d des %d points du premier segment ont un noeud de reseau a moins de "
        "%d m, soit %d noeuds distincts\n"
        % (attrapes, len(trace), SNAP_TRACE_M, len(par_noeud))
    )
    if attrapes < 0.9 * len(trace):
        sys.stderr.write(
            "      ATTENTION : moins de 90 pour cent de la trace est dans le reseau releve. "
            "Une portion du premier segment pourrait etre invisible au calcul.\n"
        )
    return par_noeud


def main():
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--trace", required=True)
    arg.add_argument("--nuits", required=True)
    arg.add_argument("--cache", required=True)
    arg.add_argument("--sortie", required=True)
    arg.add_argument(
        "--etape",
        default="tout",
        choices=("releve", "itineraires", "altitudes", "rendu", "tout"),
    )
    options = arg.parse_args()
    os.makedirs(options.cache, exist_ok=True)
    faire = (
        ("releve", "itineraires", "altitudes", "rendu")
        if options.etape == "tout"
        else (options.etape,)
    )

    if "releve" in faire:
        etape_releve(options.cache, options.trace)
    trace = c838.charger(os.path.join(options.cache, "segment1_trace.json"))

    brut = c838.charger(os.path.join(options.cache, "couchages_brut.json"))
    couchages, ecartes = c838.couchages_lisibles(brut)
    sys.stderr.write(
        "      %d couchages retenus dans la boite, %d objets ecartes\n"
        % (len(couchages), len(ecartes))
    )

    f_itin = os.path.join(options.cache, "itineraires.json")
    if "itineraires" in faire:
        noeuds, aretes, chemins = charger_reseau(options.cache)
        graphe = c838.construire_graphe(noeuds, aretes)
        sys.stderr.write(
            "[2/4] reseau : %d chemins, %d noeuds, %d aretes, %d noeuds relies\n"
            % (len(chemins), len(noeuds), len(aretes), len(graphe))
        )
        index = c838.grille_des_noeuds(noeuds, graphe)
        par_noeud = sources_depuis_la_trace(trace, noeuds, graphe, index)
        dist, source, parent = c838.dijkstra_depuis_la_trace(
            graphe, list(par_noeud.keys()), PLAFOND_RESEAU_M
        )
        sys.stderr.write(
            "[3/4] itineraires : %d noeuds atteints sous %d m de marche\n"
            % (len(dist), PLAFOND_RESEAU_M)
        )
        resultats = []
        for c in couchages:
            noeud, ecart = c838.raccord(c, noeuds, index)
            fiche = dict(c)
            fiche["raccord_noeud"] = noeud
            fiche["raccord_ecart_m"] = None if ecart is None else round(ecart, 1)
            if noeud is None or ecart > RACCORD_MAX_M:
                fiche["chemin_trace"] = False
                fiche["pourquoi"] = (
                    "aucun chemin, sentier ni piste d OpenStreetMap ne passe a moins de %d m "
                    "de cet objet%s"
                    % (
                        RACCORD_MAX_M,
                        ""
                        if ecart is None
                        else " (le plus proche est a %.0f m)" % ecart,
                    )
                )
            elif noeud not in dist:
                fiche["chemin_trace"] = False
                fiche["pourquoi"] = (
                    "un chemin existe au pied de l objet mais AUCUNE suite de chemins traces "
                    "ne le relie au premier segment du GR20 sous %d m de marche"
                    % PLAFOND_RESEAU_M
                )
            else:
                suite = c838.chemin_remonte(parent, noeud)
                depart = par_noeud[source[noeud]]
                fiche["chemin_trace"] = True
                fiche["longueur_reseau_m"] = round(dist[noeud], 1)
                fiche["pk_m"] = depart["pk_m"]
                fiche["depart_noeud"] = depart["noeud"]
                fiche["depart_lat"] = depart["lat"]
                fiche["depart_lon"] = depart["lon"]
                fiche["depart_ele"] = depart["ele"]
                fiche["geometrie"] = [list(noeuds[n]) for n in suite]
            resultats.append(fiche)
        c838.sauver(f_itin, {"itineraires": resultats, "ecartes": ecartes})

    f_profils = os.path.join(options.cache, "profils.json")
    if "altitudes" in faire:
        itin = c838.charger(f_itin)["itineraires"]
        a_demander = []
        echantillons = {}
        for c in itin:
            if not c.get("chemin_trace"):
                continue
            geo = [tuple(p) for p in c["geometrie"]]
            if (c.get("raccord_ecart_m") or 0) > 1.0:
                geo.append((c["lat"], c["lon"]))
            ech = c838.reechantillonner(geo, 15.0)
            echantillons[c["osm"]] = ech
            a_demander.extend(ech)
        cache_alt = c838.altimetriser(
            a_demander, os.path.join(options.cache, "altitudes_cache.json")
        )
        profils = {}
        for osm, ech in echantillons.items():
            alts = [cache_alt.get("%.5f,%.5f" % (lat, lon)) for lat, lon in ech]
            profils[osm] = {
                "points": len(ech),
                "altitudes": alts,
                "manquantes": sum(1 for a in alts if a is None),
            }
        c838.sauver(f_profils, profils)

    if "rendu" in faire:
        rendu(options, trace, f_itin, f_profils)


def rendu(options, trace, f_itin, f_profils):
    charge = c838.charger(f_itin)
    itin = charge["itineraires"]
    ecartes = charge["ecartes"]
    profils = c838.charger(f_profils)
    boite = c838.charger(os.path.join(options.cache, "boite.json"))

    dedans = []
    dehors = []
    sans_chemin = []
    for c in itin:
        fiche = {
            "osm": c["osm"],
            "nom": c.get("nom"),
            "anonyme": c.get("anonyme"),
            "classe": c.get("classe"),
            "classe_pourquoi": c.get("classe_pourquoi"),
            "genre": c.get("genre"),
            "genre_en_clair": c.get("genre_en_clair"),
            "lat": c["lat"],
            "lon": c["lon"],
            "lits": c.get("lits"),
            "unite_lits": c.get("unite_lits"),
            "tags_utiles": c.get("tags_utiles"),
            "chemin_trace": c.get("chemin_trace"),
        }
        if not c.get("chemin_trace"):
            fiche["pourquoi"] = c.get("pourquoi")
            fiche["raccord_ecart_m"] = c.get("raccord_ecart_m")
            sans_chemin.append(fiche)
            continue

        prof = profils.get(c["osm"], {})
        alts = prof.get("altitudes") or []
        dplus, dmoins = c838.denivele_maison(alts, ancrer=True)
        longueur = c["longueur_reseau_m"]
        if (c.get("raccord_ecart_m") or 0) > 1.0:
            longueur += c["raccord_ecart_m"]
        fiche.update(
            {
                "pk_m": c["pk_m"],
                "pk_km": round(c["pk_m"] / 1000.0, 3),
                "longueur_reseau_m": round(longueur, 1),
                "depart_lat": c["depart_lat"],
                "depart_lon": c["depart_lon"],
                "depart_ele": c["depart_ele"],
                "altitudes_manquantes": prof.get("manquantes"),
                "dplus_aller_m": dplus,
                "dmoins_aller_m": dmoins,
                "dplus_retour_m": dmoins,
                "dmoins_retour_m": dplus,
                "minutes_aller": minutes_de_marche(longueur, dplus, dmoins),
                "minutes_retour": minutes_de_marche(longueur, dmoins, dplus),
            }
        )
        fiche["minutes_aller_retour"] = fiche["minutes_aller"] + fiche["minutes_retour"]

        # EST-CE UNE COUPURE DU PREMIER SEGMENT ? La seule question qui compte.
        coupe = (PK_DEPART_M + MARGE_DE_BOUT_M) < c["pk_m"] < (PK_ARRIVEE_M - MARGE_DE_BOUT_M)
        fiche["coupe_le_segment"] = coupe
        if coupe:
            # Ce que deviendrait la journee si l on dormait la. Le detour est
            # COMPTE dans la journee, comme la 839 l a etabli : on y descend le
            # soir, on en remonte le matin.
            fiche["si_on_dort_la"] = {
                "avant_km": round(c["pk_m"] / 1000.0, 3),
                "apres_km": round((PK_ARRIVEE_M - c["pk_m"]) / 1000.0, 3),
            }
            dedans.append(fiche)
        else:
            au_depart = c["pk_m"] <= PK_DEPART_M + MARGE_DE_BOUT_M
            fiche["pourquoi_pas_une_coupure"] = (
                "son point de depart sur la trace est au %s, a %.0f m du bout du segment : "
                "y dormir ne coupe pas la montee de 1 455 m"
                % (
                    "depart (Calenzana)" if au_depart else "arrivee (Ortu di u Piobbu)",
                    min(c["pk_m"], PK_ARRIVEE_M - c["pk_m"]),
                )
            )
            dehors.append(fiche)

    dedans.sort(key=lambda f: f["minutes_aller_retour"])
    dehors.sort(key=lambda f: (f["pk_m"], f["minutes_aller"]))
    sans_chemin.sort(key=lambda f: (f["classe"], str(f["nom"])))

    sortie = {
        "quoi": (
            "Tout endroit ou dormir trouve entre Calenzana et le refuge de l Ortu di u "
            "Piobbu, dans un couloir de %d m autour du premier segment du GR20, avec le "
            "temps de marche pour y aller ET en revenir. AUCUN seuil de minutes ne filtre "
            "cette liste." % RAYON_COULOIR_M
        ),
        "tache": 849,
        "question": (
            "La tache 848 a etabli que la pire journee du GR20 ne descend jamais sous "
            "1 455 m de montee parce que le premier segment (11,349 km, 1 455 m) ne porte "
            "aucune nuit a son interieur. Existe-t-il quoi que ce soit a l interieur ?"
        ),
        "segment": {
            "depart": "Calenzana",
            "arrivee": "Refuge de l'Ortu di u Piobbu",
            "km": SEGMENT_KM,
            "dplus_m": SEGMENT_DPLUS_M,
            "dmoins_m": SEGMENT_DMOINS_M,
            "minutes": SEGMENT_MINUTES,
            "pk_depart_m": PK_DEPART_M,
            "pk_arrivee_m": PK_ARRIVEE_M,
        },
        "source": "OpenStreetMap, licence ODbL",
        "modele_terrain": c838.MODELE_TERRAIN,
        "modele_de_temps_de_marche": NOM_DU_MODELE,
        "rayon_couloir_m": RAYON_COULOIR_M,
        "plafond_reseau_m": PLAFOND_RESEAU_M,
        "raccord_max_m": RACCORD_MAX_M,
        "marge_de_bout_m": MARGE_DE_BOUT_M,
        "aucun_seuil_de_minutes": True,
        "boite_interrogee": boite,
        "points_de_trace_du_segment": len(trace),
        "couchages_dans_la_boite": len(itin),
        "coupent_le_premier_segment": len(dedans),
        "aux_deux_bouts_donc_ne_coupent_rien": len(dehors),
        "sans_chemin_trace": len(sans_chemin),
        "objets_ecartes": len(ecartes),
        "LA_REPONSE": (
            "AUCUN endroit ou dormir ne coupe le premier segment"
            if not dedans
            else "%d endroit(s) coupent le premier segment" % len(dedans)
        ),
        "coupures_trouvees": dedans,
        "aux_bouts": dehors,
        "sans_chemin": sans_chemin,
        "ecartes": ecartes,
    }
    c838.sauver(options.sortie, sortie)

    print()
    print("=" * 78)
    print("TACHE 849 PARTIE UN - DORMIR ENTRE CALENZANA ET L ORTU DI U PIOBBU")
    print("=" * 78)
    print(
        "Segment : %.3f km, %d m de montee, %d m de descente, %d min de marche"
        % (SEGMENT_KM, SEGMENT_DPLUS_M, SEGMENT_DMOINS_M, SEGMENT_MINUTES)
    )
    print(
        "Couloir interroge : %d m autour de la trace. Plafond de reseau : %.0f m."
        % (RAYON_COULOIR_M, PLAFOND_RESEAU_M)
    )
    print("Aucun seuil de minutes : tout ce qui est trouve est ecrit.")
    print()
    print("Couchages trouves dans la boite        : %d" % len(itin))
    print("  dont COUPENT le premier segment      : %d" % len(dedans))
    print("  dont aux deux bouts (ne coupent rien): %d" % len(dehors))
    print("  dont sans aucun chemin trace         : %d" % len(sans_chemin))
    print()
    print(">>> %s" % sortie["LA_REPONSE"])
    print()
    if dedans:
        print("--- LES COUPURES DU PREMIER SEGMENT ---")
        for f in dedans:
            print(
                "  %-32s PK %7.0f m | %-16s | %-8s | aller %-6s retour %-6s | %6.0f m reseau "
                "| D+%4d D-%4d | lits=%s | %s"
                % (
                    str(f["nom"])[:32],
                    f["pk_m"],
                    str(f["genre_en_clair"])[:16],
                    f["classe"],
                    c838.en_clair(f["minutes_aller"]),
                    c838.en_clair(f["minutes_retour"]),
                    f["longueur_reseau_m"],
                    f["dplus_aller_m"],
                    f["dmoins_aller_m"],
                    f["lits"],
                    f["osm"],
                )
            )
        print()
    print("--- AUX DEUX BOUTS, DONC NE COUPE RIEN (%d) ---" % len(dehors))
    for f in dehors:
        print(
            "  %-32s PK %7.0f m | %-16s | %-8s | aller %-6s retour %-6s | %s"
            % (
                str(f["nom"])[:32],
                f["pk_m"],
                str(f["genre_en_clair"])[:16],
                f["classe"],
                c838.en_clair(f["minutes_aller"]),
                c838.en_clair(f["minutes_retour"]),
                f["osm"],
            )
        )
    print()
    print("--- AUCUN CHEMIN TRACE (%d) ---" % len(sans_chemin))
    for f in sans_chemin:
        print(
            "  %-32s | %-8s | %-14s | %s"
            % (
                str(f["nom"])[:32],
                f["classe"],
                str(f["genre_en_clair"])[:14],
                str(f["pourquoi"])[:92],
            )
        )
    print()
    print("Ecrit dans %s" % options.sortie)


if __name__ == "__main__":
    main()
