# 644-03 — Découpage en lots et plan au cordeau

> Tâche 644, temps 2 de l'assainissement StepWays. Athena, 02/10/2026.
> Dépôt **Moteur-GR** (jamais GR20). Base de tous les lots : tête **147ca32d** de
> `claude/integration/633-version-complete`.
> Mesures : `644-01-inventaire.md`. Spécifications : `644-02-specifications.md`.
> Sources : `644-00-sources.md`. Modèle de plan : **CORDO**, `#85085` à `#85087`.

---

## 1. Les règles du découpage

Posées par Christophe le 30/09 (`#100914`) : « Quand je dis en sécurité c'est
petit à petit en rendant tout récupérable. »

| Réf | Règle | Conséquence |
|---|---|---|
| #P01 | **Un lot = une branche** | `claude/chore/645-NN-<nom-court>`, jamais de travail sur `main` ni sur l'intégration |
| #P02 | **Un lot = un tag de retour** | `avant-645-NN` posé **avant** le premier commit du lot |
| #P03 | **Un lot = une gate complète** | `dart format` + `flutter analyze` + `flutter test` **complet** + `flutter pub outdated` |
| #P04 | **Un lot = un critère de réussite chiffré** | le compteur d'audit visé baisse, et il est cité dans le rapport du lot |
| #P05 | **Aucune fusion sans GO de Christophe** | les lots s'empilent sur une branche d'intégration `claude/integration/645-assainissement` |
| #P06 | **Comportement AVANT = APRÈS** | 4002 tests passent, aucun test réécrit — sauf 645-08, exception nommée |
| #P07 | **Le plafond ne remonte jamais** | chaque lot abaisse le plafond de son test d'architecture ; il est interdit de le relever |

---

## 2. L'ordre, et pourquoi il n'est pas négociable

**645-01 est obligatoirement le premier lot.** Ce n'est pas une préférence de
méthode, c'est ce que mesure l'inventaire.

Constat #I195 à #I206 : entre le 21/09 et le 02/10, pendant que le dépôt livrait
les builds 7 et 8, **tous** les indicateurs déjà mesurés se sont dégradés —
fichiers hors plafond 31 → 50, boutons bruts 58 → 153, doublons 3 → 4. Et la gate
est restée **verte** tout du long : `flutter analyze` rend « No issues found! »,
`dart format` ne trouve rien, 4002 tests passent.

**Une règle qu'aucune commande ne vérifie n'est pas une règle, c'est un
souhait.** Nettoyer avant d'armer la mesure, c'est rembourser une dette dont le
taux reste inconnu : au prochain lot de fonctionnalité, elle repart.

C'est aussi la demande littérale de Christophe : « tu relanceras l'audit global
pour vérif de code propre » — il faut donc que l'audit soit **rejouable par la
gate**, pas seulement par un agent.

### Graphe des dépendances

| Réf | Lot | Dépend de | Raison de la dépendance |
|---|---|---|---|
| #P08 | 645-01 mesure | — | premier, obligatoire |
| #P09 | 645-02 code mort | 645-01 | a besoin du test de code mort pour borner son plafond |
| #P10 | 645-03 boutons | 645-01 | idem |
| #P11 | 645-04 doublons | 645-01, **645-02** | retirer le code mort d'abord évite d'instruire un doublon dont une moitié est morte |
| #P12 | 645-05 couches | 645-01, **645-04**, **arbitrage de Christophe** | SPEC-06 interdit de fusionner deux types en déplaçant ; la fusion est le travail de 645-04 |
| #P13 | 645-06 découpage | 645-01, **645-03** | découper une `build()` de 679 lignes qui contient 16 boutons bruts, c'est le faire deux fois |
| #P14 | 645-07 anglais | 645-01, **645-04**, **645-05** | renommer avant d'avoir résorbé les doublons et stabilisé les emplacements, c'est renommer deux fois |
| #P15 | 645-08 valeurs à compléter | 645-01, **décision produit de Christophe** | voie à trancher : renseigner, masquer ou retirer |
| #P16 | 645-09 observabilité | 645-01, **645-06** | instrumenter une `build()` de 679 lignes puis la découper, c'est déplacer l'instrumentation |
| #P17 | 645-10 dépendances | 645-01 | indépendant du reste ; peut passer à tout moment après 645-01 |
| #P18 | 645-11 en-têtes et couleurs | 645-01 | indépendant. **Variable d'ajustement du plan** : sécable à volonté |
| #P19 | 645-12 livre de bord | **tous les autres** | dernier par construction : il journalise ce qui a été fait |

**Trois lots sont indépendants et peuvent passer en parallèle après 645-01 :**
645-10 (dépendances), 645-11 (en-têtes et couleurs), et 645-08 dès que Christophe
a tranché.

---

## 3. Coût estimé par lot

**Base de calcul, et elle est honnête :** un lot moyen de ce dépôt coûte
**50 dollars d'API**. C'est **un seul point de mesure**, pas une statistique. Les
estimations ci-dessous sont ce point multiplié par le volume mesuré (nombre de
fichiers à ouvrir, nombre d'occurrences à traiter). Elles sont **indicatives** et
devront être recalées après les deux premiers lots réellement exécutés.

| Réf | Lot | Volume mesuré | Lots-équivalents | Coût estimé |
|---|---|---|---|---|
| #P20 | 645-01 mesure | 7 tests neufs + `analysis_options.yaml` | 1,5 | **75 $** |
| #P21 | 645-02 code mort | 152 candidats, confirmation 4 étapes chacun | 2,0 | **100 $** |
| #P22 | 645-03 boutons | 153 occurrences, 27 fichiers, captures avant/après | 2,5 | **125 $** |
| #P23 | 645-04 doublons | 5 concepts, instruction + comparaison ligne à ligne | 1,5 | **75 $** |
| #P24 | 645-05 couches, **voie A** | 321 imports, 3 modèles déplacés | 3,0 | **150 $** |
| #P24b | 645-05 couches, **voie B** | convention réécrite + 2 cas isolés | 0,5 | **25 $** |
| #P25 | 645-06 découpage | 50 fichiers + 206 fonctions, 4 vagues | 4,0 | **200 $** |
| #P26 | 645-07 anglais | 442 identifiants + 31 fichiers, 4 étapes | 2,5 | **125 $** |
| #P27 | 645-08 valeurs à compléter | 3 fichiers, 45 occurrences | 0,5 | **25 $** |
| #P28 | 645-09 observabilité | 1 service + 54 écrans | 1,5 | **75 $** |
| #P29 | 645-10 dépendances | 4 paquets + essais émulateur | 1,0 | **50 $** |
| #P30 | 645-11 en-têtes et couleurs | 479 en-têtes + 40 couleurs | 1,5 | **75 $** |
| #P31 | 645-12 livre de bord | 2 documents + 1 test | 0,5 | **25 $** |

| Réf | Total | Coût |
|---|---|---|
| #P32 | **voie A** (zone `lib/domain/` partagée) | **1 100 $** |
| #P33 | **voie B** (`trek` assumé comme socle) | **975 $** |

**Lecture de ce total.** C'est beaucoup, et ça se découpe. Trois façons de le
réduire, chiffrées :

| Réf | Arbitrage possible | Économie |
|---|---|---|
| #P34 | choisir la voie B pour 645-05 | **−125 $** |
| #P35 | s'arrêter après la vague 2 de 645-06 (les 10 pires au lieu des 50) | **−100 $** |
| #P36 | ne traiter que les 31 noms de fichier de 645-07, pas les 442 identifiants | **−95 $** |

**Le minimum utile, si le budget est serré :** 645-01 + 645-02 + 645-03 +
645-08 = **325 $**. Ces quatre lots arment la mesure, retirent le code mort,
ramènent les boutons sur le composant unique et enlèvent les valeurs bidon
visibles par le randonneur. C'est le meilleur rapport propreté / dollar du plan.

---

## 4. Le plan au cordeau — fiches CORDO

Modèle CORDO (`#85085`), **12 champs obligatoires par lot**. Les prompts du champ
C5 sont **autonomes** : l'agent qui le reçoit a tout ce qu'il faut, sans lire un
autre document (anti-pattern AP3 de `#85087`).

**Scope du GO (anti-pattern AP5) :** un GO donné sur ce plan vaut pour **tous**
les lots qu'il nomme explicitement, et seulement ceux-là. Un GO sur 645-01 ne
vaut pas pour 645-02.

---

### 645-01 — Armer la mesure

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-01 |
| **C2 Fichier:ligne** | NOUVEAUX : `test/structurel/couches_respectees_645_test.dart`, `aucun_code_mort_645_test.dart`, `aucun_doublon_645_test.dart`, `aucun_bouton_brut_645_test.dart`, `aucune_valeur_a_completer_645_test.dart`, `aucun_dialogue_hors_routeur_645_test.dart`, `taille_et_rangement_645_test.dart`. MODIFIÉ : `analysis_options.yaml` lignes 28-31 (section `rules:`) |
| **C3 Description** | Créer 7 tests d'architecture dans `test/structurel/`, sur le modèle des 15 qui existent déjà. Chacun porte un **plafond chiffré** égal à la mesure du 02/10 et échoue si le chiffre augmente. Renseigner la section `rules:` d'`analysis_options.yaml` avec les 7 règles absentes, **en sévérité `info`** pour ne pas casser la gate |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-01)* |
| **C6 Branche** | `claude/chore/645-01-armer-la-mesure` depuis `origin/claude/integration/633-version-complete` |
| **C7 Commit** | `test(645-01): sept tests d architecture, pour que l audit soit rejouable par la gate` |
| **C8 Test** | `flutter test test/structurel/` → les 7 passent. Puis `flutter test` → **4002 passés, 2 ignorés**. Puis `flutter analyze --no-pub` → **No issues found!** |
| **C9 QA** | Les 7 plafonds valent exactement les chiffres #I65-67, #I142, #I78, #I80, #I95-96, #I26-28, #I31-32. Aucun fichier de `lib/` modifié : `git diff --stat` ne montre que `test/` et `analysis_options.yaml` |
| **C10 Smoke** | `python tool/audit_global.py --strict` → même rapport qu'au 02/10. Essai de régression : ajouter un `ElevatedButton(` dans un fichier de feature doit faire **échouer** `flutter test test/structurel/` ; l'essai est constaté puis annulé, il ne part pas dans le commit |
| **C11 Rollback** | `git revert <sha>`. Tag `avant-645-01` posé avant le premier commit. Zéro fichier applicatif touché : retour total |
| **C12 Dépendances** | Aucune. **Premier lot, obligatoire** |

```
PROMPT 645-01 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-01 sur la branche
claude/chore/645-01-armer-la-mesure depuis
origin/claude/integration/633-version-complete (tete 147ca32d). git fetch
d abord, cd explicite dans chaque commande git. Ne remets JAMAIS le depot
Skynet racine sur main. Pose le tag avant-645-01 AVANT ton premier commit.

OBJET : creer 7 tests d architecture dans test/structurel/ et renseigner
analysis_options.yaml. TU NE TOUCHES AUCUNE LIGNE DE lib/. Si tu te trouves
en train d editer un fichier de lib/, arrete-toi.

FORME A SUIVRE : test/structurel/ contient deja 15 tests d architecture qui
lisent l arborescence des sources en test Dart ordinaire. Lis d abord
test/structurel/tout_ecran_a_une_route_573_test.dart et
test/structurel/aucune_icone_non_constante_619_test.dart, et copie leur forme.
N AJOUTE AUCUNE DEPENDANCE au pubspec : il n existe pas d outil officiel
d architecture en Dart, et le depot ecrit les siens a la main.

MECANIQUE OBLIGATOIRE — LE PLAFOND. Les 7 tests ne peuvent pas etre verts
aujourd hui : il y a 889 infractions. Chaque test porte donc une constante de
plafond egale a la mesure du 02/10/2026, et il ECHOUE si le chiffre mesure
DEPASSE ce plafond. Exemple de forme attendue :

  const plafondBoutonsBruts = 153; // mesure 02/10/2026, tete 147ca32d
  test('ECR-19 : pas plus de boutons bruts qu au 02/10', () {
    final trouves = compterBoutonsBruts();
    expect(trouves.length, lessThanOrEqualTo(plafondBoutonsBruts),
        reason: 'Les boutons bruts augmentent. Utilise AppButton.');
  });

LES 7 TESTS ET LEUR PLAFOND EXACT :

1. couches_respectees_645_test.dart — ECR-23. Lit les directives import de
   chaque .dart de lib/ hors generes. Compte (a) les imports de core/ ou
   shared/ vers features/ : plafond 78 ; (b) les imports croises entre deux
   features differentes : plafond 243. Une feature est le 3e segment du
   chemin (lib/features/<nom>/...). Attention aux imports relatifs ../../ :
   resous-les avant de comparer.

2. aucun_code_mort_645_test.dart — plafond 152. Releve les declarations de
   haut niveau publiques de lib/ (class, enum, mixin, extension, typedef, et
   fonctions de premier niveau ; EXCLUS les noms commencant par _). Compte
   celles qui ne sont citees NULLE PART dans lib/, test/, integration_test/
   et tool/ en dehors de leur propre fichier. Ignore les chaines de
   caracteres et les commentaires quand tu cherches les citations.

3. aucun_doublon_645_test.dart — plafond 4. Compte les noms de base de
   fichier .dart presents deux fois ou plus dans lib/, hors *.g.dart et
   *.freezed.dart. Les 4 connus : gpx_parser.dart, stage.dart,
   track_point.dart, tracking_overlay.dart.

4. aucun_bouton_brut_645_test.dart — plafond 153. Compte les appels de
   ElevatedButton, TextButton, OutlinedButton et FilledButton dans lib/,
   en EXCLUANT lib/shared/widgets/app_button.dart (c est le composant
   unique) ET lib/core/theme/ (un theme DOIT citer ElevatedButtonThemeData
   et ElevatedButton.styleFrom, c est son role, verifie dans app_theme.dart
   lignes 265-287 et 407). Motif : \bNomDuBouton\s*\( ou
   \bNomDuBouton\.(icon|styleFrom).

5. aucune_valeur_a_completer_645_test.dart — plafond 45. Cherche dans lib/,
   HORS LIGNES DE COMMENTAIRE (une ligne qui commence par // ou /// ne
   compte pas), les motifs ancres par frontiere de mot : example\.org,
   example\.com, [AÀ]\s*COMPL[EÉ]TER ou a\s+completer, \bCHANGE_?ME\b,
   \bvotre-, \byour-, \blocalhost\b, [Ll]orem\s+ipsum, \bdummy\b.
   ATTENTION, PIEGE MESURE : un motif changeme NON ancre attrape le mot
   francais changeMEnt 82 fois, et placeholder attrape le parametre
   legitime placeholder: de Flutter. ANCRE TES MOTIFS.

6. aucun_dialogue_hors_routeur_645_test.dart — plafond : mesure-le toi-meme
   et inscris-le en constante avec la date. Compte les appels showDialog et
   showModalBottomSheet dans lib/ qui ne passent pas par le routeur. Ecris
   dans le test, en commentaire, le critere exact que tu as retenu pour
   "passe par le routeur" — sans critere ecrit, ce test ne vaut rien.

7. taille_et_rangement_645_test.dart — trois verifications, trois plafonds :
   (a) ECR-13, la racine de lib/ ne contient que core, features, shared,
   i18n et main.dart — plafond d intrus : 1 (c est lib/docs/) ;
   (b) ECR-07, zero .dart sous un dossier docs/ dans lib/ — plafond 2 ;
   (c) ECR-15, fichiers source de plus de 500 lignes — plafond 50.

ANALYSIS_OPTIONS.YAML : la section rules: (lignes 28-31) ne contient
aujourd hui que deux lignes commentees. Ajoute les 7 regles suivantes, TOUTES
EN SEVERITE info, jamais en warning ni en error : public_member_api_docs,
directives_ordering, lines_longer_than_80_chars, avoid_print,
prefer_single_quotes, unnecessary_lambdas, always_declare_return_types.
Utilise la section analyzer: errors: pour forcer la severite a info.
RAISON : ces regles remontent des milliers d infractions ; les activer en
bloquant casserait la gate et interdirait tout autre lot. On les allume pour
MESURER, et leur passage en bloquant sera un lot a part.

GATE COMPLETE AVANT DE LIVRER, dans cet ordre, et les 4 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub          -> attendu : No issues found!
  flutter test                      -> attendu : 4002 passes, 2 ignores
  python tool/audit_global.py --rapide

ESSAI DE REGRESSION OBLIGATOIRE, a faire et a RAPPORTER : ajoute
temporairement un ElevatedButton( dans un fichier de lib/features/, verifie
que flutter test test/structurel/ ECHOUE, puis ANNULE la modification
(git checkout -- <fichier>). Cet essai ne part pas dans le commit. Si le test
ne detecte pas l ajout, ton test est faux : corrige-le.

COMMIT ET PUSH par le registre gerer_git, avec repo-path sur ton worktree.
Message : test(645-01): sept tests d architecture, pour que l audit soit
rejouable par la gate
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres : decoupe.
Horodate avec l heure systeme. « Christophe » partout.
RAPPORT ATTENDU : les 7 plafonds inscrits, le resultat des 4 commandes de
gate, le resultat de l essai de regression, et ce qui reste ouvert.
```

---

### 645-02 — Retirer le code mort public confirmé

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-02 |
| **C2 Fichier:ligne** | 152 candidats sur 8 dossiers : `lib/core/services` (23), `lib/features/trek` (19), `settings` (11), `trail` (7), `map` (7), `planning` (6), `safety` (5), `journal` (5), reste (69). Liste nominative : sortie JSON de `tool/audit_global.py`, section `code_mort.candidats_morts` |
| **C3 Description** | Pour chaque candidat, appliquer les 4 étapes de confirmation de SPEC-02 (#X30 à #X33). Supprimer ceux qui passent les 4. Inscrire au rapport, nominativement, chaque symbole supprimé et chaque symbole écarté avec sa raison |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-02)* |
| **C6 Branche** | `claude/chore/645-02-code-mort` depuis la tête de `claude/integration/645-assainissement` |
| **C7 Commit** | un commit **par dossier** : `chore(645-02): retirer le code mort confirme de <dossier>` |
| **C8 Test** | `flutter test` → 4002 passés, **aucun test modifié**. `flutter build appbundle --release` → réussit |
| **C9 QA** | Le rapport liste 152 lignes : symbole, verdict (supprimé / écarté), raison si écarté. `git diff --stat` ne montre aucune modification de `test/` |
| **C10 Smoke** | `flutter build appbundle --release` — c'est le filet le plus sûr : un symbole supprimé à tort casse la compilation |
| **C11 Rollback** | `git revert <sha du dossier>`. Tag `avant-645-02`. Découpage par dossier : un retour sur `core/services` n'annule pas `features/trek` |
| **C12 Dépendances** | **645-01** (le test de code mort borne le plafond) |

```
PROMPT 645-02 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-02 sur claude/chore/645-02-code-mort depuis
la tete de origin/claude/integration/645-assainissement. git fetch d abord,
cd explicite dans chaque commande git. Ne remets JAMAIS le depot Skynet
racine sur main. Pose le tag avant-645-02 AVANT ton premier commit.

OBJET : retirer de lib/ les declarations publiques qui n ont AUCUN appelant.

POURQUOI CA NE PEUT PAS VENIR DE L ANALYSEUR, et il faut que tu le saches :
le diagnostic unused_element de Dart ne voit QUE le prive. Texte officiel
(dart.dev/tools/diagnostics/unused_element, consulte le 02/10/2026) : il est
produit quand « a private declaration isn t referenced in the library that
contains the declaration ». Une declaration PUBLIQUE sans appelant n est
JAMAIS signalee. C est pour cela que flutter analyze rend No issues found
sur ce code alors que 152 symboles publics n ont aucun appelant.

OBTIENS LA LISTE :
  python tool/audit_global.py --section code_mort --json
La liste est dans code_mort.candidats_morts : 152 entrees, chacune avec
symbole, fichier et ligne.

CE SONT DES CANDIDATS, PAS DES CONDAMNES. Le detecteur ne voit pas une
citation par chaine de caracteres ni par reflexion. Pour CHAQUE symbole, dans
cet ordre, et tu t arretes des qu une etape le sauve :

  E1 Cherche le nom en texte brut dans TOUT le depot, y compris les .json,
     .yaml, les .dart generes, firestore.rules et codemagic.yaml. Une
     occurrence hors de sa declaration = ECARTE.
  E2 Cherche le nom comme CHAINE de caracteres : 'Nom' et "Nom". C est le
     cas de la reflexion et des registres. Une occurrence = ECARTE.
  E3 Lis son doc comment. S il l annonce comme point d extension destine a
     etre appele de l exterieur = ECARTE.
  E4 Verifie s il est dans test/structurel/registre_des_dormants.dart. S il
     y est, c est une dette ASSUMEE ET TRACEE, pas du code mort = ECARTE.

Un symbole ecarte est inscrit au rapport AVEC SA RAISON. Le chiffre final
sera inferieur a 152 et c est normal. Ne force jamais une suppression.

DECOUPAGE : un commit PAR DOSSIER, dans cet ordre, du plus gros au plus
petit : lib/core/services (23 candidats), lib/features/trek (19),
lib/features/settings (11), lib/features/trail (7), lib/features/map (7),
lib/features/planning (6), lib/features/safety (5), lib/features/journal (5),
puis le reste. Message : chore(645-02): retirer le code mort confirme de
<dossier>

INTERDIT : modifier un fichier de test/. Si un test cite un symbole, ce
symbole N EST PAS MORT — il est ECARTE a l etape E1.

ABAISSE LE PLAFOND : apres suppression, mets a jour la constante de plafond
de test/structurel/aucun_code_mort_645_test.dart au chiffre atteint, avec la
date en commentaire. Le plafond ne remonte JAMAIS.

GATE COMPLETE AVANT DE LIVRER, les 4 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub          -> attendu : No issues found!
  flutter test                      -> attendu : 4002 passes, 2 ignores
  flutter build appbundle --release -> DOIT REUSSIR. C est ton filet le plus
                                       sur : un symbole supprime a tort
                                       casse la compilation.

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : un tableau des 152 lignes (symbole, verdict, raison si
ecarte), le nouveau plafond, le resultat des 4 commandes de gate.
```

---

### 645-03 — Ramener les boutons sur `AppButton`

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-03 |
| **C2 Fichier:ligne** | 27 fichiers, 153 occurrences. En tête : `lib/features/checklist/presentation/checklist_screen.dart` (16), `checklist/widgets/checklist_bottom_actions.dart` (13), `safety/presentation/health_info_screen.dart` (10), `planning/presentation/trail_planning_screen.dart` (8), `planning/presentation/calendar_screen.dart` (7), `booking/presentation/nuitees_screen.dart` (6), `hub/presentation/widgets/hub_start_trek_button.dart` (6) |
| **C3 Description** | Remplacer chaque appel brut par `AppButton` avec le paramétrage équivalent. Si le `style:` local diffère du thème, porter le besoin dans `AppButton` en **paramètre nommé avec valeur par défaut** — jamais en cas particulier chez l'appelant. Si le besoin n'est pas exprimable en paramètre, **sortir le fichier du lot** et l'inscrire en arbitrage |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-03)* |
| **C6 Branche** | `claude/chore/645-03-boutons` |
| **C7 Commit** | un commit **par fichier** : `refactor(645-03): <fichier> passe par AppButton` |
| **C8 Test** | `flutter test` → 4002 passés. Les tests de widget cherchent les boutons par libellé et par `find.byType` : un changement de type **fait échouer** les tests concernés, c'est le filet voulu |
| **C9 QA** | Captures avant / après des 7 écrans les plus touchés, comparées **écran par écran** par Skynet. Tout écart visuel non expliqué = lot refusé. `lib/core/theme/app_theme.dart` n'est **pas** modifié |
| **C10 Smoke** | `integration_test/persona_s1_lea_test.dart` et `persona_s2_marc_test.dart` sur émulateur, captures comparées |
| **C11 Rollback** | `git revert <sha du fichier>` — 27 commits séparés. Tag `avant-645-03` |
| **C12 Dépendances** | **645-01** |

```
PROMPT 645-03 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-03 sur claude/chore/645-03-boutons depuis la
tete de origin/claude/integration/645-assainissement. git fetch d abord, cd
explicite dans chaque commande git. Ne remets JAMAIS le depot Skynet racine
sur main. Pose le tag avant-645-03 AVANT ton premier commit.

OBJET : remplacer 153 appels bruts de bouton du framework par le composant
unique AppButton, dans 27 fichiers.

LE COMPOSANT EXISTE DEJA ET IL EST BIEN FAIT : lib/shared/widgets/
app_button.dart, 8 parametres nommes (label, onPressed, variant, isLoading,
icon, isFullWidth, tone, minHeight), 4 variantes en enum AppButtonVariant,
champs non evidents documentes. Le probleme n est PAS son absence, c est son
contournement : 58 appels bruts le 21/09, 153 le 02/10 — multiplie par 2,6
en onze jours. Consequence concrete : changer la hauteur tactile d un bouton
demande d ouvrir 27 fichiers au lieu d un.

OBTIENS LA LISTE :
  python tool/audit_global.py --section composants_et_valeurs --json
Section composants_et_valeurs.boutons_bruts_par_fichier, triee par volume.

DEUX EXCLUSIONS, A NE PAS TOUCHER :
  - lib/shared/widgets/app_button.dart : c est le composant lui-meme.
  - lib/core/theme/app_theme.dart : un theme DOIT citer
    ElevatedButtonThemeData et ElevatedButton.styleFrom, c est son role.
    Verifie : lignes 265-287 et 407. HORS PERIMETRE.

ORDRE IMPOSE, par volume decroissant, parce qu il concentre le gain :
  16 lib/features/checklist/presentation/checklist_screen.dart
  13 lib/features/checklist/widgets/checklist_bottom_actions.dart
  10 lib/features/safety/presentation/health_info_screen.dart
   8 lib/features/planning/presentation/trail_planning_screen.dart
   7 lib/features/planning/presentation/calendar_screen.dart
   6 lib/features/booking/presentation/nuitees_screen.dart
   6 lib/features/hub/presentation/widgets/hub_start_trek_button.dart
  puis les 20 autres fichiers.

LE VRAI RISQUE DE CE LOT EST VISUEL. Un bouton brut porte souvent un style:
local qui differe du theme. Trois regles, dans cet ordre :
  R1 Si le style: ne fait que REPETER le theme : remplace directement.
  R2 Si le style: DIFFERE du theme : porte le besoin dans AppButton en
     PARAMETRE NOMME AVEC VALEUR PAR DEFAUT. Jamais de cas particulier chez
     l appelant.
  R3 Si le besoin n est pas exprimable en parametre : SORS LE FICHIER DU LOT
     et inscris-le en arbitrage pour Christophe. On ne force pas.

COMPORTEMENT AVANT = APRES. Aucune harmonisation de teinte, aucune
correction d apparence au passage, meme si quelque chose te semble laid.
C est un deplacement, pas une amelioration.

DECOUPAGE : un commit PAR FICHIER. 27 commits. Message :
refactor(645-03): <chemin du fichier> passe par AppButton
RAISON : un ecart visuel sur un ecran ne doit pas annuler les 26 autres.

ABAISSE LE PLAFOND de test/structurel/aucun_bouton_brut_645_test.dart apres
chaque fichier, avec la date. Cible finale : 0 hors app_button.dart et
core/theme/. Le plafond ne remonte JAMAIS.

GATE COMPLETE AVANT DE LIVRER, les 4 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub          -> attendu : No issues found!
  flutter test                      -> attendu : 4002 passes, 2 ignores
  flutter build appbundle --release -> DOIT REUSSIR

CAPTURES OBLIGATOIRES : pour les 7 ecrans les plus touches, une capture
AVANT et une capture APRES, via integration_test/persona_s1_lea_test.dart et
persona_s2_marc_test.dart sur l emulateur. Depose-les et nomme-les. Skynet
les compare ecran par ecran avant de montrer quoi que ce soit a Christophe.

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : fichiers traites et occurrences par fichier, fichiers
SORTIS du lot avec leur raison (regle R3), nouveau plafond, resultat des 4
commandes de gate, et ou sont les captures.
```

**ARB-645-03 (Christophe, 02/10/2026 18:01)** : la hauteur 48 dp et les coins
arrondis 12 dp du composant unique AppButton sont LA norme des boutons, y
compris le bouton Demarrer la randonnee (fin du stade) et les boutons convertis
depuis le theme (fin des 52 dp). Le rendu strictement identique n etait pas
exige pour ce lot. Les minHeight 52 explicites herites des lots SW-SKIN seront
alignes dans un lot ulterieur. Lot 645-03 fusionne en 0310fa9b.

---

### 645-04 — Résorber les quatre doublons

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-04 |
| **C2 Fichier:ligne** | `lib/core/geo/gpx_parser.dart` + `lib/features/trek/data/gpx_parser.dart` ; `lib/core/models/stage.dart` + `lib/features/trek/domain/models/stage.dart` ; `lib/core/geo/track_point.dart` + `lib/features/trek/domain/models/track_point.dart` ; `lib/features/tracking/presentation/tracking_overlay.dart` + `lib/features/trek/presentation/map/overlay/tracking_overlay.dart` ; `lib/core/ui/loading_view.dart` + `lib/shared/widgets/loading_overlay.dart` |
| **C3 Description** | Par concept : compter les appelants de chaque côté, comparer ligne à ligne, **écrire** laquelle est retenue et pourquoi, puis résorber. Si les deux ont divergé, l'implémentation retenue couvre **les deux** comportements et un test par comportement le prouve. Sinon, sortir le concept du lot |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-04)* |
| **C6 Branche** | `claude/chore/645-04-doublons` |
| **C7 Commit** | un commit **par concept** : `refactor(645-04): un seul <concept>` |
| **C8 Test** | `flutter test` → 4002 passés **sans qu'un seul test soit réécrit**. Les tests des **deux** anciens emplacements sont conservés et passent contre l'implémentation unique |
| **C9 QA** | Le rapport porte, par concept : nombre d'appelants de chaque côté, le diff des deux implémentations, la décision écrite. Le compte de fichiers générés baisse |
| **C10 Smoke** | `flutter build appbundle --release`. Pour `gpx_parser` et `track_point` : essai d'import GPX réel sur émulateur |
| **C11 Rollback** | `git revert <sha du concept>` — 5 commits. Tag `avant-645-04` |
| **C12 Dépendances** | **645-01**, **645-02** (retirer le code mort d'abord évite d'instruire un doublon dont une moitié est morte) |

```
PROMPT 645-04 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-04 sur claude/chore/645-04-doublons depuis la
tete de origin/claude/integration/645-assainissement. git fetch d abord, cd
explicite dans chaque commande git. Ne remets JAMAIS le depot Skynet racine
sur main. Pose le tag avant-645-04 AVANT ton premier commit.

OBJET : ramener a UNE SEULE implementation chacun des 5 concepts dedoubles.

LES 5 CONCEPTS, avec leur etat mesure le 02/10/2026 :

C-1 gpx_parser
    lib/core/geo/gpx_parser.dart ET lib/features/trek/data/gpx_parser.dart
    ETAT MESURE : celui de core/ IMPORTE celui de trek/. C est donc deja une
    delegation, pas une divergence. Le menage y sera moins couteux que prevu,
    mais VERIFIE-LE avant de trancher.

C-2 stage
    lib/core/models/stage.dart ET lib/features/trek/domain/models/stage.dart
    ETAT : doublon NOUVEAU, apparu entre le 21/09 et le 02/10. Instruis
    celui-la EN PREMIER : lequel est le plus recent, lequel est le plus lu.

C-3 track_point
    lib/core/geo/track_point.dart ET
    lib/features/trek/domain/models/track_point.dart
    ETAT : chacun traine son .freezed.dart et son .g.dart — 6 fichiers pour
    un seul concept.

C-4 tracking_overlay
    lib/features/tracking/presentation/tracking_overlay.dart ET
    lib/features/trek/presentation/map/overlay/tracking_overlay.dart

C-5 loading_view / loading_overlay
    lib/core/ui/loading_view.dart ET lib/shared/widgets/loading_overlay.dart
    ETAT : doublon FONCTIONNEL A NOMS DIFFERENTS. Aucune commande ne le voit,
    seule la revue. Signale le 21/09, toujours la.

INSTRUCTION PREALABLE OBLIGATOIRE, concept par concept, AVANT toute
suppression. Tu produis et tu RAPPORTES :
  I1 le nombre d appelants de chaque cote, avec la liste ;
  I2 le diff des deux implementations, lu ligne a ligne ;
  I3 laquelle tu retiens, ET POURQUOI, ecrit en une phrase.
Un doublon resorbe par « j ai garde celui de core/ » sans comparaison est
REFUSE.

PIEGE PRINCIPAL — LA DIVERGENCE. Si les deux implementations ont diverge, en
garder une CHANGE le comportement des appelants de l autre. Regle :
l implementation retenue doit couvrir LES DEUX comportements, et un test par
comportement le prouve. Si c est impossible, SORS LE CONCEPT DU LOT et
inscris-le en arbitrage pour Christophe.

INTERDIT : reecrire un test existant. Les tests des DEUX anciens
emplacements sont CONSERVES et doivent passer contre l implementation
unique. Si un test ne passe plus, c est que le comportement a change : tu
t arretes et tu rapportes.

DECOUPAGE : un commit PAR CONCEPT, dans l ordre C-2, C-1, C-3, C-4, C-5.
Message : refactor(645-04): un seul <concept>

ABAISSE LE PLAFOND de test/structurel/aucun_doublon_645_test.dart apres
chaque concept. Cible finale : 0. Le plafond ne remonte JAMAIS.

GATE COMPLETE AVANT DE LIVRER, les 4 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub          -> attendu : No issues found!
  flutter test                      -> attendu : 4002 passes, 2 ignores
  flutter build appbundle --release -> DOIT REUSSIR
Pour C-1 et C-3, en plus : un essai d import GPX reel sur l emulateur.

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : par concept, I1 + I2 + I3, le verdict, et les concepts
sortis du lot avec leur raison. Plus le resultat des 4 commandes de gate.
```

**ARB-645-04 — TROIS CONCEPTS SORTIS DU LOT, ARBITRAGE DEMANDE A CHRISTOPHE
(Hephaistos, 02/10/2026).** Le lot a instruit les cinq concepts comme la fiche
l'exige (appelants de chaque cote, diff lu ligne a ligne, decision ecrite).
**Deux ont ete resorbes** : `tracking_overlay` (commit `refactor(645-04): un
seul tracking_overlay`) et `loading_view` / `loading_overlay`, deja resorbe par
le lot 645-02 et desormais **mesure** par une garde de forme. **Trois sortent du
lot** au titre de la regle « si c'est impossible, sors le concept », chacun pour
une raison mesuree, et aucun des trois ne peut etre tranche sans Christophe.

| Ref | Concept | Ce que la mesure a montre | Ce qui est demande |
|---|---|---|---|
| **ARB-645-04-a** | `stage` | Ce ne sont **pas** deux implementations d'un concept, mais **deux types differents** : `StageModel` (`core/models/`, 80 appelants, adosse a Drift par `fromDb`/`toCompanion`, `name`/`description` uniques, duree en minutes nullable) et `Stage` (`features/trek/domain/models/`, 26 appelants, i18n 5 langues `nameFr..nameEs`, `orderIndex`, duree en secondes). `gps_providers.dart` porte un **convertisseur explicite et documente** de l'un vers l'autre (`domainStagesProvider`). En retenir un, c'est **fusionner deux types en deplacant** — ce que SPEC-06 interdit. Correction de fait (verifiee le 02/10/2026 par `git log --follow` sur l'historique **complet**) : les deux fichiers ne naissent **pas** du commit `6df3736a` du 21/09, mais de **deux commits distincts de mai 2026** — `c973dbf9` (26/05, *feat(P1): modeles Freezed Stage/Poi/UserProgress/Trail*) cree `lib/core/models/stage.dart`, et `a816b98d` (30/05, *feat(P2): E2.1a modeles Trek Freezed*) cree `lib/features/trek/domain/models/stage.dart`. Le doublon a donc **quatre mois**, pas onze jours : la conclusion reste vraie et devient **plus forte**, puisque les deux types ont vecu et divergé separement tout ce temps. Pourquoi l'erreur : le clone de travail etait **superficiel** (*shallow*), greffe sur `6df3736a` ; `--follow` y designe fatalement la greffe comme origine de tout fichier. Lecon de methode : **tout constat de datation exige `git fetch --unshallow` d'abord** | Trancher **#X60 / #X61** (voie A `lib/domain/` pour les modeles partages, ou voie B `trek` assume comme socle) : SPEC-06 nomme `stage` dans la voie A, et la place du type decide du doublon. Tant que l'arbitrage manque, le deplacer serait a refaire |
| **ARB-645-04-b** | `track_point` | **Vraie divergence, meme nom de classe.** `core/geo/` (28 appelants) porte `altitude` et `distanceFromStart`, tous deux requis, sans horodatage : c'est un point de **trace de reference**. `features/trek/domain/models/` (14 appelants) porte `elevation` et `timestamp`, sans distance cumulee : c'est un **echantillon d'enregistrement GPS**. Un seul type ne peut pas satisfaire les deux series de tests existantes : les tests de la seconde **construisent** `TrackPoint(..., elevation: ...)` et **relisent** `.elevation`. Les faire passer imposerait soit de renommer un parametre **dans un test existant** (interdit par le lot : « aucun nom »), soit de porter `altitude` ET `elevation` comme deux champs du meme type — deux champs pour une seule grandeur physique, modele incoherent | Dire **ce qu'est un `TrackPoint`** : un point de trace, un echantillon d'enregistrement, ou deux types qui doivent porter deux noms (p. ex. `PointDeTrace` et `PointEnregistre`). Le renommage touche des tests existants : il demande une levee explicite de la regle « aucun test reecrit ». Depend aussi de **#X60 / #X61**, qui nomme `track_point` |
| **ARB-645-04-c** | `gpx_parser` | La delegation annoncee est confirmee : `core/geo/gpx_parser.dart` (5 appelants) **importe** `features/trek/data/gpx_parser.dart` (4 appelants) et lui delegue tout. Mais **la separation est portante, et c'est la mesure qui le dit** : `features/trek/data/gpx_parser.dart` est du **Dart pur**, et `dart run tool/publier_sentier.dart` en depend par `tool/publication/source_de_sentier.dart`. La facade, elle, a besoin de `rootBundle` (`package:flutter/services.dart`, donc `dart:ui`). **Essai fait** : en ajoutant cet import au parseur retenu, `dart run tool/publier_sentier.dart verifier` passe de **sortie 0 a sortie 254**. Les reunir en un fichier casse donc l'outil de publication ; ne pas les reunir mais renommer la facade change le nom de classe `GpxParser` dans **quatre fichiers de test existants** — compte **re-verifie le 02/10/2026 et confirme** : `test/core/geo/gpx_parser_test.dart` (import + 5 occurrences + le nom du `group`), `test/features/map/providers/gpx_track_provider_test.dart` (import + 3), `test/features/map/providers/simplified_track_provider_test.dart` (import + 1), `test/comportement/sentier_distant_marchable_606_test.dart` (import + 2, dont 1 dans une chaine). Ce qui etait **imprecis** dans la redaction initiale, et que la mesure corrige : c'est la methode `parseFromAsset` qui n'est citee que par **un seul** de ces quatre fichiers (`sentier_distant_marchable_606_test.dart`) ; les trois autres passent par `parseFromString`. Et dans les quatre, **seuls le nom de classe et le chemin d'import changent** : aucune attente, aucune valeur, aucun nom de parametre — c'est ce qui rend la levee de regle etroite et le cout reel faible | Choisir : **(a)** renommer la facade pour qu'elle dise ce qu'elle est (`GpxDepuisLesAssets`), ce qui touche 4 tests existants et demande la meme levee ; **(b)** donner a `tool/` son propre chemin d'analyse pour liberer `lib/` de la contrainte Dart pur, puis fusionner ; **(c)** declarer la couture legitime et **retirer `gpx_parser` de la cible ECR-20** avec cette justification ecrite. Recommandation d'Hephaistos : **(a)**, la moins chere des trois, et la seule qui laisse une seule reponse a « qu'est-ce qui lit un GPX » |

**DECISION Christophe 02/10/2026 21:28 : option (a).** Levee explicite et limitee de la
regle « aucun test reecrit » pour ce seul renommage. La facade `lib/core/geo/gpx_parser.dart`
devient `lib/core/geo/gpx_depuis_les_assets.dart` et sa classe `GpxParser` devient
`GpxDepuisLesAssets` ; `parseFromAsset` garde son nom. Le parseur Dart pur
`lib/features/trek/data/gpx_parser.dart` ne bouge pas, puisque c'est lui qui porte
`dart run tool/publier_sentier.dart`. Execute par le lot 645-11 (commit
`refactor(645-04): la facade GPX dit ce qu elle est`), qui abaisse du meme coup le plafond
de `test/structurel/aucun_doublon_645_test.dart` de 3 a 2.

**Plafond ECR-20 au terme du lot : 3** (`gpx_parser.dart`, `stage.dart`,
`track_point.dart`), contre 4 avant. Il ne remontera pas. La cible 0 reste
atteignable, mais elle passe par les trois arbitrages ci-dessus, pas par du
code.

**DECISION Christophe 02/10/2026 21:55 : voie A.** `stage` et `track_point`
résolus par le lot 645-05 : rangement dans `lib/domain/` et noms de fichiers
distincts, types inchangés.

Exécution, le 02/10/2026, par le lot 645-05 (branche
`claude/chore/645-05-couches`) : le modèle de domaine
`features/trek/domain/models/stage.dart` est devenu `lib/domain/stage.dart`
(classe `Stage`) et le modèle Drift `core/models/stage.dart` est devenu
`core/models/stage_row.dart` (classe `StageModel`, inchangée, toujours dans le
socle) ; l'échantillon GPS `features/trek/domain/models/track_point.dart` est
devenu `lib/domain/track_point.dart` et le point de trace de référence
`core/geo/track_point.dart` est devenu `core/geo/trace_point.dart`. **Les
quatre types existent toujours**, avec leurs champs et le convertisseur
explicite `domainStagesProvider` : SPEC-06 interdisait de fusionner en
déplaçant, pas de ranger. **ECR-20 tombe donc à 0**, et la liste d'identité de
`test/structurel/aucun_doublon_645_test.dart` est vidée.

---

**ARB-645-05-a — LE ROUTEUR, ET POURQUOI LA CIBLE « 0 SOCLE -> FEATURE » NE
PEUT PAS ETRE ATTEINTE PAR DU RANGEMENT (Hephaistos, 02/10/2026).** La voie A a
ete executee comme la fiche l'exige, et elle a tenu toutes ses promesses
mesurables sur les MODELES. Elle ne peut pas tenir la cible 0, et la mesure dit
pourquoi en une ligne : **51 des 72 fleches `socle -> feature` restantes sortent
d'un seul fichier**, `lib/core/routing/app_router.dart`, qui importe un ecran
par route. Ce n'est pas un modele mal range, c'est la forme meme d'un routeur
central : GoRouter demande la liste des routes en un point, et une route cite
l'ecran qu'elle monte.

Les ramener a zero demande d'INVERSER le routeur — chaque feature declare ses
routes, le socle ne connait qu'un registre — ce qui touche les 30 ecrans, les
gardes de route (`redirect`, droits premium, `FeatureFlags`), l'ordre de
declaration (dont depend la resolution des deeplinks) et
`tout_ecran_a_une_route_573_test.dart`. C'est un lot a part entiere, et il
change le DEMARRAGE de l'application : exactement ce que le smoke C10 du lot
645-05 surveille. Le faire en fin de lot, sans arbitrage, aurait ete le plus
mauvais moment.

| Ref | Ce que la mesure a montre | Ce qui est demande |
|---|---|---|
| **ARB-645-05-a** | `app_router.dart` porte **51 des 72** fleches socle -> feature (re-mesure du 03/10 sur la tete livree `a5f876b0` ; les 75 et 196 ecrits le 02/10 precedaient les derniers deplacements du lot). Les 21 autres sont diffuses : `pilote_demo.dart` (6, un pilote de demo qui conduit six providers de features), `app_bootstrap_provider.dart` (3 apres K1), `data_retention_service.dart` (2), `sync_scheduler.dart` (2), `bouton_simulation_demo.dart` (2), et 6 fichiers a une fleche | Trancher si le routeur s'inverse (registre de routes alimente par les features) ou si **le routeur est declare exception ecrite** a ECR-23 (a), avec sa justification — un routeur central EST un point de rencontre, et la regle maison ne l'avait pas prevu |
| **ARB-645-05-b** | Les **182 croisements** restants ne sont pas des modeles : **130 visent un `providers/`**, 19 un `domain/`, 15 une `presentation/`, 10 un `widgets/`, 5 un `data/`, 3 un `models/` (re-mesure du 03/10 sur la tete livree `a5f876b0`). Et parmi les 19 fleches vers un `domain/`, qui touchent 12 fichiers distincts, **aucune** n'est lue par deux features ou plus — le critere ecrit de la fiche : ce qui etait partage est justement parti dans `lib/domain/` pendant le lot, et ce qui reste est un emprunt bilateral entre deux features. Les 130 sont de l'ETAT RIVERPOD partage (`gps_providers`, `tracking_providers`, `planned_days_provider`, `auth_provider`, `download_reminder_provider`...) : deplacer un provider n'est pas un deplacement de type, c'est un recablage du graphe, et SPEC-06 interdit de changer un comportement en deplacant | Trancher le principe pour l'ETAT partage : (a) une couche `lib/application/` pour les providers que plusieurs features lisent, (b) une facade par feature (chaque feature expose un contrat, les autres ne lisent plus ses providers), ou (c) assumer que l'etat partage se lit directement et **retirer les `providers/` de la cible ECR-23 (b)**. Recommandation d'Hephaistos : **(b)**, la seule qui laisse une frontiere lisible, mais c'est un chantier par feature, pas un lot |

**ARB-645-05-c — `lib/domain/` N'EST PAS LA COUCHE LA PLUS BASSE, ET AUCUNE
GARDE NE LE MESURE (Hephaistos, 03/10/2026).** La voie A a cree `lib/domain/`
comme « la maison des modeles que plusieurs features lisent, donc la couche la
plus basse » — c'est le commentaire qui est ecrit dans `tool/audit_global.py`,
et c'est sur lui que la mesure ECR-23 repose : l'audit range `core`, `shared` et
`domain` dans UN SEUL sac appele « le socle », donc une fleche de `domain` vers
`core` ou de `core` vers `domain` ne compte NULLE PART. Les deux existent, et
elles vont dans les deux sens.

`lib/domain/` -> `lib/core/`, **3 fleches, 2 fichiers** :

| Fichier de `lib/domain/` | Importe |
|---|---|
| `lib/domain/planned_day.dart` | `lib/core/models/stage_row.dart` (le modele Drift, qui importe lui-meme `core/data/database.dart`) |
| `lib/domain/planned_day.dart` | `lib/core/models/stage_duration.dart` |
| `lib/domain/trek_stats.dart` | `lib/core/geo/geo_utils.dart` |

`lib/core/` -> `lib/domain/`, **3 fleches, 3 fichiers** :

| Fichier de `lib/core/` | Importe |
|---|---|
| `lib/core/data/daos/trek_sessions_dao.dart` | `lib/domain/trek_session.dart` |
| `lib/core/geo/track_segment_stats.dart` | `lib/domain/trek_stats.dart` |
| `lib/core/services/privacy_data_policy.dart` | `lib/domain/track_point.dart` |

CE QUE CA VEUT DIRE. `planned_day`, qui vit dans la couche censee etre la plus
basse, depend du modele Drift du socle : la dependance vers Drift n'etait pas
introduite par le lot (`planned_day` importait deja `stage_row` avant son
demenagement), mais elle est maintenant VISIBLE comme une inversion de couche,
et `trek_stats` est des deux cotes a la fois — il importe `core/geo/geo_utils`
pendant que `core/geo/track_segment_stats` l'importe. Une couche qui se lit
elle-meme a travers une autre n'est plus une couche : c'est un cycle que rien
n'empeche de grossir.

| Ref | Ce que la mesure a montre | Ce qui est demande |
|---|---|---|
| **ARB-645-05-c** | Dependance a DOUBLE SENS entre `lib/domain/` et `lib/core/` : 3 fleches dans chaque sens (listes ci-dessus), dont `planned_day.dart` -> le modele Drift `stage_row.dart`. Aucune garde ne la mesure : `mesurer_couches` range `core`, `shared` et `domain` dans le meme socle | **A trancher par Christophe** : (a) **`domain` SOUS `core`** — `core` ne lit pas `domain`, et les 3 fleches de `core` disparaissent (les types voyagent vers `domain`, ou `core` passe par une abstraction) ; ou (b) **`domain` AU-DESSUS de `core`** — `domain` a le droit de lire `core`, et ce sont les 3 fleches de `domain` qui sont legitimes, les 3 autres a retirer. Dans les deux cas : **une garde** ajoutee a `tool/audit_global.py` qui separe `domain` de `core` et compte le sens interdit, sinon le double sens reviendra sans bruit |


**CE QUE LE LOT 645-05 A LIVRÉ, ET CE QU'IL N'A PAS PU LIVRER.** La voie A a
été exécutée : `lib/domain/` existe, **douze types** ont changé de maison — dix
dans `lib/domain/` et deux dans `lib/shared/poi/` pour le vocabulaire visuel
des POI — les deux homonymes sont
résolus sans qu'un seul type soit fusionné, K1 et K2 sont corrigés. Compteurs :
**socle → feature 78 → 72**, **croisements 223 → 182**, **ECR-20 2 → 0**,
**ECR-25 1 → 0**. La cible « zéro » n'est pas atteinte, et les deux fiches
ci-dessus disent pourquoi en chiffres : ce qui reste n'est pas du rangement de
modèles, c'est un routeur central et de l'état Riverpod partagé. Les deux
demandent une décision, pas du code.


---

### 645-05 — Redresser le sens des dépendances

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-05 |
| **C2 Fichier:ligne** | **Voie A** : les 3 modèles partagés (`stage`, `track_point`, `trek_session`) + les 321 fichiers importateurs. **Voie B** : `docs/conventions.md` + les cas hors `trek`. **Dans les deux voies** : `lib/core/providers/app_bootstrap_provider.dart` (importe `features/safety/presentation/health_info_screen.dart`) et `lib/features/group/presentation/follow_web_screen.dart` (importe `cloud_firestore`) |
| **C3 Description** | **Ce lot ne commence pas par du code, il commence par une décision de Christophe** (#I208, #X60/#X61). Puis traitement selon la voie. Les deux cas isolés #X62 et #X63 sont corrigés **dans tous les cas** |
| **C4 Agent** | Athena pour l'instruction de l'arbitrage, **puis** Hephaistos pour l'exécution |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-05)* |
| **C6 Branche** | `claude/chore/645-05-couches` |
| **C7 Commit** | un commit **par zone de départ** : `refactor(645-05): <zone> respecte le sens des dependances` |
| **C8 Test** | `flutter test` → 4002 passés, aucun test modifié. `flutter analyze --no-pub` → No issues found! (`unused_import` est actif et remonterait un import orphelin) |
| **C9 QA** | Voie A : zéro import socle → feature, zéro croisement hors `lib/domain/`. Voie B : la convention réécrite décrit le réel **et** le test d'architecture vérifie la convention réécrite. Dans les deux cas : #X62 et #X63 corrigés |
| **C10 Smoke** | `flutter build appbundle --release`. Essai de démarrage à froid sur émulateur (le lot touche `app_bootstrap_provider.dart`) |
| **C11 Rollback** | `git revert <sha de la zone>`. Tag `avant-645-05`. **Jamais en un seul commit** |
| **C12 Dépendances** | **645-01**, **645-04**, et **un arbitrage de Christophe** (bloquant) |

```
PROMPT 645-05 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-05 sur claude/chore/645-05-couches depuis la
tete de origin/claude/integration/645-assainissement. git fetch d abord, cd
explicite dans chaque commande git. Ne remets JAMAIS le depot Skynet racine
sur main. Pose le tag avant-645-05 AVANT ton premier commit.

CE LOT NE DEMARRE PAS SANS UN ARBITRAGE DE CHRISTOPHE. Si l arbitrage n est
pas joint a ton mandat, tu t arretes et tu le dis.

LE CONSTAT : 321 dependances interdites dans lib/ — 78 imports de core/ ou
shared/ vers une feature, et 243 croisements entre deux features.

CE QUE DIT LA SOURCE OFFICIELLE, ET CE QU ELLE NE DIT PAS. Il faut que tu le
saches avant de toucher quoi que ce soit. docs.flutter.dev/app-architecture/
guide (consulte le 02/10/2026) ne parle que de couches TECHNIQUES — UI layer
et Data layer — et ne pose QU UNE interdiction explicite : « Repositories
should never be aware of each other ». L interdiction du croisement entre
features et l interdiction socle vers feature sont une REGLE MAISON du
depot, ecrite dans docs/conventions.md lignes 17-54. Les 321 infractions ne
sont donc PAS 321 bugs : ce sont 321 ecarts a une convention que le depot
s est donnee et qu il n a jamais outillee.

LA FORME DU PROBLEME : la feature trek est devenue un domaine partage DE
FAIT. Exemples mesures : lib/core/data/daos/trek_sessions_dao.dart depend de
features/trek/domain/models/trek_session.dart ; features/after importe CINQ
fois features/trek ; lib/core/geo/gpx_parser.dart importe
features/trek/data/gpx_parser.dart.

LES DEUX VOIES, ET CHRISTOPHE TRANCHE :
  VOIE A : creer lib/domain/ pour les modeles partages (stage, track_point,
    trek_session) et y deplacer ce que plusieurs features lisent. Cout : un
    deplacement large, beaucoup d imports reecrits. Gain : la convention
    redevient vraie, et le reste du plan tient.
  VOIE B : assumer trek comme socle et REECRIRE la convention en
    consequence. Cout : presque aucun code touche. Gain : la convention
    decrit enfin le reel, mais trek reste un fourre-tout.
En voie B, tu modifies docs/conventions.md ET le test
test/structurel/couches_respectees_645_test.dart pour qu il verifie la
convention REECRITE — pas pour qu il se taise.

DEUX CAS A CORRIGER DANS LES DEUX VOIES, independamment de l arbitrage :
  K1 lib/core/providers/app_bootstrap_provider.dart importe
     features/safety/presentation/health_info_screen.dart. LE SOCLE IMPORTE
     UN ECRAN. Indefendable dans les deux voies. Corrige par INVERSION :
     l ecran s enregistre aupres de l amorcage, l amorcage ne connait pas
     l ecran.
  K2 lib/features/group/presentation/follow_web_screen.dart importe
     package:cloud_firestore/cloud_firestore.dart depuis la couche
     presentation. Unique infraction ECR-25 du depot. Meme fichier que le
     point 19 de l inventaire 593 (memoire #100656), qui le signalait deja
     comme acces Firestore SANS GARDE isAvailable : traite les deux.

INTERDICTION FORMELLE : ne fusionne AUCUN type en le deplacant. Un
deplacement de fichier et une reecriture d import ne changent aucun
comportement SI ET SEULEMENT SI le type deplace est identique. La fusion de
stage et track_point est le travail du lot 645-04, qui passe AVANT. Si tu
constates que 645-04 n a pas ete fait, tu t arretes.

DECOUPAGE : un commit par ZONE DE DEPART — core/, puis shared/, puis UNE
feature a la fois. JAMAIS en un seul commit. Message :
refactor(645-05): <zone> respecte le sens des dependances

ABAISSE LE PLAFOND de test/structurel/couches_respectees_645_test.dart apres
chaque zone, avec la date. Le plafond ne remonte JAMAIS.

GATE COMPLETE AVANT DE LIVRER, les 4 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub   -> attendu : No issues found! Le lint
                                unused_import est actif : il remonterait un
                                import devenu orphelin.
  flutter test               -> attendu : 4002 passes, 2 ignores
  flutter build appbundle --release -> DOIT REUSSIR
EN PLUS : un essai de demarrage A FROID sur l emulateur, parce que le lot
touche app_bootstrap_provider.dart.

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : la voie appliquee, les compteurs avant/apres par zone, le
traitement de K1 et K2, le resultat des 4 commandes de gate et de l essai a
froid.
```

---

### 645-06 — Découper les fichiers et les `build()` hors plafond

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-06 |
| **C2 Fichier:ligne** | **Vague 1** (`build()`) : `hub_screen.dart:88` (679 l.), `nuitees_screen.dart:446` (382), `map_screen.dart:350` (361), `health_info_screen.dart:622` (310), `checklist_item_widget.dart:80` (240). **Vague 2** (fichiers) : `trek_feasibility_screen.dart` (2028), `health_info_screen.dart` (1764), `feasibility_formula.dart` (1644), `monetization_service.dart` (1490), `map_screen.dart` (1232). **Vague 3** : `gpx_import_service.dart:259` (complexité 25) + 19 autres. **Vague 4** : les 40 fichiers restants |
| **C3 Description** | Découper en **sous-widgets nommés**, pas en méthodes privées `_buildXxx` — raison citée par ECR-28 : un sous-widget est reconstruit indépendamment, une méthode privée non. L'état reste chez le parent, les sous-widgets reçoivent leurs données en paramètres nommés |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-06)* |
| **C6 Branche** | `claude/chore/645-06-decoupage`, **une branche par vague** si le lot est étalé |
| **C7 Commit** | un commit **par fichier découpé** : `refactor(645-06): decouper <fichier> en sous-widgets` |
| **C8 Test** | `flutter test` → 4002 passés. Les tests de widget vérifient l'arbre rendu : un découpage qui change l'arbre les fait échouer |
| **C9 QA** | Aucun `_buildXxx` introduit. Captures avant / après des 5 écrans de la vague 1. Les compteurs #I47 et #I48 baissent |
| **C10 Smoke** | `integration_test/persona_*` sur les 5 écrans de la vague 1 |
| **C11 Rollback** | `git revert <sha du fichier>`. Tag `avant-645-06-vague<N>` par vague. **Lot explicitement sécable** : il peut s'arrêter après n'importe quelle vague |
| **C12 Dépendances** | **645-01**, **645-03** (découper une `build()` qui contient 16 boutons bruts, c'est le faire deux fois) |

```
PROMPT 645-06 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-06 sur claude/chore/645-06-decoupage depuis
la tete de origin/claude/integration/645-assainissement. git fetch d abord,
cd explicite dans chaque commande git. Ne remets JAMAIS le depot Skynet
racine sur main. Pose le tag avant-645-06-vague<N> AVANT la vague.

OBJET : ramener 50 fichiers sous 500 lignes et 206 fonctions sous 60 lignes.

LE CONSTAT : neuf des dix fonctions les plus longues du depot sont des
build(), dont une de 679 LIGNES (lib/features/hub/presentation/
hub_screen.dart:88). Le plus gros fichier fait 2028 lignes
(lib/features/feasibility/presentation/trek_feasibility_screen.dart). Et
c est en aggravation : 31 fichiers hors plafond le 21/09, 50 le 02/10.

METHODE IMPOSEE, ET CE N EST PAS UN DETAIL. Une build() trop longue se
decoupe en SOUS-WIDGETS NOMMES, PAS en methodes privees _buildXxx. Raison
citee par la regle ECR-28 : un sous-widget est reconstruit independamment,
une methode privee non. Un decoupage en _buildHeader(), _buildStats() est
REFUSE : il reduit le chiffre sans ameliorer le code.

FORME ATTENDUE :
  Widget build(BuildContext context) => Column(children: [
        _TrekHeader(trek: trek),
        _TrekStats(trek: trek),
        _TrekActions(onStart: _start),
      ]);
avec trois widgets nommes, chacun recevant ses donnees en PARAMETRES NOMMES.

PIEGE PRINCIPAL — L ETAT. Extraire un StatefulWidget d une build() qui
lisait l etat du parent CHANGE le cycle de vie. Regle : L ETAT RESTE CHEZ LE
PARENT. Les sous-widgets sont des StatelessWidget qui recoivent leurs
donnees. Si tu ne peux pas, laisse le fichier et rapporte-le.

LES QUATRE VAGUES, dans cet ordre :

VAGUE 1 — les 5 pires build() :
  679 l. lib/features/hub/presentation/hub_screen.dart:88
  382 l. lib/features/booking/presentation/nuitees_screen.dart:446
  361 l. lib/features/trek/presentation/map/map_screen.dart:350
  310 l. lib/features/safety/presentation/health_info_screen.dart:622
  240 l. lib/features/checklist/widgets/checklist_item_widget.dart:80

VAGUE 2 — les 5 pires fichiers :
  2028 l. lib/features/feasibility/presentation/trek_feasibility_screen.dart
  1764 l. lib/features/safety/presentation/health_info_screen.dart
  1644 l. lib/features/feasibility/domain/feasibility_formula.dart
  1490 l. lib/core/services/monetization_service.dart
  1232 l. lib/features/trek/presentation/map/map_screen.dart

VAGUE 3 — les 20 fonctions de complexite superieure a 10, en tete :
  complexite 25 lib/features/after/data/gpx_import_service.dart:259
                importGpxFile
  complexite 15 lib/core/services/delta_update_service.dart:677 _supprimer
  complexite 14 lib/core/data/revision_de_donnee.dart:155
                annonceParLeServeur
  Liste complete : python tool/audit_global.py --section complexite --json

VAGUE 4 — les 40 fichiers restants au-dela de 500 lignes.

CE LOT EST SECABLE. Il peut s arreter apres N IMPORTE QUELLE vague sans
laisser le depot dans un etat intermediaire. Si ton mandat ne nomme qu une
vague, tu ne fais que celle-la.

COMPORTEMENT AVANT = APRES. Aucune correction d apparence, aucune
simplification de logique au passage. C est un decoupage, pas une reecriture.

DECOUPAGE : un commit PAR FICHIER. Message :
refactor(645-06): decouper <chemin du fichier> en sous-widgets

ABAISSE LE PLAFOND ECR-15 de
test/structurel/taille_et_rangement_645_test.dart apres chaque vague.

GATE COMPLETE AVANT DE LIVRER, les 4 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub          -> attendu : No issues found!
  flutter test                      -> attendu : 4002 passes, 2 ignores. Les
                                       tests de widget verifient l arbre
                                       rendu : un decoupage qui change
                                       l arbre les fait echouer. C est le
                                       filet voulu.
  flutter build appbundle --release -> DOIT REUSSIR

CAPTURES OBLIGATOIRES pour la vague 1 : avant et apres, sur les 5 ecrans,
via integration_test/persona_*. Skynet les compare avant de montrer a
Christophe.

VERIFICATION ANTI-TRICHE A RAPPORTER : grep -rn "_build[A-Z]" sur les
fichiers que tu as touches. Si tu en as introduit un, tu n as pas applique
la methode.

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : vague traitee, fichiers decoupes, lignes avant/apres par
fichier, resultat du grep anti-triche, resultat des 4 commandes de gate, ou
sont les captures.
```

---

### 645-07 — Passer les identifiants en anglais

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-07 |
| **C2 Fichier:ligne** | 197 fichiers sur 599, 442 identifiants, 31 noms de fichier. **Étape 1** : les 31 noms de fichier (`sentier_distant.dart`, `trace_du_sentier.dart`, `descente_des_cartes.dart`, `fiche_technique_du_telephone.dart`, `source_de_donnees_sentier.dart`, `source_firestore_sentier.dart`, `etat_publicite.dart`, `badge_etat_publicite.dart`, `profil_randonneur_fichier.dart`, `cartes_hors_ligne_screen.dart`, `variante_etape.dart`, `copie_sauvegardable_fiche_service.dart`, `fiche_medicale_fichier.dart`, `prise_photo_carte.dart`, `porte_consentement_sauvegarde.dart`, `etat_du_sentier.dart`, + 15). **Étape 2** : `lib/core/services` (92). **Étape 3** : `lib/core/branding` (21). **Étape 4** : les features |
| **C3 Description** | Renommer les identifiants en anglais. **Les commentaires et doc comments restent en français accentué** — ce lot ne touche pas une ligne de commentaire |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-07)* |
| **C6 Branche** | `claude/chore/645-07-code-en-anglais` |
| **C7 Commit** | un commit **par étape** : `refactor(645-07): etape <N>, identifiants en anglais dans <zone>` |
| **C8 Test** | `flutter test` → 4002 passés. `dart run build_runner build --delete-conflicting-outputs` puis `git diff` sur les générés : **seuls les noms de symbole changent**, aucun nom de champ sérialisé |
| **C9 QA** | Le diff des `.g.dart` et `.freezed.dart` ne montre aucun changement de nom sérialisé. Une base Drift écrite **avant** le lot se relit après. Aucune ligne de commentaire modifiée |
| **C10 Smoke** | Test de migration Drift : ouvrir une base écrite avant le lot. Essai sur émulateur : les préférences enregistrées avant sont relues après |
| **C11 Rollback** | `git revert <sha de l'étape>` — 4 commits. Tag `avant-645-07` avant l'étape 1 |
| **C12 Dépendances** | **645-01**, **645-04**, **645-05** (renommer avant d'avoir résorbé les doublons et stabilisé les emplacements, c'est renommer deux fois) |

```
PROMPT 645-07 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-07 sur claude/chore/645-07-code-en-anglais
depuis la tete de origin/claude/integration/645-assainissement. git fetch
d abord, cd explicite dans chaque commande git. Ne remets JAMAIS le depot
Skynet racine sur main. Pose le tag avant-645-07 AVANT l etape 1.

OBJET : renommer 442 identifiants francais en anglais, et 31 noms de
fichier. Decision IDE-001 de Christophe : le code est en anglais.

LA REGLE A DEUX MOITIES, NE FAIS QUE LA PREMIERE :
  - les IDENTIFIANTS passent en anglais ;
  - les COMMENTAIRES et DOC COMMENTS RESTENT EN FRANCAIS ACCENTUE.
Ce lot ne touche PAS UNE LIGNE DE COMMENTAIRE. Si ton diff montre un
commentaire modifie, tu es sorti du perimetre.

OBTIENS LA LISTE :
  python tool/audit_global.py --section langue --json
Sections langue.par_dossier, langue.noms_de_fichier_francais et
langue.echantillon.

QUATRE ETAPES, UN COMMIT CHACUNE, dans cet ordre :
  ETAPE 1 — les 31 NOMS DE FICHIER. Les plus visibles et les plus faciles.
    Exemples : lib/core/config/sentier_distant.dart,
    lib/core/geo/trace_du_sentier.dart,
    lib/core/services/descente_des_cartes.dart,
    lib/core/services/fiche_technique_du_telephone.dart,
    lib/features/planning/models/variante_etape.dart,
    lib/features/safety/data/fiche_medicale_fichier.dart.
    Utilise git mv, et reecris tous les imports.
  ETAPE 2 — lib/core/services : 92 identifiants.
  ETAPE 3 — lib/core/branding : 21 identifiants (cremeSentier,
    orangeSentier, vertSentier, catalogueSentiers, deconnexion, diplome,
    duree, enregistrer, meteo, monCompte, poids...).
  ETAPE 4 — les features, par ordre decroissant : safety (45), trail (33),
    feasibility (27), trek (27), map (26), planning (23), booking (18),
    hub (18), puis le reste.

QUATRE PIEGES MESURES DANS CE DEPOT. Un renommage pur est sans effet SAUF
dans ces quatre cas. Verifie-les AVANT chaque renommage :
  P1 SERIALISATION. Un nom de classe ou de champ serialise par
     json_serializable ou freezed apparait dans le JSON PRODUIT. Apres
     renommage : dart run build_runner build --delete-conflicting-outputs,
     puis git diff sur les .g.dart et .freezed.dart. Si un NOM DE CHAMP
     SERIALISE change, fige-le par @JsonKey(name: 'ancien_nom'). Le JSON
     produit doit rester IDENTIQUE.
  P2 DRIFT. Un nom utilise comme cle Drift ou nom de colonne touche le
     SCHEMA DE BASE. NE RENOMME PAS LA COLONNE. Renomme seulement le
     symbole Dart.
  P3 CHAINES. Un nom cite en chaine de caracteres — cle de preference, nom
     de route, cle d analytics. Cherche 'LeNom' et "LeNom" AVANT de
     renommer. UNE CLE STOCKEE SUR LE TELEPHONE DU RANDONNEUR NE SE RENOMME
     PAS : le randonneur perdrait son reglage.
  P4 I18N. Les cles i18n de Slang sont HORS PERIMETRE de ce lot.

ABAISSE LE COMPTEUR : apres chaque etape, relance
python tool/audit_global.py --section langue et inscris le nouveau chiffre.

GATE COMPLETE A CHAQUE ETAPE, les 5 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub          -> attendu : No issues found!
  flutter test                      -> attendu : 4002 passes, 2 ignores
  flutter build appbundle --release -> DOIT REUSSIR
  dart run build_runner build --delete-conflicting-outputs, puis
    git diff sur les generes -> AUCUN nom de champ serialise modifie

TEST DE MIGRATION OBLIGATOIRE : ouvre une base Drift ecrite AVANT le lot et
verifie qu elle se lit apres. Si tu n en as pas, cree-la sur l emulateur
avant de commencer l etape 2.

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : etape traitee, compteur avant/apres, les cas P1 a P4
rencontres et comment tu les as gardes, le diff des generes, le resultat du
test de migration, le resultat des 5 commandes de gate.
```

---

### 645-08 — Supprimer les valeurs à compléter

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-08 |
| **C2 Fichier:ligne** | `lib/features/guides/domain/town_guide_catalog.dart:66, 77, 118` ; `lib/features/booking/providers/hebergement_peripherique_providers.dart:66, 75, 84` ; `lib/features/planning/domain/shop_catalog.dart` — 39 occurrences dont `:122, 140, 154, 170, 204, 220, 238, 247` |
| **C3 Description** | **Ce lot ne démarre pas sans une décision produit de Christophe** : renseigner les vraies valeurs (#X91), masquer proprement (#X92), ou retirer la fonctionnalité (#X93). Puis application |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-08)* |
| **C6 Branche** | `claude/chore/645-08-valeurs-a-completer` |
| **C7 Commit** | un commit **par fichier** : `fix(645-08): <fichier> ne montre plus de valeur a completer` |
| **C8 Test** | `test/structurel/aucune_valeur_a_completer_645_test.dart` → plafond de 45 à 0. `flutter test` → 4002 passés ; **les tests d'affichage de ces écrans sont mis à jour volontairement — c'est la seule exception du plan à la règle « aucun test réécrit »** |
| **C9 QA** | Zéro `example.org` et zéro « a completer » hors commentaire dans `lib/`. L'écran ne montre jamais de ligne vide à la place |
| **C10 Smoke** | Essai manuel sur émulateur des 3 écrans concernés : aucun texte creux visible |
| **C11 Rollback** | `git revert <sha du fichier>` — 3 commits. Tag `avant-645-08` |
| **C12 Dépendances** | **645-01**, et **une décision produit de Christophe** (bloquante) |

```
PROMPT 645-08 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-08 sur
claude/chore/645-08-valeurs-a-completer depuis la tete de
origin/claude/integration/645-assainissement. git fetch d abord, cd explicite
dans chaque commande git. Ne remets JAMAIS le depot Skynet racine sur main.
Pose le tag avant-645-08 AVANT ton premier commit.

CE LOT NE DEMARRE PAS SANS LA DECISION PRODUIT DE CHRISTOPHE. Si elle n est
pas jointe a ton mandat, tu t arretes et tu le dis.

LE CONSTAT : 45 valeurs a completer sont LIVREES AU RANDONNEUR dans le code
de production — 6 example.org et 39 « a completer ». C est exactement le
point 22 de l inventaire 593 du 26/09 (memoire #100656) : « hebergements et
guides de ville = donnees inventees ». Six jours plus tard, c est toujours la.

LES TROIS FICHIERS :
  lib/features/guides/domain/town_guide_catalog.dart lignes 66, 77, 118
    deeplinkUrl: 'https://example.org/epicerie', '/gite', '/supermarche'
  lib/features/booking/providers/hebergement_peripherique_providers.dart
    lignes 66, 75, 84 : deeplinkUrl: 'https://example.org/...'
  lib/features/planning/domain/shop_catalog.dart : 39 occurrences de
    openingHours: 'a completer' et variantes, dont lignes 122, 140, 154,
    170, 204, 220, 238, 247

LES TROIS VOIES — APPLIQUE CELLE QUE CHRISTOPHE A CHOISIE :
  V1 RENSEIGNER les vraies valeurs. Demande une collecte de donnees terrain,
     hors code : si c est la voie, ton mandat porte les donnees.
  V2 MASQUER proprement : le champ absent n affiche RIEN, au lieu d afficher
     un texte creux. C est la voie la plus sure. PRECEDENT DANS LE DEPOT :
     c est exactement ce qui a ete fait pour les goodies le 25/09 (tache
     552), qui ne promettent plus rien.
  V3 RETIRER la fonctionnalite jusqu a ce que les donnees existent. C est ce
     que Christophe a fait lui-meme pour le guide des villes, qu il a masque
     (hub_screen.dart lignes 618-631).

EN VOIE V2, LA REGLE EST STRICTE : le champ absent n affiche RIEN. Pas de
tiret, pas de « non renseigne », pas d espace reserve. La ligne disparait.

EXCEPTION ASSUMEE, ET C EST LA SEULE DU PLAN : ici, tu PEUX modifier les
tests d affichage de ces ecrans, parce que le comportement change
VOLONTAIREMENT — afficher example.org a un randonneur est un defaut, pas un
comportement a preserver. Nomme chaque test modifie dans ton rapport.

NOTE UTILE : le depot a aujourd hui DEUX honnetetes differentes pour le meme
probleme. Les goodies ne promettent plus rien (propre). booking promet
encore « Disponibilites bientot disponibles ». La voie V2 aligne tout le
depot sur la consigne deja donnee par Christophe le 25/09.

DECOUPAGE : un commit PAR FICHIER. 3 commits. Message :
fix(645-08): <chemin du fichier> ne montre plus de valeur a completer

ABAISSE LE PLAFOND de
test/structurel/aucune_valeur_a_completer_645_test.dart de 45 a 0.

GATE COMPLETE AVANT DE LIVRER, les 4 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub          -> attendu : No issues found!
  flutter test                      -> 4002 passes (moins les tests
                                       volontairement modifies, nommes)
  flutter build appbundle --release -> DOIT REUSSIR

ESSAI MANUEL OBLIGATOIRE sur emulateur : ouvre les 3 ecrans concernes et
verifie qu AUCUN texte creux n est visible. Capture-les.

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : la voie appliquee, les 45 occurrences traitees, les tests
volontairement modifies NOMMES UN PAR UN, le resultat des 4 commandes de
gate, et ou sont les captures.
```

---

### 645-09 — Poser l'observabilité sur les 54 écrans nus

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-09 |
| **C2 Fichier:ligne** | `lib/core/analytics/analytics_service.dart` (point central) + les 54 écrans sans miette. Les 9 déjà équipés sont la référence de forme : `gpx_import_screen.dart`, `profile_screen.dart`, `checklist_screen.dart`, `consent_settings_screen.dart`, `journal_screen.dart`, `cartes_hors_ligne_screen.dart`, `onboarding_screen.dart`, `trail_planning_screen.dart`, `health_info_screen.dart` |
| **C3 Description** | Poser l'instrumentation par **un seul** service, pas par 54 appels dispersés. Convention : **3 clés** (`screen`, `trail`, `stage`) dont la valeur change, pas 63 clés. Une miette courte `screen:<nom>` à l'entrée de chaque écran |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-09)* |
| **C6 Branche** | `claude/chore/645-09-observabilite` |
| **C7 Commit** | un commit pour le service, puis un commit **par groupe de 10 écrans** : `feat(645-09): miettes d observabilite, groupe <N>` |
| **C8 Test** | `flutter test` → 4002 passés. **Deux tests nouveaux** : (a) avec un service d'observabilité en échec, chaque écran s'affiche quand même ; (b) le nombre de **clés distinctes** posées par l'application est **≤ 64** |
| **C9 QA** | Un seul point d'entrée. Instrumentation **inerte** quand Firebase est indisponible — ce qui est le cas 100 % du temps aujourd'hui (`analytics_service.dart:209-213` rend `disabled()`). Aucun écran ne ralentit |
| **C10 Smoke** | Démarrage à froid sur émulateur, Firebase indisponible : aucun écran ne ralentit ni n'échoue |
| **C11 Rollback** | `git revert <sha>`. Tag `avant-645-09` |
| **C12 Dépendances** | **645-01**, **645-06** (instrumenter une `build()` de 679 lignes puis la découper, c'est déplacer l'instrumentation) |

```
PROMPT 645-09 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-09 sur claude/chore/645-09-observabilite
depuis la tete de origin/claude/integration/645-assainissement. git fetch
d abord, cd explicite dans chaque commande git. Ne remets JAMAIS le depot
Skynet racine sur main. Pose le tag avant-645-09 AVANT ton premier commit.

OBJET : poser une miette d observabilite sur les 54 ecrans qui n en ont
aucune. Aujourd hui : 9 ecrans sur 63, soit 14,3 pct.

POURQUOI CA COMPTE : point 18 de l inventaire 593 (memoire #100656), verbatim
« aucun rapport de plantage ni statistique, a 100 pct » et « vendre une appli
sans savoir qu elle plante est un pari ».

LES LIMITES OFFICIELLES DE CRASHLYTICS, CHIFFREES, ET ELLES COMMANDENT LA
CONCEPTION. Source firebase.google.com/docs/crashlytics/flutter/
customize-crash-reports, consultee le 02/10/2026 :
  - « Crashlytics supports a maximum of 64 key-value pairs. After you reach
    this threshold, additional values are not saved. Each key-value pair can
    be up to 1 kB in size. »
  - « Crashlytics limits logs to 64kB and deletes older log entries when
    logs for a session go over that limit. »
  - « Crashlytics only stores the most recent eight recorded non-fatal
    exceptions. »

CONSEQUENCE DIRECTE : AVEC 63 ECRANS ET 64 CLES, « UNE CLE PAR ECRAN » EST
IMPOSSIBLE. Au-dela de 64, les valeurs ne sont plus enregistrees — en
silence.

CONVENTION A APPLIQUER (validee par Christophe) : TROIS CLES AU TOTAL, dont
la VALEUR change :
  screen -> le nom de l ecran courant
  trail  -> le sentier actif
  stage  -> l etape en cours
Plus UNE MIETTE log() a l entree de chaque ecran, au format COURT :
  screen:<nom>
Budget : 3 cles sur 64, et au pire 63 miettes courtes par session, tres en
dessous des 64 ko.

API EXACTE :
  FirebaseCrashlytics.instance.setCustomKey('screen', nom);
  FirebaseCrashlytics.instance.log('screen:$nom');
  await FirebaseCrashlytics.instance.recordError(e, s, reason: '...');

UN SEUL POINT D ENTREE, PAS 54. L instrumentation passe par UN service, pas
par 54 appels disperses a FirebaseCrashlytics.instance. Le depot a deja
lib/core/analytics/analytics_service.dart : c est la que ca se branche.
Prends modele sur les 9 ecrans deja equipes, en tete
lib/features/checklist/presentation/checklist_screen.dart et
lib/features/safety/presentation/health_info_screen.dart.

GARDE OBLIGATOIRE — L INERTIE. L instrumentation doit etre INERTE quand
Firebase est indisponible, ce qui est le cas 100 pct du temps aujourd hui :
analytics_service.dart lignes 209-213 rend disabled(). UN ECRAN NE DOIT
JAMAIS ralentir, bloquer ni echouer parce qu une miette n a pas pu partir.
Aucun await bloquant dans une build().

DEUX TESTS NOUVEAUX A ECRIRE :
  T1 avec un service d observabilite en ECHEC, chaque ecran s affiche quand
     meme ;
  T2 le nombre de CLES DISTINCTES posees par l application est INFERIEUR OU
     EGAL A 64. C est la limite officielle, et elle merite son test.

DECOUPAGE : un commit pour le service central, puis un commit par groupe de
10 ecrans. Message : feat(645-09): miettes d observabilite, groupe <N>

GATE COMPLETE AVANT DE LIVRER, les 4 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub          -> attendu : No issues found!
  flutter test                      -> 4002 passes + T1 et T2
  flutter build appbundle --release -> DOIT REUSSIR
EN PLUS : demarrage A FROID sur emulateur, Firebase indisponible. Aucun
ecran ne ralentit ni n echoue.

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : ecrans instrumentes, nombre de cles distinctes posees,
resultat de T1 et T2, resultat des 4 commandes de gate et du demarrage a
froid.
```

---

### 645-10 — Monter les dépendances résolubles

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-10 |
| **C2 Fichier:ligne** | `pubspec.yaml`, `pubspec.lock`, + code d'adaptation. Paquets visés à l'écriture de la fiche : `cloud_firestore` 5.6.12 → 6.10.0 ; `connectivity_plus` 5.0.2 → 7.3.1 ; `battery_plus` 6.2.3 → 7.1.2 ; `carp_serializable` 2.0.1 → 3.0.0. **Réellement montés : `battery_plus` 6.2.3 → 7.1.2 (+ `android/settings.gradle.kts`, greffon Android 8.11.1 → 8.12.1) et `connectivity_plus` 5.0.2 → 7.3.1 (+ 3 sites d'appel et 1 faux de test)** — voir la correction du 03/10 ci-dessous |
| **C3 Description** | Monter **seulement** les paquets qu'on peut monter **seuls**. ~~Monter seulement les paquets dont la version résoluble est déjà la dernière.~~ **Ce critère est faux** : la colonne « résoluble » de `flutter pub outdated` relâche **toutes** les contraintes directes à la fois, elle ne dit donc rien de la montée d'un paquet isolé. Le critère valable est : **`pub get` passe en ne touchant que ce paquet**. Les paquets bloqués par une contrainte (`cached_network_image`, `analyzer`) sont **hors de ce lot** |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-10)* |
| **C6 Branche** | `claude/chore/645-10-dependances` |
| **C7 Commit** | un commit **par paquet** : `chore(645-10): monter <paquet> de <X> a <Y>` |
| **C8 Test** | `flutter test` → 4002 passés. `flutter build appbundle --release` → réussit |
| **C9 QA** | **Un essai sur émulateur par paquet**, du parcours qu'il touche. Pas de montée « à l'aveugle parce que les tests passent » |
| **C10 Smoke** | Hors ligne pour `connectivity_plus` ; lecture/écriture distante pour `cloud_firestore` ; économie de batterie pour `battery_plus` |
| **C11 Rollback** | `git revert <sha du paquet>` — **obligatoirement un paquet par commit**, pour isoler une régression. Tag `avant-645-10` |
| **C12 Dépendances** | **645-01**. Indépendant du reste : peut passer à tout moment après 645-01 |

#### Correction du 03/10/2026 — faits établis par la fabrication (session cloud) et la QA locale (tâche 662, Artemis)

1. **Le critère de sélection de la fiche était faux.** « Colonne *résoluble* = *dernière* » dans `flutter pub outdated` est calculé en relâchant **toutes** les contraintes directes **en même temps** : il ne prouve donc pas qu'un paquet est montable **seul**. Le critère valable, et le seul vérifiable, est : **`pub get` passe en ne touchant que ce paquet**. Vérifié sur un `pubspec.yaml` jetable, le 03/10 : `health` est donné « résoluble 13.3.2 » et **échoue seul** (`share_plus` 10.1.4 exige `win32 ^5.5.3`, `device_info_plus` 13 exige `win32 ^6.0.1`) ; `cloud_firestore` est donné « résoluble 6.10.0 » et **échoue seul** (`firebase_analytics` 11 exige `firebase_core_platform_interface ^6`, `cloud_firestore` 6.9+ exige `^8.1.1`).
2. **`cloud_firestore` est SORTI du lot.** Monter 6.10.0 entraîne une cascade Firebase : `firebase_core` 3 → 4, `firebase_auth`, `firebase_storage`, `firebase_analytics`, `firebase_crashlytics` 4 → 5, soit **6 majeures directes et 21 dépendances changées** — impossible à isoler paquet par paquet, donc contraire au C7 (un commit par paquet) et au C11 (revert d'un seul paquet). Reste à **5.6.12**. À instruire comme un lot à part.
3. **`carp_serializable` est SORTI du lot.** Il est **transitif** (porté par `health` seul, **zéro site d'appel** dans `lib/`), et `health` 13.3.2 est bloqué par `share_plus` 10.1.4 (voir point 1). Reste à **2.0.1**.
4. **`battery_plus` 7 n'est pas une montée Dart, c'est une montée de build Android.** Entre 6.2.3 et 7.1.2, la source Android du greffon est **identique octet pour octet** et la seule différence Dart touche l'implémentation **Linux** : le changement cassant est le plancher de build (greffon Android ≥ **8.12.1**, Gradle ≥ 8.13, Kotlin 2.2.0), d'où `android/settings.gradle.kts` 8.11.1 → 8.12.1. Planchers de plateforme relevés au passage : iOS 12.0 → **13.0**, macOS 10.14 → **10.15** (le dépôt est à 13.0 et 10.15, donc juste au plancher).
5. **`connectivity_plus` 7 rend une LISTE de liens** (`List<ConnectivityResult>`) là où la 5 rendait une valeur, et connaît le lien **satellite**. Sur Android ≥ 6, le greffon ne liste que les **transports du réseau actif** (`getActiveNetwork()`), pas tous les réseaux montés : mesuré le 03/10 sur émulateur, wifi **et** cellulaire validés en même temps rendent `[wifi]`, pas `[wifi, mobile]`. La liste à plusieurs entrées est donc le cas VPN-au-dessus-d'un-lien, que l'ancienne API rendait déjà en `vpn` — même verdict `TypesDeLien.autre` avant et après.
6. **C9/C10 — l'essai émulateur par paquet reste la règle, mais la fiche surestimait ce qu'il peut atteindre.** Le garde de lien (`DescenteDesCartes.examiner`) est **inatteignable par l'interface** tant que le circuit n'est pas acheté (le refus « fait partie du circuit acheté » et le refus « pas pendant la démonstration » passent avant le test du lien). Un essai de bout en bout de ce garde suppose donc un achat réel ; à défaut, il se vérifie par sonde du greffon réel + tests unitaires du garde.
7. **`battery_plus` n'a aucun consommateur de production.** `batteryAwareLocationControllerProvider` n'est lu par **aucun** fichier de `lib/` (seulement par son test) : aucun écran ne réagit au niveau de batterie aujourd'hui. Constat **antérieur** au lot, qui ne le crée pas — mais il rend l'essai « économie de batterie » du C10 sans objet tant que le contrôleur n'est pas branché.

```
PROMPT 645-10 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-10 sur claude/chore/645-10-dependances depuis
la tete de origin/claude/integration/645-assainissement. git fetch d abord,
cd explicite dans chaque commande git. Ne remets JAMAIS le depot Skynet
racine sur main. Pose le tag avant-645-10 AVANT ton premier commit.

OBJET : monter les paquets dont la version RESOLUBLE est deja la derniere.

ETAT MESURE LE 02/10/2026 : 188 paquets obsoletes, dont 72 en saut de
version MAJEURE. Mais tous ne sont pas montables.

LES 4 PAQUETS DE CE LOT — colonne « resoluble » deja egale a « dernier » :
  cloud_firestore     5.6.12 -> 6.10.0
  connectivity_plus   5.0.2  -> 7.3.1
  battery_plus        6.2.3  -> 7.1.2
  carp_serializable   2.0.1  -> 3.0.0

[CORRECTION DU 03/10/2026 — ce bloc de prompt est conserve tel qu il a ete
 donne, mais DEUX de ces quatre paquets ne sont pas montables seuls et sont
 sortis du lot (cloud_firestore : cascade Firebase de 6 majeures directes ;
 carp_serializable : transitif, bloque par share_plus). Le critere « colonne
 resoluble = derniere » est faux : il relache toutes les contraintes a la
 fois. Lire la section « Correction du 03/10/2026 » juste au-dessus du bloc
 avant de rejouer ce prompt.]

HORS DE CE LOT — le resoluble reste l actuel, une contrainte amont les
bloque. NE LES TOUCHE PAS :
  cached_network_image 3.4.1 (dernier 4.0.4)
  analyzer             10.0.1 (dernier 14.4.0)
Lever leur contrainte est un autre lot, a instruire a part.

C EST LE SEUL LOT DU PLAN OU LA GATE NE SUFFIT PAS, et il faut que tu le
saches. Une montee majeure peut changer un comportement sans qu on le
veuille, et aucun test ne garantit l absence de regression sur un
comportement qui n etait pas teste. cloud_firestore 5 vers 6 touche la
couche reseau. connectivity_plus 5 vers 7 touche la detection hors ligne,
qui est LE COEUR DE STEPWAYS.

GARDE SUPPLEMENTAIRE OBLIGATOIRE : chaque paquet monte demande un ESSAI SUR
EMULATEUR du parcours qu il touche, EN PLUS de la gate :
  connectivity_plus -> coupe le reseau, verifie que l appli passe hors ligne
                       proprement et revient en ligne
  cloud_firestore   -> une lecture et une ecriture distante
  battery_plus      -> le mode economie de batterie
  carp_serializable -> la serialisation qu il porte, lue et reecrite
PAS DE MONTEE A L AVEUGLE PARCE QUE LES TESTS PASSENT.

DECOUPAGE : UN COMMIT PAR PAQUET. C est obligatoire ici, pas recommande :
une regression doit pouvoir etre isolee a UN SEUL paquet. Message :
chore(645-10): monter <paquet> de <X> a <Y>

ORDRE : commence par carp_serializable (le moins risque), puis
battery_plus, puis connectivity_plus, puis cloud_firestore (le plus
risque). Si un paquet casse quelque chose que tu ne sais pas reparer, tu
t arretes a ce paquet, tu reverts celui-la seul, et tu rapportes.

GATE COMPLETE A CHAQUE PAQUET, les 4 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub          -> attendu : No issues found!
  flutter test                      -> attendu : 4002 passes, 2 ignores
  flutter build appbundle --release -> DOIT REUSSIR
Plus l essai emulateur du parcours touche.

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : paquets montes avec versions avant/apres, le code
d adaptation qu il a fallu ecrire, le resultat de CHAQUE essai emulateur, le
nouveau compteur flutter pub outdated, le resultat des 4 commandes de gate.
```

---

### 645-11 — En-têtes de fichier et couleurs au thème

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-11 |
| **C2 Fichier:ligne** | 479 fichiers sans en-tête. Couleurs : `lib/features/checklist/widgets/checklist_weight_banner.dart:40, 58, 450, 459` ; `lib/features/community/domain/waypoint_type_config.dart:38, 43, 48, 53` ; + 32 autres |
| **C3 Description** | Poser un en-tête `///` de 1 à 3 lignes à chaque fichier source. Porter les 40 couleurs en dur dans `core/theme/`, **en gardant exactement la même valeur hexadécimale** |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-11)* |
| **C6 Branche** | `claude/chore/645-11-entetes-et-couleurs` |
| **C7 Commit** | un commit **par dossier** pour les en-têtes, un commit pour les couleurs |
| **C8 Test** | `flutter test` → 4002 passés. `python tool/audit_global.py --section documentation` → #I108 monte vers 100 % |
| **C9 QA** | **La couleur affichée est identique au pixel.** Aucune harmonisation de teinte. Aucun en-tête qui paraphrase le nom du fichier |
| **C10 Smoke** | Captures avant / après sur les écrans dont une couleur a bougé de place |
| **C11 Rollback** | `git revert <sha>`. Tag `avant-645-11`. **Variable d'ajustement du plan** : sécable à volonté, aucun état intermédiaire gênant |
| **C12 Dépendances** | **645-01**. Indépendant du reste |

```
PROMPT 645-11 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-11 sur
claude/chore/645-11-entetes-et-couleurs depuis la tete de
origin/claude/integration/645-assainissement. git fetch d abord, cd explicite
dans chaque commande git. Ne remets JAMAIS le depot Skynet racine sur main.
Pose le tag avant-645-11 AVANT ton premier commit.

OBJET : deux chantiers de fond, sans risque.

CHANTIER 1 — LES EN-TETES. 479 fichiers source de lib/ sur 599 n ont pas
d en-tete, soit 80 pct. Mesure : 20,0 pct de fichiers avec en-tete le
02/10/2026, contre 17,5 pct le 21/09 — la part progresse, mais le nombre
absolu AUGMENTE (429 puis 479), parce que le depot grandit plus vite que la
discipline ne s installe.

FORME ATTENDUE : un doc comment de 1 a 3 lignes en PREMIERE LIGNE du
fichier, disant A QUOI SERT LE FICHIER.
  BON    : /// Bouton unique de l application, 4 variantes, parametre par
           /// AppButtonVariant.
  MAUVAIS: /// app_button.dart       <- paraphrase le nom, n apporte rien
  MAUVAIS: ligne 1 = import package:flutter/material.dart, pas un mot

REGLE : en francais accentue, et il doit dire quelque chose que le NOM DU
FICHIER NE DIT PAS DEJA. Un en-tete qui paraphrase le nom est refuse — tu
perdrais le benefice en gardant le cout.

OBTIENS LA LISTE :
  python tool/audit_global.py --section documentation --json
Section documentation.sans_entete.

CHANTIER 2 — LES COULEURS. 40 Color(0x...) en dur hors de lib/core/theme/ et
lib/core/branding/. Les porter dans core/theme/.
  En tete : lib/features/checklist/widgets/checklist_weight_banner.dart
    lignes 40, 58, 450, 459 — et ATTENTION, ce fichier repete DEUX FOIS les
    MEMES deux valeurs (0xFF9ACD32 lignes 40 et 450 ; 0xFF8B0000 lignes 58
    et 459). C est aussi une duplication de connaissance : une seule
    constante pour les deux.
  Puis : lib/features/community/domain/waypoint_type_config.dart lignes 38,
    43, 48, 53 (0xFF1565C0, 0xFF2E7D32, 0xFFC62828, 0xFF558B2F).
  Puis les 32 autres.

REGLE ABSOLUE SUR LES COULEURS : LA VALEUR HEXADECIMALE NE CHANGE PAS. C est
un DEPLACEMENT, pas une harmonisation. Si deux teintes voisines te semblent
devoir etre la meme, NE LES FUSIONNE PAS : note-le dans ton rapport comme
proposition pour Christophe. Toute envie d harmoniser est une EVOLUTION et
sort du perimetre.

DECOUPAGE : un commit par DOSSIER pour les en-tetes, un commit pour les
couleurs. Ce lot est SECABLE A VOLONTE : il sert de variable d ajustement du
plan. Si ton mandat dit « autant que le budget permet », fais les dossiers
par ordre decroissant de nombre de fichiers et arrete-toi ou on te le dit.

GATE COMPLETE AVANT DE LIVRER, les 4 doivent passer :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub          -> attendu : No issues found!
  flutter test                      -> attendu : 4002 passes, 2 ignores
  flutter build appbundle --release -> DOIT REUSSIR

CAPTURES OBLIGATOIRES pour le chantier 2 : avant et apres, sur les ecrans
dont une couleur a change de place. LA COULEUR AFFICHEE DOIT ETRE IDENTIQUE
AU PIXEL.

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : nombre d en-tetes poses et nouveau pourcentage, couleurs
portees au theme, teintes voisines reperees mais NON fusionnees (proposition
pour Christophe), resultat des 4 commandes de gate, ou sont les captures.
```

---

### 645-12 — Livre de bord du dépôt

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-12 |
| **C2 Fichier:ligne** | NOUVEAUX : `docs/JOURNAL.md`, `test/structurel/la_doc_ne_mente_pas_645_test.dart`. MODIFIÉ : `docs/architecture.md` |
| **C3 Description** | Un journal court : une ligne par lot — date, numéro, ce qui a changé, numéro de décision en base. Un schéma d'architecture remis au réel mesuré. Un test qui vérifie que les versions citées dans la doc **sont** celles de `pubspec.yaml` |
| **C4 Agent** | Athena |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-12)* |
| **C6 Branche** | `claude/docs/645-12-livre-de-bord` |
| **C7 Commit** | `docs(645-12): livre de bord du depot, verifie par test` |
| **C8 Test** | `flutter test test/structurel/la_doc_ne_mente_pas_645_test.dart` passe. Essai de régression : changer une version dans `pubspec.yaml` sans toucher la doc doit faire **échouer** le test |
| **C9 QA** | Aucune version citée dans la doc ne diverge de `pubspec.yaml`. Chaque lot du plan a sa ligne de journal avec son numéro de décision en base |
| **C10 Smoke** | `flutter test` complet |
| **C11 Rollback** | `git revert <sha>`. Aucun risque applicatif |
| **C12 Dépendances** | **tous les autres lots** — dernier par construction, il journalise ce qui a été fait |

```
PROMPT 645-12 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-12 sur claude/docs/645-12-livre-de-bord
depuis la tete de origin/claude/integration/645-assainissement. git fetch
d abord, cd explicite dans chaque commande git. Ne remets JAMAIS le depot
Skynet racine sur main.

OBJET : un livre de bord du depot, VERIFIE PAR UN TEST.

POURQUOI, ET LA PREUVE EST DANS LE DEPOT : docs/CONTRIBUTING.md ligne 36 et
docs/ADR/003-riverpod-over-bloc.md ligne 124 annoncaient Riverpod 2.6 alors
que pubspec.yaml etait en flutter_riverpod 3.3.2. LA DOC PERIMEE A DEJA
INDUIT EN ERREUR. Un document que rien ne verifie devient faux, et il
devient faux EN SILENCE.

TROIS LIVRABLES :

L1 docs/JOURNAL.md — NOUVEAU. UNE LIGNE PAR LOT, et une ligne est courte :
   date | numero du lot | ce qui a change, en une phrase | numero de
   decision en base.
   Exemple de forme :
   | 02/10/2026 | 644 | audit-inventaire, specifications et plan au cordeau
   | #100914, #100930 |
   Remplis-le pour les lots 643 a 645 deja faits, en lisant les memoires
   correspondantes en base. Ne RACONTE rien : une phrase, un numero.

L2 docs/architecture.md — MODIFIE. Remets-le au reel MESURE par l audit,
   pas au reel suppose. Chiffres a reprendre de
   docs/assainissement/644-01-inventaire.md : 599 fichiers source dans lib/,
   121 507 lignes ; lib/core 173 fichiers, lib/features 396, lib/shared 26 ;
   les 5 plus grosses features sont trek (64 fichiers), planning (29),
   feasibility (28), safety (25), checklist (19).
   DIS AUSSI CE QUI N EST PAS CONFORME : la feature trek est un domaine
   partage de fait, et c est mesure (78 imports socle vers feature,
   243 croisements entre features). Un schema d architecture qui cache les
   ecarts ne sert a rien.

L3 test/structurel/la_doc_ne_mente_pas_645_test.dart — NOUVEAU. Verifie :
   (a) toute version de paquet citee dans docs/ EST celle de pubspec.yaml ;
   (b) chaque lot nomme dans docs/JOURNAL.md a bien son numero de decision
       en base cite.
   PRECEDENT A COPIER : le depot a DEJA
   test/structurel/codemagic_entete_ne_mente_pas_619_test.dart, qui fait
   exactement cela pour codemagic.yaml. Lis-le et suis sa forme.

ESSAI DE REGRESSION OBLIGATOIRE, a faire et a RAPPORTER : change une version
dans pubspec.yaml sans toucher la doc, verifie que le test ECHOUE, puis
ANNULE la modification (git checkout -- pubspec.yaml). Si le test ne detecte
pas la divergence, ton test est faux : corrige-le.

GATE COMPLETE AVANT DE LIVRER :
  dart format --output=none --set-exit-if-changed lib test tool
  flutter analyze --no-pub   -> attendu : No issues found!
  flutter test               -> attendu : 4002 passes + le nouveau test

COMMIT ET PUSH par le registre gerer_git, repo-path sur ton worktree.
Message : docs(645-12): livre de bord du depot, verifie par test
AUCUNE FUSION. Commandes Bash sous 6 000 caracteres. « Christophe » partout.
RAPPORT ATTENDU : les 3 livrables, le resultat de l essai de regression, le
resultat des commandes de gate.
```

---

## 5. Checklist de complétude CORDO

Grille de `#85087`, appliquée à ce plan.

| Réf | Point de contrôle | État |
|---|---|---|
| #P37 | Les 12 champs sont renseignés pour chacun des 12 lots | **OK** |
| #P38 | Aucune réf en double | **OK** — 645-01 à 645-12, uniques |
| #P39 | Chaque prompt C5 est **autonome** (anti-pattern AP3) | **OK** — chaque prompt porte ses chemins, ses chiffres, ses commandes et ses pièges, sans renvoyer à un autre document |
| #P40 | L'index est cohérent avec les lots (AP2) | **OK** — index §4, graphe §2, coûts §3, tous à 12 lots |
| #P41 | Un smoke test global par lot (AP4) | **OK** — champ C10 de chaque fiche |
| #P42 | Le scope du GO est fixé **avant** exécution (AP5) | **OK** — §4, en tête : un GO vaut pour les lots qu'il nomme, et seulement ceux-là |
| #P43 | Les dépendances implicites sont explicitées (AP6) | **OK** — §2, et notamment 645-03 avant 645-06, 645-04 avant 645-05 et 645-07 |
| #P44 | Chaque lot a son rollback testable en une commande | **OK** — champ C11, plus un tag `avant-645-NN` par lot |
| #P45 | Chaque lot a un critère de réussite **chiffré** | **OK** — champ C9, adossé à un compteur d'audit |
| #P46 | Deux lots qui touchent le même fichier portent une dépendance explicite | **OK** — `health_info_screen.dart` et `map_screen.dart` apparaissent dans 645-03, 645-06 et 645-09 : d'où #P13 et #P16 |

---

## 6. Ce qui reste ouvert — et qui doit trancher

| Réf | Point ouvert | Qui tranche | Bloque quel lot |
|---|---|---|---|
| #P47 | **Voie A ou voie B** pour les 321 dépendances interdites (#X60/#X61) | Christophe | **bloque 645-05**, et change le coût de 150 $ à 25 $ |
| #P48 | **Décision produit** sur les 45 valeurs à compléter : renseigner, masquer ou retirer (#X91 à #X93) | Christophe | **bloque 645-08** |
| #P49 | **Convention d'observabilité** : les 3 clés `screen` / `trail` / `stage` proposées sont-elles les bonnes ? | Christophe | bloque 645-09 |
| #P50 | Les **10 arbitrages** du référentiel ECR (`#100239`) sont en attente depuis le 21/09 | Christophe | n'en bloque aucun, mais plusieurs seuils en dépendent |
| #P51 | **Budget** : le plan complet coûte 975 à 1 100 $. Le minimum utile (645-01, 02, 03, 08) coûte **325 $** | Christophe | détermine jusqu'où on va |
| #P52 | Faut-il ajouter `dart_code_metrics` pour une mesure **exacte** de la complexité, au prix d'une dépendance ? (arbitrage A-07 de `#100239`) | Christophe | n'en bloque aucun ; la mesure approchée suffit comme métrique de progression |
| #P53 | Les 72 sauts de version majeure : lesquels sont tirés par une obligation de boutique ? **Non mesuré dans ce lot** | à instruire | lot séparé, hors 645 |
| #P54 | Proposition 4 (contrat de données versionné), volet CI de la 5, et proposition 7 (personas en CI) : **hors de ce plan**, et c'est dit (#X127 à #X129) | Christophe | tâches séparées |

---

*Fin du 644-03. Suite : `644-04-audit-global.md`.*
