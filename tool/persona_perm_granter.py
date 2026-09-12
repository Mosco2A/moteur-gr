#!/usr/bin/env python3
"""Demon host-side (harnais) qui ACCORDE en boucle toutes les permissions
runtime des que le package apparait, pour que l'appli n'affiche AUCUN dialog
systeme (notification Android 13, localisation, background) pendant le rejeu.
Sans ca, le dialog systeme BLOQUE `_startWithGuard` -> le trek ne passe pas a
`StartOutcome.started` -> pas d'ouverture carte ni d'overlay SOS. Le drive
reinstalle l'appli a chaque run ; on grante donc TOT et en continu. 100%
host-side (adb), aucune modif appli/pubspec.

Usage: python tool/persona_perm_granter.py <serial> <package> [duree_s]
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


def sh(serial, *args):
    return subprocess.run(["adb", "-s", serial, *args],
                          capture_output=True, text=True, timeout=15)


def installed(serial, pkg):
    r = sh(serial, "shell", "pm", "path", pkg)
    return "package:" in (r.stdout or "")


def main():
    serial = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    pkg = sys.argv[2] if len(sys.argv) > 2 else "com.only1cent.moteur_gr"
    dur = int(sys.argv[3]) if len(sys.argv) > 3 else 600
    end = time.time() + dur
    print("[grant] serial=" + serial + " pkg=" + pkg + " duree=" + str(dur) + "s",
          flush=True)
    granted_once = False
    while time.time() < end:
        try:
            if installed(serial, pkg):
                for p in PERMS:
                    sh(serial, "shell", "pm", "grant", pkg, p)
                # exemptions batterie / background
                sh(serial, "shell", "cmd", "appops", "set", pkg,
                   "RUN_IN_BACKGROUND", "allow")
                sh(serial, "shell", "dumpsys", "deviceidle", "whitelist", "+" + pkg)
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