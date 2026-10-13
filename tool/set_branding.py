#!/usr/bin/env python3
"""Choisit la famille de logo active et la variante de splash de StepWays.

C'est LE SEUL ENDROIT qui dit quelle famille est active. Changer de famille =
une commande, puis deux generateurs :

    python tool/set_branding.py marches aube
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create

(ou `python tool/set_branding.py marches aube --generate` qui enchaine les trois)

Familles livrees par Christophe (29/09, zip stepways_assets) :
    sentier  montagne blanche + chemin en pointilles orange, fond vert  #1F3D2B
    marches  escalier blanc + fanion,                        fond orange #D9772B
    courbes  cercles concentriques + point orange,           fond vert  #1F3D2B

Variantes de splash livrees :
    foret    fond vert sombre #1F3D2B, logo sentier   (variante par defaut de son README)
    aube     fond clair       #F4F1E8, logo courbes

Ce que le script ecrit :
    assets/branding/icons/app-icon-1024.png        copie de l'icone 1024 a fond plein
    assets/branding/icons/adaptive-foreground.png  couche AVANT de l'icone adaptative Android
    flutter_launcher_icons.yaml                    config icone (Android + iOS)
    flutter_native_splash.yaml                     config splash
    lib/core/branding/app_branding.dart            la famille active, cote Dart

Pourquoi une couche avant generee, et pas l'icone 1024 telle quelle : Android 8+
masque l'icone adaptative en cercle/goutte/squircle selon le lanceur, et ne
garantit que le disque central (72dp sur les 108dp de la couche). L'icone 1024
de Christophe place le picto sur 66.8% du carre — plein cadre c'est juste, mais
sous un masque circulaire les pieds de la montagne sortiraient du disque. On
redescend donc le picto a 50% du carre (PICTO_RATIO), ce qui laisse le dessin
entier dans la zone sure quelle que soit la forme du masque.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

# `tool/` est deja le premier element de `sys.path` quand ce fichier est lance
# en script ; l'insertion explicite couvre l'import depuis ailleurs.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from resolution_executable import resoudre_executable  # noqa: E402

REPO = Path(__file__).resolve().parents[1]

FAMILIES = ("sentier", "marches", "courbes")
SPLASHES = {
    "foret": "#1F3D2B",
    "aube": "#F4F1E8",
}

# Le picto occupe (170,170)-(854,854) dans les icones 1024 des trois familles
# (transform="translate(170 170) scale(5.7)" sur une planche de 120 unites).
PICTO_BOX = (170, 170, 854, 854)
# Part du carre 1024 occupee par le picto dans la couche AVANT Android.
# 0.50 garde le dessin le plus large des trois familles (marches) a l'interieur
# du disque de 72dp sur 108dp qu'Android garantit.
PICTO_RATIO = 0.50
ICON_SIZE = 1024


def read_background(family: str) -> str:
    """Lit la couleur de fond dans le <rect> de l'icone SVG de la famille."""
    svg = REPO / "assets" / "branding" / "svg" / family / f"{family}-icone-app.svg"
    match = re.search(r'<rect[^>]*fill="(#[0-9A-Fa-f]{6})"', svg.read_text(encoding="utf-8"))
    if not match:
        raise SystemExit(f"couleur de fond introuvable dans {svg}")
    return match.group(1).upper()


def build_icons(family: str, background: str) -> None:
    src = REPO / "assets" / "branding" / "png" / f"{family}-icone-app-1024.png"
    out_dir = REPO / "assets" / "branding" / "icons"
    out_dir.mkdir(parents=True, exist_ok=True)

    shutil.copyfile(src, out_dir / "app-icon-1024.png")

    picto = Image.open(src).convert("RGBA").crop(PICTO_BOX)
    side = int(round(ICON_SIZE * PICTO_RATIO))
    picto = picto.resize((side, side), Image.LANCZOS)

    canvas = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), background)
    offset = (ICON_SIZE - side) // 2
    canvas.paste(picto, (offset, offset), picto)
    canvas.save(out_dir / "adaptive-foreground.png")


def build_icones_duo_clair() -> dict[str, int]:
    """Fabrique la variante CLAIRE des icones bicolores de Christophe.

    Il livre les 20 rubriques et les 43 icones ICO en duo vert #1F3D2B + orange
    #D9772B, et son README dit : « sur fond sombre, remplacer #1F3D2B par
    #F4F1E8 ». Fait a la main, ce remplacement serait a refaire a chaque
    livraison et oublie sur une icone ou deux. Il est donc DERIVE, ici, a chaque
    passage du script : les dossiers sources ne sont jamais edites.

    L'orange ne bouge pas : il tient le contraste sur les deux fonds.
    """
    faits: dict[str, int] = {}
    for nom in ("rubriques-duo", "ico-duo", "mat-duo"):
        source = REPO / "assets" / "icons" / nom
        cible = REPO / "assets" / "icons" / f"{nom}-clair"
        cible.mkdir(parents=True, exist_ok=True)

        compte = 0
        for svg in sorted(source.glob("*.svg")):
            contenu = svg.read_text(encoding="utf-8")
            # Le blanc des dessins pleins (la coche sur disque plein, MAT-002)
            # doit devenir sombre en meme temps que le fond devient clair,
            # sinon la coche disparait dans son propre disque.
            clair = re.sub(r"#1F3D2B", "@VERT@", contenu, flags=re.IGNORECASE)
            if "@VERT@" in clair:
                clair = re.sub(r"#FFFFFF", "#1F3D2B", clair, flags=re.IGNORECASE)
            clair = clair.replace("@VERT@", "#F4F1E8")
            # Certaines icones de mecanique (chevrons, fleches) sont d'une seule
            # couleur, l'orange : il n'y a rien a eclaircir, l'orange tient sur
            # les deux fonds. On les recopie telles quelles plutot que de refuser
            # de travailler.
            (cible / svg.name).write_text(clair, encoding="utf-8")
            compte += 1
        faits[nom] = compte
    return faits


def write_launcher_icons(family: str, background: str) -> None:
    (REPO / "flutter_launcher_icons.yaml").write_text(
        f"""# GENERE PAR tool/set_branding.py — famille active : {family}
# Ne pas editer a la main : relancer `python tool/set_branding.py <famille>`.
#
#   dart run flutter_launcher_icons
#
# image_path              icone pleine (iOS, et icone heritee Android < 8)
# adaptive_icon_*         icone adaptative Android 8+ : couche avant (picto) +
#                         couche arriere (aplat). Sans ces deux couches le
#                         lanceur rogne l'icone pleine n'importe comment.
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/branding/icons/app-icon-1024.png"
  adaptive_icon_background: "{background}"
  adaptive_icon_foreground: "assets/branding/icons/adaptive-foreground.png"
  adaptive_icon_foreground_inset: 0
  remove_alpha_ios: true
  background_color_ios: "{background}"
""",
        encoding="utf-8",
    )


def write_native_splash(splash: str) -> None:
    color = SPLASHES[splash]
    (REPO / "flutter_native_splash.yaml").write_text(
        f"""# GENERE PAR tool/set_branding.py — variante active : {splash}
# Ne pas editer a la main : relancer `python tool/set_branding.py <famille> <splash>`.
#
#   dart run flutter_native_splash:create
#
# LIMITE SYSTEME, pas un defaut de l'app (README de Christophe) : sur Android 12+
# le systeme impose sa propre fenetre de demarrage et n'affiche QUE le picto
# centre sur la couleur unie — le fond avec les cretes ne sort que sur iOS et
# Android < 12.
flutter_native_splash:
  color: "{color}"
  background_image: assets/splash/{splash}-background.png
  image: assets/splash/{splash}-logo.png
  fullscreen: true
  android_12:
    color: "{color}"
    image: assets/splash/{splash}-android12.png
  web: false
""",
        encoding="utf-8",
    )


def write_dart(family: str, splash: str) -> None:
    target = REPO / "lib" / "core" / "branding" / "app_branding.dart"
    source = target.read_text(encoding="utf-8")
    patched = re.sub(
        r"(static const String family = ')[a-z]+(';)",
        rf"\g<1>{family}\g<2>",
        source,
    )
    patched = re.sub(
        r"(static const String splashVariant = ')[a-z]+(';)",
        rf"\g<1>{splash}\g<2>",
        patched,
    )
    if patched == source and f"family = '{family}'" not in source:
        raise SystemExit(f"constantes introuvables dans {target}")
    target.write_text(patched, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("famille", nargs="?", default="sentier", choices=FAMILIES)
    parser.add_argument("splash", nargs="?", default="foret", choices=sorted(SPLASHES))
    parser.add_argument(
        "--generate",
        action="store_true",
        help="enchaine flutter_launcher_icons et flutter_native_splash:create",
    )
    args = parser.parse_args()

    background = read_background(args.famille)
    build_icons(args.famille, background)
    write_launcher_icons(args.famille, background)
    write_native_splash(args.splash)
    write_dart(args.famille, args.splash)
    duo_clair = build_icones_duo_clair()

    print(f"famille active : {args.famille} (fond {background})")
    print(f"splash actif   : {args.splash} ({SPLASHES[args.splash]})")
    for nom, compte in duo_clair.items():
        print(f"{nom:14} : {compte} icones claires derivees pour fond sombre")

    if args.generate:
        # LE NOM NU ET LE SHELL SONT PARTIS ENSEMBLE (tache 699). Sous Windows
        # `dart` est un `.bat` que `CreateProcess` ne resout pas : la version
        # precedente contournait le defaut avec `shell=(sys.platform ==
        # "win32")`, c'est-a-dire en faisant interpreter la ligne par `cmd.exe`
        # — une injection de plus pour reparer une resolution de chemin. On
        # resout le chemin, et `shell` reste faux sur toutes les plateformes.
        dart, raison = resoudre_executable("dart")
        if dart is None:
            print(f"dart introuvable, rien n a ete genere : {raison}")
            return 76
        for arguments in (
            ["run", "flutter_launcher_icons"],
            ["run", "flutter_native_splash:create"],
        ):
            print("> " + " ".join([dart, *arguments]))
            result = subprocess.run([dart, *arguments], cwd=REPO, shell=False)
            if result.returncode != 0:
                return result.returncode
    else:
        print("puis : dart run flutter_launcher_icons")
        print("       dart run flutter_native_splash:create")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
