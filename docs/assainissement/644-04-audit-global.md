# 644-04 — L'audit global rejouable, et son premier rapport

> Tâche 644, temps 2 de l'assainissement StepWays. Athena, 02/10/2026.
> Dépôt **Moteur-GR**, tête mesurée **147ca32d**.
> Outil : `tool/audit_global.py`, **1 194 lignes**, 12 sections de mesure.

## Pourquoi cet outil existe

Demande de Christophe, 30/09 (`#100914`), verbatim : « Quand tu nettoieras le
code tu le feras **après un audit** et tu **relanceras l'audit global** pour
vérif de code propre. »

Un audit qu'on ne peut pas rejouer n'est pas une garantie, c'est une photo. Ce
script est la photo **et** l'appareil : il produit les chiffres du
`644-01-inventaire.md`, et c'est lui qu'on relancera après le temps 3 pour dire
si le code est propre.

---

## Ce que c'est, et ce que ce n'est pas

| Réf | Propriété | Valeur |
|---|---|---|
| #A01 | **Lecture seule** | aucun fichier du dépôt n'est modifié. Aucune écriture hors du fichier JSON que l'utilisateur demande explicitement |
| #A02 | **Sans dépendance** | Python standard seul : `argparse`, `json`, `os`, `re`, `subprocess`, `collections`, `datetime`. Rien à installer |
| #A03 | **Autonome** | il trouve le dépôt tout seul (`os.path.dirname` de son propre chemin) : il marche depuis n'importe quel répertoire courant |
| #A04 | **Traçable** | chaque section porte un champ `methode` qui dit **comment** le chiffre a été obtenu, et chaque mesure porte le numéro de la règle ECR qu'elle contrôle |
| #A05 | **Ce n'est PAS un analyseur Dart** | il ne compile rien et ne construit pas d'arbre syntaxique. Certaines mesures sont donc approchées — c'est dit à l'endroit où elles le sont |

---

## Usage

```bash
python tool/audit_global.py                 # rapport texte
python tool/audit_global.py --json          # rapport machine, sur la sortie
python tool/audit_global.py --json-out F    # rapport machine, dans le fichier F
python tool/audit_global.py --section NOM   # une seule section
python tool/audit_global.py --rapide        # saute flutter analyze et pub outdated
python tool/audit_global.py --strict        # code retour 1 s'il reste un bloquant
```

Durée mesurée le 02/10/2026 : **environ 40 secondes** en `--rapide`, **environ
1 minute** en complet (dont 17 s pour `flutter analyze`).

---

## Les 12 sections

| Réf | Section | Ce qu'elle mesure | Règles ECR |
|---|---|---|---|
| #A06 | `arborescence` | fichiers et lignes par zone, racine de `lib/`, répartition des tailles | ECR-13, ECR-15 |
| #A07 | `code_mort` | déclarations publiques sans aucun appelant | MORT-01 |
| #A08 | `doublons` | noms de fichier en double, blocs de 6 lignes répétés 3 fois | ECR-18, ECR-20 |
| #A09 | `documentation` | en-têtes, code commenté, TODO sans tâche, commentaires bavards, doc en `.dart` | ECR-01 à ECR-07 |
| #A10 | `langue` | identifiants portant un mot français, par dossier et nominativement | ECR-05 |
| #A11 | `couches` | sens des dépendances, croisements entre features, présentation → données, rangement | ECR-23, ECR-25 |
| #A12 | `composants_et_valeurs` | boutons bruts, couleurs en dur, dialogues, valeurs à compléter | ECR-19, ECR-21, ECR-24 |
| #A13 | `complexite` | longueur des fonctions, imbrication, complexité cyclomatique | ECR-28 à ECR-31 |
| #A14 | `tests` | nombre, cas, ignorés, sans assertion, miroir de `lib/` | ECR-16 |
| #A15 | `observabilite` | miettes posées ou non, écran par écran | OBS-01 |
| #A16 | `outillage` | `dart format`, `flutter analyze`, `flutter pub outdated`, lints absents | ECR-32, DEP-01 |
| #A17 | `tete` | branche, tête, sujet de commit, propreté de l'arbre, horodatage | — |

Puis un **verdict** qui applique la grille APRÈS du référentiel ECR (`#100238`) :
13 familles bloquantes, 15 familles d'avertissement, et un booléen `propre`.

---

## Les quatre pièges de mesure, et comment le script les ferme

Ce sont des faux que la première version du script a réellement produits le
02/10, et qui sont désormais gardés. **Ils sont documentés ici parce que
quiconque relancera l'audit doit savoir ce qui a été corrigé, et pourquoi les
chiffres d'une version antérieure ne sont pas comparables.**

### Piège 1 — Le worktree sans dépendances : 77 735 erreurs fantômes

Dans un worktree neuf où `flutter pub get` n'a pas tourné, il n'y a pas de
`.dart_tool/package_config.json`. L'analyseur ne résout alors **aucun** import
de paquet et remonte une erreur par ligne d'import : **77 735 erreurs mesurées**,
toutes de type `uri_does_not_exist`. Ce chiffre ne dit **rien** du code.

**Garde posée :** le script vérifie la présence de
`.dart_tool/package_config.json`. S'il est absent, il déclare la mesure **non
valable** avec sa raison et son remède, au lieu de publier un faux :

```json
"flutter_analyze": {
  "valable": false,
  "raison": "dependances non recuperees dans cet arbre de travail ...",
  "remede": "flutter pub get avant de relancer l audit"
}
```

### Piège 2 — Flutter absent du PATH : zéro silencieux

`flutter` et `dart` sont des `.bat` sous Windows. Lancé depuis un shell POSIX,
`subprocess` ne les trouve pas et lève `FileNotFoundError` — ce que la première
version traduisait en **0 erreur, 0 fichier à reformater, 0 dépendance
obsolète**. Trois mesures vertes, toutes fausses.

**Garde posée :** une fonction `resoudre()` cherche l'exécutable dans le PATH
puis dans les emplacements usuels du SDK (`C:\flutter\bin`, `C:\src\flutter\bin`,
`~\flutter\bin`, `/usr/local/flutter/bin`, `/opt/flutter/bin`), en essayant
`.bat`, `.exe` et sans extension. Si elle ne trouve rien, le code retour est
**127** et la mesure est marquée `"disponible": false` — jamais zéro.

### Piège 3 — Motifs non ancrés : « changement » lu comme « changeme »

Le motif `changeme` cherché en sous-chaîne se trouve dans le mot français
« change**me**nt » : **82 faux positifs**. De même, `placeholder` se trouve dans
le paramètre parfaitement légitime `placeholder:` de Flutter : 12 faux positifs.
Et `XXX` se trouve dans un gabarit de format écrit en doc comment
(`finisher_number.dart:20`, « Forme : `SW-AAAAMMJJ-XXXX` »).

Total : **106 valeurs à compléter annoncées, 45 réelles.**

**Garde posée :** tous les motifs sont **ancrés par frontière de mot**
(`\bCHANGE_?ME\b`), `placeholder` a été retiré, et chaque trouvaille est
**classée code ou commentaire** — un commentaire qui *parle* de `example.org`
n'est pas une valeur à compléter. Le volet commentaire est donné à part et n'est
pas bloquant.

Même traitement pour les TODO : le marqueur doit **ouvrir** le commentaire
(`^\s*//+\s*(TODO|FIXME|HACK)\b`). Résultat : **5 faux positifs → 0**. Le dépôt
n'a réellement aucun TODO orphelin.

### Piège 4 — Périmètres légitimes comptés comme des fautes

Trois cas mesurés :

| Réf | Faux positif | Pourquoi c'est légitime | Garde |
|---|---|---|---|
| #A18 | 6 boutons bruts dans `lib/core/theme/app_theme.dart` | un thème **doit** citer `ElevatedButtonThemeData` et `ElevatedButton.styleFrom` — c'est son rôle (lignes 265-287, 407) | `core/theme/` exclu d'ECR-19 |
| #A19 | 120 `ignore_for_file: type=lint` | ce sont les en-têtes des `.g.dart` générés par Drift — normal et attendu | mesure restreinte aux fichiers **source** : il ne reste que **2** désarmements, tous deux dans `lib/docs/` |
| #A20 | `IconButton` et `CupertinoButton` comptés avec les 4 boutons d'ECR-19 | ECR-19 ne nomme que `ElevatedButton`, `TextButton`, `OutlinedButton`, `FilledButton` ; mélanger rendait la comparaison avec le 21/09 impossible | **deux périmètres distincts** : strict (153, comparable à 58) et étendu (203) |

Un cas inverse, où le script **ratait** une infraction : la détection de tests
ignorés ne cherchait que `skip: true` et `skip: 'raison'`, et annonçait donc
**0 ignoré** alors que `flutter test` en déclarait 2. Le seul `skip:` du dépôt
est **conditionné par une variable d'environnement**
(`cartes_publiees_648_test.dart:181`). Motif élargi à toute forme de `skip:`,
`@Skip` et `@TestOn`.

---

## Limites assumées, écrites dans le script lui-même

| Réf | Limite | Conséquence |
|---|---|---|
| #A21 | **La complexité est approchée.** Comptage d'accolades et de mots de branchement (`if`, `for`, `while`, `case`, `catch`, `??`, `&&`, `\|\|`, `?:`), sans analyseur Dart | *reproductible* — le même code donne toujours le même chiffre, donc utilisable comme métrique de progression. Mais ce n'est **pas** une vérité syntaxique |
| #A22 | **Le code mort est une liste de CANDIDATS.** Une citation par chaîne de caractères ou par réflexion n'est pas vue | chaque symbole doit être confirmé un par un avant suppression — procédure imposée en 4 étapes par SPEC-02 |
| #A23 | **La langue repose sur une liste fermée de 94 mots** | ordre de grandeur et liste nominative de départ, pas exhaustivité. `trace` et `journal` ont été retirés comme homographes anglais |
| #A24 | **Le miroir de test se fait par nom de base**, pas par chemin complet | un test rangé ailleurs que dans le miroir exact compte quand même comme présent : la couverture de 40,9 % est donc plutôt **optimiste** |
| #A25 | **Les croisements entre features sont comptés par chemin**, pas par graphe transitif | un croisement indirect (A → B → C) n'est pas vu. Si cela devient nécessaire, `dart_arch_test` est la solution de repli (voir `644-00` §S3) |

---

## Le premier rapport — tête 147ca32d, 02/10/2026 à 11:31

Rapport joint tel que produit par la commande, sans retouche.

```
========================================================================
AUDIT GLOBAL MOTEUR-GR — tool/audit_global.py
Branche claude/docs/644-audit-assainissement | tete 147ca32d | 2026-10-02 11:31:33
Sujet de tete : Merge branch 'claude/chore/643-formatage' into claude/integr
========================================================================

VERDICT : NON PROPRE — 12 familles bloquantes, 889 infractions bloquantes, 1759 avertissements

-- VOLUMES --
  lib                 599 fichiers source,  120 generes,  121507 lignes
  test                482 fichiers source,    0 generes,  114963 lignes
  tool                  4 fichiers source,    0 generes,    1825 lignes
  integration_test     13 fichiers source,    0 generes,   10550 lignes
  tailles lib/ : <=300 : 488 | 301-500 : 61 | 501-800 : 27 | >800 : 23

-- BLOQUANTS --
  ECR-07       2  documentation deposee en .dart sous lib/
  ECR-13       1  element non autorise a la racine de lib/
  ECR-15      50  fichier source au dela de 500 lignes
  ECR-19     153  appel de bouton brut hors du composant unique
  ECR-20       4  nom de fichier en double dans lib/
  ECR-23     321  dependance interdite entre couches ou features
  ECR-24      40  couleur en dur hors core/theme et core/branding
  ECR-25       1  acces aux donnees depuis la couche presentation
  ECR-28     206  fonction au dela de 60 lignes
  ECR-31      20  fonction de complexite superieure a 10
  ECR-04      46  code commente livre ou TODO sans numero de tache
  VAC-01      45  valeur a completer livree en production

-- AVERTISSEMENTS --
  ECR-01     479  fichier source sans en-tete
  ECR-03      13  commentaire qui paraphrase le code
  ECR-05     442  identifiant portant un mot francais
  ECR-16     354  fichier de lib/ sans test miroir
  ECR-18     114  bloc de 6 lignes repete 3 fois ou davantage
  ECR-29       1  fonction imbriquee au dela de 4 niveaux
  MORT-01    152  symbole public sans appelant (candidat, a confirmer)
  OBS-01      54  ecran sans miette d observabilite
  TST-01       1  test ignore
  DEP-01      72  dependance en retard d une version majeure
  ECR-19e     50  IconButton ou CupertinoButton brut (perimetre etendu, hors ECR-19)
  VAC-02      25  valeur a completer citee dans un commentaire (non bloquant)
  DOC-01       2  desarmement de l analyseur par ignore_for_file dans lib/

-- TESTS --
  473 fichiers de test, 3754 cas, 1 ignores, 0 fichiers sans assertion
  miroir de lib/ couvert a 40.9 pct

-- OBSERVABILITE --
  9 ecrans avec miette sur 63 (14.3 pct)

-- OUTILLAGE --
  dart format : 0 fichiers a reformater
  flutter analyze : 0 erreurs, 0 avertissements, 0 informations | No issues found! (ran in 17.4s)
  dependances : 188 obsoletes dont 72 en saut majeur
  lints absents : public_member_api_docs, directives_ordering, lines_longer_than_80_chars, avoid_print, prefer_single_quotes, unnecessary_lambdas, always_declare_return_types
========================================================================
```

Mesure jointe par `flutter test`, le même jour : **4002 tests passés, 2 ignorés,
en 3 min 56 s — All tests passed.**

---

## Comment lire ce rapport : la phrase à retenir

**`flutter analyze` dit « No issues found! » et l'audit compte 889 infractions
bloquantes. Les deux sont vrais.**

Trois raisons, toutes mesurées :

| Réf | Raison | Preuve |
|---|---|---|
| #A26 | `analysis_options.yaml` n'active **aucune** règle au-delà de `flutter_lints` : sa section `rules:` ne contient que deux lignes commentées (lignes 29-30) | les **7** règles du référentiel ECR sont absentes |
| #A27 | `unused_element` de Dart **ne voit que le privé** (source `644-00` §S1) | les 152 symboles publics sans appelant sont invisibles **par conception** |
| #A28 | Les règles ECR portent sur l'**architecture** et la **lisibilité** — rangement, doublons, sens des dépendances, taille des fonctions — que `dart analyze` ne mesure pas | aucun outil officiel Dart ne fait d'architecture (source `644-00` §S3) |

Le code n'est pas cassé : il est **non mesuré**. D'où l'ordre du plan — le lot
645-01 arme la mesure, et c'est seulement après que le ménage a un sens.

---

## Branchement sur la gate — proposition, non appliquée

`tool/audit_global.py` **n'est pas branché** sur la gate par la tâche 644. Le
branchement est une proposition soumise à Christophe, et il n'a rien coûté à
écrire parce qu'il n'a rien modifié.

| Réf | Étage | Commande | Effet |
|---|---|---|---|
| #A29 | avant commit | `python tool/audit_global.py --rapide` | affiche le rapport, ne bloque rien |
| #A30 | gate de lot | `python tool/audit_global.py --strict` | code retour 1 s'il reste un bloquant |
| #A31 | CI (`codemagic.yaml`) | `python tool/audit_global.py --json-out audit.json` | garde l'historique chiffré d'un build à l'autre |

**Réserve honnête sur `--strict` :** aujourd'hui il rend **1**, puisqu'il y a
889 infractions. Le brancher en bloquant **tout de suite interdirait tout
commit**. C'est précisément pourquoi le lot 645-01 passe par des **tests
d'architecture à plafond** plutôt que par ce drapeau : le plafond laisse le dépôt
vivre tout en empêchant la dette de croître. `--strict` ne devient utilisable
qu'une fois les plafonds tombés à zéro.

---

## Rejouer l'audit après le temps 3 — mode opératoire

C'est la demande explicite de Christophe. Quatre commandes, dans cet ordre.

```bash
cd <worktree du depot Moteur-GR>
flutter pub get                      # SANS CECI, flutter analyze ment (piege 1)
python tool/audit_global.py --json-out audit-apres-645.json
flutter test                         # attendu : 4002 passes, 2 ignores
```

Puis comparer, compteur par compteur, avec le rapport du 02/10 ci-dessus. Un
compteur qui **monte** est une régression, et il doit être expliqué avant toute
livraison.

| Réf | Compteur | 02/10 (départ) | Cible après le temps 3 |
|---|---|---|---|
| #A32 | ECR-07 doc en `.dart` | 2 | **0** |
| #A33 | ECR-13 intrus racine `lib/` | 1 | **0** |
| #A34 | ECR-15 fichiers > 500 lignes | 50 | 0 (ou arrêt de vague assumé) |
| #A35 | ECR-19 boutons bruts | 153 | **0** |
| #A36 | ECR-20 noms en double | 4 | **0** |
| #A37 | ECR-23 dépendances interdites | 321 | 0 (voie A) ou conforme à la convention réécrite (voie B) |
| #A38 | ECR-24 couleurs en dur | 40 | **0** |
| #A39 | ECR-25 présentation → données | 1 | **0** |
| #A40 | ECR-28 fonctions > 60 lignes | 206 | 0 (ou arrêt de vague assumé) |
| #A41 | ECR-04 code commenté | 46 | **0** |
| #A42 | VAC-01 valeurs à compléter | 45 | **0** |
| #A43 | MORT-01 code mort candidat | 152 | 0 **après confirmation** — le chiffre réel sera inférieur à 152 |
| #A44 | ECR-05 identifiants français | 442 | **0** |
| #A45 | ECR-01 part avec en-tête | 20,0 % | vers 100 % |
| #A46 | OBS-01 écrans sans miette | 54 | **0** |
| #A47 | DEP-01 sauts majeurs | 72 | 68 (les 4 résolubles montés) |
| #A48 | tests passés | 4002 | **4002** — invariant, sauf 645-08 |

**La ligne #A48 est la plus importante du tableau.** Tous les autres compteurs
doivent descendre ; celui-là ne doit **pas bouger**. C'est la preuve chiffrée que
l'assainissement n'a rien cassé — la condition posée par Christophe : « Pas de
risque avec l'appli comme elle est. »

---

*Fin du 644-04. Documents de la tâche 644 : `644-00-sources.md`,
`644-01-inventaire.md`, `644-02-specifications.md`,
`644-03-decoupage-et-plan.md`, `644-04-audit-global.md`, et l'outil
`tool/audit_global.py`.*
