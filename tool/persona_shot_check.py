#!/usr/bin/env python3
"""Controle de fin de run persona : les captures disent-elles la verite ?

POURQUOI CE CONTROLE EXISTE (tache 665, defaut trouve au 645-05b, memoire
#101082). Des captures persona ont montre L'ECRAN SUIVANT celui demande : la
recette rendait un jeu d'images d'apparence normale alors que plusieurs
captures d'ecrans differents portaient le MEME contenu, et un run a rendu 0
capture pour 65 marqueurs. Rien dans le run ne rougissait. Une campagne entiere
pouvait donc etre lue de travers sans qu'aucun garde-fou ne proteste.

CE QUE LE CONTROLE REFUSE. Le run echoue (code 1) si :
  1. un marqueur `PERSONA_SHOT|<nom>` du journal n'a PAS de capture sur le
     disque, ou si cette capture est vide ;
  2. deux marqueurs DIFFERENTS portent une image au contenu identique (meme
     empreinte) — signature du retard : la capture d'un ecran est servie pour
     un autre ;
  3. le retard mesure entre l'instant ou le demon voit le marqueur et l'instant
     ou il lance `screencap` depasse le budget (`--max-retard-ms`). Au-dela, le
     harnais a deja rendu la main et l'ecran a change : l'image ne prouve plus
     rien.
Le point 3 n'est verifie que si le manifeste du demon est present.

TOLERANCE EXPLICITE. Deux captures d'un MEME ecran peuvent legitimement etre
identiques (une action sans effet visible). Ces paires-la se declarent dans un
fichier de tolerance (`--tolerances`). Rien n'est tolere par defaut : un
doublon non declare rougit.

DEUX FORMES DE DECLARATION, ET LA SECONDE EST ARRIVEE A LA TACHE 685 :
  * UNE PAIRE      : `nom_a nom_b            # pourquoi`
  * UNE FAMILLE    : `groupe: nom_a nom_b nom_c ...   # pourquoi`
    Toutes les paires INTERNES a la famille sont tolerees.

POURQUOI LA FAMILLE N'EST PAS UN CONFORT (mesure du 05/10, memoire #101219).
La regle de doublon compare l'image ENTIERE, barre d'etat comprise : UN pixel
d'horloge suffit a declarer « differentes » deux captures d'un ecran ou rien ne
s'est passe. Le GROUPEMENT CHANGE DONC D'UN RUN A L'AUTRE. Sur les treize
captures de la carte immobile de S1, le run de 06:42 a rendu le groupe
{tick_05, tick_06, tick_07, apres_gps, apres_sos} et celui de 08:03 les groupes
{tick_03..tick_06} et {apres_gps, apres_sos} : les MEMES images, un decoupage
different. Declarer paire par paire obligeait donc a ecrire les 78 paires d'une
famille de treize pour que le verdict soit stable — ou a laisser le run rouge
un jour sur deux. La famille se declare une fois, avec sa raison.

UNE DECLARATION SANS RAISON EST REFUSEE (tache 685). Le fichier le demandait
depuis la tache 665 ; rien ne le verifiait. Desormais une ligne de tolerance
sans texte apres le `#` fait ROUGIR le run : la lever oblige a regarder
l'image, ce qui est exactement le but.

Usage:
  python tool/persona_shot_check.py --log <run.log> --captures <dir>
         [--manifeste <path>] [--max-retard-ms 2000] [--tolerances <path>]
         [--json <path>]
"""
import argparse
import hashlib
import json
import os
import re
import sys

MARK = re.compile(r"PERSONA_SHOT\|([A-Za-z0-9_\-]+)")


def _marqueurs(log_path):
    """Les marqueurs du journal, dans l'ordre, sans doublon de nom."""
    vus = []
    deja = set()
    if not os.path.exists(log_path):
        return vus
    with open(log_path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            m = MARK.search(line)
            if not m:
                continue
            nom = m.group(1)
            if nom not in deja:
                deja.add(nom)
                vus.append(nom)
    return vus


def _manifeste(path):
    """Le manifeste du demon, indexe par nom de marqueur."""
    par_nom = {}
    if not path or not os.path.exists(path):
        return par_nom
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                e = json.loads(line)
            except ValueError:
                continue
            nom = e.get("nom")
            if nom:
                par_nom[nom] = e
    return par_nom


def _tolerances(path):
    """Les doublons declares legitimes.

    Rend `(paires, declarations, fautes)` :
      * `paires`       : l'ensemble des paires tolerees (frozenset de deux noms),
                         familles developpees en toutes leurs paires internes ;
      * `declarations` : une entree par ligne lue (`forme`, `noms`, `raison`,
                         `ligne`), pour le rapport ;
      * `fautes`       : les lignes refusees (declaration sans raison, famille
                         d'un seul nom), qui feront ROUGIR le run.
    """
    paires = set()
    declarations = []
    fautes = []
    if not path or not os.path.exists(path):
        return paires, declarations, fautes
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for num, brut in enumerate(fh, 1):
            avant, _, apres = brut.partition("#")
            corps = avant.strip()
            raison = apres.strip()
            if not corps:
                continue  # ligne vide ou commentaire pur
            groupe = corps.startswith("groupe:")
            if groupe:
                corps = corps[len("groupe:"):].strip()
            noms = corps.split()
            mini = 2
            if len(noms) < mini:
                fautes.append(
                    "tolerance ligne %d : %s ne nomme que %d capture(s), il en "
                    "faut au moins %d -> %s"
                    % (num, "la famille" if groupe else "la paire",
                       len(noms), mini, brut.strip())
                )
                continue
            if not raison:
                fautes.append(
                    "tolerance ligne %d SANS RAISON ECRITE : %s. Une tolerance "
                    "sans raison ne se relit pas, donc ne se leve jamais."
                    % (num, " ".join(noms))
                )
                continue
            if not groupe and len(noms) > mini:
                fautes.append(
                    "tolerance ligne %d : %d noms sur une ligne de PAIRE. "
                    "Pour une famille, ecrivez 'groupe: %s'."
                    % (num, len(noms), " ".join(noms))
                )
                continue
            for i in range(len(noms)):
                for j in range(i + 1, len(noms)):
                    paires.add(frozenset((noms[i], noms[j])))
            declarations.append({
                "ligne": num,
                "forme": "groupe" if groupe else "paire",
                "noms": noms,
                "raison": raison,
            })
    return paires, declarations, fautes


def _empreinte(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for bloc in iter(lambda: fh.read(65536), b""):
            h.update(bloc)
    return h.hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--log", required=True)
    ap.add_argument("--captures", required=True)
    ap.add_argument("--manifeste", default=None)
    ap.add_argument("--max-retard-ms", type=int, default=2000)
    ap.add_argument("--tolerances", default=None)
    ap.add_argument("--json", dest="json_out", default=None)
    a = ap.parse_args()

    manifeste_path = a.manifeste or os.path.join(a.captures, "_shots.jsonl")
    marqueurs = _marqueurs(a.log)
    manif = _manifeste(manifeste_path)
    tol, declarations, fautes_tolerance = _tolerances(a.tolerances)

    fautes = []
    manquants = []
    vides = []
    par_empreinte = {}
    retards = []

    for nom in marqueurs:
        png = os.path.join(a.captures, f"{nom}.png")
        if not os.path.exists(png):
            manquants.append(nom)
            continue
        if os.path.getsize(png) == 0:
            vides.append(nom)
            continue
        par_empreinte.setdefault(_empreinte(png), []).append(nom)

    # Captures presentes sans marqueur au journal : anomalie a dire, pas un
    # echec (un re-run peut laisser des images d'avant dans le dossier).
    sur_disque = set()
    if os.path.isdir(a.captures):
        sur_disque = {
            f[:-4] for f in os.listdir(a.captures) if f.lower().endswith(".png")
        }
    orphelines = sorted(sur_disque - set(marqueurs))

    doublons = []
    for emp, noms in par_empreinte.items():
        if len(noms) < 2:
            continue
        non_tolere = []
        for i in range(len(noms)):
            for j in range(i + 1, len(noms)):
                if frozenset((noms[i], noms[j])) not in tol:
                    non_tolere.append((noms[i], noms[j]))
        if non_tolere:
            doublons.append({"empreinte": emp[:16], "noms": noms, "paires": non_tolere})

    for nom in marqueurs:
        e = manif.get(nom)
        if e is None:
            continue
        retards.append((nom, e.get("retard_ms", -1), e.get("duree_ms", -1)))

    trop_tard = [(n, r) for (n, r, _d) in retards if r > a.max_retard_ms]
    sans_manifeste = [n for n in marqueurs if n not in manif] if manif else []

    # TOLERANCES MORTES, ET LA MESURE EST PAR DECLARATION, PAS PAR PAIRE.
    #
    # POURQUOI PAS PAR PAIRE : une FAMILLE est declaree en clique complete
    # expres (le groupement reel change d'un run a l'autre au gre de l'horloge
    # de la barre d'etat), donc la plupart de ses paires ne servent a rien DANS
    # UN RUN DONNE — c'est l'attendu, pas un symptome. Compter paire par paire
    # noierait le signal sous cent lignes de bruit.
    #
    # CE QU'ON DIT DONC : une declaration dont TOUS les noms sont des marqueurs
    # de ce run et dont AUCUNE paire interne n'est identique. La famille entiere
    # a cesse d'etre un doublon : l'action a retrouve un effet visible, ou le
    # scenario a change. Ce n'est pas une faute, c'est la seule facon de voir
    # une tolerance pourrir sur place.
    appariees = set()
    for noms in par_empreinte.values():
        for i in range(len(noms)):
            for j in range(i + 1, len(noms)):
                appariees.add(frozenset((noms[i], noms[j])))
    vus = set(marqueurs)
    inutilisees = []
    for d in declarations:
        noms = d["noms"]
        if not all(n in vus for n in noms):
            continue
        servie = any(
            frozenset((noms[i], noms[j])) in appariees
            for i in range(len(noms))
            for j in range(i + 1, len(noms))
        )
        if not servie:
            inutilisees.append(
                "ligne %d (%s) : %s" % (d["ligne"], d["forme"], " ".join(noms))
            )

    if fautes_tolerance:
        # LE FICHIER DE TOLERANCES EST LUI-MEME CONTROLE (tache 685). Une
        # tolerance sans raison, ou une famille ecrite comme une paire, rend le
        # controle illisible : on refuse le run plutot que de tolerer au hasard.
        fautes.extend(fautes_tolerance)
    if not marqueurs:
        # LE CAS LE PLUS TRAITRE : aucun marqueur du tout. Le dossier de
        # captures peut meme etre plein (images d'un run precedent) et le test
        # vert. Il doit rougir le PREMIER, pas en note de bas de page.
        fautes.append(
            "AUCUN marqueur dans le journal — le demon n'avait rien a capturer "
            "(journal vide, sortie non redirigee, ou test arrete avant le 1er ecran)"
        )
    if manquants:
        fautes.append(f"{len(manquants)} marqueur(s) SANS capture : {', '.join(manquants)}")
    if vides:
        fautes.append(f"{len(vides)} capture(s) VIDE(s) : {', '.join(vides)}")
    if doublons:
        detail = "; ".join(
            f"[{d['empreinte']}] " + " = ".join(d["noms"]) for d in doublons
        )
        fautes.append(
            f"{len(doublons)} groupe(s) de captures IDENTIQUES non tolerees : {detail}"
        )
    if trop_tard:
        detail = ", ".join(f"{n} ({r} ms)" for n, r in trop_tard)
        fautes.append(
            f"{len(trop_tard)} capture(s) lancee(s) APRES le budget de "
            f"{a.max_retard_ms} ms : {detail}"
        )

    rs = [r for (_n, r, _d) in retards if r >= 0]
    ds = [d for (_n, _r, d) in retards if d >= 0]
    resume = {
        "marqueurs": len(marqueurs),
        "captures_presentes": len(marqueurs) - len(manquants) - len(vides),
        "manquants": manquants,
        "vides": vides,
        "doublons": doublons,
        "orphelines": orphelines,
        "sans_manifeste": sans_manifeste,
        "retard_ms_max": max(rs) if rs else None,
        "retard_ms_median": sorted(rs)[len(rs) // 2] if rs else None,
        "screencap_ms_max": max(ds) if ds else None,
        "screencap_ms_median": sorted(ds)[len(ds) // 2] if ds else None,
        "budget_retard_ms": a.max_retard_ms,
        "tolerances_fichier": a.tolerances,
        "tolerances_declarations": len(declarations),
        "tolerances_paires": len(tol),
        "tolerances_familles": sum(
            1 for d in declarations if d["forme"] == "groupe"
        ),
        "tolerances_inutilisees": inutilisees,
        "fautes": fautes,
        "verdict": "OK" if not fautes else "ECHEC",
    }

    print("[shot-check] marqueurs=%d captures=%d empreintes_distinctes=%d"
          % (resume["marqueurs"], resume["captures_presentes"], len(par_empreinte)))
    print("[shot-check] tolerances : %d declaration(s) dont %d famille(s), "
          "%d paire(s) couverte(s)"
          % (len(declarations), resume["tolerances_familles"], len(tol)))
    if resume["tolerances_inutilisees"]:
        print("[shot-check] %d tolerance(s) DECLAREE(S) mais inutile(s) sur ce "
              "run : toutes leurs captures sont presentes et AUCUNE n'est "
              "identique a une autre. A relire : l'action a peut-etre retrouve "
              "un effet visible."
              % len(resume["tolerances_inutilisees"]))
        for ligne in resume["tolerances_inutilisees"]:
            print("[shot-check]   - %s" % ligne)
    if rs:
        print("[shot-check] retard marqueur->screencap : median=%d ms max=%d ms "
              "(budget %d ms)" % (resume["retard_ms_median"], resume["retard_ms_max"],
                                  a.max_retard_ms))
    if ds:
        print("[shot-check] duree screencap : median=%d ms max=%d ms"
              % (resume["screencap_ms_median"], resume["screencap_ms_max"]))
    else:
        print("[shot-check] pas de manifeste (%s) : retard NON mesure" % manifeste_path)
    if orphelines:
        print("[shot-check] captures sans marqueur au journal : %s"
              % ", ".join(orphelines))
    if sans_manifeste:
        print("[shot-check] marqueurs absents du manifeste : %s"
              % ", ".join(sans_manifeste))
    for f in fautes:
        print(f"[shot-check] FAUTE : {f}")
    print(f"[shot-check] VERDICT {resume['verdict']}")

    if a.json_out:
        with open(a.json_out, "w", encoding="utf-8") as fh:
            json.dump(resume, fh, ensure_ascii=False, indent=2)

    return 1 if fautes else 0


if __name__ == "__main__":
    sys.exit(main())
