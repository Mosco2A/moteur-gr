# CAMPAGNE PERSONAS V2 — SCENARIOS ET ATTENDUS

> ## ⚠ LIRE D'ABORD — GO-61 DU 22/09 : LE REPOS EST SORTI DU VERDICT (tache 545)
>
> **La regle du score de circuit a change APRES la redaction de ce dossier.** `S_circuit = C1`,
> la pire etape, et elle seule. C2, C3 et C4 sont calculees et **affichees**, jamais decisives ;
> C3, le repos, est en outre **conseillee** (combien de jours de repos poser, et ou). Et le
> **programme par defaut pose desormais ces repos conseilles**.
>
> **Ce qui reste vrai dans ce dossier :** les entrees, les personnages, les jeux d'etapes, les
> scenarios, et **toutes les grandeurs mesurees** — C1, C2, C3, monotonie, ratios et verdicts
> d'etape. Elles n'ont pas bouge d'un chiffre.
>
> **Ce qui est PERIME, et remplace dans `matrice_96.json` (voir son `meta.GO_61`) :** tout enonce
> de ce document sur le **verdict de circuit** et la **contrainte dominante**. En particulier :
> « 42 rouges en v1 → **78** en v2 » decrivait l'ancienne regle ; sous la regle en vigueur, c'est
> **25**. Les 78/42/36 restent cites comme **la mesure qui a fonde GO-61** — 36 cellules rouges par
> le seul manque de repos, dont un profil confirme a 0,68 de pire etape, vert franc — et non comme
> l'etat du produit.
>
> **RE-MESURE FAITE LE 23/09 (tache 547), voir la section 13 :** la colonne v2 decrit un programme
> **sans aucun jour de repos**. Le programme par defaut en pose maintenant, et l'appareil le
> confirme : sur le sentier de production, les 24 cellules rendent `repos=2` et le C3 de
> `avecDeuxRepos`, soit **0,7675**, avec la pire etape pour seule contrainte dominante.

> **Tache 541. PREPARATION SEULE : aucun fichier applicatif n'est touche, aucune campagne n'est
> lancee.** Artemis, 22/09/2026.
> Cadre : mandat #100251, exigence de Christophe #100329 (« test persona refaits »), autonomie
> #100331. Source unique du moteur cible : `data/apport_stepways/SPEC_FINALE_faisabilite_et_poids.md`
> section 10 (#100332). Personnages : #100295 et #100296. Grille de lecture : #100297.
>
> **Le moteur v2 a ete ecrit PENDANT cette preparation, et il a bouge deux fois sous mes pieds**
> (tache 540, branche
> `claude/feat/540-moteur-faisabilite-v2`, meme copie de travail). Les attendus ci-dessous ont donc
> ete calcules **independamment** a partir de la spec, **puis confrontes** au moteur livre :
> **les deux colonnes concordent, cellule par cellule et chiffre par chiffre.** Ce dossier fige les
> entrees, verrouille les attendus, et nomme ce qui bloque.

---

## 1. CE QUE CE DOSSIER CONTIENT

- **`matrice_96.json`** — les 96 combinaisons, entrees completes, colonne AVANT (moteur reel
  d'aujourd'hui) et colonne APRES (formule de la spec), plus la liste des bascules une par une.
- **`../../test/features/feasibility/campagne_v2_matrice_test.dart`** — le test qui **verrouille les
  deux colonnes sur le moteur reel**. **29 verts au 22/09.**
- Ce document — les scenarios, les attendus, et les blocages a lever avant de lancer.

**Pourquoi les deux colonnes sont testees et pas seulement ecrites.** Une bascule est un couple :
le verdict d'avant et le verdict d'apres. Un chiffre recopie a la main est un chiffre que personne
n'a verifie. Sont donc confrontes un par un a `FeasibilityFormula` :

- **Colonne AVANT** — bareme `FeasibilityScale.v1` (100 m de D+ par km, plafonds 21/29/39/45),
  conserve dans le moteur **exactement pour cet usage**. 96 niveaux derives, 96 plafonds,
  **1 032 scores d'etape**, 96 verdicts de circuit (la couleur de la pire etape, qui etait le
  verdict global de la V1).
- **Colonne APRES** — bareme `FeasibilityScale.v2`, avec le **plancher demontre** de chaque
  personnage, l'**altitude** de chaque jeu d'etapes et la **saison du depart** de chaque personnage.
  1 032 scores d'etape, et pour chaque cellule **C1, C2, C3, la contrainte dominante et le verdict
  de circuit**.

**Resultat : concordance totale.** La matrice a ete calculee a partir de la seule spec, avant que le
moteur v2 ne soit disponible ; elle a ensuite ete confrontee au moteur livre. **Aucun ecart.** Deux
lectures independantes de la meme spec tombent sur les memes chiffres — c'est la meilleure garantie
qu'on puisse offrir a la campagne, et accessoirement une validation croisee de la tache 540.

**Controle de coherence reussi, en plus.** La spec publie une valeur calculable a la main (#9-e,
« sur l'etape 1 du seed, un intermediaire passe de 0,810 vert a 0,911 orange »). La matrice rend
**0,8103 vert -> 0,9113 orange** sur la cellule P2-J1-R3.

**Etat de `flutter analyze lib test integration_test` au moment du rendu : 19 issues.** Les **4** de
la baseline #100202, plus **15 nouvelles qui appartiennent toutes a la tache 540 en cours** :
d'anciens tests appellent l'API V1 retiree (`dailyCeilingFor`, `StageEffort.effortKm`,
`dailyCeilingKmEffort`) et trois widgets d'ecran ne sont pas encore ecrits. **Les fichiers de cette
preparation en portent zero**, verifie. Meme cause pour les fichiers qui ne se chargent plus dans
`flutter test` : ce sont les tests de l'ancienne API, a reprendre par la tache 540.

---

## 2. QUATRE POINTS — DEUX SONT TRANCHES, DEUX RESTENT OUVERTS

> **Etat au 22/09 en fin de journee.** **B2 est tranche** (`S_circuit = max(C1 ; C3)`, C2 en
> affichage, exigence #10-b ramenee a deux contraintes dominantes). **B3 est cable et la colonne C3
> re-mesuree** — l'artefact est leve, et le couple de chiffres du repos par defaut est mesure.
> **B1 est traite par la tache 543** : harnais recupere, prouve capable de dire non, S5 et S6
> reecrits. **B4 est traite** par le banc des niveaux et un scenario d'hiver dedie.

### B1 — LE HARNAIS — **TRAITE PAR LA TACHE 543**

- **Ce qui manquait.** `persona_harness.dart` etait la version **d'AVANT la reparation N2** : aucun
  `exige`, aucun `verdictPersona`, aucune detection d'ecran systeme. **Celle qui ne peut pas
  echouer** (#100283, mission 1).
- **Recupere** du stash `04437e8` et **verse** : la couche d'exigences, la detection d'ecrans
  systeme et les versions N2 de S1 a S4 sont de nouveau dans le depot.
- **DEUX DEFAUTS TROUVES DANS LE HARNAIS LUI-MEME, et corriges.**
  1. **Les compteurs d'exigences sont GLOBAUX et n'etaient jamais remis a zero.** Deux scenarios
     joues dans le meme processus se les partagent : le second heritait des echecs du premier, et
     surtout **le garde anti-harnais-aveugle se desarmait tout seul** — les 40 exigences du scenario
     precedent suffisaient a franchir le minimum du suivant, qui pouvait donc ne rien verifier et
     passer vert. Le garde cense empecher le retour du defaut d'origine etait neutralise par le
     defaut d'origine. Corrige par `reinitialiserExigences()`, appele en tete de chaque scenario.
  2. **La detection d'ecran systeme produisait un faux positif garanti sur tout scenario de
     saisie.** Elle signalait toute sortie de `resumed`, or `inactive` est aussi emis a l'ouverture
     du clavier. Corrige par `ecransSystemeBloquants()`, qui ne retient que `paused` et `hidden` —
     les seuls qui prouvent qu'une fenetre a pris le premier plan. Les `inactive` restent
     journalises.
- **LE HARNAIS SAIT DIRE NON, ET C'EST PROUVE.**
  `test/integration_harness/persona_harness_sait_dire_non_test.dart`, **7 verts**, tourne en
  `flutter test` donc a chaque fois et pas seulement les jours de campagne. Il verifie qu'une
  exigence fausse fait rougir la cloture **et est nommee** dans l'echec ; qu'une exigence tenue ne
  fait rougir personne (sans quoi un harnais qui echouerait toujours passerait) ; **qu'un scenario
  qui ne verifie rien est ROUGE** ; que le plancher d'exigences mord ; qu'**une seule exigence
  fausse noyee dans vingt vraies** suffit a faire rougir ; et que la remise a zero re-arme bien le
  garde.
- **S5 et S6 sont reecrits** (les originaux etaient perdus, voir plus bas).
- **Reste a faire** : rejouer S1 a S4 contre le produit corrige. Le stash a ete pose **avant** le
  correctif N2 (`4d4efc1`), donc leurs scenarios attendent encore un verdict qui tombe des la
  morphologie.

### B2 — C2 NE PEUT JAMAIS MORDRE — **TRANCHE LE 22/09, CORRECTION ACTEE**

- **La correction.** **`S_circuit = max(C1 ; C3)`.** C2 sort du maximum et passe en **affichage**,
  meme statut que C4. **L'exigence #10-b est corrigee en consequence : DEUX contraintes dominantes,
  pas trois.** La matrice, le test et la section 4 de ce document appliquent la correction.
- **Le fait qui l'a motivee.** `C2 = (somme des E) / (nb de jours de marche x C_jour)` est la
  **moyenne** des charges ; `C1 = max(E) / C_jour` est le **maximum** de la meme serie, normalise par
  le meme plafond. Une moyenne n'est jamais superieure a un maximum : **C2 <= C1 par construction**,
  egalite seulement si toutes les etapes sont egales. La phrase #2-o (« un circuit dont la moyenne
  depasse le plafond est intenable meme si aucune etape ne depasse ») decrivait donc un **cas
  impossible**. Le code reproduisait la spec a la lettre : le trou etait dans la spec.
- **Ce que le test verifie desormais, et pourquoi c'est mieux.** La preuve de dominance (« C2 n'a
  mordu aucune fois sur mes 96 cellules ») est remplacee par un **TEST D'INVARIANT** : `C2 <= C1` sur
  toutes les combinaisons, sur la matrice **et** sur le moteur, tous jeux x tous niveaux, avec et
  sans jours de repos. Un constat ne vaut que pour son echantillon ; **l'invariant dit que c'est
  impossible**, et il rougira le jour ou quelqu'un changera le normalisateur de C2 sans revoir la
  redondance. C'est la protection qui a de la valeur, pas la mesure.
- **La piste de la contrainte de Foster (charge x monotonie) est fermee.** Normalisee par nos deux
  seuils elle vaut exactement `C2 x C3`. **Une precision que je dois apporter, parce que l'argument
  avance pour la fermer n'est pas exact.** Un produit de deux positifs ne depasse leur maximum que si
  **les deux depassent 1** — et 1 n'est pas « deja rouge », il tombe dans la bande **orange**
  (0,85 a 1,10). Surtout, cette contrainte **peut** changer une couleur, **dans les deux sens**.
  Contre-exemples arithmetiques : `C2 = 1,05` et `C3 = 1,05` donnent `max = 1,05` **orange** mais
  `produit = 1,1025` **rouge** ; `C2 = 0,90` et `C3 = 1,20` donnent `max = 1,20` **rouge** mais
  `produit = 1,08` **orange**. **La conclusion tient quand meme, et elle en sort renforcee** : une
  contrainte qui peut aussi bien durcir qu'**alleger** par rapport au maximum n'a rien a faire dans
  un `max()`. Fermee pour cette raison-la, pas pour son inertie.

### B3 — C3 NE DEPEND PAS DU RANDONNEUR — **CABLAGE LIVRE, ARTEFACT LEVE, COLONNE RE-MESUREE**

> **RESOLU.** Le cablage des jours de repos est livre (commit `5154813`) : un provider lit le vrai
> programme du randonneur et traduit chaque jour de repos en index d'etape, y compris pour les jours
> qui regroupent deux etapes. **La colonne C3 de la matrice a ete re-mesuree** : elle n'est plus un
> artefact, elle decrit desormais **l'etat PAR DEFAUT du produit**, celui ou aucun jour de repos
> n'est pose dans le programme — ce que l'application rend a l'ouverture. Le contrefactuel a deux
> jours de repos vit a cote, dans `cellules[*].v2.avecDeuxRepos`, et la table complete de 0 a 12
> repos dans `jeuxEtapes[*].c3ParNombreDeRepos`. **Les deux sont verifies sur le moteur reel.**

**LE COUPLE DE CHIFFRES DEMANDE, MESURE SUR LE MOTEUR ET NON SUR LA MATRICE.** C'est lui qui permet
d'arbitrer s'il faut proposer les jours de repos par defaut.

- **78 cellules sur 96 sont ROUGES** quand aucun jour de repos n'est pose. C'est l'etat par defaut.
- **42 cellules sur 96 restent ROUGES** avec **deux** jours de repos poses.
- **Donc 36 cellules — pres d'une rouge sur deux — sont rouges UNIQUEMENT parce qu'aucun repos n'est
  pose**, pas parce que le randonneur ne tient pas le sentier.
- Et les **42** qui resistent sont exactement le nombre de cellules deja rouges **en v1** : ce qui
  reste apres les repos, c'est la severite reelle du sentier, pas un effet de la monotonie.

**Le detail par jeu d'etapes, parce que la moyenne cache l'essentiel** :

- **J1, Mare a Mare Centre, le sentier de production — 24 rouges sans repos, 6 avec deux repos.**
  **18 des 24 cellules du sentier que Christophe ouvrira sont rouges faute d'un programme.** Les 6
  qui restent sont Lea et Thomas aux rangs 0 a 2, rouges par leur **pire etape** — un vrai verdict.
- **J2, 5 etapes — 24 rouges sans repos, 6 avec deux repos.** Meme profil.
- **J3, sentier d'UNE etape — 6 rouges, et 6 avec repos : inchange.** C'est normal et c'est la
  preuve que le cas limite tient : sur une seule etape la monotonie n'est **pas calculable**, aucun
  repos ne peut y etre insere, et le verdict vient donc de C1 seul. Le repos n'y change rien parce
  qu'il n'y a rien a reposer.
- **J4, 30 etapes — 24 rouges sans repos, 24 avec deux repos : deux repos ne suffisent pas.** Avec
  la fenetre glissante, il en faut **5** pour l'orange et **12** pour le vert, et **1 a 3 repos ne
  changent strictement rien** parce que la pire fenetre de sept jours n'en contient toujours aucun.

**CE QUE J'EN DIS, ET C'EST UN ARBITRAGE, PAS UN BUG.** Le comportement est conforme a la spec, et
il correspond meme a l'intention sur un trek long. Mais un randonneur qui ouvre l'application voit
un sentier **rouge** alors qu'**aucune de ses etapes ne depasse ses capacites** — c'est le cas de
l'expert, dont la pire etape est a 0,54, vert franc. **Deux lectures, et le chiffre de 36 permet de
choisir** : soit le programme par defaut pose des repos et le rouge redevient un signal rare, soit
il n'en pose pas et l'ecran doit dire, en toutes lettres, que **c'est l'absence de repos qui
decide** — sinon l'utilisateur lira un jugement sur lui-meme la ou il y a un jugement sur son
planning.

### B3-bis — CE QUE LE DEFAUT ETAIT, POUR MEMOIRE ET POUR LA NON-REGRESSION

- **Le fait, demontre.** `monotonie = moyenne / ecart-type` des **memes** charges journalieres.
  `C_jour` est un facteur commun au numerateur et au denominateur : il se simplifie exactement.
  **La monotonie de Foster, donc C3, ne contient aucune trace du randonneur** — c'est une propriete
  du seul enchainement des etapes. La spec le dit elle-meme au sujet de la masse (#3-f, « immunisee
  par construction ») ; la meme demonstration vaut pour la **capacite entiere**.
- **Mesure** : sur chacun des quatre jeux d'etapes, les 24 cellules rendent **une seule et meme
  valeur de C3**. Verifie par test (`TROU 2`).
- **La consequence chiffree, et c'est celle que Christophe verra en dix secondes.** Le moteur ne
  recoit aujourd'hui que la **liste des etapes** (`stageEffortsProvider` -> `FeasibilityFormula`) :
  une etape par jour, **aucun jour de repos**. Sur le sentier de production :
  - Mare a Mare Centre, 7 etapes sans repos : **monotonie 4,04**, donc **C3 = 2,02**, donc **ROUGE**.
  - Ce 2,02 etant un plancher pour `S_circuit = max(C1 ; C2 ; C3)`, **le verdict de circuit est ROUGE
    pour les 24 cellules du jeu J1, du debutant a l'expert**.
  - Banc des niveaux, meme sentier : l'**expert** a une pire etape a **C1 = 0,54 (vert franc)** et
    recoit quand meme un **circuit ROUGE**. Le debutant aussi. **Le verdict de circuit ne discrimine
    plus rien.**
  - Sur les 96 cellules : **42 circuits rouges en v1 -> 78 en v2**.
- **La cause, corrigee depuis.** `FeasibilityFormula.evaluate` a toujours su recevoir des jours de
  repos, mais `trek_feasibility_provider.dart` ne les passait pas. **C'est fait** :
  `restAfterStageIndex: restDays`, alimente par `restDaysAfterStageProvider`, qui traduit les
  `DayPlan` du programme en indices d'etapes. **A prouver a l'ecran pendant la campagne**, pas
  seulement en lecture de code.
- **Contre-preuve faite sur le moteur reel, et c'est le point a retenir.** Sur J1 avec deux jours de
  repos (`restAfterStageIndex: {1, 4}`) : la monotonie tombe de **4,04 a 1,53**, donc C3 de **2,02 a
  0,77**, sous le seuil du vert. **Et la discrimination revient** : l'expert est **VERT**, le
  debutant reste **ROUGE** par sa pire etape (C1 = 1,40) — la contrainte qui decide redevient
  dependante du randonneur, ce que C3 seule ne pouvait pas faire.
- **Chiffres operationnels** — nombre minimal de jours de repos pour ramener C3 sous le seuil,
  par jeu d'etapes (table complete dans le JSON) :
  - J1, 7 etapes : **1 repos** pour passer sous l'orange, **2 repos** pour le vert.
  - J2, 5 etapes : **1 repos** pour l'orange, **2** pour le vert.
  - J4, 30 etapes : **5 repos** pour l'orange, **12** pour le vert. **Et attention** : avec la
    fenetre glissante, **1 a 3 jours de repos ne changent strictement rien** (C3 reste a 2,52), parce
    que la **pire** fenetre de 7 jours n'en contient toujours aucun. C'est contre-intuitif et l'ecran
    devra savoir l'expliquer.
  - J3, 1 etape : **sans objet** (voir cas limite n°4).
  Ces chiffres confirment la lecture de la spec (#2-t, « un jour de repos par semaine ne suffit pas,
  il en faut deux ») et la rendent operationnelle.
- **ECART A CORRIGER OU A DECLARER, trouve en construisant la table.** `PlanningCalculator` pose un
  jour de repos **AVANT** une etape (`_computeRestPositions`) ; `FeasibilityFormula.dailyLoads` le
  pose **APRES**, et **ignore** un repos demande apres la derniere etape. Les deux ne produisent donc
  pas la meme serie de charges. Sur un sentier d'**une** etape elles ne disent meme pas la meme
  chose : cote planning la serie devient `[0, E]` et la monotonie vaut 1 ; cote moteur elle reste
  `[E]` et la monotonie est **non applicable**. **C'est la semantique du moteur qui fait foi**,
  puisque c'est elle qui rend le verdict — mais le cablage doit **traduire**, pas recopier. Verifie
  par le test `ECART PLANIFICATEUR / MOTEUR`.

### B4 — DEUX TROUS DE COUVERTURE QUE LA MATRICE 6x4x4 NE PEUT PAS COMBLER (non bloquant, traite)

- **Le niveau EXPERT n'est jamais atteint.** Les six personnages de Christophe derivent au mieux en
  `confirme` (Marc et Sabine, au rang de forme 3). Detail par personnage :
  - Marc — R0 debutant, R1 intermediaire, R2 intermediaire, R3 confirme.
  - Lea — debutante aux rangs 0 a 2, intermediaire au rang 3.
  - Jean-Pierre — debutant aux rangs 0 a 2, intermediaire au rang 3.
  - Ines — debutante aux rangs 0 a 2, intermediaire au rang 3.
  - Thomas — debutant aux rangs 0 a 2, intermediaire au rang 3.
  - Sabine — R0 debutante, R1 et R2 intermediaire, R3 confirmee.
  **#10-b exige « les quatre niveaux avec les nouveaux plafonds ».** La matrice 6x4x4 ne peut pas
  le fournir. **Traitement retenu** : un **banc des quatre niveaux**, 4 cellules **declarees HORS
  des 96** (elles ne remplacent aucune combinaison), plancher demontre neutralise, meme sentier J1.
  Present dans `matrice_96.json` sous `annexeNiveaux`, verrouille par le meme test.
- **Aucun personnage ne part en hiver.** Les six dates de depart tombent au printemps (Jean-Pierre
  4 mai, Ines 12 avril), en ete (Marc 8 juin, Thomas 5 juillet) ou en automne (Lea 5 septembre,
  Sabine 20 septembre). **Le « verdict declare non valide » de #1-e ne peut donc pas sortir des 96** :
  il lui faut un scenario dedie en famille 3 (voir F3-2).

**OBSERVATION DE PRODUIT, a verser a la campagne sans attendre.** Jean-Pierre — 68 ans, quarante ans
de sentiers, tour du Mont-Blanc en dix jours — est classe **debutant** aux rangs de forme 0, 1 et 2.
Mecanique : `deriveLevel` prend le plus prudent de ses deux reperes (D+ confirme, distance
intermediaire) puis retire un cran pour l'age au-dela de 60 ans. Son but declare est que **sa**
contrainte soit prise en compte ; s'entendre appeler debutant apres quarante ans de marche est
exactement ce qu'il releve. Ligne L1 et L4 de la grille #100297. Ce n'est pas un defaut du moteur v2
— il existe **deja** en v1 — mais la campagne le fera remonter, et il vaut mieux l'avoir nomme avant.

---

## 3. LA MATRICE DES 96 — DEFINITION EXACTE

**96 = 6 personnages x 4 jeux d'etapes x 4 rangs de forme.** Meme forme que la campagne N2
(#100283). Identifiant d'une cellule : `P<n>-J<n>-R<rang>`, par exemple `P2-J1-R3`.

### 3.1 Les quatre jeux d'etapes

- **J1 — Mare a Mare Centre, seed de l'application.** 7 etapes, `assets/data/mare_a_mare_centre/stages.json`.
  44,6 m de D+ par km. Altitude maximale **1 050 m** relevee sur `track.gpx` (53 points), donc
  **`k_altitude = 1,00`, neutre et calcule** (pas absent). C'est le sentier de production : **c'est
  lui qui fait les chiffres que Christophe verra sur son telephone.**
- **J2 — Sentier de demonstration Auvergne, seed de l'application.** 5 etapes,
  `assets/data/test_stages.json`. 33,6 m/km. Altitude maximale **1 730 m** relevee sur
  `assets/gpx/test_trail.gpx`, donc **`k_altitude = 0,977`, ACTIF** — sur une donnee reellement
  presente dans l'application, pas sur un jeu invente.
- **J3 — Sentier d'UNE SEULE etape.** L'etape 1 de J1, seule. Jeu **synthetique declare**. C'est le
  cas limite le plus important de #10-e.
- **J4 — Sentier de TRENTE etapes.** Chainage J1+J2 repete, tronque a exactement 30. Jeu
  **synthetique declare**. 41,2 m/km. Il exerce la fenetre glissante de 7 jours et la retenue de la
  pire fenetre.

**Le sentier « GR Pyrenees » du catalogue est volontairement hors matrice, et c'est un cas de test
a lui seul** : sa configuration declare `assets/gpx/gr_pyrenees.gpx`, **fichier qui n'existe pas**.
C'est exactement la situation prevue par #2-h : altitude **absente -> `k_altitude = 1,00` ET on le
dit**. Voir F3-4.

### 3.2 Les six personnages — donnees de matrice

Les prompts (#100295, #100296) sont des **recits**. La matrice a besoin de **nombres**. Les valeurs
ci-dessous sont la lecture **litterale** des prompts ; la ou le recit ne chiffre pas, la deduction
est **ecrite et sourcee** dans `matrice_96.json` (champ `randos[].source`). **Ces nombres ne sont
jamais souffles au personnage** : ils servent a calculer l'attendu, le personnage saisit ce qu'il
veut et l'ecart se lit.

- **P1 Marc** — 28 ans, 178 cm, 72 kg, IMC 22,7. Depart 8 juin, **ete -> `k_chaleur` 0,93 ACTIF**.
  Vecu : GR20 en 12 jours. 15,0 km/jour et 833 m/jour. **Plancher demontre `E_max` = 34,84**.
- **P2 Lea** — 34 ans, 165 cm, 58 kg, IMC 21,3. Depart 5 septembre, **automne -> 1,00**.
  Vecu : sorties du dimanche. 9,0 km/jour, 200 m/jour. **`E_max` = 13,76**.
- **P3 Jean-Pierre** — 68 ans, 176 cm, 82 kg, IMC 26,5. Depart 4 mai, **printemps -> 1,00**.
  Vecu : tour du Mont-Blanc en 10 jours. 17,0 km/jour, 1 000 m/jour. **`E_max` = 40,81**.
- **P4 Ines** — 41 ans, 168 cm, 63 kg, IMC 22,3. Depart 12 avril, **printemps -> 1,00**.
  Vecu : GR20 nord en 6 jours. 14,2 km/jour, 1 000 m/jour. **`E_max` = 37,98**.
- **P5 Thomas** — 22 ans, 183 cm, 75 kg, IMC 22,4. Depart 5 juillet, **ete -> 0,93 ACTIF**.
  Vecu : une semaine sur le GR34. 20,0 km/jour, 200 m/jour. **`E_max` = 24,76**.
- **P6 Sabine** — 47 ans, 172 cm, 68 kg, IMC 23,0. Depart 20 septembre, **automne -> 1,00**.
  Vecu : une semaine sur le tour du Mont-Blanc. 18,0 km/jour, 900 m/jour. **`E_max` = 39,43**.

### 3.3 Les quatre rangs de forme

Rangs 0 a 3 (`WalkTestLevel.rank` : faible, moyen, bon, excellent). Le rang **0** fait perdre un
cran de niveau, le rang **3** en fait gagner un ; les rangs 1 et 2 sont neutres. Le rang 1 est aussi
le **rang de depannage** applique quand le test de marche n'a pas ete passe.

### 3.4 La couverture obtenue, mesuree et non supposee

- **Plancher demontre (#2-g)** : **actif sur 44 cellules, inactif sur 52**. Les deux cas sont donc
  couverts. C'est le plancher qui produit la totalite des allegements : Ines, Jean-Pierre et Sabine
  ont demontre plus que le plafond de leur niveau, leur `C_jour` monte, leurs verdicts s'allegent.
- **`k_altitude`** : neutre sur J1 et J3 (1,000, calcule), **actif sur J2 et J4** (0,977).
- **`k_chaleur`** : **actif** sur Marc et Thomas (0,93), neutre sur les quatre autres (1,00).
- **`C3` non applicable** : **24 cellules** (tout le jeu J3).
- **Les quatre niveaux** : voir B4, hors des 96, dans le banc annexe.
- **`C2` dominante** : **jamais**, voir B2.

---

## 4. FAMILLE 1 — CAS PASSANTS (#10-b)

**But** : chaque combinaison produit un verdict d'etape **et** un verdict de circuit, et le
facteur dominant est **nomme a l'ecran**.

- **F1-1 — La matrice des 96, passee au moteur de production.** Attendu : pour chaque cellule, les
  verdicts d'etape et le verdict de circuit **egalent la colonne APRES de `matrice_96.json`**. Tout
  ecart est un defaut, du moteur ou de la matrice, et se tranche en relisant la spec.
- **F1-2 — Le facteur dominant est nomme.** Attendu : l'ecran dit laquelle des contraintes decide
  (pire etape, charge moyenne, repos) **et** laquelle des causes domine sur l'etape (distance,
  denivele, altitude, chaleur) — #2-l. **Cote moteur c'est fait** : `LimitingFactor` porte
  desormais `altitude` et `heat`, et chaque `StageVerdict` decompose son score en parts additives
  (`distanceShare`, `elevationShare`, `altitudeShare`, `heatShare`). **Ce qui reste a prouver est a
  l'ECRAN** : le nom du facteur doit etre affiche, dans les 5 langues, et correspondre a la part
  reellement dominante.
- **F1-3 — Le plancher demontre se voit.** Attendu : sur Ines rang 0 (debutante, `E_max` 37,98 contre
  un plafond de niveau de 25,14), l'etape 1 passe de **ROUGE a ORANGE**. L'ecran doit dire **pourquoi**
  le plafond applique n'est pas celui du niveau : « on ne dit jamais a quelqu'un qu'il ne peut pas
  faire ce qu'il a demontre faire » (#2-g). Un allegement muet est un defaut.
- **F1-4 — `k_altitude` actif.** Sur J2, attendu `k_altitude = 0,977` et **la mention a l'ecran**.
- **F1-5 — `k_chaleur` actif.** Sur Marc et Thomas, attendu `0,93` et la mention. Attendu **en
  creux** pour Lea, Jean-Pierre, Ines et Sabine : **aucun coefficient de saison**, et l'ecran dit
  que le printemps et l'automne sont **neutres faute de source** (#2-i). Une dimension neutre faute
  de **donnee** et une dimension neutre faute de **source** ne se disent pas pareil (#8-b).
- **F1-6 — Les DEUX contraintes, tour a tour** (exigence #10-b corrigee le 22/09). `S_circuit =
  max(C1 ; C3)` : il faut donc des cellules ou **C1** decide et des cellules ou **C3** decide, et
  l'ecran doit **nommer laquelle**. C2 et C4 sont **affichees, jamais decisives** — et cela aussi se
  verifie : faire varier C2 sans toucher C1 ni C3 ne doit **pas** changer la couleur.
- **F1-7 — Les six buts de la grille #100297, ligne L1.** Les personnages jouent le produit reel,
  pas la matrice. Un seul **NON** en L1 = campagne rouge, quel que soit le reste.

---

## 5. FAMILLE 2 — CAS NON PASSANTS, ZERO VERDICT ABSURDE (#10-c)

**Critere, mot pour mot** : aucun verdict absurde, aucun plantage, **et tout repli est DIT**.
Rappel de la grille, L9(e) : **un refus propre et explique est un comportement correct**. C'est
l'acceptation silencieuse, le refus muet, le plantage ou la valeur aberrante affichee qui sont
des defauts. Ce scenario est a **reecrire** : l'ancien S5 est perdu (B1).

Aux nouvelles bornes (`hiker_input_bounds.dart`, deja livre en tache 539 — age 18-120, taille
60-255 cm, poids 25-200 kg) :

- **F2-1 — 200 kg** (borne haute acceptee). Attendu : **accepte**, pas de refus.
- **F2-2 — 25 kg** (borne basse acceptee). Attendu : accepte ; chez un adulte de taille normale le
  `min()` du sac rend le poids reel, **rien ne change**.
- **F2-3 — 60 cm** (borne basse acceptee). Attendu : accepte, **et** repli de reference (cas limite 2).
- **F2-4 — 255 cm** (borne haute acceptee). Attendu : accepte, aucune absurdite.
- **F2-5 — 18 ans** et **F2-6 — 120 ans** (bornes acceptees). Attendu : acceptes.
- **F2-7 — Croisements** : 60 cm avec 200 kg ; 255 cm avec 25 kg. Attendu : acceptes, replis dits,
  **aucun verdict construit sur une absurdite**.
- **F2-8 — Hors bornes** : 17 ans, 121 ans, 59 cm, 256 cm, 24 kg, 201 kg, valeurs negatives.
  Attendu : **refus explicite citant la borne**, et **l'ecran n'est pas quitte**.
- **F2-9 — Non-nombres** : `Infinity`, `NaN`, `1e9`, lettres, champ vide, nombre a rallonge.
  Attendu : refus propre. `isValidBodyWeightKg` teste deja `isFinite` — a reprouver a l'ecran, pas
  seulement en unitaire.
- **F2-10 — Code pays inexistant** (`ZZ`). Attendu : refuse (`isValidIsoCountryCode`).
- **F2-11 — La meme donnee porte la meme regle partout.** Le poids saisi sur la fiche d'info et le
  poids saisi sur le bandeau du sac doivent rendre **le meme message de borne**. C'etait le finding
  B1 du cycle 4, corrige ; c'est une **non-regression** a reprouver.
- **F2-12 — Le pseudo de 30 caracteres.** `MINEUR-1` de la campagne N2 : debordement de 126 pixels
  sur l'ecran Profil, reproduit 4 fois sur 4, capture `S5_Limites_52_pseudo_long.png`. Le correctif
  a ete livre (`a5618b7`). **Non-regression a reprouver.**

---

## 6. FAMILLE 3 — CAS METIERS A REPONSES MULTIPLES (#10-d)

- **F3-1 — Le circuit plus severe que toutes ses etapes (#2-s, ARB-004), avec son explication.**
  Attendu : quand `S_circuit` est plus severe que la pire etape, **l'ecran explique pourquoi**,
  sinon l'utilisateur croit a un bug. **Mesure de la matrice : 53 cellules sur 96 sont dans ce cas**,
  et toutes le sont **par C3**. **A rejouer apres l'arbitrage B3** : en l'etat, l'explication devrait
  s'afficher pour 24 cellules sur 24 du sentier de production, expert compris.
- **F3-2 — L'hiver declare non valide (#1-e).** **Aucun des six personnages ne part en hiver** :
  scenario dedie obligatoire. Reprendre un personnage et **deplacer sa seule date de depart en
  decembre, janvier ou fevrier** — `Season.fromDate` rend `winter`. Attendu : **aucun coefficient**,
  le verdict est **declare non valide**, et l'ecran dit pourquoi (cotations valables « par bon temps,
  terrain sec et enneigement adapte »). Un verdict tricolore affiche en hiver est un defaut.
- **F3-3 — Le decoupage choisi persiste.** Non-regression du correctif D2 (`4d4efc1`, preuve
  `preuve_n2_faisabilite_test.dart`) : choisir un decoupage laisse une trace **ailleurs** que la ou
  on a agi, et **apres redemarrage**. Ligne L5 de la grille.
- **F3-4 — Altitude absente, et on le dit.** Ouvrir le sentier **GR Pyrenees**, dont le GPX declare
  n'existe pas. Attendu : `k_altitude = 1,00` **et la mention explicite que l'altitude n'a pas pu
  etre prise en compte** (#2-h). Une neutralite silencieuse est un defaut : elle se confondrait avec
  un sentier reellement bas.
- **F3-5 — La mention hors-perimetre coupee en deux (#8-a).** Attendu : la moitie « saison »
  **disparait** (la saison entre desormais dans le calcul) ; la moitie « sac » devient
  **permanente**, avec la mesure qui la fonde (de 0 a 45 kg, le verdict ne bouge pas).
  Contre-preuve obligatoire : **faire varier le poids du sac et constater que le verdict ne bouge
  pas**, au lieu de se contenter de lire la phrase.
- **F3-6 — Le verdict attend d'avoir tout.** Non-regression du correctif D1 : saisir **la
  morphologie seule** ne doit produire **aucun verdict**, et l'ecran doit **nommer ce qui manque**.
  Ligne L6 de la grille — c'est le defaut que Christophe a trouve en deux minutes.
- **F3-7 — La morphologie ne pese pas, et on l'assume (#3-h).** Attendu : **le meme personnage a
  65 kg et a 95 kg obtient des verdicts identiques au chiffre pres**. A prouver a l'ecran sur deux
  passages. Et l'ecran doit dire que le verdict repose sur **ce qui a ete fait** et sur **la capacite
  mesuree**, pas sur la morphologie.
- **F3-8 — Le dispositif poids, les deux sorties (#4-b, #4-c).** Sac conseille =
  `0,20 x min(poids reel ; 25 x taille_m^2)`. A 1,78 m : **120 kg passe de 24,0 a 15,8 kg** ;
  **70 kg reste a 14,0, strictement inchange**. Attendu supplementaire, **a annoncer avant que
  Christophe le voie** : un sac de 20 kg porte par le randonneur de 120 kg **saute de 16,7 % orange
  a 25,2 % rouge fonce, deux crans d'un coup** (#4-i).
- **F3-9 — Le libelle du pourcentage dit de quoi il est le pourcentage (#7-e).** Changer le
  denominateur sans changer le libelle ferait mentir l'ecran. Verifier aussi que
  `checklist_recommendation_banner.dart` suit **le meme denominateur** (#7-f), sinon la meme page se
  contredit.
- **F3-10 — Le vocabulaire proscrit (#7-d).** Balayage de **tous** les ecrans touches, dans les
  **5 langues** : aucun de `surpoids`, `obesite`, `exces`, `IMC`, `corpulence`, `nanisme`,
  `pathologie`. Verification mecanique, pas a l'oeil.
- **F3-11 — Les 5 langues.** Chaque texte nouveau existe en fr, en, de, es, it. Sabine ne lit que
  l'allemand : **toute phrase restee en francais est un point de sa ligne « ce qu'elle n'a pas
  compris »**, et si elle la bloque, c'est « ce qui l'a arretee ».
- **F3-12 — LE CONSTAT DE DUREE CUMULEE : factuel, jamais un verdict.** Le moteur enonce « ce trek
  dure N jours de marche, ta plus longue sortie enchainee est de M jours »
  (`walkingDays`, `longestConsecutiveDaysDone`, `hasDurationStatement`). **Pourquoi c'est un constat
  et pas une couleur** : le modele ne capte la duree cumulee nulle part — C3 mesure une
  **regularite**, pas une **longueur**, et sur des etapes regulieres sans repos elle rend le meme
  chiffre pour trois jours et pour dix-sept. Aucun seuil publie n'existe (#M06), on ne l'invente pas.
  **VERIFIE AU NIVEAU DU MOTEUR, deja vert** : faire varier M de 0 a 40 ne change **aucune** sortie
  decisionnelle — ni le verdict global, ni le score de circuit, ni la contrainte dominante, ni le
  facteur limitant, ni la capacite du jour, ni les semaines d'entrainement, ni les jours suggeres,
  ni un seul verdict d'etape. Et M = 0 ne produit **pas** un zero parlant : le constat n'est
  simplement **pas enonce**.
  **CE QUI RESTE A PROUVER A L'ECRAN, et c'est la que ca se joue** : (a) la phrase est affichee telle
  quelle, dans les 5 langues ; (b) elle **ne porte aucune couleur, aucune icone d'alerte, aucun verbe
  de jugement** — pas de « insuffisant », pas de « tu n'es pas pret », pas de rouge ; (c) elle
  n'apparait pas **a cote** d'un feu tricolore d'une facon qui la fasse lire comme un verdict.
  **Lea est le bon personnage pour ce point** : elle veut savoir sur quoi repose ce qu'on lui dit, et
  un chiffre pose sans statut l'inquietera plus qu'il ne l'informera.

---

## 7. LES SIX CAS LIMITES, CHACUN AVEC SON ATTENDU (#10-e)

1. **200 kg** — verdict de faisabilite **identique** a 70 kg toutes choses egales (aucun terme de
   masse, #3-f) ; sac conseille **sature a 15,8 kg** a 1,78 m ; **IMC > 35 donc la normalisation du
   test de marche est hors domaine** -> repli sur l'echelle de distance absolue **deja codee**
   (`walk_test_norms.dart`, `levelFor`, seuils 400/500/600), **et l'ecran le dit**, et **pas de
   +1 cran non merite**. Cas de reference de la spec : 130 cm, 200 kg, 50 ans -> prediction 72,1 m,
   marche a 300 m -> rapport 4,16 -> « excellent » usurpe. **Le garde-fou existant ne rattrape que
   les predictions negatives** (`predicted <= 0`) : celle-ci est **positive et minuscule**, elle
   passe.
2. **60 cm** — **aucune reference calculee** (#5-h, seuil de 147 cm), sac conseille sur le **poids
   reel**, **message de repli affiche**, **aucune charge excedentaire**. Le message ne nomme **aucune
   pathologie** : il dit ce que l'application ne sait pas faire, pas ce que la personne est.
3. **120 ans** — age **clampe a 80** pour Enright (comportement existant, `walk_test_norms.dart`
   lignes 42-43) ; **-2 crans** de niveau (regle des 75 ans et plus) ; **aucun plantage** ; et le
   clamp est **declare**, pas subi.
4. **Sentier d'UNE etape (jeu J3)** — **c'est le test le plus important.** L'ecart-type d'une seule
   charge vaut zero, la monotonie **diverge**. Attendu : **la contrainte repos est DECLAREE non
   applicable, pas calculee**, elle **ne participe pas** au `max()`, et l'ecran le dit. Ce qu'il ne
   faut surtout pas voir : un `NaN`, un `Infinity`, un 0 affiche comme un resultat, un rouge
   silencieux, ou une reponse du type « un jour de repos suffirait ». Verrouille par le test
   (`CAS LIMITE #10-e`, 24 cellules, `C3` nul et non dominante, `reposMinimum` = `sans-objet`).
5. **Sentier de TRENTE etapes (jeu J4)** — monotonie calculee par **fenetre glissante de 7 jours**,
   **la pire fenetre retenue**, et **la fenetre retenue est nommee** (« jours 12-18 »). Le
   comportement en **debut** et en **fin** de sentier, la ou la fenetre est incomplete, doit etre
   **declare** et non devine.
6. **Sans test de marche** — rang de depannage **1**, **la morphologie ne pese rien** (#3-d), et le
   bandeau « resultat provisoire » est **affiche**. Contre-preuve obligatoire : un profil qui a
   passe le test **ne doit pas** voir ce bandeau — sinon la correction C1 de la campagne N2
   (« le bandeau n'a pas ete supprime pour tout le monde ») a regresse.

---

## 8. LE LIVRABLE DE LA CAMPAGNE (#10-f)

**Une LISTE, pas un compte.** Chaque bascule porte : le profil, le jeu d'etapes, le rang de forme,
la portee (etape ou circuit), l'etape concernee, l'ancien verdict, le nouveau, le sens, les deux
ratios, et **la cause**. Le format est deja celui de `matrice_96.json`, tableau `bascules`.

**Etat MESURE sur le moteur final** (campagne complete, tache 547 du 23/09, branche
`claude/feat/540-moteur-faisabilite-v2` a `56faa89`). Les chiffres ci-dessous ne sont pas recopies :
ils sont la **difference terme a terme des deux colonnes**, et les deux colonnes sont verrouillees
sur le moteur reel par `campagne_v2_matrice_test.dart` — recalcul de controle fait, les 452 bascules
declarees sont exactement les 452 ecarts entre colonnes, sans une de plus ni une de moins.

- **452 bascules** au total : **389 d'etape** et **63 de circuit**.
- **238 durcissent**, **214 allegent**. Les durcissements viennent de l'unite d'energie et des
  plafonds re-derives ; **la totalite des allegements vient du plancher demontre** (#2-g).
- Par jeu : **J1 68**, **J2 69**, **J3 32**, **J4 283**. J4 en concentre le plus : 30 verdicts
  d'etape par cellule.
- Verdict de circuit : **42 cellules rouges en v1 -> 25 en v2**, et sur le sentier de production
  **6 sur 24**. Les 78 d'avant GO-61 sont l'ancienne regle, citee comme la mesure qui a fonde la
  decision, jamais comme l'etat du produit.
- **Ou tombe le rouge, maintenant qu'il veut dire quelque chose** : les 25 cellules rouges sont
  **toutes debutantes**, et elles ne concernent que **deux personnages sur six** — Lea (12 cellules,
  rangs 0 a 2 sur les quatre jeux) et Thomas (12 cellules, memes rangs), plus **Marc rang 0 sur le
  sentier de trente etapes**. Ce sont exactement les deux dont le **plancher demontre est inactif**.
  Aucun profil confirme ni expert n'est rouge nulle part.

**Les bascules du sentier de production, une par une** (ce que Christophe verra) :

- **Ines, rangs 0 a 2, debutante** — E1 rouge -> orange ; E2 orange -> vert ; E5 orange -> vert.
  Cause : plancher demontre actif (37,98 contre un plafond de niveau de 25,14).
- **Jean-Pierre, rangs 0 a 2, debutant** — E1 rouge -> orange ; E2 orange -> vert ; E5 orange -> vert.
  Meme cause (plancher 40,81).
- **Sabine, rang 0, debutante** — E1 rouge -> orange ; E2 orange -> vert ; E5 orange -> vert.
  Meme cause (plancher 39,43).
- **Marc, rang 0, debutant** — E1 rouge -> orange ; E2 orange -> vert. Plancher 34,84, et
  `k_chaleur` 0,93 qui joue en sens inverse.
- **Lea, rangs 0 a 2, debutante** — E4 vert -> orange ; E5 orange -> **rouge** ; E6 vert -> orange.
  Plancher **inactif** (13,76 < 25,14) : elle prend l'unite d'energie de plein fouet.
- **Thomas, rangs 0 a 2, debutant** — E2 orange -> **rouge** ; E4 vert -> orange ; E5 orange ->
  **rouge** ; E6 vert -> orange. Plancher inactif **et** `k_chaleur` 0,93 : le cumul le plus dur de
  la matrice.
- **Marc R1, Marc R2, Sabine R1, Sabine R2, Ines R3, Jean-Pierre R3, Lea R3, Thomas R3 —
  intermediaires** — E1 vert -> orange. C'est la bascule de reference de la spec (#9-e),
  **0,8103 -> 0,9113**.
- **Circuit, les 16 bascules du sentier de production, mesurees sous la regle en vigueur** —
  **huit allegent**, toutes de **rouge a orange** : Marc R0, Jean-Pierre R0/R1/R2, Ines R0/R1/R2,
  Sabine R0. **Huit durcissent**, toutes de **vert a orange** : Marc R1/R2, Lea R3, Jean-Pierre R3,
  Ines R3, Thomas R3, Sabine R1/R2. **Aucune cellule de J1 ne bascule vers le rouge.** Les six
  rouges de J1 (Lea et Thomas, rangs 0 a 2) l'etaient deja en v1 et le restent — par leur pire
  etape, jamais par le repos. L'ancien « 10 cellules vertes -> ROUGE par C3, monotonie 4,04 / 2,0 »
  decrivait la regle d'avant GO-61 ; il est **mort avec elle**.

**Ecart annonce avec la spec, a dire plutot qu'a taire.** #9-c annonce « 4 bascules sur 28 cellules,
14 %, toutes vers la severite ». Ce chiffre porte sur les **donnees sourcees** du sentier reel, en ne
regardant que le score d'etape et **sans** le plancher demontre ni le score de circuit. La matrice
tourne sur le **seed de l'application**, avec **tous** les termes de la spec : elle rend donc
davantage de bascules, **dans les deux sens**. Les deux chiffres ne se contredisent pas, ils ne
mesurent pas la meme chose — la spec l'avait annonce elle-meme (#9-e, « le seed porte d'autres
valeurs »). **C'est la matrice qui fait foi pour la campagne, parce que c'est le seed que
l'application embarque.**

---

## 9. CONDUITE DE LA CAMPAGNE

- **REGLE POSEE LE 22/09, ET ELLE PASSE AVANT TOUTES LES AUTRES : AVANT DE FAIRE CONFIANCE A UN
  HARNAIS, ON PROUVE QU'IL SAIT DIRE NON.** On lui fait passer un cas **volontairement faux** et on
  verifie qu'il **rougit**. Un harnais qui ne peut pas echouer nous a deja fait croire a une campagne
  verte qui ne testait rien (#100283, mission 1). **Concretement, avant chaque campagne** : au moins
  une exigence dont on sait qu'elle est fausse (un libelle qui n'existe pas, une valeur attendue
  volontairement decalee), un run, et un **rouge constate**. Tant que ce rouge n'a pas ete vu, **les
  verts qui suivent ne valent rien** et la campagne n'est pas lancee.
- **Les personnages sont des personnages, jamais des scripts** (#10-a). Le prompt se donne **tel
  quel**. On n'y ajoute rien, surtout pas un nom d'ecran, un libelle ou un ordre d'etapes. Un indice
  souffle pendant le run = **ECHEC ASSISTE**, consigne mot pour mot avec l'instant.
- **Sabine recoit son prompt en allemand.** Lui donner la version francaise fausse le test des la
  premiere ligne.
- **Toute donnee absente du prompt et utilisee par le personnage annule le point** (L9(d)) : le
  personnage a invente, on rejoue.
- **Grille de lecture** : #100297, dix lignes. **VERTE si et seulement si** les six repondent OUI en
  L1, **zero** L5, **zero** L6, **zero** L7. **ROUGE** des qu'un seul repond NON en L1. **A REJOUER**
  si un point est non verifie en L5 ou annule en L9(d) : on ne conclut pas sur ce qu'on n'a pas
  regarde.
- **Preuve d'effet, pas preuve d'affichage** : pour chaque action censee changer quelque chose, le
  rendu doit contenir (a) ce que le personnage voulait, (b) ce qu'il a fait, (c) ce qu'il a constate
  **apres** et **ailleurs**. Sans (c), le point est **non verifie**.
- **Un seul build a la fois. Emulateur laisse propre. Jamais `main`. Aucun code applicatif
  modifie** — seuls `integration_test/` et `test/` sont ecrits.
- **Environnement connu** : le formulaire de consentement publicitaire Google est une vue **native**
  hors arbre Flutter ; il surgit tardivement des que le reseau repond et recouvre un ecran
  quelconque. Il se ferme **cote hote**, une seule fois par installation, **en ne touchant que ses
  propres boutons** et jamais un dialogue de permission.
- **Reste non prouve sur appareil, hors perimetre de cette campagne** : l'injection GPS est morte sur
  l'emulateur, donc la barre de suivi de la carte se rend a vide **par conception**. Artefact
  d'environnement, a ne pas compter comme defaut.

---

## 10. ORDRE D'EXECUTION — ETAT AU 22/09 EN FIN DE JOURNEE

1. ~~Recuperer le harnais N2~~ — **FAIT** (tache 543). Verse, plus deux defauts du harnais lui-meme
   corriges : remise a zero des compteurs, et detection d'ecran systeme qui ne crie plus au loup.
2. ~~Prouver que le harnais sait dire non~~ — **FAIT**, 7 verts, en `flutter test`.
3. ~~Brancher le PLAN sur le moteur~~ — **FAIT** (commit `5154813`).
4. ~~Trancher C2~~ — **FAIT** : `S_circuit = max(C1 ; C3)`, invariant `C2 <= C1` a la place de la
   preuve de dominance.
5. ~~Re-mesurer la colonne C3~~ — **FAIT**, avec le couple de chiffres du repos par defaut.
6. ~~Reecrire S5~~ — **FAIT ET VERT SUR L'APPAREIL** : 95 exigences evaluees, 0 echouee.
7. ~~Reecrire S6~~ — **FAIT ET VERT SUR L'APPAREIL** : 246 exigences evaluees, 0 echouee, les 24
   cellules du sentier de production jouees par les vrais notifiers. **Deux pieges a connaitre pour
   la campagne** : attendre un `FutureProvider` se fait sous `tester.runAsync`, et **seulement apres
   avoir OUVERT le sentier** — depuis le catalogue, la trace GPX n'est pas chargee, donc
   `trailMaxAltitudeProvider` n'aboutit jamais et tout le moteur reste bloque. Toute attente de
   provider est desormais **bornee a 20 s** : un test qui se fige ne dit rien, un test qui echoue
   dit ou.
8. ~~Rejouer S1 a S4~~ — **FAIT** (tache 544), et **rejoues une fois de plus sur le moteur final**
   (tache 547).
9. ~~Ecrire S7, la famille 3~~ — **FAIT** (tache 544) : l'hiver declare non valide, l'altitude
   absente et dite, la morphologie qui ne pese pas, le dispositif poids, et le constat de duree qui
   ne doit jamais devenir un verdict.
10. ~~Jouer les six personnages sur le produit reel~~ — **FAIT le 23/09 (tache 547)**, sept
    scenarios sur le moteur final, **492 exigences tenues, zero echouee, 159 captures**.
11. ~~Rendre la liste des bascules et le verdict de porte~~ — **FAIT** : section 8 pour la liste,
    section 13 pour le verdict.

---

## 11. ARBITRAGE A REMONTER A CHRISTOPHE — **TRANCHE LE 22/09 (GO-61), ET LES DEUX VOIES ONT ETE PRISES**

> **Christophe a tranche, et il a pris les deux voies a la fois.** Le repos **sort du verdict**
> (`S_circuit = C1`) **et** le programme par defaut **pose desormais des repos**. La campagne du
> 23/09 l'a re-mesure sur l'appareil, 24 cellules sur 24 du sentier de production : `repos=2`,
> `C3=0,7675`, `dominante=worstStage`. Ce qui suit est le texte d'origine de l'arbitrage, garde
> pour memoire de ce qui a ete decide et sur quels chiffres.

**Un seul, et il tient en deux chiffres.** Par defaut, aucun jour de repos n'est pose dans un
programme : **78 cellules sur 96 sont rouges**. Avec deux jours de repos, **42**. Donc **36
cellules, pres d'une rouge sur deux, sont rouges uniquement parce qu'aucun repos n'est pose** — et
sur le sentier de production, c'est **18 des 24**. L'expert y recoit un circuit rouge alors que sa
pire etape est a 0,54, vert franc.

**Deux voies, et ce n'est pas a la campagne de choisir.** Soit le programme par defaut pose des
jours de repos, et le rouge redevient un signal rare qui veut dire quelque chose. Soit il n'en pose
pas, et l'ecran doit dire en toutes lettres que **c'est l'absence de repos qui decide**, sinon le
randonneur lira un jugement sur lui-meme la ou il y a un jugement sur son planning.

---

## 12. LA RECETTE DE LANCEMENT — A SUIVRE A LA LETTRE

**Sans elle, un run est INVALIDE et ses echecs ne veulent rien dire.** Le 22/09, un premier rejeu de
S1 a rendu quatre echecs qui ressemblaient a des defauts produit : c'etait un dialogue Android et le
formulaire de consentement publicitaire Google qui recouvraient l'ecran. **La capture l'a montre en
dix secondes.** Sans image, quatre faux defauts partaient au rapport.

**1. Lancer les trois demons hote AVANT le run, DEPUIS POWERSHELL.**

- `tool/persona_shot_daemon.py <serial> <dossier_captures> --logfile <log>` — sans lui, **aucune
  capture**, donc rien a montrer.
- `tool/persona_dialog_dismisser.py <serial> <duree>` — ferme le consentement publicitaire et les
  dialogues systeme.
- `tool/persona_perm_granter.py <serial> <package> <duree> [--avant-plan]` — voir le point 3.

**PIEGE QUI COUTE UN RUN : lancer les demons depuis Git Bash ne marche pas.** MSYS convertit
`/sdcard/...` en `C:/Program Files/Git/sdcard/...`, le dump d'ecran echoue **en silence**, et le
dismisser ne ferme plus rien sans le dire.

**2. Creer le fichier de log AVANT de lancer le demon de captures, et rediriger le test en AJOUT
(`>>`), jamais en ecrasement (`>`).** Le demon se place a la fin du fichier a l'ouverture : si le
test recree le fichier, le demon garde l'ancien descripteur et ne voit plus rien.

**3. Le jeu de permissions depend du scenario, et se tromper fausse le test.**

- **S1** : `--avant-plan`. Le premier plan est accorde (sinon le dialogue de localisation recouvre
  l'ecran Faisabilite), **le fond ne l'est PAS** — c'est ce qui permet a S1 de voir le pre-vol
  explique. Accorder le fond rendrait le test faux-vert.
- **S3** : permissions **completes**. S3 teste precisement le chemin « permissions deja accordees »,
  celui ou le pre-vol ne doit rien ouvrir.
- **Les autres** : `--avant-plan` convient.

**4. Verifier que le run s'est declare VALIDE.** Chaque scenario porte desormais une exigence
`run_valide` : si une fenetre systeme a recouvert l'application, **le run se declare invalide au
lieu de se faire passer pour un rapport de defauts**.

**5. Etat de reference au 22/09, RECONDUIT A L'IDENTIQUE LE 23/09 SUR LE MOTEUR FINAL** — a
comparer apres chaque campagne :
S1 **49** exigences · S2 **15** · S3 **17** · S4 **8** · S5 **95** · S6 **246** · S7 **62**.
**492 au total, zero echouee**, **159 captures** (S1 63 · S2 20 · S3 43 · S4 16 · S5 9 · S6 4 · S7 4).
Le changement de moteur du 22/09 au soir (GO-61) n'a **deplace aucun de ces sept chiffres**.

**6. Le lanceur est ecrit, il n'est plus a retenir.** `tool/run_persona.ps1` applique les points 1
a 3 de cette recette : log cree avant le demon, sortie du test en ajout, trois demons hote lances
depuis PowerShell, jeu de permissions passe en parametre. Un run se lance par
`powershell -File tool/run_persona.ps1 -Scenario integration_test/persona_s1_lea_test.dart -Tag S1
-Perm avant-plan` (S3 prend `-Perm complet`), et il rend en fin de course le compte des exigences
tenues, des exigences echouees et des captures.

---

## 13. VERDICT DE LA PORTE — CAMPAGNE COMPLETE SUR LE MOTEUR FINAL (tache 547, 23/09)

**Cadre.** Branche `claude/feat/540-moteur-faisabilite-v2` a `56faa89`, celle qui porte GO-61.
Emulateur `emulator-5554`, Android 14. Recette de lancement suivie a la lettre pour les sept runs.

**LA PORTE DIT OUI, avec une reserve nommee et deux constats hors moteur.**

**Ce qui est vert, et prouve.**
- **Gate 0, avant tout le reste** : le harnais est prouve capable de dire non — 7 tests verts.
  Tant que ce rouge n'a pas ete vu, les verts qui suivent ne valent rien ; il a ete vu.
- **Les trois familles sont jouees** : passants (S1 a S4, S6), non passants (S5, 95 exigences aux
  bornes et hors bornes), cas metiers a reponses multiples (S7, 62 exigences).
- **492 exigences tenues, zero echouee, 159 captures** — sept scenarios sur sept.
- **Les deux colonnes de la matrice des 96 tiennent sur le moteur final**, et avec elles les
  **452 bascules** de la section 8. Suite complete : **2 517 verts**. `flutter analyze lib test
  integration_test` : **2 informations**, aucune erreur, aucun avertissement.

**La re-mesure demandee, faite sur l'appareil et non sur le papier.** Les 24 lignes
`PERSONA_MATRICE_C3` du run S6 disaient toutes, le 22/09 : `repos=0`, `C3=2,0197`,
`dominante=rest`, `circuit=red`. Elles disent maintenant, 24 sur 24 : **`repos=2`, `C3=0,7675`,
`dominante=worstStage`**, et le verdict de circuit **suit la pire etape** : **6 rouges, 16 oranges,
2 verts**. Marc rang 3 et Sabine rang 3, dont la pire etape est a 0,68 et 0,63, sont **verts** la
ou ils etaient rouges faute de repos. Ces 24 verdicts sont **identiques a la colonne v2 de la
matrice** : le moteur sur l'appareil et la matrice tombent sur les memes chiffres.

**La preuve a l'ecran que le programme par defaut pose les repos** :
`data/campagne_547/captures/S1/S1_Lea_S1E_20_programme.png` — « **9 j (dont 2 repos)** », 7 etapes,
84 km, 3 750 m de D+.

**LA RESERVE, et elle n'est pas dans le moteur.** Pendant le parcours de S3 — celui qui marche,
declenche un SOS et termine son trek — l'application leve **deux assertions Riverpod
`setState() called during build`**, toujours les memes : `currentStageIdProvider` ->
`localizedStageNumberProvider` -> `LocalizedConditionsBanner.build`, et `AppHeader.build`. Elles
sont **systematiques** (vues dans les deux runs de S3) mais leur consequence est **intermittente** :
au premier run le test s'est declare rouge a la cloture, au second il est passe vert **avec les
memes deux exceptions et les memes 17 exigences tenues**. Les quatre fichiers en cause
(`gps_providers.dart`, `current_stage_provider.dart`, `localized_conditions_banner.dart`,
`app_header.dart`) n'ont **pas ete touches par les taches 540 et 545** : ce n'est pas une regression
du moteur. Un troisieme foyer, du meme genre, est visible dans S7 sur
`trek_feasibility_screen.dart:93` (`ref.watch` d'un provider a l'interieur du `data:` d'un autre) —
introduit par le correctif N2 `4d4efc1`, pas par GO-61. **Aucune de ces exceptions ne fait perdre
une exigence ; toutes polluent les runs et peuvent en masquer une vraie.** A corriger cote produit,
pas cote test.

**Le constat hors perimetre, pour memoire** : `test/shared/widgets/purchase_gate_widget_test.dart`
est rouge (timer de 6 s d'`AdsConsentService.ensureConsentAndInit` encore pendant a la fin du test).
**Verifie a la main** : il est **deja rouge au commit `5cf8974`**, avant la tache 540. Defaut de
base, sans rapport avec le moteur de faisabilite.

---

*Preparation tache 541 et harnais tache 543 — Artemis, 22/09/2026. Aucun fichier applicatif touche.
Les deux colonnes de la matrice sont verrouillees sur le moteur reel par **29 tests verts**, le
harnais est prouve capable d'echouer par **7 tests verts**, et S5 et S6 sont **verts sur
l'appareil** avec 95 et 246 exigences evaluees.

**Preuve directe de l'arbitrage, relevee sur l'appareil le 22/09 — etat HISTORIQUE, corrige depuis
par GO-61** : les 24 lignes `PERSONA_MATRICE_C3` du run de S6 disaient alors toutes `repos=0`,
`C3=2,0197`, `dominante=rest`, `circuit=red`. Vingt-quatre sur vingt-quatre, **niveau confirme
compris, dont la pire etape est a 0,68 — vert franc**. Le meme run du 23/09 dit desormais `repos=2`,
`C3=0,7675`, `dominante=worstStage` : voir la section 13.

**Point operationnel a ne pas oublier** : S5 et S6 sont verts mais **aucune capture PNG** n'a ete
produite, le demon `tool/persona_shot_daemon.py` n'etait pas lance. A demarrer avec `--logfile`
avant la campagne, sinon il n'y aura rien a montrer a l'ecran. **Regle le 23/09** : le demon est
lance par `tool/run_persona.ps1`, S5 et S6 ont desormais leurs captures.*

*Campagne complete tache 547 — Artemis, 23/09/2026. Aucun fichier applicatif touche : un lanceur de
run et ce document. Logs et captures : `data/campagne_547/` (non versionne).*
