#!/usr/bin/env python3
"""Demon host-side (harnais) qui ACCORDE en boucle toutes les permissions
runtime des que le package apparait, pour que l'appli n'affiche AUCUN dialog
systeme (notification Android 13, localisation, background) pendant le rejeu.
Sans ca, le dialog systeme BLOQUE `_startWithGuard` -> le trek ne passe pas a
`StartOutcome.started` -> pas d'ouverture carte ni d'overlay SOS. Le drive
reinstalle l'appli a chaque run ; on grante donc TOT et en continu. 100%
host-side (adb), aucune modif appli/pubspec.

Usage: python tool/persona_perm_granter.py <serial> <package> [duree_s] [--avant-plan]

  --avant-plan : n accorde QUE le premier plan et les notifications, jamais la
                 localisation de FOND. A utiliser pour S1, qui doit voir le
                 pre-vol explique.
"""
import subprocess
import sys
import time

PERMS = [
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_BACKGROUND_LOCATION",
    "android.permission.POST_NOTIFICATIONS",
]

# TACHE 544 — JEU RESTREINT, ET IL EST INDISPENSABLE.
# S1 teste le PRE-VOL EXPLIQUE : l application doit annoncer elle-meme a quoi
# sert le suivi de fond AVANT de le demander. Accorder ACCESS_BACKGROUND_LOCATION
# supprime ce pas et rend le test faux-vert. Mais NE RIEN accorder laisse le
# dialogue de localisation de PREMIER PLAN recouvrir l ecran Faisabilite.
# Ce jeu accorde donc le premier plan et les notifications, et LAISSE le fond
# a l utilisateur : le dialogue parasite disparait, le pas teste reste teste.
PERMS_AVANT_PLAN = [
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.POST_NOTIFICATIONS",
]


def sh(serial, *args):
    return subprocess.run(["adb", "-s", serial, *args],
                          capture_output=True, text=True, timeout=15)


def installed(serial, pkg):
    r = sh(serial, "shell", "pm", "path", pkg)
    return "package:" in (r.stdout or "")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    avant_plan = "--avant-plan" in sys.argv
    serial = args[0] if len(args) > 0 else "emulator-5554"
    pkg = args[1] if len(args) > 1 else "com.only1cent.moteur_gr"
    dur = int(args[2]) if len(args) > 2 else 600
    perms = PERMS_AVANT_PLAN if avant_plan else PERMS
    end = time.time() + dur
    print("[grant] serial=" + serial + " pkg=" + pkg + " duree=" + str(dur)
          + "s jeu=" + ("AVANT-PLAN (fond NON accorde)" if avant_plan
                        else "COMPLET"), flush=True)
    granted_once = False
    while time.time() < end:
        try:
            if installed(serial, pkg):
                for p in perms:
                    sh(serial, "shell", "pm", "grant", pkg, p)
                if not avant_plan:
                    # exemptions batterie / fond — jamais en avant-plan seul,
                    # sinon on retablit par la bande ce qu on refuse.
                    sh(serial, "shell", "cmd", "appops", "set", pkg,
                       "RUN_IN_BACKGROUND", "allow")
                    sh(serial, "shell", "dumpsys", "deviceidle", "whitelist",
                       "+" + pkg)
                if not granted_once:
                    print("[grant] permissions accordees pour " + pkg, flush=True)
                    granted_once = True
        except Exception as exc:
            print("[grant] err " + str(exc), flush=True)
        time.sleep(2)
    print("[grant] fin", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())