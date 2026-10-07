# Rapport — lot fiche magasin et préparation Apple (StepWays)

> Branche `claude/chore/fiche-magasin-et-apple`, prise sur
> `claude/integration/671-batterie-dabord`.
> Ce rapport s'écrit au fil du lot et il est poussé à chaque étape, pour
> survivre aux coupures de réseau.

## Point de départ

- **Tête d'intégration vérifiée au départ : `52fb8ac2`**
  (« docs(671-02): la ligne du lot au journal, le socle podometre »).
  Elle n'a pas bougé depuis la mesure du 07/10 à 13:33.
- `main` n'est pas touchée.
- La base de mémoire (`data/memory.db` et `scripts/memory_helper.py`) n'existe
  pas dans ce conteneur. Les mémoires #101492, #101493, #101486, #101502 et
  #101503 n'ont donc **pas pu être lues**. Chaque chiffre de ce rapport a été
  remesuré dans le dépôt. Là où une mémoire était seule à porter un fait
  (l'historique réel des builds, par exemple), le rapport le dit.
- Hors périmètre, non touchés : `lib/features/trek`, `lib/features/map`,
  `lib/core/geo`.

## Étape 1 — Le nom : « The Ways » devient « StepWays »

- 26 fichiers sous `assets/store` portaient « The Ways » : les deux magasins,
  les cinq langues, les titres, les descriptions et les notes. Les 26 sont
  corrigés. Il reste **0** occurrence dans tout le dépôt.
- Graphie retenue : `StepWays`, celle de `CFBundleDisplayName`, de
  `android:label` et des documents `docs/store/data-safety*.md`. Ni
  `CFBundleDisplayName` ni `android:label` n'ont été touchés.
- Les titres, mesurés langue par langue (limite de 30 caractères chez Apple,
  30 chez Google). « StepWays » fait 8 caractères et « The Ways » en faisait 9,
  donc chaque titre perd un caractère.

| Langue | Titre | Caractères |
|---|---|---|
| fr | StepWays - Rando hors ligne | 27 |
| en | StepWays - Offline hiking | 25 |
| de | StepWays - Offline-Wandern | 26 |
| it | StepWays - Trekking offline | 27 |
| es | StepWays - Senderismo offline | 29 |

Le titre français fait 27 caractères, et non 28 comme annoncé. Il passe.

## Étape 2 — Les promesses qui mentent, retirées des deux magasins en cinq langues

Les cinq promesses de l'audit sont parties. Le détail de chaque retrait, avec
la condition pour la remettre, est dans `assets/store/PROMESSES_RETIREES.md`.
Ce fichier existe parce que les `.txt` se collent tels quels dans les
formulaires et ne peuvent porter aucun commentaire.

1. **Partage en temps réel avec les proches.** Retiré, avec la phrase sur le
   lien privé. Il est aussi retiré des notes Play (classification et
   localisation en arrière-plan) et des étiquettes de confidentialité.
2. **Cartes par secteur, consultables hors ligne.** Retiré. La fiche dit que
   le fond de carte se charge avec le réseau. Le sous-titre iOS disait
   « Carte, GPS et planning offline » et la description courte Android disait
   « 100 % hors ligne » : les deux sont réécrits. **Le correctif d'une ligne
   n'est pas fait**, parce qu'il est dans la carte de l'autre session :
   `lib/features/trek/presentation/map/map_content.dart:190`, il faut brancher
   `tileProviderForTrailProvider(widget.trailId)` derrière
   `inertTileProviderOrNull()`.
3. **Profils altimétriques interactifs.** Retiré. La fiche dit « dénivelé
   positif et négatif » de chaque étape.
4. **Photos géolocalisées.** Remplacé par « photos classées par étape ».
5. **Mode économie de batterie.** Retiré.

**Cinq autres phrases fausses** sont apparues à la remesure, et je les ai
corrigées aussi :

- « Trace GPX haute définition » : la trace a 53 points pour 84 km.
- « Lisible en plein soleil » : aucun mode à fort contraste n'existe.
- « 100 % hors ligne » et « entièrement hors ligne ».
- « Planning adapté à votre rythme » : les temps de marche ne dépendent pas
  du randonneur.
- « Historique de vos randonnées » : c'est seulement la section « Terminés »
  de « Mes treks ».

**Promesses vraies ajoutées à la place** (vérifiées dans le code) :

- ouverture sans compte et démo gratuite ;
- bouton SOS qui appelle le 112, numéros de secours régionaux, fiche
  d'urgence ;
- météo de chaque étape pour le jour même et les deux suivants ;
- risque incendie par étape ;
- liste d'équipement selon la saison, fiches conseils et plan
  d'entraînement ;
- partage du plan, du carnet ou du diplôme par la feuille de partage du
  téléphone ;
- cinq langues, thème sombre ou clair.

La description est désormais **la même pour les deux magasins**, langue par
langue. Longueurs, sur une limite de 4 000 caractères :

| Langue | fr | en | de | it | es |
|---|---|---|---|---|---|
| Description | 2 279 | 1 990 | 2 135 | 2 222 | 2 167 |

**Le titre garde « hors ligne », et c'est un risque que je signale.** Le
titre « StepWays - Rando hors ligne » a été validé par Christophe, donc je ne
l'ai pas touché. Mais tant que le correctif de carte n'est pas fusionné, un
reviewer qui passe en mode avion verra la trace sur un fond vide. Ce qui
marche vraiment hors ligne : la position, la trace, les étapes, les points
d'intérêt, les alertes de sortie de sentier, le carnet et le planning. Le
titre reste défendable, mais c'est à Christophe de trancher. Les options sont
dans le document récapitulatif.

## Étape 3 — Sous-titre, mots-clés, texte promotionnel

**Unité de mesure.** Les « 96 caractères » mesurés pour les mots-clés
français sont en réalité 96 **octets**, pour 92 caractères : chaque lettre
accentuée compte double. Je tiens donc chaque langue à 100 octets au plus,
ce qui passe quelle que soit la façon dont Apple compte.

Les mots-clés ne répètent plus aucun mot du titre ni du sous-titre, qu'Apple
indexe déjà. Mots sortis : « GPS », « hors-ligne » ou « offline », « étape »
ou « stage », et le mot du titre comme « hiking », « Wandern » ou
« senderismo ». La place gagnée est allée à : « GR », « itinérance »,
« météo », « SOS », « Fernwanderweg », « long-distance », « travesía »,
« escursionismo ».

| Langue | Sous-titre (≤ 30) | Mots-clés (≤ 100) | Texte promotionnel (≤ 170) |
|---|---|---|---|
| fr | 29 | 90 car. / 96 octets | 159 |
| en | 28 | 100 / 100 | 149 |
| de | 27 | 95 / 97 | 148 |
| it | 30 | 97 / 97 | 146 |
| es | 30 | 91 / 94 | 140 |

Le texte promotionnel n'existait pas. Il est créé dans
`assets/store/ios/promotional_text_{fr,en,de,it,es}.txt`.
