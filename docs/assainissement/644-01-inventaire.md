# 644-01 — L'inventaire MESURÉ, pas supposé

> Tâche 644, temps 2 de l'assainissement StepWays. Athena, 02/10/2026.
> Dépôt **Moteur-GR** (jamais GR20). Tête mesurée : **147ca32d**, tête de
> `claude/integration/633-version-complete` après le formatage du lot 643.
> Worktree de mesure : `.claude/worktrees/moteur-gr-644-athena`, branche
> `claude/docs/644-audit-assainissement`. **Aucune ligne de `lib/` ni de
> `test/` n'a été modifiée.**
> Corpus source et limites de méthode : `644-00-sources.md`.

**Chaque constat ci-dessous porte son fichier:ligne et la commande qui l'a
mesuré.** Tout est rejouable par `python tool/audit_global.py` (voir
`644-04-audit-global.md`).

---

## 0. Le chiffre qui résume tout, et le paradoxe qu'il faut comprendre

| Réf | Mesure sur la tête 147ca32d | Valeur |
|---|---|---|
| #I01 | `flutter analyze --no-pub` | **No issues found!** — 0 erreur, 0 avertissement, 0 info |
| #I02 | `dart format --set-exit-if-changed lib test tool` | **0 fichier** à reformater |
| #I03 | `flutter test` | **4002 tests passés, 2 ignorés, 3 min 56 s — All tests passed** |
| #I04 | `python tool/audit_global.py` | **889 infractions bloquantes**, 12 familles, **1759 avertissements** |

**Les quatre lignes sont vraies en même temps, et ce n'est pas une contradiction.**

La gate actuelle est verte parce qu'elle ne pose que les questions que
`flutter_lints` sait poser. `analysis_options.yaml` n'active **aucune** règle
supplémentaire : sa section `rules:` ne contient que deux lignes commentées
(lignes 29-30). Les sept règles que le référentiel ECR réclame sont **absentes** :
`public_member_api_docs`, `directives_ordering`, `lines_longer_than_80_chars`,
`avoid_print`, `prefer_single_quotes`, `unnecessary_lambdas`,
`always_declare_return_types`.

Et surtout — source `644-00` point S1 — `unused_element` de Dart **ne voit que
les déclarations privées**. 152 symboles publics sans aucun appelant sont donc
invisibles pour l'analyseur, par conception.

**Conclusion de méthode :** le code n'est pas « cassé ». Il est **non mesuré**.
Le temps 3 ne doit pas commencer par corriger, il doit commencer par **armer la
mesure** — c'est le lot 645-01.

---

## 1. Arborescence et volumes

Commande : `python tool/audit_global.py --section arborescence`
(parcours de `os.walk`, exclusion de `.dart_tool` et `build`, fichiers générés
identifiés par les suffixes `.g.dart`, `.freezed.dart`, `.gr.dart`,
`.config.dart`).

| Réf | Zone | Fichiers source | Générés | Lignes source |
|---|---|---|---|---|
| #I05 | `lib/` | **599** | 120 | **121 507** |
| #I06 | `test/` | 482 | 0 | 114 963 |
| #I07 | `tool/` | 4 | 0 | 1 825 |
| #I08 | `integration_test/` | 13 | 0 | 10 550 |

Répartition de `lib/` par zone (récursif, hors générés) :

| Réf | Zone | Fichiers | Lignes |
|---|---|---|---|
| #I09 | `lib/core/` | 173 | 28 786 |
| #I10 | `lib/features/` | **396** | **87 642** |
| #I11 | `lib/shared/` | 26 | 4 120 |
| #I12 | `lib/i18n/` | 1 | 26 |
| #I13 | `lib/docs/` | 2 | 337 |
| #I14 | `lib/main.dart` | 1 | 596 |

Les cinq features les plus grosses, qui portent à elles seules **49 %** des
lignes de `lib/features/` :

| Réf | Feature | Fichiers | Lignes |
|---|---|---|---|
| #I15 | `features/trek/` | 64 | 14 792 |
| #I16 | `features/planning/` | 29 | 9 914 |
| #I17 | `features/feasibility/` | 28 | 9 767 |
| #I18 | `features/safety/` | 25 | 6 833 |
| #I19 | `features/checklist/` | 19 | 5 679 |

Répartition de `test/` :

| Réf | Zone de test | Fichiers | Lignes |
|---|---|---|---|
| #I20 | `test/features/` | 302 | 61 107 |
| #I21 | `test/comportement/` | 52 | 26 946 |
| #I22 | `test/core/` | 84 | 15 890 |
| #I23 | `test/structurel/` | **15** | 4 378 |
| #I24 | `test/shared/` | 11 | 2 063 |
| #I25 | autres (`personas`, `drift`, `i18n`, `outillage`, `privacy`, `fixtures`, `integration_harness`) | 18 | 4 201 |

---

## 2. ECR-13 — un seul intrus à la racine de `lib/`, et il est documenté

Commande : listing de `lib/` comparé à l'ensemble autorisé
`{core, features, shared, i18n, main.dart}`.

| Réf | Constat | Mesure |
|---|---|---|
| #I26 | Intrus à la racine de `lib/` | **`lib/docs/`** — 1 seul |

C'est le même intrus qu'au 21/09. Il contient deux guides de migration déposés
en `.dart`, traité par ECR-07 au point suivant.

---

## 3. ECR-07 — de la documentation compilée comme du code

Commande : `find lib -name '*.dart' -path '*/docs/*'`, puis recherche de
`ignore_for_file` dans les fichiers **source** de `lib/`.

| Réf | Fichier:ligne | Constat |
|---|---|---|
| #I27 | `lib/docs/flutter_map_v8_changes.dart:1` | `// ignore_for_file: unused_element` — il faut désarmer l'analyseur pour que de la documentation compile |
| #I28 | `lib/docs/riverpod_migration_guide.dart:1` | idem |

**Mesure rassurante au passage :** sur les 123 occurrences de `ignore_for_file`
du dépôt, **120 sont dans des fichiers générés** (`// ignore_for_file: type=lint`
en tête des `.g.dart` de Drift) — c'est légitime et attendu. **Il n'y a que ces
2 désarmements dans du code source**, et tous les deux sont dans `lib/docs/`.
Le dépôt est propre sur ce point une fois `lib/docs/` déplacé.

---

## 4. ECR-15 — la taille des fichiers : 50 au-delà du plafond

Commande : `wc -l` sur les `.dart` de `lib/` hors générés, filtre > 500.

| Réf | Tranche | Fichiers | Part |
|---|---|---|---|
| #I29 | 300 lignes ou moins (cible) | **488** | 81,5 % |
| #I30 | 301 à 500 | 61 | 10,2 % |
| #I31 | 501 à 800 (hors plafond) | 27 | 4,5 % |
| #I32 | plus de 800 (hors plafond) | **23** | 3,8 % |

**50 fichiers dépassent le plafond de 500 lignes**, contre 31 au 21/09 :
**+19 en 11 jours**. Les 14 plus gros :

| Réf | Lignes | Fichier |
|---|---|---|
| #I33 | **2 028** | `lib/features/feasibility/presentation/trek_feasibility_screen.dart` |
| #I34 | 1 764 | `lib/features/safety/presentation/health_info_screen.dart` |
| #I35 | 1 644 | `lib/features/feasibility/domain/feasibility_formula.dart` |
| #I36 | 1 490 | `lib/core/services/monetization_service.dart` |
| #I37 | 1 232 | `lib/features/trek/presentation/map/map_screen.dart` |
| #I38 | 1 231 | `lib/features/journal/presentation/journal_screen.dart` |
| #I39 | 1 192 | `lib/features/trek/presentation/stages/trek_stage_detail_screen.dart` |
| #I40 | 1 122 | `lib/features/planning/presentation/trail_planning_screen.dart` |
| #I41 | 1 055 | `lib/features/booking/presentation/nuitees_screen.dart` |
| #I42 | 1 002 | `lib/features/training/presentation/training_screen.dart` |
| #I43 | 994 | `lib/features/trek/data/background_gps_service.dart` |
| #I44 | 987 | `lib/features/planning/presentation/plan_summary_screen.dart` |
| #I45 | 898 | `lib/core/routing/app_router.dart` |
| #I46 | 898 | `lib/features/diploma/presentation/diploma_screen.dart` |

Point de comparaison du 21/09 (`#100234`) : le plus gros fichier était
`trek_stage_detail_screen.dart` à 1 128 lignes. Il est aujourd'hui **septième**,
et le premier a presque doublé ce record.

---

## 5. ECR-28 et ECR-31 — les fonctions : une `build()` de 679 lignes

Commande : `python tool/audit_global.py --section complexite`. Comptage
d'accolades, **mesure approchée et reproductible** (limite #S26 du corpus
source), sur 2 947 fonctions repérées.

| Réf | Critère | Mesure | Seuil |
|---|---|---|---|
| #I47 | fonctions au-delà de 60 lignes (refus) | **206** | 60 |
| #I48 | fonctions de complexité > 10 | **20** | 10 |
| #I49 | imbrication au-delà de 4 niveaux | 1 | 4 |

Les dix fonctions les plus longues — **neuf sur dix sont des `build()`**, ce qui
confirme exactement le diagnostic d'ECR-28 : la méthode `build()` qui enfle au
lieu d'être découpée en sous-widgets nommés.

| Réf | Lignes | Fonction | Fichier:ligne |
|---|---|---|---|
| #I50 | **679** | `build` | `lib/features/hub/presentation/hub_screen.dart:88` |
| #I51 | 382 | `build` | `lib/features/booking/presentation/nuitees_screen.dart:446` |
| #I52 | 361 | `build` | `lib/features/trek/presentation/map/map_screen.dart:350` |
| #I53 | 310 | `build` | `lib/features/safety/presentation/health_info_screen.dart:622` |
| #I54 | 240 | `build` | `lib/features/checklist/widgets/checklist_item_widget.dart:80` |
| #I55 | 235 | `build` | `lib/features/consent/presentation/consent_settings_screen.dart:32` |
| #I56 | 224 | `build` | `lib/features/trail/presentation/trail_catalog_screen.dart:297` |
| #I57 | 218 | `build` | `lib/features/checklist/presentation/checklist_screen.dart:47` |
| #I58 | 218 | `build` | `lib/features/planning/presentation/transport_screen.dart:274` |
| #I59 | 216 | `build` | `lib/features/monetization/presentation/subscription_screen.dart:118` |

Les fonctions les plus complexes :

| Réf | Complexité | Fonction | Fichier:ligne |
|---|---|---|---|
| #I60 | **25** | `importGpxFile` | `lib/features/after/data/gpx_import_service.dart:259` |
| #I61 | 15 | `_supprimer` | `lib/core/services/delta_update_service.dart:677` |
| #I62 | 14 | `annonceParLeServeur` | `lib/core/data/revision_de_donnee.dart:155` |
| #I63 | 14 | `balayer` | `lib/core/services/garde_sauvegarde_ios.dart:178` |
| #I64 | 14 | `_rafraichir` | `lib/features/trail/providers/catalogue_sentiers_provider.dart:126` |

Rappel de la source NIST SP 500-235 citée par ECR-31 : une fonction de
complexité 10 demande **déjà 10 tests** pour être couverte. `importGpxFile` à 25
en demanderait 25.

---

## 6. ECR-23 — le vrai gros morceau : 321 dépendances interdites

Commande : lecture des directives `import` de chaque fichier de `lib/`. Une
feature est le troisième segment du chemin.

| Réf | Infraction | Nombre |
|---|---|---|
| #I65 | **croisement entre deux features** | **243** |
| #I66 | **socle (`core/`, `shared/`) qui importe une feature** | **78** |
| #I67 | total ECR-23 | **321** |

C'est, en volume, le premier défaut du dépôt. Et il a une **forme** : la feature
`trek` s'est transformée en domaine partagé de fait. Échantillon mesuré :

| Réf | Fichier → import | Lecture |
|---|---|---|
| #I68 | `lib/core/geo/gpx_parser.dart` → `../../features/trek/data/gpx_parser.dart` | le socle appelle la feature pour son propre métier |
| #I69 | `lib/core/data/daos/trek_sessions_dao.dart` → `../../../features/trek/domain/models/trek_session.dart` | un DAO du socle dépend d'un modèle de feature |
| #I70 | `lib/core/providers/app_bootstrap_provider.dart` → `../../features/safety/presentation/health_info_screen.dart` | l'amorçage du socle importe un **écran** |
| #I71 | `lib/features/after/providers/adventure_recap_provider.dart` → `../../trek/domain/models/stage.dart` (+ 4 autres imports de `trek`) | 5 croisements dans un seul fichier |
| #I72 | `lib/features/booking/presentation/nuitees_screen.dart` → `../../planning/models/planned_day.dart` | `booking` lit le modèle de `planning` |

**Lecture honnête de ce chiffre** (voir corpus source S2) : l'interdiction du
croisement entre features est une **règle maison** du dépôt
(`docs/conventions.md` lignes 17-54), pas une citation de Flutter. Les 321
infractions ne sont donc pas 321 bugs : ce sont 321 écarts à une convention que
le dépôt s'est donnée et qu'il n'a jamais outillée. **Et c'est précisément
pourquoi elles sont là.**

**Bonne nouvelle mesurée :** le rangement par couche, lui, est **irréprochable**.

| Réf | Constat | Mesure |
|---|---|---|
| #I73 | fichiers de feature hors d'une couche reconnue | **0** |
| #I74 | ECR-25 — accès aux données depuis `presentation/` | **1** |

L'unique infraction ECR-25 :
`lib/features/group/presentation/follow_web_screen.dart` importe
`package:cloud_firestore/cloud_firestore.dart` depuis la couche présentation.
C'est le même fichier que le point 19 de l'inventaire 593 (`#100656`), qui le
signalait déjà comme accès Firestore sans garde `isAvailable`.

---

## 7. ECR-20 — quatre doublons de nom, soit un de plus qu'au 21/09

Commande : basename des `.dart` de `lib/` hors générés, trié, doublons conservés.

| Réf | Nom | Les deux emplacements | État au 21/09 |
|---|---|---|---|
| #I75 | `gpx_parser.dart` | `lib/core/geo/` et `lib/features/trek/data/` | déjà signalé |
| #I76 | `track_point.dart` | `lib/core/geo/` et `lib/features/trek/domain/models/` | déjà signalé |
| #I77 | `tracking_overlay.dart` | `lib/features/tracking/presentation/` et `lib/features/trek/presentation/map/overlay/` | déjà signalé |
| #I78 | **`stage.dart`** | `lib/core/models/` et `lib/features/trek/domain/models/` | **NOUVEAU** |

Le doublon `stage.dart` est apparu **entre le 21/09 et le 02/10**. C'est la
démonstration pratique de la règle ECR-22 : sans la question « qu'est-ce qui
existe déjà ? » posée avant de coder, le dépôt fabrique un doublon tous les dix
jours.

Les deux `gpx_parser.dart` ont une particularité mesurée : celui de `core/`
**importe** celui de `features/trek/` (#I68). Ce n'est donc plus une divergence,
c'est une délégation — le ménage y sera moins coûteux que prévu, mais il faut le
vérifier fichier par fichier avant de trancher (voir SPEC-05).

Doublon fonctionnel à noms différents signalé le 21/09 — `lib/core/ui/loading_view.dart`
et `lib/shared/widgets/loading_overlay.dart` — **toujours présent** : seule la
revue le détecte, aucune commande ne le voit.

---

## 8. ECR-18 — 114 blocs de code répétés trois fois ou plus

Commande : blocs de 6 lignes non vides et non commentaires, au moins
120 caractères, répétés 3 fois ou davantage.

| Réf | Constat | Mesure |
|---|---|---|
| #I79 | blocs de 6 lignes répétés 3 fois ou plus | **114** |

Seuil et justification : règle de trois de Fowler, *Refactoring* 1999, citée par
ECR-18. Le détail nominatif (40 premiers blocs, avec leurs lieux) est dans la
sortie JSON de l'audit, section `doublons.blocs_repetes_3_fois`.

---

## 9. ECR-19 — le composant unique est contourné 2,6 fois plus qu'au 21/09

Commande : appel des boutons du framework hors
`lib/shared/widgets/app_button.dart`. **`lib/core/theme/` est exclu** : la
définition du thème *doit* citer `ElevatedButtonThemeData` et
`ElevatedButton.styleFrom`, c'est son rôle (vérifié dans `app_theme.dart`
lignes 265-287 et 407).

| Réf | Périmètre | Occurrences | Fichiers | Référence 21/09 |
|---|---|---|---|---|
| #I80 | **strict** — les 4 boutons nommés par ECR-19 | **153** | 27 | 58 dans 24 fichiers |
| #I81 | étendu — + `IconButton`, `CupertinoButton` | 203 | — | non mesuré |

**58 → 153 : le contournement a été multiplié par 2,6 en onze jours**, alors que
`AppButton` existe, est bien fait et est documenté (8 paramètres nommés,
4 variantes). Les plus gros contributeurs :

| Réf | Occurrences | Fichier |
|---|---|---|
| #I82 | 16 | `lib/features/checklist/presentation/checklist_screen.dart` |
| #I83 | 13 | `lib/features/checklist/widgets/checklist_bottom_actions.dart` |
| #I84 | 10 | `lib/features/safety/presentation/health_info_screen.dart` |
| #I85 | 8 | `lib/features/planning/presentation/trail_planning_screen.dart` |
| #I86 | 7 | `lib/features/planning/presentation/calendar_screen.dart` |
| #I87 | 6 | `lib/features/booking/presentation/nuitees_screen.dart` |
| #I88 | 6 | `lib/features/hub/presentation/widgets/hub_start_trek_button.dart` |

Conséquence concrète, inchangée depuis le 21/09 : changer la hauteur tactile ou
la couleur d'un bouton demande d'ouvrir **27 fichiers** au lieu d'un.

---

## 10. ECR-24 — 40 couleurs en dur hors du thème

Commande : `Color(0x...)` hors de `lib/core/theme/` et `lib/core/branding/`.

| Réf | Constat | Mesure |
|---|---|---|
| #I89 | couleurs en dur hors thème et branding | **40** |

Échantillon :

| Réf | Fichier:ligne | Valeur |
|---|---|---|
| #I90 | `lib/features/checklist/widgets/checklist_weight_banner.dart:40` | `Color(0xFF9ACD32)` |
| #I91 | `lib/features/checklist/widgets/checklist_weight_banner.dart:58` | `Color(0xFF8B0000)` |
| #I92 | `lib/features/checklist/widgets/checklist_weight_banner.dart:450` | `Color(0xFF9ACD32)` (la même, deuxième fois) |
| #I93 | `lib/features/community/domain/waypoint_type_config.dart:38` | `Color(0xFF1565C0)` |
| #I94 | `lib/features/community/domain/waypoint_type_config.dart:43` | `Color(0xFF2E7D32)` |

Note : `checklist_weight_banner.dart` répète deux fois les mêmes deux valeurs
(#I90/#I92 et #I91/#I93) — c'est aussi une infraction ECR-21 (duplication de
connaissance).

---

## 11. Valeurs à compléter livrées en production — 45, et elles sont visibles

Commande : 10 motifs ancrés par frontière de mot, comptés **hors commentaire**.
Le volet « cité dans un commentaire » (25 occurrences) est donné à part et n'est
pas bloquant.

**Calibrage honnête, à savoir pour relire les chiffres :** une première mesure
annonçait 106 occurrences. Elle était fausse. Le motif `changeme` non ancré
attrapait le mot français « change**me**nt » (82 fois), et `placeholder`
attrapait le paramètre légitime `placeholder:` de Flutter. Après ancrage et
séparation code / commentaire : **45**.

| Réf | Motif | Occurrences dans le code |
|---|---|---|
| #I95 | `a completer` | **39** |
| #I96 | `example.org` | **6** |

Les `example.org` sont des **URL de lien profond livrées dans l'application** :

| Réf | Fichier:ligne | Contenu |
|---|---|---|
| #I97 | `lib/features/booking/providers/hebergement_peripherique_providers.dart:66, 75, 84` | `deeplinkUrl: 'https://example.org/...'` — 3 occurrences |
| #I98 | `lib/features/guides/domain/town_guide_catalog.dart:66, 77, 118` | `deeplinkUrl: 'https://example.org/epicerie'`, `/gite`, `/supermarche` |

C'est **exactement** le point 22 de l'inventaire 593 du 26/09 (`#100656`) :
« hébergements et guides de ville = données inventées ». Six jours plus tard,
c'est toujours là, et c'est mesuré.

Les `a completer` sont des **données affichées au randonneur** :

| Réf | Fichier:ligne | Contenu |
|---|---|---|
| #I99 | `lib/features/planning/domain/shop_catalog.dart:122` | `openingHours: 'Horaires d\'officine (a completer)'` |
| #I100 | `lib/features/planning/domain/shop_catalog.dart:170` | `openingHours: 'a completer'` |
| #I101 | `lib/features/planning/domain/shop_catalog.dart:140, 154, 204, 220, 238, 247…` | même famille, 39 au total |

---

## 12. ECR-04 — commentaires morts : 46 blocs, et **zéro TODO orphelin**

Commande : motif de code commenté (`// final`, `// return`, `// if (`,
`// import`, `// Navigator.`, `// setState`, `// print(`) ; puis TODO/FIXME/HACK
**en ouverture** de commentaire, sans numéro de tâche.

| Réf | Constat | Mesure |
|---|---|---|
| #I102 | lignes de code commenté livrées | **46** |
| #I103 | **TODO sans numéro de tâche** | **0** |

**Calibrage honnête :** une première mesure annonçait 5 TODO orphelins. Les cinq
étaient des faux positifs — des phrases qui *parlent* d'un TODO passé
(`gpx_export_service.dart:11` : « l'export était un TODO. Ce se… ») et des
gabarits de format écrits `XXXX` dans un doc comment
(`finisher_number.dart:20` : « Forme : `SW-AAAAMMJJ-XXXX` »). Après ancrage du
motif en ouverture de commentaire : **0**.

**Le dépôt est donc exemplaire sur la discipline des TODO.** C'est à dire
explicitement, parce que c'est rare.

Échantillon de code commenté :

| Réf | Fichier:ligne |
|---|---|
| #I104 | `lib/core/routing/contextual_actions_provider.dart:80` |
| #I105 | `lib/core/services/consent_service.dart:29` |
| #I106 | `lib/core/services/delta_update_service.dart:635` |
| #I107 | `lib/docs/flutter_map_v8_changes.dart:47` et `:48` (déjà couvert par ECR-07) |

---

## 13. ECR-01 et ECR-03 — l'en-tête de fichier manque à 80 % des fichiers

Commande : une des 3 premières lignes commence par `///`.

| Réf | Constat | Mesure | 21/09 |
|---|---|---|---|
| #I108 | fichiers source **avec** en-tête | **120 / 599 = 20,0 %** | 17,5 % |
| #I109 | fichiers source **sans** en-tête | **479** | 429 / 520 |
| #I110 | commentaires qui paraphrasent le code (ECR-03) | 13 | non mesuré |

**20,0 % contre 17,5 % le 21/09 : la part progresse**, mais le nombre absolu de
fichiers sans en-tête augmente (429 → 479), parce que le dépôt grandit plus vite
que la discipline ne s'installe. Métrique de progression, cible 100 %.

Les 13 commentaires bavards sont détectés par un critère écrit : **plus de 60 %
des mots de 3 lettres ou plus du commentaire sont présents dans la ligne de code
suivante**. C'est peu, et c'est une bonne nouvelle : le dépôt commente le
pourquoi, pas le quoi.

---

## 14. ECR-05 — 442 identifiants français à passer en anglais

Commande : liste fermée de 94 mots français cherchés dans les identifiants, hors
chaînes et commentaires, identifiants de moins de 4 lettres ignorés. Décision
IDE-001 de Christophe : le code est en anglais.

| Réf | Constat | Mesure |
|---|---|---|
| #I111 | identifiants portant un mot français | **442** |
| #I112 | fichiers touchés | **197** sur 599 |
| #I113 | **noms de fichier** en français | **31** |

Répartition par dossier (les 10 premiers) :

| Réf | Dossier | Identifiants |
|---|---|---|
| #I114 | `lib/core/services` | **92** |
| #I115 | `lib/features/safety` | 45 |
| #I116 | `lib/features/trail` | 33 |
| #I117 | `lib/features/feasibility` | 27 |
| #I118 | `lib/features/trek` | 27 |
| #I119 | `lib/features/map` | 26 |
| #I120 | `lib/features/planning` | 23 |
| #I121 | `lib/core/branding` | 21 |
| #I122 | `lib/features/booking` | 18 |
| #I123 | `lib/features/hub` | 18 |

Les 31 noms de fichier en français, nominativement — ce sont les plus visibles
et les plus faciles à traiter en premier :

| Réf | Fichier |
|---|---|
| #I124 | `lib/core/config/sentier_distant.dart` |
| #I125 | `lib/core/geo/trace_du_sentier.dart` |
| #I126 | `lib/core/services/descente_des_cartes.dart` |
| #I127 | `lib/core/services/fiche_technique_du_telephone.dart` |
| #I128 | `lib/core/services/source_de_donnees_sentier.dart` |
| #I129 | `lib/core/services/source_firestore_sentier.dart` |
| #I130 | `lib/features/ads/domain/etat_publicite.dart` |
| #I131 | `lib/features/ads/presentation/badge_etat_publicite.dart` |
| #I132 | `lib/features/feasibility/data/profil_randonneur_fichier.dart` |
| #I133 | `lib/features/map/presentation/cartes_hors_ligne_screen.dart` |
| #I134 | `lib/features/planning/models/variante_etape.dart` |
| #I135 | `lib/features/safety/data/copie_sauvegardable_fiche_service.dart` |
| #I136 | `lib/features/safety/data/fiche_medicale_fichier.dart` |
| #I137 | `lib/features/safety/data/prise_photo_carte.dart` |
| #I138 | `lib/features/safety/presentation/porte_consentement_sauvegarde.dart` |
| #I139 | `lib/features/trail/domain/etat_du_sentier.dart` |
| #I140 | + 15 autres (`journal_*`, `session_trace_*`, `*_dao.dart`, liste complète dans la sortie JSON) |

Échantillon d'identifiants, pour donner la couleur : `cremeSentier`,
`orangeSentier`, `vertSentier` (`core/branding/app_branding.dart`) ;
`catalogueSentiers`, `deconnexion`, `diplome`, `duree`, `enregistrer`, `meteo`,
`monCompte`, `poids` (`core/branding/stepways_icons.dart`) ;
`EntreeManifesteEnSentier`, `versSentier` (`core/config/sentier_distant.dart`) ;
`marquerEtape` (`core/analytics/analytics_service.dart`).

---

## 15. Code mort — 152 candidats publics, invisibles pour l'analyseur

Commande : déclarations de haut niveau de `lib/` (classe, enum, mixin,
extension, typedef, fonction de premier niveau, hors `_privé`) sans **aucune**
citation dans `lib/`, `test/`, `integration_test/`, `tool/` en dehors de leur
propre fichier.

| Réf | Constat | Mesure |
|---|---|---|
| #I141 | déclarations publiques recensées | 1 047 |
| #I142 | **candidats au code mort** | **152** (14,5 %) |

**Rappel capital (corpus source S1) :** `flutter analyze` rend « No issues
found! » sur ce même code. L'analyseur Dart **ne regarde pas** les déclarations
publiques — par conception documentée. Ces 152 symboles ne pouvaient donc pas
être trouvés autrement que par un outil maison.

Répartition :

| Réf | Dossier | Candidats |
|---|---|---|
| #I143 | `lib/core/services` | **23** |
| #I144 | `lib/features/trek` | 19 |
| #I145 | `lib/features/settings` | 11 |
| #I146 | `lib/features/trail` | 7 |
| #I147 | `lib/features/map` | 7 |
| #I148 | `lib/features/planning` | 6 |
| #I149 | `lib/features/safety` | 5 |
| #I150 | `lib/features/journal` | 5 |

Dix premiers, nominativement :

| Réf | Symbole | Fichier:ligne |
|---|---|---|
| #I151 | `AccountErasure` | `lib/features/settings/providers/account_erasure_provider.dart:67` |
| #I152 | `ActiveTrekConflictResolver` | `lib/features/trek/providers/tracking_providers.dart:113` |
| #I153 | `AppLanguage` | `lib/features/settings/providers/settings_provider.dart:9` |
| #I154 | `AppThemeMode` | `lib/features/settings/providers/settings_provider.dart:74` |
| #I155 | `AsyncValueUI` | `lib/core/extensions/async_value_extensions.dart:12` |
| #I156 | `AuthMethod` | `lib/features/auth/domain/auth_service.dart:57` |
| #I157 | `BackgroundTaskRunner` | `lib/core/services/update_downloader.dart:75` |
| #I158 | `BatteryLocationState` | `lib/features/trek/providers/battery_aware_location_controller.dart:15` |
| #I159 | `BgCaptureStats` | `lib/features/trek/data/background_gps_service.dart:191` |
| #I160 | `BilanBalayageSauvegarde` | `lib/core/services/garde_sauvegarde_ios.dart:102` |

**Ce sont des CANDIDATS, pas des condamnés.** Limite #S27 du corpus source : une
citation par chaîne de caractères ou par réflexion n'est pas vue. Chaque symbole
doit être confirmé un par un avant suppression — c'est l'objet de SPEC-02, et
c'est non négociable.

---

## 16. Tests — 4002 passent, le miroir couvre 41 %

Commande : `flutter test` (exécution réelle, 02/10/2026) et
`python tool/audit_global.py --section tests`.

| Réf | Mesure | Valeur |
|---|---|---|
| #I161 | fichiers `*_test.dart` | 473 |
| #I162 | fichiers d'aide (sans `_test`) | 9 |
| #I163 | cas comptés statiquement (`test(`, `testWidgets(`) | 3 754 |
| #I164 | **tests réellement exécutés** | **4 002 passés** |
| #I165 | **tests ignorés** | **2** |
| #I166 | **durée totale** | **3 min 56 s** |
| #I167 | verdict | **All tests passed** |
| #I168 | fichiers de test **sans aucune assertion** | **0** |
| #I169 | fichiers de `lib/` **sans test miroir** | 354 → couverture miroir **40,9 %** |

L'écart 3 754 / 4 002 est normal et expliqué : des cas sont engendrés en boucle,
le comptage statique ne les voit pas.

Les tests ignorés, nominativement :

| Réf | Fichier:ligne | Condition |
|---|---|---|
| #I170 | `test/outillage/cartes_publiees_648_test.dart:181` | `skip: Platform.environment['STEPWAYS_TEST_RESEAU'] == '1'` — ignoré **quand la variable réseau est posée**, donc joué par défaut |

**Calibrage honnête :** la première version du détecteur ne cherchait que
`skip: true` ou `skip: 'raison'` et comptait donc **0 ignoré**, alors que
`flutter test` en annonçait 2. Le motif a été élargi à toute forme de `skip:`,
`@Skip` et `@TestOn`. Un seul `skip:` existe dans le dépôt ; il est
**conditionné par l'environnement**, ce qui est un usage légitime.

**Deux bonnes nouvelles à dire :** zéro fichier de test sans assertion, et zéro
test désactivé en dur. La dette est dans la **couverture** (41 % de miroir), pas
dans la sincérité des tests.

---

## 17. Observabilité — 9 écrans sur 63 posent une miette

Commande : un écran = un fichier `*_screen.dart` de `lib/` ; une miette = une des
marques `recordError`, `setCustomKey`, `log(`, `miette`, `breadcrumb`,
`FirebaseCrashlytics`, `crashlytics` présente dans le fichier.

| Réf | Mesure | Valeur |
|---|---|---|
| #I171 | écrans | **63** |
| #I172 | écrans avec au moins une miette | **9** |
| #I173 | écrans **sans** miette | **54** |
| #I174 | part couverte | **14,3 %** |

Les 9 écrans équipés :

| Réf | Écran |
|---|---|
| #I175 | `features/after/presentation/gpx_import_screen.dart` |
| #I176 | `features/auth/presentation/profile_screen.dart` |
| #I177 | `features/checklist/presentation/checklist_screen.dart` |
| #I178 | `features/consent/presentation/consent_settings_screen.dart` |
| #I179 | `features/journal/presentation/journal_screen.dart` |
| #I180 | `features/map/presentation/cartes_hors_ligne_screen.dart` |
| #I181 | `features/onboarding/presentation/onboarding_screen.dart` |
| #I182 | `features/planning/presentation/trail_planning_screen.dart` |
| #I183 | `features/safety/presentation/health_info_screen.dart` |

Contrainte de conception à retenir pour le lot observabilité (corpus S4) :
**64 clés maximum, 64 ko de miettes par session, 8 erreurs non fatales par
session.** Avec 63 écrans et 64 clés, « une clé par écran » est impossible : il
faut une convention de nommage décidée, pas une clé ajoutée au fil de l'eau.

---

## 18. Outillage et dépendances

| Réf | Mesure | Valeur |
|---|---|---|
| #I184 | `dart format --set-exit-if-changed lib test tool` | **0** fichier à reformater — le lot 643 a tenu |
| #I185 | `flutter analyze --no-pub` | **No issues found!** (17,4 s) |
| #I186 | `flutter pub outdated` — paquets obsolètes | **188** |
| #I187 | dont **saut de version majeure** | **72** |
| #I188 | règles de lint du référentiel ECR absentes de `analysis_options.yaml` | **7 sur 7** |

Les sauts majeurs les plus structurants (`actuel → résoluble → dernier`) :

| Réf | Paquet | Actuel | Résoluble | Dernier |
|---|---|---|---|---|
| #I189 | `cloud_firestore` | 5.6.12 | **6.10.0** | 6.10.0 |
| #I190 | `connectivity_plus` | 5.0.2 | **7.3.1** | 7.3.2 |
| #I191 | `battery_plus` | 6.2.3 | **7.1.2** | 7.1.2 |
| #I192 | `cached_network_image` | 3.4.1 | 3.4.1 | 4.0.4 |
| #I193 | `analyzer` | 10.0.1 | 10.0.1 | 14.4.0 |
| #I194 | `carp_serializable` | 2.0.1 | **3.0.0** | 3.0.0 |

Distinction qui compte pour le plan : certains sauts sont **résolubles tout de
suite** (`cloud_firestore`, `connectivity_plus`, `battery_plus`,
`carp_serializable` — la colonne « résoluble » est déjà la dernière), d'autres
sont **bloqués par une contrainte** (`cached_network_image`, `analyzer` — le
résoluble reste l'actuel). Les premiers sont un lot court ; les seconds demandent
de lever une contrainte amont.

**Piège de mesure à connaître, et il est désormais gardé par le script :** dans
un worktree neuf où `flutter pub get` n'a pas tourné, `flutter analyze` remonte
**77 735 erreurs**, toutes de type `uri_does_not_exist` — une par ligne d'import.
Ce chiffre ne dit **rien** du code. `tool/audit_global.py` vérifie désormais la
présence de `.dart_tool/package_config.json` et déclare la mesure **non
valable** plutôt que de publier un faux (voir `644-04`).

---

## 19. Récapitulatif chiffré, et comparaison avec le 21/09

| Réf | Critère | 21/09 | **02/10** | Tendance |
|---|---|---|---|---|
| #I195 | fichiers source `lib/` | 520 | **599** | +79 |
| #I196 | fichiers > 500 lignes (ECR-15) | 31 | **50** | **+19** |
| #I197 | boutons bruts (ECR-19, périmètre strict) | 58 | **153** | **x 2,6** |
| #I198 | noms de fichier en double (ECR-20) | 3 | **4** | +1 (`stage.dart`) |
| #I199 | documentation en `.dart` dans `lib/` (ECR-07) | 2 | **2** | inchangé |
| #I200 | part de fichiers avec en-tête (ECR-01) | 17,5 % | **20,0 %** | +2,5 pts |
| #I201 | dépendances interdites (ECR-23) | non mesuré | **321** | — |
| #I202 | code mort public candidat | non mesuré | **152** | — |
| #I203 | identifiants français (ECR-05) | non mesuré | **442** | — |
| #I204 | fonctions > 60 lignes (ECR-28) | non mesuré | **206** | — |
| #I205 | valeurs à compléter en production | non mesuré | **45** | — |
| #I206 | écrans avec observabilité | non mesuré | **9 / 63** | — |

**Ce que ce tableau dit, et c'est le constat principal de l'audit :** tous les
indicateurs que le 21/09 avait mesurés se sont **dégradés en onze jours**, pendant
que le dépôt livrait les builds 7 et 8. Ce n'est pas un relâchement de qualité :
`flutter analyze` est vert, `dart format` est vert, 4002 tests passent. **C'est
l'absence de mesure automatique.** Une règle qu'aucune commande ne vérifie n'est
pas une règle, c'est un souhait.

D'où l'ordre du plan : **la mesure d'abord (645-01), le ménage ensuite.**

---

## 20. Ce qui reste ouvert à la fin de cet inventaire

| Réf | Point ouvert | Qui tranche |
|---|---|---|
| #I207 | Les 10 arbitrages du référentiel ECR (`#100239`) sont **toujours en attente** depuis le 21/09 | Christophe |
| #I208 | 321 infractions ECR-23 : faut-il créer une zone `lib/domain/` partagée pour les modèles que plusieurs features lisent (`stage`, `track_point`, `trek_session`), ou bien assumer `trek` comme socle ? | Christophe, sur proposition du temps 3 |
| #I209 | Les 152 candidats au code mort doivent être **confirmés un par un** ; le chiffre final sera inférieur | temps 3, SPEC-02 |
| #I210 | Les 45 valeurs à compléter sont des **données**, pas du code : certaines attendent une décision produit (horaires réels des commerces, liens d'affiliation réels) | Christophe |
| #I211 | 72 sauts de version majeure : lesquels sont tirés par une obligation de boutique, lesquels sont du confort ? Non mesuré dans ce lot | temps 3, lot dédié |
| #I212 | La mesure de complexité est approchée (#S26). Faut-il ajouter `dart_code_metrics` pour une mesure exacte, au prix d'une dépendance ? | Christophe, arbitrage A-07 de `#100239` |

---

*Fin du 644-01. Suite : `644-02-specifications.md`.*
