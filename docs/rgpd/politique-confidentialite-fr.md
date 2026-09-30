# Politique de confidentialité — StepWays

> **CE DOCUMENT EST LA SOURCE ; LA PAGE EN LIGNE EN EST LE RENDU.**
> Publiée le 30/09/2026 sur <https://only1cent.com/stepways/privacy>
> (version anglaise : `/stepways/privacy-en`), hébergement Firebase du
> projet `gr20-app`, comme la politique du GR20 — décision de Christophe
> du 30/09 13:39 : « Regarde celle de GR20 et fais pareil ! » (tâche 642).
> L'adresse est portée par `StepwaysLegal` (`lib/core/branding/`), d'où
> les quatre configurations de sentier la tirent. Toute modification de
> ce texte doit être reportée sur les deux pages en ligne, et
> réciproquement : deux vérités qui divergent ne valent pas mieux
> qu'aucune.
>
> **ZONE JURISTE — validation encore requise sur la forme.**
> Ce document décrit fidèlement le comportement du code de l'application
> à la date ci-dessous. Il a été rédigé par l'équipe technique sur la
> base de sources documentaires (recommandations CNIL, textes RGPD/DSA)
> et **NON par un avocat**. Les passages marqués **[JURISTE]** restent à
> arbitrer. Champ encore ouvert : **`[ADRESSE]`** (siège social), qui
> n'est volontairement PAS inventé et n'apparaît pas sur la page publiée.
> Toute évolution fonctionnelle (analytics activé, sync photos, partage
> de position réellement ouvert…) impose la mise à jour préalable de ce
> texte.

**Dernière mise à jour : 30 septembre 2026** (tâche 642 — mise en
conformité du texte avec le code mesuré, et publication en ligne.
Consolidation précédente : 15 juin 2026, lot SEC-D, design D4 #86166)

## 1. Qui sommes-nous ?

L'application StepWays (« l'Application ») est éditée par **Only1Cent**,
représentée par **Christophe Mosconi** (« nous »). Nous sommes le
responsable du traitement des données décrites dans ce document.

Contact pour toute question relative aux données personnelles :
**contact@only1cent.com**.

> **[JURISTE] — siège social et DPO.** L'adresse du siège
> (**`[ADRESSE]`**) reste à renseigner ; elle n'est pas publiée tant
> qu'elle n'est pas vérifiée. La désignation d'un DPO n'est pas
> systématiquement obligatoire pour une petite structure ; le point de
> contact identifiable exigé par l'art. 13.1.b RGPD est assuré par
> `contact@only1cent.com`. Reste à arbitrer : faut-il un contact de
> modération distinct ?

## 2. Notre principe : minimisation dès la conception

StepWays est conçue pour fonctionner **d'abord en local, sur votre
téléphone**, y compris entièrement hors ligne en montagne :

- **Aucun compte nominatif n'est requis ni créé.** À la première
  utilisation, l'Application ouvre un **compte anonyme** auprès de
  Firebase Authentication. Lorsque vous connectez un compte Apple ou
  Google, l'Application n'enregistre **ni votre nom, ni votre adresse
  e-mail, ni votre photo** : le modèle de données de l'Application ne
  comporte tout simplement pas ces champs (garantie vérifiable dans le
  code — réf. interne #85383).
- L'authentification Apple est demandée **sans** les autorisations
  « nom » et « e-mail ».
- Vos **photos de journal**, votre **carnet de bord**, vos **traces GPS
  détaillées**, votre **morphologie**, vos **données de santé et
  contacts d'urgence** restent **exclusivement sur votre appareil** et
  ne sont jamais transmis à nos serveurs.
- **Ce qui sort est une LISTE FERMÉE, pas une liste d'exclusions**
  (tâches 612 et 617). Le code n'énumère pas ce qui reste dehors — il
  énumère ce qui a le droit de partir, et refuse tout le reste **avant
  le réseau**, dans les deux sens. Voir § 8.

> **Deux identifiants, et il faut les distinguer (corrigé tâche 642).**
> Les documents rangés sur nos serveurs le sont sous
> `users/{uid}`, où `uid` est l'**identifiant du compte anonyme Firebase**
> — attribué automatiquement, sans nom ni e-mail. Ce n'est PAS une
> empreinte SHA-256 : les règles de sécurité Firestore n'autorisent
> l'accès que si `request.auth.uid == userId`, ce qui impose l'identifiant
> brut comme chemin. L'empreinte SHA-256 salée existe bien, mais elle sert
> ailleurs : d'identifiant « métier » exposé aux écrans, et de
> `complainantUidHash` sur les plaintes de modération. Les versions
> antérieures de ce document annonçaient l'empreinte comme clé des
> données synchronisées — c'était inexact.

> **Pseudonyme, pas anonyme.** Lorsque l'Application affiche un
> classement, un pseudonyme ou une contribution communautaire, les
> données restent **pseudonymisées** (rattachables à un identifiant
> technique), et non anonymes au sens strict du RGPD (les trois critères
> CNIL — singularisation, corrélation, inférence — ne sont pas tous
> écartés). Nous ne communiquons donc jamais ces données comme
> « anonymes ». Un garde-fou automatisé empêche cette confusion dans
> l'interface (test transverse D4A-03).

## 3. Consentement granulaire par finalité

Vous décidez, **finalité par finalité**, ce que l'Application est
autorisée à faire. Le consentement est recueilli par un **acte positif
clair** (aucune case pré-cochée, recommandation CNIL), il est
**horodaté** (`decidedAt`), **versionné** (`policyVersion` : si la
politique change, votre accord est redemandé) et **révocable à tout
moment** depuis les réglages (Réglages → Confidentialité), où un bouton
**« Tout refuser »** retire les quatre finalités standard d'un seul geste
(tâche 580). Le détail technique du recueil figure dans le service de
consentement de l'Application (ConsentService, D4A-01/D4A-02).

**Le défaut est FERMÉ** : en l'absence d'état lisible, l'Application
considère qu'il n'y a pas consentement.

### 3.1 Le registre de consentement vit EN BASE (commits e3170ca0, d92d5cd5)

Décision de Christophe, verbatim : « Le consentement est dans nos bases,
horodaté, c'est les données qui n'y sont pas ».

Chaque décision tranchée est écrite sous
**`users/{uid}/consents/{finalité}`** — un document par finalité, liste
**fermée** de champs :

| Champ <!-- #304 --> | Contenu |
|---|---|
| `granted` | accordé ou refusé |
| `decided_at` | horodatage **serveur** : c'est lui qui fait foi |
| `updated_at` | dernière écriture du document |
| `version_du_texte` | version de cette politique que l'accord couvrait |
| `declencheur` | `premiere_demande`, `modification_des_donnees`, `evolution_de_politique`, `reglages`, `inconnu` |
| `decide_sur_le_telephone_le` | date de la **prise** de décision, distincte de sa transmission |

**Pourquoi deux dates.** Le serveur date l'ÉCRITURE ; une décision prise
hors réseau en montagne n'arrive que des jours plus tard. Dater le
consentement du jour de sa transmission serait une inexactitude
matérielle pour la preuve (art. 7-1 RGPD). L'arbitre reste le serveur.

**Aucun refus inventé.** Une finalité jamais tranchée n'a **pas** de
document : écrire `granted: false` sans décision fabriquerait un choix
qui n'a pas eu lieu. L'absence est une information.

**Le piège fermé.** `decided_at` étant un horodatage serveur, le renvoyer
à chaque réveil déplacerait la date du consentement à chaque lancement. Le
service retient l'empreinte de la dernière décision poussée et ne repousse
que ce qui a bougé ; l'empreinte ne se pose qu'**après** une écriture
réussie.

**Règle Firestore :** `users/{uid}/consents/{finalité}`, lecture et
écriture par le **propriétaire seul**, déclarée à part dans
`firestore.rules` (ligne 103) plutôt que laissée à la règle générique.

**UNE MODIFICATION DES DONNÉES REDEMANDE LE CONSENTEMENT** (d92d5cd5).
Décision de Christophe : « en cas de modification des données, on
redemande le consentement ». `ConsentState` porte une **révision des
données** à côté de sa version de texte ; quand elle ne correspond plus au
compteur courant, l'accord porte sur des données qui ne sont plus celles
d'aujourd'hui, et la question est reposée. **Une fois par modification,
jamais au simple affichage** : la notation part des écrans qui ÉCRIVENT,
pas de ceux qui affichent. Conséquence à connaître, et écrite sur les
pages publiées : répondre « Retirer » après enregistrement de la fiche
médicale **efface la morphologie**, parce que c'est ce que le retrait du
consentement santé a toujours emporté.

**CE QUI NE MONTE TOUJOURS PAS : la donnée protégée.** Le registre
enregistre le CHOIX, jamais son objet. La fiche médicale n'a aucun chemin
de sortie (liste fermée 612, intacte) et la morphologie non plus (635).

> **ÉTAT D'INTÉGRATION — à connaître (tâche 642, 30/09).** Ce code vit sur
> la branche `claude/feat/635-montee-en-base` (e3170ca0, d92d5cd5) et
> **n'est pas encore fusionné dans `main`**. Les deux pages publiées
> décrivent donc le comportement du build qui portera ce lot. **Un build
> livré sans le lot 635 rendrait ces paragraphes faux** : ne pas publier de
> version de l'application sans lui, ou corriger les pages avant.

| Finalité | Ce qu'elle autorise | Donnée sensible ? |
|---|---|---|
| **Navigation / position** <!-- #301 --> | Carte, suivi sur le sentier, enregistrement d'une randonnée | Géolocalisation précise |
| **Partage social** | Classements pseudonymes, fil d'activité, kudos, contributions communautaires | Pseudonyme |
| **Signalement public** | Signaler un contenu / un problème sur le sentier (modération DSA) | Contact du notifiant |
| **Publicité** (tâche 595) | Annonces **personnalisées**. Refusée, la publicité reste affichée mais devient non personnalisée | Identifiant publicitaire |
| **Données de santé** | Fréquence cardiaque / lecture santé (capteur BLE / Health), morphologie, montée des mesures d'effort, **optionnel** | **Oui — art. 9 RGPD** |

Une décision **distincte** de ces cinq finalités gouverne la
**sauvegarde système Google / Apple** (tâche 617) : elle est **refusée
par défaut**, avant même que la question ait été vue. Elle n'est, à ce
jour, **pas horodatée** — c'est un simple booléen.

> **Données de santé (article 9 RGPD).** Les données de santé
> (fréquence cardiaque, lecture santé) sont une **catégorie
> particulière**. Leur consentement est **séparé, explicite et
> renforcé** : il n'est jamais groupé avec les autres finalités, et un
> avertissement dédié vous est présenté. Ces données restent **locales
> sur votre appareil** (voir § 8). Voir aussi l'analyse d'impact dédiée
> (AIPD capteurs santé, document `AIPD-capteurs-sante.md`).

## 4. Données traitées, finalités et bases légales

### 4.1 Géolocalisation (précise)

- **Quand ?** Uniquement lorsque vous utilisez la carte, la navigation
  sur le sentier, ou l'enregistrement d'une randonnée. Le suivi en
  **arrière-plan** (service de premier plan Android, mode `location`
  iOS) démarre **au lancement d'un trek**, sur le geste du randonneur,
  et s'arrête à l'arrêt ou à l'abandon du trek. Il n'est **jamais actif
  hors randonnée en cours**.
- **Pendant combien de temps ?** Aussi longtemps que dure la randonnée,
  **sans mise en pause automatique** : une étape de sept heures doit
  être enregistrée en entier (le seuil des 30 minutes a été retiré —
  la capture continue EST le besoin). Une **notification permanente**
  reste affichée pendant tout le suivi : il ne peut pas être discret.
- **Minimisation technique.** Filtre de distance d'une douzaine de
  mètres à la source ; politique `PrivacyDataPolicy` (D4B-01) pour les
  agrégats.
- **Où vont les points ?** Dans la **base locale (Drift/SQLite) du
  téléphone, et nulle part ailleurs.** Aucune trace, aucun point de
  position ne monte vers nos serveurs.
- **Base légale :** consentement (article 6.1.a RGPD) — activation
  volontaire, désactivable à tout moment ; permission système requise.

> **LE PARTAGE DE POSITION EN TEMPS RÉEL N'EST PAS ACTIF — corrigé
> tâche 642.** Les versions antérieures de ce document décrivaient la
> publication de positions vers Cloud Firestore avec expiration à 48 h.
> **Mesure du code : ce chemin n'est appelé par aucun geste de
> l'application** (`FollowService.publishPosition`,
> `GroupSyncService` : zéro appelant), et les écritures de la
> fonctionnalité « groupe », elles, sont **refusées par les règles
> Firestore** (la collection `groups` n'a aucune règle, donc tombe sur le
> refus global). La carte « Mon groupe » a d'ailleurs été retirée du HUB.
> **Aucune position ne quitte donc l'appareil.** Le jour où cette
> fonction sera ouverte, ce document et les deux pages en ligne devront
> être mis à jour AVANT, et le consentement demandé.

### 4.2 Synchronisation cloud (optionnelle)

- **Quoi ?** La **liste fermée** de ce qui monte, sous `users/{uid}` :
  1. **la progression** sur le sentier (`user_progress`) : étape
     courante, distance, dénivelé, temps de marche, dates, sentier
     terminé ou non ;
  2. **la liste de préparation** (`checklist_items`) : l'état du sac ;
  3. **les mesures d'effort des randonnées passées** (`past_hikes`) :
     date, nombre de jours, heures de marche moyennes, dénivelé et
     distance totaux — **gardées par le consentement santé**, qui est
     vérifié AVANT même la lecture de la base locale ;
  4. **la fiche technique de l'appareil** : huit champs et huit
     seulement (première/dernière utilisation, version de
     l'application, build, plateforme, version du système, langue,
     fuseau), réécrits à chaque retour au premier plan ;
  5. **vos retours** (`user_feedback` : sentier, type, texte libre,
     note) et les **signalements / plaintes de modération** ;
  6. **le registre de vos consentements** (`consents/{finalité}`,
     commits e3170ca0 et d92d5cd5) : le CHOIX et sa preuve, jamais son
     objet. Détail au § 3.1.
- **Ce qui NE monte PLUS, et qui montait avant** (à ne pas réintroduire
  dans le texte sans réintroduire le code) : le **journal** (texte et
  chemins de photos), la **morphologie** (âge, taille, poids, sexe), et
  le **compte** (solde, droits, abonnement) — ce dernier étant en outre
  refusé côté serveur par `firestore.rules`. Les **photos** n'ont jamais
  été synchronisées.
- **Base légale :** exécution des fonctionnalités demandées
  (article 6.1.b RGPD) pour la progression et le sac ; consentement
  explicite art. 9.2.a pour les mesures d'effort ; intérêt légitime
  (6.1.f) pour la fiche technique de l'appareil.

### 4.3 Identifiant du compte anonyme

- **Quoi ?** L'identifiant attribué par Firebase Authentication au
  **compte anonyme** ouvert à la première utilisation. C'est la clé
  technique des données synchronisées (`users/{uid}`). Ni nom, ni
  e-mail, ni photo, ni identifiant publicitaire n'y sont associés.
- **À ne pas confondre** avec l'empreinte SHA-256 salée (voir l'encadré
  du § 2), qui sert d'identifiant « métier » côté écrans et de
  `complainantUidHash` sur les plaintes.
- **Base légale :** exécution des fonctionnalités demandées
  (article 6.1.b RGPD).

### 4.4 Contenus communautaires et signalements (modération)

- **Quoi ?** Lorsque vous publiez une contribution (commentaire de
  point d'intérêt, activité, signalement) ou que vous **signalez** un
  contenu, l'Application traite votre contribution et, pour un
  signalement, les informations nécessaires à son examen (motif,
  référence du contenu, contact du notifiant, déclaration de bonne foi —
  article 16 du règlement européen sur les services numériques, DSA).
- **Notre rôle.** StepWays agit comme **hébergeur** au sens du DSA pour
  les contenus publiés par les utilisateurs : la modération est faite
  **a posteriori** (après signalement), nous ne contrôlons pas les
  contenus a priori. Les règles de modération, la procédure de
  signalement, l'exposé des motifs (article 17) et le droit de
  contestation (article 20) figurent dans les **CGU et la page
  modération** (`docs/legal/cgu-moderation.md`), publiées le 30/09/2026
  sur <https://only1cent.com/stepways/conditions> (version anglaise :
  `/stepways/conditions-en`).
- **Base légale :** consentement (publication volontaire / signalement)
  et respect d'obligations légales (DSA) pour le traitement des
  signalements. Le contact du notifiant est une **donnée personnelle**
  minimisée et protégée (durée limitée, accès réservé aux modérateurs).

### 4.5 Publicité (Google AdMob)

L'Application intègre le SDK Google AdMob. **Deux formats seulement :
bannières et vidéos récompensées. Aucun interstitiel** — aucune API
interstitielle n'est exposée dans le code. Le SDK AdMob peut collecter
automatiquement : adresse IP, identifiant publicitaire de l'appareil,
interactions avec les annonces, données de diagnostic (voir la
documentation Google « AdMob data disclosure »).

**Le recueil du consentement est EN PLACE, pas à venir — corrigé
tâche 642.** Les versions antérieures de ce document annonçaient une
CMP « avant toute mise en production publicitaire » ; la plateforme de
consentement de Google (**UMP** : `ConsentInformation`, `ConsentForm`)
est **implémentée et appelée** (tâche 595) :

- dans l'EEE, le formulaire est présenté **avant toute demande
  d'annonce** ; son affichage est **reporté** s'il sort de la fenêtre
  d'amorçage (budget borné à 6 s, pour ne pas retarder le démarrage) ;
- un **point d'entrée permanent** (Réglages → Confidentialité) permet de
  rouvrir le choix publicitaire à tout moment, comme le CMP l'exige ;
- **aucun formulaire n'est demandé** sur un build sans identifiants de
  production : il n'ouvrirait sur rien ;
- sur iOS, l'invite **App Tracking Transparency** s'ajoute au formulaire
  (`NSUserTrackingUsageDescription` déclaré ; un seul réseau
  `SKAdNetwork`, celui de Google).

**Refus de la personnalisation ≠ disparition de la publicité** : la
bannière reste affichée, mais l'Application demande explicitement des
annonces **non personnalisées** (`nonPersonalizedAds: true`). C'est à
dire au randonneur sans ambiguïté.

**Quatre situations sans publicité** (source unique
`MonetizationService.isNoAdsActive`) : sentier acheté, abonnement actif,
24 h offertes par une vidéo récompensée, mode vitrine. **Conséquence
assumée** : sur le sentier de démonstration gratuit, une bannière peut
apparaître en marchant.

Les identifiants présents dans le dépôt sont les **identifiants de test
officiels de Google** ; ceux de production sont injectés à la
fabrication (`--dart-define`).

**Base légale :** consentement (article 6.1.a RGPD ; directive
ePrivacy).

> **[JURISTE] — évaluer le maintien d'AdMob.** L'identifiant
> publicitaire est la donnée la plus sensible du point de vue store et
> RGPD. Retirer AdMob simplifierait fortement la conformité (voir
> `docs/store/data-safety.md`). Décision business/juridique à arbitrer.

### 4.6 Services en ligne tiers (cartes et météo)

Lorsque l'Application n'a pas de fond de carte hors ligne disponible,
elle télécharge des tuiles cartographiques depuis
**OpenStreetMap** (tile.openstreetmap.org). Les prévisions météo des
étapes sont obtenues auprès d'**Open-Meteo** (api.open-meteo.com), sans
compte ni clé. Ces requêtes transmettent techniquement votre **adresse
IP** et les coordonnées du point consulté (étape du sentier) aux
serveurs concernés, le temps de la requête. **Base légale :** intérêt
légitime (article 6.1.f RGPD) — fournir la carte et la météo demandées.

### 4.7 Achats intégrés

Les achats intégrés (pass de suivi, contenus premium) sont traités par
l'App Store ou Google Play. **Nous ne recevons aucune donnée bancaire.**
À ce jour, le module d'achat de l'Application est verrouillé en mode
test : aucun paiement réel ne peut être déclenché.

### 4.8 Données strictement locales (jamais transmises)

Restent exclusivement sur votre appareil : photos du journal, **texte du
carnet de bord**, traces GPS détaillées des sessions enregistrées,
**données de santé** (groupe sanguin, allergies, traitements,
antécédents, fréquence cardiaque) et **toute la fiche d'urgence**
(identité, date de naissance, adresse, contacts, médecin, numéro
d'assuré, photos des cartes de santé), **morphologie** (âge, taille,
poids, sexe), préférences de l'Application. La désinstallation de
l'Application les supprime.

Stockages locaux employés : **Drift/SQLite** (`stepways.sqlite`) pour la
progression, le journal, la trace et les randonnées faites ;
**SharedPreferences** pour les consentements, les réglages et le tampon
GPS de fond ; **flutter_secure_storage** (Keystore Android / Keychain
iOS) pour la clé du coffre et le code de reconnexion ; des **fichiers
dédiés** sous le répertoire privé pour `medical/` et le profil du
randonneur. Le coffre local est chiffré en **AES-GCM 256 bits** avec
dérivation de clé ; cette clé **ne quitte jamais l'appareil**.

## 5. Ce que nous ne faisons pas

- Pas de collecte de nom, e-mail, photo de profil, carnet d'adresses.
- **Pas de mesure d'audience ACTIVE** : Firebase Analytics est présent
  mais **coupé au démarrage** (`setConsent(granted: false)`) et ne
  s'active que sur accord explicite. **En revanche, les rapports de
  plantage REMONTENT** : Firebase Crashlytics est actif, indépendamment
  de la mesure d'audience — corrigé tâche 642, les versions antérieures
  de ce document affirmaient qu'aucun rapport de plantage tiers n'était
  intégré, ce qui était faux et devait être déclaré aux magasins.
- Pas de notifications push : `firebase_messaging` est **absent** du
  projet.
- Pas de vente ni de location de données personnelles.
- Pas d'appel automatique aux services de secours, ni de transmission
  de vos données de santé à quiconque.
- Nous ne présentons jamais les données pseudonymisées (classements,
  contributions) comme « anonymes ».

## 6. Destinataires et sous-traitants

| Destinataire | Rôle | Données concernées |
|---|---|---|
| Google Ireland Ltd / Google LLC (Firebase Authentication) <!-- #302 --> | Sous-traitant | Identifiant du compte anonyme ; connexion Google / Apple si choisie |
| Google (Cloud Firestore) | Sous-traitant (hébergement) | Progression, liste de préparation, mesures d'effort, fiche technique de l'appareil, retours, signalements et plaintes de modération |
| Google (Firebase Crashlytics) | Sous-traitant | Rapports de plantage, version du système, modèle d'appareil |
| Google (Firebase Analytics) | Sous-traitant | **Aucune donnée par défaut** — coupé au démarrage, activé sur accord seulement |
| Google (AdMob) | Partenaire publicitaire (identifiants de test dans le dépôt) | Identifiant publicitaire, IP, interactions publicitaires |
| Google Cloud Storage | Sous-traitant | Téléchargement des données de sentier et des mises à jour — **descente uniquement** |
| Fondation OpenStreetMap | Fournisseur de tuiles cartographiques | Adresse IP, tuiles demandées |
| Open-Meteo | Fournisseur météo | Adresse IP, coordonnées du point météo demandé |
| Apple / Google Play | Encaissement des achats intégrés | Traité par le magasin ; **aucune donnée bancaire ne nous parvient** |

> `firebase_storage` est déclaré dans `pubspec.yaml` mais **n'est utilisé
> nulle part** dans `lib/` : il n'est donc pas destinataire de données.
> À retirer du projet, ou à documenter le jour où il sert.

Les traitements Google sont couverts par les *Google Data Processing
Terms*. La **localisation des données** (région Firebase/Firestore) et
le cadre des **transferts hors UE** (clauses contractuelles types,
EU-US Data Privacy Framework) sont documentés dans
`docs/rgpd/transferts-hors-ue.md`.

## 7. Durées de conservation

Les durées ci-dessous correspondent à la politique de rétention
appliquée par le code (service `DataRetentionService`, D4B-02 — source
de vérité). Une purge automatique supprime les données locales
expirées ; le droit à l'effacement (§ 9) permet une suppression
immédiate à votre demande.

| Donnée | Durée | Mécanisme |
|---|---|---|
| Sessions de suivi temps réel (positions partagées) <!-- #303 --> | *Sans objet à ce jour* : la fonction n'est pas active (§ 4.1). Le champ `expiresAt` et l'expiration à **48 h** sont écrits dans le code et s'appliqueront le jour de son ouverture (politique TTL Firestore à activer alors) | Champ `expiresAt` + purge serveur |
| Registre des consentements (serveur) | Tant que le compte existe. C'est une **preuve** : elle doit survivre à la décision elle-même, sinon elle ne prouve rien | Effacement du compte |
| Fiche technique de l'appareil (serveur) | Réécrite à chaque retour au premier plan ; supprimée avec le compte | Effacement du compte |
| Rapports de plantage (Crashlytics) | **90 jours**, politique de rétention de Google | Rétention Firebase |
| Caches cartographiques / météo (local) | **7 jours** (données recalculables) | `purgeExpired()` (RetentionPolicy.cartoCache) |
| Contributions déjà synchronisées (signalements, efforts, kudos, commentaires) — copie locale | **30 jours** après synchronisation | `purgeExpired()` (RetentionPolicy.syncedContributions) ; la donnée de référence vit côté serveur |
| File de synchronisation terminée (local) | **7 jours** | `purgeExpired()` (RetentionPolicy.completedSyncQueue) |
| Données synchronisées serveur (progression, journal texte, checklists) | Tant que le compte pseudonymisé existe | Suppression sur demande / effacement du compte (art. 17) |
| Données locales (photos, santé, contacts, traces fines) | Sous votre seul contrôle | Supprimées avec l'Application ou via l'effacement du compte |
| Identifiant pseudonymisé | Tant que le compte existe | Effacé par l'effacement du compte |
| Contact du notifiant (signalement) | Durée limitée au traitement de la modération | Accès réservé aux modérateurs |

> **[JURISTE] — durées de conservation.** Les durées techniques
> ci-dessus (7 j / 30 j / 48 h) sont des choix de minimisation par
> défaut. Confirmer leur adéquation réglementaire et, le cas échéant,
> la durée de conservation des journaux de modération (DSA) et des
> signalements.

## 8. Données de santé (article 9 RGPD)

Les données de santé éventuellement traitées (fréquence cardiaque via
une ceinture BLE, lecture santé du téléphone) relèvent de l'**article 9
RGPD** (catégorie particulière). À ce titre :

- leur traitement repose sur un **consentement explicite et renforcé**,
  séparé des autres finalités (§ 3) ;
- elles restent **strictement locales** : aucun canal d'envoi vers nos
  serveurs n'existe dans le code. Cette promesse est tenue par **deux
  listes fermées**, et il faut les distinguer :
  1. **la liste du coffre distant** (tâche 612,
     `DocumentsDuCoffreDistant.autorises` dans `cloud_sync_service.dart`) :
     elle ne contient qu'**une seule entrée**, `account`. Tout autre
     document est refusé **avant le réseau et avant toute lecture**, avec
     une raison nommée, et **symétriquement en descente** — une fiche
     déposée par une version antérieure ne peut pas redescendre ;
  2. **la liste de la sauvegarde système Google / Apple** (tâche 617,
     `sauvegarde_systeme.dart`) : **une seule inclusion**
     (`sauvegarde_systeme/`), plus une **exclusion explicite** du dossier
     `medical/` comme second verrou, appliquée aux deux sections
     (`cloud-backup` et `device-transfer`). Une `<include>` désactivant le
     défaut d'Android, tout le reste — base, photos, préférences, tuiles,
     fiche médicale — est **dehors par défaut** ;
- la fiche médicale vit dans son **dossier dédié** (`medical/`), avec
  écriture atomique et `NSURLIsExcludedFromBackupKey` **reposé à chaque
  enregistrement** sur iOS (tâche 615) ;
- seules les **mesures d'effort** des randonnées passées (durée,
  distance, dénivelé) peuvent monter, sous garde du consentement santé
  (§ 4.2) : ce sont des mesures de marche, pas des mesures médicales ;
- elles sont couvertes par une **analyse d'impact** dédiée (AIPD,
  `docs/rgpd/AIPD-capteurs-sante.md`) ;
- vous pouvez les supprimer à tout moment (effacement du compte, § 9, ou
  désinstallation).

> **DEUX TROUS NOMMÉS PLUTÔT QUE CACHÉS** (mesurés tâche 642, à traiter).
> 1. La section `<cross-platform-transfer>` (Android 16 QPR2) **n'est pas
>    déclarée** dans les règles de sauvegarde : son absence vaut
>    autorisation complète vers un appareil non-Android. Bloqué faute de
>    `teamId` Apple. Les deux pages publiées le disent au randonneur.
> 2. Sur iOS, `NSUserDefaults` / `SharedPreferences` **ne peut pas** être
>    exclu d'iCloud par l'éditeur. La morphologie en est sortie
>    (tâche 623) ; il y reste le **solde d'étapes et les réglages** —
>    jamais la fiche médicale, qui est dans un dossier séparé et exclu.

## 9. Vos droits

Conformément au RGPD, vous disposez des droits d'accès, de
rectification, d'effacement, de limitation, d'opposition et de
portabilité sur vos données.

- **Effacement (article 17).** L'Application propose une **suppression
  du compte et de ses données** : elle purge toutes les données locales
  (base locale, caches, consentements) et émet une **demande de
  suppression côté serveur** des documents liés à votre identifiant
  pseudonymisé (opération `deleteAccountData()`, D4B-02). Comme
  l'Application est pseudonyme par conception, cet effacement est simple
  mais **complet et traçable**.
- **Retrait du consentement.** À tout moment, finalité par finalité,
  depuis Réglages → Confidentialité.
- **Exercice des autres droits :** **contact@only1cent.com**, réponse
  sous 30 jours. Compte tenu de la pseudonymisation, nous pourrons vous
  demander des éléments techniques (identifiant de session) pour
  localiser vos données.

Vous pouvez introduire une réclamation auprès de la CNIL
(www.cnil.fr) ou de l'autorité de contrôle de votre pays.

## 10. Sécurité

Accès aux données serveur régi par des règles de sécurité Firestore
testées automatiquement : vos sessions de suivi ne sont inscriptibles
que par vous ; les suiveurs anonymes n'accèdent qu'aux positions d'une
session valide, jamais à votre identifiant ; les signalements de
modération ne sont lisibles/traitables que par un rôle modérateur.
Données locales protégées par le bac à sable de l'appareil et son
chiffrement système.

## 11. Mineurs

L'Application ne s'adresse pas aux enfants de moins de 15 ans et ne
propose aucun contenu qui leur soit destiné.

## 12. Évolutions

Toute modification substantielle de cette politique sera publiée dans
l'Application et sur la fiche store avant son entrée en vigueur.

---

*Document consolidé dans le cadre du lot SEC-D (D4D-01), design D4 CORDO
#86166. Couverture : finalités, données, bases légales, droits (dont
art. 17), durées de conservation (alignées D4B-02), DPO/contact,
données de santé (art. 9), modération DSA (hébergeur), transferts
hors-UE (renvoi D4D-02). **Validation juriste/DPO requise avant
publication.***
