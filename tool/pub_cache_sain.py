#!/usr/bin/env python3
"""LE CACHE PUB EST PARTAGE PAR TOUTE LA MACHINE : UN SEUL `pub get` A LA FOIS.

CE QUI S'EST PASSE, ET C'EST MESURE (tache 695, kaizen #101276, rapport
#101275). Le 05/10 a 13:24:55, pendant le build 10, DEUX `flutter pub get` ont
tourne en parallele dans deux arbres de travail differents. Le cache pub est
PARTAGE : `C:/Users/<moi>/AppData/Local/Pub/Cache/hosted/pub.dev`. Resultat
mesure : 29 dossiers de paquets EXISTAIENT mais etaient VIDES —
cloud_firestore, share_plus, firebase_core, connectivity_plus, battery_plus,
device_info_plus, package_info_plus, printing, sqlite3_flutter_libs et vingt
autres, tous horodates a la meme seconde.

ET VOICI LE PIEGE, CELUI QUI COUTE UNE DEMI-JOURNEE. `flutter pub get` decide
qu'un paquet est deja la EN REGARDANT SI SON DOSSIER EXISTE. Un dossier vide
passe donc pour un paquet installe : plus jamais retelecharge, et plus jamais
reparé. La resolution reste cassee EN SILENCE, pour TOUS les arbres de la
machine. La facture du 05/10 : 219 fausses erreurs de `flutter analyze`
(« Target of URI doesn't exist: package:cloud_firestore/cloud_firestore.dart »,
« Undefined name Share / Timestamp / ConnectivityResult »...) sur un depot
parfaitement sain, vues par DEUX agents.

CE QUE CET OUTIL FAIT, EN DEUX GESTES, ET RIEN D'AUTRE.

  1. LE VERROU (`--pub-get`). Un seul `pub get` a la fois PAR CACHE. Le fichier
     de verrou vit DANS le cache qu'il protege, et c'est tout l'argument : deux
     arbres qui partagent le cache partagent le verrou par construction, et un
     arbre qui a son propre `PUB_CACHE` n'a personne a attendre. Les appels
     concurrents ATTENDENT, ils n'echouent pas — un `pub get` refuse ferait
     echouer un build pour une raison qui n'est pas la sienne.

  2. LA PURGE (`--purger`). Les dossiers de paquets INCOMPLETS sont effaces,
     pour que le prochain `pub get` les retelecharge. « Incomplet » a une
     definition unique et verifiable, EN DEUX CONDITIONS : le dossier porte la
     forme `<paquet>-<version>`, ET il n'a PAS de `pubspec.yaml` a sa racine.
     Tout paquet du cache en a un — c'est ce que `pub` y depose en premier.
     Rien d'autre n'est jamais touche : ni un paquet complet, ni un fichier, ni
     un dossier hors `hosted/<hote>/`, ni le cache `git/`, NI LES DOSSIERS DE
     PUB LUI-MEME (`hosted/pub.dev/.cache`, son cache de metadonnees : la
     premiere version de cet outil l'a efface, voir `FORME_PAQUET`). Et chaque
     suppression est JOURNALISEE avec ce qu'elle contenait.

POURQUOI LE VERROU ET PAS UN `PUB_CACHE` PAR ARBRE (la decision, et son prix).
Un cache par arbre isole parfaitement — et fait retelecharger 732 paquets par
arbre. Cette machine porte plus de quarante arbres de travail : c'est plusieurs
dizaines de gigaoctets et plusieurs minutes de reseau par arbre neuf, pour
resoudre un conflit qui dure quelques secondes. Le verrou coute une attente, ne
change RIEN a la facon d'appeler flutter, et laisse le cache partage faire son
travail. La purge, elle, repare le cache deja abime par un appelant qui n'est
pas passe par ici — c'est le filet, le verrou est la regle.

Usage :
  python tool/pub_cache_sain.py --purger [--simuler] [--cache <dir>]
  python tool/pub_cache_sain.py --pub-get [--attente-max-s 900] [--cache <dir>]
  python tool/pub_cache_sain.py --sous-verrou <commande...>
  python tool/pub_cache_sain.py --mesurer          # ne touche a rien

Codes de sortie : 0 si tout va bien, le code de la commande sous verrou, et 75
si le verrou n'a pas pu etre pris dans le budget (pas de trace d'exception :
l'appelant est un script, il merite une ligne lisible).
"""
import argparse
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import time

# Nom du fichier de verrou, pose A LA RACINE DU CACHE. Il commence par un point
# et ne vit pas sous `hosted/`, donc la purge ne peut pas le voir.
NOM_VERROU = '.stepways_pub_get.lock'

# Un paquet du cache a TOUJOURS ce fichier a sa racine. C'est le seul critere
# d'integrite utilise, et il est verifiable d'un coup d'oeil.
TEMOIN = 'pubspec.yaml'

# LA FORME D'UN DOSSIER DE PAQUET : `<paquet>-<version>`, et rien d'autre.
#
# DEFAUT TROUVE AU PREMIER VRAI PASSAGE, PAS SUPPOSE (tache 695). La premiere
# version de cet outil ne regardait que l'absence de `pubspec.yaml`. Lancee pour
# de bon au reveil du pilote le 05/10 a 19:48, elle a donc efface
# `hosted/pub.dev/.cache` — 697 fichiers, 22 315 916 octets — qui est le cache
# de metadonnees de `pub` LUI-MEME, pas un paquet a moitie descendu. Rien n'a
# ete perdu (pub le reconstruit en reinterrogeant pub.dev) mais le contrat
# affiche en tete de ce fichier, « jamais autre chose que des dossiers de
# paquets incomplets », etait faux. Un dossier n'est donc candidat que s'il
# PORTE LA FORME d'un paquet ; tout nom cache (`.cache`, `.tmp`) et tout nom
# sans numero de version appartient a pub et ne se touche pas.
FORME_PAQUET = re.compile(r'^[A-Za-z0-9_]+-[0-9][0-9A-Za-z.+_-]*$')


def cache_par_defaut() -> str:
    """Le cache pub de cette machine, dans l'ordre ou `pub` le choisit."""
    depuis_env = os.environ.get('PUB_CACHE')
    if depuis_env:
        return depuis_env
    if platform.system() == 'Windows':
        local = os.environ.get('LOCALAPPDATA')
        if local:
            return os.path.join(local, 'Pub', 'Cache')
    return os.path.join(os.path.expanduser('~'), '.pub-cache')


def dossiers_de_paquets(cache: str):
    """Les dossiers de paquets du cache, et eux seuls.

    STRICTEMENT `<cache>/hosted/<hote>/<paquet>-<version>/`. Ni le cache `git/`,
    ni `bin/`, ni les fichiers de la racine, NI LES DOSSIERS DE PUB LUI-MEME
    (`.cache` et compagnie) : la purge ne doit pouvoir atteindre qu'un dossier
    de paquet telecharge.
    """
    racine = os.path.join(cache, 'hosted')
    if not os.path.isdir(racine):
        return
    for hote in sorted(os.listdir(racine)):
        chemin_hote = os.path.join(racine, hote)
        if not os.path.isdir(chemin_hote):
            continue
        for paquet in sorted(os.listdir(chemin_hote)):
            if paquet.startswith('.') or not FORME_PAQUET.match(paquet):
                continue
            chemin = os.path.join(chemin_hote, paquet)
            if os.path.isdir(chemin):
                yield hote, paquet, chemin


def incomplets(cache: str):
    """Les dossiers de paquets SANS `pubspec.yaml`, avec leur taille reelle.

    Rend une liste de dicts `{hote, paquet, chemin, entrees, octets}`.
    `entrees` = 0 veut dire « dossier vide », le cas exact du 05/10.
    """
    out = []
    for hote, paquet, chemin in dossiers_de_paquets(cache):
        if os.path.isfile(os.path.join(chemin, TEMOIN)):
            continue
        entrees = 0
        octets = 0
        for dossier, _sous, fichiers in os.walk(chemin):
            entrees += len(fichiers)
            for f in fichiers:
                try:
                    octets += os.path.getsize(os.path.join(dossier, f))
                except OSError:
                    pass
        out.append({
            'hote': hote,
            'paquet': paquet,
            'chemin': chemin,
            'entrees': entrees,
            'octets': octets,
        })
    return out


def mesurer(cache: str):
    """Combien de paquets, combien d'incomplets. Ne touche a rien."""
    total = sum(1 for _ in dossiers_de_paquets(cache))
    casses = incomplets(cache)
    return total, casses


def purger(cache: str, simuler: bool = False) -> int:
    """Efface les dossiers de paquets incomplets. Rend le nombre efface.

    JAMAIS AUTRE CHOSE QU'UN DOSSIER DE PAQUET INCOMPLET. Le chemin efface est
    re-verifie juste avant la suppression : il doit etre sous
    `<cache>/hosted/<hote>/`, etre un dossier, et ne pas avoir de
    `pubspec.yaml`. Un paquet complet qui arriverait entre la mesure et la
    suppression (un `pub get` concurrent qui finit) est donc EPARGNE et dit.
    """
    total, casses = mesurer(cache)
    print('[cache-pub] cache : %s' % cache)
    print('[cache-pub] %d dossier(s) de paquet, %d INCOMPLET(S) (sans %s)'
          % (total, len(casses), TEMOIN))
    if not casses:
        print('[cache-pub] rien a purger : le cache est sain')
        return 0

    # LE SEPARATEUR FINAL EST AJOUTE APRES `abspath`, PAS AVANT : `abspath`
    # retire un separateur de fin, et `startswith` sans lui accepterait un
    # voisin comme `hosted_autre/`.
    racine = os.path.abspath(os.path.join(cache, 'hosted')) + os.sep
    efface = 0
    for e in casses:
        chemin = e['chemin']
        detail = ('%s/%s (%d fichier(s), %d octet(s))'
                  % (e['hote'], e['paquet'], e['entrees'], e['octets']))
        if not os.path.abspath(chemin).startswith(racine):
            print('[cache-pub] EPARGNE (hors du cache hoste) : %s' % chemin)
            continue
        if not FORME_PAQUET.match(os.path.basename(chemin)):
            # Ceinture ET bretelles : c'est ce controle qui manquait quand
            # `.cache` a ete efface le 05/10.
            print('[cache-pub] EPARGNE (pas la forme paquet-version, donc a '
                  'pub) : %s' % detail)
            continue
        if not os.path.isdir(chemin):
            print('[cache-pub] EPARGNE (plus un dossier) : %s' % detail)
            continue
        if os.path.isfile(os.path.join(chemin, TEMOIN)):
            print('[cache-pub] EPARGNE (complete entre-temps, un pub get '
                  'concurrent a fini) : %s' % detail)
            continue
        if simuler:
            print('[cache-pub] A PURGER : %s' % detail)
            continue
        try:
            shutil.rmtree(chemin)
        except OSError as err:
            print('[cache-pub] ECHEC de la purge de %s : %s' % (detail, err))
            continue
        efface += 1
        print('[cache-pub] PURGE : %s' % detail)

    if simuler:
        print('[cache-pub] SIMULATION : %d dossier(s) a purger, rien efface'
              % len(casses))
        return 0
    print('[cache-pub] %d dossier(s) incomplet(s) purge(s) - le prochain '
          'pub get les retelechargera' % efface)
    return efface


def _vivant(pid: int) -> bool:
    """Ce PID tourne-t-il encore ? Sert a reprendre un verrou abandonne."""
    if pid <= 0:
        return False
    if platform.system() == 'Windows':
        try:
            sortie = subprocess.run(
                ['tasklist', '/FI', 'PID eq %d' % pid, '/NH'],
                capture_output=True, text=True, timeout=30,
            ).stdout
        except (OSError, subprocess.SubprocessError):
            return True  # on ne sait pas : on respecte le verrou
        return str(pid) in sortie
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    except OSError:
        return True
    return True


def prendre_le_verrou(cache: str, attente_max_s: int):
    """Prend le verrou du cache, ou attend. Rend le chemin du verrou.

    `O_CREAT | O_EXCL` est le seul primitif d'exclusion disponible partout sans
    dependance : la creation du fichier reussit a UN SEUL appelant. Un verrou
    dont le proprietaire est mort (agent tue, machine redemarree) est REPRIS,
    avec la ligne qui le dit — sinon un `pub get` abattu bloquerait la machine
    jusqu'a ce qu'un humain efface un fichier.
    """
    os.makedirs(cache, exist_ok=True)
    verrou = os.path.join(cache, NOM_VERROU)
    t0 = time.time()
    dit = False
    while True:
        try:
            fd = os.open(verrou, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.write(fd, json.dumps({
                'pid': os.getpid(),
                'machine': platform.node(),
                'depuis': time.strftime('%Y-%m-%dT%H:%M:%S'),
                'cwd': os.getcwd(),
            }).encode('utf-8'))
            os.close(fd)
            return verrou
        except FileExistsError:
            pass

        tenant = {}
        try:
            with open(verrou, 'r', encoding='utf-8') as fh:
                tenant = json.loads(fh.read() or '{}')
        except (OSError, ValueError):
            tenant = {}
        pid = int(tenant.get('pid', 0) or 0)
        if pid and not _vivant(pid):
            print('[cache-pub] VERROU ABANDONNE par le processus %d (mort) : '
                  'je le reprends' % pid)
            try:
                os.remove(verrou)
            except OSError:
                pass
            continue
        if not dit:
            print('[cache-pub] UN AUTRE pub get TOURNE SUR CETTE MACHINE '
                  '(pid=%s, depuis %s, %s) - j attends mon tour, budget %d s. '
                  'Deux pub get en parallele sur un cache partage laissent des '
                  'dossiers de paquets VIDES que flutter prend pour installes.'
                  % (tenant.get('pid', '?'), tenant.get('depuis', '?'),
                     tenant.get('cwd', '?'), attente_max_s))
            dit = True
        if time.time() - t0 > attente_max_s:
            raise TimeoutError(
                'verrou du cache pub toujours tenu apres %d s (%s). Si le '
                'processus tenant est bien mort, effacez %s.'
                % (attente_max_s, verrou, verrou)
            )
        time.sleep(1.0)


def rendre_le_verrou(verrou: str) -> None:
    try:
        os.remove(verrou)
    except OSError:
        pass


def sous_verrou(cache: str, attente_max_s: int, cmd, avec_purge: bool) -> int:
    """Lance [cmd] SOUS LE VERROU du cache, apres l'avoir assaini.

    LA PURGE EST FAITE SOUS LE VERROU, ET CE N'EST PAS UN DETAIL : purger
    pendant qu'un autre `pub get` telecharge, c'est effacer sous ses pieds un
    paquet qu'il est en train de remplir — exactement le defaut qu'on repare.
    """
    verrou = prendre_le_verrou(cache, attente_max_s)
    try:
        if avec_purge:
            purger(cache)
        print('[cache-pub] %s (sous verrou)' % ' '.join(cmd))
        return subprocess.run(list(cmd), shell=False).returncode
    finally:
        rendre_le_verrou(verrou)


def main() -> int:
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument('--cache', default=None,
                    help='racine du cache pub (defaut : PUB_CACHE, sinon le '
                         'cache de la machine)')
    ap.add_argument('--purger', action='store_true',
                    help='efface les dossiers de paquets sans pubspec.yaml')
    ap.add_argument('--simuler', action='store_true',
                    help='avec --purger : dit ce qu il effacerait, n efface '
                         'rien')
    ap.add_argument('--mesurer', action='store_true',
                    help='compte seulement, ne touche a rien')
    ap.add_argument('--pub-get', action='store_true',
                    help='purge puis lance flutter pub get, sous le verrou de '
                         'la machine')
    ap.add_argument('--sous-verrou', nargs=argparse.REMAINDER, default=None,
                    help='purge puis lance LA COMMANDE QUI SUIT sous le verrou '
                         '(pour tout ce qui touche au cache : dart pub get, '
                         'flutter pub upgrade...)')
    ap.add_argument('--attente-max-s', type=int, default=900,
                    help='budget d attente du verrou')
    a, extra = ap.parse_known_args()

    cache = a.cache or cache_par_defaut()

    if a.sous_verrou:
        return sous_verrou(cache, a.attente_max_s, a.sous_verrou,
                           avec_purge=True)
    if a.pub_get:
        return sous_verrou(cache, a.attente_max_s,
                           ['flutter', 'pub', 'get'] + list(extra or []),
                           avec_purge=True)
    if a.purger:
        purger(cache, simuler=a.simuler)
        return 0
    # Par defaut : on MESURE. Un outil qui efface quand on l'appelle sans
    # argument est un outil qu'on finit par lancer par erreur.
    total, casses = mesurer(cache)
    print('[cache-pub] cache : %s' % cache)
    print('[cache-pub] %d dossier(s) de paquet, %d INCOMPLET(S)'
          % (total, len(casses)))
    for e in casses:
        print('[cache-pub]   - %s/%s (%d fichier(s), %d octet(s))'
              % (e['hote'], e['paquet'], e['entrees'], e['octets']))
    if not a.mesurer and not casses:
        print('[cache-pub] cache sain. --purger pour reparer, --pub-get pour '
              'un pub get serialise.')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except TimeoutError as erreur:
        # PAS DE TRACE D'EXCEPTION : l'appelant est un script de recette ou une
        # gate, et il doit pouvoir recopier la ligne telle quelle.
        print('[cache-pub] VERROU NON OBTENU : %s' % erreur)
        sys.exit(75)
