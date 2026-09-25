#!/usr/bin/env python3
"""Veilleur du formulaire de consentement PUBLICITAIRE (tache 559, passe finale).

POURQUOI IL EXISTE. Le formulaire Google UMP (« Publisher Test Ads ») recouvre
l application en pleine session. Il n est PAS dans l arbre Flutter : aucun test
Flutter ne peut le voir. Il ne met pas non plus l activite en pause : la veille
« ecran systeme » du harnais ne le voit pas davantage. En premiere passe, seules
les CAPTURES l ont montre — c est-a-dire par hasard.

CE QU IL FAIT. Il interroge l ecran REEL toutes les N secondes (uiautomator) et
ecrit une ligne chaque fois que le formulaire est au premier plan, avec l heure.
A la fin, il rend un compte : combien de fois vu, sur combien de regards. Zero
vu sur une session longue est une PREUVE ; zero capture ne l etait pas.

Usage: python tool/persona_ads_watcher.py <serial> <duree_s> [intervalle_s]
"""
import subprocess
import sys
import time

MOTIFS = (
    "Publisher Test Ads",
    "Do not consent",
    "Ne pas consentir",
    "asks for your consent",
)


def dump(serial):
    """Arbre de l ecran courant. Passe par un FICHIER : la voie /dev/tty rend
    « Killed » sur cette image Android (constate tache 544)."""
    subprocess.run(
        ["adb", "-s", serial, "shell", "uiautomator", "dump",
         "/sdcard/persona_ads.xml"],
        capture_output=True, text=True, timeout=25,
    )
    r = subprocess.run(
        ["adb", "-s", serial, "shell", "cat", "/sdcard/persona_ads.xml"],
        capture_output=True, text=True, timeout=25,
    )
    return r.stdout or ""


def main():
    serial = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    duree = float(sys.argv[2]) if len(sys.argv) > 2 else 600.0
    pas = float(sys.argv[3]) if len(sys.argv) > 3 else 5.0
    fin = time.time() + duree
    regards = 0
    vus = 0
    print(f"[ads-watcher] serial={serial} duree={duree}s pas={pas}s", flush=True)
    while time.time() < fin:
        try:
            arbre = dump(serial)
        except Exception as exc:
            print(f"[ads-watcher] dump impossible : {exc}", flush=True)
            time.sleep(pas)
            continue
        regards += 1
        if any(m in arbre for m in MOTIFS):
            vus += 1
            horodate = time.strftime("%H:%M:%S")
            print(f"[ads-watcher] FORMULAIRE PUB AU PREMIER PLAN a {horodate}",
                  flush=True)
        time.sleep(pas)
    print(f"[ads-watcher] BILAN : formulaire vu {vus} fois sur {regards} "
          f"regards", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
