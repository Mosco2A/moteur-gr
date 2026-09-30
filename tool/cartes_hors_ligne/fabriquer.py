"""FABRIQUE LA CARTE HORS LIGNE D UN SENTIER, DE L EXTRAIT OSM AU .mbtiles.

    python tool/cartes_hors_ligne/fabriquer.py \
        --trace assets/data/mare_a_mare_centre/track.gpx \
        --sentier mare-a-mare-centre \
        --travail C:/Users/Christophe/stepways_tuiles_648

LES QUATRE ETAPES, ET AUCUNE N EST FACULTATIVE :

  1. L EMPRISE se lit dans la TRACE du sentier, jamais tapee a la main : la
     boite de la trace, plus une marge (5 km par defaut). Une emprise saisie a
     la main, c est une carte qui s arrete a une heure de marche du randonneur.
  2. L EXTRAIT OpenStreetMap vient de Geofabrik, avec sa somme MD5 publiee, et
     elle est VERIFIEE. Un extrait tronque produirait une carte a trous que rien
     ne signalerait.
  3. PLANETILER fait les tuiles vectorielles de l emprise (Java 17 suffit pour
     la version 0.7.0 ; les versions suivantes demandent Java 21).
  4. LE RENDU (`rendu.py`) dessine les PNG et ecrit le `.mbtiles` raster.

TOUT CE QUI EST GROS RESTE HORS DU DEPOT : l extrait `.osm.pbf` (33 Mo), les
sources auxiliaires de Planetiler (500 Mo), les tuiles vectorielles et le
`.mbtiles` final vivent dans le dossier `--travail`. Le depot ne porte que les
scripts.

POURQUOI GEOFABRIK ET PAS `tile.openstreetmap.org`. La politique d usage des
tuiles d OpenStreetMap interdit le telechargement en masse ; les loueurs de
tuiles interdisent la redistribution du fichier hors ligne. L extrait de donnees
brutes, lui, est sous ODbL : on peut en tirer une oeuvre produite (les tuiles) et
la distribuer dans une application payante, la seule obligation etant
l attribution. C est la conclusion chiffree du lot 608.
"""

from __future__ import annotations

import argparse
import hashlib
import math
import os
import re
import subprocess
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import rendu  # noqa: E402

GEOFABRIK = "https://download.geofabrik.de/europe/france/"
PLANETILER = (
    "https://github.com/onthegomap/planetiler/releases/download/v0.7.0/planetiler.jar"
)
POLICE = "https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans%5Bwdth,wght%5D.ttf"
POLICE_LICENCE = "https://github.com/google/fonts/raw/main/ofl/notosans/OFL.txt"
AGENT = "StepWays/1.0 (fabrication de cartes hors ligne, christophe.mosconi@only1cent.com)"


def _telecharger(url: str, destination: str) -> str:
    if os.path.exists(destination) and os.path.getsize(destination) > 0:
        print(f"  deja la : {os.path.basename(destination)}")
        return destination
    print(f"  telechargement : {url}")
    requete = urllib.request.Request(url, headers={"User-Agent": AGENT})
    with urllib.request.urlopen(requete) as reponse, open(destination + ".partiel", "wb") as sortie:
        while True:
            morceau = reponse.read(1 << 20)
            if not morceau:
                break
            sortie.write(morceau)
    os.replace(destination + ".partiel", destination)
    return destination


def _md5(chemin: str) -> str:
    h = hashlib.md5()
    with open(chemin, "rb") as f:
        for morceau in iter(lambda: f.read(1 << 20), b""):
            h.update(morceau)
    return h.hexdigest()


def sha256_du_fichier(chemin: str) -> str:
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for morceau in iter(lambda: f.read(1 << 20), b""):
            h.update(morceau)
    return h.hexdigest()


def emprise_de_la_trace(chemin_gpx: str, marge_km: float) -> tuple[float, float, float, float]:
    """Boite de la trace, elargie de [marge_km] de chaque cote."""
    texte = open(chemin_gpx, encoding="utf-8").read()
    points = re.findall(r'lat="([-0-9.]+)"\s+lon="([-0-9.]+)"', texte)
    if not points:
        raise SystemExit(f"aucun point dans {chemin_gpx} — emprise impossible")
    lats = [float(a) for a, _ in points]
    lons = [float(b) for _, b in points]
    dlat = marge_km / 111.32
    milieu = (min(lats) + max(lats)) / 2
    dlon = marge_km / (111.32 * math.cos(math.radians(milieu)))
    return (min(lons) - dlon, min(lats) - dlat, max(lons) + dlon, max(lats) + dlat)


def main() -> int:
    a = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    a.add_argument("--trace", required=True, help="trace GPX du sentier (donne l emprise)")
    a.add_argument("--sentier", required=True, help="identifiant du sentier (ex: mare-a-mare-centre)")
    a.add_argument("--travail", required=True, help="dossier de travail HORS DEPOT")
    a.add_argument("--extrait", default="corse", help="nom de l extrait Geofabrik (defaut: corse)")
    a.add_argument("--date-extrait", default=None, help="date AAMMJJ de l extrait, ex 260929")
    a.add_argument("--marge-km", type=float, default=5.0)
    a.add_argument("--zoom-mini", type=int, default=10)
    a.add_argument("--zoom-maxi", type=int, default=15)
    a.add_argument("--nom", default=None, help="nom porte par le .mbtiles")
    args = a.parse_args()

    travail = os.path.abspath(args.travail)
    os.makedirs(travail, exist_ok=True)
    os.makedirs(os.path.join(travail, "polices"), exist_ok=True)

    print("1. EMPRISE")
    ouest, sud, est, nord = emprise_de_la_trace(args.trace, args.marge_km)
    print(f"  trace {args.trace} + {args.marge_km} km")
    print(f"  ouest={ouest:.5f} sud={sud:.5f} est={est:.5f} nord={nord:.5f}")
    total_attendu = 0
    for z in range(args.zoom_mini, args.zoom_maxi + 1):
        x0, y0, x1, y1 = rendu.tuiles_de_l_emprise(ouest, sud, est, nord, z)
        n = (x1 - x0 + 1) * (y1 - y0 + 1)
        total_attendu += n
        print(f"  z{z} : {n} tuiles")
    print(f"  total attendu : {total_attendu} tuiles")

    print("2. EXTRAIT OPENSTREETMAP")
    if args.date_extrait:
        nom_pbf = f"{args.extrait}-{args.date_extrait}.osm.pbf"
    else:
        # `<extrait>-latest.osm.pbf` est un lien symbolique que le serveur de
        # Geofabrik renvoie en 301 vers lui-meme : on prend donc un fichier DATE,
        # ce qui rend la fabrication reproductible a l identique.
        nom_pbf = f"{args.extrait}-latest.osm.pbf"
    pbf = _telecharger(GEOFABRIK + nom_pbf, os.path.join(travail, nom_pbf))
    md5 = _telecharger(GEOFABRIK + nom_pbf + ".md5", pbf + ".md5")
    attendu = open(md5, encoding="utf-8").read().split()[0]
    obtenu = _md5(pbf)
    if attendu != obtenu:
        raise SystemExit(f"SOMME MD5 REFUSEE pour {nom_pbf} : {obtenu} au lieu de {attendu}")
    print(f"  {nom_pbf} : {os.path.getsize(pbf)} octets, MD5 {obtenu} VERIFIE")

    print("3. TUILES VECTORIELLES (Planetiler)")
    jar = _telecharger(PLANETILER, os.path.join(travail, "planetiler-0.7.0.jar"))
    vecteur = os.path.join(travail, f"{args.sentier}-vecteur.mbtiles")
    commande = [
        "java", "-Xmx4g", "-jar", jar,
        f"--osm-path={pbf}",
        f"--output={vecteur}",
        f"--bounds={ouest},{sud},{est},{nord}",
        f"--minzoom={args.zoom_mini}",
        f"--maxzoom={args.zoom_maxi}",
        "--download", "--force",
    ]
    print("  " + " ".join(commande))
    resultat = subprocess.run(commande, cwd=travail)
    if resultat.returncode != 0:
        raise SystemExit("Planetiler a echoue — rien n est fabrique")
    print(f"  {vecteur} : {os.path.getsize(vecteur)} octets")

    print("4. RENDU RASTER")
    police = _telecharger(POLICE, os.path.join(travail, "polices", "NotoSans-variable.ttf"))
    _telecharger(POLICE_LICENCE, os.path.join(travail, "polices", "OFL.txt"))
    sortie = os.path.join(travail, f"{args.sentier}.mbtiles")
    if os.path.exists(sortie):
        os.remove(sortie)
    bilan = rendu.fabriquer(
        chemin_vecteur=vecteur,
        chemin_sortie=sortie,
        emprise=(ouest, sud, est, nord),
        zoom_mini=args.zoom_mini,
        zoom_maxi=args.zoom_maxi,
        police=police,
        nom=args.nom or args.sentier,
        description=(
            f"Carte hors ligne StepWays — {args.nom or args.sentier}. "
            f"Fabriquee depuis l extrait OpenStreetMap {nom_pbf} (MD5 {obtenu}). "
            "Donnees (c) OpenStreetMap contributors, ODbL."
        ),
    )

    taille = os.path.getsize(sortie)
    empreinte = sha256_du_fichier(sortie)
    print("")
    print("BILAN")
    print(f"  fichier   : {sortie}")
    print(f"  tuiles    : {bilan['tuiles']} (attendu {total_attendu})")
    print(f"  taille    : {taille} octets ({taille / 1e6:.1f} Mo)")
    print(f"  SHA-256   : {empreinte}")
    print(f"  duree     : {bilan['secondes']:.0f} s")
    if bilan["tuiles"] != total_attendu:
        print("  ATTENTION : le compte de tuiles ne tombe pas sur l attendu.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
