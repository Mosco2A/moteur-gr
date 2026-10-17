#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""FAIT ENTRER LE FONDS PHOTO DOCUMENTE DANS LES ASSETS DE L'APPLICATION.

POURQUOI UN SCRIPT ET PAS UNE COPIE A LA MAIN. Le fonds vit hors du depot de
l'application, dans un dossier que git IGNORE (`data/` du depot Skynet,
.gitignore ligne 20). Une copie manuelle laisserait donc DEUX choses invisibles :
le geste qui a ete fait, et la preuve que le fichier copie est bien le fichier
dont la licence a ete verifiee. C'est la lecon de la tache 839 sur les chiffres
du GR20 : le procede devient un script, et le script est la trace.

CE QUE CE SCRIPT GARANTIT, ET IL REFUSE PLUTOT QUE DE DEVINER :
  1. L'EMPREINTE EST REVERIFIEE. Le manifeste du fonds (tache 845) porte le
     SHA-256 MESURE de chaque image. Ce script le recalcule sur le fichier
     source : une image dont l'empreinte ne colle pas N'ENTRE PAS. Sans ca, la
     preuve de licence porterait sur une image et le binaire en embarquerait une
     autre.
  2. LA LICENCE EST REVERIFIEE, par la MEME liste blanche que le lecteur Dart
     (`LicencesCommerciales`) : domaine public, CC0, CC-BY et CC-BY-SA toutes
     versions. Une licence hors liste n'entre pas, et le refus est NOMME.
  3. LA PREUVE VOYAGE AVEC L'IMAGE. A cote des images, le script ecrit
     `PROVENANCE.json` (tous les champs du fonds, image par image : adresse
     d'origine, auteur, licence exacte, adresse de la licence, mention,
     conditions, empreinte) et `CHOIX_ET_REFUS.csv` (les images EXAMINEES puis
     ECARTEES, avec leur motif). Les deux sont dans le dossier d'assets declare
     au pubspec, donc dans le binaire : la preuve est la ou est ce qu'elle
     prouve, comme les fichiers de releve brut de la tache 839.
  4. LA FICHE EST MISE A JOUR, dans le format que le lecteur attend
     (`lib/core/models/fiche_de_sentier.dart`) : `fichier`,
     `adresse_d_origine`, `auteur`, `licence`, `mention`, et `lat`/`lon`
     SEULEMENT quand la source les donne.

LES CHAPITRES DU FONDS NE SONT PAS LES PRODUITS DU CATALOGUE. Le fonds est
range par CHAPITRE (gr20-nord, gr20-sud, mare-a-mare-centre) parce que le
chapitre est l'unite de vente visee (#101920). Le catalogue de CETTE branche
porte deux produits : `gr20` (entier) et `mare_a_mare_centre`. Les deux
chapitres du GR20 alimentent donc le meme produit, et c'est DIT dans le fichier
de provenance : le jour ou les chapitres deviennent des produits, chacun a deja
sa couverture et ses vues.

USAGE
  python tool/photos_dans_stepways.py [--fonds <dossier>] [--verifier]

  --verifier  ne recopie rien : controle que les assets presents sont conformes
              au fonds (empreintes et comptes). Sortie non nulle si un ecart.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

# Le fonds documente par la tache 845, hors du depot de l'application.
FONDS_PAR_DEFAUT = Path("C:/Users/Christophe/claude/data/photos_sentiers")

RACINE = Path(__file__).resolve().parent.parent

# CHAPITRE DU FONDS -> DOSSIER DE DONNEES DU SENTIER. Un chapitre sans dossier
# n'est pas une erreur : il attend que le produit existe (cf. en-tete).
#
# ATTENTION, LE DOSSIER N'EST PAS L'IDENTIFIANT. Le Mare a Mare Centre a pour
# identifiant `mare-a-mare-centre` (tirets, cf. sa TrailConfig) et pour dossier
# d'assets `mare_a_mare_centre` (soulignes). Le `trailId` de la fiche n'est donc
# JAMAIS deduit du dossier ici : il est laisse tel que la fiche le porte, et le
# lecteur refuse une fiche qui annonce un autre sentier que le sien.
DOSSIER_PAR_CHAPITRE = {
    "gr20-nord": "gr20",
    "gr20-sud": "gr20",
    "mare-a-mare-centre": "mare_a_mare_centre",
}

# LA COUVERTURE DU SENTIER, QUAND PLUSIEURS CHAPITRES L'ALIMENTENT. Le lecteur
# retient la PREMIERE photo qui se declare couverture ; il en faut donc une
# seule par produit, et le choix se fait ici plutot qu'au hasard de l'ordre.
COUVERTURE_PAR_DOSSIER = {
    "gr20": "gr20-nord",
    "mare_a_mare_centre": "mare-a-mare-centre",
}

# CHAPITRE DU FONDS -> SA FICHE PROPRE, QUAND LE CHAPITRE EST UN PRODUIT.
#
# TACHE 853 — LES DEUX MOITIES DU GR20 SONT LES PRODUITS EN VENTE, ET ELLES
# N AVAIENT NI FICHE NI PHOTOS. Le lot 841 a fait du chapitre l unite de vente
# et a retire le GR20 entier du catalogue ; le fonds de la 845 etait deja range
# par chapitre (six vues au nord, six au sud, une couverture chacun) et l en-tete
# de ce script l annoncait : « le jour ou les chapitres deviennent des produits,
# chacun a deja sa couverture et ses vues ». Ce jour est arrive.
#
# LES IMAGES NE SONT PAS DUPLIQUEES, ET C EST UNE DECISION. Les douze fichiers
# restent dans `assets/data/gr20/photos/` avec LEUR PREUVE UNIQUE ; les fiches
# des chapitres les declarent par leur vrai chemin. Recopier six images par
# chapitre aurait double six megaoctets de JPEG dans un binaire hors ligne par
# conception, et surtout DEDOUBLE la preuve : deux PROVENANCE.json a tenir a
# jour pour les memes images, donc deux occasions de se contredire. La garde
# `photos_du_produit_848_test` a ete reecrite pour verifier la preuve A COTE DE
# L IMAGE plutot qu a cote de la fiche — elle y a gagne en force, puisqu elle
# compte desormais les images DISTINCTES du fonds.
FICHES_DE_CHAPITRE = {
    "gr20-nord": "gr20-nord",
    "gr20-sud": "gr20-sud",
}

# MEME LISTE BLANCHE QUE LE LECTEUR DART (`LicencesCommerciales`). Les deux
# doivent dire la meme chose : une liste plus permissive ici ferait entrer dans
# le binaire ce que l'application refuserait d'afficher, et l'inverse ferait
# refuser ici ce qu'elle accepte.
DOMAINE_PUBLIC = {"CC0", "CC01.0", "DOMAINEPUBLIC", "PUBLICDOMAIN", "PD"}
CC_BY = re.compile(r"^CCBY(SA)?[0-9.]*$")


def normaliser_licence(licence: str) -> str:
    """La forme comparable d'un libelle de licence (comme en Dart)."""
    return (
        licence.upper()
        .replace(" ", "")
        .replace("_", "")
        .replace("-", "")
        .replace("LICENSE", "")
        .replace("LICENCE", "")
    )


def licence_autorisee(licence: str) -> bool:
    """Vrai si la licence autorise l'usage commercial."""
    normalisee = normaliser_licence(licence)
    if not normalisee:
        return False
    if normalisee in DOMAINE_PUBLIC:
        return True
    return bool(CC_BY.match(normalisee))


def empreinte(chemin: Path) -> str:
    """SHA-256 du fichier, en minuscules."""
    somme = hashlib.sha256()
    with chemin.open("rb") as flux:
        for bloc in iter(lambda: flux.read(1 << 20), b""):
            somme.update(bloc)
    return somme.hexdigest().lower()


def ordre_dans_la_bande(image: dict) -> tuple:
    """L'ORDRE DE LA BANDE DE PHOTOS, ET IL EST VOULU.

    Les couvertures des chapitres passent EN TETE, puis les vues. Sur le GR20
    entier, le randonneur voit donc d'abord le nord et le sud : la description
    de la fiche dit que les deux moities ne se ressemblent pas (7 401 m de
    montee au nord contre 4 243 m au sud, mesures de la tache 839), et une bande
    qui ne montrerait que l'une des deux contredirait le texte juste en dessous.
    """
    return (0 if image["role"] == "couverture" else 1, image["code"])


def photo_pour_la_fiche(image: dict, est_couverture: bool) -> dict:
    """Traduit une entree du fonds dans le format attendu par le lecteur Dart."""
    dossier = DOSSIER_PAR_CHAPITRE[image["chapitre"]]
    nom = Path(image["fichier_local"]).name
    entree = {
        "fichier": f"assets/data/{dossier}/photos/{nom}",
        "adresse_d_origine": image["adresse_origine"],
        "auteur": image["auteur"],
        "licence": image["licence"],
        "mention": image["mention_a_afficher"],
    }
    # lat/lon SEULEMENT si la source les donne : on ne devine pas un lieu.
    coordonnees = image.get("coordonnees") or {}
    if coordonnees.get("lat") is not None and coordonnees.get("lon") is not None:
        entree["lat"] = coordonnees["lat"]
        entree["lon"] = coordonnees["lon"]
    if est_couverture:
        entree["couverture"] = True
    return entree


def lire_refus(fonds: Path) -> list[dict]:
    """Les images EXAMINEES PUIS ECARTEES, telles que le fonds les a inscrites."""
    fichier = fonds / "CHOIX_ET_REFUS.csv"
    if not fichier.exists():
        return []
    with fichier.open("r", encoding="utf-8-sig", newline="") as flux:
        return [
            ligne
            for ligne in csv.DictReader(flux, delimiter=";")
            if (ligne.get("decision") or "").strip().upper() != "RETENUE"
        ]


def main() -> int:
    analyseur = argparse.ArgumentParser(description=__doc__)
    analyseur.add_argument("--fonds", type=Path, default=FONDS_PAR_DEFAUT)
    analyseur.add_argument("--verifier", action="store_true")
    options = analyseur.parse_args()

    fonds: Path = options.fonds
    manifeste_du_fonds = fonds / "MANIFESTE.json"
    if not manifeste_du_fonds.exists():
        print(f"FONDS INTROUVABLE : {manifeste_du_fonds}", file=sys.stderr)
        return 2

    fonds_json = json.loads(manifeste_du_fonds.read_text(encoding="utf-8"))
    images = fonds_json["images"]
    refus = lire_refus(fonds)

    retenues: dict[str, list[dict]] = {}
    ecarts: list[str] = []

    for image in sorted(images, key=ordre_dans_la_bande):
        chapitre = image["chapitre"]
        donnees = DOSSIER_PAR_CHAPITRE.get(chapitre)
        if donnees is None:
            ecarts.append(
                f"{image['code']} : chapitre « {chapitre} » sans sentier au "
                f"catalogue — l'image reste au fonds"
            )
            continue

        source = fonds / image["fichier_local"]
        if not source.exists():
            ecarts.append(f"{image['code']} : fichier absent du fonds ({source})")
            continue

        # (1) L'EMPREINTE, RECALCULEE. La preuve doit porter sur CE fichier.
        mesuree = empreinte(source)
        annoncee = (image.get("copie_locale_sha256") or "").lower()
        if annoncee and mesuree != annoncee:
            ecarts.append(
                f"{image['code']} : empreinte differente du manifeste du fonds "
                f"(mesuree {mesuree[:12]}…, annoncee {annoncee[:12]}…)"
            )
            continue

        # (2) LA LICENCE, REVERIFIEE par la liste blanche.
        if not licence_autorisee(image["licence"]):
            ecarts.append(
                f"{image['code']} : licence « {image['licence']} » hors liste "
                f"blanche — refusee"
            )
            continue

        retenues.setdefault(donnees, []).append(image)

    anomalies: list[str] = []

    for donnees, liste in sorted(retenues.items()):
        dossier = RACINE / "assets" / "data" / donnees / "photos"
        dossier.mkdir(parents=True, exist_ok=True)
        chapitre_de_couverture = COUVERTURE_PAR_DOSSIER.get(donnees)
        couverture_posee = False
        photos_fiche: list[dict] = []
        provenance: list[dict] = []

        for image in liste:
            source = fonds / image["fichier_local"]
            cible = dossier / Path(image["fichier_local"]).name

            if options.verifier:
                if not cible.exists():
                    anomalies.append(f"{donnees} : {cible.name} absent des assets")
                elif empreinte(cible) != empreinte(source):
                    anomalies.append(
                        f"{donnees} : {cible.name} differe du fonds"
                    )
            else:
                shutil.copy2(source, cible)

            est_couverture = (
                not couverture_posee
                and image["role"] == "couverture"
                and image["chapitre"] == chapitre_de_couverture
            )
            if est_couverture:
                couverture_posee = True

            photos_fiche.append(photo_pour_la_fiche(image, est_couverture))
            provenance.append(
                {
                    "fichier": cible.name,
                    "chapitre_du_fonds": image["chapitre"],
                    "role_dans_le_fonds": image["role"],
                    "couverture_du_sentier": est_couverture,
                    "lieu": image.get("lieu", ""),
                    "legende": image.get("legende", ""),
                    "adresse_d_origine": image["adresse_origine"],
                    "adresse_du_fichier_original": image.get(
                        "adresse_fichier_original", ""
                    ),
                    "auteur": image["auteur"],
                    "licence": image["licence"],
                    "adresse_de_la_licence": image.get("licence_adresse", ""),
                    "attribution_obligatoire": image.get(
                        "attribution_obligatoire", ""
                    ),
                    "mention_a_afficher": image["mention_a_afficher"],
                    "conditions": image.get("conditions", ""),
                    "preuve_de_licence": image.get("preuve_de_licence", {}),
                    "coordonnees": image.get("coordonnees"),
                    "distance_a_la_trace_m": image.get("distance_a_la_trace_m"),
                    "pixels": image.get("copie_locale_pixels", ""),
                    "octets": image.get("copie_locale_octets"),
                    "sha256": image.get("copie_locale_sha256", ""),
                    "modification_apportee": image.get(
                        "modification_apportee", ""
                    ),
                }
            )

        if not couverture_posee and photos_fiche:
            # Le lecteur se rabat sur la premiere photo publiable ; on le DIT
            # plutot que de laisser croire a un choix.
            anomalies.append(
                f"{donnees} : aucune couverture declaree, le lecteur prendra "
                f"la premiere photo de la bande"
            )

        if options.verifier:
            continue

        # (3) LA PREUVE, A COTE DE L'IMAGE.
        (dossier / "PROVENANCE.json").write_text(
            json.dumps(
                {
                    "objet": (
                        "La provenance des photos embarquees dans le binaire, "
                        "image par image. Ce fichier est dans le dossier "
                        "d'assets declare au pubspec : la preuve de licence "
                        "voyage avec l'image, comme les fichiers de releve brut "
                        "voyagent avec les chiffres (tache 839)."
                    ),
                    "dossier_de_donnees": donnees,
                    "source_du_fonds": fonds_json.get("etabli_par", ""),
                    "etabli_le": fonds_json.get("etabli_le", ""),
                    "source_unique": fonds_json.get("source_unique", ""),
                    "regle": fonds_json.get("regle", ""),
                    "copies_locales": fonds_json.get("copies_locales", ""),
                    "ecrit_par": (
                        "tool/photos_dans_stepways.py — ne pas editer a la main"
                    ),
                    "nombre_d_images": len(provenance),
                    "images": provenance,
                },
                ensure_ascii=False,
                indent=1,
            )
            + "\n",
            encoding="utf-8",
        )

        # (3bis) LE FICHIER DE REFUS. Il prouve que le tri a eu lieu : une
        # absence nommee n'est pas la meme chose qu'une absence.
        with (dossier / "CHOIX_ET_REFUS.csv").open(
            "w", encoding="utf-8", newline=""
        ) as flux:
            colonnes = [
                "code",
                "chapitre",
                "role",
                "decision",
                "fichier Commons",
                "licence",
                "auteur",
                "distance a la trace",
                "preuve",
                "motif du refus",
            ]
            redacteur = csv.DictWriter(flux, fieldnames=colonnes, delimiter=";")
            redacteur.writeheader()
            for ligne in refus:
                if DOSSIER_PAR_CHAPITRE.get(ligne.get("chapitre", "")) == donnees:
                    redacteur.writerow({c: ligne.get(c, "") for c in colonnes})

        # (4) LA FICHE, dans le format du lecteur.
        fiche = RACINE / "assets" / "data" / donnees / "fiche.json"
        contenu = json.loads(fiche.read_text(encoding="utf-8"))
        contenu["photos"] = photos_fiche
        fiche.write_text(
            json.dumps(contenu, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

        print(
            f"{donnees} : {len(photos_fiche)} photos, "
            f"couverture {'posee' if couverture_posee else 'ABSENTE'}, "
            f"{sum(1 for r in refus if DOSSIER_PAR_CHAPITRE.get(r.get('chapitre', '')) == donnees)} refus inscrits"
        )

        # (4bis) LA FICHE DE CHAQUE CHAPITRE QUI EST UN PRODUIT (tache 853).
        #
        # Le chapitre ne prend QUE ses images, et sa couverture est la SIENNE —
        # le lac de Capitello au nord, le col de Bavella au sud. Sans ce bloc, la
        # couverture du sentier mere servait aussi de couverture au sud, qui
        # s'ouvrait donc sur une photo du nord.
        for chapitre, dossier_du_chapitre in sorted(FICHES_DE_CHAPITRE.items()):
            if DOSSIER_PAR_CHAPITRE.get(chapitre) != donnees:
                continue
            fiche_du_chapitre = (
                RACINE / "assets" / "data" / dossier_du_chapitre / "fiche.json"
            )
            if not fiche_du_chapitre.exists():
                anomalies.append(
                    f"{chapitre} : {fiche_du_chapitre.relative_to(RACINE)} "
                    f"manque — le texte de la fiche est EDITORIAL, ce script "
                    f"n'ecrit que ses photos"
                )
                continue

            du_chapitre = [i for i in liste if i["chapitre"] == chapitre]
            couverture_du_chapitre = False
            photos_du_chapitre: list[dict] = []
            for image in du_chapitre:
                est_couverture = (
                    not couverture_du_chapitre and image["role"] == "couverture"
                )
                if est_couverture:
                    couverture_du_chapitre = True
                photos_du_chapitre.append(
                    photo_pour_la_fiche(image, est_couverture)
                )

            if not couverture_du_chapitre:
                anomalies.append(
                    f"{chapitre} : aucune image de couverture dans le fonds — "
                    f"la carte du catalogue resterait vide"
                )

            contenu_du_chapitre = json.loads(
                fiche_du_chapitre.read_text(encoding="utf-8")
            )
            contenu_du_chapitre["photos"] = photos_du_chapitre
            fiche_du_chapitre.write_text(
                json.dumps(contenu_du_chapitre, ensure_ascii=False, indent=2)
                + "\n",
                encoding="utf-8",
            )
            print(
                f"{chapitre} : {len(photos_du_chapitre)} photos, "
                f"couverture {'posee' if couverture_du_chapitre else 'ABSENTE'}"
            )

    for ligne in ecarts:
        print(f"ECARTEE — {ligne}")
    for ligne in anomalies:
        print(f"ANOMALIE — {ligne}", file=sys.stderr)

    return 1 if anomalies else 0


if __name__ == "__main__":
    sys.exit(main())
