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
identiques (une action sans effet visible). Ces paires-la se declarent une par
une dans un fichier de tolerance (`--tolerances`), une paire par ligne au
format `nom_a nom_b  # raison`. Rien n'est tolere par defaut : un doublon non
declare rougit.

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
    """Les paires de doublons declarees legitimes."""
    paires = set()
    if not path or not os.path.exists(path):
        return paires
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            bouts = line.split()
            if len(bouts) >= 2:
                paires.add(frozenset((bouts[0], bouts[1])))
    return paires


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
    tol = _tolerances(a.tolerances)

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
        "fautes": fautes,
        "verdict": "OK" if not fautes else "ECHEC",
    }

    print("[shot-check] marqueurs=%d captures=%d empreintes_distinctes=%d"
          % (resume["marqueurs"], resume["captures_presentes"], len(par_empreinte)))
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
