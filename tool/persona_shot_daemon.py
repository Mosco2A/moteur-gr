#!/usr/bin/env python3
"""Demon host-side de capture des personas (cycle 2/3).

Surveille un flux de marqueurs `PERSONA_SHOT|<nom>` imprimes par le harnais
integration_test et declenche `adb exec-out screencap` pour ecrire un PNG par
marqueur dans le dossier de captures. Robuste carte GL / trek actif (le driver
ne peut pas se deconnecter quand un isolate de fond tourne).

Deux SOURCES de marqueurs :
  * `adb logcat` (par defaut) — voie utilisee avec `flutter drive` : les `print`
    du test remontent dans logcat (tag flutter:I).
  * un FICHIER LOG (option `--logfile <path>`) — voie utilisee avec
    `flutter test` : les `print` du test vont sur la sortie du listener (le
    fichier de log redirige), PAS dans logcat. On tail alors ce fichier en
    direct. Le harnais laisse ~700 ms (`kShotWait`) apres le marqueur, ce qui
    donne au demon le temps de declencher `screencap` sur l'ecran courant.

Usage:
  python tool/persona_shot_daemon.py <serial> <captures_dir> [--logfile <path>]
"""
import subprocess
import sys
import os
import re
import time

MARK = re.compile(r"PERSONA_SHOT\|([A-Za-z0-9_\-]+)")


def _iter_logcat(serial):
    """Genere les lignes de `adb logcat` (voie flutter drive)."""
    subprocess.run(["adb", "-s", serial, "logcat", "-c"], check=False)
    proc = subprocess.Popen(
        ["adb", "-s", serial, "logcat", "-v", "brief", "flutter:I", "*:S"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    assert proc.stdout is not None
    try:
        for line in proc.stdout:
            yield line
    finally:
        proc.terminate()


def _iter_logfile(path):
    """Tail -f d'un fichier de log (voie flutter test).

    On attend l'apparition du fichier, puis on lit les nouvelles lignes en
    continu. On se place a la FIN a l'ouverture pour ne pas rejouer d'anciens
    marqueurs d'un run precedent.
    """
    while not os.path.exists(path):
        time.sleep(0.2)
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        fh.seek(0, os.SEEK_END)
        while True:
            line = fh.readline()
            if line:
                yield line
            else:
                time.sleep(0.2)


def main() -> int:
    serial = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "data/captures_personas_cycle2"
    logfile = None
    if "--logfile" in sys.argv:
        i = sys.argv.index("--logfile")
        logfile = sys.argv[i + 1] if i + 1 < len(sys.argv) else None
    os.makedirs(out_dir, exist_ok=True)

    source = _iter_logfile(logfile) if logfile else _iter_logcat(serial)
    src_desc = f"logfile={logfile}" if logfile else "logcat"
    print(f"[shot-daemon] serial={serial} out={out_dir} src={src_desc} — en ecoute",
          flush=True)
    seen = 0
    try:
        for line in source:
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
    print(f"[shot-daemon] fin — {seen} captures", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
