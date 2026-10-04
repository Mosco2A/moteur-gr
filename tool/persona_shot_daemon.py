#!/usr/bin/env python3
"""Demon host-side de capture des personas (cycle 3 — instrumente, tache 665).

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
    direct. Le harnais laisse `kShotWait` (3000 ms depuis la tache 665) apres le
    marqueur, ce qui donne au demon le temps de declencher `screencap` sur
    l'ecran courant.

CE QUI A CHANGE A LA TACHE 665, ET POURQUOI. Au 645-05b (memoire #101082) des
captures persona montraient L'ECRAN SUIVANT : plusieurs captures d'ecrans
differents portaient le MEME hash, et un run a rendu 0 capture pour 65
marqueurs. La cause mesurable est une DERIVE CUMULEE : la boucle etait
SEQUENTIELLE (lire un marqueur, faire le screencap, puis seulement lire le
suivant). Quand un `adb exec-out screencap` coute plus que l'intervalle entre
deux marqueurs, chaque capture part un peu plus tard que la precedente, le
retard s'accumule, et la capture finit par tomber sur l'ecran d'apres. Trois
corrections :
  1. LECTURE ET CAPTURE DECOUPLEES : un fil lit les marqueurs et les pousse dans
     une file, des ouvriers tirent et capturent. L'heure de DEPART d'un
     screencap ne depend plus de la duree du precedent — la derive ne peut plus
     s'accumuler.
  2. TOUT EST DATE DANS UN MANIFESTE (`_shots.jsonl`) : heure ou le marqueur est
     vu, heure de depart et de fin du screencap, octets, code de retour. Le
     retard devient MESURABLE au lieu d'etre devine, et `persona_shot_check.py`
     refuse le run si un marqueur n'a pas sa capture, si deux captures portent
     le meme hash, ou si le retard depasse le budget.
  3. TRONCATURE TOLEREE : si le fichier de log est recree ou tronque sous le
     demon (re-run, redirection systeme), on repart du debut au lieu de rester
     muet derriere l'ancienne position — c'est le mode d'echec « 0 capture ».

Usage:
  python tool/persona_shot_daemon.py <serial> <captures_dir> [--logfile <path>]
         [--workers N] [--manifest <path>]
"""
import json
import os
import queue
import re
import subprocess
import sys
import threading
import time

MARK = re.compile(r"PERSONA_SHOT\|([A-Za-z0-9_\-]+)")

# Nombre d'ouvriers de capture. 1 = ancien comportement sequentiel (garde pour
# pouvoir REPRODUIRE la derive et prouver la correction).
DEFAULT_WORKERS = 2

# Sentinelle de fin de file.
_STOP = object()


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

    TRONCATURE TOLEREE (tache 665) : si la taille du fichier redescend sous
    notre position de lecture, c'est que le fichier a ete recree ou tronque
    (re-run, `Start-Process -RedirectStandardOutput` qui remet a zero). Sans
    cette garde on reste bloque derriere l'ancienne position et on ne voit PLUS
    AUCUN marqueur : c'est le mode d'echec « 0 capture pour 65 marqueurs ».
    """
    while not os.path.exists(path):
        time.sleep(0.2)
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        fh.seek(0, os.SEEK_END)
        while True:
            line = fh.readline()
            if line:
                yield line
                continue
            try:
                taille = os.path.getsize(path)
            except OSError:
                taille = None
            if taille is not None and taille < fh.tell():
                print(
                    f"[shot-daemon] log tronque ({taille} < {fh.tell()}) — "
                    "relecture depuis le debut",
                    flush=True,
                )
                fh.seek(0, os.SEEK_SET)
                continue
            time.sleep(0.05)


def _capture(serial, out_dir, name, t_seen, manifest_lock, manifest_path):
    """Un screencap, date de bout en bout et inscrit au manifeste."""
    path = os.path.join(out_dir, f"{name}.png")
    t_start = time.time()
    rc = -1
    erreur = None
    try:
        with open(path, "wb") as fh:
            r = subprocess.run(
                ["adb", "-s", serial, "exec-out", "screencap", "-p"],
                stdout=fh,
                check=False,
                timeout=20,
            )
        rc = r.returncode
    except Exception as exc:  # pragma: no cover - best effort
        erreur = f"{type(exc).__name__}: {exc}"
    t_end = time.time()
    sz = os.path.getsize(path) if os.path.exists(path) else 0
    entree = {
        "nom": name,
        "fichier": os.path.basename(path),
        "vu_a": round(t_seen, 3),
        "capture_depart": round(t_start, 3),
        "capture_fin": round(t_end, 3),
        "retard_ms": int((t_start - t_seen) * 1000),
        "duree_ms": int((t_end - t_start) * 1000),
        "octets": sz,
        "rc": rc,
    }
    if erreur:
        entree["erreur"] = erreur
    with manifest_lock:
        with open(manifest_path, "a", encoding="utf-8") as mf:
            mf.write(json.dumps(entree, ensure_ascii=False) + "\n")
    etat = "ECHEC" if (erreur or rc != 0 or sz == 0) else "ok"
    print(
        f"[shot-daemon] {etat} {name}.png ({sz} octets) rc={rc} "
        f"retard={entree['retard_ms']}ms duree={entree['duree_ms']}ms",
        flush=True,
    )


def main() -> int:
    serial = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "data/captures_personas_cycle2"

    def _opt(nom, defaut=None):
        if nom in sys.argv:
            i = sys.argv.index(nom)
            return sys.argv[i + 1] if i + 1 < len(sys.argv) else defaut
        return defaut

    logfile = _opt("--logfile")
    workers = int(_opt("--workers", DEFAULT_WORKERS) or DEFAULT_WORKERS)
    os.makedirs(out_dir, exist_ok=True)
    manifest_path = _opt("--manifest") or os.path.join(out_dir, "_shots.jsonl")
    # Le manifeste est REMIS A ZERO a chaque run : il decrit CE run, et le
    # controle de fin de run le lit comme tel.
    with open(manifest_path, "w", encoding="utf-8"):
        pass

    source = _iter_logfile(logfile) if logfile else _iter_logcat(serial)
    src_desc = f"logfile={logfile}" if logfile else "logcat"
    print(
        f"[shot-daemon] serial={serial} out={out_dir} src={src_desc} "
        f"ouvriers={workers} manifeste={manifest_path} — en ecoute",
        flush=True,
    )

    travail: "queue.Queue" = queue.Queue()
    manifest_lock = threading.Lock()
    compte = {"n": 0}
    compte_lock = threading.Lock()

    def ouvrier():
        while True:
            item = travail.get()
            try:
                if item is _STOP:
                    return
                name, t_seen = item
                _capture(serial, out_dir, name, t_seen, manifest_lock, manifest_path)
                with compte_lock:
                    compte["n"] += 1
            except Exception as exc:  # noqa: BLE001
                # UN OUVRIER NE MEURT PLUS D'UNE CAPTURE (tache 676). Tout ce
                # qui n'etait pas dans le `try` de `_capture` (taille du
                # fichier, ecriture du manifeste, impression) tuait le FIL :
                # les deux ouvriers morts, la file n'etait plus servie, le
                # demon ne capturait plus rien et ne disait rien -- c'est le
                # mode d'echec « 14 captures pour 16 marqueurs, puis silence »
                # mesure le 04/10. On le dit, et on continue.
                print(
                    f"[shot-daemon] OUVRIER : {item!r} perdu ({type(exc).__name__}: {exc})",
                    flush=True,
                )
            finally:
                travail.task_done()

    fils = [threading.Thread(target=ouvrier, daemon=True) for _ in range(workers)]
    for f in fils:
        f.start()

    try:
        for line in source:
            m = MARK.search(line)
            if not m:
                continue
            # L'HEURE EST PRISE ICI, au plus tot : c'est la reference du retard.
            travail.put((m.group(1), time.time()))
    except KeyboardInterrupt:
        pass
    finally:
        # On laisse les captures en vol se terminer avant de rendre la main :
        # sinon la derniere capture d'un run est perdue a l'arret du demon.
        travail.join()
        for _ in fils:
            travail.put(_STOP)
    print(f"[shot-daemon] fin — {compte['n']} captures", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
