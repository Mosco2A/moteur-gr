#!/usr/bin/env python3
"""Pousse en BOUCLE les points du trace mare-a-mare-centre pendant TOUTE la
duree d'un run persona (utile quand la phase MARCHER arrive tard, ex: S1 qui
joue d'abord toute la preparation). Contrairement a persona_s3_geo_push (one-shot
avec petit delai), ici on boucle sur le trace en continu jusqu'a un nombre de
cycles/duree max, pour que geolocator lise toujours une position mockee des que
la carte s'ouvre. Host-side, hors appli.

Usage: python tool/persona_geo_loop.py <serial> [duree_s]
"""
import subprocess, sys, time

TRACK = [
    (42.0156, 9.4039), (42.0100, 9.3900), (42.0020, 9.3780), (41.9950, 9.3700),
    (41.9870, 9.3500), (41.9780, 9.3300), (41.9700, 9.3100), (41.9630, 9.2980),
    (41.9567, 9.2864), (41.9550, 9.2800), (41.9520, 9.2650), (41.9480, 9.2400),
]

def main() -> int:
    serial = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    dur = int(sys.argv[2]) if len(sys.argv) > 2 else 600
    end = time.time() + dur
    i = 0
    while time.time() < end:
        lat, lon = TRACK[i % len(TRACK)]
        r = subprocess.run(["adb", "-s", serial, "emu", "geo", "fix", str(lon), str(lat)],
                           check=False, capture_output=True, text=True)
        print(f"[geo-loop] point {i:03d} lon={lon} lat={lat} rc={r.returncode}", flush=True)
        i += 1
        time.sleep(6)
    print("[geo-loop] fin", flush=True)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
