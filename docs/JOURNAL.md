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
| 04/10/2026 | 645-F1 | Hors plan : unité de température persistée et parcours persona Marc réel. | #101128, #101196 |
| 04/10/2026 | 676 | Preuves émulateur de la pile rejouée et de l'unité de température, commit direct dans l'intégration. | #101196 |
| 04/10/2026 | build 9 | Version 0.1.5+9 livrée (`STEPWAYS-V0.1.5-9-202610041521-d48d2fd.aab`). | #101205, #101206 |
| 04/10/2026 | 645-06b | Les fichiers `part` redécoupés en bibliothèques, et deux résidus sous 500 lignes. | #101208, #101214, #101217, #101219 |
| 04/10/2026 | 645-12 | Ce journal, l'architecture remise au réel mesuré, et le test qui les vérifie. | #101229, #101232 |
| 05/10/2026 | 645-05c | Les cinquante-deux croisements entre features à zéro : trois tuiles montent dans `shared/`, le reste passe par les façades. | #101226 |
| 05/10/2026 | build 10 | Version 0.1.6+10 livrée le 05/10 à 13:56 (`STEPWAYS-V0.1.6-10-202610051356-a06f500.aab`), le build propre de fin du plan d'assainissement : il porte le 645-06b, le 645-12 et le 645-05c que le build 9 n'avait pas. | #101265, #101266 |
| 05/10/2026 | produit P1 | Lecture tolérante des réglages : une clé héritée du build du 26/05 ne remet plus les autres réglages par défaut. | #101255 |
| 05/10/2026 | produit P2 | La température s'affiche dans l'unité choisie, par une seule fonction de `lib/domain/` ; sept lectures de plus par la façade des réglages. | #101255 |
| 05/10/2026 | produit P3 | La route `/booking` dormante retirée avec son écran inatteignable et son drapeau sans lecteur ; le domaine `booking` reste entier. | #101255 |
| 05/10/2026 | outillage 695 | Un seul `pub get` à la fois par machine (verrou dans le cache partagé, purge des paquets sans `pubspec.yaml`) ; les deux tests instables rendus déterministes (horloge injectée côté cadence, attente de l'écran au lieu d'un budget de pompes) ; les 114 549 dossiers temporaires que le socle de test ne rendait pas ; et les cinq tolérances de captures « devenues inutiles » retirées puis REMISES, parce qu'un run S1 mesuré a montré que ce signal est faux tant que le contrôle compare la barre d'état. | #101267, #101276, #101306, #101320 |
| 05/10/2026 | build 11 | Version 0.1.7+11 livrée le 05/10 à 21:54 (`STEPWAYS-V0.1.7-11-202610052154-e978072.aab`), le premier build de produit et non plus d'assainissement : il porte le lot P1 (réglages conservés, température dans l'unité choisie, `/booking` retirée) et la recette persona robuste. | #101332, #101333 |
| 05/10/2026 | outillage 699 | Les outils Python de `tool/` ne lancent plus `flutter` ni `dart` par leur nom nu, que Windows ne résout pas : une seule résolution d'exécutable pour tout le dépôt, six commandes corrigées dans trois fichiers, `--pub-get` vérifiée de bout en bout sur le vrai cache — l'outil du verrou peut enfin faire le `pub get` pour lequel il avait été écrit — et une garde structurelle de six cas qui refuse tout nom nu à l'avenir et rougit quand on y remet la faute. | #101335 |
| 06/10/2026 | 671-00 | Batterie d'abord, premier lot : le robinet unique GPS, à comportement identique. Un `PositionController` possède la seule souscription Geolocator de l'interface et la diffuse ; carte, hors-trace, suivi, détection d'étape et arrivées en dérivent au lieu d'ouvrir chacun la leur ; le canal `kPrefsBgProfile` est posé (écrit par l'interface, relu par l'isolate de fond, sans effet sur sa cadence) ; une garde à plafond refuse un troisième `Geolocator.getPositionStream` (2 robinets, 6 `LocationAccuracy.high`). Écart rapporté : le régime adaptatif de `GpsService` ne pilote plus le flux, le profil carte (haute précision, 10 m) le remplace. | a completer par Skynet |

## Ce qui reste ouvert au 04/10/2026

| Point | Ce qui reste ouvert | Numéro(s) |
|---|---|---|
| Défauts produit | Des quatre défauts du 03/10, trois sont tranchés : la persistance de l'unité (lot 645-F1), la route `/booking` (retirée, lot produit P1) et le GPS économiseur (devient le profil batterie basse du design #101100). Reste le scénario persona S2, dont le libellé « Confidentialité et consentement » existe deux fois. | #101094, #101255 |
| Défaut produit | Des trois défauts du 04/10, deux sont tranchés par le lot produit P1 : la lecture tolérante des réglages et la température affichée dans l'unité choisie. Reste le contrôle de captures qui compare l'image entière, traité par le lot recette persona. | #101197, #101255 |
| Captures | Les captures de comparaison faites avant le 645-07 sont douteuses : worktree neuf sans fichier de config ignoré par git, recette de capture qui écrivait en retard. | #101077, #101092 |
| Tests ignorés | Deux tests ignorés : `persona_le_mefiant_573_test.dart` (profil randonneur non semé) et `cartes_publiees_648_test.dart` (preuve réseau). | a completer par Skynet |
| Recette de capture | Doublons de ticks GPS non déclarés, contrôle de captures rouge pour S1 et S3 des deux côtés. | #101219 |
| Fiche médicale | Cinq imports inutiles dans six fichiers, et ECR-16 monté mécaniquement de 409 à 416. | #101217 |
| Démon de captures | `skynet_watchdog.py` abat le démon de captures (hors dépôt). | #101220 |
| Plan 644-03 #P49 | Convention d'observabilité appliquée par 645-09 sans décision listée qui la tranche. | #101121 |
| Plan 644-03 #P50 | Les dix arbitrages du référentiel ECR, en attente depuis le 21/09. | #100239 |
| Plan 644-03 #P51 | Budget du plan, sans décision listée. | a completer par Skynet |
| Plan 644-03 #P52 | Ajouter ou non `dart_code_metrics` pour une complexité exacte (arbitrage A-07). | #100239 |
| Plan 644-03 #P53 | Les sauts de version majeure tirés par une obligation de boutique, non mesurés. | a completer par Skynet |
| Plan 644-03 #P54 | Contrat de données versionné, volet CI de la proposition 5, personas en CI : hors plan. | a completer par Skynet |
