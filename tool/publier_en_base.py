#!/usr/bin/env python3
"""LES DONNEES DU SENTIER VONT EN BASE, ET ON PEUT LE REJOUER (tache 641).

DEMANDE DE CHRISTOPHE, verbatim du 30/09 11:54 : « Je veux que les donnees des
applications soient dans Firebase, chaque donnee a jour avec son timestamp de MAJ.
Ensuite je veux que l application vienne mettre a jour ses donnees a cette
source. » Et la veille : « tout en base, seule la copie sur le tel ; JE NE VEUX
PAS QUE CE SOIT EN DUR MAIS DANS LA BASE. »

CE QUI ETAIT MESURE AVANT CE LOT : le projet Firestore `stepways-app` ne portait
QUE la collection `users`. `trails` etait VIDE. Les sept familles du Mare a Mare
vivaient dans les assets embarques, le catalogue dans une constante Dart, et le
transport comme le ravitaillement dans deux autres constantes Dart. L application
savait deja lire une base par revision (lots 605 a 610) : PERSONNE N AVAIT JAMAIS
RIEN PUBLIE.

LA CHAINE, EN TROIS ETAPES, ET CHACUNE A UNE SEULE AUTORITE.

    python tool/publier_en_base.py source
    dart run tool/publier_sentier.dart publier publication/sources/mare-a-mare-centre
    python tool/publier_en_base.py pousser
    python tool/publier_en_base.py verifier

  1. `source` — LES ASSETS EMBARQUES SONT LA MATIERE, PAS L AUTORITE. Cette
     commande lit `assets/data/mare_a_mare_centre.json` (les sept familles en
     camelCase, lues par `TrailSeeder`) et la trace `track.gpx`, les convertit au
     schema PUBLIE (snake_case, lu par `DeltaUpdateService`), y fusionne le
     contenu source de `publication/contenu/<slug>.json`, et ecrit la source de
     l outil de publication. Elle ne pose AUCUNE revision : la source n a pas le
     droit d en porter (`SourceDeSentier._refuserLesRevisions`).

  2. `publier_sentier.dart` — L AUTORITE DES REVISIONS, ET ELLE EXISTE DEJA. Le
     calcul selectif du lot 607 (`RevisionSelective`) decide seul quel
     enregistrement change d instant : on ne le refait pas ici, sinon deux
     autorites decideraient du meme horodatage et la plus silencieuse gagnerait.

  3. `pousser` — LE MIROIR DU DEPOT DANS FIRESTORE. Cette commande lit le depot
     produit a l etape 2 et ecrit, pour le sentier :
       * `trails/{trailId}`                — la fiche du catalogue (l entree de
         liste), avec `data_version`, `rev` et `updated_at` ;
       * `trails/{trailId}/{famille}/{id}` — un document par enregistrement, avec
         son `rev` et son `updated_at`.
     C est EXACTEMENT la forme que `SourceInterrogeable` interroge
     (`collection('trails/{id}/{famille}').where('rev','>',R)`) et que
     `UpdateChecker` lit deja (`trails/{id}.data_version`).

POURQUOI `rev` ET `updated_at`, ET POURQUOI CE N EST PAS UN DOUBLON. `rev` est le
champ que le MECANISME compare — son nom est fige depuis le lot 605 et le
renommer casserait la synchronisation. `updated_at` est le meme instant, ecrit
pour etre LU PAR UN HUMAIN dans la console Firestore : c est la demande explicite
de Christophe, « chaque donnee a jour avec son timestamp de MAJ ». Les deux sont
ecrits depuis LA MEME valeur, a un seul endroit dans ce fichier, donc ils ne
peuvent pas diverger — c est la lecon de la tache 610 sur `dataVersion` et
`lastUpdated`.

IDEMPOTENCE, ET ELLE EST VERIFIEE CONTRE LA BASE, PAS SUPPOSEE. Avant d ecrire,
`pousser` relit ce qui est en base et compare une empreinte de CONTENU qui exclut
`rev` et `updated_at`. Un document inchange n est PAS reecrit : son `updated_at`
ne bouge pas. Rejouer la chaine sans rien changer ecrit ZERO document — et c est
la seule facon de rendre `updated_at` croyable. Un outil qui reecrirait tout
ferait redescendre le sentier entier a chaque publication sur le forfait de
chaque randonneur.

CE QUI DISPARAIT SE DIT. Un document present en base et absent du depot devient un
MARQUEUR DE SUPPRESSION (`supprime: true`) a l instant courant, jamais un `delete`
silencieux : un horodatage croissant ne transmet pas une absence, et un point d eau
tari resterait a vie sur le telephone du randonneur.

AUCUN SECRET DANS LE DEPOT. Le jeton d ecriture vient de l environnement
(`STEPWAYS_FIRESTORE_TOKEN`) ou, a defaut, de
`gcloud auth application-default print-access-token`. Rien n est ecrit sur disque,
rien n est journalise.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from typing import Any

# --------------------------------------------------------------------------
# CE QUE LE MOTEUR SAIT LIRE — LES SEPT FAMILLES, DANS L ORDRE DES CLES
# ETRANGERES. Cette liste est le miroir de `MorceauxDeSentier.tous`
# (lib/core/models/trail_manifest.dart) et elle doit rester identique : un
# hebergement pose avant son etape echoue.
# --------------------------------------------------------------------------
FICHE = "trail_meta"
FAMILLES = [
    FICHE,
    "itineraries",
    "stages",
    "accommodations",
    "pois",
    "gpx_tracks",
    "gpx_points",
]

# Les deux champs de bookkeeping de version, exclus de toute comparaison de
# contenu — sinon la decision « a-t-il change ? » dependrait de sa propre sortie
# precedente et TOUT changerait a chaque passage.
CHAMP_REVISION = "rev"
CHAMP_SUPPRIME = "supprime"
CHAMP_HORODATAGE = "updated_at"
BOOKKEEPING = {CHAMP_REVISION, CHAMP_SUPPRIME, CHAMP_HORODATAGE, "data_version"}

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJET_PAR_DEFAUT = "stepways-app"
BASE_PAR_DEFAUT = "(default)"


# ==========================================================================
# ETAPE 1 — LA SOURCE, DEPUIS LES ASSETS EMBARQUES
# ==========================================================================

_CAMEL = re.compile(r"(?<!^)(?=[A-Z])")


def en_serpent(nom: str) -> str:
    """`nameFr` -> `name_fr`, `bookingUrl` -> `booking_url`.

    LE DEPOT PORTE DEUX ECRITURES DU MEME SENTIER, ET C EST MESURE (piege #Z01
    du MODOP 603, confirme par la tache 607) : l asset embarque est en camelCase
    et lu par `TrailSeeder`, le fichier publie est en snake_case et lu par
    `DeltaUpdateService`. On ne cree pas un troisieme format : on CONVERTIT, a un
    seul endroit, et cette fonction est cet endroit.
    """
    return _CAMEL.sub("_", nom).lower()


def convertir(enregistrement: dict[str, Any]) -> dict[str, Any]:
    """Un enregistrement de l asset, au schema publie, sans les valeurs nulles."""
    return {
        en_serpent(cle): valeur
        for cle, valeur in enregistrement.items()
        if valeur is not None and not cle.startswith("_")
    }


def lire_json(chemin: str) -> Any:
    with open(chemin, encoding="utf-8") as flux:
        return json.load(flux)


def ecrire_json(chemin: str, contenu: Any) -> None:
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8", newline="\n") as flux:
        json.dump(contenu, flux, ensure_ascii=False, indent=2)
        flux.write("\n")


def commande_source(args: argparse.Namespace) -> int:
    """Fabrique la source de l outil de publication depuis les assets + le contenu."""
    asset = os.path.join(RACINE, args.asset)
    contenu_chemin = os.path.join(RACINE, args.contenu)
    if not os.path.exists(asset):
        print(f"REFUS — asset embarque absent : {asset}")
        return 1
    if not os.path.exists(contenu_chemin):
        print(f"REFUS — fichier de contenu absent : {contenu_chemin}")
        return 1

    brut = lire_json(asset)
    contenu = lire_json(contenu_chemin)
    trail_id = contenu["trail_id"]

    # --- Les sept familles, converties ------------------------------------
    familles: dict[str, Any] = {}
    for famille in FAMILLES:
        valeur = brut.get(famille)
        if valeur is None:
            continue
        if isinstance(valeur, dict):
            familles[famille] = convertir(valeur)
        elif valeur:
            familles[famille] = [convertir(e) for e in valeur]

    # `trail_meta` ne porte QUE son identite dans la source : `status` est declare
    # au niveau du sentier (l outil l injecte avant le calcul) et `data_version`
    # est du bookkeeping que l outil ecrit lui-meme.
    meta = familles.get(FICHE, {})
    familles[FICHE] = {"id": meta.get("id", trail_id), "code": meta["code"]}

    # --- Les hebergements enrichis et ajoutes -----------------------------
    hebergements = familles.get("accommodations", [])
    enrichissements = contenu.get("accommodations_enrichies", {})
    for h in hebergements:
        ajout = enrichissements.get(h["id"])
        if ajout:
            h.update({c: v for c, v in ajout.items() if not c.startswith("_")})
    hebergements.extend(
        {c: v for c, v in h.items() if not c.startswith("_")}
        for h in contenu.get("accommodations_ajoutees", [])
    )
    familles["accommodations"] = hebergements

    # --- Les points d interet : retires puis ajoutes -----------------------
    retires = contenu.get("pois_retires", {})
    pois = [p for p in familles.get("pois", []) if p["id"] not in retires]
    pois.extend(
        {c: v for c, v in p.items() if not c.startswith("_")}
        for p in contenu.get("pois_ajoutes", [])
    )
    familles["pois"] = pois

    # --- La trace : le meme fichier, lu par le meme parseur ---------------
    # La trace embarquee est COPIEE dans le dossier source et declaree en
    # `trace_depuis_gpx` : l outil de publication la lit avec `GpxParser`, c
    # est-a-dire le MEME code que l application. Un second parseur aurait pu
    # produire une trace legerement differente du meme fichier — la classe
    # d ecart que le lot 606 a passe une soiree a defaire.
    dossier = os.path.join(RACINE, args.sortie, trail_id)
    os.makedirs(dossier, exist_ok=True)
    gpx = os.path.join(RACINE, args.gpx)
    declaration_trace = None
    if os.path.exists(gpx):
        shutil.copyfile(gpx, os.path.join(dossier, "track.gpx"))
        itineraire = (familles.get("itineraries") or [{}])[0].get("id")
        declaration_trace = {
            "fichier": "track.gpx",
            "id": f"{trail_id}-trace",
            "itinerary_id": itineraire,
            "name": contenu["fiche"]["displayName"],
        }
        # Deux sources pour la meme trace divergeraient : l outil refuse les deux
        # ensemble, on retire donc les familles vides venues de l asset.
        familles.pop("gpx_tracks", None)
        familles.pop("gpx_points", None)

    # --- La fiche d affichage ---------------------------------------------
    fiche = {c: v for c, v in contenu["fiche"].items() if not c.startswith("_")}
    fiche.pop("source", None)
    fiche["emergencyNumbers"] = [
        {"name": n["name"], "phone": n["phone"]}
        for n in contenu.get("emergency_numbers_conserves", [])
        + contenu.get("emergency_numbers_ajoutes", [])
    ]

    source = {
        "_engendre_par": "tool/publier_en_base.py source — NE PAS MODIFIER A LA "
        "MAIN. Le contenu editorial et ses sources vivent dans "
        f"{args.contenu}, les sept familles dans {args.asset}.",
        "status": contenu.get("status", "active"),
        FICHE: familles[FICHE],
        "fiche": fiche,
    }
    for famille in FAMILLES[1:]:
        if famille in familles:
            source[famille] = familles[famille]
    if declaration_trace:
        source["trace_depuis_gpx"] = declaration_trace

    cible = os.path.join(dossier, "sentier.json")
    ecrire_json(cible, source)

    print(f"{trail_id} — source ecrite : {os.path.relpath(cible, RACINE)}")
    for famille in FAMILLES:
        valeur = source.get(famille)
        if isinstance(valeur, dict):
            print(f"  {famille:16s} 1 enregistrement")
        elif isinstance(valeur, list):
            print(f"  {famille:16s} {len(valeur)} enregistrement(s)")
    if declaration_trace:
        print("  gpx_tracks/points  depuis track.gpx, lus par GpxParser a la publication")
    print("")
    print("Etape suivante : dart run tool/publier_sentier.dart publier "
          f"{os.path.relpath(dossier, RACINE).replace(os.sep, '/')}")
    return 0


# ==========================================================================
# ETAPE 3 — LE MIROIR DANS FIRESTORE
# ==========================================================================

def jeton() -> str:
    """Le jeton d ecriture, depuis l environnement ou l identite de la machine.

    AUCUN SECRET DANS LE DEPOT. `STEPWAYS_FIRESTORE_TOKEN` prime pour qu une
    chaine d integration puisse fournir son propre jeton ; a defaut on demande
    a `gcloud` le jeton des identifiants par defaut de l application. Le jeton
    n est ni ecrit sur disque ni journalise.
    """
    depuis_env = os.environ.get("STEPWAYS_FIRESTORE_TOKEN")
    if depuis_env:
        return depuis_env.strip()
    try:
        sortie = subprocess.run(
            ["gcloud", "auth", "application-default", "print-access-token"],
            capture_output=True,
            text=True,
            check=True,
            shell=os.name == "nt",
        )
    except (OSError, subprocess.CalledProcessError) as erreur:
        raise SystemExit(
            "Aucun jeton d ecriture. Fournissez STEPWAYS_FIRESTORE_TOKEN, ou "
            "installez gcloud et lancez « gcloud auth application-default "
            f"login ». Cause : {erreur}"
        ) from erreur
    return sortie.stdout.strip()


class Firestore:
    """Le strict necessaire de l API REST de Firestore, et rien de plus.

    On n ajoute PAS de dependance Python au depot pour cela : la surface utilisee
    tient en quatre appels (lire un document, lister une collection, ecrire,
    supprimer) et une dependance de plus serait une dependance a maintenir.
    """

    def __init__(self, projet: str, base: str, jeton_acces: str) -> None:
        self.racine = (
            f"https://firestore.googleapis.com/v1/projects/{projet}"
            f"/databases/{urllib.parse.quote(base, safe='')}/documents"
        )
        self._entetes = {
            "Authorization": f"Bearer {jeton_acces}",
            "Content-Type": "application/json",
        }

    def _appeler(self, methode: str, chemin: str, corps: Any = None) -> Any:
        url = f"{self.racine}/{chemin}" if chemin else self.racine
        donnees = json.dumps(corps).encode("utf-8") if corps is not None else None
        requete = urllib.request.Request(
            url, data=donnees, headers=self._entetes, method=methode
        )
        try:
            with urllib.request.urlopen(requete) as reponse:
                brut = reponse.read().decode("utf-8")
                return json.loads(brut) if brut else {}
        except urllib.error.HTTPError as erreur:
            if erreur.code == 404 and methode == "GET":
                return None
            detail = erreur.read().decode("utf-8", "replace")[:600]
            raise SystemExit(
                f"Firestore a refuse {methode} {chemin} : HTTP {erreur.code}\n{detail}"
            ) from erreur

    def lire(self, chemin: str) -> dict[str, Any] | None:
        return self._appeler("GET", chemin)

    def lister(self, collection: str) -> list[dict[str, Any]]:
        documents: list[dict[str, Any]] = []
        jeton_page = None
        while True:
            suffixe = f"{collection}?pageSize=300"
            if jeton_page:
                suffixe += f"&pageToken={urllib.parse.quote(jeton_page)}"
            page = self._appeler("GET", suffixe) or {}
            documents.extend(page.get("documents", []))
            jeton_page = page.get("nextPageToken")
            if not jeton_page:
                return documents

    def ecrire(self, chemin: str, champs: dict[str, Any]) -> None:
        self._appeler("PATCH", chemin, {"fields": champs})


# --- Traduction entre le JSON du depot et les valeurs typees de Firestore ---

def en_valeur(valeur: Any) -> dict[str, Any]:
    """Une valeur JSON en valeur typee Firestore.

    LES HORODATAGES SONT DES `timestampValue`, PAS DES CHAINES, et c est le point
    de toute la demande de Christophe : dans la console Firestore un
    `timestampValue` s affiche comme une DATE lisible et se compare nativement
    cote serveur, ce qu une chaine ne fait ni l un ni l autre. C est aussi ce que
    `HorodatageServeur.annonceParLeServeur` attend cote application (forme
    `Timestamp` serialisee, ou ISO 8601).
    """
    if valeur is None:
        return {"nullValue": None}
    if isinstance(valeur, bool):
        return {"booleanValue": valeur}
    if isinstance(valeur, int):
        return {"integerValue": str(valeur)}
    if isinstance(valeur, float):
        return {"doubleValue": valeur}
    if isinstance(valeur, str):
        return {"stringValue": valeur}
    if isinstance(valeur, list):
        return {"arrayValue": {"values": [en_valeur(v) for v in valeur]}}
    if isinstance(valeur, dict):
        return {"mapValue": {"fields": {c: en_valeur(v) for c, v in valeur.items()}}}
    raise TypeError(f"Valeur non publiable : {valeur!r}")


def depuis_valeur(valeur: dict[str, Any]) -> Any:
    if "nullValue" in valeur:
        return None
    if "booleanValue" in valeur:
        return valeur["booleanValue"]
    if "integerValue" in valeur:
        return int(valeur["integerValue"])
    if "doubleValue" in valeur:
        return valeur["doubleValue"]
    if "timestampValue" in valeur:
        return valeur["timestampValue"]
    if "stringValue" in valeur:
        return valeur["stringValue"]
    if "arrayValue" in valeur:
        return [depuis_valeur(v) for v in valeur["arrayValue"].get("values", [])]
    if "mapValue" in valeur:
        return {
            c: depuis_valeur(v)
            for c, v in valeur["mapValue"].get("fields", {}).items()
        }
    return None


def champs_firestore(
    enregistrement: dict[str, Any], instant_iso: str
) -> dict[str, Any]:
    """Les champs du document : le contenu, puis `rev` et `updated_at`.

    LES DEUX SONT ECRITS DEPUIS LA MEME VALEUR, ICI ET NULLE PART AILLEURS. Deux
    noms pour un meme fait, renseignes separement, c est deux autorites dont la
    plus silencieuse gagne — la lecon de la tache 610 sur `dataVersion` et
    `lastUpdated`, qu on ne recommence pas.
    """
    champs = {
        cle: en_valeur(valeur)
        for cle, valeur in enregistrement.items()
        if cle not in (CHAMP_REVISION, CHAMP_HORODATAGE)
    }
    champs[CHAMP_REVISION] = {"timestampValue": instant_iso}
    champs[CHAMP_HORODATAGE] = {"timestampValue": instant_iso}
    return champs


def empreinte_de_contenu(enregistrement: dict[str, Any]) -> str:
    """Empreinte du CONTENU, hors bookkeeping de version.

    Les clefs sont triees et les nombres ramenes a leur valeur : `14` et `14.0`
    designent la meme distance, et les distinguer ferait bouger un `updated_at`
    pour une virgule — exactement le gaspillage que ce modele existe pour
    supprimer (meme regle que `RevisionSelective.empreinteDeContenu`).
    """

    def canonique(valeur: Any) -> Any:
        if isinstance(valeur, dict):
            return {c: canonique(valeur[c]) for c in sorted(valeur)}
        if isinstance(valeur, list):
            return [canonique(v) for v in valeur]
        if isinstance(valeur, bool):
            return valeur
        if isinstance(valeur, (int, float)):
            entier = int(valeur)
            return entier if float(entier) == float(valeur) else float(valeur)
        return valeur

    utile = {c: v for c, v in enregistrement.items() if c not in BOOKKEEPING}
    texte = json.dumps(canonique(utile), sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(texte.encode("utf-8")).hexdigest()


def identite(famille: str, enregistrement: dict[str, Any]) -> str | None:
    """L identite d un enregistrement, et l identifiant du document Firestore.

    Les points de trace n ont pas d identifiant propre : leur identite REELLE est
    le couple trace + rang (#R8). On la reconstitue en un identifiant de document
    stable, sans quoi une correction de trace publierait des doublons.
    """
    if famille == "gpx_points":
        trace = enregistrement.get("track_id")
        rang = enregistrement.get("sequence_index")
        if not isinstance(trace, str) or not isinstance(rang, int):
            return None
        return f"{trace}--{rang:06d}"
    identifiant = enregistrement.get("id")
    return identifiant if isinstance(identifiant, str) and identifiant else None


def enregistrements(brut: Any) -> list[dict[str, Any]]:
    if isinstance(brut, dict):
        return [brut]
    if isinstance(brut, list):
        return [e for e in brut if isinstance(e, dict)]
    return []


def commande_pousser(args: argparse.Namespace) -> int:
    """Miroir du depot publie dans Firestore, idempotent."""
    depot = os.path.join(RACINE, args.depot)
    liste_chemin = os.path.join(depot, "manifest.json")
    if not os.path.exists(liste_chemin):
        print(f"REFUS — aucune liste publiee dans {depot}. Lancez d abord "
              "« dart run tool/publier_sentier.dart publier ... ».")
        return 1

    liste = lire_json(liste_chemin)
    entrees = {e["trailId"]: e for e in liste.get("trails", [])}
    cibles = args.sentiers or sorted(entrees)

    base = Firestore(args.projet, args.base, jeton())
    total_ecrits = 0
    total_marqueurs = 0
    total_inchanges = 0

    for trail_id in cibles:
        entree = entrees.get(trail_id)
        if entree is None:
            print(f"REFUS — « {trail_id} » n est pas dans la liste publiee.")
            return 1

        instant = entree["dataVersion"]
        print(f"{trail_id} — instant publie {instant}")

        # 1. LES DONNEES D ABORD, LA FICHE ENSUITE (#P1). La fiche est la seule
        #    chose que l application interroge pour decider ; l ecrire en premier
        #    ouvrirait une fenetre ou un telephone voit un instant neuf et ne
        #    trouve pas les enregistrements qui vont avec.
        donnees: dict[str, Any] = {}
        chemin_donnees = entree.get("filePath", "")
        if chemin_donnees:
            fichier = os.path.join(depot, chemin_donnees)
            if not os.path.exists(fichier):
                print(f"  REFUS — la liste pointe sur « {chemin_donnees} », absent.")
                return 1
            donnees = lire_json(fichier)

        for famille in FAMILLES:
            publies = enregistrements(donnees.get(famille))
            collection = f"trails/{trail_id}/{famille}"

            en_base = {}
            for document in base.lister(collection):
                identifiant = document["name"].rsplit("/", 1)[-1]
                en_base[identifiant] = {
                    c: depuis_valeur(v)
                    for c, v in document.get("fields", {}).items()
                }

            vus: set[str] = set()
            ecrits = 0
            inchanges = 0
            for enregistrement in publies:
                cle = identite(famille, enregistrement)
                if cle is None:
                    print(f"  REFUS — « {famille} » : un enregistrement sans "
                          "identite ne pourrait etre ni corrige ni retire. "
                          f"{enregistrement}")
                    return 1
                vus.add(cle)

                ancien = en_base.get(cle)
                if ancien is not None and empreinte_de_contenu(
                    ancien
                ) == empreinte_de_contenu(enregistrement):
                    # INCHANGE : on ne le reecrit PAS, donc son `updated_at` ne
                    # bouge pas. C est toute la difference entre un horodatage de
                    # mise a jour et un horodatage de publication.
                    inchanges += 1
                    continue

                # L INSTANT DU DOCUMENT EST CELUI QUE L OUTIL DE PUBLICATION LUI A
                # DONNE, jamais l heure de cette machine : une seule autorite de
                # temps, et c est le calcul selectif du lot 607.
                revision = enregistrement.get(CHAMP_REVISION, instant)
                base.ecrire(
                    f"{collection}/{urllib.parse.quote(cle, safe='')}",
                    champs_firestore(enregistrement, revision),
                )
                ecrits += 1

            # CE QUI A DISPARU — la question qu on oublie. Un marqueur, jamais un
            # effacement : sans lui un hebergement ferme resterait a vie sur le
            # telephone du randonneur.
            marqueurs = 0
            for cle, ancien in en_base.items():
                if cle in vus or ancien.get(CHAMP_SUPPRIME) is True:
                    continue
                marqueur: dict[str, Any] = {CHAMP_SUPPRIME: True}
                if famille == "gpx_points":
                    marqueur["track_id"] = ancien.get("track_id")
                    marqueur["sequence_index"] = ancien.get("sequence_index")
                else:
                    marqueur["id"] = ancien.get("id", cle)
                base.ecrire(
                    f"{collection}/{urllib.parse.quote(cle, safe='')}",
                    champs_firestore(marqueur, instant),
                )
                marqueurs += 1

            if ecrits or marqueurs or inchanges:
                detail = f"  {famille:16s} {ecrits} ecrit(s)"
                if inchanges:
                    detail += f", {inchanges} inchange(s) — updated_at conserve"
                if marqueurs:
                    detail += f", {marqueurs} marqueur(s) de suppression"
                print(detail)
            total_ecrits += ecrits
            total_marqueurs += marqueurs
            total_inchanges += inchanges

        # 2. LA FICHE DU CATALOGUE. C est l entree de liste du manifeste, a plat :
        #    l application y lit le catalogue (nom, prix, distance) ET l instant
        #    publie du sentier. `UpdateChecker` lit deja `data_version` ici.
        fiche_plate: dict[str, Any] = {
            "trail_id": trail_id,
            "data_version": entree["dataVersion"],
            "last_updated": entree["lastUpdated"],
            "hash": entree.get("hash", ""),
            "file_path": entree.get("filePath", ""),
            "file_size": entree.get("fileSize", 0),
            "status": entree.get("status", "active"),
        }
        for optionnel in ("tilesPath", "tilesSize", "tilesHash"):
            if entree.get(optionnel) is not None:
                fiche_plate[en_serpent(optionnel)] = entree[optionnel]
        if entree.get("fiche") is not None:
            fiche_plate["fiche"] = entree["fiche"]

        document = base.lire(f"trails/{trail_id}")
        ancien = (
            {c: depuis_valeur(v) for c, v in (document or {}).get("fields", {}).items()}
            if document
            else None
        )
        if ancien is not None and empreinte_de_contenu(ancien) == empreinte_de_contenu(
            fiche_plate
        ):
            print("  trails/" + trail_id + " — fiche inchangee, updated_at conserve")
        else:
            base.ecrire(f"trails/{trail_id}", champs_firestore(fiche_plate, instant))
            print("  trails/" + trail_id + " — fiche du catalogue ecrite")
            total_ecrits += 1

    print("")
    print(f"{total_ecrits} document(s) ecrit(s), {total_inchanges} inchange(s), "
          f"{total_marqueurs} marqueur(s) de suppression.")
    if total_ecrits == 0 and total_marqueurs == 0:
        print("RIEN N A BOUGE EN BASE — c est le comportement attendu d un second "
              "passage : aucun « updated_at » n a ete touche pour rien.")
    return 0


def commande_verifier(args: argparse.Namespace) -> int:
    """Relit la base et PROUVE ce qui y est, document par document."""
    base = Firestore(args.projet, args.base, jeton())
    cibles = args.sentiers or [
        d["name"].rsplit("/", 1)[-1] for d in base.lister("trails")
    ]
    if not cibles:
        print("La collection « trails » est VIDE.")
        return 1

    anomalies = 0
    for trail_id in cibles:
        document = base.lire(f"trails/{trail_id}")
        if document is None:
            print(f"ABSENT — trails/{trail_id}")
            anomalies += 1
            continue
        champs = {
            c: depuis_valeur(v) for c, v in document.get("fields", {}).items()
        }
        fiche = champs.get("fiche") or {}
        print(f"trails/{trail_id}")
        print(f"  {fiche.get('displayName', '(sans fiche)')} — "
              f"{fiche.get('region', '?')}, {fiche.get('totalStages', '?')} etapes, "
              f"{fiche.get('totalDistanceKm', '?')} km, "
              f"D+ {fiche.get('totalElevationGain', '?')} m")
        print(f"  statut {champs.get('status')} — data_version "
              f"{champs.get('data_version')}")
        print(f"  rev {champs.get(CHAMP_REVISION)} — {CHAMP_HORODATAGE} "
              f"{champs.get(CHAMP_HORODATAGE)}")

        for famille in FAMILLES:
            documents = base.lister(f"trails/{trail_id}/{famille}")
            if not documents:
                continue
            vivants = 0
            marqueurs = 0
            plus_recent = ""
            sans_horodatage = 0
            for d in documents:
                valeurs = {
                    c: depuis_valeur(v) for c, v in d.get("fields", {}).items()
                }
                if valeurs.get(CHAMP_SUPPRIME) is True:
                    marqueurs += 1
                else:
                    vivants += 1
                horodatage = valeurs.get(CHAMP_HORODATAGE)
                if not horodatage:
                    sans_horodatage += 1
                elif horodatage > plus_recent:
                    plus_recent = horodatage
            ligne = (f"  {famille:16s} {vivants} document(s), dernier "
                     f"{CHAMP_HORODATAGE} {plus_recent or 'ABSENT'}")
            if marqueurs:
                ligne += f", {marqueurs} marqueur(s) de suppression"
            print(ligne)
            if sans_horodatage:
                print(f"    ANOMALIE — {sans_horodatage} document(s) sans "
                      f"« {CHAMP_HORODATAGE} » : la demande de Christophe est que "
                      "CHAQUE donnee porte son timestamp de mise a jour.")
                anomalies += 1

    print("")
    if anomalies:
        print(f"{anomalies} anomalie(s).")
        return 1
    print(f"Base conforme, relue le {datetime.now(timezone.utc).isoformat()}.")
    return 0


def main(argv: list[str]) -> int:
    analyseur = argparse.ArgumentParser(
        prog="publier_en_base.py",
        description="Publie un sentier dans Firestore, et le prouve.",
    )
    analyseur.add_argument("--projet", default=PROJET_PAR_DEFAUT)
    analyseur.add_argument("--base", default=BASE_PAR_DEFAUT)
    sous = analyseur.add_subparsers(dest="commande", required=True)

    p_source = sous.add_parser(
        "source", help="fabrique la source de l outil depuis les assets embarques"
    )
    p_source.add_argument("--asset", default="assets/data/mare_a_mare_centre.json")
    p_source.add_argument("--gpx", default="assets/data/mare_a_mare_centre/track.gpx")
    p_source.add_argument(
        "--contenu", default="publication/contenu/mare-a-mare-centre.json"
    )
    p_source.add_argument("--sortie", default="publication/sources")
    p_source.set_defaults(fonction=commande_source)

    p_pousser = sous.add_parser("pousser", help="ecrit le depot publie dans Firestore")
    p_pousser.add_argument("--depot", default="publication/publie")
    p_pousser.add_argument("sentiers", nargs="*")
    p_pousser.set_defaults(fonction=commande_pousser)

    p_verifier = sous.add_parser("verifier", help="relit la base et prouve son contenu")
    p_verifier.add_argument("sentiers", nargs="*")
    p_verifier.set_defaults(fonction=commande_verifier)

    args = analyseur.parse_args(argv)
    return args.fonction(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
