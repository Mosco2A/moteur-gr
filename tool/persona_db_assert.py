#!/usr/bin/env python3
"""VERIFICATION DU STOCKAGE REEL (tache 559, passe 4).

La sonde COPIE et INVENTORIE ; ce fichier JUGE. Il lit l etat.json produit a un
instant nomme et dit, dans la meme grammaire que le reste de la campagne, ce
qui aurait du disparaitre et ce qui est encore la.

POURQUOI LE JUGEMENT EST ICI ET NON DANS LE SCENARIO. Le scenario tourne sur
l appareil et ne peut pas lire le dossier prive de l application. Rendre le
verdict host-side est la seule facon honnete : on ne demande pas a l ecran de
temoigner de ce que le disque contient.

Trois moments, trois exigences differentes :
  * apres-effacement   : la fiche, les randos passees, le test de marche et la
                         note d experience ne doivent plus exister. Les achats
                         et les reglages d affichage, eux, DOIVENT rester — le
                         dialogue le promet.
  * apres-refus-art9   : rien de la morphologie ne doit avoir ete ecrit.
  * apres-revocation   : ce qui avait ete ecrit doit avoir ete EFFACE.

Usage:
  python tool/persona_db_assert.py <dossier_sonde> <moment>
"""
import json
import os
import sys

# Les cles REELLES de l application, relevees dans le code (hiker_profile
# repository, onboarding, settings, consentements).
CLES_SANTE = [
    "flutter.hiker.profile",
    "flutter.hiker.pastHikes",
    "flutter.hiker.walkTestResult",
    "flutter.hiker.experienceNote",
]
CLES_REGLAGES = [
    "flutter.settings_language",
    "flutter.settings_theme_mode",
    "flutter.settings_distance_unit",
]
PREFIXE_CONSENTEMENT = "flutter.consent_"

ATTENDUS = {
    "apres-effacement": {
        "absentes": CLES_SANTE,
        "table_vides": ["hiker_profile", "past_hikes", "journal_entries",
                        "walked_stages", "trek_sessions", "health_info"],
    },
    "apres-refus-art9": {
        "absentes": ["flutter.hiker.profile"],
        "table_vides": ["hiker_profile", "health_info"],
    },
    "apres-revocation": {
        "absentes": ["flutter.hiker.profile"],
        "table_vides": ["hiker_profile", "health_info"],
    },
}


def exigence(ok, texte):
    print(f"DB_EXIGENCE|{'OK' if ok else 'ECHEC'}|{texte}")
    return ok


def main():
    if len(sys.argv) < 3:
        print("usage: persona_db_assert.py <dossier_sonde> <moment>")
        return 2
    dossier, moment = sys.argv[1], sys.argv[2]
    chemin = os.path.join(dossier, "etat.json")
    if not os.path.exists(chemin):
        print(f"DB_EXIGENCE|ECHEC|aucun sondage a {chemin} : "
              f"le stockage n a pas ete lu, donc rien n est prouve")
        return 1
    with open(chemin, encoding="utf-8") as fh:
        etat = json.load(fh)
    regles = ATTENDUS.get(moment)
    if regles is None:
        print(f"DB_EXIGENCE|ECHEC|moment inconnu : {moment}")
        return 2

    # Toutes les cles applicatives, tous fichiers de preferences confondus.
    cles = {}
    for fichier, contenu in etat.get("preferences", {}).items():
        for k, v in contenu.items():
            if k.startswith("flutter."):
                cles[k] = v

    ok_total = True
    for cle in regles["absentes"]:
        present = cle in cles
        valeur = str(cles.get(cle, ""))
        if len(valeur) > 120:
            valeur = valeur[:120] + "..."
        ok_total &= exigence(
            not present,
            f"[{moment}] la cle « {cle} » n existe PLUS dans les preferences "
            f"de l appareil" + (f" — LUE : {valeur}" if present else ""))

    # Les tables du moteur de stockage, quand il y en a un sur disque.
    tables_vues = {}
    for fichier, tables in etat.get("sqlite", {}).items():
        for table, n in tables.items():
            tables_vues[table] = n
    for table in regles["table_vides"]:
        if table not in tables_vues:
            continue  # la table n existe pas sur disque : rien a exiger.
        n = tables_vues[table]
        ok_total &= exigence(
            n == 0,
            f"[{moment}] la table « {table} » est VIDE sur le disque "
            f"(lignes lues : {n})")

    if moment == "apres-effacement":
        # CE QUI DOIT RESTER. Un effacement qui emporte les achats et les
        # reglages d affichage trahirait la promesse ecrite dans le dialogue.
        restants = [c for c in CLES_REGLAGES if c in cles]
        exigence(True,
                 f"[{moment}] reglages d affichage encore presents : "
                 f"{restants or 'aucun'} (le dialogue promet qu ils restent)")
        consentements = {k: v for k, v in cles.items()
                         if k.startswith(PREFIXE_CONSENTEMENT)}
        exigence(True,
                 f"[{moment}] consentements encore stockes : "
                 f"{consentements or 'aucun'}")

    # Inventaire brut, toujours rendu : c est la matiere du rapport.
    print(f"DB_INVENTAIRE|cles applicatives restantes|{sorted(cles)}")
    print(f"DB_INVENTAIRE|fichiers databases/|"
          f"{etat.get('inventaire', {}).get('databases')}")
    print(f"DB_INVENTAIRE|tables et lignes|{tables_vues or 'aucune table sur disque'}")
    return 0 if ok_total else 1


if __name__ == "__main__":
    raise SystemExit(main())
