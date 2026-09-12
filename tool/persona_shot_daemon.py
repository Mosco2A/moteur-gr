#!/usr/bin/env python3
"""Demon host-side de capture des personas (cycle 2).

Surveille `adb logcat` (marqueur `PERSONA_SHOT|<nom>` imprime par le harnais
integration_test) et declenche `adb exec-out screencap` pour ecrire un PNG par
marqueur dans le dossier de captures. Robuste carte GL / trek actif (le driver
ne peut pas se deconnecter quand un isolate de fond tourne).

Usage:
  python tool/persona_shot_daemon.py <serial> <captures_dir>
"""
import subprocess
import sys
import os
import re

MARK = re.compile(r"PERSONA_SHOT\|([A-Za-z0-9_\-]+)")


def main() -> int:
    serial = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "data/captures_personas_cycle2"
    os.makedirs(out_dir, exist_ok=True)

    # On vide le buffer logcat pour ne pas rejouer d'anciens marqueurs.
    subprocess.run(["adb", "-s", serial, "logcat", "-c"], check=False)

    proc = subprocess.Popen(
        ["adb", "-s", serial, "logcat", "-v", "brief", "flutter:I", "*:S"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    print(f"[shot-daemon] serial={serial} out={out_dir} — en ecoute", flush=True)
    seen = 0
    try:
        assert proc.stdout is not None
        for line in proc.stdout:
            m = MARK.search(line)
            if not m:
                continue
            name = m.group(1)
            path = os.path.join(out_dir, f"{name}.png")
            try:
                with open(path, "wb") as fh:
                    r = subprocess.run(
                        ["adb", "-s", serial, "exec-out", "screencap", "-p"],
                        stdout=fh,
                        check=False,
                        timeout=20,
                    )
                sz = os.path.getsize(path) if os.path.exists(path) else 0
                seen += 1
                print(f"[shot-daemon] {name}.png ({sz} octets) rc={r.returncode}", flush=True)
            except Exception as exc:  # pragma: no cover - best effort
                print(f"[shot-daemon] ECHEC {name}: {exc}", flush=True)
    except KeyboardInterrupt:
        pass
    finally:
        proc.terminate()
    print(f"[shot-daemon] fin — {seen} captures", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
