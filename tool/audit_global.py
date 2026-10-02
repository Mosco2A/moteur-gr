#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Audit global du depot Moteur-GR : rejoue les mesures de l inventaire 644.

Outil de MESURE, en LECTURE SEULE. Aucun fichier du depot n est modifie.
Il est rejoue apres chaque lot d assainissement pour verifier que le code
est propre (demande de Christophe, 30/09, memoire #100914).

Chaque mesure porte le numero de la regle ECR qu elle controle
(referentiel ECR-01 a ECR-32, memoires #100232 a #100241).

Usage :
    python tool/audit_global.py                 # rapport texte
    python tool/audit_global.py --json          # rapport machine
    python tool/audit_global.py --json-out F    # ecrit le JSON dans F
    python tool/audit_global.py --section NOM   # une seule section
    python tool/audit_global.py --strict        # code retour 1 si bloquant
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime

# --- Reperage du depot ----------------------------------------------------

TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(TOOL_DIR)

LIB = os.path.join(REPO, "lib")
TEST = os.path.join(REPO, "test")

# Zones autorisees a la racine de lib/ (ECR-13).
LIB_RACINE_AUTORISEE = {"core", "features", "shared", "i18n", "main.dart"}

# Suffixes des fichiers produits par la generation de code : exclus de
# toutes les mesures de qualite (ECR-15, ECR-20, ECR-01...).
SUFFIXES_GENERES = (".g.dart", ".freezed.dart", ".gr.dart", ".config.dart")

# Boutons bruts du framework, interdits hors du composant unique (ECR-19).
# PERIMETRE STRICT : les 4 boutons nommes par le referentiel ECR-19, seuls
# comparables a la mesure de depart du 21/09 (58 occurrences, 24 fichiers).
BOUTONS_STRICTS = ("ElevatedButton", "TextButton", "OutlinedButton",
                   "FilledButton")
# PERIMETRE ETENDU : ajoute les boutons que l audit 644 a trouves en plus.
BOUTONS_ETENDUS = BOUTONS_STRICTS + ("IconButton", "CupertinoButton")
COMPOSANT_BOUTON = "lib/shared/widgets/app_button.dart"
# La definition du theme DOIT citer les boutons du framework : c est son
# role (ElevatedButtonThemeData, ElevatedButton.styleFrom). Verifie le
# 02/10/2026 dans lib/core/theme/app_theme.dart lignes 265 a 287 et 407.
ZONES_BOUTON_LEGITIMES = (COMPOSANT_BOUTON, "lib/core/theme/")

# Paquets d acces aux donnees interdits dans la couche presentation (ECR-25).
PAQUETS_DONNEES = ("package:http/", "package:dio/", "package:drift/",
                   "package:cloud_firestore/", "package:firebase_storage/",
                   "package:sqflite/")

# Valeurs a completer : marqueurs de code non fini livre en production.
# Motifs ANCRES par frontiere de mot : sans cela, "changeme" est trouve dans
# le mot francais "changement" et "placeholder" dans le parametre legitime
# placeholder: de Flutter. Chaque trouvaille est ensuite classee code ou
# commentaire, car un commentaire qui PARLE de example.org n est pas une
# valeur a completer.
MARQUEURS_A_COMPLETER = (
    ("example.org", r"example\.org"),
    ("example.com", r"example\.com"),
    ("a completer", r"[AÀ]\s*COMPL[EÉ]TER|a\s+completer"),
    ("changeme", r"\bCHANGE_?ME\b|\bchange_?me\b"),
    ("votre-", r"\bvotre-|\byour-"),
    ("adresse bidon", r"\bxxx@|\bfoo@|\btest@test\b"),
    ("localhost", r"\blocalhost\b|127\.0\.0\.1"),
    ("lorem ipsum", r"[Ll]orem\s+ipsum"),
    ("valeur bidon", r"\bdummy\b|\bbidon\b|\bfake_?[A-Za-z]*\b"),
    ("numero nul", r"\b0{7,}\b"),
)

# Mots francais frequents dans les identifiants : detection d ECR-05.
# Liste fermee, volontairement courte, pour ne signaler que du certain.
MOTS_FRANCAIS = [
    "etape", "etapes", "sentier", "sentiers", "randonnee", "randonneur",
    "denivele", "duree", "sac", "poids", "charge", "meteo", "carte",
    "cartes", "ecran", "bouton", "liste", "fiche", "compte", "profil",
    "reglage", "reglages", "parametre", "parcours", "balise",
    "refuge", "gite", "bivouac", "secours", "urgence", "alerte",
    "souvenir", "diplome", "classement", "groupe", "partage",
    "abonnement", "publicite", "consentement", "verrou", "connexion",
    "deconnexion", "enregistrer", "charger", "calculer", "afficher",
    "mettre", "ajouter", "supprimer", "chercher", "trouver", "valider",
    "annuler", "fermer", "ouvrir", "demarrer", "arreter", "terminer",
    "dormant", "dormants", "porte", "portes", "volet", "miette",
    "miettes", "cordeau", "lot", "lots", "jalon", "borne", "bornes",
]

# Homographes anglais retires de la liste des mots francais apres
# verification sur le depot le 02/10/2026 : "trace" (StackTrace, tracer,
# session_trace_painter) et "journal" (mot anglais courant) produisaient des
# faux positifs. Les identifiants ci-dessous sont exclus nominativement.
EXCEPTIONS_FRANCAIS = ("carteSize", "listen", "listener", "listeners",
                       "chargerPort", "portefolio", "important",
                       "transportation", "supported", "deported")

# Prefixes des ecrans, pour la mesure d observabilite.
SUFFIXE_ECRAN = "_screen.dart"
APPELS_CRASHLYTICS = ("recordError", "setCustomKey", "log(", "miette",
                      "Miette", "breadcrumb", "Breadcrumb",
                      "FirebaseCrashlytics", "crashlytics")


# --- Utilitaires ----------------------------------------------------------

def est_genere(chemin: str) -> bool:
    """Vrai si le fichier est produit par la generation de code."""
    return chemin.endswith(SUFFIXES_GENERES)


def lister_dart(racine: str, avec_generes: bool = False) -> list[str]:
    """Liste les .dart sous `racine`, en chemins relatifs au depot."""
    trouves = []
    for dossier, sous, fichiers in os.walk(racine):
        sous[:] = [d for d in sous if d not in (".dart_tool", "build")]
        for f in fichiers:
            if not f.endswith(".dart"):
                continue
            chemin = os.path.join(dossier, f)
            if not avec_generes and est_genere(chemin):
                continue
            trouves.append(os.path.relpath(chemin, REPO).replace("\\", "/"))
    return sorted(trouves)


def lire(rel: str) -> str:
    """Lit un fichier du depot en UTF-8 tolerant."""
    chemin = os.path.join(REPO, rel)
    with open(chemin, "r", encoding="utf-8", errors="replace") as fh:
        return fh.read()


def lignes_de(rel: str) -> list[str]:
    """Retourne les lignes d un fichier, sans fin de ligne."""
    return lire(rel).splitlines()


# Emplacements usuels du SDK Flutter. Sous Windows, flutter et dart sont des
# .bat que subprocess ne trouve pas par le PATH du shell POSIX : il faut le
# chemin complet. Verifie le 02/10/2026 : C:\flutter\bin existe sur la
# machine de Christophe.
RACINES_SDK = (r"C:\flutter\bin", r"C:\src\flutter\bin",
               os.path.expanduser(r"~\flutter\bin"),
               "/usr/local/flutter/bin", "/opt/flutter/bin")


def resoudre(binaire: str) -> str | None:
    """Chemin complet d un executable du SDK, ou None s il est introuvable."""
    import shutil
    trouve = shutil.which(binaire)
    if trouve:
        return trouve
    for racine in RACINES_SDK:
        for suffixe in (".bat", ".exe", ""):
            candidat = os.path.join(racine, binaire + suffixe)
            if os.path.isfile(candidat):
                return candidat
    return None


def commande(args: list[str], cwd: str | None = None) -> tuple[int, str]:
    """Execute une commande et retourne (code, sortie). Jamais d exception.

    Le premier element d `args` est resolu contre le PATH puis contre les
    emplacements usuels du SDK Flutter. Un code 127 signifie que la
    commande est absente de la machine : la mesure est alors declaree
    INDISPONIBLE, jamais zero.
    """
    complet = resoudre(args[0])
    if complet is None:
        return 127, f"commande absente de la machine : {args[0]}"
    try:
        proc = subprocess.run([complet] + args[1:], cwd=cwd or REPO,
                              capture_output=True, text=True,
                              encoding="utf-8", errors="replace",
                              timeout=900)
        return proc.returncode, (proc.stdout or "") + (proc.stderr or "")
    except OSError as err:
        return 127, f"commande inexecutable : {err}"
    except subprocess.TimeoutExpired:
        return 124, "depassement de delai"


def decoupler_identifiants(texte: str) -> list[str]:
    """Extrait les identifiants d un source Dart, hors chaines et commentaires."""
    sans_doc = re.sub(r"^\s*///.*$", "", texte, flags=re.M)
    sans_bloc = re.sub(r"/\*.*?\*/", " ", sans_doc, flags=re.S)
    sans_ligne = re.sub(r"(?<!:)//.*$", "", sans_bloc, flags=re.M)
    sans_chaines = re.sub(r"'''.*?'''|\"\"\".*?\"\"\"", " ", sans_ligne,
                          flags=re.S)
    sans_chaines = re.sub(r"'(?:\\.|[^'\\])*'", " ", sans_chaines)
    sans_chaines = re.sub(r'"(?:\\.|[^"\\])*"', " ", sans_chaines)
    return re.findall(r"[A-Za-z_][A-Za-z0-9_]*", sans_chaines)


# --- Section 1 : arborescence et volumes (ECR-13, ECR-15) -----------------

def mesurer_arborescence() -> dict:
    """Fichiers et lignes par zone, et respect de la racine de lib/."""
    res: dict = {"zones": {}, "racine_lib": {}, "tailles": {}}

    for nom, racine in (("lib", LIB), ("test", TEST),
                        ("tool", os.path.join(REPO, "tool")),
                        ("integration_test",
                         os.path.join(REPO, "integration_test"))):
        if not os.path.isdir(racine):
            continue
        source = lister_dart(racine)
        tous = lister_dart(racine, avec_generes=True)
        n_lignes = sum(len(lignes_de(f)) for f in source)
        res["zones"][nom] = {
            "fichiers_source": len(source),
            "fichiers_generes": len(tous) - len(source),
            "lignes_source": n_lignes,
        }

    # Detail par sous-dossier de lib/ (deux niveaux).
    detail = {}
    for zone in ("core", "features", "shared", "i18n"):
        base = os.path.join(LIB, zone)
        if not os.path.isdir(base):
            continue
        for entree in sorted(os.listdir(base)):
            chemin = os.path.join(base, entree)
            if not os.path.isdir(chemin):
                continue
            fics = lister_dart(chemin)
            detail[f"lib/{zone}/{entree}"] = {
                "fichiers": len(fics),
                "lignes": sum(len(lignes_de(f)) for f in fics),
            }
    res["detail_lib"] = detail

    # ECR-13 : la racine de lib/ ne porte que les zones autorisees.
    presents = set(os.listdir(LIB))
    res["racine_lib"] = {
        "presents": sorted(presents),
        "intrus": sorted(presents - LIB_RACINE_AUTORISEE),
    }

    # ECR-15 : repartition des tailles de fichier.
    seaux = {"<=300": 0, "301-500": 0, "501-800": 0, ">800": 0}
    hors_plafond = []
    for f in lister_dart(LIB):
        n = len(lignes_de(f))
        if n <= 300:
            seaux["<=300"] += 1
        elif n <= 500:
            seaux["301-500"] += 1
        elif n <= 800:
            seaux["501-800"] += 1
        else:
            seaux[">800"] += 1
        if n > 500:
            hors_plafond.append((f, n))
    res["tailles"] = {
        "repartition": seaux,
        "au_dela_de_500": sorted(hors_plafond, key=lambda x: -x[1]),
        "nombre_au_dela_de_500": len(hors_plafond),
    }
    return res


# --- Section 2 : code mort (symboles sans appelant) -----------------------

def mesurer_code_mort() -> dict:
    """Symboles declares dans lib/ et jamais cites ailleurs.

    Methode : on releve les declarations de haut niveau (classe, enum,
    mixin, extension, fonction de premier niveau) de chaque fichier de
    lib/, puis on compte les citations du nom dans TOUT le depot Dart
    (lib/, test/, integration_test/, tool/) hors le fichier qui le
    declare. Zero citation = candidat au code mort.

    Limite assumee et declaree : la citation par chaine de caracteres
    ou par reflexion n est pas vue. La liste est donc une liste de
    CANDIDATS, a confirmer un par un avant suppression.
    """
    motif_decl = re.compile(
        r"^(?:abstract\s+|sealed\s+|final\s+|base\s+|interface\s+)*"
        r"(class|enum|mixin|extension|typedef)\s+([A-Z_][A-Za-z0-9_]*)",
        re.M)
    motif_fonction = re.compile(
        r"^(?:Future<[^>]*>|Stream<[^>]*>|void|bool|int|double|String|"
        r"List<[^>]*>|Map<[^>]*>|[A-Z][A-Za-z0-9_<>,\s?]*)\s+"
        r"([a-z_][A-Za-z0-9_]*)\s*\(", re.M)

    declarations: dict[str, str] = {}
    for f in lister_dart(LIB):
        texte = lire(f)
        for _, nom in motif_decl.findall(texte):
            if nom.startswith("_"):
                continue
            declarations.setdefault(nom, f)
        for nom in motif_fonction.findall(texte):
            if nom.startswith("_") or nom in ("main", "build", "if", "for",
                                              "while", "switch", "return",
                                              "catch"):
                continue
            declarations.setdefault(nom, f)

    # Index des citations sur tout le code Dart du depot.
    citations: dict[str, set[str]] = defaultdict(set)
    sources = []
    for racine in (LIB, TEST, os.path.join(REPO, "integration_test"),
                   os.path.join(REPO, "tool")):
        if os.path.isdir(racine):
            sources += lister_dart(racine, avec_generes=True)
    for f in sources:
        mots = set(decoupler_identifiants(lire(f)))
        for mot in mots:
            if mot in declarations:
                citations[mot].add(f)

    morts = []
    for nom, origine in sorted(declarations.items()):
        ailleurs = citations.get(nom, set()) - {origine}
        if not ailleurs:
            ligne = 0
            for i, l in enumerate(lignes_de(origine), 1):
                if re.search(rf"\b{re.escape(nom)}\b", l):
                    ligne = i
                    break
            morts.append({"symbole": nom, "fichier": origine, "ligne": ligne})

    return {
        "declarations_publiques": len(declarations),
        "candidats_morts": morts,
        "nombre_candidats": len(morts),
        "methode": ("declarations de haut niveau de lib/ sans aucune citation "
                    "dans lib/ test/ integration_test/ tool/ hors leur propre "
                    "fichier ; citation par chaine ou reflexion non vue"),
    }


# --- Section 3 : doublons (ECR-20) ----------------------------------------

def mesurer_doublons() -> dict:
    """Noms de fichier en double dans lib/, et blocs repetes (ECR-18)."""
    par_nom: dict[str, list[str]] = defaultdict(list)
    for f in lister_dart(LIB):
        par_nom[os.path.basename(f)].append(f)
    doublons_nom = {n: v for n, v in sorted(par_nom.items()) if len(v) > 1}

    # ECR-18 : blocs de 6 lignes non triviales repetes 3 fois ou plus.
    empreintes: dict[str, list[str]] = defaultdict(list)
    for f in lister_dart(LIB):
        utiles = [(i, l.strip()) for i, l in enumerate(lignes_de(f), 1)
                  if l.strip() and not l.strip().startswith(("//", "///"))]
        for k in range(len(utiles) - 5):
            bloc = [t for _, t in utiles[k:k + 6]]
            if sum(len(t) for t in bloc) < 120:
                continue
            cle = "\n".join(bloc)
            empreintes[cle].append(f"{f}:{utiles[k][0]}")

    clones = []
    for cle, lieux in empreintes.items():
        if len(lieux) >= 3:
            clones.append({"occurrences": len(lieux), "lieux": lieux[:6],
                           "extrait": cle.splitlines()[0][:90]})
    clones.sort(key=lambda c: -c["occurrences"])

    return {
        "noms_en_double": doublons_nom,
        "nombre_noms_en_double": len(doublons_nom),
        "blocs_repetes_3_fois": clones[:40],
        "nombre_blocs_repetes": len(clones),
        "methode": ("basename des .dart de lib/ hors generes ; blocs de 6 "
                    "lignes non vides non commentaires, au moins 120 "
                    "caracteres, repetes 3 fois ou davantage"),
    }


# --- Section 4 : documentation et commentaires (ECR-01 a ECR-07) ----------

def mesurer_documentation() -> dict:
    """En-tetes de fichier, commentaires morts, TODO sans tache, lib/docs."""
    sans_entete = []
    for f in lister_dart(LIB):
        trois = lignes_de(f)[:3]
        if not any(l.lstrip().startswith("///") for l in trois):
            sans_entete.append(f)

    # ECR-04 : code commente livre.
    motif_code_commente = re.compile(
        r"^\s*//\s*(final|var|const|return|if\s*\(|import\s|await|"
        r"Navigator\.|setState|print\()")
    code_commente = []
    todo_sans_tache = []
    # Le marqueur doit OUVRIR le commentaire. Sans cette ancre, on attrape
    # les phrases qui PARLENT d un TODO passe et les gabarits de format
    # ecrits XXXX dans un doc comment : 5 faux positifs sur 5 mesures le
    # 02/10/2026, dont finisher_number.dart:20 (format SW-AAAAMMJJ-XXXX).
    motif_todo = re.compile(r"^\s*//+\s*(TODO|FIXME|HACK)\b", re.I)
    motif_tache = re.compile(r"#\d{2,}|\b\d{3,}\b|TODO\([^)]+\)|tache\s*\d+",
                             re.I)
    for f in lister_dart(LIB):
        for i, l in enumerate(lignes_de(f), 1):
            if motif_code_commente.match(l):
                code_commente.append(f"{f}:{i}: {l.strip()[:80]}")
            if motif_todo.match(l) and not motif_tache.search(l):
                todo_sans_tache.append(f"{f}:{i}: {l.strip()[:100]}")

    # ECR-03 : commentaire bavard (plus de 60 pct des mots dans la ligne
    # de code qui suit). Echantillon mesure sur tout lib/.
    bavards = []
    for f in lister_dart(LIB):
        lignes = lignes_de(f)
        for i in range(len(lignes) - 1):
            c = lignes[i].strip()
            if not c.startswith("//") or c.startswith("///"):
                continue
            mots = [m.lower() for m in re.findall(r"[A-Za-zÀ-ÿ]{3,}",
                                                  c.lstrip("/ "))]
            if len(mots) < 3:
                continue
            suite = lignes[i + 1].lower()
            dedans = sum(1 for m in mots if m in suite)
            if dedans / len(mots) > 0.6:
                bavards.append(f"{f}:{i + 1}: {c[:90]}")

    # ECR-07 : documentation deposee en .dart dans lib/.
    doc_en_dart = [f for f in lister_dart(LIB, avec_generes=True)
                   if "/docs/" in f]
    # Les fichiers generes portent legitimement // ignore_for_file: type=lint
    # (mesure du 02/10/2026 : 120 des 123 occurrences). Seuls les fichiers
    # SOURCE qui desarment l analyseur sont un defaut.
    desarmements = []
    for f in lister_dart(LIB):
        for i, l in enumerate(lignes_de(f), 1):
            if "ignore_for_file" in l:
                desarmements.append(f"{f}:{i}: {l.strip()[:90]}")

    total = len(lister_dart(LIB))
    return {
        "fichiers_source": total,
        "sans_entete": sans_entete,
        "nombre_sans_entete": len(sans_entete),
        "part_avec_entete_pct": round(100 * (total - len(sans_entete)) /
                                      max(total, 1), 1),
        "code_commente": code_commente,
        "nombre_code_commente": len(code_commente),
        "todo_sans_tache": todo_sans_tache,
        "nombre_todo_sans_tache": len(todo_sans_tache),
        "commentaires_bavards": bavards[:60],
        "nombre_commentaires_bavards": len(bavards),
        "doc_en_dart_dans_lib": doc_en_dart,
        "desarmements_analyseur": desarmements,
        "methode": ("en-tete = une des 3 premieres lignes commence par /// ; "
                    "bavard = plus de 60 pct des mots de 3 lettres ou plus du "
                    "commentaire presents dans la ligne de code suivante"),
    }


# --- Section 5 : identifiants en francais (ECR-05) ------------------------

def mesurer_langue() -> dict:
    """Identifiants portant un mot francais, par dossier et nominativement."""
    motifs = [(m, re.compile(rf"(?:^|[^A-Za-z]){m}(?![a-z])|"
                             rf"(?:[a-z]){m[0].upper()}{m[1:]}(?![a-z])",
                             re.I)) for m in MOTS_FRANCAIS]

    par_dossier: Counter = Counter()
    touches: dict[str, list[str]] = defaultdict(list)
    noms_fichiers = []
    for f in lister_dart(LIB):
        base = os.path.basename(f)
        for mot in MOTS_FRANCAIS:
            if re.search(rf"(^|_){mot}($|_)", base[:-5]):
                noms_fichiers.append(f)
                break
        identifiants = set(decoupler_identifiants(lire(f)))
        trouves = set()
        for ident in identifiants:
            if ident in EXCEPTIONS_FRANCAIS or len(ident) < 4:
                continue
            for mot, motif in motifs:
                if motif.search(ident):
                    trouves.add(ident)
                    break
        if trouves:
            dossier = "/".join(f.split("/")[:3])
            par_dossier[dossier] += len(trouves)
            touches[f] = sorted(trouves)[:12]

    return {
        "par_dossier": dict(sorted(par_dossier.items(),
                                   key=lambda kv: -kv[1])),
        "total_identifiants_francais": sum(par_dossier.values()),
        "fichiers_touches": len(touches),
        "noms_de_fichier_francais": sorted(noms_fichiers),
        "nombre_noms_de_fichier_francais": len(noms_fichiers),
        "echantillon": dict(list(sorted(touches.items()))[:40]),
        "methode": (f"liste fermee de {len(MOTS_FRANCAIS)} mots francais "
                    "cherches dans les identifiants, hors chaines et "
                    "commentaires ; identifiants de moins de 4 lettres "
                    "ignores"),
    }


# --- Section 6 : couches et rangement (ECR-13, ECR-23, ECR-25) -----------

def mesurer_couches() -> dict:
    """Sens des dependances, croisements entre features, couche presentation."""
    motif_import = re.compile(r"""import\s+['"]([^'"]+)['"]""")

    socle_vers_feature = []
    croisements = []
    presentation_donnees = []

    for f in lister_dart(LIB):
        texte = lire(f)
        imports = motif_import.findall(texte)
        zone = f.split("/")[1] if f.count("/") >= 1 else ""
        ma_feature = f.split("/")[2] if f.startswith("lib/features/") else None

        for imp in imports:
            # ECR-23 : core/ et shared/ ne connaissent aucune feature.
            if zone in ("core", "shared") and (
                    "features/" in imp or imp.startswith("../features")):
                socle_vers_feature.append(f"{f} -> {imp}")
            # ECR-23 : pas de croisement entre deux features.
            if ma_feature:
                autre = None
                m = re.search(r"features/([a-z_0-9]+)/", imp)
                if m:
                    autre = m.group(1)
                elif imp.startswith("../../"):
                    m2 = re.search(r"\.\./\.\./([a-z_0-9]+)/", imp)
                    if m2 and m2.group(1) not in ("core", "shared", "i18n"):
                        autre = m2.group(1)
                if autre and autre != ma_feature:
                    croisements.append(f"{f} -> {imp}")
            # ECR-25 : la presentation n accede pas aux donnees.
            if "/presentation/" in f or f.endswith(SUFFIXE_ECRAN):
                if imp.startswith(PAQUETS_DONNEES) or imp.endswith("_dao.dart"):
                    presentation_donnees.append(f"{f} -> {imp}")

    # Rangement : fichiers de feature sans couche identifiable.
    couches = ("presentation", "domain", "data", "application", "widgets",
               "providers", "models", "services", "state")
    hors_couche = []
    for f in lister_dart(LIB):
        if not f.startswith("lib/features/"):
            continue
        parts = f.split("/")
        if len(parts) == 4:  # lib/features/<nom>/<fichier>.dart
            hors_couche.append(f)
        elif len(parts) >= 5 and parts[3] not in couches:
            hors_couche.append(f)

    return {
        "socle_vers_feature": socle_vers_feature,
        "nombre_socle_vers_feature": len(socle_vers_feature),
        "croisements_entre_features": croisements,
        "nombre_croisements": len(croisements),
        "presentation_accede_aux_donnees": presentation_donnees,
        "nombre_presentation_donnees": len(presentation_donnees),
        "fichiers_de_feature_hors_couche": hors_couche,
        "nombre_hors_couche": len(hors_couche),
        "couches_reconnues": list(couches),
        "methode": ("lecture des directives import de chaque fichier de "
                    "lib/ ; une feature est le 3e segment du chemin"),
    }


# --- Section 7 : composant unique et valeurs en dur (ECR-19, ECR-24) -----

def mesurer_composants_et_valeurs() -> dict:
    """Boutons bruts, couleurs en dur, dialogues hors routeur."""
    stricts: dict[str, list[str]] = defaultdict(list)
    etendus: dict[str, list[str]] = defaultdict(list)
    # UN APPEL, PAS UNE MENTION (correction du 02/10/2026, tache 645-03). Un nom
    # de bouton ECRIT DANS UN COMMENTAIRE n appelle rien, il en parle : au
    # 02/10, 31 des 153 lignes relevees etaient des phrases du genre
    # « SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary », soit la trace
    # d une conversion DEJA FAITE. Les compter revenait a reprocher au depot
    # d avoir documente son assainissement. Le volet commentaire est donne a
    # part, comme pour les valeurs a completer juste en dessous : il informe,
    # il ne bloque pas.
    stricts_commentaire: dict[str, list[str]] = defaultdict(list)
    couleurs = []
    dialogues = []
    for f in lister_dart(LIB):
        legitime = any(f.startswith(z) or f == z
                       for z in ZONES_BOUTON_LEGITIMES)
        for i, l in enumerate(lignes_de(f), 1):
            if not legitime:
                en_commentaire = l.lstrip().startswith(("//", "///", "*"))
                for b in BOUTONS_ETENDUS:
                    if re.search(rf"\b{b}\s*\(|\b{b}\.(icon|styleFrom)", l):
                        if en_commentaire:
                            if b in BOUTONS_STRICTS:
                                stricts_commentaire[f].append(f"{i}:{b}")
                            continue
                        etendus[f].append(f"{i}:{b}")
                        if b in BOUTONS_STRICTS:
                            stricts[f].append(f"{i}:{b}")
            if re.search(r"Color\(0x[0-9a-fA-F]{6,8}\)", l):
                if "/core/theme/" not in f and "/core/branding/" not in f:
                    couleurs.append(f"{f}:{i}: {l.strip()[:80]}")
            if re.search(r"\bshowDialog\s*(<|\()|\bshowModalBottomSheet\s*(<|\()",
                         l):
                dialogues.append(f"{f}:{i}")

    total_stricts = sum(len(v) for v in stricts.values())
    total_etendus = sum(len(v) for v in etendus.values())
    motifs_vac = [(nom, re.compile(m)) for nom, m in MARQUEURS_A_COMPLETER]
    dans_code, dans_commentaire = [], []
    for f in lister_dart(LIB):
        for i, l in enumerate(lignes_de(f), 1):
            est_commentaire = l.lstrip().startswith(("//", "///", "*"))
            for nom, motif in motifs_vac:
                if motif.search(l):
                    entree = f"{f}:{i}: {nom} | {l.strip()[:80]}"
                    (dans_commentaire if est_commentaire
                     else dans_code).append(entree)
                    break
    a_completer = dans_code

    return {
        "boutons_bruts_par_fichier": {k: v for k, v in
                                      sorted(stricts.items(),
                                             key=lambda kv: -len(kv[1]))},
        "total_boutons_bruts": total_stricts,
        "fichiers_avec_boutons_bruts": len(stricts),
        "total_boutons_perimetre_etendu": total_etendus,
        "fichiers_perimetre_etendu": len(etendus),
        "boutons_etendus_par_fichier": {k: v for k, v in
                                        sorted(etendus.items(),
                                               key=lambda kv: -len(kv[1]))},
        "boutons_bruts_en_commentaire": {k: v for k, v in
                                         sorted(stricts_commentaire.items(),
                                                key=lambda kv: -len(kv[1]))},
        "total_boutons_bruts_en_commentaire": sum(
            len(v) for v in stricts_commentaire.values()),
        "reference_21_09": {"occurrences": 58, "fichiers": 24,
                            "source": "memoire #100235, regle ECR-19"},
        "couleurs_en_dur": couleurs,
        "nombre_couleurs_en_dur": len(couleurs),
        "dialogues": dialogues,
        "nombre_dialogues": len(dialogues),
        "valeurs_a_completer": a_completer,
        "nombre_valeurs_a_completer": len(a_completer),
        "valeurs_a_completer_en_commentaire": dans_commentaire,
        "nombre_en_commentaire": len(dans_commentaire),
        "methode": ("appel des boutons du framework hors "
                    "lib/shared/widgets/app_button.dart, comptes SEULEMENT "
                    "hors commentaire (le volet commentaire est donne a part, "
                    "il n est pas bloquant) ; Color(0x hors "
                    "core/theme et core/branding ; valeurs a completer : "
                    "10 motifs ancres par frontiere de mot, comptees "
                    "SEULEMENT hors commentaire (le volet commentaire est "
                    "donne a part, il n est pas bloquant)"),
    }


# --- Section 8 : taille et complexite (ECR-28, ECR-29, ECR-31) -----------

def mesurer_complexite() -> dict:
    """Longueur des fonctions, imbrication, complexite cyclomatique.

    Mesure par comptage d accolades, sans analyseur Dart : approchee mais
    reproductible. Elle sert de metrique de progression, pas de verite
    syntaxique. Une fonction = une signature suivie d un bloc accolade au
    meme niveau.
    """
    motif_sig = re.compile(
        r"^\s{2,}(?:@override\s+)?(?:static\s+|final\s+)?"
        r"(?:[A-Za-z_][\w<>,\s?\[\]]*\s+)?([A-Za-z_]\w*)\s*\([^;]*$|"
        r"^\s{2,}(?:[A-Za-z_][\w<>,\s?\[\]]*\s+)?([A-Za-z_]\w*)\s*\([^)]*\)"
        r"\s*(?:async\s*|async\*\s*|sync\*\s*)?\{")
    mots_branche = re.compile(
        r"\b(if|for|while|case|catch|\?\?|&&|\|\|)\b|\?[^:]*:")

    longues, profondes, complexes = [], [], []
    total_fonctions = 0

    for f in lister_dart(LIB):
        lignes = lignes_de(f)
        i = 0
        while i < len(lignes):
            m = motif_sig.match(lignes[i])
            if not m or lignes[i].strip().startswith(("//", "///", "return")):
                i += 1
                continue
            nom = m.group(1) or m.group(2) or "?"
            # Recherche de l accolade ouvrante dans les 4 lignes suivantes.
            j, ouvre = i, -1
            while j < min(i + 5, len(lignes)):
                if "{" in lignes[j]:
                    ouvre = j
                    break
                if ";" in lignes[j] or "=>" in lignes[j]:
                    break
                j += 1
            if ouvre < 0:
                i += 1
                continue
            # Parcours du corps en comptant les accolades.
            niveau, maxi, fin = 0, 0, ouvre
            branches = 1
            for k in range(ouvre, len(lignes)):
                ligne = re.sub(r"'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\"", "''",
                               lignes[k])
                ligne = re.sub(r"//.*$", "", ligne)
                branches += len(mots_branche.findall(ligne))
                for ch in ligne:
                    if ch == "{":
                        niveau += 1
                        maxi = max(maxi, niveau)
                    elif ch == "}":
                        niveau -= 1
                        if niveau == 0:
                            fin = k
                            break
                if niveau == 0 and k > ouvre:
                    fin = k
                    break
            taille = fin - i + 1
            total_fonctions += 1
            if taille > 60:
                longues.append({"fichier": f, "ligne": i + 1, "nom": nom,
                                "lignes": taille})
            if maxi > 5:  # 1 niveau = le corps lui-meme
                profondes.append({"fichier": f, "ligne": i + 1, "nom": nom,
                                  "imbrication": maxi - 1})
            if branches > 10:
                complexes.append({"fichier": f, "ligne": i + 1, "nom": nom,
                                  "complexite": branches})
            i = max(fin, i + 1)

    longues.sort(key=lambda d: -d["lignes"])
    profondes.sort(key=lambda d: -d["imbrication"])
    complexes.sort(key=lambda d: -d["complexite"])
    return {
        "fonctions_mesurees": total_fonctions,
        "au_dela_de_60_lignes": longues[:60],
        "nombre_au_dela_de_60_lignes": len(longues),
        "imbrication_au_dela_de_4": profondes[:40],
        "nombre_imbrication_excessive": len(profondes),
        "complexite_au_dela_de_10": complexes[:40],
        "nombre_complexite_excessive": len(complexes),
        "methode": ("comptage d accolades, sans analyseur Dart : mesure "
                    "approchee et reproductible ; complexite = 1 + nombre de "
                    "mots de branchement (if for while case catch ?? && || ?:)"),
    }


# --- Section 9 : tests ----------------------------------------------------

def mesurer_tests() -> dict:
    """Nombre de tests, tests ignores, tests sans assertion, miroir de lib/."""
    fichiers = [f for f in lister_dart(TEST) if f.endswith("_test.dart")]
    aides = [f for f in lister_dart(TEST) if not f.endswith("_test.dart")]

    n_cas, ignores, sans_assertion = 0, [], []
    motif_cas = re.compile(r"^\s*(test|testWidgets)\s*\(", re.M)
    # Un test peut etre ignore par skip: true, par skip: 'raison', mais aussi
    # par une CONDITION calculee. Mesure du 02/10/2026 : l unique skip du
    # depot est conditionne par une variable d environnement
    # (test/outillage/cartes_publiees_648_test.dart:181), que le motif
    # restreint a true ou a une chaine ne voyait pas.
    motif_skip = re.compile(r"(?<![.\w])skip\s*:|@Skip\b|@TestOn\b")
    motif_assertion = re.compile(
        r"\bexpect\s*\(|\bexpectLater\s*\(|\bverify\s*\(|\bverifyNever\s*\(|"
        r"\bfail\s*\(|\bthrowsA\b|matcher")
    for f in fichiers:
        texte = lire(f)
        n_cas += len(motif_cas.findall(texte))
        for i, l in enumerate(lignes_de(f), 1):
            if motif_skip.search(l):
                ignores.append(f"{f}:{i}: {l.strip()[:90]}")
        if not motif_assertion.search(texte):
            sans_assertion.append(f)

    # ECR-16 : miroir. Un fichier de lib/ a-t-il son test ?
    tests_attendus = set()
    for f in lister_dart(TEST):
        tests_attendus.add(os.path.basename(f).replace("_test.dart", ".dart"))
    sans_miroir = [f for f in lister_dart(LIB)
                   if os.path.basename(f) not in tests_attendus]

    return {
        "fichiers_de_test": len(fichiers),
        "fichiers_d_aide": len(aides),
        "cas_de_test": n_cas,
        "note_comptage": ("n_cas est un comptage STATIQUE des appels test( et "
                          "testWidgets( ; l execution en declare davantage "
                          "car des cas sont engendres en boucle. Mesure du "
                          "02/10/2026 sur la tete 147ca32d : 4002 tests "
                          "passes, 2 ignores, en 3 min 56 s, All tests "
                          "passed (flutter test)"),
        "execution_mesuree_02_10": {"passes": 4002, "ignores": 2,
                                    "duree": "3 min 56 s", "verdict": "vert"},
        "tests_ignores": ignores,
        "nombre_ignores": len(ignores),
        "fichiers_sans_assertion": sans_assertion,
        "nombre_sans_assertion": len(sans_assertion),
        "fichiers_de_lib_sans_test_miroir": len(sans_miroir),
        "part_de_lib_avec_test_miroir_pct": round(
            100 * (len(lister_dart(LIB)) - len(sans_miroir)) /
            max(len(lister_dart(LIB)), 1), 1),
        "methode": ("comptage des appels test( et testWidgets( ; assertion = "
                    "expect, expectLater, verify, fail ou throwsA present "
                    "dans le fichier ; miroir par nom de base"),
    }


# --- Section 10 : observabilite -------------------------------------------

def mesurer_observabilite() -> dict:
    """Miettes d observabilite posees ou non, ecran par ecran."""
    ecrans = [f for f in lister_dart(LIB) if f.endswith(SUFFIXE_ECRAN)]
    avec, sans = [], []
    for f in ecrans:
        texte = lire(f)
        if any(a in texte for a in APPELS_CRASHLYTICS):
            avec.append(f)
        else:
            sans.append(f)
    # Le service d observabilite existe-t-il ?
    services = [f for f in lister_dart(LIB)
                if "crashlytics" in f.lower() or "observabilit" in f.lower()
                or "miette" in f.lower() or "telemetr" in f.lower()
                or "analytics" in f.lower()]
    return {
        "ecrans": len(ecrans),
        "ecrans_avec_miette": sorted(avec),
        "ecrans_sans_miette": sorted(sans),
        "nombre_avec": len(avec),
        "nombre_sans": len(sans),
        "part_couverte_pct": round(100 * len(avec) / max(len(ecrans), 1), 1),
        "services_candidats": services,
        "methode": ("un ecran = un fichier *_screen.dart de lib/ ; miette = "
                    f"une des marques {list(APPELS_CRASHLYTICS)} presente "
                    "dans le fichier"),
    }


# --- Section 11 : formatage et dependances --------------------------------

def mesurer_outillage(rapide: bool = False) -> dict:
    """dart format, flutter analyze, flutter pub outdated."""
    res: dict = {}
    code, sortie = commande(["dart", "format", "--output=none",
                             "--set-exit-if-changed", "lib", "test", "tool"])
    changes = [l for l in sortie.splitlines() if l.startswith("Changed")]
    res["dart_format"] = {
        "code_retour": code,
        "disponible": code != 127,
        "fichiers_a_reformater": len(changes) if code != 127 else None,
        "liste": changes[:40],
        "commande": "dart format --output=none --set-exit-if-changed lib test tool",
    }
    # Lints absents de analysis_options.yaml, pointes par le referentiel ECR.
    # Une ligne commentee ne compte pas comme active.
    chemin = os.path.join(REPO, "analysis_options.yaml")
    contenu = ""
    if os.path.exists(chemin):
        with open(chemin, encoding="utf-8", errors="replace") as fh:
            contenu = "\n".join(l for l in fh.read().splitlines()
                                if not l.strip().startswith("#"))
    attendus = ("public_member_api_docs", "directives_ordering",
                "lines_longer_than_80_chars", "avoid_print",
                "prefer_single_quotes", "unnecessary_lambdas",
                "always_declare_return_types")
    res["lints"] = {
        "fichier": "analysis_options.yaml",
        "absents": [l for l in attendus if l not in contenu],
        "presents": [l for l in attendus if l in contenu],
    }

    if rapide:
        res["flutter_analyze"] = {"ignore": "mode rapide"}
        res["pub_outdated"] = {"ignore": "mode rapide"}
        return res

    # GARDE INDISPENSABLE. Sans .dart_tool/package_config.json, l analyseur
    # ne resout AUCUN import de paquet et remonte une erreur par ligne
    # d import : mesure du 02/10/2026 dans un worktree neuf, 77 735 erreurs
    # toutes de type uri_does_not_exist. Ce chiffre ne dit rien du code. On
    # declare donc la mesure NON VALABLE plutot que de publier un faux.
    config = os.path.join(REPO, ".dart_tool", "package_config.json")
    if not os.path.exists(config):
        res["flutter_analyze"] = {
            "valable": False,
            "raison": ("dependances non recuperees dans cet arbre de travail "
                       "(.dart_tool/package_config.json absent) : l analyseur "
                       "remonterait une erreur par import de paquet"),
            "remede": "flutter pub get avant de relancer l audit",
        }
        res["pub_outdated"] = {
            "valable": False,
            "raison": "dependances non recuperees (.dart_tool absent)",
            "remede": "flutter pub get avant de relancer l audit",
        }
        return res

    code, sortie = commande(["flutter", "analyze", "--no-pub", "--no-fatal-infos"])
    res["flutter_analyze"] = {
        "code_retour": code,
        "disponible": code != 127,
        "erreurs": len(re.findall(r"^\s*error\s+[•-]", sortie, re.M)),
        "avertissements": len(re.findall(r"^\s*warning\s+[•-]", sortie, re.M)),
        "informations": len(re.findall(r"^\s*info\s+[•-]", sortie, re.M)),
        "resume": next((l for l in sortie.splitlines()
                        if "issue" in l or "No issues" in l), "")[:120],
        "commande": "flutter analyze --no-pub --no-fatal-infos",
    }

    code, sortie = commande(["flutter", "pub", "outdated", "--json"])
    obsoletes = []
    try:
        donnees = json.loads(sortie[sortie.index("{"):sortie.rindex("}") + 1])
        for paquet in donnees.get("packages", []):
            actuel = (paquet.get("current") or {}).get("version")
            dernier = (paquet.get("latest") or {}).get("version")
            resoluble = (paquet.get("resolvable") or {}).get("version")
            if actuel and dernier and actuel != dernier:
                obsoletes.append({"paquet": paquet.get("package"),
                                  "actuel": actuel, "resoluble": resoluble,
                                  "dernier": dernier,
                                  "majeur": actuel.split(".")[0] !=
                                            dernier.split(".")[0]})
    except (ValueError, KeyError):
        pass
    res["pub_outdated"] = {
        "code_retour": code,
        "disponible": code != 127,
        "nombre_obsoletes": len(obsoletes),
        "saut_majeur": [o for o in obsoletes if o["majeur"]],
        "liste": obsoletes,
        "commande": "flutter pub outdated --json",
    }
    return res


# --- Section 12 : tete du depot -------------------------------------------

def mesurer_tete() -> dict:
    """Branche, tete et proprete de l arbre de travail."""
    _, branche = commande(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    _, tete = commande(["git", "rev-parse", "--short", "HEAD"])
    _, sujet = commande(["git", "log", "-1", "--pretty=%s"])
    _, statut = commande(["git", "status", "--porcelain"])
    return {
        "branche": branche.strip(),
        "tete": tete.strip(),
        "sujet": sujet.strip(),
        "fichiers_modifies": len([l for l in statut.splitlines() if l.strip()]),
        "horodatage": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    }


# --- Verdict --------------------------------------------------------------

def verdict(rapport: dict) -> dict:
    """Applique la grille APRES du referentiel ECR (#100238)."""
    bloquants, avertissements = [], []

    arbo = rapport.get("arborescence", {})
    doc = rapport.get("documentation", {})
    dbl = rapport.get("doublons", {})
    cch = rapport.get("couches", {})
    cmp_ = rapport.get("composants_et_valeurs", {})
    cpx = rapport.get("complexite", {})
    out = rapport.get("outillage", {})

    def bloc(regle, n, quoi):
        if n:
            bloquants.append({"regle": regle, "nombre": n, "constat": quoi})

    def avert(regle, n, quoi):
        if n:
            avertissements.append({"regle": regle, "nombre": n,
                                   "constat": quoi})

    bloc("ECR-07", len(doc.get("doc_en_dart_dans_lib", [])),
         "documentation deposee en .dart sous lib/")
    bloc("ECR-13", len(arbo.get("racine_lib", {}).get("intrus", [])),
         "element non autorise a la racine de lib/")
    bloc("ECR-15", arbo.get("tailles", {}).get("nombre_au_dela_de_500", 0),
         "fichier source au dela de 500 lignes")
    bloc("ECR-19", cmp_.get("total_boutons_bruts", 0),
         "appel de bouton brut hors du composant unique")
    bloc("ECR-20", dbl.get("nombre_noms_en_double", 0),
         "nom de fichier en double dans lib/")
    bloc("ECR-23", cch.get("nombre_socle_vers_feature", 0) +
         cch.get("nombre_croisements", 0),
         "dependance interdite entre couches ou features")
    bloc("ECR-24", cmp_.get("nombre_couleurs_en_dur", 0),
         "couleur en dur hors core/theme et core/branding")
    bloc("ECR-25", cch.get("nombre_presentation_donnees", 0),
         "acces aux donnees depuis la couche presentation")
    bloc("ECR-28", cpx.get("nombre_au_dela_de_60_lignes", 0),
         "fonction au dela de 60 lignes")
    bloc("ECR-31", cpx.get("nombre_complexite_excessive", 0),
         "fonction de complexite superieure a 10")
    bloc("ECR-04", doc.get("nombre_code_commente", 0) +
         doc.get("nombre_todo_sans_tache", 0),
         "code commente livre ou TODO sans numero de tache")
    bloc("ECR-32", out.get("dart_format", {}).get("fichiers_a_reformater")
         or 0, "fichier non conforme a dart format")
    bloc("VAC-01", cmp_.get("nombre_valeurs_a_completer", 0),
         "valeur a completer livree en production")

    avert("ECR-01", doc.get("nombre_sans_entete", 0),
          "fichier source sans en-tete")
    avert("ECR-03", doc.get("nombre_commentaires_bavards", 0),
          "commentaire qui paraphrase le code")
    avert("ECR-05", rapport.get("langue", {})
          .get("total_identifiants_francais", 0),
          "identifiant portant un mot francais")
    avert("ECR-16", mesure_sure(rapport, "tests",
                                "fichiers_de_lib_sans_test_miroir"),
          "fichier de lib/ sans test miroir")
    avert("ECR-18", dbl.get("nombre_blocs_repetes", 0),
          "bloc de 6 lignes repete 3 fois ou davantage")
    avert("ECR-29", cpx.get("nombre_imbrication_excessive", 0),
          "fonction imbriquee au dela de 4 niveaux")
    avert("MORT-01", rapport.get("code_mort", {}).get("nombre_candidats", 0),
          "symbole public sans appelant (candidat, a confirmer)")
    avert("OBS-01", rapport.get("observabilite", {}).get("nombre_sans", 0),
          "ecran sans miette d observabilite")
    avert("TST-01", mesure_sure(rapport, "tests", "nombre_ignores"),
          "test ignore")
    avert("TST-02", mesure_sure(rapport, "tests", "nombre_sans_assertion"),
          "fichier de test sans aucune assertion")
    avert("DEP-01", len(out.get("pub_outdated", {}).get("saut_majeur", [])),
          "dependance en retard d une version majeure")
    avert("RNG-01", cch.get("nombre_hors_couche", 0),
          "fichier de feature hors d une couche reconnue")
    avert("ECR-19e", cmp_.get("total_boutons_perimetre_etendu", 0) -
          cmp_.get("total_boutons_bruts", 0),
          "IconButton ou CupertinoButton brut (perimetre etendu, hors ECR-19)")
    avert("VAC-02", cmp_.get("nombre_en_commentaire", 0),
          "valeur a completer citee dans un commentaire (non bloquant)")
    avert("DOC-01", len(doc.get("desarmements_analyseur", [])),
          "desarmement de l analyseur par ignore_for_file dans lib/")

    return {
        "bloquants": bloquants,
        "avertissements": avertissements,
        "nombre_bloquants": len(bloquants),
        "total_infractions_bloquantes": sum(b["nombre"] for b in bloquants),
        "total_avertissements": sum(a["nombre"] for a in avertissements),
        "propre": not bloquants,
    }


def mesure_sure(rapport: dict, section: str, cle: str) -> int:
    """Lecture defensive d un compteur, zero si la section manque."""
    return rapport.get(section, {}).get(cle, 0) or 0


# --- Rendu texte ----------------------------------------------------------

def rendre(rapport: dict) -> str:
    """Rapport texte lisible par Christophe, chiffres d abord."""
    l = []
    t = rapport["tete"]
    l.append("=" * 72)
    l.append("AUDIT GLOBAL MOTEUR-GR — tool/audit_global.py")
    l.append(f"Branche {t['branche']} | tete {t['tete']} | {t['horodatage']}")
    l.append(f"Sujet de tete : {t['sujet'][:60]}")
    l.append("=" * 72)

    v = rapport["verdict"]
    l.append("")
    l.append(f"VERDICT : {'PROPRE' if v['propre'] else 'NON PROPRE'} — "
             f"{v['nombre_bloquants']} familles bloquantes, "
             f"{v['total_infractions_bloquantes']} infractions bloquantes, "
             f"{v['total_avertissements']} avertissements")

    a = rapport["arborescence"]
    l.append("")
    l.append("-- VOLUMES --")
    for nom, z in a["zones"].items():
        l.append(f"  {nom:17s} {z['fichiers_source']:5d} fichiers source, "
                 f"{z['fichiers_generes']:4d} generes, "
                 f"{z['lignes_source']:7d} lignes")
    r = a["tailles"]["repartition"]
    l.append(f"  tailles lib/ : <=300 : {r['<=300']} | 301-500 : "
             f"{r['301-500']} | 501-800 : {r['501-800']} | >800 : {r['>800']}")

    l.append("")
    l.append("-- BLOQUANTS --")
    if not v["bloquants"]:
        l.append("  aucun")
    for b in v["bloquants"]:
        l.append(f"  {b['regle']:8s} {b['nombre']:5d}  {b['constat']}")

    l.append("")
    l.append("-- AVERTISSEMENTS --")
    if not v["avertissements"]:
        l.append("  aucun")
    for w in v["avertissements"]:
        l.append(f"  {w['regle']:8s} {w['nombre']:5d}  {w['constat']}")

    ts = rapport.get("tests", {})
    l.append("")
    l.append("-- TESTS --")
    l.append(f"  {ts.get('fichiers_de_test', 0)} fichiers de test, "
             f"{ts.get('cas_de_test', 0)} cas, "
             f"{ts.get('nombre_ignores', 0)} ignores, "
             f"{ts.get('nombre_sans_assertion', 0)} fichiers sans assertion")
    l.append(f"  miroir de lib/ couvert a "
             f"{ts.get('part_de_lib_avec_test_miroir_pct', 0)} pct")

    ob = rapport.get("observabilite", {})
    l.append("")
    l.append("-- OBSERVABILITE --")
    l.append(f"  {ob.get('nombre_avec', 0)} ecrans avec miette sur "
             f"{ob.get('ecrans', 0)} ({ob.get('part_couverte_pct', 0)} pct)")

    out = rapport.get("outillage", {})
    po = out.get("pub_outdated", {})
    fa = out.get("flutter_analyze", {})
    l.append("")
    l.append("-- OUTILLAGE --")
    df = out.get("dart_format", {})
    if df.get("disponible") is False:
        l.append("  dart format : INDISPONIBLE (dart absent du PATH)")
    else:
        l.append(f"  dart format : {df.get('fichiers_a_reformater')} "
                 f"fichiers a reformater")
    if fa.get("valable") is False:
        l.append(f"  flutter analyze : NON VALABLE — {fa.get('raison', '')}")
        l.append(f"    remede : {fa.get('remede', '')}")
    elif fa.get("disponible") is False:
        l.append("  flutter analyze : INDISPONIBLE (flutter absent du PATH)")
    elif "erreurs" in fa:
        l.append(f"  flutter analyze : {fa['erreurs']} erreurs, "
                 f"{fa['avertissements']} avertissements, "
                 f"{fa['informations']} informations"
                 + (f" | {fa['resume']}" if fa.get("resume") else ""))
    if po.get("valable") is False or po.get("disponible") is False:
        l.append("  dependances : mesure indisponible — "
                 f"{po.get('raison', 'flutter absent du PATH')}")
    elif "nombre_obsoletes" in po:
        l.append(f"  dependances : {po['nombre_obsoletes']} obsoletes dont "
                 f"{len(po.get('saut_majeur', []))} en saut majeur")
    l.append(f"  lints absents : "
             f"{', '.join(out.get('lints', {}).get('absents', [])) or 'aucun'}")
    l.append("")
    l.append("=" * 72)
    return "\n".join(l)


# --- Point d entree -------------------------------------------------------

SECTIONS = {
    "arborescence": mesurer_arborescence,
    "code_mort": mesurer_code_mort,
    "doublons": mesurer_doublons,
    "documentation": mesurer_documentation,
    "langue": mesurer_langue,
    "couches": mesurer_couches,
    "composants_et_valeurs": mesurer_composants_et_valeurs,
    "complexite": mesurer_complexite,
    "tests": mesurer_tests,
    "observabilite": mesurer_observabilite,
}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--json", action="store_true", help="sortie JSON")
    ap.add_argument("--json-out", metavar="FICHIER", help="ecrit le JSON")
    ap.add_argument("--section", action="append", help="limite aux sections")
    ap.add_argument("--rapide", action="store_true",
                    help="saute flutter analyze et pub outdated")
    ap.add_argument("--strict", action="store_true",
                    help="code retour 1 s il reste un bloquant")
    args = ap.parse_args()

    rapport: dict = {"tete": mesurer_tete(), "depot": REPO}
    voulues = args.section or list(SECTIONS)
    for nom in voulues:
        if nom not in SECTIONS:
            print(f"section inconnue : {nom}", file=sys.stderr)
            return 2
        rapport[nom] = SECTIONS[nom]()
    if not args.section:
        rapport["outillage"] = mesurer_outillage(rapide=args.rapide)
    rapport["verdict"] = verdict(rapport)

    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as fh:
            json.dump(rapport, fh, ensure_ascii=False, indent=2)
    if args.json:
        print(json.dumps(rapport, ensure_ascii=False, indent=2))
    else:
        print(rendre(rapport))

    if args.strict and not rapport["verdict"]["propre"]:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
