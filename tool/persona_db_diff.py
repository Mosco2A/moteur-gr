#!/usr/bin/env python3
"""DIFFERENTIEL DU STOCKAGE ENTRE DEUX INSTANTS (tache 559, passe 5).

POURQUOI, ET C EST UNE OBJECTION JUSTE. Le correctif du lot O ferme la cle que
J AVAIS MESUREE apres un refus — mais rien ne garantit qu aucune AUTRE ecriture
n a lieu apres un refus, ailleurs. Une seule lecture avait suffi a trouver un
defaut ; chercher la meme chose cle par cle, a la main, ne prouverait rien de
plus.

Cet outil ne cherche donc rien de precis : il compare DEUX sondages et rend
TOUT ce qui a bouge entre les deux. Ce qui APPARAIT apres un refus est le
signal : une application qui dit « rien n est enregistre » ne doit ajouter
AUCUNE cle, quel que soit l ecran ou le refus a ete exprime.

Usage:
  python tool/persona_db_diff.py <sonde_avant> <sonde_apres> [libelle]
"""
import json
import os
import sys


def cles(chemin):
    fichier = os.path.join(chemin, "etat.json")
    if not os.path.exists(fichier):
        return None
    with open(fichier, encoding="utf-8") as fh:
        etat = json.load(fh)
    plat = {}
    for _, contenu in etat.get("preferences", {}).items():
        for k, v in contenu.items():
            if k.startswith("flutter."):
                plat[k] = v
    for nom, tables in etat.get("sqlite", {}).items():
        for table, n in tables.items():
            plat[f"<table>{nom}:{table}"] = n
    return plat


def main():
    if len(sys.argv) < 3:
        print("usage: persona_db_diff.py <sonde_avant> <sonde_apres> [libelle]")
        return 2
    avant, apres = cles(sys.argv[1]), cles(sys.argv[2])
    libelle = sys.argv[3] if len(sys.argv) > 3 else "differentiel"
    if avant is None or apres is None:
        print(f"DB_EXIGENCE|ECHEC|[{libelle}] un des deux sondages manque : "
              f"rien ne peut etre compare")
        return 1

    apparues = sorted(set(apres) - set(avant))
    disparues = sorted(set(avant) - set(apres))
    modifiees = sorted(k for k in set(avant) & set(apres)
                       if avant[k] != apres[k])

    for k in apparues:
        valeur = str(apres[k])
        print(f"DB_DIFF|APPARUE|{k} = "
              f"{valeur[:160] + ('...' if len(valeur) > 160 else '')}")
    for k in disparues:
        print(f"DB_DIFF|DISPARUE|{k}")
    for k in modifiees:
        a, b = str(avant[k]), str(apres[k])
        print(f"DB_DIFF|MODIFIEE|{k} : {a[:80]} -> {b[:80]}")
    if not (apparues or disparues or modifiees):
        print(f"DB_DIFF|AUCUN CHANGEMENT|le stockage est identique")

    # L EXIGENCE, ET SA NUANCE — QUE J AI DU CORRIGER APRES LA PREMIERE MESURE.
    # « Un refus ne doit rien ajouter » etait MON exigence, et elle etait trop
    # stricte : enregistrer la DECISION de refus est legitime, et meme requis —
    # sans elle, l application ne saurait pas que l utilisateur a refuse et le
    # lui redemanderait sans fin. Ce qui ne doit PAS apparaitre, c est une cle
    # de DONNEE. On distingue donc les deux, et on les rend separement.
    decisions = [k for k in apparues if k.startswith("flutter.consent_")]
    donnees = [k for k in apparues if not k.startswith("flutter.consent_")]
    if decisions:
        print(f"DB_DIFF|LEGITIME|decision(s) de consentement enregistree(s) : "
              f"{decisions}")
    ok = not donnees
    print(f"DB_EXIGENCE|{'OK' if ok else 'ECHEC'}|[{libelle}] un refus n ecrit "
          f"AUCUNE donnee dans le stockage (la trace de la decision, elle, est "
          f"legitime)" + (f" — DONNEES APPARUES : {donnees}" if donnees else ""))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
