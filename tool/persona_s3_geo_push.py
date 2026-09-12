#!/usr/bin/env python3
"""Pousse ~12 points GPS le long du trace mare-a-mare-centre pendant la fenetre
d'injection du persona S3 Steve (cycle 3).

Le harnais integration_test ouvre une fenetre GPS d'environ 60 s (12 tranches de
~5 s). On pousse un point toutes les ~5 s via `adb emu geo fix <lon> <lat>` pour
que geolocator lise la position mockee et que la carte suive le trace.

Usage:
  python tool/persona_s3_geo_push.py <serial>
"""
import subprocess
import sys
import time

# Points reels du trace (assets/data/mare_a_mare_centre/track.gpx), ~12 points
# du debut vers le sud-ouest. Format (lat, lon).
TRACK = [
    (42.0156, 9.4039),
    (42.0100, 9.3900),
    (42.0020, 9.3780),
    (41.9950, 9.3700),
    (41.9870, 9.3500),
    (41.9780, 9.3300),
    (41.9700, 9.3100),
    (41.9630, 9.2980),
    (41.9567, 9.2864),
    (41.9550, 9.2800),
    (41.9520, 9.2650),
    (41.9480, 9.2400),
]


def main() -> int:
    serial = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    # Petit delai de demarrage pour laisser l'app arriver sur la carte.
    time.sleep(8)
    for i, (lat, lon) in enumerate(TRACK):
        # `emu geo fix` attend l'ordre LON puis LAT.
        r = subprocess.run(
            ["adb", "-s", serial, "emu", "geo", "fix", str(lon), str(lat)],
            check=False,
            capture_output=True,
            text=True,
        )
        print(f"[geo-push] point {i:02d} lon={lon} lat={lat} rc={r.returncode}",
              flush=True)
        time.sleep(5)
    print("[geo-push] fin — trace pousse", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
