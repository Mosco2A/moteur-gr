# Journal du dépôt — Moteur-GR / StepWays

> Une ligne par lot, dans l'ordre réel des fusions dans
> `claude/integration/645-assainissement`. La date est celle du commit de
> fusion du lot, ou celle du commit du lot quand il n'a pas de fusion propre.
> Les numéros sont ceux des décisions et comptes rendus en base de Christophe.
> Un numéro manquant s'écrit « a completer par Skynet », jamais deviné.
>
> Vérifié par `test/structurel/la_doc_ne_mente_pas_645_test.dart` : chaque
> ligne de lot porte un numéro `#NNNNNN` ou la mention « a completer par
> Skynet », et chaque lot du plan `docs/assainissement/644-03-decoupage-et-plan.md`
> a sa ligne.

## Lots

| Date | Lot | Ce qui a changé | Numéro(s) en base |
|---|---|---|---|
| 30/09/2026 | 643 | `dart format` sur tout le dépôt et gate de formatage, sans changement de comportement (temps 1). | #100970, #100913 |
| 02/10/2026 | 644 | Audit-inventaire mesuré, spécifications, découpage et plan au cordeau, et l'outil `tool/audit_global.py`. | #101000, #100914, #100930 |
| 02/10/2026 | 645-01 | Sept gardes d'architecture à plafond et documents de l'audit dans la branche d'intégration. | #101003 |
| 02/10/2026 | 645-02 | Le code mort public confirmé sort, plafond descendu à 144. | #101011 |
| 02/10/2026 | 645-03 | 112 appels de bouton brut passés sur `AppButton`, plafond ECR-19 à 10. | #101035 |
| 02/10/2026 | 645-04 | Doublons : deux résorbés, trois sortis en arbitrage (`gpx_parser`, `stage`, `track_point`). | #101040, #101041 |
| 02/10/2026 | 645-11 | En-têtes sur les fichiers de `lib/` et 40 couleurs ramenées au thème à valeur identique. | #101050, #101051 |
| 03/10/2026 | 645-05 | Voie A : `lib/domain/` pour les modèles partagés, routeur seule exception du socle. | #101052, #101067, #101068, #101071 |
| 03/10/2026 | 645-08 | Voie V2 : les 45 valeurs à compléter retirées, un champ absent n'affiche rien. | #101055 |
| 03/10/2026 | 645-10 | Dépendances montables seules montées (`battery_plus`, `connectivity_plus`), un commit par paquet. | #101074 |
| 03/10/2026 | 645-06 | Vague 1 : cinq `build()` en sous-widgets nommés ; vague 2 : cinq fichiers scindés en `part`, convention refusée ensuite. | #101076, #101077, #101098 |
| 03/10/2026 | 645-05b | Une façade par feature lue par ses voisines, et le socle ne lit plus le métier. | #101082 |
| 03/10/2026 | 645-07 | Identifiants passés en anglais, commentaires en français intacts. | #101092 |
| 04/10/2026 | 645-09 | Observabilité posée sur les 63 écrans, inerte sans Firebase. | #101121 |
| 04/10/2026 | 645-09b | Correctif joint au 645-09 : la clé `screen` est fidèle à l'écran visible. | #101196 |
| 04/10/2026 | 676 | Preuves émulateur de la pile rejouée et de l'unité de température, commit direct dans l'intégration. | a completer par Skynet |
| 04/10/2026 | 645-F1 | Hors plan : unité de température persistée et parcours persona Marc réel. | #101128, #101196 |
| 04/10/2026 | build 9 | Version 0.1.5+9 livrée (`STEPWAYS-V0.1.5-9-202610041521-d48d2fd.aab`). | #101205, #101206 |
| 04/10/2026 | 645-06b | Les fichiers `part` redécoupés en bibliothèques, et deux résidus sous 500 lignes. | #101208, #101214, #101217, #101219 |
| 04/10/2026 | 645-12 | Ce journal, l'architecture remise au réel mesuré, et le test qui les vérifie. | a completer par Skynet |

## Ce qui reste ouvert au 04/10/2026

| Point | Ce qui reste ouvert | Numéro(s) |
|---|---|---|
| Défauts produit | Quatre défauts produit ouverts, détaillés en base. | #101094 |
| Défaut produit | Un défaut produit ouvert, détaillé en base. | #101197 |
| Captures | Les captures de comparaison faites avant le 645-07 sont douteuses : worktree neuf sans fichier de config ignoré par git, recette de capture qui écrivait en retard. | #101077, #101092 |
| Tests ignorés | Deux tests ignorés : `persona_le_mefiant_573_test.dart` (profil randonneur non semé) et `cartes_publiees_648_test.dart` (preuve réseau). | a completer par Skynet |
| Couches | Vingt croisements entre features vers une `presentation/` ou un `data/` voisin, pour le lot 645-05c à venir. | a completer par Skynet |
| Recette de capture | Doublons de ticks GPS non déclarés, contrôle de captures rouge pour S1 et S3 des deux côtés. | #101219 |
| Fiche médicale | Cinq imports inutiles dans six fichiers, et ECR-16 monté mécaniquement de 409 à 416. | #101217 |
| Démon de captures | `skynet_watchdog.py` abat le démon de captures (hors dépôt). | #101220 |
| Plan 644-03 #P49 | Convention d'observabilité appliquée par 645-09 sans décision listée qui la tranche. | #101121 |
| Plan 644-03 #P50 | Les dix arbitrages du référentiel ECR, en attente depuis le 21/09. | #100239 |
| Plan 644-03 #P51 | Budget du plan, sans décision listée. | a completer par Skynet |
| Plan 644-03 #P52 | Ajouter ou non `dart_code_metrics` pour une complexité exacte (arbitrage A-07). | #100239 |
| Plan 644-03 #P53 | Les sauts de version majeure tirés par une obligation de boutique, non mesurés. | a completer par Skynet |
| Plan 644-03 #P54 | Contrat de données versionné, volet CI de la proposition 5, personas en CI : hors plan. | a completer par Skynet |
