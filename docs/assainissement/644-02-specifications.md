# 644-02 — Les spécifications : une par changement envisagé

> Tâche 644, temps 2 de l'assainissement StepWays. Athena, 02/10/2026.
> Dépôt **Moteur-GR**, tête mesurée **147ca32d**.
> Mesures : `644-01-inventaire.md`. Sources : `644-00-sources.md`.

## Règle qui gouverne TOUTES les spécifications de ce document

**Comportement AVANT = comportement APRÈS. Zéro changement fonctionnel.**

C'est la condition posée par Christophe le 30/09 : « Quand je dis en sécurité
c'est petit à petit en rendant tout récupérable. Pas de risque avec l'appli comme
elle est. » (`#100914`). Un assainissement qui change un comportement n'est plus
un assainissement : c'est une évolution, et elle sort de ce périmètre.

**Conséquence pratique, appliquée partout :** le test qui prouve une
spécification est un test qui **passait déjà avant** et qui passe encore après.
Si un test doit être *modifié* pour qu'un lot passe, c'est que le comportement a
changé — et le lot est refusé.

**Trois exceptions, nommées ici et nulle part ailleurs**, où le comportement
change volontairement parce qu'il est faux aujourd'hui :

| Réf | Exception | Pourquoi c'est volontaire |
|---|---|---|
| #X01 | SPEC-09, valeurs à compléter | `example.org` et « a completer » livrés au randonneur sont un défaut, pas un comportement à préserver. Décision produit de Christophe nécessaire **avant** le lot |
| #X02 | SPEC-10, observabilité | poser des miettes **ajoute** un effet (un envoi réseau conditionnel) ; aucun comportement visible ne change, mais ce n'est pas rigoureusement « zéro effet » |
| #X03 | SPEC-11, dépendances | une montée de version majeure peut changer un comportement sans qu'on le veuille. C'est le seul lot où la gate complète ne suffit pas : il demande un essai sur émulateur |

---

## Index des spécifications

| Réf | Spéc | Objet | Règle ECR | Lot |
|---|---|---|---|---|
| #X04 | SPEC-01 | Armer la mesure : tests d'architecture + lints | ECR-02/13/17/19/20/23/25 | 645-01 |
| #X05 | SPEC-02 | Retirer le code mort public confirmé | — (MORT-01) | 645-02 |
| #X06 | SPEC-03 | Sortir la documentation de `lib/` | ECR-07, ECR-13 | 645-01 |
| #X07 | SPEC-04 | Ramener les boutons sur `AppButton` | ECR-19 | 645-03 |
| #X08 | SPEC-05 | Résorber les 4 doublons de nom | ECR-20 | 645-04 |
| #X09 | SPEC-06 | Redresser le sens des dépendances | ECR-23 | 645-05 |
| #X10 | SPEC-07 | Découper les fichiers et les `build()` hors plafond | ECR-15, ECR-28, ECR-31 | 645-06 |
| #X11 | SPEC-08 | Passer les identifiants en anglais | ECR-05 (IDE-001) | 645-07 |
| #X12 | SPEC-09 | Supprimer les valeurs à compléter | VAC-01 | 645-08 |
| #X13 | SPEC-10 | Poser l'observabilité sur les 54 écrans nus | OBS-01 | 645-09 |
| #X14 | SPEC-11 | Monter les dépendances résolubles | DEP-01 | 645-10 |
| #X15 | SPEC-12 | En-têtes de fichier et couleurs au thème | ECR-01, ECR-24 | 645-11 |
| #X16 | SPEC-13 | Livre de bord du dépôt | — (proposition 8) | 645-12 |

---

## SPEC-01 — Armer la mesure avant de toucher au code

**Quoi.** Étendre `test/structurel/` de **sept tests d'architecture** qui
rejouent, en `flutter test`, les mesures bloquantes de l'inventaire ; et activer
dans `analysis_options.yaml` les règles de lint que le référentiel ECR réclame et
qui sont absentes.

**Pourquoi.** Décision de Christophe du 30/09 (`#100914`) : « Quand tu nettoieras
le code tu le feras après un audit et tu relanceras l'audit global pour vérif de
code propre. » Un audit qu'on ne peut pas rejouer n'est pas une garantie. Et
constat #I195 à #I206 : **tous les indicateurs mesurés le 21/09 se sont dégradés
en onze jours** alors que la gate restait verte. Une règle qu'aucune commande ne
vérifie n'est pas une règle.

**Pourquoi des tests maison et pas un paquet.** Corpus source S3 (#S19 à #S22) :
il n'existe aucun outil officiel d'architecture en Dart, et le dépôt écrit déjà
les siens à la main dans `test/structurel/` — 15 fichiers. Étendre coûte zéro
dépendance et suit la forme existante.

**Fichiers touchés.**

| Réf | Fichier | Nature |
|---|---|---|
| #X17 | `test/structurel/couches_respectees_645_test.dart` | NOUVEAU — ECR-23 : aucun import socle → feature, aucun croisement entre features |
| #X18 | `test/structurel/aucun_code_mort_645_test.dart` | NOUVEAU — MORT-01 : toute déclaration publique de `lib/` est citée ailleurs |
| #X19 | `test/structurel/aucun_doublon_645_test.dart` | NOUVEAU — ECR-20 : aucun basename en double dans `lib/` |
| #X20 | `test/structurel/aucun_bouton_brut_645_test.dart` | NOUVEAU — ECR-19 : les 4 boutons hors `app_button.dart` et `core/theme/` |
| #X21 | `test/structurel/aucune_valeur_a_completer_645_test.dart` | NOUVEAU — VAC-01 : `example.org`, « a completer », hors commentaire |
| #X22 | `test/structurel/aucun_dialogue_hors_routeur_645_test.dart` | NOUVEAU — `showDialog` / `showModalBottomSheet` passent par le routeur |
| #X23 | `test/structurel/taille_et_rangement_645_test.dart` | NOUVEAU — ECR-13 racine de `lib/`, ECR-07 pas de `.dart` sous `docs/`, ECR-15 plafond 500 |
| #X24 | `analysis_options.yaml` | MODIFIÉ — section `rules:` renseignée |
| #X25 | `tool/audit_global.py` | existant, livré par la tâche 644 — sert de référence de calcul aux tests |

**Comportement AVANT = APRÈS.** Aucun fichier de `lib/` n'est touché. Un test
d'architecture et une règle de lint ne changent **aucun** comportement à
l'exécution de l'application.

**Mécanisme obligatoire : le socle de référence (« baseline »).** Les sept tests
ne peuvent pas être verts le premier jour — il y a 889 infractions. Chaque test
porte donc un **plafond chiffré** qui vaut la mesure du 02/10, et il échoue dès
que le chiffre **augmente**. Exemple : « au plus 153 boutons bruts ». Chaque lot
suivant **abaisse** le plafond de son propre test, et le plafond ne remonte
jamais. C'est ce qui empêche la dette de croître pendant qu'on la rembourse, et
c'est ce qui rend ce lot utile dès le premier jour au lieu d'attendre la fin.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X26 | `flutter test test/structurel/` — les 7 nouveaux tests passent, chacun au plafond du 02/10 |
| #X27 | `flutter test` complet — **4002 passés, 2 ignorés**, identique à la mesure #I164 |
| #X28 | `flutter analyze --no-pub` — **No issues found!** après activation des lints (si une règle remonte des infractions, elle est activée en `info`, pas en `warning`, et son passage en bloquant est un lot à part) |
| #X29 | `python tool/audit_global.py --strict` — le même rapport chiffré qu'aujourd'hui |

**Critère de réussite.** Les 7 tests existent, passent, et un essai manuel de
régression le prouve : ajouter volontairement un `ElevatedButton(` dans un
fichier de feature doit faire **échouer** `flutter test test/structurel/`. Cet
essai est fait, constaté, puis annulé — il ne part pas dans le commit.

**Retour arrière.** `git revert` du commit du lot. Aucun fichier applicatif
touché, donc le retour est total et sans effet de bord. Tag de retour
`avant-645-01` posé avant le premier commit.

---

## SPEC-02 — Retirer le code mort public, après confirmation un par un

**Quoi.** Supprimer les déclarations publiques de `lib/` qui n'ont **aucun**
appelant, après confirmation individuelle.

**Pourquoi.** Mesure #I141/#I142 : **152 candidats sur 1 047 déclarations
publiques**, soit 14,5 %. Et surtout, source S1 du corpus : `unused_element` de
Dart **ne voit que le privé** — ces 152 symboles ne seront **jamais** signalés
par `flutter analyze`, qui rend « No issues found! » sur ce même code (#I01). Sans
ce lot, ils restent invisibles indéfiniment.

**Fichiers touchés.** 152 candidats répartis sur 8 dossiers principaux
(#I143 à #I150). La liste nominative complète est dans la sortie JSON de l'audit,
section `code_mort.candidats_morts`.

**Procédure de confirmation — obligatoire, et c'est le cœur de la spécification.**
Limite #S27 : le détecteur ne voit pas une citation par chaîne de caractères ni
par réflexion. Pour **chaque** symbole, dans cet ordre :

| Réf | Étape de confirmation | Rejet si |
|---|---|---|
| #X30 | recherche du nom en texte brut dans tout le dépôt, **y compris** `.json`, `.yaml`, `.dart` générés, `firestore.rules`, `codemagic.yaml` | une occurrence existe hors de la déclaration |
| #X31 | recherche du nom comme **chaîne de caractères** (`'Nom'`, `"Nom"`) — cas de la réflexion et des registres | une occurrence existe |
| #X32 | vérification qu'il ne s'agit pas d'une API publique **destinée** à être appelée de l'extérieur (point d'extension documenté en doc comment) | le doc comment l'annonce comme point d'extension |
| #X33 | vérification qu'il n'est pas dans le **registre des dormants** déjà tenu par le dépôt (`test/structurel/registre_des_dormants.dart`) | il y est — alors c'est une dette **assumée et tracée**, pas du code mort |

Un symbole qui échoue à l'une des quatre étapes est **sorti de la liste** et
inscrit dans le rapport du lot avec la raison. Le chiffre final sera donc
**inférieur à 152**, et c'est normal.

**Comportement AVANT = APRÈS.** Par construction : on ne supprime que ce qui
n'est appelé par personne. Si un comportement change, c'est que la confirmation
a échoué — et le lot est refusé.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X34 | `flutter test` — **4002 passés**, aucun test modifié, aucun test retiré |
| #X35 | `flutter analyze --no-pub` — **No issues found!** |
| #X36 | `test/structurel/aucun_code_mort_645_test.dart` — plafond abaissé de 152 au chiffre atteint |
| #X37 | `flutter build appbundle --release` réussit — un symbole supprimé à tort casse la compilation, c'est le filet le plus sûr |

**Critère de réussite.** Le plafond du test d'architecture est abaissé, la
compilation release passe, 4002 tests passent, et le rapport du lot liste
nominativement **chaque** symbole supprimé et **chaque** symbole écarté avec sa
raison.

**Retour arrière.** `git revert`. Découpage obligatoire **par dossier** (un
commit par dossier de #I143 à #I150) : un retour arrière sur `core/services` ne
doit pas annuler le ménage de `features/trek`.

---

## SPEC-03 — Sortir la documentation de `lib/`

**Quoi.** Déplacer `lib/docs/flutter_map_v8_changes.dart` et
`lib/docs/riverpod_migration_guide.dart` vers `docs/`, convertis en `.md`.
Supprimer le dossier `lib/docs/`.

**Pourquoi.** ECR-07 et ECR-13. Mesures #I26 à #I28 : c'est le **seul** intrus à
la racine de `lib/`, et ces deux fichiers portent en ligne 1 un
`// ignore_for_file: unused_element` — **il faut désarmer l'analyseur pour que de
la documentation compile**. Ils sont analysés, comptés comme du code applicatif
et gonflent le périmètre de tout audit (337 lignes).

**Fichiers touchés.**

| Réf | Fichier | Action |
|---|---|---|
| #X38 | `lib/docs/flutter_map_v8_changes.dart` | SUPPRIMÉ, contenu porté dans `docs/migrations/flutter_map_v8_changes.md` |
| #X39 | `lib/docs/riverpod_migration_guide.dart` | SUPPRIMÉ, contenu porté dans `docs/migrations/riverpod_migration_guide.md` |
| #X40 | `lib/docs/` | dossier SUPPRIMÉ |

**Comportement AVANT = APRÈS.** Ces deux fichiers ne déclarent que des éléments
**non utilisés** — c'est la raison même du `ignore_for_file: unused_element`.
Aucun code applicatif ne les importe. Vérification préalable obligatoire : une
recherche d'import de `docs/` dans tout `lib/`, `test/` et `integration_test/`
doit rendre **zéro** résultat avant de supprimer.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X41 | `flutter test` — 4002 passés |
| #X42 | `flutter analyze --no-pub` — No issues found! |
| #X43 | `python tool/audit_global.py --section documentation` — `doc_en_dart_dans_lib` vaut **0**, `desarmements_analyseur` vaut **0** |
| #X44 | `test/structurel/taille_et_rangement_645_test.dart` — la racine de `lib/` ne porte plus que `core`, `features`, `shared`, `i18n`, `main.dart` |

**Critère de réussite.** `find lib -name '*.dart' -path '*/docs/*'` rend zéro, et
`grep -rn "ignore_for_file" lib/ --include='*.dart'` hors fichiers générés rend
zéro. Le compte de fichiers source de `lib/` passe de 599 à **597**.

**Retour arrière.** `git revert`. Le lot le plus sûr du plan : deux fichiers,
aucun appelant, 337 lignes.

---

## SPEC-04 — Ramener les boutons sur le composant unique

**Quoi.** Remplacer les **153 appels bruts** d'`ElevatedButton`, `TextButton`,
`OutlinedButton` et `FilledButton` répartis dans **27 fichiers** par `AppButton`,
avec le paramétrage équivalent.

**Pourquoi.** ECR-19 et la demande de Christophe citée mot pour mot dans
`#100235` : « un appel de bouton c'est standard avec des paramètres ». Mesure
#I80 : **58 occurrences le 21/09, 153 le 02/10 — multiplié par 2,6 en onze
jours**, alors qu'`AppButton` existe, est bien fait et documenté (8 paramètres
nommés, 4 variantes). Conséquence concrète : changer la hauteur tactile d'un
bouton demande d'ouvrir 27 fichiers au lieu d'un.

**Fichiers touchés.** Les 27 fichiers de #I82 à #I88 et suivants. **Ordre imposé,
par volume décroissant**, parce qu'il concentre le gain : `checklist_screen.dart`
(16), `checklist_bottom_actions.dart` (13), `health_info_screen.dart` (10),
`trail_planning_screen.dart` (8), `calendar_screen.dart` (7), `nuitees_screen.dart`
(6), `hub_start_trek_button.dart` (6), puis les 20 autres.

**Exclusion mesurée et à ne pas oublier.** `lib/core/theme/app_theme.dart` cite
légitimement `ElevatedButtonThemeData` et `ElevatedButton.styleFrom`
(lignes 265-287 et 407) : c'est le rôle d'un thème. Ce fichier est **hors
périmètre**, et le test d'architecture #X20 l'exclut explicitement.

**Comportement AVANT = APRÈS — et c'est ici le vrai risque du plan.** Un bouton
brut porte souvent un `style:` local qui diffère du thème. Le remplacer par
`AppButton` peut **changer son apparence**. Règle imposée :

| Réf | Règle de non-régression visuelle |
|---|---|
| #X45 | si le bouton brut porte un `style:` qui ne fait que **répéter** le thème, il est remplacé directement |
| #X46 | si le `style:` **diffère** du thème, le besoin est porté dans `AppButton` en **paramètre nommé avec valeur par défaut** — jamais en cas particulier dans l'appelant |
| #X47 | si le besoin ne peut pas être exprimé par un paramètre, le fichier est **sorti du lot** et inscrit comme arbitrage pour Christophe. On ne force pas |

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X48 | `flutter test` — 4002 passés. Les tests de widget du dépôt cherchent les boutons par leur libellé et par `find.byType` ; un changement de type de widget **fera échouer** les tests concernés, ce qui est exactement le filet voulu |
| #X49 | `test/structurel/aucun_bouton_brut_645_test.dart` — plafond abaissé fichier par fichier |
| #X50 | capture d'écran avant / après sur les 7 écrans les plus touchés, via la campagne personas existante (`integration_test/persona_*`) — la comparaison est faite par Skynet, écran par écran |

**Critère de réussite.** Le plafond du test tombe à **0 hors `app_button.dart` et
`core/theme/`** ; 4002 tests passent ; les captures avant/après des 7 écrans sont
identiques à l'œil. Un écart visuel non expliqué = lot refusé.

**Retour arrière.** `git revert`, **un commit par fichier** — 27 commits. C'est
le lot où le découpage fin compte le plus : un écart visuel sur un écran ne doit
pas annuler les 26 autres.

---

## SPEC-05 — Résorber les quatre doublons de nom

**Quoi.** Ramener à **une seule** implémentation chacun des quatre concepts
dédoublés.

**Pourquoi.** ECR-20. Mesure #I75 à #I78 : **4 doublons, dont un apparu entre le
21/09 et le 02/10** (`stage.dart`). C'est la démonstration de la règle ECR-22 :
sans la question « qu'est-ce qui existe déjà ? » posée avant de coder, le dépôt
fabrique un doublon tous les dix jours.

**Fichiers touchés et état mesuré de chacun.**

| Réf | Concept | Les deux emplacements | État mesuré le 02/10 |
|---|---|---|---|
| #X51 | `gpx_parser` | `lib/core/geo/` et `lib/features/trek/data/` | **celui de `core/` IMPORTE celui de `trek/`** (#I68) — c'est déjà une délégation, pas une divergence |
| #X52 | `track_point` | `lib/core/geo/` et `lib/features/trek/domain/models/` | chacun traîne son `.freezed.dart` et son `.g.dart` : **6 fichiers pour un concept** |
| #X53 | `stage` | `lib/core/models/` et `lib/features/trek/domain/models/` | **NOUVEAU**, à instruire en premier : lequel est le plus récent, lequel est le plus lu |
| #X54 | `tracking_overlay` | `lib/features/tracking/presentation/` et `lib/features/trek/presentation/map/overlay/` | deux widgets, deux features |
| #X55 | `loading_view` / `loading_overlay` | `lib/core/ui/` et `lib/shared/widgets/` | doublon **fonctionnel à noms différents** : aucune commande ne le voit, seule la revue. Signalé le 21/09, **toujours là** |

**Instruction préalable obligatoire, par concept.** Avant de supprimer quoi que
ce soit : compter les appelants de chaque côté, comparer les deux
implémentations ligne à ligne, et **écrire** laquelle est retenue et pourquoi.
Un doublon résorbé par « j'ai gardé celui de `core/` » sans comparaison est
refusé.

**Comportement AVANT = APRÈS.** Point de vigilance majeur : si les deux
implémentations ont **divergé**, en garder une change le comportement des
appelants de l'autre. Règle imposée : si la comparaison montre une divergence
fonctionnelle, l'implémentation retenue doit couvrir **les deux** comportements,
et un test par comportement le prouve. Si c'est impossible, le concept est sorti
du lot et porté en arbitrage.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X56 | `flutter test` — 4002 passés, **sans modifier aucun test existant** |
| #X57 | pour chaque concept, les tests des **deux** anciens emplacements sont conservés et passent contre l'implémentation unique |
| #X58 | `test/structurel/aucun_doublon_645_test.dart` — plafond de 4 à 0 |
| #X59 | `flutter build appbundle --release` réussit |

**Critère de réussite.** Zéro basename en double dans `lib/` ; le compte de
fichiers générés baisse (les `.freezed.dart` et `.g.dart` du doublon disparaissent) ;
4002 tests passent sans qu'un seul ait été réécrit.

**Retour arrière.** `git revert`, **un commit par concept** — 5 commits
(4 doublons de nom + le doublon fonctionnel).

---

## SPEC-06 — Redresser le sens des dépendances

**Quoi.** Supprimer les **78** imports socle → feature et les **243** croisements
entre features.

**Pourquoi.** ECR-23, et c'est en volume le premier défaut du dépôt :
**321 infractions** (#I65 à #I67).

**Honnêteté de sourçage, et elle change la façon de traiter le lot.** Corpus
source S2 : le texte officiel Flutter ne parle que de couches techniques (UI /
Data) et ne pose **qu'une** interdiction explicite — *« Repositories should never
be aware of each other »*. L'interdiction du croisement entre features et
l'interdiction socle → feature sont une **règle maison** du dépôt
(`docs/conventions.md` lignes 17-54). **Les 321 infractions ne sont donc pas
321 bugs** : ce sont 321 écarts à une convention que le dépôt s'est donnée et
qu'il n'a jamais outillée.

**Ce lot ne peut donc PAS commencer par du code. Il commence par une décision.**
Mesure #I68 à #I72 : la feature `trek` s'est transformée en **domaine partagé de
fait** — `core/data/daos/trek_sessions_dao.dart` dépend de
`features/trek/domain/models/trek_session.dart`, et `features/after` importe cinq
fois `features/trek`. Deux voies, et c'est Christophe qui tranche (#I208) :

| Réf | Voie | Ce qu'elle coûte | Ce qu'elle rapporte |
|---|---|---|---|
| #X60 | **Voie A** — créer `lib/domain/` pour les modèles partagés (`stage`, `track_point`, `trek_session`) et y déplacer ce que plusieurs features lisent | un déplacement large, beaucoup d'imports réécrits | la convention redevient vraie, et le reste du plan tient |
| #X61 | **Voie B** — assumer `trek` comme socle et **réécrire la convention** en conséquence | presque aucun code touché | la convention décrit enfin le réel, mais `trek` reste un fourre-tout |

**Fichiers touchés.** Dépend de la voie. En voie A : les 3 modèles partagés plus
les 321 fichiers importateurs. En voie B : `docs/conventions.md` plus les
quelques infractions qui restent hors du cas `trek`.

**Traitement à part, et il est indépendant de l'arbitrage :**

| Réf | Cas isolé | Traitement |
|---|---|---|
| #X62 | `lib/core/providers/app_bootstrap_provider.dart` importe `features/safety/presentation/health_info_screen.dart` — **le socle importe un écran** (#I70) | indéfendable dans les deux voies. À corriger dans tous les cas, par inversion : l'écran s'enregistre auprès de l'amorçage, l'amorçage ne connaît pas l'écran |
| #X63 | `lib/features/group/presentation/follow_web_screen.dart` importe `cloud_firestore` — unique infraction ECR-25 (#I74) | à corriger dans tous les cas. Même fichier que le point 19 de l'inventaire 593 (`#100656`), qui le signalait déjà sans garde `isAvailable` |

**Comportement AVANT = APRÈS.** Un déplacement de fichier et une réécriture
d'import ne changent aucun comportement **si et seulement si** le type déplacé est
identique. Interdiction formelle dans ce lot : **fusionner deux types au passage**.
La fusion de `stage` et `track_point` est l'objet de SPEC-05, qui passe
**avant** — d'où la dépendance.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X64 | `flutter test` — 4002 passés, aucun test modifié |
| #X65 | `test/structurel/couches_respectees_645_test.dart` — plafond abaissé par étape |
| #X66 | `flutter build appbundle --release` réussit |
| #X67 | `flutter analyze --no-pub` — No issues found! (un import orphelin serait remonté par `unused_import`, qui est actif) |

**Critère de réussite.** En voie A : zéro import socle → feature, zéro croisement
hors `lib/domain/`. En voie B : la convention réécrite décrit le réel, et le test
d'architecture vérifie **la convention réécrite**. Dans les deux cas : #X62 et
#X63 sont corrigés, et 4002 tests passent.

**Retour arrière.** `git revert`. Lot à découper par **zone de départ**
(`core/`, puis `shared/`, puis une feature à la fois) — jamais en un seul commit.

---

## SPEC-07 — Découper les fichiers et les `build()` hors plafond

**Quoi.** Ramener les **50 fichiers** de plus de 500 lignes sous le plafond, et
les **206 fonctions** de plus de 60 lignes sous le seuil de refus.

**Pourquoi.** ECR-15 et ECR-28. Mesures #I29 à #I46 et #I47 à #I59 :
**50 fichiers hors plafond contre 31 le 21/09 (+19 en onze jours)** ; le plus
gros à **2 028 lignes** ; et **neuf des dix fonctions les plus longues sont des
`build()`**, dont une de **679 lignes** (`hub_screen.dart:88`). C'est exactement
le diagnostic d'ECR-28 : la méthode `build()` qui enfle au lieu d'être découpée.

**Méthode imposée par ECR-28, et ce n'est pas un détail.** Une `build()` trop
longue se découpe en **sous-widgets nommés**, pas en méthodes privées
`_buildXxx`. Raison citée par la règle : un sous-widget est reconstruit
indépendamment, une méthode privée non. Un découpage en `_buildHeader()`,
`_buildStats()` est donc **refusé** : il réduit le chiffre sans améliorer le code.

**Fichiers touchés, ordre imposé par le gain.**

| Réf | Vague | Cibles |
|---|---|---|
| #X68 | vague 1 — les 5 pires `build()` | `hub_screen.dart:88` (679 l.), `nuitees_screen.dart:446` (382), `map_screen.dart:350` (361), `health_info_screen.dart:622` (310), `checklist_item_widget.dart:80` (240) |
| #X69 | vague 2 — les 5 pires fichiers | `trek_feasibility_screen.dart` (2028 l.), `health_info_screen.dart` (1764), `feasibility_formula.dart` (1644), `monetization_service.dart` (1490), `map_screen.dart` (1232) |
| #X70 | vague 3 — les 20 fonctions de complexité > 10, en tête `importGpxFile` (complexité 25) | `gpx_import_service.dart:259` et suivants |
| #X71 | vague 4 — le reste des 50 fichiers | 40 fichiers restants |

**Comportement AVANT = APRÈS.** C'est le lot le plus long mais le moins risqué
**si la règle est tenue** : extraire un sous-widget ne change rien tant que
l'arbre de widgets produit est identique. Point de vigilance : extraire un
`StatefulWidget` d'une `build()` qui lisait l'état du parent **change** le cycle
de vie. Règle imposée : l'état reste chez le parent, les sous-widgets reçoivent
leurs données en paramètres nommés.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X72 | `flutter test` — 4002 passés. Les tests de widget vérifient l'arbre rendu : un découpage qui change l'arbre les fait échouer |
| #X73 | `test/structurel/taille_et_rangement_645_test.dart` — plafond ECR-15 abaissé par vague |
| #X74 | `python tool/audit_global.py --section complexite` — les compteurs #I47 et #I48 baissent |
| #X75 | captures avant / après via `integration_test/persona_*` sur les 5 écrans de la vague 1 |

**Critère de réussite.** Par vague : le plafond du test baisse, 4002 tests
passent, les captures sont identiques. Le lot est **explicitement sécable** : il
peut s'arrêter après n'importe quelle vague sans laisser le dépôt dans un état
intermédiaire.

**Retour arrière.** `git revert`, **un commit par fichier découpé**.

---

## SPEC-08 — Passer les identifiants en anglais

**Quoi.** Renommer les **442 identifiants** portant un mot français et les
**31 fichiers** au nom français.

**Pourquoi.** Décision **IDE-001** de Christophe : le code est en anglais. ECR-05,
déjà en vigueur avec 5 sources concordantes dans le dépôt
(`docs/conventions.md` ligne 62, `docs/CONTRIBUTING.md` lignes 7-8, et trois
fiches d'agent). Proposition 1 des huit (`#100928`) : « le code mélange les deux
(`monteeEnBaseDemarreeProvider` vs `syncScheduler`) ».

**Rappel de la règle complète, parce qu'elle a deux moitiés :** les
**identifiants** passent en anglais, les **commentaires et doc comments restent
en français accentué**. Ce lot ne touche pas une ligne de commentaire.

**Fichiers touchés.** 197 fichiers sur 599 (#I112). Ordre imposé par la
visibilité et la facilité :

| Réf | Étape | Cibles | Volume |
|---|---|---|---|
| #X76 | étape 1 — les **noms de fichier** | les 31 de #I124 à #I140 | 31 renommages, plus les imports |
| #X77 | étape 2 — `lib/core/services` | #I114 | 92 identifiants |
| #X78 | étape 3 — `lib/core/branding` | #I121 — `cremeSentier`, `orangeSentier`, `catalogueSentiers`, `diplome`… | 21 identifiants |
| #X79 | étape 4 — les features, par ordre décroissant | `safety` (45), `trail` (33), `feasibility` (27), `trek` (27), `map` (26), `planning` (23), `booking` (18), `hub` (18), puis le reste | ~ 298 identifiants |

**Comportement AVANT = APRÈS.** Un renommage pur est sans effet… **sauf dans
quatre cas**, et ils sont mesurés dans le dépôt :

| Réf | Piège | Garde imposée |
|---|---|---|
| #X80 | un nom de classe sérialisé par `json_serializable` ou `freezed` apparaît dans le **JSON produit** | regénérer (`dart run build_runner`) et vérifier que le JSON produit est **identique** ; sinon, figer le nom de champ par `@JsonKey(name:)` |
| #X81 | un nom utilisé comme **clé Drift** ou nom de colonne touche le schéma de base | ne pas renommer la colonne ; renommer seulement le symbole Dart |
| #X82 | un nom cité en **chaîne de caractères** (clé de préférence, nom de route, clé d'analytics) | rechercher la chaîne avant de renommer ; une clé stockée sur le téléphone du randonneur **ne se renomme pas** |
| #X83 | un nom de **clé i18n** Slang | les clés i18n sont hors périmètre de ce lot |

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X84 | `flutter test` — 4002 passés |
| #X85 | `dart run build_runner build --delete-conflicting-outputs` puis `git diff` sur les `.g.dart` et `.freezed.dart` : **seuls les noms de symbole changent**, aucun nom de champ sérialisé |
| #X86 | test de migration Drift : ouvrir une base écrite **avant** le lot et vérifier qu'elle se lit après |
| #X87 | `python tool/audit_global.py --section langue` — le compteur #I111 baisse |

**Critère de réussite.** Par étape : le compteur baisse, 4002 tests passent, le
diff des fichiers générés ne montre aucun changement de nom sérialisé, et la base
d'avant se relit.

**Retour arrière.** `git revert`, **un commit par étape**, et un tag de retour
avant l'étape 1. C'est le lot le plus mécanique du plan, donc celui où un
`revert` est le plus sûr — mais aussi celui qui touche le plus de fichiers, donc
celui où un `revert` tardif coûterait le plus cher. D'où le découpage en 4 étapes.

---

## SPEC-09 — Supprimer les valeurs à compléter livrées au randonneur

**Quoi.** Traiter les **45** valeurs à compléter présentes dans le code livré :
6 `example.org` et 39 « a completer ».

**Pourquoi.** Mesures #I95 à #I101. Ce sont des **données affichées au
randonneur** : des URL de lien profond `https://example.org/epicerie` et des
horaires de commerce marqués « a completer ». C'est **exactement** le point 22 de
l'inventaire 593 du 26/09 (`#100656`) : « hébergements et guides de ville =
données inventées ». Six jours plus tard, c'est toujours là. Proposition 2 des
huit (`#100928`) : « aucune valeur à compléter / example.org en prod ».

**Exception assumée à la règle du comportement inchangé (#X01).** Afficher
`example.org` à un randonneur n'est pas un comportement à préserver. **Mais la
correction n'est pas technique : c'est une décision produit**, et elle appartient
à Christophe.

**Fichiers touchés.**

| Réf | Fichier:ligne | Contenu | Décision attendue |
|---|---|---|---|
| #X88 | `lib/features/guides/domain/town_guide_catalog.dart:66, 77, 118` | `deeplinkUrl: 'https://example.org/epicerie'`, `/gite`, `/supermarche` | vraies URL, ou **retirer le champ** et ne rien promettre |
| #X89 | `lib/features/booking/providers/hebergement_peripherique_providers.dart:66, 75, 84` | `deeplinkUrl: 'https://example.org/...'` | idem |
| #X90 | `lib/features/planning/domain/shop_catalog.dart` — 39 occurrences, dont `:122`, `:140`, `:154`, `:170`, `:204`, `:220`, `:238`, `:247` | `openingHours: 'a completer'` et variantes | vrais horaires, ou **ne pas afficher la ligne** quand l'horaire est inconnu |

**Trois voies, à trancher par Christophe avant que le lot s'ouvre :**

| Réf | Voie | Effet |
|---|---|---|
| #X91 | **renseigner** les vraies valeurs | demande une collecte de données terrain, hors code |
| #X92 | **masquer** proprement : le champ absent n'affiche rien, au lieu d'afficher un texte creux | c'est la voie la plus sûre, et c'est celle déjà appliquée aux goodies le 25/09 (tâche 552, `#100656` point 20) |
| #X93 | **retirer** la fonctionnalité jusqu'à ce que les données existent | c'est ce que Christophe a fait pour le guide des villes, qu'il a lui-même masqué (`hub_screen.dart:618-631`) |

**Précédent qui éclaire le choix :** le dépôt a déjà deux honnêtetés différentes
pour le même problème. Les goodies ne promettent plus rien (propre, conforme à la
consigne du 25/09) ; `booking` promet encore « Disponibilités bientôt
disponibles ». La voie #X92 aligne tout le dépôt sur la consigne déjà donnée.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X94 | `test/structurel/aucune_valeur_a_completer_645_test.dart` — plafond de 45 à 0 |
| #X95 | `flutter test` — 4002 passés ; les tests qui vérifient l'affichage de ces écrans sont **mis à jour volontairement**, et c'est la seule exception du plan |
| #X96 | essai manuel sur émulateur des 3 écrans concernés : aucun texte creux visible |

**Critère de réussite.** Zéro `example.org` et zéro « a completer » hors
commentaire dans `lib/`, et l'écran concerné ne montre jamais de ligne vide à la
place.

**Retour arrière.** `git revert`, un commit par fichier (3 commits).

---

## SPEC-10 — Poser l'observabilité sur les 54 écrans nus

**Quoi.** Poser une miette d'observabilité sur les **54 écrans** qui n'en ont
aucune, selon une convention de nommage décidée.

**Pourquoi.** Mesures #I171 à #I183 : **9 écrans sur 63, soit 14,3 %**.
Proposition 6 des huit (`#100928`) : « miettes standard, erreurs attrapées
remontées, sessions sans plantage lues à chaque build avant de dire c'est bon ».
Et point 18 de l'inventaire 593 (`#100656`) : « aucun rapport de plantage ni
statistique, à 100 % » — « vendre une appli sans savoir qu'elle plante est un
pari ».

**Contrainte de conception, chiffrée et non négociable (corpus S4) :**

| Réf | Ressource Crashlytics | Limite officielle | Ce que ça impose |
|---|---|---|---|
| #X97 | clés personnalisées | **64 maximum**, 1 ko chacune ; au-delà, **les valeurs ne sont plus enregistrées** | avec 63 écrans, « une clé par écran » est **impossible**. Il faut une clé `screen` dont la **valeur** change, pas une clé par écran |
| #X98 | miettes `log()` | **64 ko par session**, les anciennes sont **effacées** | les miettes doivent être courtes et peu nombreuses ; une miette par geste saturerait la session |
| #X99 | erreurs non fatales | **8 par session** seulement | on ne peut pas tout remonter en non fatal ; il faut choisir ce qui mérite une remontée |

**Convention proposée, à valider par Christophe avant le lot.** Trois clés au
total, pas 63 : `screen` (nom de l'écran courant), `trail` (sentier actif),
`stage` (étape en cours). Plus une miette `log()` à l'entrée de chaque écran, au
format court `screen:<nom>`. Budget : 3 clés sur 64, et 63 miettes courtes par
session au pire — très en dessous des 64 ko.

**Fichiers touchés.** Les 54 écrans sans miette, **plus** un point central :
l'instrumentation doit passer par **un seul** service, pas par 54 appels
dispersés à `FirebaseCrashlytics.instance`. Le dépôt a déjà
`lib/core/analytics/analytics_service.dart` — c'est là que ça se branche.

**Exception assumée (#X02).** Poser une miette **ajoute** un effet : un envoi
réseau conditionnel. Aucun comportement visible ne change, mais ce n'est pas
rigoureusement « zéro effet ». Garde imposée : l'instrumentation doit être
**inerte** quand Firebase est indisponible — ce qui est le cas 100 % du temps
aujourd'hui (`analytics_service.dart:209-213` rend `disabled()`, point 18 de
`#100656`). Un écran ne doit jamais ralentir ni échouer parce qu'une miette n'a
pas pu partir.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X100 | `flutter test` — 4002 passés |
| #X101 | test nouveau : avec un service d'observabilité en échec, chaque écran s'affiche quand même |
| #X102 | test nouveau : le nombre de **clés distinctes** posées par l'application est **inférieur ou égal à 64** — c'est la limite officielle, et elle mérite son test |
| #X103 | `python tool/audit_global.py --section observabilite` — #I172 passe de 9 à 63 |

**Critère de réussite.** 63 écrans sur 63 instrumentés, par un service unique,
inerte en cas d'indisponibilité, et sous les trois budgets #X97 à #X99.

**Retour arrière.** `git revert`. Un commit pour le service central, puis un
commit par groupe de 10 écrans.

---

## SPEC-11 — Monter les dépendances résolubles

**Quoi.** Monter les paquets dont la version **résoluble** est déjà la dernière,
sans toucher à ceux qui sont bloqués par une contrainte.

**Pourquoi.** Mesures #I186 à #I194 : **188 paquets obsolètes, dont 72 en saut de
version majeure**. Proposition 5 des huit (`#100928`) : la gate complète doit
inclure « dépendances à jour ».

**Distinction mesurée qui découpe le lot en deux.**

| Réf | Catégorie | Exemples mesurés | Traitement |
|---|---|---|---|
| #X104 | **résoluble tout de suite** — la colonne « résoluble » est déjà la dernière | `cloud_firestore` 5.6.12 → 6.10.0 ; `connectivity_plus` 5.0.2 → 7.3.1 ; `battery_plus` 6.2.3 → 7.1.2 ; `carp_serializable` 2.0.1 → 3.0.0 | lot court, un paquet par commit |
| #X105 | **bloqué par une contrainte** — le résoluble reste l'actuel | `cached_network_image` 3.4.1 (dernier 4.0.4) ; `analyzer` 10.0.1 (dernier 14.4.0) | **hors de ce lot** : demande de lever une contrainte amont, à instruire à part |

**Exception assumée (#X03).** C'est **le seul lot du plan où la gate complète ne
suffit pas**. Une montée majeure peut changer un comportement sans qu'on le
veuille, et aucun test ne garantit l'absence de régression sur un comportement
qui n'était pas testé. `cloud_firestore` 5 → 6 touche la couche réseau ;
`connectivity_plus` 5 → 7 touche la détection hors ligne, qui est le cœur de
StepWays.

**Garde supplémentaire imposée, propre à ce lot :** chaque paquet monté demande
un **essai sur émulateur** du parcours qu'il touche, en plus de la gate. Pas de
montée « à l'aveugle parce que les tests passent ».

**Fichiers touchés.** `pubspec.yaml`, `pubspec.lock`, et le code d'adaptation
éventuel.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X106 | `flutter test` — 4002 passés |
| #X107 | `flutter build appbundle --release` réussit |
| #X108 | essai émulateur du parcours touché, paquet par paquet : hors ligne pour `connectivity_plus`, lecture/écriture distante pour `cloud_firestore`, économie de batterie pour `battery_plus` |
| #X109 | `flutter pub outdated` — le compteur #I186 baisse |

**Critère de réussite.** Les 4 paquets de #X104 montés, 4002 tests passent,
release construite, et l'essai émulateur de chaque parcours touché est constaté.

**Retour arrière.** `git revert` **un paquet par commit** — c'est obligatoire ici,
pas recommandé : une régression doit pouvoir être isolée à un seul paquet.

---

## SPEC-12 — En-têtes de fichier et couleurs au thème

**Quoi.** Deux chantiers de fond, sans risque, à mener en continu :
poser un en-tête aux **479 fichiers** qui n'en ont pas, et porter les
**40 couleurs en dur** dans le thème.

**Pourquoi.** ECR-01 et ECR-24. Mesures #I108 à #I110 et #I89 à #I94 :
**20,0 % de fichiers avec en-tête** (contre 17,5 % le 21/09 — la part progresse,
mais le nombre absolu augmente de 429 à 479 parce que le dépôt grandit plus vite
que la discipline) ; et 40 couleurs en dur hors `core/theme/` et
`core/branding/`, dont deux valeurs **répétées deux fois chacune** dans
`checklist_weight_banner.dart` (#I90/#I92 et #I91/#I93) — ce qui en fait aussi
une infraction ECR-21.

**Comportement AVANT = APRÈS.** L'en-tête est un commentaire : zéro effet. La
couleur portée au thème **doit garder exactement la même valeur
hexadécimale** — c'est un déplacement, pas une harmonisation. Toute envie
d'harmoniser les teintes est une **évolution** et sort du périmètre.

**Fichiers touchés.** 479 fichiers pour les en-têtes ; pour les couleurs, en tête
`checklist_weight_banner.dart` (4 occurrences) et
`community/domain/waypoint_type_config.dart`.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X110 | `flutter test` — 4002 passés |
| #X111 | `python tool/audit_global.py --section documentation` — #I108 monte vers 100 % |
| #X112 | `python tool/audit_global.py --section composants_et_valeurs` — #I89 descend vers 0 |
| #X113 | captures avant / après : **la couleur affichée est identique au pixel** |

**Critère de réussite.** Part d'en-têtes en progression mesurée à chaque lot ;
zéro `Color(0x` hors `core/theme/` et `core/branding/` ; aucune différence
visuelle.

**Retour arrière.** `git revert`. Les en-têtes sont **sécables à volonté** : ce
lot sert de variable d'ajustement du plan — on en fait autant que le budget
permet, et il n'y a jamais d'état intermédiaire gênant.

---

## SPEC-13 — Livre de bord du dépôt

**Quoi.** Un `docs/JOURNAL.md` court, vérifié par un test, qui renvoie aux
numéros de décision en base ; et un schéma d'architecture à jour.

**Pourquoi.** Propositions 3 et 8 des huit (`#100928`) : « décisions hors du
code : commentaire = pourquoi en une phrase + numéro de décision en base — 31 %
de commentaires narratifs qui vieillissent » et « livre de bord du dépôt : docs
vérifiés par test, schéma d'architecture à jour, journal court des décisions
renvoyant à la base ».

**Preuve mesurée que c'est nécessaire.** ECR-04 citait déjà le cas :
`docs/CONTRIBUTING.md` ligne 36 et `docs/ADR/003-riverpod-over-bloc.md` ligne 124
annonçaient Riverpod 2.6 alors que `pubspec.yaml` était en `flutter_riverpod`
3.3.2. **La doc périmée a déjà induit en erreur.** Un document que rien ne
vérifie devient faux, et il devient faux en silence.

**Fichiers touchés.**

| Réf | Fichier | Nature |
|---|---|---|
| #X114 | `docs/JOURNAL.md` | NOUVEAU — une ligne par lot : date, numéro, ce qui a changé, numéro de décision en base |
| #X115 | `docs/architecture.md` | MODIFIÉ — remis au réel mesuré par l'audit |
| #X116 | `test/structurel/la_doc_ne_mente_pas_645_test.dart` | NOUVEAU — vérifie que les versions citées dans la doc **sont** celles de `pubspec.yaml`, et que chaque lot du plan a sa ligne de journal |

**Comportement AVANT = APRÈS.** Aucun fichier de `lib/` touché.

**Précédent dans le dépôt :** `test/structurel/codemagic_entete_ne_mente_pas_619_test.dart`
fait **déjà exactement cela** pour `codemagic.yaml`. Ce lot étend un motif qui
existe et qui a fait la preuve de son utilité.

**Tests qui le prouvent.**

| Réf | Vérification |
|---|---|
| #X117 | `flutter test test/structurel/la_doc_ne_mente_pas_645_test.dart` passe |
| #X118 | essai de régression : changer une version dans `pubspec.yaml` sans toucher la doc doit faire **échouer** le test |

**Critère de réussite.** Le test existe, passe, et l'essai de régression échoue
bien. Aucune version citée dans la doc ne diverge de `pubspec.yaml`.

**Retour arrière.** `git revert`. Aucun risque applicatif.

---

## Récapitulatif : où va chacune des huit propositions de Christophe

Décision du 30/09 : « Ok sur toutes tes propositions » (`#100930`).

| Réf | Proposition (`#100928`) | Spéc | Lot |
|---|---|---|---|
| #X119 | 1 — une langue pour le code : identifiants en anglais | SPEC-08 | 645-07 |
| #X120 | 2 — tests d'architecture : couches, code mort, doublons, dialogues hors Navigator, valeurs à compléter | **SPEC-01** | **645-01, en premier** |
| #X121 | 3 — décisions hors du code, avec numéro de décision en base | SPEC-13 | 645-12 |
| #X122 | 4 — contrat de données versionné, testé des 3 côtés | **non couvert par ce plan** — voir #X124 | hors 645 |
| #X123 | 5 — gate complète : format, analyse, tests, dépendances, version Flutter épinglée, aucun identifiant sensible | SPEC-01 (lints) + SPEC-11 (dépendances) ; **le volet version Flutter épinglée et identifiants sensibles n'est pas couvert** | 645-01, 645-10, + reste ouvert |
| #X124 | 6 — observabilité | SPEC-10 | 645-09 |
| #X125 | 7 — campagne personas automatisée sur émulateur en CI | **non couvert par ce plan** | hors 645 |
| #X126 | 8 — livre de bord du dépôt | SPEC-13 | 645-12 |

**Trois propositions ne sont PAS couvertes par ce plan, et il faut le dire
franchement :**

| Réf | Proposition | Pourquoi elle sort du périmètre |
|---|---|---|
| #X127 | 4 — contrat de données versionné | ce n'est pas de l'assainissement : c'est une **conception**. Elle touche l'outil de publication, les règles Firestore et le lecteur Drift — trois composants, dont deux hors de `lib/`. Elle mérite sa propre tâche de conception, après le temps 3 |
| #X128 | 5, volet « version Flutter épinglée local = CI » et « aucun identifiant sensible » | c'est de l'**outillage CI**, pas du code applicatif. Touche `codemagic.yaml` et la configuration de la machine. Lot séparé, sans risque pour l'application |
| #X129 | 7 — campagne personas automatisée en CI | demande un émulateur **dans la CI**, ce qui est une question d'infrastructure et de coût de minutes de build, pas d'assainissement de code |

---

*Fin du 644-02. Suite : `644-03-decoupage-et-plan.md`.*
