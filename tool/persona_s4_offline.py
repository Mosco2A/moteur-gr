#!/usr/bin/env python3
"""Coupe le reseau pendant la fenetre OFFLINE du persona S4 Ines, puis le
retablit.

Le harnais S4 ouvre une fenetre OFFLINE d'environ 25 s (apres la capture
`06_carte_online`) pendant laquelle on verifie que le contenu premium reste
accessible sans reseau (LE point sensible : le payeur ne doit jamais etre
bloque hors-ligne). Ce script host-side coupe wifi + data au bon moment, puis
retablit tout a la fin.

Usage:
  python tool/persona_s4_offline.py <serial>
"""
import subprocess
import sys
import time


def sh(serial, *args):
    return subprocess.run(
        ["adb", "-s", serial, *args],
        check=False, capture_output=True, text=True,
    )


def main() -> int:
    serial = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    # Laisse le scenario demarrer + parcourir online (boot, onboarding, achat,
    # entrainement online, carte online) avant de couper. ~55 s de marge.
    print("[s4-offline] attente avant coupure (~55 s)...", flush=True)
    time.sleep(55)
    print("[s4-offline] COUPURE reseau (airplane on + wifi/data off)", flush=True)
    sh(serial, "shell", "settings", "put", "global", "airplane_mode_on", "1")
    sh(serial, "shell", "svc", "wifi", "disable")
    sh(serial, "shell", "svc", "data", "disable")
    # Fenetre offline du test (~25 s) + marge de re-parcours.
    time.sleep(45)
    print("[s4-offline] RETABLISSEMENT reseau", flush=True)
    sh(serial, "shell", "settings", "put", "global", "airplane_mode_on", "0")
    sh(serial, "shell", "svc", "wifi", "enable")
    sh(serial, "shell", "svc", "data", "enable")
    print("[s4-offline] fin", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
