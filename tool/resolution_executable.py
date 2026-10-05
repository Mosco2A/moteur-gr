#!/usr/bin/env python3
"""UN OUTIL DU SDK NE SE LANCE JAMAIS PAR SON NOM NU SOUS WINDOWS.

CE QUI S'EST PASSE, ET C'EST MESURE DEUX FOIS (lot infra L8a #101318, build 11
#101332). Le dossier `bin` de Flutter ne contient QUE `flutter` (un script sh)
et `flutter.bat` — AUCUN `.exe`. Or `CreateProcess`, l'appel systeme derriere
`subprocess.run(..., shell=False)`, ne cherche dans le PATH que le nom EXACT
puis le nom + `.exe` : il NE RESOUT NI `.bat` NI `.cmd`. C'est `cmd.exe`
interactif qui honore `PATHEXT`, pas le systeme. Un
`subprocess.run(['flutter', ...])` leve donc `FileNotFoundError [WinError 2]`
IMMEDIATEMENT, sans rien lancer : 36 millisecondes pour un faux echec de
compilation le 05/10 a 18:20, puis un `--pub-get` inutilisable a 21:50 — dans
l'outil meme qui venait d'etre ecrit pour serialiser les `pub get`.

CE QUE CE MODULE FAIT, ET C'EST TOUT. Il rend le CHEMIN COMPLET d'un
executable, ou la raison PRECISE pour laquelle il ne l'a pas trouve. Trois
regles, dans cet ordre :

  1. `shutil.which` d'abord — il honore `PATHEXT`, donc `.BAT` et `.CMD` ;
  2. UN REPLI EXPLICITE ensuite, dossier de PATH par dossier de PATH, sur
     `.bat`, `.cmd`, `.exe`, `.com` puis sans suffixe. Ce repli n'est PAS
     decoratif : `which` echoue des que `PATHEXT` est tronque ou detourne, et
     c'est un cas que les gardes mesurent ;
  3. des RACINES SUPPLEMENTAIRES, si l'appelant en donne (les emplacements
     usuels du SDK), en dernier recours seulement.

JAMAIS `shell=True`. On resout un CHEMIN et on garde une LISTE d'arguments :
aucune injection n'est reintroduite pour reparer un defaut de resolution.

CODE DE SORTIE CONVENU POUR LES APPELANTS : **76** quand l'executable est
introuvable. Il se distingue de 75 (verrou non obtenu, `pub_cache_sain.py`) et
de 127 (commande absente, `audit_global.py`), et il dit au script appelant que
rien n'a tourne — ce qui n'est pas la meme chose qu'une commande qui a echoue.
"""
import os
import shutil

# Les suffixes essayes par le repli, DANS CET ORDRE. `.bat` d'abord parce que
# c'est la forme reelle des outils du SDK Flutter sous Windows ; la chaine vide
# en dernier pour le script sh sans suffixe (Linux, macOS, et le `flutter` de
# C:\flutter\bin lu par un shell POSIX).
SUFFIXES = ('.bat', '.cmd', '.exe', '.com', '')

# Combien de dossiers de PATH la raison d'echec cite. Au-dela c'est un mur de
# texte que personne ne lit, et le compte total est donne a cote.
DOSSIERS_CITES = 15


def dossiers_du_path() -> list:
    """Les dossiers du PATH, dans l'ordre, sans les vides ni les doublons."""
    vus = []
    for brut in (os.environ.get('PATH') or '').split(os.pathsep):
        dossier = brut.strip().strip('"')
        if dossier and dossier not in vus:
            vus.append(dossier)
    return vus


def resoudre_executable(nom: str, racines_extra=()) -> tuple:
    """Rend `(chemin, None)` si [nom] est trouve, sinon `(None, raison)`.

    [nom] est un NOM NU (`flutter`, `dart`) : c'est la seule place du depot ou
    un nom nu a un sens, parce que c'est ici qu'il devient un chemin. Un [nom]
    qui est deja un chemin (il porte un separateur) est rendu tel quel s'il
    existe — un appelant qui sait ou est son outil n'a rien a chercher.

    [racines_extra] : des dossiers essayes APRES le PATH (emplacements usuels
    d'un SDK). Vide par defaut : la resolution par le PATH est la regle, une
    liste de chemins en dur est le filet.
    """
    if os.sep in nom or (os.altsep and os.altsep in nom):
        if os.path.isfile(nom):
            return nom, None
        return None, 'chemin donne par l appelant, et il n existe pas : %s' % nom

    trouve = shutil.which(nom)
    if trouve:
        return trouve, None

    candidats = [nom + s for s in SUFFIXES]
    dossiers = dossiers_du_path()
    for dossier in list(dossiers) + [d for d in racines_extra if d]:
        for candidat in candidats:
            chemin = os.path.join(dossier, candidat)
            if os.path.isfile(chemin):
                return chemin, None

    # LA RAISON DIT CE QUI A ETE TENTE, pas « introuvable ». Sans PATHEXT ni la
    # liste des candidats, le lecteur ne peut pas savoir si le defaut est dans
    # sa machine ou dans ce code.
    debut = ', '.join(dossiers[:DOSSIERS_CITES])
    return None, (
        '%s introuvable. PATHEXT=%s. Candidats essayes : %s. %d dossier(s) de '
        'PATH consulte(s)%s%s. Racines supplementaires : %s.'
        % (
            nom,
            os.environ.get('PATHEXT', '(non defini)'),
            ', '.join(candidats[:-1]) + ' et sans suffixe',
            len(dossiers),
            (' (les %d premiers : ' % min(DOSSIERS_CITES, len(dossiers)))
            if dossiers else '',
            (debut + ')') if dossiers else ' : aucun',
            ', '.join(racines_extra) or '(aucune)',
        )
    )
