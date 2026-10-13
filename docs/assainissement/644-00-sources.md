# 644-00 — Le corpus source, gravé AVANT la rédaction

> Tâche 644, temps 2 de l'assainissement StepWays. Athena, 02/10/2026.
> Dépôt **Moteur-GR**. Branche de mesure `claude/docs/644-audit-assainissement`,
> issue de `claude/integration/633-version-complete` à sa tête **147ca32d**
> (« Merge branch 'claude/chore/643-formatage' »).
> Règle 6178 : chercher les bonnes pratiques du domaine en base, aller chercher
> ce qui manque dans les sources officielles, le graver, **puis** produire.

Ce document existe pour une seule raison : Christophe a écrit, le 30/09,
« Attention je veux les meilleures pratiques de dev **sourcées** ! ». Chaque
recommandation des documents 644-01 à 644-04 renvoie ici, et chaque ligne d'ici
renvoie soit à un numéro en base, soit à une adresse officielle avec sa date de
consultation.

---

## 1. Ce que la base portait déjà — le référentiel ECR

La base **répondait déjà**, et largement. Le référentiel ECR (Écriture du Code),
produit par Athena le 21/09/2026 sur mandat de Christophe, porte **32 règles
numérotées ECR-01 à ECR-32**, réparties en 6 familles, chacune avec son énoncé,
son pourquoi, un exemple bon et un mauvais, et **un critère vérifiable**.

| Réf | Enregistrement | Contenu |
|---|---|---|
| #S01 | `#100240` | **Index** du référentiel — point d'entrée unique |
| #S02 | `#100232` | F1 Commentaires et documentation — ECR-01 à ECR-07 |
| #S03 | `#100233` | F2 Nommage — ECR-08 à ECR-12 |
| #S04 | `#100234` | F3 Arborescence — ECR-13 à ECR-17 |
| #S05 | `#100235` | F4 Zéro répétition — ECR-18 à ECR-22 |
| #S06 | `#100236` | F5 Modularité et couplage — ECR-23 à ECR-27 |
| #S07 | `#100237` | F6 Taille et complexité — ECR-28 à ECR-32 |
| #S08 | `#100238` | **Les deux gates** — checklist AVANT (10 points), grille APRÈS (32 critères) |
| #S09 | `#100239` | 10 arbitrages en attente de Christophe |
| #S10 | `#100241` | Bilan de clôture de la tâche 533 |

**Conséquence sur la méthode de la tâche 644 :** l'audit n'invente aucun seuil.
Il **rejoue** les critères ECR sur la tête actuelle et compare avec la mesure de
départ du 21/09. C'est ce qui rend les chiffres comparables d'un lot à l'autre.

Autres entrées en base utilisées, toutes citées à l'endroit où elles servent :

| Réf | En base | Ce qu'elle apporte |
|---|---|---|
| #S11 | `#100228` | le constat chiffré de Christophe du 21/09 — 8 chiffres, tous revérifiés |
| #S12 | `#100656` | l'inventaire 593 du 26/09 — 26 points mesurés, dont les `example.org` |
| #S13 | `#100928` | les 8 propositions de propreté du 30/09 |
| #S14 | `#100930` | la décision de Christophe du 30/09 : « Ok sur toutes tes propositions » |
| #S15 | `#100914` | « un audit, des spec, un découpage, un plan au cordeau = sécurité » |
| #S16 | `#100925` | « Attention je veux les meilleures pratiques de dev sourcées ! » |
| #S17 | `#85085` à `#85087` | modèle **CORDO** de plan au cordeau — 12 champs obligatoires |
| #S18 | `#81094` | BP audit qualité code Flutter — checklist 12 axes |

---

## 2. Ce que la base NE portait PAS — quatre points, allés chercher dehors

Gravés en base le **02/10/2026 à 11:35**, mémo BP domaine `dart`, sources citées
avec leur date de consultation, **avant** l'écriture de l'inventaire.

### S1 — `unused_element` ne voit que le privé. C'est LE point de la tâche.

Source : <https://dart.dev/tools/diagnostics/unused_element>, consultée le
02/10/2026. Texte exact : le diagnostic est produit quand *« a private
declaration isn't referenced in the library that contains the declaration »*. Il
analyse *« private top-level declarations and all of their members »* et
*« private members of public declarations »*.

**Une déclaration PUBLIQUE sans aucun appelant n'est JAMAIS signalée par
l'analyseur Dart.**

C'est l'explication du paradoxe mesuré le 02/10 à 11:31 sur la tête 147ca32d :

- `flutter analyze --no-pub` rend **« No issues found! »** — 0 erreur, 0 avertissement, 0 info ;
- et l'audit 644 compte **152 symboles publics sans appelant** sur 1047 déclarations publiques.

Les deux résultats sont vrais **en même temps**. L'outil officiel ne couvre pas
ce cas. Le code mort public exige donc un test d'architecture maison : il ne
viendra jamais de `dart analyze`. Diagnostics voisins qui, eux, existent et sont
déjà actifs : `dead_code` (code inatteignable), `unused_field`, `unused_import`,
`unused_local_variable`.

### S2 — Le sens des dépendances : ce que Flutter dit, et ce qu'il ne dit pas

Source : <https://docs.flutter.dev/app-architecture/guide>, consultée le 02/10/2026.

Texte officiel : *« Your Flutter application should split into two broad layers,
the UI layer and the Data layer »*. UI = views + view models. Data = repositories
+ services. Couche domaine optionnelle (use-cases). Sens descendant imposé :
views → view models → repositories → services, avec *« Services are in the
lowest layer of your application... they hold no state »*. Relations
many-to-many tolérées entre view models et repositories, et entre repositories
et services. **Une seule** interdiction explicite dans le texte officiel :
*« Repositories should never be aware of each other »*.

**Honnêteté de sourçage, et elle compte :** l'interdiction du croisement entre
features et l'interdiction socle → feature (ECR-23) ne sont **pas** dans le texte
officiel Flutter, qui ne parle que de couches techniques. Elles viennent des
conventions du dépôt (`docs/conventions.md` lignes 17-54). Elles sont donc
présentées partout dans ce corpus comme une **règle maison**, adossée au principe
officiel *« Separation-of-concerns is the most important principle to follow when
designing your Flutter app »*, et jamais comme une citation de Flutter.

### S3 — Tests d'architecture en Dart : il n'y a pas d'outil officiel

Relevé du 02/10/2026 : ni le SDK Dart ni Flutter ne fournissent d'équivalent
d'ArchUnit. Quatre voies, dont une déjà dans le dépôt :

| Réf | Voie | Nature | Coût |
|---|---|---|---|
| #S19 | `dart_arch_test` | inspiré d'ArchUnit ; `shouldNotDependOn`, `defineLayers` + `enforceDirection`, détection de cycles sur le graphe d'imports ; sans annotation ni génération | une dépendance de dev |
| #S20 | `import_rules` | greffon d'analyseur, contraintes en YAML dans `analysis_options.yaml`, violations remontées par `dart analyze` et dans l'IDE | une dépendance + config |
| #S21 | DCM (Dart Code Metrics) | règle `avoid-banned-imports` | payant |
| #S22 | **`test/structurel/` du dépôt** | test Dart ordinaire qui lit l'arborescence des sources — **existe déjà, 15 fichiers** | **zéro dépendance** |

**La quatrième voie est celle du dépôt, et c'est la moins chère.** Moteur-GR écrit
**déjà** ses tests d'architecture à la main. Répertoire `test/structurel/`,
**15 fichiers** mesurés le 02/10/2026, dont `tout_ecran_a_une_route_573_test.dart`,
`toute_route_a_une_porte_573_test.dart`, `aucun_geste_mort_573_test.dart`,
`registre_des_dormants.dart`, `aucune_icone_non_constante_619_test.dart`.

**Recommandation retenue pour le lot 645-01 : étendre `test/structurel/`, ne pas
ajouter de dépendance.** Zéro paquet nouveau, même forme que l'existant, et la
gate les joue déjà avec `flutter test`. `dart_arch_test` reste la solution de
repli si le graphe d'imports **transitif** devient nécessaire — ce que l'audit
644 n'a pas eu besoin de mesurer.

### S4 — Observabilité : les limites chiffrées de Crashlytics

Source : <https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports>,
consultée le 02/10/2026. API Flutter exacte :

```dart
FirebaseCrashlytics.instance.setCustomKey('cle', valeur);
FirebaseCrashlytics.instance.log('miette');
FirebaseCrashlytics.instance.setUserIdentifier('id');
await FirebaseCrashlytics.instance.recordError(e, s, reason: '...');
```

Limites citées mot pour mot :

| Réf | Ressource | Limite officielle |
|---|---|---|
| #S23 | clés personnalisées | *« a maximum of 64 key-value pairs. After you reach this threshold, additional values are not saved. Each key-value pair can be up to 1 kB in size »* |
| #S24 | miettes (`log`) | *« limits logs to 64kB and deletes older log entries when logs for a session go over that limit »* |
| #S25 | erreurs non fatales | *« only stores the most recent eight recorded non-fatal exceptions »* |

**Ce que cela impose au lot observabilité :** le budget de 64 clés est une
ressource **rare**, à répartir volontairement par une convention de nommage
décidée — pas une clé par écran ajoutée au fil de l'eau. Les miettes doivent être
courtes, car les anciennes sont effacées au-delà de 64 ko. Et les erreurs non
fatales ne remontent qu'à **huit par session** : on ne peut pas tout envoyer en
non fatal. État mesuré du dépôt le 02/10/2026 : **9 écrans sur 63** portent une
miette, soit **14,3 %**.

---

## 3. Portée et limites de ce corpus

Ces quatre points sont les **seuls** que la tâche 644 a eu besoin d'aller
chercher à l'extérieur. Tout le reste s'appuie sur le référentiel ECR déjà gravé.

Trois limites, dites franchement :

| Réf | Limite assumée | Conséquence pratique |
|---|---|---|
| #S26 | Le compteur de complexité de `tool/audit_global.py` est **approché** : il compte les accolades et les mots de branchement, sans analyseur Dart | *reproductible* — le même code donne toujours le même chiffre, donc utilisable comme métrique de progression. Mais ce n'est pas une vérité syntaxique |
| #S27 | La liste de code mort est une liste de **candidats** : une citation par chaîne de caractères ou par réflexion n'est pas vue | chaque symbole est confirmé un par un avant suppression — c'est écrit dans la spécification SPEC-02 |
| #S28 | La détection d'identifiants français repose sur une **liste fermée de 94 mots** | elle donne un ordre de grandeur et une liste nominative de départ, pas une exhaustivité. Deux homographes anglais ont été retirés après vérification le 02/10 : `trace` (qui attrapait `StackTrace`, `tracer`, `session_trace_painter`) et `journal` (mot anglais courant) |

---

*Fin du 644-00. Suite : `644-01-inventaire.md`, l'audit mesuré.*
