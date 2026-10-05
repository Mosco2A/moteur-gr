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


#### LES TROIS ARBITRAGES SONT TRANCHÉS — DÉCISIONS DE CHRISTOPHE DU 03/10/2026

Les trois lignes ci-dessus ne sont plus des questions ouvertes. Elles ont été
tranchées le **03/10/2026** et exécutées : **ARB-645-05-a par le lot 645-06**
(tête `eb948e24`), **ARB-645-05-b et ARB-645-05-c par le lot 645-05b** (branche
`claude/chore/645-05b-facades`, tête `88ffbe5c`, fusionnée en `7019908e`).

- **ARB-645-05-a — voie (A).** Le routeur est déclaré **exception écrite** à
  ECR-23 (a), avec sa justification : un routeur central EST un point de
  rencontre, et GoRouter demande la liste des routes en un point. Exécuté par le
  lot 645-06 : `lib/core/routing/app_router.dart` est exclu du comptage de la
  garde des couches et la règle est écrite dans `docs/conventions.md`
  (**règle 9**). Tout autre fichier du socle y reste compté.

- **ARB-645-05-b — voie (B).** Une **façade par feature** : une feature ne lit
  une autre feature que par sa porte publique
  `lib/features/<f>/<f>_facade.dart`. Exécuté par le lot 645-05b : **20
  façades** créées (48 directives `export … show` explicites, **87 symboles**
  exposés, aucun `export *`, aucune logique), et **130 imports croisés
  redirigés**. Chacun des 130 porte un `show` explicite **du côté import aussi**
  (109 lignes d'import, 169 symboles nommés) : c'est le double verrou qui rend
  la redirection vérifiable. Aucun symbole n'a changé de source — pour chacun
  des 130, le fichier qui le déclare était déjà importé par le même appelant.
  `docs/conventions.md` **règle 10**.

- **ARB-645-05-c — voie (B).** `lib/domain/` est **AU-DESSUS** de `core/` et de
  `shared/` : le métier lit le socle, le socle ne remonte jamais vers le métier.
  Exécuté par le lot 645-05b, les 3 flèches `core → domain` payées une par une :
  le **seuil de bruit de l'altimètre** descend dans `GeoUtils` — c'est une
  propriété d'instrument, pas une règle de randonnée — et
  `TrekStats.elevationNoiseThresholdM` le relit, valeur inchangée à 3.0 m ;
  **`privacy_data_policy.dart`** monte dans `lib/domain/`, c'est une règle de
  conformité typée sur `TrackPoint` de bout en bout ; le **mapping
  `TrekSession` ↔ Drift** quitte le DAO pour `lib/domain/trek_session_mapping.dart`,
  **en extension**, pour que les appelants gardent le même appel, le même nom et
  la même signature. `docs/conventions.md` **règle 11**.

**LES PLAFONDS, AVANT ET APRÈS, MESURÉS (QA locale, tâche 664, 03/10/2026).**
Relevés sur la tête fusionnée `7019908e`. Les trois plafonds de
`test/structurel/couches_respectees_645_test.dart` sont posés **à la mesure,
sans marge** : un plafond au-dessus de la mesure est une autorisation de
régresser.

- *socle → feature* : 78 au 02/10, 72 après 645-05, **21** après 645-06
  (routeur exclu, ARB-a), **21** après 645-05b.
- *croisements entre features* : 223 au 02/10, 182 après 645-05, 182 après
  645-06, **52** après 645-05b.
- *socle → métier* (`core`/`shared` → `lib/domain/`) : 3 au 02/10, 3 après
  645-05, 3 après 645-06 — et **non mesurés** jusque-là, puisque l'audit rangeait
  `core`, `shared` et `domain` dans un seul sac — **0** après 645-05b.
- *ECR-23 (audit global)* : 301 au 02/10, 254 après 645-05, 254 après 645-06,
  **233** après 645-05b.

Les trois gardes ont été **prouvées vivantes par mutation** (tâche 664) : une
flèche `core → domain` injectée fait rougir (c) ; une façade qui re-exporte une
autre feature fait rougir la garde négative dédiée ; et un fichier nommé
`<f>_facade.dart` placé **ailleurs** qu'à la racine de sa feature **ne gagne pas
l'exemption** — le croisement reste compté (52 → 53, rouge). L'exclusion est
donc étroite, et elle est gardée.

**CE QUI RESTE, ET QUI EST L'ARBITRAGE SUIVANT.** Des 52 croisements restants,
**aucun ne vise un `providers/`** : l'état Riverpod partagé est entièrement payé.
**32 sont des emprunts bilatéraux de type** — 19 vers un `domain/` de feature, 10
vers un `widgets/`, 3 vers un `models/` — dont ARB-645-05-b a déjà établi
qu'aucun n'est lu par deux features ou plus. Les **20 autres** sont d'une autre
nature : un écran qui monte le widget d'une autre feature, ou un service de
données lu de loin, n'est pas le même problème qu'un provider. Ce sont eux qui
demandent la décision suivante de Christophe.

*Les 15 vers une `presentation/`* : `after/adventure_recap_screen` →
`diploma/…/session_trace_painter` ; `auth/profile_screen` →
`safety/…/refus_sauvegarde_systeme_dialog` ; `hub/hub_screen` →
`ads/…/banner_ad_slot` et → `safety/…/sos_button` ; `hub/…/hub_cockpit_scroll` →
`ads/…/badge_etat_publicite` ; `hub/…/hub_start_trek_button` →
`treks/…/active_trek_conflict_dialog` ; `hub/…/localized_conditions_banner` →
`weather/…/fire_risk_screen` ; `map/…/simplified_track_provider` →
`trek/…/map/marker_cluster` ; `settings/…/account_erasure_provider` →
`safety/…/health_info_screen` ; `trail/trail_catalog_screen` →
`ads/…/badge_etat_publicite` et → `ads/…/banner_ad_slot` ; `trek/…/map_screen` →
`safety/…/sos_button` ; `treks/my_treks_screen` → `hub/…/hub_section` et →
`hub/…/quick_access_card` ; `weather/…/weather_alert_banner` →
`tips/…/tip_detail_sheet`.

*Les 5 vers un `data/`* : `feasibility/…/ibp_calculator` →
`trek/data/track_simplifier` ; `feasibility/…/walk_test_provider` →
`trek/data/gps_service` ; `settings/…/account_erasure_provider` →
`feasibility/data/hiker_profile_repository` ; `trek/…/map_screen` →
`journal/data/photo_service` ; `trek/…/trek_stage_detail_screen` →
`safety/data/signalement_service`.

Trois familles s'y dessinent, et elles n'appellent pas le même geste. Les
**bandeaux publicitaires** (`ads/`) et le **bouton SOS** (`safety/`) sont montés
par trois écrans différents chacun : ce qui est lu par plusieurs features monte
dans `shared/`. Les **widgets de cockpit** (`hub/`) relus par `my_treks_screen`
posent plutôt la question de savoir si `hub` et `treks` ne sont pas une seule
feature. Les **services de données** (`gps_service`, `photo_service`,
`signalement_service`) sont le seul groupe qui se lirait naturellement par une
façade élargie.


**CE QUE LE 645-05c A FAIT (05/10/2026).** L'arbitrage suivant est tranché :
**option A, zéro croisement par des gestes conformes**, décision de Skynet sous
délégation de Christophe (04/10/2026, GO-90, **#101226**), avec la règle de
Christophe du 03/10 : propre et aux normes, la solution conforme l'emporte sur
le coût. Branche `claude/chore/645-05c-zero-croisement`, partie de
l'intégration `7d2a2dbc`, un commit par geste, gate complète verte après
chacun. **Les 52 croisements sont à zéro**, aucune feature n'est fusionnée
(option B écartée), aucun écran ne change de dossier, aucun symbole n'est
renommé.

Deux gestes seulement, choisis fichier par fichier :

- **Monter dans `lib/shared/widgets/`** — uniquement ce qui n'importe AUCUNE
  feature (règle 9) : `hub_section`, `quick_access_card` et `step_status_icon`
  (dont dépend `quick_access_card`), trois briques d'interface qui ne lisent
  que `core/` et `shared/`. Déplacées telles quelles (`git diff -M` : trois
  renommages, seuls les chemins d'import changent). Deux croisements payés.
- **Lire la façade de la feature** (règle 10) — tout le reste, 50 croisements.
  Aucun widget de la famille « pub / SOS » ne pouvait monter : `banner_ad_slot`
  lit `ads_providers`, `ad_state_badge` lit `ads/domain/ad_state`,
  `sos_button` lit la façade `trek`. Les emprunts isolés sont un peintre, des
  dialogues, un écran ou un algorithme propres à leur feature, et plusieurs
  lisent ses providers. Les 32 emprunts de type restent dans leur feature :
  aucun n'est lu par deux features ou plus (ARB-645-05-b), ils n'ont rien à
  faire dans `lib/domain/`. **38 directives `export … show` ajoutées, 51
  symboles**, dans 16 façades dont **2 créées** (`checklist`, `tips`) ; côté
  appelant, chaque import de façade porte aussi son `show`, et se fusionne dans
  la ligne de façade existante quand il y en avait une. Une façade ne contient
  toujours que des `export`.

| # | Geste | Vers | Appelant (`lib/features/…`) | Cible (`lib/features/…`) | Geste retenu |
|---|---|---|---|---|---|
| 1 | G1 | presentation | `hub/presentation/hub_screen.dart` | `ads/presentation/banner_ad_slot.dart` | facade de `ads` |
| 2 | G1 | presentation | `hub/presentation/hub_screen.dart` | `safety/presentation/sos_button.dart` | facade de `safety` |
| 3 | G1 | presentation | `hub/presentation/widgets/hub_cockpit_scroll.dart` | `ads/presentation/ad_state_badge.dart` | facade de `ads` |
| 4 | G1 | presentation | `trail/presentation/trail_catalog_screen.dart` | `ads/presentation/ad_state_badge.dart` | facade de `ads` |
| 5 | G1 | presentation | `trail/presentation/trail_catalog_screen.dart` | `ads/presentation/banner_ad_slot.dart` | facade de `ads` |
| 6 | G1 | presentation | `trek/presentation/map/map_overlays.dart` | `safety/presentation/sos_button.dart` | facade de `safety` |
| 7 | G2 | presentation | `treks/presentation/my_treks_screen.dart` | `hub/presentation/widgets/hub_section.dart` | monte dans lib/shared/widgets/ |
| 8 | G2 | presentation | `treks/presentation/my_treks_screen.dart` | `hub/presentation/widgets/quick_access_card.dart` | monte dans lib/shared/widgets/ |
| 9 | G3 | data | `feasibility/domain/ibp_calculator.dart` | `trek/data/track_simplifier.dart` | facade de `trek` |
| 10 | G3 | data | `feasibility/providers/walk_test_provider.dart` | `trek/data/gps_service.dart` | facade de `trek` |
| 11 | G3 | data | `settings/providers/account_erasure_provider.dart` | `feasibility/data/hiker_profile_repository.dart` | facade de `feasibility` |
| 12 | G3 | data | `trek/presentation/map/map_photo_button.dart` | `journal/data/photo_service.dart` | facade de `journal` |
| 13 | G3 | data | `trek/presentation/stages/trek_stage_detail_screen.dart` | `safety/data/signalement_service.dart` | facade de `safety` |
| 14 | G4 | presentation | `after/presentation/adventure_recap_screen.dart` | `diploma/presentation/widgets/session_trace_painter.dart` | facade de `diploma` |
| 15 | G4 | presentation | `auth/presentation/profile_screen.dart` | `safety/presentation/refus_sauvegarde_systeme_dialog.dart` | facade de `safety` |
| 16 | G4 | presentation | `hub/presentation/widgets/hub_start_trek_button.dart` | `treks/presentation/widgets/active_trek_conflict_dialog.dart` | facade de `treks` |
| 17 | G4 | presentation | `hub/presentation/widgets/localized_conditions_banner.dart` | `weather/presentation/fire_risk_screen.dart` | facade de `weather` |
| 18 | G4 | presentation | `map/providers/simplified_track_provider.dart` | `trek/presentation/map/marker_cluster.dart` | facade de `trek` |
| 19 | G4 | presentation | `settings/providers/account_erasure_provider.dart` | `safety/presentation/health_info_screen.dart` | facade de `safety` |
| 20 | G4 | presentation | `weather/widgets/weather_alert_banner.dart` | `tips/presentation/tip_detail_sheet.dart` | facade de `tips` |
| 21 | G5 | domain | `checklist/presentation/checklist_screen.dart` | `feasibility/domain/hiker_profile.dart` | facade de `feasibility` |
| 22 | G5 | domain | `checklist/providers/checklist_provider.dart` | `feasibility/domain/body_weight_reference.dart` | facade de `feasibility` |
| 23 | G5 | domain | `checklist/providers/checklist_provider.dart` | `feasibility/domain/hiker_input_bounds.dart` | facade de `feasibility` |
| 24 | G5 | domain | `checklist/widgets/checklist_descent_alert.dart` | `feasibility/domain/body_weight_reference.dart` | facade de `feasibility` |
| 25 | G5 | domain | `checklist/widgets/checklist_recommendation_banner.dart` | `feasibility/domain/body_weight_reference.dart` | facade de `feasibility` |
| 26 | G5 | domain | `checklist/widgets/checklist_weight_banner.dart` | `feasibility/domain/body_weight_reference.dart` | facade de `feasibility` |
| 27 | G5 | domain | `checklist/widgets/checklist_weight_banner.dart` | `feasibility/domain/hiker_input_bounds.dart` | facade de `feasibility` |
| 28 | G5 | domain | `diploma/presentation/diploma_screen.dart` | `journal/domain/models/journal_entry.dart` | facade de `journal` |
| 29 | G5 | domain | `feasibility/domain/feasibility_program.dart` | `planning/domain/planning_calculator.dart` | facade de `planning` |
| 30 | G5 | domain | `feasibility/domain/program_plan_search.dart` | `planning/domain/planning_calculator.dart` | facade de `planning` |
| 31 | G5 | domain | `feasibility/providers/trek_feasibility_provider.dart` | `checklist/domain/season.dart` | facade de `checklist` |
| 32 | G5 | domain | `hub/presentation/cockpit_phase.dart` | `treks/domain/trek_lifecycle_state.dart` | facade de `treks` |
| 33 | G5 | domain | `hub/presentation/widgets/finish_trek_button.dart` | `treks/domain/trek_lifecycle_state.dart` | facade de `treks` |
| 34 | G5 | domain | `hub/presentation/widgets/hub_trek_card.dart` | `treks/domain/trek_lifecycle_state.dart` | facade de `treks` |
| 35 | G5 | domain | `planning/presentation/plan_summary_screen.dart` | `booking/domain/models/nuitee_type.dart` | facade de `booking` |
| 36 | G5 | domain | `planning/providers/planning_provider.dart` | `feasibility/domain/program_plan_search.dart` | facade de `feasibility` |
| 37 | G5 | domain | `trail/presentation/trail_catalog_screen.dart` | `ads/domain/ad_state.dart` | facade de `ads` |
| 38 | G5 | domain | `trek/domain/itinerary_calculator.dart` | `trail/domain/models/trail_feasibility_params.dart` | facade de `trail` |
| 39 | G5 | domain | `trek/presentation/map/map_content.dart` | `map/domain/stage_focus.dart` | facade de `map` |
| 40 | G5 | models | `feasibility/domain/feasibility_program.dart` | `planning/models/day_plan.dart` | facade de `planning` |
| 41 | G5 | models | `hub/presentation/widgets/hub_weather_card.dart` | `weather/models/weather_forecast.dart` | facade de `weather` |
| 42 | G5 | models | `hub/presentation/widgets/localized_conditions_banner.dart` | `weather/models/weather_forecast.dart` | facade de `weather` |
| 43 | G5 | widgets | `hub/presentation/widgets/hub_weather_card.dart` | `weather/widgets/day_forecast_card.dart` | facade de `weather` |
| 44 | G5 | widgets | `hub/presentation/widgets/localized_conditions_banner.dart` | `weather/widgets/day_forecast_card.dart` | facade de `weather` |
| 45 | G5 | widgets | `trek/presentation/map/layers/trail_markers_layer.dart` | `map/widgets/poi_marker.dart` | facade de `map` |
| 46 | G5 | widgets | `trek/presentation/map/layers/user_position_layer.dart` | `map/widgets/user_position_marker.dart` | facade de `map` |
| 47 | G5 | widgets | `trek/presentation/map/map_content.dart` | `map/widgets/stage_progress_bar.dart` | facade de `map` |
| 48 | G5 | widgets | `trek/presentation/map/map_overlays.dart` | `map/widgets/off_track_banner.dart` | facade de `map` |
| 49 | G5 | widgets | `trek/presentation/map/map_screen.dart` | `map/widgets/map_guide_sheet.dart` | facade de `map` |
| 50 | G5 | widgets | `trek/presentation/map/map_sheets.dart` | `map/widgets/poi_filter_bar.dart` | facade de `map` |
| 51 | G5 | widgets | `trek/presentation/map/map_sheets.dart` | `map/widgets/poi_popup.dart` | facade de `map` |
| 52 | G5 | widgets | `trek/presentation/map/map_sheets.dart` | `map/widgets/stage_poi_checklist.dart` | facade de `map` |

Fichiers déplacés (contenu identique hors chemins d'import) :
`lib/features/hub/presentation/widgets/hub_section.dart` →
`lib/shared/widgets/hub_section.dart`, `…/quick_access_card.dart` →
`lib/shared/widgets/quick_access_card.dart`, `…/step_status_icon.dart` →
`lib/shared/widgets/step_status_icon.dart`. Deux tests adaptés en chemin
d'import seulement : `test/comportement/icones_bicolores_639_test.dart` et
`test/comportement/libelles_longs_634_test.dart`.

**Compteurs, avant (`7d2a2dbc`) → après (`27fb89bf`), mesurés.**

- Garde `couches_respectees_645_test.dart` : *socle → feature* 21 → **21**
  (routeur exclu, ARB-a) ; *croisements entre features* **52 → 0**, et son
  plafond descendu de 52 à **0** ; *socle → métier* 0 → **0**. Façades qui
  re-exportent une voisine : 0.
- Audit (`tool/audit_global.py --rapide`) : **ECR-23 236 → 208** (les
  croisements de l'audit comptent aussi les façades : 164 → 136, dont
  façades 112 → 136 et intérieur 52 → 0) ; ECR-15 46 = 46 ; ECR-28 195 =
  195 ; ECR-19 10 = 10 ; ECR-31 19 = 19 ; MORT-01 141 = 141. Trois compteurs
  montent, chacun par construction et sans code nouveau : **ECR-16 416 →
  418** et **RNG-01 20 → 22**, les deux façades créées étant à la racine de
  leur feature et sans test miroir, comme les vingt autres ; **ECR-05 77 →
  78**, la liste fermée de l'audit trouvant le mot « lot » dans
  `BannerAdSlot` (Slot), désormais cité par `ads_facade.dart` — aucun
  identifiant n'est nouveau ni renommé. Observabilité 63/63, OBS-01 0,
  VAC-01 0, en-têtes 100 %.
- `flutter analyze` : 0 erreur, 0 warning, infos **7 614 → 7 613** (une
  `directives_ordering` disparaît avec l'import interne retiré de
  `plan_summary_screen.dart`). `flutter test` : 4 092 réussis, 2 ignorés,
  0 échec, avant comme après chaque geste.

**Mutations, chacune annulée par `git checkout --`, zéro diff résiduel.**
(1) un import de `lib/features/hub/hub_facade.dart` injecté dans
`lib/shared/widgets/hub_section.dart` : garde rouge, *socle → feature* 22
contre 21. (2) un import de `ads/presentation/banner_ad_slot.dart` injecté
dans `hub_screen.dart` : garde rouge, *croisements* 1 contre 0. (3)
`tips_facade.dart` qui re-exporte `weather/presentation/fire_risk_screen.dart` :
garde rouge, « une façade ne re-exporte que SA feature ». (4) le 0 de la
ligne « dont vers l'intérieur de la voisine » de `docs/architecture.md`
changé en 1 : `la_doc_ne_mente_pas_645_test.dart` rouge (« la doc dit 1,
l audit mesure 0 »).

**Ce qui n'est pas fait, et pourquoi.** Les chiffres balisés de
`docs/architecture.md` sont revérifiés à chaque `flutter test` : ils ont donc
été remis au réel dans CHAQUE commit de code du lot, pas seulement dans le
commit de documentation, sans quoi la gate aurait été rouge entre deux
gestes. La preuve à l'écran (captures avant/après, personas) reste à faire
en local par Skynet : ni SDK Android ni émulateur dans la session cloud.

**QA DU 645-05c, PARTIE CODE (05/10/2026, 03:25 UTC).** Artemis, session cloud
lancée par Skynet pour Christophe. Branche `claude/qa/645-05c-jonction`, partie
de l'intégration `7d2a2dbc` ; branche vérifiée `d5cb91f0` (G1 à G7, un commit
par geste) ; jonction sans avance rapide `9a854e70`, aucun conflit, arbre
identique à `d5cb91f0`. L'intégration n'est pas touchée, aucun tag.

Verdicts de lecture, tous **OK** :

- (a) `git diff -M` : 64 fichiers, tous sous `lib/features/`, `lib/shared/`,
  `test/` ou `docs/` ; trois renommages (R096 à R098) pour les trois briques
  montées ; ni `pubspec`, ni `android/`, ni `macos/`, ni `lib/i18n`, ni le
  routeur.
- (b) Compte par programme indépendant de la garde (imports, exports et `part`,
  relatifs résolus) : croisements vers l'intérieur d'une voisine **52 → 0**
  (avant : 19 `domain/`, 15 `presentation/`, 10 `widgets/`, 5 `data/`,
  3 `models/`) ; socle → feature hors routeur **21 = 21** en imports (22 si
  l'on compte aussi l'`export` de `gpx_depuis_les_assets.dart`, inchangé et
  antérieur au lot) ; `core/`, `shared/` → `lib/domain/` **0**.
- (c) Les trois fichiers montés n'importent que `core/` et `shared/` ; leur
  corps est identique ligne à ligne, seules les directives `import` changent.
  Les 22 façades relues : uniquement des `export … show`, chacune vers SA
  feature. Les 52 lignes du tableau ci-dessus vérifiées dans le code : chaque
  appelant lit la façade (avec `show`) et ne lit plus l'intérieur, chaque
  façade exporte bien la cible. **38 directives, 51 symboles : exact.**
  **Correction : 14 façades touchées (12 élargies, 2 créées), et non 16.**
- (d) Dans les 47 fichiers de `lib/` et `test/` modifiés hors façades, une fois les
  directives `import`/`export` retirées, le texte est identique, commentaires
  compris ; seule exception, la garde `couches_respectees_645_test.dart`
  (constante 52 → 0 et deux commentaires). Les deux tests adaptés ne changent
  que des chemins d'import ; aucun test nouveau.
- (e) Garde : plafonds 21 / 0 / 0, test « une façade ne re-exporte que SA
  feature » intact. Les quatre mutations rejouées, toutes **rouges** puis
  restaurées, zéro diff : (1) import de `hub_facade.dart` dans
  `shared/widgets/hub_section.dart` → (a) 22 contre 21 ; (2) import de
  `ads/presentation/banner_ad_slot.dart` dans `hub_screen.dart` → (b) 1 contre
  0 ; (3) `tips_facade.dart` qui re-exporte `weather/…/fire_risk_screen.dart`
  → « une façade ne re-exporte que SA feature » ; (4) le 0 de « dont vers
  l'intérieur de la voisine » passé à 1 → `la_doc_ne_mente_pas` (« la doc dit
  1, l audit mesure 0 »).
- (f) `JOURNAL.md` : ligne 645-05c (#101226), lignes 676 (#101196) et 645-12
  (#101229, #101232) présentes, ligne « Vingt croisements » retirée de « Ce qui
  reste ouvert ». `architecture.md` : 24 chiffres balisés, égaux à l'audit de
  la tête jointe. Écart vérifié commit par commit : G1 à G5 ne changent dans
  `architecture.md` QUE des nombres balisés, G6 aucun document, seul G7 change
  du texte.

**Gate sur la tête jointe `9a854e70`.** `dart format` : 1 309 fichiers, 0
modifié. `flutter analyze` : 0 erreur, 0 warning, infos **7 614 → 7 613**
(la `directives_ordering` de `plan_summary_screen.dart`). `flutter test` :
**4 092 réussis, 2 ignorés, 0 échec**. `build_runner` : aucun fichier
généré ne change. Gardes `couches_respectees`, `pas_de_part` et
`la_doc_ne_mente_pas` vertes.

**Audit `--rapide`, avant (`7d2a2dbc`) → après (tête jointe).** ECR-23
**236 → 208** ; ECR-16 416 → 418 et RNG-01 20 → 22 (les deux façades créées,
`checklist_facade.dart` et `tips_facade.dart`, à la racine de leur feature
et sans test miroir) ; ECR-05 77 → 78 (`lib/features/ads` 1 → 2 :
`BannerAdSlot` cité par `ads_facade.dart`) ; ECR-15 46, ECR-28 195, ECR-19 10,
ECR-31 19, MORT-01 141 inchangés ; observabilité 63/63, OBS-01 0, VAC-01 0,
en-têtes 100 %.

**QA DU 645-05c, PARTIE ÉCRANS (05/10/2026 — Artemis, émulateur local).**
Deux arbres jetables sur le même émulateur (`emulator-5554`, 1080×2400,
Android 14), même mode local, même profil, même thème, **installation vierge à
chaque run** : AVANT sur l'intégration `7d2a2dbc`, APRÈS sur la branche de QA
`claude/qa/645-05c-jonction` à `53f9d51b`. Huit scénarios joués **des deux
côtés** : S1 Léa, S2 Marc, S3 Steve, S4 Inès, S8 démo, traversée 645-09, les
douze tours de pile du 676, et un scénario écrit pour cette QA
(`qa_684_conflit_test.dart`, **non commité**) qui ouvre le **dialogue de conflit
de trek actif** — le seul écran du lot qu'aucun persona ne traverse.

**Comparaison au pixel : 177 captures comparées, 156 IDENTIQUES AU PIXEL hors
barre d'état, et aucun des 21 écarts n'est imputable au code.** La barre d'état
est exclue (85 px du haut : l'horloge y bouge sur *toutes* les captures).

| scénario | comparées | identiques | écarts |
|---|---|---|---|
| S1 Léa | 65 | 55 | 10 |
| S2 Marc | 20 | 19 | 1 |
| S3 Steve | 44 | **39** | 5 |
| S4 Inès | 15 | **15** | **0** |
| S8 démo | 11 | 10 | 1 |
| traversée 645-09 | 16 | 13 | 3 |
| douze tours de pile | 3 | 2 | 1 |
| dialogue de conflit | 3 | **3** | **0** |

**Les deux écrans prioritaires sont à zéro.** Cockpit `/home` (où montent
`HubSection`, `QuickAccessCard` et `StepStatusIcon`, désormais dans
`lib/shared/widgets/`, et où `BannerAdSlot` et `SosButton` passent par leur
façade) : `S1 07c_cockpit`, `S1 26_cockpit_fin`, `S2 04_cockpit`,
`S3 03_cockpit`, `S3 10_cockpit_fin`, `S4 03_cockpit`,
`S4 10_cockpit_offline`, `T645 03_hub` — **identiques au pixel**. Mes treks
`/my-treks` : `S2 03_mes_treks`, `S8 11_mes_treks_apres_demo` — **identiques au
pixel**. (`S1 07b_mes_treks` n'existe pas dans un run sain : il vit dans le
filet de régression `if (onMapAfterEnter)`, et « Entrer » ouvre bien le
cockpit.) Écrans secondaires, tous identiques au pixel : catalogue, carte et
dialogue SOS, récapitulatif, diplôme, checklist, profil, détail d'étape,
synthèse du plan, faisabilité.

**Les 21 écarts, nommés un par un** (captures des deux côtés dans le
scratchpad `645-05c/`) :
- **Course de démarrage** (4) : `01_boot` de S1, S2, S8 et des douze tours —
  l'écran d'attente de l'app d'un côté, « Test starting… » du harnais de
  l'autre : deux instants du même boot. Celui de la traversée est
  **sous-perceptible** (amplitude max **9 sur 255**).
- **Clavier SYSTÈME re-thémé** (6) : `S1 09b`, `S1 12a`, `S1 31`, `S3 15`,
  `S3E 37c`, `S3E 37d`. L'écart est **entièrement dans la bande du clavier** ;
  les touches de modification passent du bleu au lilas — c'est Material You
  de l'émulateur, re-tiré par le **redémarrage** que la QA a dû faire. Le
  contenu de l'application au-dessus est identique au pixel.
- **Horloge dans le contenu** (5) : heure de la note du journal (`S1 32`,
  `S3 16`), « mis à jour à » de la météo (`S1E 25`, `T645 07` : `oct. 07:14`
  → `oct. 09:06`), du risque d'incendie (`S3E 26` : `10:18` → `10:36`).
- **Bandeau fugace** (1) : `S1 09c`, le bandeau vert « Fiche enregistrée »
  (4 s de vie), dans la seule bande `y 2195..2373`.
- **Image d'animation** (1) : `T645 12_secours`, le rouage « Acquisition GPS »
  à un autre angle (133 px).
- **Dérive de parcours, prouvée** (3) : `S1 12c`, `S1 13_retour_cockpit` et
  `S1 10b` — l'image d'un côté est, **au pixel**, celle d'un AUTRE marqueur de
  l'autre côté (`13_retour_cockpit` APRÈS = `14_entrainement` AVANT). Le run
  était un écran en retard : la comparaison est nulle, pas l'écran.

**Ce que la méthode a appris, et qui vaut pour les prochaines QA.** Compter des
pixels ne suffit pas : on mesure aussi l'**amplitude** (écart maximal sur un
canal). Jouer les sept scénarios d'un côté **puis** de l'autre laisse une heure
et demie de dérive machine entre deux captures du même écran. Rejoué **dos à
dos**, S3 est passé de 15 à **39 identiques sur 44** et S4 de « écarts partout »
à **15 sur 15**, sans qu'une ligne de code bouge : les 16 écarts « carte » à
amplitude 14/255 et les 4 décalages de défilement de 42 px ont disparu d'eux-mêmes.

**Preuve statique, en complément, jeton par jeton.** Sur **tout `lib/`**, le
multi-ensemble de ce qui peut se voir est identique des deux côtés : **1 443**
occurrences de clés de traduction, **199** `ValueKey`, **886** icônes
`StepwaysIcons`, **2 376** constantes `AppTheme` — **zéro jeton dont le compte
diffère**. Et le déplacement est un miroir exact : `lib/features/hub` perd
précisément les **douze** jetons que `lib/shared` gagne (`StepwaysIcons.sablier`
1→0 contre 0→1, `AppTheme.spacingMd` 7→4 contre 0→3, …). Rien de visible n'a été
créé, détruit ni modifié : seulement déplacé.

**Personas sur la tête APRÈS — identiques à la tête AVANT, exigence par
exigence.** S1 Léa **61/2** (et ce sont les deux connues : CTA « Démarrer la
randonnée » absent de l'arbre, diplôme qui ne s'ouvre pas) ; S2 Marc **20/20** ;
S3 Steve **17/1** (le même diplôme) ; S4 Inès **8/1** (le même verrou d'achat) ;
S8 démo **29/1** (« Démarrer » actif en démo, des deux côtés) ; traversée
`traversee_645_09_test.dart` **verte des deux côtés**, 16/16 captures. Le
dialogue de conflit s'ouvre, porte ses **trois** boutons (annuler / abandonner /
terminer) et « Annuler » rend bien `ActiveTrekConflictChoice.cancel`, des deux
côtés, avec les 3 captures identiques au pixel.

**Journal local et observabilité.** **38 écrans distincts émettent leur miette
`screen:<nom>` des deux côtés**, mêmes clés : aucun n'a cessé d'émettre, aucun
n'est apparu, aucun n'a changé de nom. Les **douze tours de pile** du 676 sont
**verts des deux côtés** et leur dictionnaire de miettes est identique
caractère pour caractère — `settings 12` (les douze poussées), `journal 13` (le
journal plus les douze redescentes), et **aucune miette d'un écran resté vivant
sous la pile**.

**Logcat : 0 plantage, 0 ANR, 0 mort non demandée, 0 exception Dart de
l'application**, sur les 8 runs de chaque côté, **141 166 lignes** lues
(buffers `main`, `crash`, `system`). Deux précisions d'honnêteté : la ligne
`Killing … com.only1cent.stepways` présente à chaque run est **notre propre**
`force-stop` avant la désinstallation ; et les deux seules `FATAL EXCEPTION`
rencontrées appartiennent à `com.android.commands.uiautomator`, c'est-à-dire au
démon de dialogues **de la QA**, pas au produit.

**Ce qui n'est pas vert, et ne vient pas du lot.** (1) Le contrôle de fin de run
refuse plusieurs runs sur des captures **légitimement identiques** non déclarées
dans `captures_doublons_tolerees.txt` — y compris, pour le dialogue de conflit,
`01_cockpit_avant_dialogue = 03_cockpit_apres_annuler`, c'est-à-dire **la preuve
elle-même** que « Annuler » ne laisse pas de trace. Le fichier de tolérances
n'a pas été élargi : on ne négocie pas avec un rouge pour le faire taire.
(2) **`completeOnboardingIfPresent` donne 10 s au texte « Passer/Skip »** ; sur
une installation à froid l'onboarding peint plus tard, le harnais conclut
« Onboarding absent (déjà complété) » et le scénario entier se joue **derrière
le carrousel** — la miette `screen:onboarding` le prouve au même instant.
Trois runs perdus. (3) La **pile Bluetooth de l'émulateur** part en boucle de
plantage (`F/libc SIGABRT` dans `bt_stack_manage`) autour des bascules de mode
avion de S4 et affame le système jusqu'à l'ANR de l'application : trois runs
perdus, réparés en éteignant le Bluetooth. (4) L'aide hôte de S4 **dort 55 s en
aveugle** avant de couper le réseau, pendant que le run avance à son rythme :
une fois la coupure tombée pendant l'étape *en ligne*, S4 rend 4 échecs qui ne
disent rien du produit. (5) Le scénario de QA du dialogue reste rouge au
teardown sur `A SemanticsHandle was active at the end of the test`, **des deux
côtés**, y compris en rendant la poignée dans l'ordre vert de S1 et de la
traversée : la poignée est prise par l'application, pas par le scénario.

Rien n'est livré : `main` reste `708b82ce`, l'intégration n'est pas touchée,
aucun tag, aucune jonction.


**QA GROUPÉE P1 + RECETTE PERSONA (05/10/2026 — Artemis, tâche 690, émulateur
local).** Deux lots joints sur une branche de QA jetable,
`claude/qa/p1-recette-jonction`, prise sur l'intégration `a06f5000` (build 10) :
d'abord la **recette persona robuste**
(`claude/chore/recette-persona-robuste` à `1e5a3a0b`, dix commits, `#101261` et
`#101275`), puis le **lot produit P1**
(`claude/fix/produit-p1-reglages-temperature-booking` à `a4eafbe6`, trois
commits, `#101271`). Un seul conflit, attendu et trivial : `docs/JOURNAL.md`,
où les deux côtés ajoutent des lignes au même endroit — **les deux sont
gardées** ; `docs/architecture.md` s'est joint sans conflit. **Verdict : les
deux lots sont OK, aucun AFFAIBLI.**

**LA LECTURE, POINT PAR POINT.** *P1* — (a) le diff est borné aux réglages, à
`lib/domain/temperature_unit.dart`, aux sept affichages de température, à la
route `/booking` et à ses miettes, à `lib/i18n` (5 langues), à `test/` et à
`docs/` ; (b) la lecture tolérante **rejouée à l'envers** :
`settings_service.dart` ramené à son état d'avant le lot rend **4 rouges** aux
motifs exacts — `type 'int' is not a subtype of type 'String?'` puis
`Expected: 'en' / Actual: 'fr'`, la preuve qu'une clé abîmée en emportait une
intacte — et **81 verts** une fois le correctif remis ; (c) **une seule**
fonction de formatage, dans `lib/domain/`, et **exactement sept** fichiers
importent `settings_facade.dart show settingsProvider` — la façade, jamais
l'intérieur : ce sont les +7 d'ECR-23. Aucun « °C » en dur ne subsiste dans
`lib/` ni dans `assets/i18n/`, et le modèle reste en Celsius (`weather/data/`
et `weather/models/` ne sont pas touchés) ; (d) `/booking` n'a plus ni route,
ni nom, ni écran, ni miette, ni drapeau, le **domaine** `booking` est intact
(façade, `NuiteeType`, nuitées, hébergements périphériques), et la garde
d'observabilité passe à **62/62** ; (e) les 31 cas ajoutés sont lus et
substantiels — les cinq langues de l'alerte incendie vérifient 35 °C ↔ 95 °F —
et **aucune attente existante n'est affaiblie**.
*Recette* — (f) les 11 fichiers du diff vivent dans `integration_test/`,
`tool/` et `test/`, **zéro sous `lib/`** ; (g) les cinq points sont relus et les
deux mutations rejouées : délai fixe de 10 s remis → **2 rouges sur 12** aux
motifs prévus ; tolérance **sans raison écrite** ajoutée au fichier réel, puis
contrôle rejoué sur un run réel du 05/10 → `FAUTE : tolerance ligne 141 SANS
RAISON ECRITE` et **code de sortie 1**, là où le fichier du dépôt sort en 0.

**LA GATE, SUR LA TÊTE DE LA JONCTION.** `dart format` : **1 198** fichiers
Dart écrits à la main, tous conformes. `flutter analyze lib test
integration_test` : **7 534 remarques, 0 erreur, 0 avertissement**, toutes de
sévérité *info*. `flutter test` : **4 169 verts, 2 ignorés, 0 échec**, et le
compte **tombe juste à l'unité** — 4 092 (build 10, remesurés par moi sur
`a06f5000`) + 27 (les trois fichiers de test de P1) + 52 (les cinq gardes de la
recette) − 2 (un cas *généré par écran* en moins dans `tout_ecran_a_une_route`
et `aucun_geste_mort`, l'écran `/booking` ayant disparu) = **4 169**.
`build_runner` : 2 593 sorties, puis `git status` **vide**. Audit rapide : **un
seul compteur monte**, ECR-23 de **208 à 214**, exactement ce que P1 annonçait ;
ECR-28 tient à **195** ; tous les autres tiennent ou baissent (ECR-16 418→417,
MORT-01 141→140, ECR-19e 48→47, VAC-02 36→34). `test/structurel/` : **211
verts, 0 échec**, dont les onze gardes — `la_doc_ne_mente_pas` comprise, et
**sans remesure**.

**LES ÉCRANS : 58 CAPTURES SUR 65 IDENTIQUES AU PIXEL HORS BARRE D'ÉTAT, ET LES
7 ÉCARTS SONT TOUS NOMMÉS.** Deux arbres jetables sur le même émulateur, la
**recette identique au fichier près des deux côtés** (le diff
`integration_test/` + `tool/` entre les deux arbres est vide), de sorte que
seuls les 24 fichiers `lib/` de P1 distinguent le produit. **Deux écarts sont
l'écart ANNONCÉ, et ce n'est pas une régression** : météo d'étape
(`S1E_25_meteo`, 11 020 px) « 21° / 14° » devient « 21 / 14 °C », et tuile
météo du cockpit (`26_cockpit_fin`, 2 624 px) « 14° / 21° » devient
« 14 / 21 °C » — l'unité écrite une seule fois, règle du SI. **Les cinq autres
ne touchent pas le produit** : barre d'outils du clavier Gboard présente d'un
seul côté, qui remonte tout le dialogue (`31_journal_note_saisie`, 1 200 014 px,
contenu applicatif identique) ; bandeau fugace « Fiche enregistrée », 4 s de vie
(`09c`, 153 071 px) ; course de démarrage, « Test starting… » du harnais
(`01_boot`, 15 298 px) ; barre de navigation système sur 10 px de haut (`12b`,
3 104 px) ; heure de la note dans le contenu, 15:12 contre 14:30 (`32`,
1 406 px). **Deux précisions utiles** : la « fiche conseil » (`tips_screen`) et
l'écran « risque incendie » (`fire_risk_screen`) **n'affichent aucune
température** — les cinq écrans du mandat se ramènent en réalité à deux,
l'écran météo (cinq des sept affichages) et le cockpit (les deux autres) ; et la
capture `07c_cockpit` s'arrête **au-dessus de la ligne de flottaison**, la tuile
météo n'y est pas, c'est `26_cockpit_fin` qui la porte.

**CE QUE SEUL L'APPAREIL POUVAIT DIRE** (scénario `qa_690_produit_p1_test.dart`,
**non commité**, joué des deux côtés) : **12 exigences tenues, 0 échouée** côté
APRÈS. `/booking` poussé pour de vrai dans le routeur est **refusé et nommé**
(page introuvable) et **aucune miette `screen:booking` n'est émise** ; côté
AVANT la même exigence **échoue**, la route existant encore. Une clé héritée
**en ENTIER** écrite dans le **magasin natif** d'Android : côté APRÈS elle se
replie sur `celsius` et **les sept autres réglages tiennent** (langue `en`,
thème `light`, distance `mi`, peau, main dominante, cache, taille) ; côté AVANT
le test **meurt** sur `type 'int' is not a subtype of type 'String?'`. Enfin,
l'unité **persistée** arrive jusqu'à l'écran météo **convertie** : « 70 / 57 °F,
69 / 59 °F, 68 / 57 °F », et **plus aucun °C**. *Réserve honnête* : le cycle
« choisir, tuer l'application, relancer » n'est pas joué de bout en bout —
`flutter test` efface les données entre deux fichiers (mesure du 04/10 citée en
tête de `temperature_676_a_choix_test.dart`), et l'APK de debug lancé seul par
`am start` n'a pas dépassé son écran d'attente en deux minutes. La persistance
est donc prouvée **par le magasin natif relu à poignée neuve**, pas par une mort
de processus.

**LES PERSONAS, AU CHIFFRE DE RÉFÉRENCE, ET ZÉRO RUN PERDU.** S1 Léa **61/2**
(les deux connues : CTA « Démarrer la randonnée » absent de l'arbre, diplôme qui
ne s'ouvre pas), 65/65 captures ; S2 Marc **20/0**, 20/20 ; S3 Steve **17/1** (le
même diplôme), 44/44 ; S4 Inès **8/0 sur 8 évaluées** — et non 8/1 sur 9, parce
que `gr-pyrenees` est passé en statut **« draft » dans la liste distante** : le
pas qui portait l'exigence échouée n'est plus joué, c'est une donnée distante et
pas une correction ; S8 démo **29/1**, 11/11 ; traversée 645-09 **« All tests
passed »**, 16/16 ; douze tours de pile **« All tests passed »**, dictionnaire
de miettes identique à la référence (journal 13, settings 12, les quatre autres
à 1) — **la clé `screen` suit bien l'écran visible**. **Logcat : 131 885 lignes
lues, 0 plantage, 0 ANR, 0 mort non demandée, 0 exception Dart de
l'application**, et **aucune miette `booking` sur aucun run**.

**UN SEUL CONTRÔLE DE FIN DE RUN EST ROUGE, ET IL DIT VRAI.** S3 :
`11_apres_terminer` = `17_recap_apres_trek`, doublon non toléré. Ce n'est pas
une image périmée (retard marqueur→capture **0 ms**, machine calme à 2,88) :
c'est la **face visible du défaut connu** que S3 signale par ailleurs, « le
diplôme ne s'ouvre pas après un trek terminé » — l'écran ne change pas, donc
l'image non plus. Mesure qui le prouve : sur le run de référence **sans P1**,
ces deux captures diffèrent de **612 px au total et de 0 px hors barre d'état**,
c'est-à-dire par la seule horloge. Le fichier de tolérances **n'a pas été
élargi** : on ne négocie pas avec un rouge pour le faire taire.

**ET LA RECETTE A FAIT SES PREUVES, MESURE À L'APPUI.** Sur les huit runs,
**sept** ont vu l'accueil **après 10 000 ms** (jusqu'à 16 127 ms ; seul S1 à
8 101 ms passait sous l'ancien seuil) : l'ancienne recette, avec son délai fixe
de dix secondes, aurait déclaré « onboarding absent » et **perdu sept runs sur
huit**. La gate de charge a retenu des runs jusqu'à **373 s** le temps que
l'émulateur redescende sous 3, et la coupure Bluetooth plus le pré-build
PRC-003 ont été vus à l'œuvre dans chaque journal.

**CE QUI A COÛTÉ UN RUN, ET CE N'EST NI L'UN NI L'AUTRE LOT.** Le premier run
AVANT a perdu 18 captures sur 65 : le démon de captures a été **abattu par le
chien de garde de la machine** à 15:58:30 (règle PRC-003). Cause racine
mesurée : l'instance **en cours d'exécution** de la tâche planifiée
`Skynet-Watchdog` portait le code **d'avant** le correctif de la tâche 688
(commit `8d6353b6`) — le libellé qu'elle écrivait dans son journal n'existe plus
dans `scripts/skynet_watchdog.py`, dont la liste `MARQUEURS_EXCLUSION` exclut
déjà `persona` et `capture`. Le chien de garde périmé a été arrêté à 16:57 et
remplacé par celui du lot L6 ; **tous les runs postérieurs sont complets**, et
le run perdu a été **rejoué**, pas deviné.


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

**CORRECTION DU 03/10/2026 — LE C9 DE CETTE FICHE N'EST PLUS LE CRITÈRE.** Cette
fiche a été écrite avant l'arbitrage, et son C9 demande « zéro import socle →
feature, zéro croisement hors `lib/domain/` ». Ce zéro-là n'était pas atteignable
par du rangement, et c'est la mesure qui l'a dit, pas une renonciation : 51 des
72 flèches socle → feature sortaient du seul routeur, et 130 des 182 croisements
visaient de l'état Riverpod partagé. Christophe a tranché les trois arbitrages le
**03/10/2026** (voir le bloc « LES TROIS ARBITRAGES SONT TRANCHÉS » ci-dessus), et
les critères réels sont désormais **les trois plafonds mesurés** de
`test/structurel/couches_respectees_645_test.dart` : socle → feature **21**
(routeur exclu), croisements **52** (façades exclues), socle → métier **0**. Les
deux cas isolés #X62 et #X63 restent, eux, corrigés comme la fiche l'exigeait.

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

#### Ce que les vagues 1 et 2 ont réellement produit (03/10/2026)

**Chiffres mesurés.** Départ à `4966a85a` : ECR-15 = **52**, ECR-28 = **203**
(la fiche annonçait 50 et 206, les deux étaient faux). Arrivée après les deux
vagues : ECR-15 = **48**, ECR-28 = **198**. `ECR-23` (254), `ECR-19` (10),
`ECR-31` (19) et `VAC-01` (0) sont inchangés : un découpage ne déplace aucun
import et ne touche aucune valeur.

**La vague 2 a été faite en fichiers `part`, et c'est une convention
nouvelle.** Les cinq plus gros fichiers n'ont pas été éclatés en bibliothèques
séparées mais scindés en **fichiers `part` d'UNE SEULE bibliothèque Dart** :
une racine qui porte la documentation, `library;`, tous les imports et les
directives `part`, puis des morceaux qui n'ont pas d'imports à eux. 29 morceaux
créés. Raison : l'état et les widgets privés d'un écran se voient entre eux
sans rien exposer publiquement, donc le découpage ne change ni l'API ni le
comportement. **Conséquence qui n'est pas un détail : l'unité à lire n'est plus
le fichier mais la bibliothèque.** Toute garde qui mesure du texte source doit
lire la racine ET ses morceaux, sinon elle ne lit plus que des imports.
**Cette convention est soumise à l'arbitrage de Christophe** — elle n'était pas
prévue par la fiche, qui ne parlait que de sous-widgets nommés.

**Deux résidus restent au-delà de 500 lignes**, et c'est assumé :
`monetization_service_service.dart` (965) et `health_info_screen_etat.dart`
(579). Les deux sont des classes à état irréductibles : les découper plus
demanderait de déplacer l'état, ce que la méthode imposée interdit
explicitement (« L'ÉTAT RESTE CHEZ LE PARENT »).

**Une garde négative a été réparée en local, hors du lot cloud.** La scission
avait vidé la racine `map_screen.dart` (1236 lignes → 62, imports seuls) alors
que `test/features/map/cadrage_et_forme_558_test.dart` y lisait encore une
ABSENCE en direct : la garde ne pouvait plus jamais rougir, et le voisinage
qu'elle surveille avait déménagé dans `map_screen_barres.dart`. Elle lit
désormais la bibliothèque entière. Aucune attente modifiée. Vérifié par
mutation en bac à sable : le laïus injecté dans un morceau est invisible à
l'ancienne lecture et vu par la nouvelle.

#### Ce que le 645-06b a fait (04/10/2026)

**L'arbitrage est tranché.** Décision de Christophe du 03/10/2026, 22:12,
verbatim : « Moi je veux que se soit propre et aux normes ». La convention des
fichiers `part` est REFUSÉE, pour les cinq bibliothèques comme pour les deux
résidus : pas d'exception. Elle est inscrite en **règle 12** de
`docs/conventions.md` (« Pas de `part` hors code généré ») et gardée à ZÉRO par
`test/structurel/pas_de_part_645_test.dart`.

**Chiffres mesurés.** Départ à `aed4a3d8` (645-09b, jonction 645-09 comprise) :
29 morceaux `part of` hors code généré, ECR-15 = **48**, ECR-28 = **198**,
ECR-23 = **233**, ECR-19 = 10, ECR-31 = 19, ECR-05 = 77, VAC-01 = 0, en-têtes
100 %, observabilité 63/63, `flutter test` 4081 passés et 2 ignorés. Arrivée :
**0** `part of` hors code généré, ECR-15 = **46**, ECR-28 = **195**, ECR-23 =
**236**, ECR-19 = 10, ECR-31 = 19, ECR-05 = 77, VAC-01 = 0, en-têtes 100 %,
observabilité 63/63 ; plafond `plafondFichiersTropLongs` abaissé de 48 à 46.

**ECR-23 monte de trois, et c'est dit.** Les trois sont des imports de FAÇADE
(`map_facade.dart`, lu par quatre fichiers de la carte au lieu d'un) : la
règle 10 les autorise et la garde des couches, qui ne compte pas les façades,
reste à 52. L'audit, lui, les compte. Les ramener à un seul fichier aurait
demandé soit un fichier de plus de 500 lignes, soit de remonter les lectures de
providers des sous-widgets vers l'écran — donc de changer leur périmètre de
reconstruction, ce que le lot interdit. Aucun import hors façade n'a été
dupliqué.

**Les fichiers créés.** Noms anglais (IDE-001), chacun avec ses imports :
- formule (`lib/domain/`) : `feasibility_types`, `feasibility_scale`,
  `feasibility_stages`, `feasibility_assessment`, `feasibility_engine`,
  `feasibility_program_rules` ; `feasibility_formula.dart` les re-exporte ;
- monétisation (`lib/core/services/`) : `monetization_models`,
  `monetization_providers`, puis, pour le résidu, `monetization_dependencies`,
  `monetization_pricing`, `monetization_entitlements`,
  `monetization_subscription`, `monetization_rewards`, `monetization_access`,
  `monetization_purchases` ;
- faisabilité : `feasibility_guided_flow`, `feasibility_demo_inputs`,
  `feasibility_verdict_view`, `feasibility_advice`,
  `feasibility_verdict_sections`, `feasibility_summary`, `feasibility_tiles`,
  `feasibility_labels` ;
- carte : `map_content`, `map_sheets`, `map_overlays`, `map_photo_button`,
  `map_arrival_pipeline`, `map_controller` ;
- fiche médicale : `health_info_form`, `health_info_fields`,
  `health_info_advice`, `health_info_inputs`, `health_info_top_sections`,
  `health_info_bottom_sections`, puis, pour le résidu, `health_info_form_data`
  et `health_info_dialogs`.
Les widgets privés lus par un autre fichier sont devenus des classes publiques
nommées, à paramètres nommés et avec `super.key` ; aucune façade de feature ne
re-exporte quoi que ce soit de nouveau.

**Les deux résidus.** `MonetizationService` (965 lignes) est devenu une façade
de 330 lignes, derrière la même API publique, composée de six collaborateurs
(prix, droits, abonnement, récompense, accès, achats) ; `buyTrail` (122 lignes)
est lu en trois temps, pas à pas identiques. L'état de la fiche médicale (577
lignes) garde le chargement, l'enregistrement, l'effacement et le `build` ; ses
valeurs en édition vivent dans `HealthInfoFormData`, ses deux dialogues dans
`health_info_dialogs.dart`. AUCUN état n'est descendu dans une section : chaque
contrôleur est lu à l'enregistrement, écrit au chargement et vidé à
l'effacement par l'écran, aucun n'est local à la section qui l'affiche. Plus
aucun fichier des cinq anciennes bibliothèques ne dépasse 500 lignes, et plus
aucune fonction des deux résidus ne dépasse 60.

**La miette de la carte et de la fiche médicale** vit désormais dans le fichier
qui porte la classe de l'écran, posée à l'entrée (`initState`).
`observabilite_des_ecrans_645_test.dart` ne lit plus que ce fichier ;
`cadrage_et_forme_558_test.dart` lit la carte avec ses bibliothèques voisines.
Aucune attente n'a bougé ; les deux gardes rougissent encore par mutation
(miette retirée, laïus injecté dans deux voisines différentes).

**Les deux `@override` en double** de la vague 1 avaient déjà été retirés par
`6b91325` (fix(645-06)), présent dans la base : rien à faire.

##### QA du 645-06b, partie code (04/10/2026, 17:26 UTC — Artemis, session cloud)

**Périmètre.** Branche vérifiée `claude/chore/645-06b-bibliotheques-4xyqxt`
à `2aca5db9` (9 commits sur `aed4a3d8`). Jonction faite sur la branche de QA
`claude/qa/645-06b-jonction`, partie de l'intégration à `d48d2fd8` (build 9,
version 0.1.5+9) : fusion `80698cf8`, sans avance rapide, **aucun conflit**
(la fiche s'est fusionnée seule, les deux paragraphes sont gardés).
L'intégration elle-même n'est pas touchée, aucun tag.

**Verdicts de lecture (E1) — six OK, aucun AFFAIBLI.**
- (a) OK : les 63 fichiers du diff sont tous sous `lib/domain`,
  `lib/core/services`, `lib/features/feasibility`,
  `lib/features/trek/presentation/map`, `lib/features/safety/presentation`,
  `test/` ou `docs/`. Rien sous `tool/`.
- (b) OK : `part of` écrits à la main 29 → **0** ; directives `part` hors
  `.g.dart` / `.freezed.dart` → 0 (les 114 restantes visent du code généré).
  Garde `pas_de_part_645_test.dart` prouvée par mutation : `part` ajouté dans
  `feasibility_formula.dart` → rouge ; `part of` ajouté dans
  `health_info_dialogs.dart` → rouge ; restauré, zéro diff. Limite notée, sans
  effet : un `part "x.dart";` entre guillemets doubles échappe au motif de la
  racine, mais le morceau qu'il viserait porte forcément un `part of`, que la
  garde voit quelles que soient les guillemets (mutation faite : rouge).
- (c) OK : API publique de `MonetizationService` comparée PAR PROGRAMME
  (analyseur Dart résolu, avant `aed4a3d8` / après `2aca5db9`) : 45 lignes
  identiques — constructeur et ses 10 paramètres nommés (5 requis), 4
  accesseurs, 39 méthodes, signatures et types compris. Les 23 noms exportés
  par la bibliothèque `monetization_service.dart` sont identiques aussi : aucun
  collaborateur n'est exporté. `buyTrail` relu côte à côte : même suite
  d'appels et d'`await` (démo, `await ownsTrail`, gratuit, prix au catalogue,
  `await _quote`, `await debit`, complément : `await _isOnline` puis rollback,
  ou `await rechargeWallet` puis rollback ; sinon `await markOwned`) ; seul
  ajout, un cadre `async` de plus (`_refusal`), sans effet sur l'ordre.
  `HealthInfoFormData` : `fill`, `compose`, `clear`, `dispose` reprennent
  ligne à ligne l'ordre de l'ancien état ; aucune section n'a d'état (toutes
  `StatelessWidget` / `ConsumerWidget`, zéro `setState` hors de l'écran).
- (d) OK : 71 symboles devenus publics (ou nouveaux) ; aucun n'apparaît dans
  les 20 `*_facade.dart`, qui n'exportent que des `providers/`. Les +3 d'ECR-23
  sont exactement trois imports de `map/map_facade.dart` (par `map_content`,
  `map_overlays`, `map_photo_button`) ; tous les autres croisements ont
  seulement changé de fichier, un pour un.
- (e) OK : les 12 tests adaptés ne changent que des imports, des chemins, un
  nom (`_CollecteDeLaDemo` → `FeasibilityDemoInputs`) et l'aide de lecture
  (`_sourceAvecSesParts` → `_sourceAvecSesVoisines`, qui suit les imports du
  même dossier) ; aucune attente modifiée. Vérifié que les lectures couvrent
  toujours tout l'ancien code : chaque ancienne bibliothèque est entièrement
  lue par la nouvelle aide (carte 8 fichiers, faisabilité 9, fiche médicale 9,
  monétisation 13), et les trois marqueurs de position du test 638 sont dans
  le même fichier. Les listes de fichiers autorisés (647, journal) suivent le
  découpage sans s'élargir à un fichier hors du service. Le plafond 48 → 46 est
  un resserrement. Les 2 tests nouveaux (`pas_de_part_645_test.dart`) lus en
  entier.
- (f) OK avec correction de l'annonce : +101 infos nettes (7 513 → 7 614 sur
  la tête jointe), mais elles ne sont PAS toutes `public_member_api_docs` :
  +70 `public_member_api_docs`, +32 `directives_ordering`, +5
  `unnecessary_import`, +1 `prefer_const_constructors`, −7
  `lines_longer_than_80_chars`. Tolérées (décision « ok infos »).
  `public_member_api_docs` par fichier (nouveaux) : `health_info_fields` 19,
  `feasibility_tiles` 9, `feasibility_verdict_sections` 6,
  `health_info_advice` 5, `feasibility_advice` 4, `feasibility_summary` 4,
  `health_info_top_sections` 4, `map_content` 4,
  `health_info_bottom_sections` 3, `feasibility_demo_inputs` 2,
  `feasibility_verdict_view` 2, `health_info_form` 2, `health_info_inputs` 2,
  `map_overlays` 2, `feasibility_guided_flow` 1, `map_arrival_pipeline` 1,
  `map_photo_button` 1 (71), moins 1 disparu avec
  `monetization_service_service`. Les `unnecessary_import` (+5 nets : un
  dans chacun de six fichiers de la fiche médicale, `advice`, `fields`,
  `form`, `inputs`, `top_sections`, `bottom_sections`, celui de l'ancien
  écran ayant disparu) sont un nettoyage à faire dans un lot de code : la QA
  ne touche pas `lib/`.

**Gate sur la tête jointe `80698cf8`.** `dart format` : 1 306 fichiers, 0
changé. `flutter analyze --no-pub --no-fatal-infos` : 0 erreur, 0 warning,
7 614 infos. `flutter test` : **4 088 passés, 2 ignorés, 0 échec** (base
`d48d2fd8` : 4 086). `build_runner build --delete-conflicting-outputs` puis
`git status` : aucun fichier changé. `audit_global.py --rapide`, base →
jointe : ECR-15 48 → **46**, ECR-28 198 → **195**, ECR-23 233 → **236**,
ECR-19 10, ECR-31 19, ECR-05 77, VAC-01 0, OBS-01 0, observabilité 63/63,
en-têtes 100 %, MORT-01 141 (inchangé). Un compteur monte en plus d'ECR-23,
et c'est dit : **ECR-16 409 → 416** (avertissement, fichier de `lib/` sans
test miroir du même nom), purement mécanique — ce sont les nouveaux fichiers
des bibliothèques découpées, couverts par les mêmes tests qu'avant.

**L'écart ECR-23 à 236 est accepté par Skynet.** Les trois sont des imports
de FAÇADE, permis par la règle 10 ; la garde des couches reste à 52. Les
ramener à un seul fichier demandait un fichier de plus de 500 lignes ou de
remonter les lectures de providers vers l'écran, donc de changer le
périmètre de reconstruction.

**Mutations rejouées sur la tête jointe**, rouges chaque fois, puis
restaurées, zéro diff : miette de la carte retirée de `map_screen.dart` →
`observabilite_des_ecrans_645_test` rouge ; laïus `t.map.statsPendingNote`
injecté dans `map_content.dart` (puis dans `map_overlays.dart`) →
`cadrage_et_forme_558_test` rouge ; `part` ajouté à `map_screen.dart` →
`pas_de_part_645_test` rouge.

##### QA du 645-06b, partie écrans (04/10/2026, 21:45 — Artemis, émulateur local)

**Périmètre et méthode.** Deux arbres de travail jetables sur le même
émulateur (`emulator-5554`, 1080×2400, Android 14), même mode local, même
thème, **installation vierge à chaque run** (recette réparée de la tâche 676,
désinstallation du paquet contrôlée avant chaque scénario) : AVANT sur
l'intégration `d48d2fd8` (build 9), APRÈS sur la branche de QA
`claude/qa/645-06b-jonction` à `aa00623b`. Cinq scénarios joués **des deux
côtés, dans le même ordre** : S1 Léa, S2 Marc, S3 Steve, traversée 645-09, et
un scénario écrit pour cette QA (`qa_679_portefeuille_test.dart`, non commité)
qui ouvre par la route les deux écrans qu'aucun persona ne traverse —
`/wallet` et `/subscription` — et qui **joue une recharge**. Dix runs, zéro
marqueur sans image, **retard de capture 0 ms partout**.

**Comparaison au pixel : 148 captures comparées, 136 identiques AU PIXEL,
12 écarts tous nommés — et aucun imputable au code.** La barre d'état est
exclue (bande du haut, 85 px : l'horloge y bouge sur *toutes* les captures,
écart mesuré 500 à 1 100 px par image, boîte `y 47..79`).

| scénario | comparées | identiques au pixel | écarts |
|---|---|---|---|
| S1 Léa | 65 | 61 | 4 |
| S2 Marc | 20 | 19 | 1 |
| S3 Steve | 44 | 39 | 5 |
| traversée 645-09 | 16 | 14 | 2 |
| portefeuille / abonnement | 3 | **3** | **0** |

Les douze écarts, un par un, avec les deux captures (scratchpad `645-06b/`) :
- **Horloge dans le contenu** (5 captures) : `S1_32` et
  `S3_16_journal_note_enregistree` (heure de la note, 18:58 → 19:25),
  `S1E_25_meteo` et `T645_07_meteo` (« mis à jour à », 18:54 → 19:21),
  `S3E_26_incendie` (idem, 19:06). Boîtes de 122 à 1 473 px.
- **Bandeau fugace** (2 captures) : `S1_09c` et `S3E_37d_health_saved`, 153 000 px dans
  la **seule** bande `y 2195..2336` — le bandeau vert « Fiche enregistrée »,
  vivant 4 s, encore là d'un côté, déjà parti de l'autre. **Au-dessus de la
  bande, les deux images sont identiques au pixel.**
- **Image d'animation** (4 captures) : `S1_31` et `S3_15_journal_note_saisie`
  (le bouton flottant du journal en cours d'effacement derrière la boîte
  modale, plus 3 108 px de bord de clavier en bas),
  `T645_12_secours` (le rouage « Acquisition GPS » à un autre angle),
  `S2_01_boot` (97 % : l'écran « Test starting… » du harnais d'un côté,
  l'écran de démarrage de l'app de l'autre — deux instants du même boot).
- **Décalage d'un pixel du déroulant** (1 capture) : `S3E_37c_health_saisie`, 22 755 px.
  **Prouvé, pas supposé** : l'en-tête fixe donne **0 px**, le clavier donne
  **0 px**, et la bande `y 295..355` du déroulant tombe à **exactement 0 px**
  quand on décale l'image APRÈS d'**un** pixel vers le bas. Mêmes glyphes,
  posés un pixel plus bas : la position d'arrêt du défilement, pas le code.
- **`S1_09c`** compte double ci-dessus (bandeau) ; le douzième écart est la
  bande basse du clavier de `S1_31` (3 108 px, `y 2363..2373`).

**Preuve statique en complément, jeton par jeton.** Un lot qui *déplace* du
code ne se juge pas sur un diff ligne à ligne (fichiers supprimés puis
recréés). Le multi-ensemble de tout ce qui peut se voir a donc été compté des
deux côtés sur **tout `lib/`** : **1 443** occurrences de clés de traduction,
**199** `ValueKey`, **886** icônes `StepwaysIcons`, **2 376** constantes de
gabarit `AppTheme` — **zéro jeton dont le compte diffère**. Par zone touchée :
faisabilité 41/23/69/156, carte 57/0/21/45, fiche médicale 115/30/59/127,
monétisation 28 clés — zéro écart partout.

**Personas sur la tête APRÈS — identiques à la tête AVANT, exigence par
exigence.** S1 Léa **61 tenues / 2 échouées**, et ce sont **les deux connues**
(CTA « Démarrer la randonnée » absent de l'arbre ; diplôme qui ne s'ouvre pas
après un trek terminé) ; S2 Marc **20/20** ; S3 Steve **17/1** (le même
diplôme) ; traversée `traversee_645_09_test.dart` **verte**, 12 écrans peints,
pas de seconde miette au retour immédiat. Les mêmes chiffres, aux mêmes
endroits, sur `d48d2fd8`.

**Achat et recharge joués pour de vrai.** L'achat complet de S1 (mur payant
`19b1`, achat, `19b2_apres_achat`) et celui de S3 (`03b_apres_achat`) sont
passés des deux côtés, captures identiques au pixel. La **recharge** du
compte-étapes est jouée par le scénario de QA : les trois paquets (11, 25, 50)
sont présents, le solde est affiché, l'appui sur « 11 étapes » traverse
`rechargeWallet` dans le collaborateur *achats* et rend **la même branche des
deux côtés** — « Le paiement n'est pas disponible pour le moment. » (pas de
magasin réel sur l'émulateur). Les trois captures de `/wallet`,
du bandeau et de `/subscription` sont **identiques au pixel**.

**Journal local : les miettes partent, et elles partent à l'identique.** Les
deux écrans qui ont changé de fichier sont les plus surveillés : la carte
(`screen:map`, l'appel est passé de `map_screen_view.dart` à
`map_screen.dart`) et la fiche médicale (`screen:health_info`, passé de
`health_info_screen_etat.dart` à `health_info_screen.dart`). Sur les cinq runs
cumulés : `map` **3 / 3**, `health_info` **2 / 2**. Et le relevé complet est
plus fort que ça : **40 écrans distincts, et le dictionnaire des comptes de
miettes est identique caractère pour caractère entre AVANT et APRÈS**
(`hub` 41, `trek_feasibility` 8, `settings` 7, `trail_catalog` 7,
`adventure_recap` 6, `onboarding` 5, … `wallet_recharge` 1, `subscription` 1).

**Logcat : 0 plantage, 0 ANR, 0 exception** — sur les **dix** runs, 96 000
lignes lues (`main`, `crash`, `system`), recherche de `F/libc`,
`FATAL EXCEPTION`, `signal N (SIG…)`, `ANR in`, `am_anr`, `Input dispatching
timed out`, mort du processus `com.only1cent.stepways`, tombstone, et
exceptions Dart (`E/flutter`, `Unhandled Exception`).

**Ce qui n'est pas vert, et qui ne vient pas du lot.**
- Le **contrôle de fin de run refuse S1 et S3 des deux côtés** : des captures
  légitimement identiques (ticks GPS successifs sur une carte immobile,
  `23_apres_gps` = `25_apres_sos`) ne sont pas toutes déclarées dans
  `captures_doublons_tolerees.txt`, et le groupement change d'un run à
  l'autre. Les jeux de captures, eux, sont sains : 65/65 et 44/44, aucun
  manquant, aucun vide, aucune orpheline, retard 0 ms. **Dette de la recette
  de capture, pas du 645-06b** — et le refus tombe identiquement sur
  `d48d2fd8`.
- Le scénario de QA du portefeuille est tombé **rouge au teardown côté AVANT**
  (« A SemanticsHandle was active at the end of the test ») et **vert côté
  APRÈS**, après les trois captures et après les deux attentes. Rejoué une
  troisième fois sur `d48d2fd8` : plus d'erreur de sémantique du tout — c'est
  donc **intermittent, et dans mon harnais jetable** (non commité), pas dans le
  produit. Ce troisième run a en revanche montré une autre faiblesse du même
  harnais : sur un démarrage lent, la poussée directe vers `/wallet` part
  **pendant que l'accueil est encore à l'écran** et n'atteint jamais le
  compte-étapes (`packs=[]`). Les deux runs comparés, eux, ont bien atteint
  l'écran complet des deux côtés.
- **La QA a failli être impossible, et ça n'est pas un détail d'outillage.**
  `skynet_watchdog.py` (PRC-003, `_find_disk_hog`) **a tué le démon de
  captures** à 20:18:55 et le démon de dialogues à 20:13:32, run perdu, 0
  capture pour 52 marqueurs. Cause : le premier build Gradle d'un arbre neuf
  fait croître l'occupation du volume de 17 Go/h, au-dessus du seuil critique
  de 5 Go/h — et le tueur ne regarde **que** `python|node`, donc il abat le
  démon de captures (python) et jamais Gradle (java). Pire, `Get-Process` ne
  porte aucune propriété `IO` : le tri `$_.IO.WriteBytes` trie sur `$null` et
  `Select -First 1` rend **un processus au hasard**. PRC-003 n'abat donc pas
  le glouton, il abat un passant. Parade appliquée ici, dans mon périmètre :
  **pré-construire les APK avant d'allumer les démons**, puis attendre que la
  vitesse soit retombée avant chaque run. Le correctif du watchdog est
  hors périmètre QA (`scripts/` interdit à Artemis) : signalé en base.

**Verdict écrans : RIEN NE CHANGE À L'ÉCRAN.** Les quatre zones découpées
(faisabilité, carte, fiche médicale, monétisation) rendent le même pixel, le
même texte, les mêmes clés, les mêmes icônes, les mêmes miettes et les mêmes
verdicts persona qu'avant le lot. Rien n'est livré, rien ne touche `main` ni
l'intégration.

```
PROMPT 645-06 (autonome)

Depot Moteur-GR, JAMAIS GR20. Worktree neuf
.claude/worktrees/moteur-gr-645-06 sur claude/chore/645-06-decoupage depuis
la tete de origin/claude/integration/645-assainissement. git fetch d abord,
cd explicite dans chaque commande git. Ne remets JAMAIS le depot Skynet
racine sur main. Pose le tag avant-645-06-vague<N> AVANT la vague.

OBJET : ramener 52 fichiers sous 500 lignes et 203 fonctions sous 60 lignes.
(CHIFFRES CORRIGES le 03/10 apres les vagues 1 et 2 : la fiche annoncait 50 et
206 ; la mesure a 4966a85a, tete de depart reelle du lot, donne ECR-15 = 52 et
ECR-28 = 203. Arrivee mesuree apres les deux vagues : ECR-15 = 48,
ECR-28 = 198. ECR-23 254, ECR-19 10, ECR-31 19 et VAC-01 0 sont INCHANGES par
le lot, qui ne deplace pas d import et ne touche a aucune valeur.)

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
  1644 l. lib/domain/feasibility_formula.dart
          (CHEMIN CORRIGE le 03/10 : la fiche ecrivait
          lib/features/feasibility/domain/. Ce type a change de maison au lot
          645-05, voie A : il est lu par plusieurs features, il vit donc dans
          lib/domain/.)
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
| **C3 Description** | Renommer les identifiants en anglais. **Les commentaires et doc comments restent en français accentué.** Corrigé le 03/10 : « ce lot ne touche pas une ligne de commentaire » était **trop absolu et irréalisable** — un commentaire qui *cite* un identifiant renommé doit suivre, sinon il désigne un symbole qui n'existe plus. La règle juste est : **aucun commentaire réécrit, seules les citations de code mises à jour**. Mesuré sur le lot livré : 179 lignes de commentaire modifiées, toutes expliquées par une citation de code |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-07)* |
| **C6 Branche** | `claude/chore/645-07-code-en-anglais` |
| **C7 Commit** | un commit **par étape** : `refactor(645-07): etape <N>, identifiants en anglais dans <zone>` |
| **C8 Test** | `flutter test` → 4002 passés. `dart run build_runner build --delete-conflicting-outputs` puis `git diff` sur les générés : **seuls les noms de symbole changent**, aucun nom de champ sérialisé |
| **C9 QA** | Le diff des `.g.dart` et `.freezed.dart` ne montre aucun changement de nom sérialisé. Une base Drift écrite **avant** le lot se relit après. Aucune ligne de commentaire modifiée |
| **C10 Smoke** | Test de migration Drift : ouvrir une base écrite avant le lot. Essai sur émulateur : les préférences enregistrées avant sont relues après |
| **C11 Rollback** | `git revert <sha de l'étape>` — 4 commits. Tag `avant-645-07` avant l'étape 1 |
| **C12 Dépendances** | **645-01**, **645-04**, **645-05** (renommer avant d'avoir résorbé les doublons et stabilisé les emplacements, c'est renommer deux fois) |

#### 645-07 — ce qui a été fait, et ce que la mesure corrige (03/10/2026)

Lot livré en session cloud sur `claude/chore/645-07-code-en-anglais` (4 commits,
tête `2a819973`), fusionné sans conflit dans `claude/integration/645-assainissement`
(merge `6471f400`). Les chiffres ci-dessous sont **remesurés après la fusion**,
pas repris de la session qui a produit le lot.

**Les compteurs de la fiche étaient ceux du 02/10 et ont bougé avant que le lot
ne démarre.** Au départ réel : **464 identifiants** portant un mot français
(ECR-05) et **23 noms de fichier** français, et non 442 et 31. À l'arrivée :
**75 identifiants** et **0 nom de fichier**. **28 fichiers ont été renommés** :
25 sous `lib/` (dont 2 fichiers générés, `stage_variant.g.dart` et
`stage_variant.freezed.dart`, qui suivent leur source) et 3 sous `test/`
(`sentier_distant_marchable_606_test.dart`, `variante_etape_test.dart`,
`lien_vers_les_cartes_641_test.dart`).

**Les 75 identifiants qui restent ne sont pas un reste de travail — ils se
qualifient en trois familles, et deux d'entre elles n'ont rien à faire là.**
Première famille, **le vocabulaire du sentier, gardé volontairement** : `refuge`
(14), `fiche` (10), `gite` (8), `bivouac` (5) — soit 37 à eux seuls. Ce sont les
mots du métier ; les traduire ferait dire au code autre chose que ce qu'il
désigne. Deuxième famille, **les faux positifs de la mesure** : la liste de mots
de `tool/audit_global.py` contient `lot`, et la recherche est une recherche de
sous-chaîne — tout `slot` anglais est donc compté comme français
(`FollowerSlots`, `followerSlots`, `freeFollowerSlots`, `BannerAdSlot`,
`NuiteeSlot`, `buildNuiteeSlots`…), environ 17 occurrences. Troisième famille
seulement, **les vrais restes à traiter**, une quinzaine : `Parcours`, `cartes`,
`annuler`, `bouton`, `poids`, `pretesPoids`, `supprimer`, `supprimerAnnuler`,
`telecharger`, `etapes`, `etape`, `calculer`, `compteReafficher`,
`collecteProfil`, `collecteSentier`. Ils se répartissent sur 44 fichiers, dont
20 occurrences dans `lib/features/booking`.

**Un seul champ sérialisé a été gelé, et c'est le piège P1 qui a servi.** Dans
`lib/features/planning/models/stage_variant.dart`, le champ `selectionParEtape`
devient `selectionByStage` côté Dart, mais la clé écrite sur le téléphone reste
`selectionParEtape`, gelée par `@JsonKey(name: 'selectionParEtape')`. Le code
généré le prouve : `_$VariantSelectionToJson` émet
`{'selectionParEtape': instance.selectionByStage}`. Sans ce gel, la mise à jour
aurait fait perdre **silencieusement** le choix de variante du randonneur.
Cette annotation a un coût qui n'était pas prévu : l'analyseur la refuse sur un
paramètre de constructeur d'usine (`invalid_annotation_target`), ce qui rendait
`flutter analyze` rouge d'un avertissement. La règle est descendue à `info` dans
`analysis_options.yaml`, avec sa justification écrite sur place — elle mesure
toujours, elle ne bloque plus.

**La méthode annoncée n'est pas reproductible, et c'est à dire.** La session qui
a produit le lot rapporte avoir écrit un **lexeur Dart** pour distinguer un
identifiant d'une chaîne et d'un commentaire, et avoir joué les 4 étapes avec
lui. Ce lexeur **n'a été versé nulle part** : aucun fichier n'est ajouté par les
4 commits du lot. Le résultat est vérifiable, la méthode ne l'est pas — un
prochain lot de renommage repartira de zéro ou devra redemander l'outil.

**Une garde était devenue muette, et elle a été réparée.**
`test/comportement/cartes_hors_ligne_622_test.dart` surveillait que
l'ordonnanceur de synchronisation ne cite pas `descente_des_cartes`. Le lot a
renommé ce fichier en `map_downloader.dart` sans mettre la chaîne surveillée à
jour : la garde cherchait alors un nom qui n'existait plus nulle part et passait
au vert quoi qu'il arrive. Prouvé par mutation : avec l'ancienne chaîne, un
import de `map_downloader.dart` injecté dans l'ordonnanceur passe **vert** ;
avec la chaîne corrigée, il passe **rouge**.

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

### 645-09 — Poser l'observabilité sur les 63 écrans nus

> **FAITS CORRIGÉS APRÈS LE LOT — mesuré par Artemis le 04/10/2026 (tâche 669).**
> Les lignes C2, C3 et C8 ci-dessous, et le bloc PROMPT 645-09, gardent leurs
> chiffres d'origine : ils sont l'archive de ce qui a été commandé. Les faits
> justes sont ici.
>
> **LE POINT DE DÉPART DE CETTE FICHE ÉTAIT FAUX**, et il faut le dire parce que
> tout le dimensionnement du lot en dépendait. Point de départ réel :
> **ZÉRO écran instrumenté sur 63**, pas 9 sur 63 (14,3 %). Les « écrans déjà
> équipés » étaient un **faux positif de la mesure** : la liste de marqueurs de
> `tool/audit_global.py` contient `log(`, qui est une **sous-chaîne de
> `AlertDialog(`**. Mesure refaite sur la tête 6f747bf0 : l'audit comptait **8**
> écrans équipés (12,7 %, et non 9 — le 9e avait quitté la mesure avec le
> renommage du 645-07), et les 8 sont expliqués un par un : 4 fois
> `AlertDialog(`, 2 fois `_showAddNoteDialog(` / `_showResetDialog(`, 1 fois
> `_goToCatalog();` — et 1 fois `ErrorHandler.log(`, un vrai appel de journal,
> mais pas une miette d'entrée d'écran. **Aucun des 63 écrans ne disait son nom
> à un rapport de plantage.**
>
> **CE QUI A ÉTÉ FAIT : 63 écrans sur 63**, et non 54. **23 miettes dans
> `initState`** (écrans à état), **40 en première instruction de `build`**
> (écrans sans état, où le service déduplique, si bien que les deux
> emplacements rendent la même chose : une miette par entrée, pas par
> reconstruction). La clé `trail` est alimentée par **23 écrans**, la clé
> `stage` par **4** : `trail_stage_detail`, `trek_stage_detail`,
> `accommodation_detail`, `weather` — les seuls qui portent déjà un numéro
> d'étape en champ, donc **sans une seule lecture de provider nouvelle**. La
> carte, elle, n'alimente volontairement pas `stage` : le numéro d'étape vit
> dans un provider, et le lire à l'entrée le ferait naître une frame plus tôt
> qu'aujourd'hui.
>
> **DEUX MIETTES SONT POSÉES À LA MAIN**, la carte et la fiche médicale, parce
> que le 645-06 a scindé ces deux écrans : la classe et l'état vivent dans un
> fichier `part` (`map_screen_view.dart`, `health_info_screen_etat.dart`) alors
> que l'audit compte comme « écran » le fichier racine. La constante est donc
> **déclarée dans la racine**, où la mesure la voit, et **l'appel posé dans le
> morceau qui porte l'état**, où l'écran entre vraiment.
>
> **ANONYMISATION DE `trail`, EN UNE PHRASE** : la valeur part en **SHA-256
> hexadécimal de ses octets UTF-8** (`AnalyticsService.anonymize`), et la
> transformation est appliquée **à l'intérieur de `enterScreen`**, pas chez
> l'appelant — aucun des 23 écrans ne peut donc poser un identifiant en clair,
> même par erreur, et les 23 passent tous un champ `trailId`, jamais un titre.
> La clé `stage` ne porte qu'un entier, jamais un nom de lieu, et elle est
> bornée à 64 caractères. La fiche médicale ne transmet **que son nom d'écran** :
> ni donnée de santé, ni texte saisi, ni identifiant de profil.
>
> **25 TESTS AJOUTÉS** dans 4 fichiers — 4050 cas à la tête 6f747bf0,
> **4075 passés, 2 ignorés, 0 échec** après le lot :
> `screen_entry_test.dart` (12), `screen_breadcrumb_test.dart` (6),
> `observabilite_des_ecrans_645_test.dart` (6, la **garde OBS-01**),
> `observabilite_inerte_645_test.dart` (1, balayage des routes du vrai routeur
> avec un puits qui lève à chaque geste).
>
> **LA GARDE OBS-01 EST VIVANTE — 3 MUTATIONS REJOUÉES EN LOCAL, ROUGES LES
> TROIS FOIS** : miette retirée de `weather_screen`, 2 tests rouges ;
> `checklist_screen` qui nomme son voisin, rouge avec « attendu checklist,
> trouve tips » ; miette du hub déplacée de `initState` vers `build`, rouge avec
> « hors de initState alors que l écran a un etat ». Plafond à **0 écran nu**,
> marge zéro.
>
> **ECR-18 (119 → 125), EXPLICATION EXHAUSTIVE** — et ce n'est pas du « bruit de
> numéros de lignes » : 8 blocs répétés apparaissent, 2 disparaissent, et **les
> 8 sont des blocs de lignes d'`import`**, parce que le nouvel
> `import screen_entry.dart` crée des en-têtes identiques dans 63 fichiers.
> **Aucun** des 8 ne contient la miette : la mesure ECR-18 ignore les
> commentaires, et la ligne d'appel diffère par le nom d'écran.
>
> **UNE LIGNE À CORRIGER DANS L'AUDIT, ET PAS DANS CE LOT** :
> `tool/audit_global.py`, constante `APPELS_CRASHLYTICS`, contient `log(`. Le
> lot ne l'a pas touchée — la mesure passe bien à 63/63, mais grâce au marqueur
> `Breadcrumb`, pendant que `log(` continue de compter tout `AlertDialog(`.
> À reprendre dans un lot outillage avec un marqueur précis
> (`observeScreenEntry(`). Même famille, trouvée au passage : ECR-05 monte de 75
> à 77, et les deux sont le **même jeton `walletRecharge`**, faux positif du mot
> `charge` cherché en sous-chaîne.
>
> **TROIS RÉSERVES DE DOCUMENTATION, À REPRENDRE** (zéro effet à l'exécution,
> relevé exhaustif : les 65 points d'insertion du lot ont été passés au peigne,
> il y en a trois et pas une de plus). Dans `health_info_screen.dart`, la
> constante `_breadcrumb` a été insérée **entre le commentaire de doc et la
> classe**, si bien que la phrase « les données ne quittent JAMAIS le
> téléphone » documente désormais une constante privée et que
> `HealthInfoScreen` n'a plus de documentation. Dans
> `trek_feasibility_screen.dart`, le pavé qui expliquait la remontée des deux
> observations **en tête de `build`** documente maintenant `initState`. Dans
> `my_treks_screen.dart`, la ligne « Barre contextuelle de l'accueil maison
> (SPEC §4) » documentait `buildContextualActions` et documente maintenant
> `initState`. C'est la même famille que la garde morte du 645-06 : un
> commentaire qui a changé de propriétaire sans que rien ne proteste.
>
> **UN DÉFAUT DE VALEUR** : `accommodation_detail_screen.dart` passe
> `stage: '$stageNumber'` alors que le champ est `int?`. Quand il est absent, la
> clé vaudra la chaîne `"null"` pendant que l'écran affiche l'étape 1
> (`stageNumber ?? 1`).
>
> **LE DÉFAUT QUI COMPTE, TROUVÉ SUR L'ÉMULATEUR ET REPRODUCTIBLE À COUP SÛR :
> QUAND LA PILE DE NAVIGATION EMPILE, LA CLÉ `screen` NOMME LE MAUVAIS ÉCRAN.**
> La déduplication ne retient que **la dernière** empreinte posée
> (`_lastEntry`). Or `Navigator` **reconstruit les écrans restés vivants sous
> celui du dessus** : les 40 écrans instrumentés **dans `build`** reposent donc
> leur miette à chaque empilement, à tour de rôle. Mesure, traversée du
> 04/10 (`integration_test/traversee_645_09_test.dart`, 14 routes empilées sans
> retour) — après l'ouverture de `/settings`, le journal porte dans l'ordre :
> `screen:settings`, puis `screen:trail_stage_detail`, puis `screen:weather`,
> puis `screen:journal`. **La dernière miette, et donc la valeur de la clé
> `screen` au moment d'un plantage, désigne un écran que le randonneur ne
> regarde pas.** Le motif se répète à l'identique aux 12 ouvertures de la
> traversée. Les 23 écrans instrumentés dans `initState` n'y participent pas
> (`initState` ne tourne qu'une fois par montage), et le parcours persona S1 le
> masque presque entièrement parce qu'il **revient au cockpit** entre deux
> écrans, ce qui dépile. Conséquences : aucun plantage, aucune donnée
> personnelle, budget toujours borné par le plafond de 256 miettes par session
> — mais **la promesse du lot (« savoir sur quel écran est le randonneur »)
> n'est pas tenue dès que deux écrans `build` restent vivants sous la pile.**
> Direction de correctif, à décider hors QA : ne poser la miette que si l'écran
> est la route **courante** (`ModalRoute.of(context)?.isCurrent == true`), ou
> dédupliquer par écran vivant au lieu de la seule dernière empreinte.
>
> **LE « JOURNAL LOCAL » N'EST PAS UN FICHIER** : c'est la console (`logger`
> 2.7.0, `ConsoleOutput` vers `print`, donc logcat), d'où **ni taille maximale
> ni rotation à prévoir sur le téléphone** — et, filtre `DevelopmentFilter`
> oblige, **rien n'est écrit en build release**. La trace `screen:<nom>` est donc
> une preuve de recette, en build de debug, pas un journal embarqué. Elle est
> vérifiée : **1 656 lignes `screen:` émises pendant `flutter test`**.

> **CE QUE LE 645-09b A CORRIGÉ — session cloud du 04/10/2026, branche
> `claude/fix/645-09b-pile-de-navigation`.** Jonction du 645-09 (`6ec401d9`)
> sur l'intégration (`168cb8a2`) par fusion sans avance rapide, sans conflit
> (`6a4863d6`), puis gate complète **avant** toute correction : 4075 passés,
> 2 ignorés, 0 échec ; observabilité 63/63.
>
> **LA PILE DE NAVIGATION — VOIE (1), COMPLÉTÉE PAR UN OBSERVATEUR QUI NE SAIT
> AUCUN NOM D'ÉCRAN.** Toute la correction vit dans le socle
> (`lib/core/analytics/screen_entry.dart`) ; aucun des 63 écrans n'est touché,
> le routeur reçoit une ligne (`observers: [ScreenEntryObserver()]`).
> 1. **Le filtre (voie 1).** `observeScreenEntry` ne transmet l'entrée que si
>    la route de l'écran est la route **courante**. Pour un écran sans état
>    (`ConsumerWidget`, appel forcément depuis `build`) :
>    `ModalRoute.isCurrentOf(context)`, qui abonne l'écran au **seul** aspect
>    « courant » de sa route — quand on dépile ce qui le couvrait, il est
>    reconstruit et repose sa miette. Les clés `trail` et `stage` suivent le
>    même filtre : un écran caché ne pose plus rien. Un écran à état pose dans
>    `initState`, où Flutter interdit de lire une route, et son montage **est**
>    son entrée : il est transmis tel quel, comme avant.
> 2. **L'observateur.** La voie (1) seule laissait un trou, mesuré : un écran
>    **à état** qui redevient visible ne repasse pas par `initState`. Le
>    cockpit (`/home`) et l'accueil (`/my-treks`) en sont — « Réglages » puis
>    retour au cockpit laissait `screen` sur `settings`, un écran qui n'existe
>    plus. `ScreenEntryObserver`, branché une fois sur `appRouter`, repose
>    **après la frame** (l'arbre ne se parcourt pas pendant que `Navigator`
>    reconstruit) l'entrée de l'écran redevenu courant, sur `didPop` et
>    `didRemove`. Il ne connaît **aucun nom d'écran** : chaque écran range sa
>    dernière entrée sur son propre élément (`Expando`, clé faible, rien ne
>    s'accumule) et l'observateur ne fait que la reposer.
>
> **POURQUOI PAS LA VOIE (2) SEULE** : un observateur qui pose la miette du
> sommet doit savoir quel écran porte chaque route — une seconde table des 63
> noms à tenir à jour — et il laisse les écrans cachés poser leurs clés
> `trail` et `stage`. Le filtre ferme les deux d'un coup, à la source.
> **Aucune donnée de plus ne part** (moins, en fait : les miettes des écrans
> cachés ne partent plus), les **63 miettes restent**, la **garde OBS-01 est
> inchangée** et reste verte.
>
> **LA PREUVE DE PILE, ROUGE PUIS VERTE.**
> `test/core/analytics/pile_de_navigation_645_09b_test.dart` monte le vrai
> GoRouter, empile `settings` sur `weather` (deux écrans instrumentés dans
> `build`), reconstruit l'écran du dessous par un changement d'état (le thème
> bascule — un `ref.watch` ne suffit pas : Riverpod 3 **met en pause** les
> abonnements d'un widget hors de l'écran), puis dépile. **Avant** la
> correction : journal `[weather, settings, weather, settings, weather,
> settings]`, le motif « à tour de rôle » d'Artemis. **Après** :
> `[weather, settings]`, puis `weather` reposé au dépilement. Deux tests de
> plus dans ce fichier (écran à état sous la pile : l'observateur repose sa
> miette ; dialogue ouvert puis fermé : pas une miette de plus), et
> `test/comportement/pile_de_navigation_reelle_645_09b_test.dart` rejoue la
> pile sur **l'application réelle** : `/home` → météo → journal → réglages,
> puis trois retours, la clé `screen` nommant l'écran visible à chaque étage.
> Mutations rejouées : filtre retiré → rouge (« après l'ouverture de
> /journal, la clé screen nomme un écran caché », journal `[hub, weather,
> journal, weather]`) ; observateur débranché du routeur → rouge (« retour sur
> hub : la clé screen nomme encore un écran dépilé », clé restée `weather`).
>
> **LES QUATRE RÉSERVES.**
> (a) **Trois commentaires de doc rendus à leur cible** : la constante de
> `health_info_screen.dart` passe au-dessus du doc de `HealthInfoScreen` (qui
> retrouve « ne quittent JAMAIS le téléphone » — l'analyseur compte une info
> `public_member_api_docs` de moins), `initState` passe au-dessus du pavé
> « ABONNEMENTS INCONDITIONNELS » de `trek_feasibility_screen.dart` et de la
> « Barre contextuelle » de `my_treks_screen.dart`. Balayage du diff
> `168cb8a2..6ec401d9` sous `lib/features` : **68 blocs** (les 65 points
> d'insertion — 63 appels et 2 constantes — plus les 3 signatures de classe
> `StatelessWidget` → `ConsumerWidget`), en regardant la dernière ligne non
> vide au-dessus de chaque bloc : **3 commentaires déplacés avant, 0 après**.
> (b) **`accommodation_detail` passe `stageNumber?.toString()`** : absent, la
> clé `stage` n'est plus posée (elle valait la chaîne `"null"`). Les 3 autres
> porteurs de `stage` sont sûrs par leur type (`int stageNumber` pour
> `trail_stage_detail` et `weather`, `int stageId` pour `trek_stage_detail`).
> Test ajouté, rouge avant (« la clé stage vaut "null" »), vert après.
> (c) **Le test « le service INERTE ne pose rien » observe enfin quelque
> chose** : un faux Crashlytics qui compte ses appels, **zéro** avec
> `operational: false`, la convention complète (`setCustomKey` ×3, `log`)
> avec `true`. Retour anticipé de `enterScreen` retiré : il rougit.
> (d) **`tool/audit_global.py`** : `APPELS_CRASHLYTICS` devient une liste de
> motifs, et `log(` y est remplacé par `\bobserveScreenEntry\(` (limite de
> mot sur le vrai geste d'un écran). Mesure **63/63** sur la tête ; rejouée
> sur la tête `6f747bf0` : **8/63 → 0/63**, les 8 faux positifs d'Artemis
> disparus un par un (4 `AlertDialog(` seuls, `_showResetDialog(` et
> `_showAddNoteDialog(`, `_goToCatalog(`, `ErrorHandler.log(`).
>
> **COMPTEURS, AVANT → APRÈS** : tests 4075 → **4081** passés (+6 ajoutés :
> 3 de pile, 1 de pile sur l'application réelle, 2 de la fiche hébergement ;
> 1 renforcé), 2 ignorés, 0 échec ; observabilité 63/63 → 63/63 ; OBS-01 0 → 0 ; ECR-23
> 233 → 233 ; ECR-15 48 → 48 ; ECR-28 198 → 198 ; ECR-19 10 → 10 ; ECR-31
> 19 → 19 ; VAC-01 0 → 0 ; ECR-05 77 → 77 ; ECR-18 125 → 125 ; en-têtes
> 100 % ; infos de l'analyseur 7513 → 7512 ; aucun fichier généré modifié.
> **COMMITS** : jonction `6a4863d6`, pile `9a3d4f02`, (a) `c2112a7d`,
> (b) `1dfaaf4b`, (c) `768fa6c6`, (d) `ddc7f0bd`, puis cette fiche ; gate
> complète verte après la jonction et après chaque commit.
> **Reste à faire par Skynet en local** : la preuve sur émulateur (parcours
> « Réglages puis retour » et traversée `traversee_645_09_test.dart`).

> **QA DU 645-09b (04/10) — Artemis, tâche 676, sur l'émulateur.** Jonction
> `a992e780` (sans avance rapide, **zéro conflit**, base commune `168cb8a2`),
> tête d'intégration après le lot F1 : `4026665b`.
>
> **LE DÉFAUT DE LA PILE EST MORT — 0 sur 12.** Le matin du 04/10, la clé
> `screen` nommait un écran caché **12 fois sur 12**. Rejoué à l'identique
> (`integration_test/pile_676_douze_tours_test.dart`) : trois écrans
> instrumentés dans `build` empilés et laissés vivants (détail d'étape, météo,
> journal), puis **douze** fois « ouvrir les Réglages, redescendre ». Après
> chaque empilement le journal local ne porte **que** `settings` ; après chaque
> dépilement, **que** `journal`. Aucun écran caché ne parle : **0 défaut
> sur 12**, et les Réglages sont montés aux 12 tours (sinon la mesure ne
> vaudrait rien).
>
> **LA CORRECTION COUVRE BIEN LES DEUX FAMILLES, et c'est mesuré, pas supposé.**
> Les 63 écrans se répartissent en **23 instrumentés dans `initState`** (21 dans
> leur propre fichier, 2 dans un fichier `part` — carte et fiche médicale) et
> **40 dans `build`**. Les **40** portent tous un `ConsumerWidget` : le filtre
> `ModalRoute.isCurrentOf` s'applique donc à tous les quarante, sans exception.
> Les 23 autres ne posent qu'une fois par montage, et leur **retour** au premier
> plan est l'affaire de `ScreenEntryObserver` — qui voit tout, puisque
> l'application n'a **qu'un seul `Navigator`** (plus aucun `ShellRoute` depuis le
> big-bang).
>
> **MUTATIONS REJOUÉES EN LOCAL, sur une copie jetable** : filtre de visibilité
> neutralisé → **2 tests rouges** (dont la pile sur l'application réelle,
> « attendu journal, trouvé weather ») ; observateur neutralisé → **2 tests
> rouges** (« retour au cockpit : la clé screen nomme encore un écran dépilé ») ;
> retour anticipé du drapeau inerte retiré → le test d'inertie rougit en
> nommant les 4 appels partis. Les trois réserves de la QA du matin sont donc
> **fermées par des tests qui mordent**, et la quatrième (l'outil d'audit) est
> vérifiée des deux côtés : avec le marqueur corrigé, la tête `6f747bf0` mesure
> **0 écran instrumenté sur 63** (les 8 faux positifs ont disparu) et la tête du
> lot **63 sur 63**.
>
> **GATE COMPLÈTE SUR LA TÊTE JOINTE** : formatage **1 175 fichiers** tous
> conformes ; analyse **0 erreur, 0 avertissement** (7 513 infos, base du dépôt) ;
> **4 086 tests passés, 2 ignorés, 0 échec** (4 075 + 11 des deux lots, compte
> exact) ; audit **identique au matin** — 556 bloquants, 874 avertissements,
> ECR-15 48, ECR-23 233, ECR-28 198, ECR-19 10, ECR-31 19, ECR-05 77, ECR-18 125,
> VAC-01 0, OBS-01 0, en-têtes 100 %, observabilité 63/63. **Un seul écart au
> critère « aucun fichier généré ne change »** : `dart run slang` réécrit la
> ligne d'horodatage `Built on …` de `translations.g.dart`, **sans une
> différence de contenu** (5 langues, 10 020 chaînes inchangées) ;
> `build_runner` (707 sorties) ne touche rien.
>
> **PERSONAS ET TRAVERSÉE, sur installation vierge à chaque fois.**
> **S1 Léa : 61 exigences tenues / 2 non tenues sur 63**, 553 s — l'attendu
> exact, et les 2 sont **exactement** les deux défauts connus (CTA « Démarrer »
> absent avant achat, qui est le comportement **voulu** par la règle produit, et
> le diplôme après trek terminé, défaut A déjà tracé). **S2 Marc : 20 / 20, 0 non
> tenue** (15 / 15 avant le lot F1). **Traversée `traversee_645_09_test.dart` :
> verte**, 254 s, 16 marqueurs / 16 captures, retard médian 0 ms, contrôle des
> captures **OK**. Les trois runs rendent 65, 20 et 16 captures pour autant de
> marqueurs.
>
> **UNE ERREUR DE RECETTE, TROUVÉE ET CORRIGÉE EN COURS DE QA.** Le premier run
> S1 a été joué avec `-Perm complet` alors que la recette documentée
> (CAMPAGNE_V2 §12) impose `-Perm avant-plan` pour S1 et S2. Les permissions de
> suivi de fond étant accordées d'avance, l'application saute son **pré-vol
> expliqué** et l'exigence C2 — verte le 03/10 — rougissait : 57 / 3 sur 60. Ce
> n'était pas une régression, c'était le paramètre. Rejoué avec `avant-plan` :
> C2 redevient verte et le compte retombe sur 61 / 2.
>
> **CE QUE LA COMPARAISON DE CAPTURES APPREND VRAIMENT.** Le jeu du 03/10 n'est
> **pas** comparable au pixel, et ce n'est pas le produit : il a été pris en
> thème **clair** sur un profil **sale** (distance en miles), le mien en thème
> **sombre** sur profil vierge — même mise en page, mêmes textes, mêmes
> positions, seule la palette change (**96,9 %** de l'écran en médiane sur les
> 20 captures S2). C'est exactement ce que la remise à zéro de E0 corrige.
> Comparaison **valable**, entre deux runs à profil vierge et mode identique :
> **12 captures sur 14 à ZÉRO pixel** hors barre d'état ; les 2 écarts sont la
> météo (272 px, contenu distant) et l'écran de secours (132 px).
> **ET UN DÉFAUT DU CONTRÔLE LUI-MÊME** : sa règle de doublon compare l'image
> **entière**, donc un pixel d'horloge suffit à faire passer pour « différentes »
> deux captures d'un écran où rien ne s'est passé. Quatre familles de doublons
> ont été déclarées **sur mesure** (elles montrent le même contenu dans les trois
> runs, référence du 03/10 comprise, où elles ne diffèrent que de 75 à 363 pixels
> **tous dans la barre d'état**). À reprendre en lot outillage.
>
> **LOGCAT SUR TOUTE LA RECETTE** : 0 plantage, 0 ANR, 0 exception Dart non
> rattrapée. **À NOTER** : contrairement aux mesures du matin (faites dans un
> worktree temporaire, donc sans clés), ce worktree porte déjà un
> `android/app/google-services.json` du 29/09 — non suivi, ignoré par git, **non
> copié par la QA**. Firebase s'initialise donc pour de vrai pendant ces runs, et
> l'observabilité est exercée **opérationnelle**, pas inerte : c'est l'état du
> build livré, et c'est une preuve plus forte, pas plus faible.
>
> **CE QUI N'A PAS PU ÊTRE FAIT : LE BUNDLE DE PREUVE.** `ops_enforcer` refuse
> la compilation d'un bundle en release et renvoie vers `gerer_qa('gate')` — qui
> ne sait pas compiler (gate, analyser, tester, scanner, rapport). La seule
> action du registre qui compile est `gerer_mep('deployer')`, **interdite à
> Artemis** et qui livrerait en plus. Aucun chemin légitime n'existe donc pour un
> agent QA qui doit seulement **prouver** que le bundle compile : le garde n'a
> **pas** été contourné, une plainte est déposée (`data/hook_plaintes.json`) avec
> la proposition d'une action `gerer_qa('compiler')` qui compile sans copier.
> Repère : le bundle du matin, sur le même code **moins** les deux lots,
> compilait en 274 s pour 70 917 769 octets.

| Champ | Contenu |
|---|---|
| **C1 Réf** | 645-09 |
| **C2 Fichier:ligne** | *(commandé)* `lib/core/analytics/analytics_service.dart` (point central) + les 54 écrans sans miette. ~~Les 9 déjà équipés sont la référence de forme~~ — *(mesuré : il n'y en avait **aucun**. La liste citée — `gpx_import_screen.dart`, `profile_screen.dart`, `checklist_screen.dart`, `consent_settings_screen.dart`, `journal_screen.dart`, `cartes_hors_ligne_screen.dart`, `onboarding_screen.dart`, `trail_planning_screen.dart`, `health_info_screen.dart` — est le relevé du faux positif `log(` ; `cartes_hors_ligne_screen.dart` n'existe même plus, renommé `offline_maps_screen.dart` par le 645-07. Livré : le service + `screen_breadcrumb.dart` (catalogue fermé de 63 noms) + `screen_entry.dart` (le raccord) + **les 63 écrans**)* |
| **C3 Description** | Poser l'instrumentation par **un seul** service, pas par 54 *(mesuré : **63**)* appels dispersés. Convention : **3 clés** (`screen`, `trail`, `stage`) dont la valeur change, pas 63 clés — *tenue : 4 clés distinctes dans tout le dépôt, les 3 du lot plus `consentement_sauvegarde` de la tâche 637, sur 64 permises*. Une miette courte `screen:<nom>` à l'entrée de chaque écran |
| **C4 Agent** | Hephaistos |
| **C5 Prompt complet** | *(ci-dessous, bloc 645-09)* |
| **C6 Branche** | `claude/chore/645-09-observabilite` |
| **C7 Commit** | un commit pour le service, puis un commit **par groupe de 10 écrans** : `feat(645-09): miettes d observabilite, groupe <N>` |
| **C8 Test** | *(commandé)* `flutter test` → 4002 passés. **Deux tests nouveaux** : (a) avec un service d'observabilité en échec, chaque écran s'affiche quand même ; (b) le nombre de **clés distinctes** posées par l'application est **≤ 64**. — *(mesuré le 04/10 : **4075 passés, 2 ignorés, 0 échec**, et **25 tests** dans 4 fichiers, pas 2 ; les deux tests commandés existent bien, plus la garde OBS-01 et le balayage des routes réelles)* |
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

### Lot 645-F1 — Deux défauts visibles, hors plan

> **Hors découpage : ce lot ne vient pas de l'audit 644, il vient de ce que
> Christophe voit.** Décision du 04/10/2026, 10 h 28, verbatim « A » (mémoire
> `#101128`) : *build 9 ce soir*. Branche
> `claude/fix/645-f1-defauts-visibles` (`3c2aec0e`, 2 commits), jointe à
> l'intégration le 04/10 (`4026665b`). Cinq fichiers, tous dans les zones
> attendues : `lib/features/settings/` (2), `test/` (2),
> `integration_test/` (1).

> **CE QUI A CHANGÉ.**
> 1. **L'unité de température survit au redémarrage.** Elle vivait en mémoire
>    seule : `_load()` recopiait `state.temperatureUnit` au lieu de lire le
>    magasin, et `setTemperatureUnit` n'écrivait nulle part. Le randonneur qui
>    choisissait Fahrenheit le reperdait à chaque démarrage. Clé nouvelle
>    `settings_temperature_unit`, repli `celsius`, lue dans `_load` et écrite
>    par `setTemperatureUnit` — comme la distance, à l'identique.
> 2. **Le parcours persona S2 Marc ouvre vraiment la gestion du consentement.**
>    L'exigence `#P38` se déclarait couverte sans rien ouvrir : le libellé
>    « Confidentialité et consentement » est porté **trois fois** (en-tête de
>    section, titre de la tuile, titre de l'écran `/consent`), et
>    `find.text(...)` tombait sur l'en-tête, qui ne se tape pas. Le parcours
>    tape désormais la **tuile** (`find.widgetWithText(ListTile, …)`) et prouve
>    l'arrivée par ce qui n'existe que là : `ConsentSettingsScreen` monté **et**
>    `/consent` route courante. La bascule d'une finalité (partage social) est
>    jouée dans les deux sens, et Marc ressort avec le consentement qu'il avait
>    en entrant.

> **LES DEUX PREUVES, MESURÉES LE 04/10 (tâche 676).**
> * **Température.** Test de redémarrage rouge avant / vert après
>   (`settings_provider_test.dart`, conteneur neuf après
>   `SharedPreferences.resetStatic()`), plus 3 tests de service (persistance,
>   installation vierge, valeur inconnue → celsius). **Sur l'émulateur** : un
>   vrai geste sur le bouton °F écrit `fahrenheit` dans le magasin du
>   téléphone, relu par une poignée `SharedPreferences` neuve (3 exigences
>   tenues sur 3).
> * **Parcours Marc.** **20 exigences tenues sur 20, 0 non tenue**, sur
>   installation vierge — contre 15 sur 15 avant le lot : les 5 exigences
>   ajoutées tiennent toutes. **La preuve par l'image** : le 03/10 les deux
>   captures `S2E_38_consent` et `S2E_38b_consent_bascule` portaient le **même**
>   md5 (`088e5cf2…`), signature du mensonge — c'est pour cela que
>   `captures_doublons_tolerees.txt` déclare ce doublon **non toléré, expres**.
>   Le 04/10, les deux md5 diffèrent.

> **DEUX RÉSERVES, À TRANCHER PAR CHRISTOPHE.**
> * **La clé n'est pas tout à fait neuve, et une valeur héritée coûterait TOUS
>   les réglages.** Le build du 26/05/2026 (`db71ad1e`) écrivait déjà
>   `settings_temperature_unit`, mais **en entier**
>   (`setInt(…, unit.index)`) ; le code a disparu le 01/06 (`7dbfe5dd`).
>   Mesuré : une valeur entière sous cette clé fait **lever** `getString`
>   (`type 'int' is not a subtype of type 'String?'`), l'exception traverse
>   `_load()` — qui n'a pas de filet — et l'application repart avec **langue,
>   thème, unités et cache à leur valeur par défaut**, en silence.
>   **Pourquoi ce n'est pas bloquant aujourd'hui** : StepWays n'est arrivée sur
>   un vrai appareil que le **29/09/2026** (mémoire `#100794`), bien après le
>   01/06 — aucune installation de la flotte ne peut porter cette valeur.
>   À corriger par une lecture gardée, au prochain lot d'assainissement.
> * **Le choix ne change rien à ce que le randonneur voit.** Aucun écran
>   n'affiche de température avec son unité : la carte météo du cockpit et le
>   bandeau de conditions rendent `$min° / $max°` (sans lettre), l'alerte
>   incendie code `°C` en dur, et personne ne lit `settings.temperatureUnit`
>   hors de l'écran Réglages lui-même. Le réglage persiste donc — et ne fait
>   rien.

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

#### QA du 645-12 (04/10/2026, 21:20 UTC — Artemis, session cloud)

**Périmètre.** Branche vérifiée `claude/docs/645-12-livre-de-bord` à
`a51a5c8e` (trois commits sur `0f679929` : `2e01a0c7`, `bb47656c`,
`a51a5c8e`). Branche de QA `claude/qa/645-12-jonction`, partie de
l'intégration à `0f679929`. **Deux AFFAIBLI : pas de jonction.** La branche
de QA ne porte que ce paragraphe. L'intégration n'est pas touchée, aucun tag.

**Verdicts de lecture (E1) — trois OK, deux AFFAIBLI.**
- (a) **AFFAIBLI** : le diff touche six fichiers ; trois sont hors de la
  liste autorisée : `docs/ADR/003-riverpod-over-bloc.md`,
  `docs/CONTRIBUTING.md`, `docs/README.md` (Riverpod 2.6 → 3.3.2). Leur
  contenu est vrai (`pubspec.yaml` dit `flutter_riverpod: ^3.3.2`, le lock
  3.3.2) et le test (a) les exige, mais ils sortent du périmètre fixé. Rien
  sous `lib/`, `pubspec`, `android/`, `macos/`, `lib/i18n`.
- (b) **AFFAIBLI**, trois écarts :
  1. ordre faux : le journal place 676 avant 645-F1. Or la fusion 645-F1
     `4026665b` (04/10 12:13) est le parent direct de `e22b7af8` (676,
     04/10 13:07) ;
  2. `#101220` (ligne « Démon de captures ») n'est pas dans la liste des
     numéros fournie par Skynet, et ce point n'était pas demandé ;
  3. `#100239` (lignes #P50 et #P52) n'est pas dans la liste fournie : il
     vient de la section 6 de cette fiche, mais le journal n'a qu'une source
     autorisée.
  Le reste est conforme : dates justes pour les 20 lignes ; aucun lot
  manquant ; 645-09 et 645-09b dans le bon ordre ; les sept points demandés
  pour « Ce qui reste ouvert » sont présents. La ligne « Captures » donne en
  plus une explication de la cause, à la limite de « ne raconte rien ».
- (c) OK : les 32 chiffres marqués `audit:` sont égaux au JSON de
  `audit_global.py --rapide` sur `a51a5c8e` (32/32). Les chiffres non marqués
  sont justes : 22 fichiers hors core/features/shared (18 `domain` + `main` +
  `i18n_setup` + 2 `lib/docs`), 63/63/0, 493 fichiers et 3840 cas sur
  `0f679929`, ECR-16 416, 37,2 %, les huit règles bloquantes, 236 = 72 + 164,
  plafonds 21, 52 et 0, versions du tableau = pubspec/lock, `schemaVersion`.
  ARB-645-05-a, b, c et les règles 9 à 12 sont citées, et la
  non-conformité est dite (21, 52, 20, ECR-15, ECR-13/07).
- (d) OK : trois verdicts, conformes à la demande, dans la forme du test
  619. Mutations (`flutter test --no-pub`) : `flutter_riverpod: ^3.3.3`
  dans `pubspec.yaml` → **rouge** (4 citations vues : ADR-003:5,
  CONTRIBUTING:36, README:27, architecture:176) ; `#101011` retiré de la ligne
  645-02 → **rouge** (« lot 645-02 sans numero en base ») ; `662` → `663` dans
  architecture.md → **rouge** (« la doc dit 663, l audit mesure 662 ») ;
  contre-essai `127 443` → `127 444` → rouge. `git checkout --` après
  chaque mutation : zéro diff résiduel. Sans `--no-pub`, la mutation 1 est
  rouge pour une autre raison (résolution `pub get`), d'où l'option.
  Limite : (b) vérifie la forme `#NNNNNN`, pas l'appartenance à la liste
  fournie ; c'est pour ça que les écarts 2 et 3 passent au vert.
- (e) OK : aucun chemin absolu, seulement `Directory.systemTemp` pour le JSON.
  Vert avec trois graines d'ordre aléatoire (1, 42, 9999) et pour chacun des
  quatre tests lancé seul. Durée : 22,3 s à froid, 9,4 s à chaud.

**Gate (E2), sans jonction.** Elle a tourné sur l'arbre `a51a5c8e`. Comme
`0f679929` en est l'ancêtre direct, une jonction `--no-ff` aurait le même
arbre. `dart format` : 0 changement ; `flutter analyze --no-pub
--no-fatal-infos` : 0 erreur, 0 warning (7614 infos) ; `flutter test` :
**+4092 ~2, 0 échec** (4088 + les 4 du lot), 10 min 58 s ; `build_runner` :
`git status` vide ; audit `--rapide` comparé à `0f679929` : aucun compteur ne
bouge (ECR-07 2, ECR-15 46, ECR-28 195, ECR-23 236, ECR-19 10, ECR-31 19,
ECR-05 77, VAC-01 0, OBS-01 0, observabilité 63/63, en-têtes 100 %). Seuls
les tests changent : fichiers 493 → 494, cas 3840 → 3844.

**Trous « a completer par Skynet » que le journal porte encore.** Lots : 676
et 645-12. Points ouverts : tests ignorés, vingt croisements (645-05c),
#P51, #P53, #P54.

**QA rejouée (05/10/2026, 00:24 UTC — Artemis, session cloud).** Skynet a
levé les deux AFFAIBLI par arbitrage (`#101233`, rapport `#101232`). Pour
(a), les trois fichiers de `docs/` étaient autorisés par le brief du lot
(tout `docs/` et `test/structurel/`) : la liste de la QA était trop
étroite. Pour (b), Athena a corrigé le journal en `d53ebcee`, et la liste
des numéros est amendée : `#101220`, `#100239`, `#101196` pour la ligne 676,
`#101229` et `#101232` pour la ligne 645-12.
- (b) **OK** sur `d53ebcee`. Le seul changement depuis `a51a5c8e` est
  `docs/JOURNAL.md`, sur deux lignes. 645-F1 passe avant 676, ce qui suit
  l'ordre réel (`4026665b` puis `e22b7af8`). 676 porte `#101196` et 645-12
  porte `#101229, #101232`. Les 38 numéros distincts du journal sont tous
  dans la liste amendée, aucun n'est hors liste. Les 20 lignes de lots sont
  dans l'ordre réel et les dates n'ont pas changé.
- (a) **OK** : `0f679929..d53ebcee` touche 6 fichiers, tous sous `docs/` ou
  `test/structurel/` ; rien ailleurs.
- **Jonction** `78a49737`, sans avance rapide (parents `c078185e` et
  `d53ebcee`), **aucun conflit**. La tête jointe ne diffère de `d53ebcee` que
  par ce paragraphe de fiche.
- **Gate sur `78a49737`** : `dart format` à 0 changement ; `flutter analyze
  --no-pub --no-fatal-infos` à 0 erreur et 0 warning (7614 infos).
  `flutter test` : **+4092 ~2, 0 échec**, soit 4088 + les 4 du lot, en 10 min
  31 s. Après `build_runner`, `git status` est vide. Audit `--rapide` comparé
  à `0f679929` : aucun compteur ne bouge (ECR-07 2, ECR-15 46, ECR-28 195,
  ECR-23 236, ECR-19 10, ECR-31 19, ECR-05 77, VAC-01 0, OBS-01 0,
  observabilité 63/63, en-têtes 100 %). Seuls les tests changent : fichiers
  493 → 494, cas 3840 → 3844.
- **Trous « a completer par Skynet » restants** : les deux tests ignorés,
  les vingt croisements (645-05c), #P51, #P53 et #P54. Ce sont les cinq
  attendus. Plus aucune ligne de lot n'en porte.

**Verdict final : 645-12 VERT, joint sur `claude/qa/645-12-jonction`
(`78a49737`).** Il reste à Skynet de le réunir dans l'intégration. Aucun tag.

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

---

## QA outillage (05/10)

> **QA DU LOT OUTILLAGE — Artemis, tâche 696, sans émulateur.** Jonction
> `e36d0cd5` (sans avance rapide, **zéro conflit**) de
> `claude/chore/outillage-cache-pub-tests-tolerances` (`2d82af54`, 3 commits) sur
> l'intégration `3fa557c7`. Lot de code et de tests : **aucun produit livré**.
> **VERDICT : OK sur les cinq points, avec deux AFFAIBLI mineurs, tous deux de
> documentation ou de périmètre — rien qui touche le produit.**
>
> **LA GATE, AU CHIFFRE PRÈS, REMESURÉE SUR LA JONCTION.** `flutter test` :
> **4 183 verts, 2 ignorés, 0 échec**, code 0 — la référence annoncée, à
> l'unité. `flutter analyze --no-fatal-infos lib test integration_test` :
> **7 552 remarques, toutes de sévérité `info`, 0 erreur, 0 avertissement**.
> `gate_format` : OK. `build_runner` : **2 595 sorties**, code 0, puis
> `git status` **vide**. Gardes structurelles : **211 vertes**. Audit rapide
> comparé avant/après sur **336 clés** : **aucun compteur d'infraction ne
> bouge** ; seules bougent des mesures de volume, et chacune de la valeur
> exacte attendue (+25 lignes dans `lib/core/services`, +1 fichier et +837
> lignes de test, +14 cas de test = 11 gardes du cache + 1 horloge réelle + 2
> gardes des tolérances). **Un chiffre du rapport est à corriger** :
> `gate_format` compte **1 199** fichiers Dart écrits à la main sur la
> jonction, pas 1 198 — 1 198 est la mesure d'**avant** le lot (vérifiée sur
> `3fa557c7`), le lot en ajoute exactement un.
>
> **A — LE CACHE PUB : LE VERROU TIENT, LA PURGE EST BORNÉE, ET LA LEÇON DE LA
> V1 EST VERROUILLÉE.** Le verrou est bien posé **dans** le cache qu'il protège
> (donc partagé par construction entre arbres) et rendu dans un `finally`, donc
> même en échec. La purge n'atteint que les dossiers de forme
> `paquet-version` **sans** `pubspec.yaml`, et la règle est vérifiée **deux
> fois** (au listage, puis juste avant la suppression). Mesuré sur le **vrai**
> cache de la machine, en lecture seule : **732 paquets, 0 incomplet**, et la
> **seule** entrée de `hosted/pub.dev` que la règle de forme épargne est
> `.cache` — exactement le dossier que la V1 avait détruit. **MUTATION 1** :
> règle de forme retirée aux deux endroits → le banc passe **rouge** sur trois
> cas, et le premier nomme le témoin perdu (`/hosted/pub.dev/.cache`) ; la même
> mutation, **simulée** sur le vrai cache, annonce la purge de
> `pub.dev/.cache` (322 fichiers, 17 082 620 octets). La règle porte donc bien
> le défaut. **AFFAIBLI (mineur) :** la purge que le pilote lance à son réveil
> est le `--purger` **nu**, hors verrou, alors que l'outil écrit lui-même qu'une
> purge hors verrou « efface sous les pieds d'un autre `pub get` le paquet
> qu'il est en train de remplir ». La fenêtre est étroite et l'état d'avant le
> lot était l'absence totale de parade, mais `--sous-verrou` existe déjà :
> l'appeler coûterait une ligne.
>
> **AFFAIBLI (mineur, documentation) :** `docs/README.md` et le commentaire de
> `tool/run_persona.ps1` décrivent tous deux la purge comme effaçant les
> dossiers « qui n'ont pas de `pubspec.yaml` à leur racine », **sans** la
> condition de forme — c'est mot pour mot le contrat que l'en-tête de
> `pub_cache_sain.py` déclare **faux** depuis l'incident de la V1. Le code est
> juste ; les deux endroits qu'un humain lit d'abord ne le sont pas.
>
> **B — LES DEUX TESTS INSTABLES : LA PREUVE EST FAITE, ET ELLE EST PLUS FORTE
> QUE CELLE DU RAPPORT.** L'horloge est injectée ; la production est
> **inchangée** — défaut `Timer.periodic`, aucun appelant de `lib/` ne passe
> `poserLHorloge`, et une garde dédiée garde la **vraie** horloge (vérifiée :
> cadence rendue inéchéable, elle passe **rouge** avec le bon message, ce n'est
> donc pas un faux vert). Les comptes sont exacts et le négatif est démontré en
> rejouant le battement sur une horloge annulée. **MUTATION 2** : ancienne
> recette remise (vraie horloge de 25 ms + sommeil de 80 ms). Calme : 0 rouge
> sur 20 ; sous une suite complète en parallèle : 0 rouge sur 20 ; **sous
> saturation CPU réelle (32 boucles sur 16 cœurs) : 7 rouges sur 32**. Et la
> **version corrigée, sous la saturation identique : 0 rouge sur 20 pour 616 et
> 0 sur 20 pour 637.** Le correctif supprime donc la fragilité, en mesure
> contrôlée avant/après.
>
> **TROUVAILLE QUI CORRIGE LE RAPPORT DU LOT.** Le matcher
> `Expected: <2> / Actual: <3>`, que le mandat attribuait à
> `mon_compte_menu_trek_637` et que le lot a renvoyé à
> `fiche_medicale_locale_612` dans un autre arbre, **est reproductible ici** :
> il sort de l'ancienne recette de **`niveaux_et_cadence_616`, test « ARRETER
> ARRETE VRAIMENT », ligne 866** — le repère pris pendant qu'une passe est en
> vol, puis l'incrément légitime qui suit l'arrêt. Reproduit **7 fois sur 32**
> sous saturation. Le mandat avait donc apparié le **nom** du 637 au
> **matcher** du 616 ; il n'y a pas d'énigme venue d'un autre arbre, et le
> correctif du 616 vise exactement l'échec dont le matcher était gardé.
>
> **LA FUITE DES BACS TEMPORAIRES EST FERMÉE, MESURÉE.** 20 passages du 637 :
> **173 dossiers `stepways_parcours_reel_*` avant, 173 après, delta 0**, 0
> échec. Et 173 est exactement le nombre de bacs que le lot déclarait avoir dû
> épargner : le compte tombe juste.
>
> **C — LES TOLÉRANCES.** Les cinq déclarations sont bien remises, chacune avec
> sa raison et sa mesure (**0 pixel** de différence pour `19b`/`19b2`,
> identiques au bit ; **603 pixels** pour `27`/`33`, tous dans la boîte
> `(123,47)-(967,80)`, la barre d'état). Les deux gardes neuves tiennent la
> leçon : les cinq doivent rester déclarées **avec** leur raison, et les
> chiffres doivent rester dans le fichier. `docs/JOURNAL.md` porte **une ligne
> vraie** — elle dit bien les cinq tolérances retirées **puis remises**.
>
> **A — PÉRIMÈTRE : LE MANDAT DE QA ÉTAIT INEXACT, PAS LE LOT.** Le mandat
> annonçait « rien sous `lib/` » : il y a **un** fichier,
> `lib/core/services/ordonnanceur_de_synchronisation.dart` (+25 lignes de
> commentaire, 1 paramètre optionnel, 1 appel). Le rapport du lot le déclarait
> honnêtement ; c'est la fiche de QA qui disait faux. Le comportement de
> production, lui, est bien inchangé — et c'est vérifié, pas déduit.
>
> **CE QUE JE N'AI PAS PU FAIRE.** (1) Rejouer les tolérances de S3 et S4 :
> aucun émulateur sur cette tâche, les trois déclarations restent en l'état.
> (2) Reproduire l'instabilité du 637 : 0 échec sur 20 passages calmes et 0 sur
> 20 sous saturation — comme le lot, je corrige une fragilité mesurée, pas un
> symptôme observé. (3) `jusqua()` est présenté comme « pas un budget de
> temps » ; pour l'unique test qui attend une **vraie** `Timer.periodic`, ses
> 20 000 tours **valent** un budget, mesuré entre **200 et 400 ms** sur cette
> machine pour un besoin de 25 ms. La marge est de 8 à 16 fois : ce n'est pas
> un risque aujourd'hui, c'est une dépendance machine qu'il faut savoir.

---

*Fin du 644-03. Suite : `644-04-audit-global.md`.*
