#!/usr/bin/env python3
"""SONDE DU STOCKAGE REEL DE L APPLICATION (tache 559, passe 4).

POURQUOI ELLE EXISTE. Retour de Chris, mot pour mot : « Tu verifie aussi ce
quo s'ecrit en base de donnees j'espere ». Toute la campagne lisait ce que
l ECRAN affiche ; les tests unitaires lisent les repositories. Personne
n ouvrait le stockage REEL de l appareil. Le lot M a montre que le disque
pouvait etre propre pendant que la memoire vive servait encore des donnees
effacees ; le cas symetrique — un ecran vide au-dessus d un stockage qui
contient encore — est tout aussi possible, et invisible a qui ne regarde qu un
seul cote.

CE QU ELLE FAIT. Sur un build DEBUG, `run-as` donne acces au dossier prive de
l application. La sonde copie sur l hote, a un instant nomme :
  * tous les fichiers de preferences (shared_prefs/*.xml) — c est la source
    DURABLE de la fiche randonneur, des randos passees et du reste ;
  * tous les fichiers du dossier databases/ (moteur Drift), s il y en a ;
  * l inventaire de app_flutter/ et files/.
Puis elle OUVRE les fichiers .db copies avec le module sqlite3 de Python, cote
Windows : aucun outil n est requis sur l image Android, et on ne renonce pas
parce qu un binaire manque sur l appareil.

Elle rend un rapport lisible ET un fichier machine (etat.json) : noms de
tables, nombre de lignes par table, et toutes les cles de preferences avec
leur valeur. C est ce fichier que la verification compare a ce qui DEVRAIT
rester.

Usage:
  python tool/persona_db_probe.py <libelle> <dossier_sortie> [--serial S]
"""
import json
import os
import re
import sqlite3
import subprocess
import sys
import xml.etree.ElementTree as ET

PKG = "com.only1cent.moteur_gr"
BASE = f"/data/data/{PKG}"


def sh(serial, commande, binaire=False):
    """Execute une commande dans le shell de l appareil.

    MSYS_NO_PATHCONV=1 : Git Bash convertit les chemins Unix et casse la
    commande (« C:/Program: No such file or directory »). On neutralise la
    conversion et on garde la commande entre guillemets.
    """
    env = dict(os.environ, MSYS_NO_PATHCONV="1")
    args = ["adb", "-s", serial, "exec-out" if binaire else "shell", commande]
    r = subprocess.run(args, capture_output=True, env=env, timeout=120)
    return r.stdout if binaire else (r.stdout or b"").decode("utf-8", "replace")


def lister(serial, dossier):
    sortie = sh(serial, f'run-as {PKG} ls -1 {dossier} 2>/dev/null')
    return [l.strip() for l in sortie.splitlines() if l.strip()]


def copier(serial, distant, local):
    """Copie un fichier prive vers l hote, en binaire, via run-as."""
    contenu = sh(serial, f'run-as {PKG} cat {distant}', binaire=True)
    if not contenu:
        return 0
    with open(local, "wb") as fh:
        fh.write(contenu)
    return len(contenu)


def lire_preferences(chemin):
    """Toutes les cles d un fichier de preferences Android, avec leur valeur."""
    cles = {}
    try:
        racine = ET.parse(chemin).getroot()
    except Exception as exc:
        return {"_erreur_lecture": str(exc)}
    for noeud in racine:
        nom = noeud.get("name")
        if nom is None:
            continue
        if noeud.tag == "string":
            cles[nom] = noeud.text or ""
        elif noeud.tag in ("int", "long", "float", "boolean"):
            cles[nom] = noeud.get("value")
        elif noeud.tag == "set":
            cles[nom] = [e.text or "" for e in noeud]
        else:
            cles[nom] = f"<{noeud.tag}>"
    return cles


def lire_sqlite(chemin):
    """Tables et nombre de lignes d un fichier SQLite copie sur l hote."""
    resultat = {}
    try:
        cx = sqlite3.connect(f"file:{chemin}?mode=ro", uri=True)
    except Exception as exc:
        return {"_erreur_ouverture": str(exc)}
    try:
        tables = [r[0] for r in cx.execute(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name").fetchall()]
        for table in tables:
            try:
                n = cx.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
            except Exception as exc:
                n = f"illisible: {exc}"
            resultat[table] = n
    except Exception as exc:
        resultat["_erreur_inventaire"] = str(exc)
    finally:
        cx.close()
    return resultat


def main():
    if len(sys.argv) < 3:
        print("usage: persona_db_probe.py <libelle> <dossier_sortie> "
              "[--serial S]")
        return 2
    libelle = re.sub(r"[^A-Za-z0-9_-]", "_", sys.argv[1])
    sortie = sys.argv[2]
    serial = "emulator-5554"
    if "--serial" in sys.argv:
        serial = sys.argv[sys.argv.index("--serial") + 1]

    dossier = os.path.join(sortie, libelle)
    os.makedirs(dossier, exist_ok=True)
    etat = {"libelle": libelle, "preferences": {}, "sqlite": {},
            "inventaire": {}}

    # 1. Preferences — la source durable.
    # SEUL LE FICHIER DE L APPLICATION EST COPIE, ET C EST UNE CORRECTION.
    # Copier les cinq XML (Google, WebView, mesure) coutait une dizaine
    # d appels adb : sur un emulateur occupe par un test, la sonde depassait la
    # fenetre que le scenario lui laisse, et le demon manquait les marqueurs
    # suivants — un seul sondage sur sept. On ne copie plus que ce qui porte
    # les donnees de l application.
    for nom in lister(serial, f"{BASE}/shared_prefs"):
        if nom != "FlutterSharedPreferences.xml":
            continue
        local = os.path.join(dossier, nom)
        taille = copier(serial, f"{BASE}/shared_prefs/{nom}", local)
        if taille:
            etat["preferences"][nom] = lire_preferences(local)

    # 2. Fichiers du moteur de stockage, lus cote Windows.
    fichiers = lister(serial, f"{BASE}/databases")
    etat["inventaire"]["databases"] = fichiers
    for nom in fichiers:
        local = os.path.join(dossier, nom)
        taille = copier(serial, f"{BASE}/databases/{nom}", local)
        if taille and nom.endswith(".db"):
            etat["sqlite"][nom] = lire_sqlite(local)

    # 3. Inventaire du reste (on ne copie pas : on constate).
    for coin in ("app_flutter", "files", "no_backup"):
        etat["inventaire"][coin] = lister(serial, f"{BASE}/{coin}")

    with open(os.path.join(dossier, "etat.json"), "w", encoding="utf-8") as fh:
        json.dump(etat, fh, ensure_ascii=False, indent=2)

    # Rapport lisible.
    print(f"[sonde] {libelle}")
    for fichier, cles in etat["preferences"].items():
        interessantes = {k: v for k, v in cles.items()
                         if k.startswith("flutter.")}
        print(f"[sonde]   {fichier} : {len(cles)} cle(s), "
              f"{len(interessantes)} cote application")
        for k in sorted(interessantes):
            valeur = str(interessantes[k])
            if len(valeur) > 160:
                valeur = valeur[:160] + "..."
            print(f"[sonde]     {k} = {valeur}")
    print(f"[sonde]   databases/ : "
          f"{etat['inventaire']['databases'] or 'VIDE'}")
    for nom, tables in etat["sqlite"].items():
        print(f"[sonde]     {nom} : {tables}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
