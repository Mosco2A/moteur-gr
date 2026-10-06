# Architecture globale — Moteur GR

> Dernière mise à jour : 05/10/2026 — Hephaistos, lot produit P1 (#101255).
>
> **Ce document décrit le réel mesuré, pas le réel supposé.** Les chiffres
> viennent de `python3 tool/audit_global.py --rapide`, relancé le 05/10/2026 sur
> la branche `claude/fix/produit-p1-reglages-temperature-booking`, après les
> trois points du lot produit P1 (lecture tolérante des réglages, température
> affichée dans l'unité choisie, route `/booking` retirée). Ils
> remplacent ceux de `docs/assainissement/644-01-inventaire.md`, qui datent du
> 30/09 et sont périmés.
>
> Un chiffre suivi d'un commentaire HTML `audit:` et sa clé (invisible au rendu)
> est **revérifié à chaque `flutter test`** par
> `test/structurel/la_doc_ne_mente_pas_645_test.dart`, qui relance l'audit
> (sections `arborescence` et `couches`) et compare. La clé est le chemin du
> chiffre dans le JSON de l'audit ; `*` en fin de segment additionne les
> dossiers qui commencent ainsi ; `[~motif]` et `[!~motif]` ne comptent que les
> entrées d'une liste qui correspondent, ou non, à l'expression régulière.
> Les autres chiffres (tests, observabilité, verdict) viennent des autres
> sections du même JSON et ne sont pas revérifiés par ce test.

## Présentation

Le Moteur GR est un moteur générique Flutter multi-sentiers. Il transforme
n'importe quel sentier de grande randonnée en application mobile complète :
carte, navigation GPS, planning, POIs, offline-first. Indépendant de tout
sentier spécifique. Premier client : Mare à Mare (Corse), sous le nom
StepWays.

## Les couches, telles que les règles les fixent

Une flèche se lit « a le droit d'importer ». Les règles 9 à 12 de
`docs/conventions.md` en sont la loi ; les gardes de `test/structurel/` les
mesurent.

```
lib/features/<f>/        presentation/  providers/  data/  domain/  widgets/ ...
   |      \
   |       \--> lib/features/<g>/<g>_facade.dart   (seule porte d'une voisine, règle 10)
   v
lib/domain/              modèles et règles métier partagés (voie A, lot 645-05)
   |
   v
lib/core/   lib/shared/  socle : base Drift, services, thème, routage, widgets communs
```

- **Règle 9 — le socle ne remonte jamais vers une feature.** Une seule
  exception, **ARB-645-05-a** (décision A de Christophe, 03/10/2026) :
  `lib/core/routing/app_router.dart` importe les écrans de toutes les
  features, parce qu'un routeur connaît tous les écrans par construction.
- **Règle 10 — une feature ne lit une autre feature que par sa façade**,
  `lib/features/<f>/<f>_facade.dart`, qui ré-exporte avec `show` les seuls
  symboles publics. **ARB-645-05-b** (décision B de Christophe, 03/10/2026).
- **Règle 11 — le socle ne connaît pas le métier** : `core/` et `shared/`
  n'importent jamais `lib/domain/`. Plafond à zéro. **ARB-645-05-c**
  (décision B de Christophe, 03/10/2026).
- **Règle 12 — pas de `part` hors code généré** : une bibliothèque = un
  fichier avec ses propres imports (décision de Christophe du 03/10/2026).

## Arborescence mesurée

`lib/` compte 667 <!-- audit:arborescence.zones.lib.fichiers_source --> fichiers source et
128 140 <!-- audit:arborescence.zones.lib.lignes_source --> lignes, hors
120 <!-- audit:arborescence.zones.lib.fichiers_generes --> fichiers générés (`.g.dart`,
`.freezed.dart`).

| Dossier | Fichiers | Lignes |
|---|---|---|
| `lib/core/` | 185 <!-- audit:arborescence.detail_lib.lib/core/*.fichiers --> | 30 507 <!-- audit:arborescence.detail_lib.lib/core/*.lignes --> |
| `lib/features/` | 430 <!-- audit:arborescence.detail_lib.lib/features/*.fichiers --> | 88 449 <!-- audit:arborescence.detail_lib.lib/features/*.lignes --> |
| `lib/shared/` | 29 <!-- audit:arborescence.detail_lib.lib/shared/*.fichiers --> | 4 831 <!-- audit:arborescence.detail_lib.lib/shared/*.lignes --> |
| `lib/domain/` | non ventilé par l'audit | non ventilé par l'audit |

**`lib/domain/` n'a pas de ligne dans l'audit** : `mesurer_arborescence` ne
détaille que les sous-dossiers de `core/`, `features/`, `shared/` et `i18n/`.
Les 23 fichiers source de `lib/` hors de `core/`, `features/` et
`shared/` sont `lib/domain/`, `lib/i18n/i18n_setup.dart`, `lib/main.dart` et
les deux fichiers de `lib/docs/`. Ajouter `domain` à la boucle de l'outil est à
faire par un lot qui a le droit d'écrire dans `tool/`.

### Les cinq plus grosses features (en fichiers)

| Feature | Fichiers | Lignes |
|---|---|---|
| `trek` | 51 <!-- audit:arborescence.detail_lib.lib/features/trek.fichiers --> | 11 799 <!-- audit:arborescence.detail_lib.lib/features/trek.lignes --> |
| `safety` | 30 <!-- audit:arborescence.detail_lib.lib/features/safety.fichiers --> | 6 803 <!-- audit:arborescence.detail_lib.lib/features/safety.lignes --> |
| `feasibility` | 30 <!-- audit:arborescence.detail_lib.lib/features/feasibility.fichiers --> | 7 442 <!-- audit:arborescence.detail_lib.lib/features/feasibility.lignes --> |
| `weather` | 29 <!-- audit:arborescence.detail_lib.lib/features/weather.fichiers --> | 5 061 <!-- audit:arborescence.detail_lib.lib/features/weather.lignes --> |
| `planning` | 25 <!-- audit:arborescence.detail_lib.lib/features/planning.fichiers --> | 8 931 <!-- audit:arborescence.detail_lib.lib/features/planning.lignes --> |

`trek` reste la plus grosse feature, et de loin.

## Couches mesurées (ECR-23, ECR-25)

| Mesure | Nombre | Conforme ? |
|---|---|---|
| Imports du socle (`core/`, `shared/`, `domain/`) vers une feature | 71 <!-- audit:couches.nombre_socle_vers_feature --> | voir les deux lignes suivantes |
| … dont depuis `lib/core/routing/app_router.dart` | 50 <!-- audit:couches.socle_vers_feature[~^lib/core/routing/app_router\.dart ] --> | **oui**, exception ARB-645-05-a (règle 9) |
| … dont depuis tout autre fichier du socle | 21 <!-- audit:couches.socle_vers_feature[!~^lib/core/routing/app_router\.dart ] --> | **non** (règle 9) |
| Imports d'une feature vers une autre feature | 146 <!-- audit:couches.nombre_croisements --> | voir les deux lignes suivantes |
| … dont par la façade de la voisine | 146 <!-- audit:couches.croisements_entre_features[~_facade\.dart$] --> | **oui**, ARB-645-05-b (règle 10) |
| … dont vers l'intérieur de la voisine | 0 <!-- audit:couches.croisements_entre_features[!~_facade\.dart$] --> | **oui** : zéro depuis le lot 645-05c (règle 10) |
| Fichiers de présentation qui importent un paquet de données | 0 <!-- audit:couches.nombre_presentation_donnees --> | **oui** (ECR-25) |
| Fichiers de feature hors d'une couche reconnue | 22 <!-- audit:couches.nombre_hors_couche --> | **non** (RNG-01, avertissement) |

Les 146 croisements passent TOUS par une façade. Le 05/10, le lot produit P1
(#101255) en a ajouté 7 en branchant `weather` et `hub` sur le réglage d'unité
de température, par `settings_facade.dart` ; le 06/10, le lot 671-00 en a
ajouté 3 en branchant la carte (`location_provider`, `off_track_provider`) et
le suivi (`tracking_provider`) sur le robinet unique GPS de `trek`, par
`trek_facade.dart`. Le chiffre qui compte — les croisements vers l'INTÉRIEUR
d'une voisine — reste à zéro.

Parmi les croisements vers l'intérieur d'une voisine,
0 <!-- audit:couches.croisements_entre_features[!~_facade\.dart$][~ -> .*/(presentation|data)/] --> visent une `presentation/` ou un `data/` voisin : le
lot 645-05c les a payés, avec les 32 emprunts de type — trois tuiles montées
dans `lib/shared/widgets/`, tout le reste par la façade de la feature lue.
**Conforme.**

**Socle vers métier (règle 11) : zéro.** L'audit ne le mesure pas — il range
encore `core`, `shared` et `domain` dans le même sac « socle ». La mesure est
celle de la garde `test/structurel/couches_respectees_645_test.dart`, dont le
plafond `plafondSocleVersMetier` est à zéro et passe.

Le verdict de l'audit compte **214** dépendances interdites (ECR-23), soit la
somme des deux totaux ci-dessus : il compte encore le routeur et les façades,
que les décisions ARB-645-05-a et ARB-645-05-b autorisent. Les gardes de
`test/structurel/couches_respectees_645_test.dart` ne comptent que les écarts
réels, et leurs plafonds (21 et 0) sont serrés contre la mesure.

## Taille des fichiers (ECR-15)

46 <!-- audit:arborescence.tailles.nombre_au_dela_de_500 --> fichiers de `lib/` dépassent
500 lignes, dont 17 <!-- audit:arborescence.tailles.repartition.>800 --> au-delà de 800. Le
plus gros, `lib/features/journal/presentation/journal_screen.dart`, compte
1 247 <!-- audit:arborescence.tailles.au_dela_de_500.0.1 --> lignes. **Non conforme.**

La racine de `lib/` porte 1 <!-- audit:arborescence.racine_lib.intrus --> dossier non
autorisé (ECR-13) : `lib/docs/`, de la documentation déposée en `.dart`
(ECR-07). **Non conforme.**

## Observabilité

L'audit compte **62** écrans (`*_screen.dart` de `lib/`), **62** portent une
miette d'observabilité, **0** n'en porte pas : 62 sur 62, posées par le lot
645-09, inertes sans Firebase.

**ILS ÉTAIENT 63 JUSQU'AU 05/10/2026.** Le lot produit P1 (#101255) a retiré
`booking_screen.dart` avec la route `/booking` : un écran qu'aucune porte ne
menait, qu'aucune donnée n'alimentait, et dont le drapeau n'a jamais été
ouvert — sa miette ne pouvait donc jamais être émise. La garde
`test/structurel/observabilite_des_ecrans_645_test.dart` attend désormais 62,
et la couverture reste à 100 %.

## Tests

L'audit compte **497** fichiers de test et **3867** cas déclarés par
`test(` ou `testWidgets(` (comptage statique ; l'exécution en déclare davantage,
des cas étant engendrés en boucle). **417** fichiers de `lib/` n'ont pas de
test miroir du même nom (ECR-16, avertissement), soit **37.2** % de `lib/`
couvert par un miroir. Ces chiffres sont ceux du lot produit P1.

## Ce qui n'est pas conforme, au 05/10/2026

Les huit règles bloquantes du verdict de l'audit, chiffre à l'appui :

| Règle | Nombre | Constat |
|---|---|---|
| ECR-23 | 214 | dépendance interdite entre couches ou features (dont routeur et façades, autorisés — voir plus haut) |
| ECR-28 | 195 | fonction au-delà de 60 lignes |
| ECR-15 | 46 | fichier source au-delà de 500 lignes |
| ECR-04 | 45 | code commenté livré ou TODO sans numéro de tâche |
| ECR-31 | 19 | fonction de complexité supérieure à 10 |
| ECR-19 | 10 | appel de bouton brut hors du composant unique |
| ECR-07 | 2 | documentation déposée en `.dart` sous `lib/` |
| ECR-13 | 1 | élément non autorisé à la racine de `lib/` |

## Principes fondateurs

1. **Offline-first** — Tout fonctionne sans réseau. Drift (SQLite) est la
   source de vérité locale. Firebase est le miroir cloud.
2. **Multi-sentier** — Le moteur ne connaît pas les sentiers. Ils sont
   injectés via `TrailConfig` dérivé de `activeTrailProvider`.
3. **Indépendance GR20** — Jamais de référence au GR20 dans le code.

## Stack technique

Versions lues dans `pubspec.yaml` (contrainte) et `pubspec.lock` (résolue),
vérifiées par `test/structurel/la_doc_ne_mente_pas_645_test.dart`.

| Paquet | Contrainte | Résolue |
|---|---|---|
| `flutter_riverpod` | ^3.3.2 | 3.3.2 |
| `go_router` | ^13.0.0 | 13.2.5 |
| `drift` | ^2.22.1 | 2.31.0 |
| `freezed` | ^3.2.5 | 3.2.5 |
| `slang` | ^4.15.0 | 4.15.0 |
| `flutter_map` | ^8.2.0 | 8.3.0 |
| `firebase_core` | ^3.8.0 | 3.15.2 |

- SDK Dart : `>=3.8.0 <4.0.0` (`pubspec.yaml`).
- Riverpod : providers manuels, pas de génération de code.
- Drift : le numéro de schéma est `schemaVersion` dans
  `lib/core/data/database.dart`.
- Slang : i18n 5 langues (fr, en, de, it, es).
- Firebase (Auth, Firestore, Storage, Analytics, Crashlytics), Open-Meteo.

## Flux de données principal

```
Firestore --> trail_download_service --> Drift (tables locales)
                                              |
                                              v
                                     trailConfigProvider
                                              |
                                              v
                              +---------------+---------------+
                              |               |               |
                           carte           planning        journal
```

La synchronisation fonctionne en mode **last-write-wins** via `sync_queue`.
