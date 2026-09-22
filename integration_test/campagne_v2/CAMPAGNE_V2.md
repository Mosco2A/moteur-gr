# CAMPAGNE PERSONAS V2 — SCENARIOS ET ATTENDUS

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
  deux colonnes sur le moteur reel**. **28 verts au 22/09.**
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

> **Etat au 22/09 en fin de preparation.** **B2 est tranche** (`S_circuit = max(C1 ; C3)`, C2 en
> affichage). **B3 est cable** (les jours de repos remontent au moteur) — mais **la colonne C3 de la
> matrice, calculee avant ce cablage, est un artefact a RE-MESURER : la campagne ne part pas
> dessus.** **B1 reste ouvert** et devient la tache 543. **B4 est traite** par le banc des niveaux
> et un scenario d'hiver dedie.

### B1 — LE HARNAIS DE LA CAMPAGNE N'EST PLUS DANS LE DEPOT (bloquant, recuperable)

- **Ce qui manque.** `integration_test/persona_harness.dart` sur la branche courante est la version
  **d'AVANT la reparation N2** : aucune fonction `exige`, `exigeVisible`, `exigeAbsent`, `exigeTap`,
  `exigeSaisie`, aucun `verdictPersona`, aucune detection d'ecran systeme. C'est la version qui
  « loguait COINCE et concluait All tests passed » — celle qui ne peut pas echouer (#100283,
  mission 1, decrite comme « la partie la plus importante »).
- **Ou elle est.** Dans le **stash**, commit `04437e8` (`stash@{0}`,
  « On claude/fix/stepways-pseudo-long: wip-personas-avant-correction-n2 », Vulcain 22/09 08:18).
  Il porte +194 lignes sur le harnais (les six helpers ci-dessus sont a partir de la ligne 456) et
  les versions N2 de S1, S2, S3, S4 et `preuve_c1_moteur_unique_test.dart`.
- **Ce qui est PERDU, et qui n'est nulle part.** `persona_s5_limites_test.dart` (famille 2) et
  `persona_s6_matrice_test.dart` (famille 3, les 96 combinaisons) : **absents du depot, absents de
  toutes les branches, absents du stash, absents du disque**. Seules restent leurs 47 captures dans
  `data/captures_personas_n2/`. Ils sont a **reecrire entierement**.
- **Piege a la reprise du stash** : il a ete pose **avant** le correctif N2 (`4d4efc1`, D1 le verdict
  attend tous les criteres, D2 le decoupage retenu persiste). Les scenarios S1 a S4 du stash
  attendent donc un verdict qui tombe des la morphologie. Ils doivent etre **rejoues et corriges**
  apres reprise, pas repris tels quels.
- **Action** : recuperer `04437e8`, le **committer** (il n'a jamais ete verse), rejouer S1-S4 contre
  le produit corrige, puis ecrire S5 et S6.

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

### B3 — C3 NE DEPEND PAS DU RANDONNEUR — **CABLAGE LIVRE, MAIS LA COLONNE C3 DE LA MATRICE EST A RE-MESURER**

> **AVERTISSEMENT QUI PRIME SUR TOUT CE QUI SUIT.** Le cablage a ete livre pendant la redaction de
> ce document : `trek_feasibility_provider.dart` passe desormais `restAfterStageIndex: restDays`,
> alimente par `restDaysAfterStageProvider` qui lit les jours de repos du programme. **Les valeurs de
> C3, la contrainte dominante et le verdict de circuit de la colonne APRES ont ete calcules AVANT ce
> cablage, sur une serie sans aucun jour de charge nulle : ce sont des ARTEFACTS.**
> **NE PAS LANCER LA CAMPAGNE DESSUS — on enregistrerait un faux.** Le JSON porte le drapeau
> `meta.C3_PROVISOIRE`, et le test le verifie.
> **Ce qui reste valable sans re-mesure** : toute la colonne AVANT, les scores et verdicts
> d'**etape** de la colonne APRES, **C1**, **C2**, et l'invariant `C2 <= C1` — ils ne dependent
> d'aucun jour de repos.
> **Pour la re-mesure, rien a recalculer** : `jeuxEtapes[*].c3ParNombreDeRepos` donne d'avance la
> valeur de C3 pour 0 a 12 jours de repos, avec le placement exact retenu
> (`reposPosesApresLesEtapes`), **verifie sur le moteur** par le test `TABLE DE RE-MESURE`.

**UNE PRECISION SUR LE MECANISME, parce que la raison avancee n'est pas la bonne.** Il a ete dit que
« tant que le repos ne remonte pas au moteur, l'ecart-type vaut zero partout et la monotonie sature
partout ». **Mesure : l'ecart-type n'est pas nul** — J1 6,129, J2 5,128, J4 5,627 — et la monotonie
ne sature pas : elle vaut 4,04, 5,06 et 4,53. L'ecart-type n'est nul que si toutes les charges sont
**strictement egales**, ce qu'aucun de nos jeux n'est ; et la monotonie n'est **non calculable** que
sur J3, qui n'a qu'une etape. **Le vrai mecanisme est plus simple et tout aussi bloquant** : sans
jours de repos, il manque a la serie les jours de **charge nulle**, qui sont precisement ce qui
creuse l'ecart-type et fait chuter la monotonie. On mesure donc la bonne formule **sur la mauvaise
serie**. **La conclusion ne change pas d'un iota : la colonne C3 est a re-mesurer.**

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

**Etat attendu, calcule d'avance sur les entrees figees** — a confronter au moteur reel une fois la
tache 540 livree :

- **449 bascules** au total : **389 d'etape** et **60 de circuit**.
- **257 durcissent**, **192 allegent**. Les durcissements viennent de l'unite d'energie et des
  plafonds re-derives ; **la totalite des allegements vient du plancher demontre** (#2-g).
- Par jeu : **J1 62**, **J2 77**, **J3 32**, **J4 278**. J4 en concentre le plus : 30 verdicts
  d'etape par cellule.
- Verdict de circuit : **42 cellules rouges en v1 -> 78 en v2**, dont **24 sur 24** sur le sentier
  de production. **Ce chiffre est le symptome de B3, pas un resultat a livrer tel quel.**

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
- **Circuit, les 10 cellules qui etaient vertes** — Marc R1, R2, R3 ; Lea R3 ; Jean-Pierre R3 ;
  Ines R3 ; Thomas R3 ; Sabine R1, R2, R3 : **vert -> ROUGE**, cause **C3, monotonie 4,04 / 2,0**.
  **Les 14 autres cellules de J1 etaient deja rouges et le restent.** Voir B3 : ce n'est pas un
  resultat, c'est un symptome.

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

## 10. ORDRE D'EXECUTION PROPOSE

1. **Lever B1 — tache 543** : recuperer `04437e8`, committer le harnais N2, **lui faire passer un
   cas volontairement faux et constater le rouge**, puis rejouer S1-S4 contre le produit corrige.
2. ~~Brancher le PLAN sur le moteur~~ — **FAIT** pendant cette preparation
   (`restAfterStageIndex: restDays`). **Reste a prouver a l'ecran**, et a verifier le sens de pose
   des jours de repos (AVANT cote planning, APRES cote moteur).
3. ~~Faire trancher B2~~ — **FAIT** : `S_circuit = max(C1 ; C3)`, C2 en affichage, #10-b corrigee a
   deux contraintes dominantes. Le test de dominance est devenu un **invariant** `C2 <= C1`.
4. **RE-MESURER LA COLONNE C3** de la matrice apres le cablage, avant toute campagne. La table
   `c3ParNombreDeRepos` est deja verifiee sur le moteur : il s'agit de choisir la ligne qui
   correspond au programme reellement retenu par chaque personnage, pas de recalculer.
5. **Reprendre les tests de l'ancienne API** laisses en plan par la tache 540 (15 erreurs
   `flutter analyze`, une dizaine de fichiers qui ne se chargent plus).
6. **Reecrire S5 (famille 2) et S6 (famille 1 + matrice)**, plus un **S7** pour la famille 3
   (F3-1 a F3-12) — l'ancien S6 ne couvrait pas F3-2, F3-4, F3-7, F3-8 ni F3-12, qui naissent des
   decisions du 22/09.
7. **Rejouer la matrice a l'ecran** (elle est deja verte au niveau du moteur) : ce qui reste a
   prouver, c'est que **l'ecran dit** ce que le moteur calcule — facteur dominant nomme, replis
   declares, explication d'ARB-004.
8. **Jouer les six personnages** sur le produit reel, grille #100297 comme seule feuille de lecture.
9. **Rendre la liste des bascules**, une par une, et le verdict de porte.

---

*Preparation tache 541 — Artemis, 22/09/2026. Aucun fichier applicatif touche.
Les deux colonnes de la matrice sont verrouillees sur le moteur reel par **28 tests verts**, et
elles concordent avec le moteur v2 livre pendant la preparation, cellule par cellule.
Quatre points nommes, dont un cablage a faire tout de suite et un arbitrage a rendre.*
