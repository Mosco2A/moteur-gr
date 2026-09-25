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

    CORRIGE LE 25/09 (tache 559) — ZERO CAPTURE SUR UN RUN COMPLET. Le run S11
    a joue ses onze pas, imprime ses onze marqueurs dans le log, et le demon
    n'a ecrit AUCUNE image : il gardait un descripteur ouvert en permanence et
    se placait a la FIN a l'ouverture. Quand PowerShell (`Out-File -Append`)
    reecrit le fichier au lieu de l'allonger, ce descripteur pointe sur un
    fichier qui ne grandit plus — le demon ecoute un fichier mort, en silence,
    et un run entier se termine sans la moindre preuve a montrer.

    On lit desormais PAR CHEMIN, avec un offset d'octets : a chaque tour on
    rouvre le fichier, on reprend ou on s'etait arrete, et si le fichier a
    RETRECI (troncature ou remplacement) on repart de zero. Le runner garantit
    un log VIERGE au demarrage (il archive le precedent), donc lire depuis le
    debut ne rejoue jamais les marqueurs d'un run passe.
    """
    while not os.path.exists(path):
        time.sleep(0.2)
    offset = 0
    reste = ""
    while True:
        try:
            taille = os.path.getsize(path)
        except OSError:
            time.sleep(0.2)
            continue
        if taille < offset:
            # Fichier tronque ou remplace : on repart du debut.
            offset = 0
            reste = ""
        if taille > offset:
            try:
                # Lecture BINAIRE : l'offset est un nombre d'OCTETS, comme
                # `getsize`. En mode texte, `tell()` rend une position opaque
                # qu'on ne peut pas comparer a une taille de fichier — c'est
                # exactement le genre de decalage silencieux qui fait qu'un
                # garde-fou echoue sans rien dire.
                with open(path, "rb") as fh:
                    fh.seek(offset)
                    brut = fh.read()
                    offset = fh.tell()
            except OSError:
                time.sleep(0.2)
                continue
            bloc = reste + brut.decode("utf-8", errors="replace")
            lignes = bloc.split("\n")
            reste = lignes.pop()
            for ligne in lignes:
                yield ligne
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
