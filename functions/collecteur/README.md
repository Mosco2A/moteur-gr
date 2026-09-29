# Le collecteur serveur — ce qu'il est, et comment on le met en service

> Tâche 624. Met en œuvre la conception 611 d'Athena et la spécification serveur 605.
> **Rien n'est déployé.** Ce document dit comment on déploie ; la décision appartient
> à Christophe.

Décision de Christophe du 28/09, verbatim : *« il y a un gros chantier qui est mise
à jour des données sentiers, météo, incendie. Je ne veux pas que ce soit l'appli qui
fasse ça mais notre serveur qui mette à jour les données. »*

---

## 1. Ce qu'il fait, en une phrase

Trois travaux planifiés, sans interface, qui vont lire des sources officielles et
déposent ce qu'ils ont lu à côté des données du sentier, **horodaté par le serveur**.
Ils ne calculent aucun verdict, ne décident rien, et **n'effacent jamais**.

| Tâche | Cadence | Ce qu'elle fait |
|---|---|---|
| `collecteMeteo` | toutes les 4 h | MET Norway → un bulletin de 5 jours par étape |
| `collecteRisqueIncendie` | 06:00, 16:00, 19:00 UTC | Météo des forêts → le danger du jour par étape |
| `surveillantDuCollecteur` | toutes les 3 h | lit le battement des deux autres et alerte si l'un s'est tu |

**Trois tâches, c'est exactement l'allocation gratuite de Cloud Scheduler** — 3 par
mois et par *compte de facturation*, pas par projet. Ce n'est pas une coïncidence,
c'est la contrainte de dimensionnement.

---

## 2. Ce qu'il écrit, et ce que l'application doit en lire

| Collection | Clé | Lecture cliente | Contenu |
|---|---|---|---|
| `meteo_etape` | `<trailId>__<stageId>` | **publique** | le bulletin complet d'une étape |
| `risque_incendie_etape` | `<trailId>__<stageId>` | **publique** | deux blocs séparés : `dangerMeteo`, `acces` |
| `catalogue_borne` | `courant` | **publique** | `arreteA` + une date par (sentier, famille) |
| `collecteur_battement` | `courant` | **REFUSÉE** | l'exploitation seulement (voir §6) |
| `collecteur_registre` | `meteo`, `risque_incendie` | refusée | validateurs de cache + empreintes |
| `collecteur_enrolement` | `courant` | refusée | la liste des étapes à collecter |

### Le contrat d'horodatage, et il tient en une ligne

Le champ de synchronisation s'appelle **`rev`**, et c'est un **`Timestamp` Firestore
natif**.

Côté application, aucune modification n'est nécessaire : `HorodatageServeur
.annonceParLeServeur` accepte déjà un entier de millisecondes, donc

```dart
HorodatageServeur.annonceParLeServeur(snap.get('rev').millisecondsSinceEpoch)
```

**Pourquoi `rev` et pas `majLe`.** La conception 611 nomme ce champ `majLe`. Le dépôt
a **déjà** un nom pour ce fait exact — `RevisionDeDonnee.champRevision` = `'rev'` — et
c'est le champ que `SourceInterrogeable` interroge (`where('rev','>',R)`). Introduire
`majLe` aurait créé deux noms pour un même fait, ce que #M7 et #X12 de la spec 605
dénoncent explicitement, et aurait obligé à écrire un second chemin de requête côté
application. **C'est un écart assumé au vocabulaire de la conception, pas au modèle.**

### Les deux dates d'un bulletin, et laquelle s'affiche

| Champ | Ce qu'il dit | Usage |
|---|---|---|
| `produiteLe` | l'heure du **modèle** MET Norway (`meta.updated_at`), ou l'instant de production du bulletin incendie | **c'est celle que l'écran affiche** : « la date en haut du bulletin est celle de fabrication » |
| `rev` | l'instant du passage qui a écrit ce document | la synchronisation |

La conception annonçait **trois** dates (#W11 : `produiteLe`, `collecteeLe`, `majLe`).
Il n'y en a que deux, et c'est sa propre règle #H3 qui le justifie : `collecteeLe` et
`majLe` désigneraient le même instant (il y a un seul instant par passage), et
« a-t-on vérifié récemment ? » est porté par le **battement**, puisque *« la fraîcheur
est portée par la donnée, la vivacité par le battement »*.

### L'état n'est pas stocké — il est dérivé

`connu` / `périmé` / `hors saison` / `inconnu` **n'existe pas comme champ**, et c'est
volontaire. #I16 : *« un bulletin vaut pour un jour nommé. Passé ce jour, il n'est pas
un peu vieux, il est faux. »* Un champ `etat` écrit à 16:00 serait donc faux à minuit,
et il serait faux **en disant « connu »**.

La fonction de référence est `documents.js → etatDerive({jourDuBulletin, jourCourant,
saisonActive})`. **Le côté application doit utiliser la même définition, pas une
seconde qui dériverait.**

Conséquence heureuse : le passage de 06:00 UTC n'a **rien à retirer** (contrairement à
ce qu'annonce #I14). Un bulletin périmé disparaît tout seul chez le lecteur, sans que
le serveur écrive un octet.

---

## 3. Ce qui se passe quand une source tombe

**Le collecteur n'efface rien et ne boucle pas.** Les deux sont structurels, pas
intentionnels :

- **Il n'efface pas** : il n'existe **aucun appel `delete`** dans `depot_firestore.js`.
  Une collecte qui échoue **n'écrit rien** — pas un vide, pas un `null`, pas un
  enregistrement « indisponible ». La dernière donnée connue reste en place **avec son
  `rev` inchangé**, donc elle ne redescend même pas vers les téléphones : *un échec ne
  produit aucun octet de trafic*.
- **Il ne boucle pas** : au plus **une seconde tentative**, et seulement sur une panne
  de transport (réseau, 5xx). **Un 4xx n'est jamais réessayé** — ce n'est pas un aléa,
  c'est un défaut, et le réessayer par lassitude finirait par le normaliser. **La
  cadence EST la politique de reprise** : c'est précisément pourquoi l'incendie a un
  passage à 19:00 en plus de celui de 16:00.

*Testé de bout en bout* : `collecteur_passage_complet.test.mjs` vérifie qu'après une
panne totale, les 7 documents précédents sont **identiques octet pour octet**, que la
borne **n'a pas bougé**, et que le battement **dit** l'échec.

Et si cinq étapes sur sept répondent, **on écrit cinq** (#T2). Refuser tout le passage
priverait de météo les cinq qui vont bien.

---

## 4. Le cache MET Norway — une obligation de licence, pas une optimisation

`api.met.no/doc/TermsOfService` impose trois choses, et ne pas les faire **fait
bannir l'application entière** :

| Obligation | Où elle est tenue | Mesure |
|---|---|---|
| User-Agent nommant l'application **et un moyen de contact** | `config.js` — le collecteur **REFUSE DE PARTIR** sans lui, et exige un `@` ou une URL | — |
| *« Cache data locally and use the If-Modified-Since request header »* | `cache_conditionnel.js` + `collecteur_registre` | passage 3 mesuré : **7 appels, 0 octet reçu** (7 × HTTP 304) |
| respecter les en-têtes `Expires` | `deciderAppel` → `appeler: false` tant que `Expires` n'est pas atteint | passage 2 mesuré : **0 appel sortant** |
| ≤ 20 requêtes/seconde par application | `collecte.js` : 4 appels en vol, 100 ms d'espacement → **plafonné à 10/s** | 7 étapes en 692 ms |

**Le cache vit dans Firestore, pas en mémoire.** Une fonction planifiée peut démarrer
à froid à chaque réveil : un cache en mémoire serait systématiquement vide, et
l'obligation ne serait tenue que sur le papier.

Les coordonnées sont **tronquées à 4 décimales**, ce que MET Norway demande
explicitement pour l'efficacité de son propre cache.

### Aucune clé en clair, nulle part

**Les deux sources sont publiques et sans clé** — mesuré : HTTP 200 sans compte, sans
jeton. Il n'y a donc **aucun secret à gérer** pour la collecte. Le collecteur ne lit
que des **noms** de variables d'environnement :

| Variable | Obligatoire | Défaut |
|---|---|---|
| `STEPWAYS_COLLECTEUR_USER_AGENT` | **OUI** — refus de démarrage sinon | — |
| `STEPWAYS_COLLECTEUR_FOURNISSEUR_METEO` | non | `met-norway` |
| `STEPWAYS_COLLECTEUR_JOURS_PORTEE` | non | `5`, borné à [3..5] |
| `STEPWAYS_COLLECTEUR_FUSEAU_DEFAUT` | non | `Europe/Paris` |
| `STEPWAYS_COLLECTEUR_CORSE_ACTIF` | non | **éteint** (licence non établie, §7) |
| `STEPWAYS_COLLECTEUR_A_BLANC` | non | éteint (tout calculer, rien écrire) |

---

## 5. Ce que coûte un passage — MESURÉ le 29/09/2026 sur les sources réelles

`node collecteur/outils/mesurer_un_passage.mjs` — n'écrit rien, compte tout.

### Un passage météo sur 7 étapes

| Poste | Mesure |
|---|---|
| durée | **692 ms** |
| appels sortants | **7** (MET Norway ne groupe pas les points) |
| octets reçus **sur le réseau** | **~4,9 Kio par appel**, soit ~34 Kio (mesuré au `Content-Length` gzip) |
| octets écrits en base | **11 072** (1 581 octets par étape) |
| opérations d'écriture | **10** (7 documents + registre + borne + battement) |
| opérations de lecture | **2** (registre + borne) |

### Les deux passages qui ne coûtent rien

| Cas | Appels | Octets reçus | Écritures de donnée |
|---|---|---|---|
| `Expires` pas atteint | **0** | 0 | 0 |
| revalidation, rien de neuf | 7 | **0** (304) | **0** |

### Un passage incendie

| Poste | Mesure |
|---|---|
| appels sortants | **1** — le fichier est national, 96 départements |
| octets reçus | **47 374** (gzip) |
| documents écrits | 7 (825 octets chacun) |

### À l'échelle de 10 sentiers de 7 étapes (70 étapes)

| Poste | Par jour | Palier gratuit |
|---|---|---|
| lectures Firestore (collecteur) | **18** | 50 000 |
| écritures Firestore | **~510** | 20 000 |
| octets écrits | ~648 Kio | — |
| appels sortants météo | 420 (0,005/s) | 20/s |
| appels sortants incendie | 3 | — |
| **lectures côté randonneurs** (1 000 × 6 passages × 1 borne) | **6 000** | 50 000 |

**On est à deux ordres de grandeur sous le palier gratuit.** Le coût récurrent attendu
est de **0 €** : MET Norway est gratuit (et économise les ~29 $/mois d'Open-Meteo), la
Météo des forêts est en Licence Ouverte, et les trois tâches planifiées tiennent dans
l'allocation gratuite.

**Les 250 $ de crédits expirent le 5 novembre 2026** : à ces volumes, ils ne seront
pas entamés par le collecteur. Le risque de coût n'est pas là — il est dans le bucket
Cloud Storage européen, dont le palier gratuit n'est **pas** garanti (réserve #R03 /
#V4 de la conception, sortie documentée : Cloudflare R2).

### La cadence retenue, et pourquoi

- **Météo : 4 heures.** C'est la cadence que Christophe a fixée au téléphone, donc
  collecter plus souvent ne servirait **personne** ; et MET Norway annonce sa propre
  péremption à +31 min, donc 4 h reste très au-dessus de ce qu'il tolère. **Hors
  saison, la cadence est la même** : le coût est nul, et une météo absente coûte plus
  cher qu'une collecte inutile.
- **Incendie : 16:00 UTC** (la source est posée à 14:50 avec une régularité d'horloge
  — 124 jours sur 124), **19:00 UTC** (le rattrapage d'un retard de publication, seul
  mode de panne plausible d'une source qui ne rate jamais un jour), **06:00 UTC**
  (prendre le bulletin du jour et permettre au surveillant d'alerter à 08:00 s'il
  manque).
- **Surveillant : 3 heures**, soit sous la demi-période de la tâche la plus rapide.

---

## 6. Le battement, et pourquoi l'application ne le lit pas

Un collecteur qui s'arrête **ne produit aucune erreur** : la donnée cesse simplement
de bouger, et rien ne distingue « le monde n'a pas changé » de « nous avons arrêté de
regarder ». C'est le seul mode de panne totalement silencieux du dispositif.

Le battement est donc écrit **à chaque exécution, succès ou échec**, même quand rien
d'autre n'est écrit — y compris quand la configuration est **refusée**. C'est tout son
intérêt : **c'est le seul enregistrement dont l'absence est une information.**

**Sa lecture est refusée par les règles Firestore**, et c'est une décision de
conception, pas un oubli de permission : si le téléphone le lisait, un battement vert
rassurerait sur une donnée périmée. *Un collecteur peut tourner parfaitement et ne
collecter que des échecs.* L'exploitation le lit par la console ou l'Admin SDK.

Le surveillant lève trois alertes : une tâche muette depuis plus de deux fois sa
période, une source en échec derrière un collecteur en bonne santé (#H6 — le vrai
risque), et le bulletin du jour absent à 08:00 UTC en pleine saison (#H7).

---

## 7. Ce qui est écrit, testé, et volontairement éteint

**La carte du risque par massif en Corse** (`incendie_corse.js`) est complète et
testée, et **elle ne tourne pas**. Raison : **sa licence n'est pas établie** (#I8 /
#R1). Aucune page de mentions légales, deux URL testées en 404. Le site est public et
produit par l'État, ce qui rend la Licence Ouverte *plausible* — mais plausible n'est
pas établi, et StepWays est payant.

**Ce qui la débloque : un courriel à `srfb.draaf-corse@agriculture.gouv.fr`.** Le jour
où la réponse arrive, il n'y a rien à écrire : `STEPWAYS_COLLECTEUR_CORSE_ACTIF=1`.

Le battement la **nomme** même éteinte (`issue: 'eteint'`), parce qu'un silence se
lirait comme « tout va bien ».

Deux autres réserves, non comblées :
- **l'échelle numérique du flux corse n'est pas documentée** : on transmet le niveau
  brut avec `echelleEtablie: false` et `libelle: null`. Mettre une table de libellés
  serait une supposition présentée comme un fait, sur une donnée qui porte une
  **interdiction**.
- **MET Norway ne fournit pas de probabilité de précipitation** (mesuré) :
  `precipitationProbabilityMax` reste `null`. C'est une **perte fonctionnelle réelle**
  par rapport à Open-Meteo, nommée plutôt que comblée.

---

## 8. COMMENT ON DÉPLOIE, le jour où Christophe le décide

**Rien de ce qui suit n'a été fait.** L'ordre n'est pas négociable.

### Préalables (console, non automatisables)

```
[ ] 1. Passer le projet stepways-app au plan BLAZE
       Ce n'est pas un choix : depuis le 3 février 2026 il faut Blaze pour créer ou
       conserver un bucket Cloud Storage, et les fonctions planifiées l'exigent de
       toute façon.
[ ] 2. Poser une ALERTE DE BUDGET le même jour. Blaze est du paiement à l'usage ;
       l'alerte est le seul garde-fou, et elle se pose en deux minutes.
[ ] 3. Créer Firestore en mode NATIF, région europe-west1
       (la même que celle déclarée par les trois fonctions).
[ ] 4. Vérifier que les 3 tâches gratuites de Cloud Scheduler sont LIBRES :
       le palier est mesuré au COMPTE DE FACTURATION, pas au projet. Si un autre
       projet en consomme, ces trois-là coûtent 0,10 $ par tâche et par 31 jours.
[ ] 5. Créer .firebaserc (absent du dépôt) ou passer --project à chaque commande.
```

### Mise en service

```bash
# 1. Les règles de sécurité et les index D'ABORD.
#    Les index AVANT la première requête réelle : sans eux la requête échoue
#    à l'EXÉCUTION, pas à la compilation — donc les tests passent et la
#    production tombe.
firebase deploy --only firestore:rules,firestore:indexes --project stepways-app

# 2. Les dépendances, puis les tests.
cd functions && npm install && npm test        # 139 tests attendus, 0 échec

# 3. Le User-Agent, dans l'environnement. SANS LUI LE COLLECTEUR REFUSE DE PARTIR.
firebase functions:config:unset collecteur --project stepways-app   # si besoin
#    (v2 : passer par --set-env-vars au déploiement, ou un fichier .env.<projet>
#     NON VERSIONNÉ — functions/.env* doit rester hors du dépôt)

# 4. Les trois fonctions, NOMMÉES une par une : jamais --only functions tout court,
#    qui redéploierait aussi les trois fonctions de classement et de modération.
firebase deploy --project stepways-app --only \
  functions:collecteMeteo,functions:collecteRisqueIncendie,functions:surveillantDuCollecteur

# 5. Enrôler au moins un sentier, sinon le collecteur n'a rien à collecter.
#    Écrire collecteur_enrolement/courant : { etapes: [ {trailId, stageId,
#    stageNumber, lat, lng, codeDepartement, zoneIncendie, massifIncendie} ] }
#    C'est l'étape #X13 de la conception, « celle qu'on oublie, et c'est pour cela
#    qu'elle est numérotée » : sans elle le sentier est vendu SANS météo et SANS
#    risque incendie, et rien ne le signale.

# 6. Premier passage à blanc, pour mesurer sans écrire :
#    STEPWAYS_COLLECTEUR_A_BLANC=1, puis lire le battement.
```

### Essai local, sans rien déployer

```bash
cd functions
npm install
npm test                                        # la logique pure
node collecteur/outils/mesurer_un_passage.mjs    # les VRAIES sources, RIEN d'écrit
firebase emulators:start --only firestore        # puis le reste sous émulateur
```

### Retour arrière

Supprimer les trois fonctions (`firebase functions:delete collecteMeteo …`). Les
collections restent, avec leur dernière donnée et son `rev` : l'application continue
de lire ce qui est là et d'en afficher l'âge. **Aucune donnée n'est perdue, parce que
le collecteur n'en supprime jamais.**

---

## 9. Ce qui reste ouvert, et qui n'est pas de ce lot

| Point | Pourquoi ce n'est pas ici |
|---|---|
| **Les tests `functions/` ne tournent pas en CI** (`codemagic.yaml` n'a aucune étape `functions`) | `codemagic.yaml` appartient au lot 621. L'étape à ajouter : `npm --prefix functions ci && npm --prefix functions test` |
| **La lecture côté application** | c'est le lot 625 |
| **`arreteA` reste épinglé au minimum** : un téléphone qui en ferait son unique repère relirait, à chaque passage, tout ce qui a été écrit depuis. Juste, mais cher. | le remède est côté lecteur : un repère **par famille**, lu dans `sentiers[trailId][famille]`. Le contrat est écrit dans le document lui-même (`contratDeLecture`). |
| **`calculateFireRiskLevel` fabrique un niveau de risque incendie depuis la météo** (`lib/features/weather/domain/fire_risk.dart:115`) | **C'est exactement ce que #I21 interdit** : « pas de niveau calculé depuis la météo collectée, nous n'avons ni l'indice ni le droit de le fabriquer ». Signalé, **non corrigé** : c'est du code Flutter, hors de ce lot. |
| **Le bucket Cloud Storage** et la publication des sentiers | chantier du publicateur, pas du collecteur |
| **La vigilance météo** (orange/rouge) | proposée en V2 par #Z1 : elle demande une écriture hors rythme |
