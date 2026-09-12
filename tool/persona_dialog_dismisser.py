#!/usr/bin/env python3
"""Demon host-side qui FERME automatiquement les dialogs BLOQUANTS pendant un
rejeu persona (harnais, hors appli). Formulaire consentement PUB (UMP/AdMob) +
dialogs SYSTEME de permission Android 13 (POST_NOTIFICATIONS, localisation) sont
des overlays NON-Flutter qui recouvrent l'ecran et empechent le harnais de
trouver SOS / Terminer. Ce demon boucle uiautomator dump -> input tap sur un
bouton connu. 100% host-side (adb), aucune modif appli/pubspec.

Usage: python tool/persona_dialog_dismisser.py <serial> [duree_s]
"""
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

BUTTON_LABELS = [
    "While using the app", "Only this time", "Allow", "Autoriser",
    "Autoriser tout le temps", "Allow all the time",
    "Uniquement cette fois",
    "Do not consent", "Ne pas consentir", "Consent", "Consentir",
    "OK", "Continue", "Continuer",
]


def _dump(serial):
    r = subprocess.run(
        ["adb", "-s", serial, "exec-out", "uiautomator", "dump", "/dev/tty"],
        capture_output=True, text=True, timeout=15,
    )
    out = r.stdout or ""
    i = out.find("<?xml")
    if i == -1:
        i = out.find("<hierarchy")
    return out[i:] if i != -1 else ""


def _center(bounds):
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds or "")
    if not m:
        return None
    x1, y1, x2, y2 = map(int, m.groups())
    return (x1 + x2) // 2, (y1 + y2) // 2


def _find_and_tap(serial, xml):
    try:
        root = ET.fromstring(xml)
    except Exception:
        return False
    nodes = []
    for node in root.iter("node"):
        txt = (node.get("text") or "").strip()
        desc = (node.get("content-desc") or "").strip()
        label = txt or desc
        if label:
            nodes.append((label, node.get("bounds")))
    for want in BUTTON_LABELS:
        wl = want.lower()
        for label, bounds in nodes:
            if label.lower() == wl:
                c = _center(bounds)
                if c:
                    subprocess.run(
                        ["adb", "-s", serial, "shell", "input", "tap",
                         str(c[0]), str(c[1])],
                        capture_output=True, text=True, timeout=10,
                    )
                    print("[dialog] tap '" + label + "' @ " + str(c), flush=True)
                    return True
    return False


def main():
    serial = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    dur = int(sys.argv[2]) if len(sys.argv) > 2 else 600
    end = time.time() + dur
    print("[dialog] serial=" + serial + " duree=" + str(dur) + "s", flush=True)
    taps = 0
    while time.time() < end:
        try:
            xml = _dump(serial)
            if xml and _find_and_tap(serial, xml):
                taps += 1
                time.sleep(0.8)
                continue
        except Exception as exc:
            print("[dialog] err " + str(exc), flush=True)
        time.sleep(1.2)
    print("[dialog] fin -- " + str(taps) + " dialogs fermes", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
