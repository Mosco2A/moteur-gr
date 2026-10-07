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
langue. Elle se termine par la mention des achats intégrés et les liens
vers les conditions et la politique de confidentialité. Apple les exige dès
qu'un abonnement se renouvelle automatiquement (règle 3.1.2), et
`stepways_sub_noads_monthly` en est un. Longueurs, sur une limite de
4 000 caractères :

| Langue | fr | en | de | it | es |
|---|---|---|---|---|---|
| Description | 2 659 | 2 291 | 2 498 | 2 583 | 2 539 |

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

## Étape 4 — Le paquet iPhone : ce qui est corrigé dans le dépôt

- **Déclaration de chiffrement.** La clef `ITSAppUsesNonExemptEncryption`
  manquait. Elle est posée à **NO** dans `ios/Runner/Info.plist`. Le
  raisonnement légal est écrit dans le document récapitulatif, § Chiffrement.
- **Textes d'autorisation en cinq langues.** Ils n'existaient qu'en
  français. Il y a maintenant cinq `InfoPlist.strings` (fr, en, de, it, es),
  de 8 textes chacun. Ils sont **déclarés dans le projet Xcode** : groupe de
  variantes, phase de ressources de Runner et `knownRegions`. Sans cette
  déclaration, les fichiers resteraient sur le disque sans entrer dans le
  paquet. J'ai vérifié le `pbxproj` avec un analyseur OpenStep.
  `CFBundleLocalizations` liste les cinq langues : sans elle, la page App
  Store n'aurait annoncé que l'anglais.
- **Le texte de localisation en arrière-plan mentait.** Il promettait de
  « partager votre position en temps réel avec vos proches ». Il dit
  maintenant : enregistrement écran éteint, téléphone dans le sac, et la
  position reste sur le téléphone, comme le dit la politique publiée (§ 4.1).
- **Le texte des capteurs de mouvement** parlait de « mesure de batterie ».
  Il dit maintenant à quoi servent les pas : longueur de pas et
  consommation de batterie. La garde du lot 671 qui exige ce texte reste
  verte.
- **Cible de déploiement iOS : 13.0 passe à 15.0** dans le projet.
  - Le Flutter stable du jour (3.47.6), celui que Codemagic prend, réécrit de
    lui-même 13.0 en 15.0 à chaque compilation
    (`ios_deployment_target_migration.dart`).
  - Flutter 3.41, la version du `pubspec.lock`, laisserait 13.0, alors que
    le paquet `health` exige iOS 14.
  - 15.0 compile avec les deux. Seuls les iPhone restés sous iOS 13 ou 14
    sont exclus.
- **Notes au reviewer réécrites.** Connexion requise : NON. Aucun
  identifiant n'est écrit nulle part. Le parcours sans marcher en Corse passe
  par « Try the demo » du catalogue, puis « Start the trek », puis
  « Simulate the next stage ». La démo n'utilise ni GPS ni permission.
- **Spécification des captures réécrite** avec les tailles Apple du
  07/10/2026 : 1320 × 2868, 1206 × 2622, iPad 2064 × 2752, Duo 1398 × 2034
  et 2007 × 2853, en-tête 5244 × 2950 ou 3840 × 1646. Elle liste dix écrans
  à montrer.
- **Une garde de test** (`test/structurel/fiche_magasin_et_apple_test.dart`,
  23 tests) verrouille tout ce qui précède : nom, limites, mots-clés sans
  doublon, promesses retirées dans cinq langues, chiffrement, cinq langues
  des autorisations, copie dans le paquet, et aucun identifiant dans les
  notes.

## Étape 5 — Le document pour remplir la page

`docs/store/fiche-app-store-connect.md` suit l'ordre du formulaire App Store
Connect. Chaque champ y porte « À COLLER » (le texte exact ou son fichier),
« À PRODUIRE » (ce qu'il faut) ou « DÉCISION DE CHRISTOPHE » (les options et
leurs conséquences).

Les réponses aux questions posées par le lot :

- **Adresse d'assistance (obligatoire).** `https://only1cent.com/stepways/conditions`
  pour le français, `…/conditions-en` pour les quatre autres langues. Cette
  page répond 200 et donne `contact@only1cent.com`.
  - Ce qui manquerait pour mieux faire : une page `/stepways/support` dédiée.
  - Le réseau de ce poste refuse `only1cent.com`, donc je n'ai pas pu
    revérifier les pages moi-même : Christophe les ouvre une fois avant de
    coller.
- **Adresse marketing.** Ce champ est **facultatif** chez Apple, contrairement
  à ce que disait la consigne. Il vaut mieux le laisser vide plutôt que d'y
  mettre une page qui ne présente pas l'application.
- **Droits d'auteur.** `2026 Only1Cent`, à condition que ce soit le nom du
  vendeur du compte développeur.
- **Numéro de version.** Le `1.0` du formulaire n'est pas dans le dépôt : c'est
  le nom par défaut qu'App Store Connect donne à la première version. Le
  dépôt enverra `0.1.7`. Le build ne s'attachera à la page que si les deux
  numéros sont identiques. Trois options, laissées à Christophe ; rien n'a
  été changé.
- **Xcode et SDK.** C'est tenable : Codemagic prend `xcode: latest`, qui est
  un Xcode 26 ou plus en octobre 2026. Ce n'est pas vérifié sur Codemagic, et
  le dépôt ne fige pas la version.
- **CFBundleName.** Je propose `StepWays`. Rien n'a été changé, conformément à
  la consigne.

## Étape 6 — Ce que j'ai trouvé en route et que je n'ai pas corrigé

Le détail est au § 8 du document récapitulatif. Classé du plus grave au moins
grave :

1. **Les publicités iPhone partiraient avec les identifiants de test de
   Google.** Aucune chaîne iPhone ne passe `ADMOB_BANNER_IOS` ni
   `ADMOB_REWARDED_IOS`, et `Release.xcconfig` retombe sur l'App ID de test.
   C'est de l'infra, donc hors de mes droits.
2. **L'étape d'analyse de toutes les chaînes Codemagic s'arrête.**
   `dart analyze --no-fatal-infos` est refusé (« Cannot negate option »,
   code de sortie 64). Je l'ai mesuré avec Flutter 3.41.9, la version du
   `pubspec.lock`, et avec 3.47.6, la version stable du jour. Le correctif
   est `dart analyze lib/ test/`. C'est de l'infra, donc hors de mes droits.
3. **Une déclaration de suivi publicitaire sans fenêtre ATT.** C'est un
   motif de refus en revue (règle 5.1.2). La décision revient à Christophe.
4. **Les paquets Santé et Bluetooth sont liés sans fonction visible.** Ce
   sont deux paquets morts à retirer.
5. **Le catalogue montre « Volcans Trail » (sentier de test) et
   « Traversée des Pyrénées » (sans trace).**
6. **L'accueil de l'application promet encore une carte hors ligne**
   (`onboarding.welcomeSubtitle`, `onboarding.downloadSubtitle`).
7. **Le correctif de carte hors ligne** (la ligne 190 de `map_content.dart`)
   appartient à l'autre session.
8. **`docs/store/app-privacy-att.md` et `docs/store/data-safety.md` datent
   d'avant l'extinction du partage.** Ils déclarent la position comme
   collectée.
