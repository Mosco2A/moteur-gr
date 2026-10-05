#!/usr/bin/env python3
"""Coupe le reseau pendant la fenetre OFFLINE du persona S4 Ines, puis le
retablit.

Le harnais S4 ouvre une fenetre OFFLINE d'environ 25 s (apres la capture
`06_carte_online`) pendant laquelle on verifie que le contenu premium reste
accessible sans reseau (LE point sensible : le payeur ne doit jamais etre
bloque hors-ligne). Ce script host-side coupe wifi + data au bon moment, puis
retablit tout a la fin.

LE BLUETOOTH DE L'IMAGE EST ETEINT AVANT LA PREMIERE BASCULE (tache 685,
kaizen #101252). CE QUI A ETE MESURE le 05/10 dans le logcat du run S4 :
    07:48:32  bt_stack_manager_thread demarre
    07:48:36  F/libc : Fatal signal 6 (SIGABRT) in tid bt_stack_manage,
              pid droid.bluetooth (com.google.android.bluetooth)
    07:48:59  E/ActivityManager : ANR in com.google.android.bluetooth
    07:50:10  ANR in com.google.android.bluetooth (le second)
34 lignes `bt_stack_manage` et 8 reinitialisations de pile (`event_init_stack`)
dans le seul run S4. La bascule en mode avion fait repartir la pile Bluetooth
de l'IMAGE D'EMULATEUR en boucle, l'ANR du service systeme etouffe
l'application, et le run a rendu 0 marqueur et 0 capture.

L'image en cause : google/sdk_gphone64_x86_64/emu64xa:14/UE1A.230829.050,
c'est-a-dire `system-images/android-34/google_apis/x86_64`. Aucun AVD de la
machine ne porte `hw.bluetooth=no`. La vraie correction est dans l'image ; en
attendant, on eteint la pile avant de toucher au mode avion. AUCUN scenario
persona n'exerce le Bluetooth (la seule fonction qui s'en sert est la ceinture
de frequence cardiaque, traversee par aucun parcours), donc cette extinction
ne peut rendre vert aucun chemin du produit.

Le pilote `tool/run_persona.ps1` eteint deja la pile avant le run ; on le refait
ICI parce que ce script est celui qui DECLENCHE la bascule, et qu'il est aussi
lance a la main.

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


def couper_bluetooth(serial):
    """Eteint la pile Bluetooth de l'image et DIT si elle est bien eteinte."""
    sh(serial, "shell", "svc", "bluetooth", "disable")
    sh(serial, "shell", "settings", "put", "global", "bluetooth_on", "0")
    etat = sh(serial, "shell", "settings", "get", "global", "bluetooth_on")
    etat = (etat.stdout or "").strip()
    if etat == "0":
        print("[s4-offline] BLUETOOTH eteint (bluetooth_on=0) avant la "
              "bascule : la boucle SIGABRT bt_stack_manage de l image ne peut "
              "plus etouffer l application", flush=True)
        return True
    print("[s4-offline] BLUETOOTH : extinction SANS EFFET "
          "(bluetooth_on=%r). Attendez-vous a des ANR de "
          "com.google.android.bluetooth sur les bascules de mode avion : "
          "lisez le logcat AVANT d accuser le produit." % etat, flush=True)
    return False


def main() -> int:
    serial = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    # AVANT TOUT : la pile Bluetooth de l'image, qui plante sur les bascules.
    couper_bluetooth(serial)
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
    # LE BLUETOOTH RESTE ETEINT : le retablissement du reseau rallume la radio
    # Wi-Fi/data, et une pile Bluetooth qui repart derriere une bascule est
    # exactement ce qui a plante. On ne la rallume pas.
    print("[s4-offline] fin (Bluetooth laisse eteint, voir l en-tete)",
          flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
