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

# LIBELLES CIBLES. Ordre = priorite : on tape le premier trouve.
#
# TACHE 544 — DEUX DEFAUTS CORRIGES ICI, TROUVES EN REJOUANT S1.
#   1. La liste etait en ANGLAIS alors que l emulateur est en FRANCAIS. Le
#      dialogue de localisation propose « Lorsque vous utilisez l appli »,
#      qui ne figurait nulle part : il n etait donc JAMAIS ferme.
#   2. La comparaison etait une EGALITE STRICTE. Android affiche « Uniquement
#      cette fois-ci » ; la liste portait « Uniquement cette fois ». Un suffixe
#      de deux caracteres suffisait a rater le bouton.
# Consequence mesuree : le dialogue de localisation ET le formulaire de
# consentement publicitaire recouvraient l ecran Faisabilite pendant tout le
# pas 12c de S1, ce qui produisait des echecs ressemblant a des defauts produit
# (capture S1_Lea_12c_faisabilite_verdict_reel.png a l appui).
BUTTON_LABELS = [
    # Permission de localisation (FR puis EN).
    "Lorsque vous utilisez l'appli", "Lorsque vous utilisez l’appli",
    "While using the app",
    "Uniquement cette fois-ci", "Uniquement cette fois", "Only this time",
    "Autoriser tout le temps", "Allow all the time",
    "Autoriser", "Allow",
    # Consentement publicitaire (UMP/AdMob).
    "Ne pas consentir", "Do not consent", "Consentir", "Consent",
    "J'accepte", "J’accepte", "Tout accepter",
    # Generiques, en dernier.
    "OK", "Continuer", "Continue",
]


def _dump(serial):
    """Arbre de l ecran courant, en XML.

    TACHE 544 — TROISIEME DEFAUT CORRIGE ICI, ET C EST LE PIRE.
    La voie `exec-out uiautomator dump /dev/tty` rend « Killed » sur cette image
    Android (verifie a la main : sortie « Killed », rien d autre). Le demon ne
    recevait donc JAMAIS d arbre, ne trouvait JAMAIS de bouton, et ne tapait
    JAMAIS rien — tout en tournant sans erreur et sans rien dire. Un veilleur
    qui ne veille pas, exactement le defaut qu on venait de corriger dans le
    harnais Flutter. On passe par un FICHIER, qui marche, et on garde l ancienne
    voie en repli.
    """
    out = ""
    subprocess.run(
        ["adb", "-s", serial, "shell", "uiautomator", "dump",
         "/sdcard/persona_ui.xml"],
        capture_output=True, text=True, timeout=20,
    )
    r = subprocess.run(
        ["adb", "-s", serial, "shell", "cat", "/sdcard/persona_ui.xml"],
        capture_output=True, text=True, timeout=20,
    )
    out = r.stdout or ""
    if "<hierarchy" not in out:
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
            ll = label.lower()
            # Egalite OU prefixe : « Uniquement cette fois » doit attraper
            # « Uniquement cette fois-ci ». On ne fait PAS un `in` complet, qui
            # taperait « Ne pas autoriser » en cherchant « Autoriser ».
            if ll == wl or ll.startswith(wl) or wl.startswith(ll):
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
