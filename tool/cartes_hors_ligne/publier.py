"""PUBLIE UNE CARTE HORS LIGNE LA OU L APPLICATION LA LIT, ET LE PROUVE.

    python tool/cartes_hors_ligne/publier.py \
        --sentier mare-a-mare-centre \
        --fichier C:/.../mare-a-mare-centre.mbtiles \
        --chemin mare_a_mare_centre/tuiles_z10-15_v20260930.mbtiles

OU L APPLICATION LIT, MESURE AVANT D ECRIRE (30/09, branches 640 et 641) :

  * LE FICHIER. `DescenteDesCartes.descendre` appelle
    `TrailDataSource.urlDonneesSentier(tilesPath)` : un chemin relatif devient
    `https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<data%2F...>?alt=media`.
    Le fichier va donc sous le prefixe `data/` du bucket du projet, et le
    `tilesPath` publie est le chemin SANS ce prefixe.

  * LES TROIS CHAMPS. La ligne locale Drift (`trail_manifests`) porte
    `tilesPath` / `tilesSize` / `tilesHash`, et elle est remplie par
    `ManifestService.saveLocalManifest` depuis l entree de liste. La liste vient
    de DEUX sources depuis le lot 641, dans cet ordre :
      1. la collection Firestore `trails` — champs A PLAT et en `snake_case` :
         `tiles_path`, `tiles_size`, `tiles_hash` ;
      2. a defaut, le fichier `data/manifest.json` du bucket — memes champs en
         `camelCase` (`tilesPath`, `tilesSize`, `tilesHash`).
    Les deux sont ecrites ici : la base fait foi, le fichier est le repli d un
    telephone sans Firebase.

  * L EMPREINTE EST UN SHA-256 en hexadecimal minuscule
    (`EmpreinteDePublication`, prefixe `sha256-` tolere). Elle est verifiee sur
    le telephone AVANT que le fichier ne prenne son nom definitif.

CE SCRIPT NE PORTE AUCUN SECRET. Le jeton d ecriture vient de la variable
`STEPWAYS_GCP_TOKEN` ou, a defaut, de
`gcloud auth application-default print-access-token`.

LA PREUVE EST LA DERNIERE ETAPE, ET ELLE EST SANS AUTHENTIFICATION : le script
retelecharge le fichier par l URL EXACTE que l application construit, sans jeton,
et recalcule taille et empreinte. Un fichier depose mais illisible par un
telephone est un fichier non publie.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

DOSSIER_DONNEES = "data"
BUCKET_DEFAUT = "stepways-app.firebasestorage.app"
PROJET_DEFAUT = "stepways-app"


def jeton() -> str:
    """Le jeton d ecriture, jamais en dur, jamais dans le depot."""
    depuis_env = os.environ.get("STEPWAYS_GCP_TOKEN")
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
        return sortie.stdout.strip()
    except Exception as erreur:  # pragma: no cover
        raise SystemExit(
            "Aucun jeton d ecriture. Posez STEPWAYS_GCP_TOKEN, ou authentifiez "
            f"gcloud (application-default). Detail : {erreur}"
        )


def sha256_du_fichier(chemin: str) -> str:
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for morceau in iter(lambda: f.read(1 << 20), b""):
            h.update(morceau)
    return h.hexdigest()


def _appel(url: str, methode: str = "GET", corps=None, entetes=None, projet=None):
    entetes = dict(entetes or {})
    if projet:
        entetes.setdefault("X-Goog-User-Project", projet)
    requete = urllib.request.Request(url, data=corps, headers=entetes, method=methode)
    with urllib.request.urlopen(requete) as reponse:
        return reponse.status, reponse.read(), dict(reponse.headers)


# ---------------------------------------------------------------------------
# 1. LE FICHIER DANS LE BUCKET
# ---------------------------------------------------------------------------


def televerser(chemin_local: str, bucket: str, objet: str, projet: str, jeton_acces: str) -> dict:
    """Depose [chemin_local] a [objet] dans [bucket], en une seule requete reprise.

    Le televersement passe par l API JSON de Cloud Storage en mode `resumable` :
    un `.mbtiles` fait des dizaines de megaoctets, et un envoi en un bloc qui
    casse a 90 % ne dit meme pas ou il en etait.
    """
    taille = os.path.getsize(chemin_local)
    debut = (
        f"https://storage.googleapis.com/upload/storage/v1/b/{bucket}/o"
        f"?uploadType=resumable&name={urllib.parse.quote(objet, safe='')}"
    )
    metadonnees = json.dumps(
        {
            "name": objet,
            "contentType": "application/octet-stream",
            "cacheControl": "public, max-age=3600",
        }
    ).encode()
    statut, _, entetes = _appel(
        debut,
        "POST",
        metadonnees,
        {
            "Authorization": f"Bearer {jeton_acces}",
            "Content-Type": "application/json; charset=UTF-8",
            "X-Upload-Content-Type": "application/octet-stream",
            "X-Upload-Content-Length": str(taille),
        },
        projet,
    )
    session = entetes.get("Location") or entetes.get("location")
    if not session:
        raise SystemExit("Cloud Storage n a pas ouvert de session de televersement")

    with open(chemin_local, "rb") as f:
        contenu = f.read()
    statut, corps, _ = _appel(
        session,
        "PUT",
        contenu,
        {"Content-Type": "application/octet-stream", "Content-Length": str(taille)},
    )
    return json.loads(corps)


# ---------------------------------------------------------------------------
# 2. LES TROIS CHAMPS EN BASE
# ---------------------------------------------------------------------------


def ecrire_en_base(
    projet: str, sentier: str, chemin: str, taille: int, empreinte: str, jeton_acces: str
) -> dict:
    """Pose `tiles_path`/`tiles_size`/`tiles_hash` sur `trails/{sentier}`.

    ECRITURE PARTIELLE, ET C EST DELIBERE. Un `PATCH` avec masque ne touche QUE
    les champs nommes : `data_version`, `hash`, `file_path` et `file_size`
    decrivent la publication des DONNEES du sentier, pas de sa carte, et les
    reecrire ferait redescendre le fichier de donnees a tous les telephones pour
    rien. `rev` et `updated_at` avancent, eux : c est ce qui rend la
    modification visible dans la console de Christophe.
    """
    instant = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
    champs = {
        "tiles_path": {"stringValue": chemin},
        "tiles_size": {"integerValue": str(taille)},
        "tiles_hash": {"stringValue": empreinte},
        "rev": {"timestampValue": instant},
        "updated_at": {"timestampValue": instant},
    }
    masque = "&".join(f"updateMask.fieldPaths={c}" for c in champs)
    url = (
        f"https://firestore.googleapis.com/v1/projects/{projet}/databases/(default)"
        f"/documents/trails/{urllib.parse.quote(sentier)}?{masque}"
    )
    statut, corps, _ = _appel(
        url,
        "PATCH",
        json.dumps({"fields": champs}).encode(),
        {"Authorization": f"Bearer {jeton_acces}", "Content-Type": "application/json"},
        projet,
    )
    return json.loads(corps)


# ---------------------------------------------------------------------------
# 3. LE REPLI : data/manifest.json
# ---------------------------------------------------------------------------


def mettre_a_jour_le_manifeste(
    manifeste: dict, sentier: str, chemin: str, taille: int, empreinte: str
) -> dict:
    trouve = False
    for entree in manifeste.get("trails", []):
        if entree.get("trailId") == sentier:
            entree["tilesPath"] = chemin
            entree["tilesSize"] = taille
            entree["tilesHash"] = empreinte
            trouve = True
    if not trouve:
        raise SystemExit(f"{sentier} absent du manifeste — rien a mettre a jour")
    return manifeste


# ---------------------------------------------------------------------------
# 4. LA PREUVE
# ---------------------------------------------------------------------------


def url_de_telechargement(bucket: str, chemin_dans_le_bucket: str) -> str:
    """L URL EXACTE que construit `TrailDataSource.urlDe` dans l application."""
    encode = urllib.parse.quote(chemin_dans_le_bucket, safe="")
    return f"https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encode}?alt=media"


def prouver(url: str, taille_attendue: int, empreinte_attendue: str) -> dict:
    """Retelecharge SANS jeton, comme un telephone, et recalcule tout."""
    h = hashlib.sha256()
    recus = 0
    requete = urllib.request.Request(url, headers={"User-Agent": "StepWays/preuve-648"})
    with urllib.request.urlopen(requete) as reponse:
        statut = reponse.status
        while True:
            morceau = reponse.read(1 << 20)
            if not morceau:
                break
            h.update(morceau)
            recus += len(morceau)

    # LA REPRISE EST-ELLE POSSIBLE ? `MBTilesManager` demande `Range: bytes=N-`
    # et attend un 206. Un serveur qui rend 200 fait tout retelecharger — le code
    # le supporte, mais il faut le SAVOIR, pas le supposer.
    reprise = None
    try:
        requete = urllib.request.Request(
            url, headers={"Range": f"bytes={max(0, recus - 1024)}-", "User-Agent": "StepWays/preuve-648"}
        )
        with urllib.request.urlopen(requete) as reponse:
            reprise = reponse.status
    except urllib.error.HTTPError as erreur:
        reprise = erreur.code

    return {
        "statut": statut,
        "octets": recus,
        "empreinte": h.hexdigest(),
        "taille_ok": recus == taille_attendue,
        "empreinte_ok": h.hexdigest() == empreinte_attendue,
        "statut_reprise": reprise,
    }


def main() -> int:
    a = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    a.add_argument("--sentier", required=True)
    a.add_argument("--fichier", required=True, help="le .mbtiles a publier")
    a.add_argument("--chemin", required=True, help="chemin publie, SANS le prefixe data/")
    a.add_argument("--projet", default=PROJET_DEFAUT)
    a.add_argument("--bucket", default=BUCKET_DEFAUT)
    a.add_argument("--manifeste", default=None, help="manifest.json local a publier aussi")
    a.add_argument("--sans-base", action="store_true", help="ne pas ecrire dans Firestore")
    a.add_argument(
        "--preuve-seule", action="store_true", help="ne rien ecrire, seulement verifier"
    )
    args = a.parse_args()

    taille = os.path.getsize(args.fichier)
    empreinte = sha256_du_fichier(args.fichier)
    objet = f"{DOSSIER_DONNEES}/{args.chemin}"
    url = url_de_telechargement(args.bucket, objet)

    print("CE QUI VA ETRE PUBLIE")
    print(f"  fichier  : {args.fichier}")
    print(f"  taille   : {taille} octets")
    print(f"  SHA-256  : {empreinte}")
    print(f"  objet    : gs://{args.bucket}/{objet}")
    print(f"  URL lue par l application : {url}")
    print(f"  tilesPath publie : {args.chemin}")

    if not args.preuve_seule:
        acces = jeton()
        print("1. TELEVERSEMENT")
        info = televerser(args.fichier, args.bucket, objet, args.projet, acces)
        print(f"  depose : {info.get('name')} ({info.get('size')} octets, gen {info.get('generation')})")

        if not args.sans_base:
            print("2. LES TROIS CHAMPS EN BASE (Firestore trails/{id})")
            doc = ecrire_en_base(args.projet, args.sentier, args.chemin, taille, empreinte, acces)
            champs = doc.get("fields", {})
            print(
                "  tiles_path="
                + str(champs.get("tiles_path", {}).get("stringValue"))
                + " tiles_size="
                + str(champs.get("tiles_size", {}).get("integerValue"))
                + " rev="
                + str(champs.get("rev", {}).get("timestampValue"))
            )

        if args.manifeste:
            print("3. LE REPLI (data/manifest.json)")
            manifeste = json.load(open(args.manifeste, encoding="utf-8"))
            manifeste = mettre_a_jour_le_manifeste(
                manifeste, args.sentier, args.chemin, taille, empreinte
            )
            temporaire = args.manifeste + ".publie"
            with open(temporaire, "w", encoding="utf-8") as f:
                json.dump(manifeste, f, ensure_ascii=False, indent=2)
            info = televerser(
                temporaire, args.bucket, f"{DOSSIER_DONNEES}/manifest.json", args.projet, acces
            )
            print(f"  depose : {info.get('name')} ({info.get('size')} octets)")

    print("4. PREUVE — TELECHARGEMENT REEL, SANS JETON")
    bilan = prouver(url, taille, empreinte)
    print(f"  HTTP {bilan['statut']}, {bilan['octets']} octets")
    print(f"  taille    : {'CONFORME' if bilan['taille_ok'] else 'NON CONFORME'}")
    print(f"  empreinte : {'CONFORME' if bilan['empreinte_ok'] else 'NON CONFORME'}")
    print(f"  reprise (Range) : HTTP {bilan['statut_reprise']}"
          + (" — 206, la reprise fonctionne" if bilan["statut_reprise"] == 206 else ""))
    return 0 if bilan["taille_ok"] and bilan["empreinte_ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
