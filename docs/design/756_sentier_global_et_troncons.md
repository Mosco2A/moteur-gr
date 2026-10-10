# Le sentier global et l'achat de tronçons

Conception — tâche 756. Athena, 10/10/2026.

Demande de Christophe, 09/10 14:52, reprise le 10/10 09:35, mot pour mot :
« 17 et 18, 2 rando dans un groupe GR34 .... il faut qu on apprenne a decouper »
puis « le sentier global et les achats de troncons ».

Ce document est une conception. Aucun code, aucune migration, aucun écran.
Le cycle est : conception, validation par Christophe, puis implémentation.
Tout ce qui est mesuré l'a été sur `main` à `708b82ce`, le 10/10, en lecture seule.

---

## Le problème en une phrase

Aujourd'hui le catalogue vend des sentiers, un par un. Christophe veut vendre un sentier
global qui rassemble plusieurs randonnées, vendre chaque tronçon séparément ou l'ensemble,
et enchaîner deux randonnées en un circuit long, puisque la fin de l'une est le départ de la
suivante.

## Les cinq choses à retenir si on ne lit que ça

1. **Le tronçon reste le produit.** Un tronçon est un sentier. Le groupe est un rayon de
   catalogue. Le parcours est l'affaire du randonneur. Trois objets, trois rôles.
2. **On paie les étapes qu'on n'a pas, jamais celles qu'on a.** Cette phrase répond aux trois
   questions de prix de Christophe : le global contre la somme, la montée en gamme, et le
   chevauchement.
3. **Pas de remise sur le global.** La remise de volume existe déjà, elle est dans les packs
   de crédits, et sur le cas des tronçons 17 et 18 une remise ne changerait pas d'un centime
   ce que la caisse demande. Démonstration au chapitre 2.
4. **Deux tronçons verts peuvent faire un circuit rouge.** La faisabilité doit se calculer sur
   le circuit entier. C'est la conséquence la plus dangereuse de l'enchaînement.
5. **Enchaîner deux sentiers est interdit par construction aujourd'hui**, et la règle qui
   l'interdit a raison. C'est son objet qu'il faut changer, pas la règle. Chapitre 3.

---

## 0. Ce que j'ai mesuré, et ce que je n'ai pas trouvé

### Ce qui est absent de la base, et je le dis avant de m'en servir

**Le découpage du GR34 du 09/10 n'est pas dans memory.db, et les sept règles de découpage non
plus.** Vérifié : les recherches « quiberon », « lorient », « etel », « bateau passage
saisonnier », « gr34 decoupage », « troncon », « regles de decoupage » ne rendent rien qui
porte ce travail, à toutes les profondeurs du moteur. Les entrées du 09/10 à 14:57, 15:02 et
15:03 portent sur autre chose. La demande de 14:52 a été reçue, elle n'a jamais été écrite.

Conséquence : **je ne reprends pas les sept règles, je les reconstitue.** Le chapitre 6 est
une proposition, pas une citation. Si Christophe a gardé les originales, il faut les comparer
ligne à ligne avant de valider.

### Deux contradictions dans ce qui m'est donné comme déjà décidé

**Un — l'arrondi à X,90 n'existe plus.** La fiche de cette tâche dit « environ un euro par
étape arrondi à X,90 ». C'est la décision du 23/05 (#81333 : GR20 16 étapes = 15,90, demi-GR20
8 étapes = 7,90). Elle a été remplacée par `data/apport_stepways/MODELE_ECO.md` du 08/09, qui
se déclare source de vérité unique : l'unité est l'étape, le prix est calé sur le palier
boutique de **0,99 €**, et l'exemple donné est « GR20 16 étapes = **15,84 €** ». Le code dit la
même chose : `kStepTierEur = 0.99` et `eurPriceForSteps(steps) => steps * kStepTierEur` dans
`lib/core/services/monetization_service.dart`. **Il n'y a aucun arrondi à X,90 nulle part dans
le dépôt.** Je travaille sur 0,99.

**Deux — l'accès n'est pas d'une saison, il est sans échéance.** La fiche dit « accès une
saison », reprise de #81333. Remplacée deux fois : MODELE_ECO.md §3 écrit « Crédits/étapes =
acquis **À VIE** (droit de réaliser) », et Christophe lui-même le 27/09 12:35 (#100698) : « les
sentiers achetés, dont la propriété n'a aucune échéance ».

Ce deuxième point ne m'appartient pas : c'est une décision commerciale. Ce que je tranche, et
qui tient dans les deux cas, est la règle **P5** du chapitre 2 : la durée d'accès est un seul
paramètre, porté par le droit du tronçon, et identique pour un tronçon et pour un global. Le
reste de la conception ne change pas selon la réponse.

### Ce que le code dit aujourd'hui

**Le modèle de sentier, et il y en a trois.**
- `lib/core/config/trail_config.dart` — `TrailConfig`, classe Dart `const`. C'est la source de
  vérité à l'exécution : `id`, `name`, `displayName`, `tagline`, `totalStages`,
  `totalDistanceKm`, `totalElevationGain`, `region`, `country`, `directions`,
  `availableDurations`, `gpxAssetPath`, `isShowcaseTrail`, et le reste. **Pas de prix** : le
  prix se déduit de `totalStages`.
- `lib/core/models/trail.dart` — `Trail`, modèle JSON parallèle, les neuf champs métier, peu
  utilisé.
- `lib/core/data/tables/trail_meta_table.dart` — `TrailMeta` en base locale, avec un `code`
  unique qui n'est relié à aucun `TrailConfig`.

**Le catalogue réellement affiché est compilé en dur.** `lib/core/config/trail_catalog.dart`
expose `TrailCatalog.all`, une `List<TrailConfig> const` de **trois** sentiers :
`mare-a-mare-centre` (7 étapes), le sentier de test (5) et la traversée des Pyrénées (12).
L'écran `lib/features/trail/presentation/trail_catalog_screen.dart` lit
`availableTrailsProvider`, qui rend cette liste constante.
**Donc aujourd'hui, ajouter un tronçon vendable veut dire recompiler et livrer
l'application.** Le catalogue distant existe — `lib/features/trail/providers/catalog_provider.dart`
avec `catalogStateProvider`, `CatalogEntry`, `downloadTrail`, plus
`lib/core/services/manifest_service.dart` — il est **construit, testé, et non branché à
l'interface**, et le fichier de manifeste attendu à
`https://storage.googleapis.com/moteur-gr/manifest.json` n'existe nulle part. C'est le
prérequis zéro de tout ce document.

**Le manifeste.** `lib/core/models/trail_manifest.dart` : `TrailManifest { schemaVersion,
trails }` et `TrailManifestEntry { trailId, dataVersion, hash, filePath, fileSize, status,
lastUpdated }`, `status` valant `active` / `draft` / `archived`. **Aucune notion de groupe, de
section ni de tronçon.** Et `schemaVersion` est désérialisé puis **jamais lu** par
`ManifestService` : si on enrichit le manifeste, il faudra enfin le lire.

**L'étape, et c'est là que se joue le découpage.** `lib/core/models/stage.dart` : une étape est
`(trailId, stageNumber)`, numérotée à partir de 1 **dans son sentier**. Rien ne la relie à un
sentier plus grand. Et le numéro absolu **sert d'identité** : `lib/features/trek/providers/gps_providers.dart`
construit `Stage(id: '${sm.stageNumber}', orderIndex: sm.stageNumber, ...)`. Ce numéro est
ensuite stocké tel quel dans `JournalEntries.stageNumber`, `UserProgressEntries.currentStage`,
`TrekSession.completedStages`, `TrekEditLock.doneStageIds` et les repos conseillés.
**Renuméroter un sentier déjà vendu casserait le journal, la progression, la mémoire de
l'arrivée et le verrou d'édition du programme.** C'est la contrainte la plus dure du dépôt.

**Le droit d'accès.** `lib/core/data/tables/trek_entitlements_table.dart` — `TrekEntitlements`,
**clé primaire `trailId`**, une ligne par sentier, portant `owned`, `acquiredStages`,
`totalStages`, `consumedComplementSteps`, `purchaseSource`, `purchasedAt`. Miroir distant à
`users/{uid}/entitlements/{trailId}`. **Faux ami à connaître** : `acquiredStages: 4` est un
**compteur**, pas un ensemble — la table sait combien d'étapes sont acquises, elle ne sait pas
lesquelles.

**Le prix.** `lib/core/services/monetization_service.dart` : `kStepTierEur = 0.99`, les paliers
de crédits `kStepPacks` (11 étapes pour 9,99 € ; 25 pour 19,99 € ; 50 pour 34,99 €),
**`stepPriceForTrail({totalStages}) => totalStages`** — le prix d'un sentier **est** son nombre
d'étapes —, `stagesOfTrail(trailId)` qui lit ce nombre dans le catalogue effectif,
`buyTrail(String trailId)` qui ne reçoit plus aucun prix de son appelant depuis la tâche 614,
le refus nommé `PurchaseStatusResult.unknownPrice`, et `accessFor(trailId)` qui rend
`owned` / `subscriber` / `free`.

**La base locale est volatile sur main.** `lib/core/providers/database_provider.dart` ligne 11 :
`AppDatabase(NativeDatabase.memory())`. Version du schéma : **26**. Le correctif existe dans le
dépôt — commit `c981e789`, « la base de StepWays vit dans un FICHIER », tâche 613 — **il n'est
pas sur main**. Toute table neuve de ce document en dépend : sans lui, le groupe et le parcours
disparaîtraient à la fermeture, comme le reste, et il faudrait les loger dans les préférences
comme le portefeuille.

**La décision du 28/05 sur les sections n'a jamais été implémentée.** #81841 disait :
« TrailManifest doit inclure un champ `sections: List<TrailSection>` (sectionId, name,
stageStart, stageEnd, price) ». Vérifié : `TrailSection`, `sectionId`, `stageStart` et
`stageEnd` comme champ de manifeste **ne figurent nulle part**. Les seules occurrences de
`sections` dans `lib/` sont des rubriques d'interface (`hub.sections` = Préparer / Randonner /
Informations), et celles de `stageEnd` un type d'événement d'arrivée. Cinq mois d'attente.

### Deux découvertes qui changent la conception

**Un — une maquette de cette fonctionnalité existe déjà, et elle est morte.**
`lib/features/packs/` contient `PackType { nord, sud, complet, mam }`,
`SentierPack { id, nom, trailId, type, description }`, `PackCatalog.packId(trailId, type) =>
'${trailId}_$type'`, `PackPurchaseService.productId(packId) => 'pack_$packId'`, un écran
`PackStoreScreen`, des cartes, trois fichiers de tests, et les libellés traduits dans les cinq
langues (`packs.alaCarteNote` = « À la carte : achetez seulement le pack qu'il vous faut, pas
d'abonnement. »). Sa documentation dit mot pour mot que chaque type est « une unité achetable
et téléchargeable indépendante ». C'est exactement la demande de Christophe, écrite avant
l'heure.

Et c'est mort : `PackStoreScreen` n'est routé nulle part, `packFileSourceProvider` est un
no-op qui échoue toujours, `kPackPurchaseRealModeEnabled` vaut `false`, et aucun `PackManifest`
ne porte de liste d'étapes — un pack « nord » ne sait pas quelles étapes il couvre.

**Je tranche : ce module doit être supprimé, pas ressuscité.** Trois raisons. Le mot « pack »
désigne déjà trois choses différentes dans ce dépôt — les paquets de crédits (`kStepPacks`),
les paquets de téléchargement de cartes (`pack_catalog.dart`), et ces paquets commerciaux :
en garder trois sens garantit la confusion. `PackType` est un **enum fermé** à quatre valeurs,
donc ajouter un tronçon demanderait de recompiler, ce qui est exactement ce que la règle DEC-6
interdit. Et son modèle ne porte pas les étapes, donc il ne peut ni calculer un prix ni
détecter un chevauchement. Ce qu'on peut récupérer : les libellés traduits, si les mots
servent. Rien du code.

**Deux — le moteur de fin de randonnée sait déjà marcher un morceau de sentier.**
`lib/features/trek/domain/trek_completion.dart` : `TrekPlan.fromStages(allStages, {direction,
stageIds, forceFull})` — le paramètre `stageIds` restreint le parcours à un sous-ensemble — et
`TrekCompletionKind { full, partial }` avec `TrekCongratulations.partialLabel`. Le commentaire
du fichier dit : « La restriction à un sous-ensemble (demi-parcours, section) se fera via
l'écran de préparation ». **Aucun appelant de production ne passe `stageIds`** :
`gps_providers.dart` appelle `TrekPlan.fromStages` sans lui, donc `isFullTrail` est toujours
vrai. C'est une brique déjà posée, déjà testée, qui attend son appelant. Bonne nouvelle pour
le chapitre 3.

---

## 1. Le modèle

### Le vocabulaire d'abord, parce que le mot « sentier » en désigne trois

Un seul mot recouvre trois choses qui n'ont ni le même propriétaire, ni la même durée de vie,
ni la même raison d'être. Tant qu'elles portent le même nom, chaque discussion repart de zéro.

| Objet | Ce que c'est | Qui le pose | À quoi il sert |
|---|---|---|---|
| **Tronçon** | Un sentier vendable, avec ses étapes, sa trace, son prix | Le publicateur, côté serveur | **C'est le produit.** On l'achète, on le télécharge, on le marche |
| **Groupe** | Un rassemblement ordonné de tronçons sous un nom commercial | Le publicateur, côté serveur | **C'est le rayon.** Il range le catalogue et permet de tout prendre d'un geste |
| **Parcours** | La composition que le randonneur se fabrique | Le randonneur, sur son téléphone | **C'est la marche.** Il porte le programme, le calendrier, le journal |

« GR34 » est un groupe. « Lorient–Quiberon » est un tronçon. « Les tronçons 17 et 18 enchaînés
à partir du 14 juillet » est un parcours.

Les trois ne se recouvrent pas. **Le groupe ne sert pas à l'enchaînement, et le parcours ne
sert pas à la vente.** C'est l'erreur à ne pas faire : confondre ce qu'on vend avec ce qu'on
marche. Un randonneur peut acheter deux tronçons sans les enchaîner, et il peut enchaîner deux
tronçons qui ne sont pas dans le même groupe.

### Les trois formes possibles, et leurs conséquences

**Forme A — le tronçon est le sentier, le groupe est au-dessus.**
Chaque tronçon est un sentier de plein droit : son identifiant, ses étapes numérotées de 1 à N,
sa trace, son prix, sa ligne de droits. Le groupe est un objet neuf, purement commercial, qui
liste ses tronçons dans l'ordre.
Conséquences : la table des droits ne change pas, le prix ne change pas de mécanique, le
téléchargement ne change pas, les collecteurs ne changent pas, la numérotation d'étape ne
change pas — donc ni le journal, ni la progression, ni le verrou d'édition. En échange, **deux
tronçons enchaînés sont deux sentiers**, donc deux programmes, deux calendriers, deux journaux,
sauf si un troisième objet les réunit. C'est le coût de cette forme, et il est réel.

**Forme B — le sentier global est le sentier, le tronçon est une plage d'étapes.**
Le GR34 est un sentier de soixante étapes numérotées de 1 à 60 ; le tronçon 17 est la plage
81–85. C'est la forme de la décision du 28/05 (#81841).
Conséquences : l'enchaînement devient gratuit — marcher le 17 puis le 18, c'est marcher dix
étapes consécutives d'un seul sentier, un programme, un journal, rien à réunir. En échange,
**tout ce qui est clé par `trailId` doit apprendre à porter une plage** : la table des droits,
dont la clé primaire est `trailId` et qui compte les étapes sans savoir lesquelles ; le prix ;
le téléchargement, qui devient partiel sur un sentier alors que la règle de Christophe du
27/09 est la copie complète et atomique (#100721) ; la faisabilité ; le journal ; l'enrôlement
dans les collecteurs. Et un randonneur qui achète un tronçon télécharge quoi — soixante étapes
ou cinq ? Les deux réponses cassent quelque chose. Enfin, cette forme ne répond pas à la
question du GR34 découpé en douze : les tronçons n'auraient ni nom, ni accroche, ni carte
propre, alors que la règle DEC-7 exige qu'un tronçon se tienne seul au catalogue.

**Forme C — le tronçon est une étiquette.**
On pose des mots-clés sur les étapes : « tronçon 17 », « Morbihan », « bord de mer ».
Conséquences : coût nul en tables. Mais une étiquette ne s'achète pas, ne se télécharge pas,
n'a pas de nom d'affichage en cinq langues et ne peut pas porter un prix. Le catalogue a
besoin d'un produit à présenter, pas d'un filtre. **Cette forme ne répond pas à la demande** ;
je la mentionne pour fermer la question.

**Une quatrième forme, examinée et écartée : détourner `TrailItineraries`.**
La table `lib/core/data/tables/trail_itineraries_table.dart` existe, elle est quasi vide, et
elle porte déjà `trailId`, `code`, les cinq noms traduits, `distanceKm`, `elevationGain` et
`stageCount` — c'est-à-dire presque exactement la forme d'un tronçon. Et `TrailStages.itineraryId`
pointe déjà dessus. Mais la sémantique actuelle de `code` est le **sens de marche** (`EW`,
`ns`, `sn`), lu depuis `TrailConfig.directions`. Y mettre « nord » et « sud » créerait une
collision de sens dans la table qui porte déjà le sens. **Écartée pour cette raison seule** :
la place est bonne, le champ est pris.

### Le choix : la forme A, plus le parcours comme troisième objet

**Je choisis la forme A : le tronçon reste le sentier et le produit, le groupe est un objet de
catalogue neuf, et le parcours est un objet du randonneur neuf.**

Les raisons, par ordre de poids.

**Un — la numérotation d'étape sert d'identité, et on ne peut pas y toucher.** Le numéro absolu
de l'étape devient son identifiant dans le moteur de randonnée, et il est stocké tel quel dans
le journal, la progression, la mémoire de l'arrivée et le verrou d'édition du programme. La
forme A ne renumérote rien : chaque tronçon garde sa propre numérotation de 1 à N, pour
toujours. La forme B impose une numérotation globale, donc une renumérotation de tout sentier
existant qu'on voudrait découper.

**Deux — toute l'application est clé par `trailId`.** Ce n'est pas une préférence de style,
c'est une mesure : dix-sept tables en base locale, trois collections distantes, une douzaine de
préfixes de clés de préférences (`departure_date_<id>`, la durée retenue par sentier), les
drapeaux de fonctionnalité (`premium:$trailId`), les événements de mesure, et la clé primaire
de la table des droits. La forme A n'en touche aucun. La forme B les touche tous.

**Trois — la règle de copie complète et atomique de Christophe est une règle sur le sentier**
(#100721 : « un sentier téléchargé est copié en entier », « un sentier à moitié copié ne doit
jamais apparaître comme disponible »). Si le tronçon est le sentier, elle s'applique telle
quelle, et un global téléchargé n'est que N tronçons copiés chacun en entier.

**Quatre — vendre l'ensemble ne demande aucun produit nouveau.** Acheter le global, c'est poser
les droits de tous ses tronçons en un geste. Il n'y a pas de « droit de global » à inventer,
donc rien à migrer sur la table des droits, et un randonneur qui possède déjà un tronçon a
simplement un droit de moins à poser. Tout le chapitre 2 en tire sa simplicité.

**Cinq — le découpage reste modifiable sans toucher au code**, ce qui était l'exigence du
28/05. Ajouter un tronçon, c'est publier un sentier ; le regrouper, c'est modifier le groupe
dans le manifeste. L'esprit de #81841 est tenu ; seule sa forme change.

### Ce que ce choix coûte, et comment je le paie

Le coût de la forme A est l'enchaînement : deux tronçons sont deux sentiers, donc rien ne les
réunit. C'est le **parcours** qui le paie. Le parcours appartient au randonneur, vit sur son
téléphone, et porte la suite ordonnée de tronçons, la date de départ et les jours de repos
qu'il a insérés. Le programme, le calendrier, la faisabilité et le journal se calculent sur le
parcours, plus sur le sentier. C'est la vraie dépense de cette conception, et elle est chiffrée
au chapitre 4.

### L'ancrage sur le sentier mère, la pièce qui rend le chevauchement calculable

Un groupe peut vendre des tronçons qui se chevauchent, et ce n'est pas un cas tordu : c'est le
GR20. Le groupe GR20 contient « intégral » (16 étapes), « nord » (8) et « sud » (8), et
l'intégral recouvre entièrement les deux autres. Sans rien de plus, un randonneur qui possède
le nord et achète l'intégral paierait seize étapes dont huit qu'il a déjà.

La pièce qui ferme ça : **chaque appartenance d'un tronçon à un groupe porte son ancrage sur le
sentier mère** — le rang du tronçon dans le groupe, et la plage d'étapes mères qu'il couvre.

Le sentier mère est une **numérotation de référence du groupe**, pas un sentier téléchargeable :
personne ne l'achète, personne ne le marche, il ne sert qu'à dire que l'étape 3 du nord et
l'étape 3 de l'intégral sont la même journée de marche.

Cet ancrage vit dans le manifeste, posé par le publicateur. Il ne touche ni `StageModel`, ni la
table des étapes, ni la table des droits. **C'est une donnée du groupe, pas une donnée de
l'étape.** C'est le point le plus important de ce chapitre : c'est lui qui rend tout le
chapitre 2 calculable sans migration lourde.

### La forme du groupe, en clair

Un groupe porte : un identifiant ; un nom d'affichage dans les cinq langues ; une accroche ; un
pays et une région ; un statut `active` / `draft` / `archived`, comme un sentier, pour qu'un
groupe se teste avant d'être visible — c'est le mécanisme du brouillon de #100738, qui met un
objet dans la liste et hors du catalogue ; la longueur de sa numérotation de référence ; et la
liste ordonnée de ses membres.

Un membre porte : le `trailId` du tronçon, son rang dans le groupe, et sa plage d'étapes mères
— première et dernière.

Trois règles de bonne formation, vérifiées **à la publication** et jamais sur le téléphone :
la plage d'un membre tient dans la numérotation de référence ; le nombre d'étapes du tronçon
égale la longueur de sa plage ; un groupe sans membre ne se publie pas.

---

## 2. Le prix

### Le fait dur qui commande tout : les boutiques vendent des paliers

Un achat intégré est facturé par Google Play ou par l'App Store, et ces deux boutiques ne
vendent pas des montants libres, elles vendent des paliers. 0,99 €, 9,99 €, 19,99 € et 34,99 €
sont des paliers. **15,84 € n'en est pas un, et 8,91 € non plus.** On ne peut pas encaisser un
prix calculé.

C'est pour cette raison que le modèle a deux étages, et le code le dit lui-même : le montant en
euros d'un sentier est « un ancrage d'affichage », et le paiement réel passe par un **pack de
crédits** dont le prix est, lui, un palier. Les crédits sont des étapes, ils sont fongibles, et
ils sont acquis à vie.

**Conséquence, et c'est la clé de tout ce chapitre : l'unité de prix est l'étape, l'euro est un
affichage.** Toute question de prix sur le global se tranche donc en étapes. Une remise en
pourcentage, ou un prix de global négocié, produirait un montant que la caisse ne sait pas
encaisser.

### Les cinq règles de prix

**P1 — Le prix d'un tronçon ne change pas.** Un tronçon coûte son nombre d'étapes, au palier en
vigueur. Rien de ce qui existe n'est touché, et `stepPriceForTrail` reste ce qu'il est. Un
tronçon à zéro étape est un tronçon gratuit, au sens du §2 bis de MODELE_ECO.md : jouable, non
possédé, avec publicité.

**P2 — Le prix d'un global est la somme des étapes mères DISTINCTES de ses tronçons.**
Distinctes : une étape mère couverte par deux tronçons est comptée **une fois**. C'est
l'ancrage du chapitre 1 qui le permet. Sur le groupe GR20, « intégral + nord + sud » coûte
seize étapes, pas trente-deux.

**P3 — On ne paie que les étapes qu'on n'a pas.** À tout achat, le prix porte sur les étapes
mères du panier **moins** celles déjà couvertes par un droit possédé. Jamais de remboursement,
jamais de double paiement, jamais d'arithmétique à expliquer.

**P4 — Pas de remise sur le global.** Le global coûte exactement la somme de ses tronçons
distincts. Je développe plus bas, parce que c'est la question que Christophe pose le plus
directement et que ma réponse est non.

**P5 — La durée d'accès est un seul paramètre, identique pour un tronçon et pour un global.**
Que la réponse soit « à vie » (MODELE_ECO.md §3 et Christophe le 27/09) ou « une saison » (la
fiche de cette tâche), elle doit être la même pour les deux, et **portée par le droit du
tronçon, jamais par le groupe**. Sinon on obtient un global expiré dont les tronçons sont
encore valides, ou l'inverse, et plus personne ne sait ce qu'il possède. Le groupe ne porte
aucun droit, donc il ne porte aucune échéance.

### P3 répond aux trois questions de Christophe avec une seule phrase

C'est tout l'intérêt de l'avoir écrite comme ça. **On paie les étapes qu'on n'a pas, jamais
celles qu'on a.**

*Que se passe-t-il quand quelqu'un a déjà acheté un tronçon et achète ensuite le global ?*
Il paie les étapes du global moins celles de son tronçon. Sur le GR20 : il possède le nord
(8 étapes), il prend l'intégral (16 étapes mères), il paie **8 étapes**. Il n'y a ni remise à
calculer, ni remboursement à verser, ni message à écrire pour expliquer un écart. La
transaction pose les droits des tronçons qui lui manquent, et laisse le sien intact — avec sa
date d'achat, sa progression et son journal.

*Quelle est la règle quand deux tronçons se chevauchent sur une étape commune ?*
L'étape mère est payée une fois. Qu'elle soit achetée dans le même panier (P2) ou à six mois
d'écart (P3), c'est la même règle et le même calcul.

*Combien coûte le global par rapport à la somme de ses tronçons ?*
Exactement pareil, aux chevauchements près — et **moins cher que la somme dès qu'il y a
chevauchement**, ce qui est le cas du GR20 et de tout groupe qui vend un intégral à côté de ses
parties.

### Pourquoi je dis non à la remise sur le global

Quatre raisons, par ordre de poids.

**Un — la remise de volume existe déjà, et elle est dans les packs de crédits.** Onze étapes
pour 9,99 € font 0,91 € l'étape ; vingt-cinq pour 19,99 € font 0,80 € ; cinquante pour 34,99 €
font 0,70 €. Un randonneur qui prend large achète un gros pack et paie **déjà** son étape 29 %
moins cher qu'au détail. Ajouter une remise sur le global serait une remise sur une remise, et
personne ne saurait plus dire ce qu'une étape coûte.

**Deux — elle casserait le seul invariant propre du modèle.** Une étape coûte une étape. Le
portefeuille, la cagnotte de l'abonné (deux étapes par mois), les packs et les prix sont tous
comptés dans la même unité. Dès qu'une étape coûte 0,9 étape dans un cas, le portefeuille cesse
d'être une monnaie et devient un barème.

**Trois — sur un petit global, la remise serait invisible à la caisse.** Démonstration sur le
cas de Christophe. Tronçons 17 et 18, cinq étapes chacun, dix au total, portefeuille vide.
*Sans remise* : besoin de dix étapes, le plus petit pack couvrant est celui de onze, la caisse
demande **9,99 €**, il reste une étape au portefeuille. *Avec une remise d'une étape par tronçon
au-delà du premier* : besoin de neuf étapes, le plus petit pack couvrant est **toujours celui de
onze**, la caisse demande **9,99 €**, il reste deux étapes. **Le randonneur paie le même prix et
voit un rabais annoncé qui ne se produit pas.** C'est pire que pas de remise du tout.

**Quatre — P3 rend la remise inutile commercialement.** La raison d'acheter le global n'est pas
qu'il est moins cher, c'est qu'il est **plus simple** : un geste, un téléchargement annoncé une
fois, un parcours déjà composé, un prix dit une seule fois. Et la raison de ne pas hésiter est
que **rien n'est perdu** si on commence petit : acheter le 17 puis le global coûte exactement le
même total qu'acheter le global tout de suite. Un modèle où avancer par petits pas ne coûte rien
de plus vend plus qu'un modèle qui punit l'hésitation.

**Si Christophe veut une remise malgré ça**, la seule forme qui reste dans l'unité du système
est : *une étape offerte par tronçon au-delà du premier*, appliquée en réduction du besoin, avec
deux conditions. La vitrine doit afficher **deux lignes** — les étapes payées et le reste au
portefeuille —, sinon le point trois ci-dessus se transforme en reproche. Et il faut un **pack
intermédiaire**, parce que la granularité onze / vingt-cinq / cinquante avale toute remise
inférieure à un palier. Ce pack manquant est déjà un défaut connu, relevé sous le nom M1bis : un
sentier de douze étapes affiche 11,88 € et la caisse demande 19,99 €, le randonneur gardant
treize étapes. Ce défaut n'a jamais été arbitré par Christophe, et les globaux vont l'aggraver.

### Les deux garde-fous à ne pas casser

**Le prix affiché est le prix débité.** C'est un acquis de la tâche 614 : `buyTrail` ne reçoit
plus de prix de son appelant, il le lit lui-même dans le catalogue effectif, et la vitrine
demande le prix au même service. La même discipline s'applique au global : **l'écran du groupe
ne calcule jamais le prix, il le demande.** Sinon on retrouve exactement le trou de 614, un cran
plus haut.

**Un prix inconnu se refuse, il ne vaut pas zéro.** `PurchaseStatusResult.unknownPrice` refuse
l'achat d'un sentier que le catalogue ignore, sans rien débiter et sans poser de droit. Un
groupe dont **un seul** membre a un prix inconnu doit être refusé **en entier**, par le même
refus nommé, et le dire. Un global qui vend neuf tronçons sur dix en silence est le même défaut
que la vitrine d'autrefois, en plus gros.

---

## 3. L'enchaînement

### Le mur qui est là avant tout le reste

**Enchaîner deux sentiers dans la même sortie est interdit par construction aujourd'hui.**
`lib/features/trek/data/trek_session_manager.dart` expose `ensureSingleActiveThenStart()`, et
`lib/features/treks/presentation/widgets/active_trek_conflict_dialog.dart` impose, pour démarrer
un second trek, de **terminer, abandonner ou annuler** l'autre. La règle est l'unicité de la
randonnée active, tous sentiers confondus.

**Cette règle a raison, et il ne faut pas la lever.** On ne marche pas deux choses à la fois, et
deux sessions actives produiraient deux traces GPS concurrentes, deux journaux et deux
progressions sur le même corps.

**Ce qu'il faut changer, c'est son objet, pas la règle.** L'unité active devient le **parcours**.
Un seul parcours actif à la fois, et un parcours peut contenir plusieurs tronçons. L'intention de
la règle est préservée mot pour mot ; elle s'applique un cran plus haut. C'est la bascule
centrale du chapitre 4, et c'est elle qui rend tout le reste possible.

### Jonction automatique ou geste du randonneur : c'est un geste, proposé

**Je tranche : la jonction est un geste du randonneur, que l'application propose.**

Posséder deux tronçons voisins ne veut pas dire qu'on va les marcher d'affilée. Beaucoup
achèteront le 17 pour juillet et le 18 pour l'année suivante. Une jonction automatique
fusionnerait deux journaux et un calendrier sans qu'on l'ait demandé, et **défusionner est
beaucoup plus difficile que fusionner**. Proposer coûte un bouton ; devenir coûte un dégât.

L'application propose quand trois conditions tiennent : les deux tronçons sont possédés, et ils
sont soit **consécutifs dans un groupe** — le cas ordinaire, déclaré par le publicateur — soit
**géographiquement joignables**, c'est-à-dire que le point d'arrivée du dernier est proche du
point de départ du suivant. Un geste suffit à accepter.

La distance de ce « proche » est un paramètre, pas une vérité : je propose de partir à **2 km** et
de le mesurer sur de vrais tronçons avant de le graver. Les coordonnées nécessaires existent
déjà : `StageModel` porte `startLat`, `startLng`, `endLat`, `endLng`.

### Le jour de transition : il n'y en a pas, par défaut

**Je tranche : zéro jour de transition par défaut, et le randonneur peut insérer un jour de
repos s'il le veut.**

C'est la règle de Christophe du 09/10 09:53 qui le dit, mot pour mot : « chaque étape a déjà sa
journée : un jour de plus n'ajoutera que du repos ». Arriver à Quiberon le soir du jour 5 et
repartir de Quiberon le matin du jour 6, c'est une nuit comme les autres. **La transition n'est
pas une journée, c'est une nuit.** L'inventer en ferait une journée de marche fantôme dans le
programme et dans le calendrier.

Mais une journée d'arrêt peut être **voulue** : refaire les courses, laver, attendre un bateau
qui ne passe pas ce jour-là. C'est alors un jour de repos ordinaire, inséré par le même geste
qu'ailleurs dans le programme — le mécanisme existe, `plannedDaysProvider` porte déjà
`isRestDay` et un cache de repos manuels. **Pas de mécanisme neuf pour la transition.**

### Ce que l'enchaînement change, domaine par domaine

**Le programme.** Aujourd'hui `plannedDaysProvider` est indexé par `trailId`, et
`RetainedPlanStore` garde une clé de préférences **par sentier**, avec ce commentaire : « UNE
CLÉ PAR SENTIER : deux sentiers ont deux plans. » Il devient le programme **du parcours**. Chaque
ligne garde son origine — « jour 7, étape 2 du tronçon Quiberon–Vannes » — parce que le
randonneur doit pouvoir rattacher sa journée au tronçon qu'il a acheté, et parce que les données
de l'étape vivent sous `(trailId, stageNumber)`. Le rang dans le parcours est un affichage
calculé, jamais une donnée stockée en double. C'est là que `TrekPlan.fromStages(stageIds:)`, déjà
écrit et jamais appelé, trouve son emploi.

**Le calendrier.** Une seule date de départ, celle du parcours. Aujourd'hui la date de départ est
une clé de préférences `departure_date_<trailId>`, donc une par sentier. Les dates des tronçons
suivants se déduisent, elles ne se saisissent pas. **C'est le point qui change le plus de choses
en aval** : le bateau du jour 13 n'est pas le bateau du jour 3, la météo du jour 13 n'est pas
celle du jour 3, et la saison du sac à dos peut avoir changé si le circuit franchit un changement
de saison — le sac est déjà saisonnier et dérive sa saison de la date de départ. **Tout ce qui
est daté doit être daté à la date calculée dans le parcours, jamais à la date de départ.**

**Le ravitaillement.** Le point de jonction est presque toujours une ville — Quiberon, Vannes —,
donc c'est une occasion de ravitaillement par nature, et le plan doit le dire au lieu de le
laisser deviner. Le vrai risque est l'inverse de ce qu'on croit : ce n'est pas que le sac soit
vide à la jonction, c'est que **le calcul reparte de zéro** et traite le jour 6 comme un premier
jour. Et il y a un piège mesuré : `supply_alert_provider.dart` exprime l'écart au prochain
commerce **en nombre d'étapes**, avec un seuil par sentier. Un écart compté en étapes se remet à
zéro à chaque tronçon. La fenêtre d'autonomie se calcule sur le parcours, de bout en bout.

**Les hébergements.** La nuit de jonction est **une** nuit. Les nuitées sont aujourd'hui stockées
sous la clé logique `(trailId, dayNumber)`, avec `dayNumber = 0` pour la veille du départ. Si le
tronçon qui arrive et celui qui part revendiquent chacun la nuit à Quiberon — l'un comme sa
dernière nuit, l'autre comme sa veille de départ —, le randonneur réserve deux fois et paie deux
fois. **Règle : la nuit de jonction appartient au tronçon qui arrive.** Une nuit, un
propriétaire. C'est une règle d'une ligne qui ferme un défaut de double comptage que personne ne
verrait avant une facture.

**La faisabilité.** C'est la conséquence la plus importante et la plus dangereuse à manquer.
**Un circuit de dix jours n'est pas deux randonnées de cinq jours.** La fatigue se cumule, et le
modèle de faisabilité le sait déjà : il raisonne sur le cumul et les repos conseillés
(`FeasibilityFormula.recommendedRestAfterStageIndex`, `restDaysAfterStageProvider`). Donc **deux
tronçons verts peuvent faire un circuit rouge**, et si la faisabilité est calculée tronçon par
tronçon, l'application dira deux fois « c'est bon » pour un circuit qui ne l'est pas. Elle doit
se calculer sur le parcours entier.
Bonne nouvelle mesurée : **le profil du randonneur est déjà global**, pas par sentier
(`HikerProfile`, `PastHikeEntries`, `HikerExperienceNote`, persistés dans les préférences). Il
n'y a donc rien à dédupliquer : c'est le verdict qui doit monter au parcours, pas le profil.

**Le journal.** Un journal par parcours, jamais deux pour une seule marche. Aujourd'hui
`JournalEntries` porte `(trailId, stageNumber)` et les statistiques cumulées agrègent
`getByTrailId(trailId)` : un journal multi-tronçons n'existe pas. Chaque journée y nommera son
tronçon.
Sur le diplôme, je tranche : **le diplôme se gagne par tronçon**, parce que le tronçon est le
produit et donc la promesse, **plus une distinction de groupe quand tous les tronçons d'un groupe
ont été marchés** — peu importe si c'est d'un coup ou sur cinq ans. C'est la bonne réponse
produit : elle récompense celui qui en achète plus, sans punir celui qui prend son temps. Et le
moteur sait déjà dire « parcours partiel » : `TrekCompletionKind.partial` et
`TrekCongratulations.partialLabel` existent.

---

## 4. Ce que ça coûte dans l'application

Je nomme les tables et les écrans. Je ne les écris pas. L'ampleur est donnée en trois crans :
**petit** = un ou deux fichiers, aucune table ; **moyen** = plusieurs fichiers, une table ou un
écran ; **gros** = une bascule qui traverse une fonctionnalité entière. **Je ne convertis pas en
jours** : je n'ai pas mesuré la surface de tests, et un chiffre inventé serait pire que pas de
chiffre.

### Le prérequis zéro, et il n'est pas dans mon périmètre

**Le catalogue distant doit être branché.** Tant que `TrailCatalog.all` est une liste `const` de
trois sentiers, vendre douze tronçons du GR34 veut dire douze `TrailConfig` compilés et une
livraison par tronçon — c'est-à-dire exactement ce que la règle DEC-6 interdit. Les pièces
existent et sont testées (`catalogStateProvider`, `ManifestService`, `CatalogEntry`,
`downloadTrail`) ; il manque le branchement à l'interface et le fichier de manifeste.
**Rien de ce document n'a de sens avant ça**, et c'est un chantier à part entière.

**Et la base locale doit devenir durable.** Sur main elle est en mémoire
(`NativeDatabase.memory()`), donc toute table neuve disparaîtrait à la fermeture. Le correctif
existe dans le dépôt (commit `c981e789`, tâche 613) et n'est pas sur main. Soit il y arrive, soit
le groupe et le parcours doivent vivre dans les préférences comme le portefeuille — ce qui est
faisable mais moins propre.

### Ce qui ne change pas, et c'est le gros du bénéfice de la forme A

- `TrekEntitlements` : **aucun changement**, ni de schéma ni de clé. Un droit par tronçon. Le
  miroir distant `users/{uid}/entitlements/{trailId}` ne change pas non plus.
- `StageModel`, la table des étapes, et la numérotation : **aucun changement**. Donc ni le
  journal, ni la progression, ni la mémoire de l'arrivée, ni le verrou d'édition du programme.
- `buyTrail`, `quoteTrail`, `accessFor`, `stagesOfTrail`, `stepPriceForTrail` : signatures
  **inchangées**.
- Le téléchargement et sa règle d'atomicité (#100721) : **inchangés**. Un global téléchargé est
  N tronçons copiés chacun en entier.
- Les collecteurs météo et risque incendie : **inchangés**. Un tronçon est un sentier, donc il
  s'enrôle comme un sentier. Un seul piège : **un groupe ne s'enrôle jamais** — il n'a pas
  d'étapes, donc ni météo ni risque incendie. L'étape 13 du mécanisme d'ajout (#100738)
  s'applique aux tronçons, un par un.
- Le profil du randonneur : **déjà global**, rien à faire.

### Ce qu'il faut ajouter

| Chantier | Ce que c'est | Ampleur |
|---|---|---|
| Le groupe dans le manifeste | `TrailManifest` gagne une liste de groupes ; `TrailManifestEntry` ne change pas. Plus les trois contrôles de bonne formation **à la publication**, et la lecture enfin effective de `schemaVersion` | Petit côté modèle, moyen côté publicateur |
| Les deux tables du groupe | Groupes et appartenances (rang, plage d'étapes mères), en lecture seule sur le téléphone. Migration du schéma local, **27** | Moyen |
| Les deux tables du parcours | Le parcours du randonneur et ses membres ordonnés, plus sa date de départ et ses repos. Même migration. À persister durablement, cf. prérequis | Moyen |
| Le devis multi-tronçons | P2 et P3 dans `MonetizationService` : étapes mères distinctes, moins celles possédées. **C'est la seule arithmétique neuve de cette conception** | Moyen |
| La vitrine d'achat | `PaywallSheet` doit annoncer un panier : ce qu'on prend, ce qu'on possède déjà, ce qu'on paie, ce qui reste au portefeuille. Et refuser le groupe entier sur un seul prix inconnu | Moyen |
| Le catalogue | `trail_catalog_screen` présente un groupe comme **une** carte qui ouvre sur ses tronçons. Aujourd'hui il présente des sentiers à plat | Moyen |
| Mes treks | `my_treks_provider` et `entitlements_provider` rangent les tronçons possédés sous leur groupe, et proposent la jonction quand les conditions du chapitre 3 tiennent | Moyen |
| L'écran du parcours | Composer, ordonner, dater, insérer un repos. Écran neuf | Moyen |
| **L'unicité de la randonnée active passe du sentier au parcours** | `trek_session_manager`, `ensureSingleActiveThenStart`, le dialogue de conflit. Peu de fichiers, mais c'est **le** verrou de l'enchaînement | **Gros par le risque**, petit par la taille |
| **Programme et calendrier sur le parcours** | Ils prennent un parcours là où ils prennent un `trailId`, y compris les clés de préférences par sentier | **Gros** |
| **Faisabilité sur le parcours** | Le cumul traverse les tronçons. Le chantier à ne pas rater | **Gros** |
| **Journal sur le parcours** | Un journal, chaque jour nommant son tronçon. Plus la distinction de groupe | **Gros** |
| Ravitaillement et hébergements | La fenêtre d'autonomie sur le parcours — l'écart compté en étapes ne doit plus se remettre à zéro ; la nuit de jonction appartient au tronçon qui arrive | Moyen chacun |
| Supprimer `lib/features/packs/` | Le module mort, son écran non routé, ses trois fichiers de tests. Récupérer les libellés traduits si les mots servent | Petit, et à faire **avant** d'écrire le nouveau, pas après |

### L'ordre, parce qu'il n'est pas libre

1. **Le ménage et les prérequis.** Supprimer `lib/features/packs/`, brancher le catalogue
   distant, faire arriver la base durable. Rien ne commence avant.
2. **Le groupe et le prix.** Les deux tables du groupe, le manifeste, le devis multi-tronçons,
   la vitrine, le catalogue. À la fin de ce lot, **Christophe peut vendre le GR34 par tronçons
   et en bloc**, et l'enchaînement n'existe pas encore. C'est déjà la moitié de la demande, et
   c'est la moitié qui rapporte.
3. **Le parcours**, sans la faisabilité : l'unicité qui monte d'un cran, composer, ordonner,
   dater, un journal, un programme.
4. **La faisabilité sur le parcours en dernier**, parce qu'elle est la plus lourde et parce
   qu'elle doit être juste. Mais **tant qu'elle n'est pas faite, un circuit long composé de deux
   tronçons verts ne doit pas s'annoncer vert** : il doit dire qu'il ne sait pas. Un silence vaut
   mieux qu'un faux vert sur une donnée qui engage le corps du randonneur.

### Les cinq pièges que je signale maintenant

**Un — le prix affiché par l'écran du groupe.** S'il le calcule lui-même, on a refait le trou de
la tâche 614 un cran plus haut. Il demande, il ne calcule pas.

**Deux — le téléchargement partiel d'un global est normal.** Acheter dix tronçons et en
télécharger six est un **état**, pas un défaut, et il doit se nommer. La règle d'atomicité porte
sur le tronçon, jamais sur le groupe.

**Trois — la numérotation de référence n'est pas un sentier.** Si quelqu'un la rend
téléchargeable ou achetable « pour simplifier », on retombe dans la forme B par la fenêtre, avec
toutes ses conséquences et aucune de ses décisions.

**Quatre — il y a deux chaînes d'étapes incompatibles dans le dépôt**, et un découpage doit
choisir laquelle porte la vérité. La chaîne simple est `Stages.trailId` + `stageNumber`, utilisée
par les écrans ; la chaîne riche est `TrailMeta` → `TrailItineraries` → `TrailStages.itineraryId`
→ `TrailAccommodations.stageId`, seule à porter les hébergements et les points d'intérêt riches.
Deux semeurs les remplissent séparément, et l'un fabrique un itinéraire dégénéré où
`id == itineraryId == trailId`. **Un découpage fait sur une seule des deux sera juste sur les
étapes et faux sur les hébergements.**

**Cinq — le sentier choisi n'est pas persisté** (`selectedTrailIdProvider` est un état en
mémoire ; au redémarrage on revient sur le sentier par défaut). Le parcours, lui, **doit** être
persisté : c'est l'objet qui porte une marche en cours. Ne pas reproduire le même oubli un cran
plus haut.

---

## 5. Le banc d'essai : le GR34, tronçons 17 et 18

### Les chiffres, et ce qu'ils valent

**Ce sont des ordres de grandeur, pas des mesures.** Ils viennent de la demande de Christophe,
pas d'un relevé de terrain ni d'une trace. Aucun n'a été vérifié contre un GPX.

| Tronçon | Trajet | Durée | Distance |
|---|---|---|---|
| 17 | Lorient – Quiberon | environ 5 jours | environ 95 km |
| 18 | Quiberon – Vannes | environ 5 jours | environ 109 km |

**Ce que je ne sais pas et que je n'invente pas** : le découpage exact en étapes — cinq jours ne
veut pas dire cinq étapes de même longueur —, les points de nuit, les hébergements, les
ravitaillements, le dénivelé, et les horaires et saisons réels des trois passages en bateau. Tout
cela est à relever avant publication, et c'est le travail du publicateur, pas celui de cette
conception.

### Le cas déroulé, bout à bout

Le groupe **GR34** est publié avec, parmi d'autres, les membres 17 et 18 dans cet ordre.
Quiberon est l'arrivée de la dernière étape du 17 et le départ de la première du 18 : c'est un
**point** partagé, pas une **étape** partagée. **Il n'y a donc aucun chevauchement sur ce cas**,
et le prix du global des deux est la somme franche.

Avec cinq étapes par tronçon : chaque tronçon coûte cinq étapes, le global des deux en coûte dix.
Portefeuille vide, le plus petit pack couvrant est celui de onze à 9,99 €, et il reste une étape
créditée. Pas de remise, et elle serait invisible ici de toute façon (chapitre 2).

Le randonneur achète les deux. L'application lui propose la jonction ; il accepte. Il obtient un
parcours de dix journées de marche, une date de départ, un programme continu, un calendrier
continu, un journal, et une faisabilité calculée sur dix jours de cumul — pas deux fois cinq. La
nuit à Quiberon appartient au tronçon 17. À l'arrivée, il gagne deux diplômes de tronçon, et la
distinction du groupe GR34 quand il aura marché les autres.

S'il n'avait acheté que le 17, puis le global du GR34 un an plus tard : il paie les étapes mères
du GR34 moins les cinq qu'il possède. Son tronçon 17 reste intact, avec sa progression et son
journal.

### Les trois passages en bateau, et le verdict

Trois passages en bateau concernent ces tronçons, et ils sont **saisonniers** : la rade de
Lorient, la barre d'Étel, et Locmariaquer vers Port-Navalo. Un circuit long qui dépend d'un
bateau saisonnier pose une question que la conception doit traiter, et la voici traitée.

**Le passage est une donnée du sentier, portée par l'étape, pas une astuce d'affichage.** Il a un
nom, une étape de rattachement, une saison d'exploitation, une source nommée et une date de
vérification. Il est publié par le **publicateur**, pas par le collecteur : c'est une donnée
éditoriale, qui ne change pas six fois par jour mais qui se **date**. C'est exactement la famille
« transports » déjà définie dans la conception 611 (#100738), avec sa péremption d'une saison et
son affichage « vérifié en *mois année* ». **Je ne crée pas de doctrine neuve, je réutilise celle
qui existe.**

**Quatre états, jamais deux.** La règle est déjà écrite pour le risque incendie (#100738) et elle
vaut mot pour mot ici. **Connu** : le bateau passe, avec sa saison et sa date de vérification.
**Hors saison** : le bateau ne passe pas à cette date — ce n'est pas une absence d'information,
c'est une réponse, et il faut la distinguer d'une panne sinon on apprend au randonneur à ignorer
le message. **Périmé** : la donnée date d'une saison antérieure, on le dit, on n'affirme rien sur
aujourd'hui. **Inconnu** : on ne sait pas, et on renvoie à l'autorité qui sait.
**Un passage dont on ne connaît pas la saison ne s'affiche jamais comme ouvert.** Un défaut « ça
passe » serait un mensonge confortable, et sur un bras de mer il ne se corrige pas en marchant un
peu plus.

**Le passage se vérifie à sa date calculée dans le parcours, jamais à la date de départ.** C'est
le point que seul l'enchaînement révèle. Un bateau ouvert au jour 3 peut être fermé au jour 13 :
dix jours de décalage traversent une fin de saison. Un circuit long **déplace les dates de tout
ce qui vient après la jonction**, et donc déplace les passages dans le calendrier des bateaux.
Vérifier à la date de départ serait juste pour le tronçon 17 et faux pour le 18.

**Ce qu'un passage fermé produit : un avertissement daté, pas un verdict d'infaisabilité.** Le
randonneur sait mieux que l'application s'il peut faire autrement — un taxi-bateau, un détour, un
bus, un autre jour. L'application dit ce qu'elle sait : « le *tel* jour, à *tel* endroit, ce
bateau ne passe pas à cette saison, *source*, vérifié en *mois année* ». Elle ne dit pas
« infaisable ». Je ne connais pas les contournements à pied de ces trois passages et je ne les
invente pas : le détour par le fond de la rade de Lorient, s'il existe, est un relevé de terrain.

**Sur la vente, je tranche : un tronçon à passage saisonnier se vend toute l'année, avec
l'avertissement affiché avant le paiement.** Interdire l'achat hors saison empêcherait d'acheter
en février pour marcher en juillet, qui est le comportement normal du randonneur et le meilleur
moment pour lui vendre. Mais l'avertissement doit être **avant** la caisse, et nommer le passage
et sa saison. Vendre un circuit long qui dépend d'un bateau sans le dire, c'est vendre un sentier
qu'on ne peut pas finir.

**Et le vrai danger du circuit long, qui est une règle de découpage, pas une règle de prix** : un
bateau saisonnier transforme un découpage sain en découpage fragile. Si le point de jonction d'un
groupe **est** un passage en bateau, alors la jonction elle-même est saisonnière, et le circuit
long devient imprévisible. Ici Quiberon est une ville et le point de jonction est à terre : le 17
et le 18 se joignent sans bateau, ils sont sains. La règle qui en sort est DEC-8 au chapitre 6.

---

## 6. Les sept règles de découpage

### Avertissement

Les sept règles posées le 09/10 **ne sont pas dans la base** (chapitre 0). Ce qui suit est une
**reconstitution**, pas une citation. Si Christophe a gardé les originales, il faut les comparer
avant de valider ce chapitre. Je les ai reconstituées en partant du cas du GR34 et des
contraintes mesurées dans le code, et j'ai ajouté les trois qui manquaient.

### Les sept, reconstituées

**DEC-1 — On coupe sur une nuit, jamais sur une journée de marche.** Un tronçon commence le matin
et finit le soir. **Tient.** C'est la règle qui rend le chevauchement impossible dans le cas
ordinaire : deux tronçons consécutifs partagent un point, pas une étape.

**DEC-2 — On coupe là où on peut arriver et repartir.** Le point de coupe doit être accessible
autrement qu'à pied : gare, car, port desservi toute l'année. **Tient, et c'est la plus
importante commercialement** : un tronçon qu'on ne peut pas rejoindre ne se vend pas, quelle que
soit sa beauté.

**DEC-3 — On coupe là où on peut dormir et se ravitailler.** Le point de coupe est une ville ou un
bourg. **Tient.** Corollaire : le point de coupe est une occasion de ravitaillement par nature, et
le plan doit le dire.

**DEC-4 — Un tronçon fait entre quatre et huit étapes.** En dessous, il ne vaut ni un achat ni une
préparation. Au-dessus, il redevient un engagement de vacances entières et perd l'intérêt du
découpage. **Tient, avec une réserve** : ce sont des bornes de bon sens, adossées à aucune mesure
d'usage. À revoir quand il y aura des ventes.

**DEC-5 — Un tronçon se marche dans les deux sens.** Le découpage ne présuppose pas le sens de
marche. **Tient**, et le code y est prêt : `TrailConfig.directions` existe, avec `NS` et `SN` par
défaut.

**DEC-6 — Le découpage est une donnée, jamais du code.** Ajouter, déplacer ou regrouper un tronçon
se fait côté serveur, sans livrer l'application. **Tient, et c'est la seule règle qu'on sait déjà
avoir trahie deux fois** : la décision du 28/05 (#81841) disait la même chose et n'a jamais été
implémentée, et le catalogue affiché est aujourd'hui une liste compilée en dur. C'est le prérequis
zéro du chapitre 4.

**DEC-7 — Un tronçon est un sentier complet, pas un morceau.** Son nom, son accroche, sa carte,
ses conseils, sa trace, ses hébergements : il doit se tenir seul au catalogue. **Tient, et c'est
la règle la plus coûteuse à respecter** : découper le GR34 en douze tronçons, c'est publier douze
sentiers, pas en découper un. **Le coût du découpage est éditorial, pas technique**, et c'est là
qu'il faut regarder avant de promettre un calendrier.

### Les trois que j'ajoute, parce qu'elles manquent

**DEC-8 — On ne coupe pas sur un passage saisonnier.** Si le point de jonction dépend d'un bateau
qui ne passe pas toute l'année, la jonction est saisonnière et le circuit long devient
imprévisible. Le chapitre 5 montre pourquoi. Quiberon est à terre, donc le 17 et le 18 sont sains.

**DEC-9 — Deux tronçons consécutifs ne partagent aucune étape ; deux tronçons qui se chevauchent
sont une offre délibérée.** DEC-1 interdit le chevauchement accidentel. Mais le chevauchement
volontaire est légitime, et c'est même la forme du GR20 : intégral, nord et sud. La règle est
donc : accidentel, jamais ; volontaire, déclaré dans le groupe par les plages d'étapes mères, et
le prix s'en charge par P2 et P3.

**DEC-10 — Un groupe a une numérotation de référence, et elle ne bouge plus.** C'est la pièce qui
rend tout calculable, et c'est aussi la contrainte la plus dure du dépôt : le numéro d'étape sert
d'identité et il est stocké dans le journal, la progression, la mémoire de l'arrivée et le verrou
d'édition du programme. Si on renumérote un groupe après avoir vendu des tronçons, les ancrages
mentent et les droits déjà vendus désignent les mauvaises journées. **Un groupe publié ne se
renumérote jamais** : on ajoute à la fin, on marque un membre comme archivé, on ne redistribue
pas les numéros.

---

## 7. Ce qui reste à trancher par Christophe

Cinq points. Aucun n'est technique. Je les ai tranchés dans ce document pour qu'il y ait une
proposition sur la table, mais ils lui appartiennent.

1. **La durée d'accès.** La fiche dit une saison ; le modèle consolidé du 08/09 et sa propre
   décision du 27/09 disent sans échéance. Quelle que soit la réponse, elle est un seul paramètre
   et elle vaut pour un tronçon comme pour un global (P5).
2. **La remise sur le global.** Je dis non, avec quatre raisons et une démonstration chiffrée sur
   son propre cas. S'il la veut quand même, la forme est écrite, et elle exige un pack
   intermédiaire.
3. **Le pack intermédiaire.** Le défaut M1bis n'a jamais été arbitré : douze étapes affichent
   11,88 € et la caisse demande 19,99 €. Les globaux vont l'aggraver.
4. **Le sort du module `lib/features/packs/`.** Je dis : supprimer. Il porte le bon vocabulaire
   pour la mauvaise architecture, et garder deux systèmes garantit la confusion.
5. **Les sept règles de découpage.** Les miennes sont une reconstitution. S'il a gardé les
   originales, il faut comparer.

---

## Ce que ce document ne fait pas

Aucun code, aucune migration, aucun écran. Aucune donnée de terrain inventée : les kilométrages
du GR34 sont des ordres de grandeur, et les saisons et horaires des trois bateaux sont inconnus
de moi et doivent être relevés. Aucune pull request, et `main` n'est pas touchée.

*Athena — tâche 756 — 10/10/2026. Mesuré sur `main` à `708b82ce`.*
