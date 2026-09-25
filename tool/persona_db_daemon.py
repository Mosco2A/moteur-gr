#!/usr/bin/env python3
"""DEMON DE SONDAGE DU STOCKAGE, declenche PAR LE SCENARIO (tache 559, passe 4).

Le scenario s execute SUR L APPAREIL : il ne peut ni lire le dossier prive de
l application, ni lancer adb. Il peut en revanche IMPRIMER un marqueur a
l instant precis ou la mesure a du sens — juste apres un effacement, juste
apres un refus de consentement. Ce demon tail le log du run, et a chaque
marqueur `PERSONA_DB_PROBE|<libelle>` il lance la sonde host-side.

Meme grammaire que le demon de captures, et meme reparation : on lit PAR
CHEMIN avec un offset d octets, et on repart de zero si le fichier retrecit —
un descripteur garde ouvert sur un log que PowerShell reecrit est un veilleur
qui ne veille plus, en silence.

Usage:
  python tool/persona_db_daemon.py <logfile> <dossier_sortie> [--serial S]
"""
import os
import re
import subprocess
import sys
import time

MARQUEUR = re.compile(r"PERSONA_DB_PROBE\|([A-Za-z0-9_-]+)")


def lignes(chemin):
    while not os.path.exists(chemin):
        time.sleep(0.2)
    offset = 0
    reste = ""
    while True:
        try:
            taille = os.path.getsize(chemin)
        except OSError:
            time.sleep(0.2)
            continue
        if taille < offset:
            offset = 0
            reste = ""
        if taille > offset:
            try:
                with open(chemin, "rb") as fh:
                    fh.seek(offset)
                    brut = fh.read()
                    offset = fh.tell()
            except OSError:
                time.sleep(0.2)
                continue
            bloc = reste + brut.decode("utf-8", "replace")
            parts = bloc.split("\n")
            reste = parts.pop()
            for ligne in parts:
                yield ligne
        else:
            time.sleep(0.2)


def main():
    if len(sys.argv) < 3:
        print("usage: persona_db_daemon.py <logfile> <dossier_sortie>")
        return 2
    logfile = sys.argv[1]
    sortie = sys.argv[2]
    serial = "emulator-5554"
    if "--serial" in sys.argv:
        serial = sys.argv[sys.argv.index("--serial") + 1]
    os.makedirs(sortie, exist_ok=True)
    outil = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                         "persona_db_probe.py")
    print(f"[sonde-demon] log={logfile} sortie={sortie} — en ecoute",
          flush=True)
    vus = 0
    for ligne in lignes(logfile):
        m = MARQUEUR.search(ligne)
        if not m:
            continue
        libelle = m.group(1)
        vus += 1
        print(f"[sonde-demon] sondage « {libelle} »", flush=True)
        r = subprocess.run(
            [sys.executable, outil, libelle, sortie, "--serial", serial],
            capture_output=True, text=True, timeout=300,
        )
        for l in (r.stdout or "").splitlines():
            print(l, flush=True)
        if r.returncode != 0:
            print(f"[sonde-demon] ECHEC sondage {libelle} : {r.stderr[:400]}",
                  flush=True)
    print(f"[sonde-demon] fin — {vus} sondage(s)", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
