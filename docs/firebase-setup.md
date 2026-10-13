# Configuration Firebase — StepWays

> **ÉTAT AU 29/09/2026 (tâche 626, GO-73).** Le projet existe, les deux
> applications existent, et les greffons qui lisent leur configuration sont
> posés. **CE QUE CE DOCUMENT AFFIRMAIT DE FAUX, ET QUI A COÛTÉ DES JOURS :**
> il écrivait que « leurs fichiers de configuration sont dans le dépôt » et
> qu'ils étaient « présents depuis la tâche 604 ». C'était **faux depuis le
> premier jour** — `.gitignore` les exclut explicitement (lignes 64-65) et
> aucun des deux n'a jamais été suivi par git. C'est en lisant ce document
> qu'on a cru Firebase branché alors qu'il était **muet sur les deux
> téléphones**. Le tuyau est branché depuis la tâche 626 : les deux fichiers
> arrivent **à la fabrication**, depuis des variables Codemagic, et ne sont
> **jamais** dans le dépôt.
>
> Ce qui reste exige la **console web** et n'est pas automatisable : voir « Ce
> qu'il reste à faire à la main » en fin de document. Tant que ce reste n'est
> pas fait, l'app tourne en **mode local** (état explicite dans Réglages →
> Cloud, écrans follow/profil dégradés proprement — voir
> `CloudUnavailableNotice`).

## Règles non négociables

- **Projet Firebase DÉDIÉ StepWays**, identifiant `stepways-app`, créé pour
  ce produit. **JAMAIS le projet `gr20-app`** ni aucun projet de l'ancienne
  application : zéro mutualisation de données, de comptes ou de quotas avec
  le legacy (#326 divorce).
- Emplacement des ressources (Firestore / Storage) : **europe-west** —
  cohérent RGPD (docs/rgpd/registre-traitements.md, transferts). **CE CHOIX
  EST IRRÉVERSIBLE** : l'emplacement des ressources d'un projet Firebase ne
  se change pas après coup, il faudrait recréer le projet.
- Identifiant de paquet : **`com.only1cent.stepways`**, le MÊME sur les deux
  plateformes. **DÉFINITIF après publication au store.** Avant la tâche 604
  les deux plateformes divergeaient (`com.only1cent.moteur_gr` sur Android,
  `com.only1cent.moteurGr` sur iOS) — c'est corrigé, et un test le garde.

## Où vit la configuration, et pourquoi elle n'est PAS dans le dépôt

- **`android/app/google-services.json`** — **hors dépôt**, exclu par
  `.gitignore`. Porte l'identifiant et le numéro de projet, le nom de paquet,
  la clé d'API cliente et le nom du bucket. Il arrive **à la fabrication**,
  écrit par `scripts/ci/config_firebase.sh deposer android` depuis la variable
  `STEPWAYS_GOOGLE_SERVICES_JSON` (tâche 626). Sans lui, les greffons Gradle ne
  se posent pas (étape 2 bis) et Firebase est muet côté Android.
- **`ios/Runner/GoogleService-Info.plist`** — **hors dépôt** lui aussi, mêmes
  informations, même mécanisme (`deposer ios`, variable
  `STEPWAYS_GOOGLE_SERVICE_INFO_PLIST`). Le projet Xcode le **référence** dans
  la phase de copie des ressources de la cible `Runner` depuis la tâche 626 :
  avant, il n'était référencé nulle part, donc même déposé à la main il
  n'entrait pas dans le paquet et le SDK ne lisait rien.
- **`lib/firebase_options.dart`** — **absent, et c'est voulu.**
  `FirebaseService.initialize()` appelle `Firebase.initializeApp()` **sans
  options** : sur Android et iOS le SDK lit alors les deux fichiers natifs
  ci-dessus. En générer un en plus dupliquerait la même information dans
  `lib/`, où une invariante de la tâche 596
  (`test/comportement/verite_596_plantages_test.dart`) interdit toute clé
  en clair. La configuration native suffit aux deux plateformes des
  stores ; ce fichier ne redeviendra nécessaire que pour une cible web ou
  desktop.

**Ce que contiennent ces deux fichiers, et ce qu'ils ne contiennent pas.**
Uniquement des identifiants **clients publics** : identifiant et numéro de
projet, nom de paquet, clé d'API cliente, nom du bucket. Aucun compte de
service, aucune clé privée, aucun jeton d'administration. Ces valeurs
partent de toute façon dans l'APK et l'IPA : elles sont lisibles par
quiconque décompresse le paquet publié. Ce qui protège réellement les
données, ce sont les **règles de sécurité Firestore et Storage**, la
restriction de la clé par nom de paquet et empreinte de signature, et App
Check — pas la discrétion de ces fichiers.

> **CE QUI A ÉTÉ TRANCHÉ, ET QUI NE SE REDISCUTE PAS.** Les versionner serait
> techniquement sans conséquence, et ce document l'a longtemps écrit. La règle
> de Christophe est néanmoins **sans exception : aucune valeur de configuration
> ni aucun identifiant en clair dans le dépôt.** Les deux fichiers restent donc
> dans `.gitignore` et arrivent par variables d'environnement. Ce qui était
> cassé n'était pas ce choix, c'était qu'**aucune chaîne ne les fournissait** —
> le trou que la tâche 626 ferme.

> À noter : ni l'un ni l'autre ne porte de `oauth_client` /
> `REVERSED_CLIENT_ID`, parce qu'aucune empreinte SHA-1 n'est encore
> déclarée. **La connexion Google restera donc inopérante** jusqu'à ce que
> l'empreinte de la clé de signature soit ajoutée (voir le reste à faire).

## Prérequis

```bash
npm i -g firebase-tools        # 15.8.0 utilisée pour la tâche 604
firebase login                 # compte Google dédié au projet
```

## Étapes

### 1. Créer le projet — FAIT

Projet **StepWays**, identifiant `stepways-app`. Créé et vérifié le
27/09/2026. Analytics non activé — l'app n'embarque pas d'analytics
(cf. docs/rgpd/).

### 2. Créer les deux applications et récupérer leur configuration — FAIT

```bash
firebase apps:create ANDROID "StepWays Android" \
  --project stepways-app --package-name com.only1cent.stepways
firebase apps:create IOS "StepWays iOS" \
  --project stepways-app --bundle-id com.only1cent.stepways

firebase apps:sdkconfig ANDROID <app-id-android> --project stepways-app \
  --out android/app/google-services.json
firebase apps:sdkconfig IOS <app-id-ios> --project stepways-app \
  --out ios/Runner/GoogleService-Info.plist
```

> `firebase apps:list --project stepways-app` redonne les deux identifiants
> d'application à tout moment — inutile de les recopier ailleurs.

### 2 bis. Les greffons Gradle — FAIT (tâche 604), rendus CONDITIONNELS (tâche 619)

**Sans eux, les fichiers ci-dessus ne sont JAMAIS lus.** Ils étaient
absents : `Firebase.initializeApp()` échouait donc à 100 % des démarrages
Android et l'app repassait en mode local avec la raison
`echecInitialisation`. `com.google.gms.google-services` et
`com.google.firebase.crashlytics` sont désormais déclarés dans
`android/settings.gradle.kts` et appliqués dans
`android/app/build.gradle.kts`.

> **TÂCHE 619 — ils ne sont plus posés EN DUR, et voici ce que cela change pour
> vous.** `com.google.gms.google-services` **refuse de fonctionner** sans
> `android/app/google-services.json` : il arrête le build avec
> *« File google-services.json is missing. The Google Services Plugin cannot
> function without it. »* Or ce fichier est exclu du dépôt (`.gitignore`) et
> **aucune** chaîne ne le fournit — `codemagic.yaml` ne le mentionne nulle part.
> Résultat mesuré le 28/09 : **depuis la tâche 604, plus aucun build Android ne
> passait**, ni en local ni sur le workflow `merge` qui compile pourtant un APK
> debug. Personne ne l'avait vu parce que personne n'avait recompilé Android
> depuis.
>
> Les deux greffons sont maintenant posés **sous condition de présence du
> fichier**. Avec le fichier : rien ne change. Sans lui : le paquet se construit
> quand même, l'application s'installe, et le catalogue distant reste muet — le
> repli sur les sentiers compilés (acquis du lot 605) prend le relais. Gradle le
> dit à voix haute au build (`logger.warn`).
>
> **Pour rétablir Firebase sur un poste neuf**, les applications existent déjà
> côté console (étape 2 ci-dessus, `FAIT`) : il suffit de redemander leur
> configuration.
>
> ```bash
> firebase apps:list --project stepways-app
> firebase apps:sdkconfig ANDROID <app-id-android> --project stepways-app \
>   --out android/app/google-services.json
> firebase apps:sdkconfig IOS <app-id-ios> --project stepways-app \
>   --out ios/Runner/GoogleService-Info.plist
> ```

### 2 ter. La configuration arrive à la FABRICATION — FAIT (tâche 626)

**C'était le mur, et il était devant tous les autres.** Les deux fichiers sont
hors dépôt, et **aucune chaîne Codemagic ne les fournissait** : l'APK sortait,
Firebase y dormait, et côté iPhone `GoogleService-Info.plist` n'était référencé
nulle part dans `ios/Runner.xcodeproj/project.pbxproj`. Rien de ce que publie
le collecteur serveur ne pouvait donc arriver sur un téléphone.

Ce que la tâche 626 a posé :

- **`scripts/ci/config_firebase.sh`** — écrit les fichiers depuis des variables
  base64 (`deposer`), garantit l'existence du plist pour que la compilation
  iPhone passe même sans configuration (`garantir-ios`), et dit l'état (`etat`).
  Utilisable en local :

  ```bash
  scripts/ci/config_firebase.sh etat
  ```

- **la référence du plist dans le projet Xcode**, dans la phase de copie des
  ressources de la cible `Runner`, plus une phase de script qui garantit le
  fichier **avant** cette copie et le déclare en sortie — sans quoi xcodebuild
  s'arrête sur « Build input file cannot be found » sur tout clone neuf.
- **l'invariante** `test/structurel/firebase_branche_sur_les_deux_telephones_626_test.dart`,
  qui suit la chaîne de renvois du `pbxproj` comme Xcode la suit (cible →
  phases → PBXBuildFile → PBXFileReference) et **démontre** qu'elle devient
  rouge quand on casse le projet.

- **le câblage des chaînes Codemagic** : cinq des sept chaînes déposent la
  configuration et passent `--dart-define=STEPWAYS_FIREBASE_PROJECT_ID` ;
  `ios_compile` et `pr_gate` ne reçoivent rien, et c'est voulu. Détail chaîne
  par chaîne, et raison de chaque choix, dans
  `docs/ci/626_etape_codemagic_config_firebase.md`.

**Ce qui reste, et ce n'est pas dans le dépôt** : créer le groupe
d'environnement `stepways_firebase` dans la console Codemagic (trois
variables, noms dans le document ci-dessus). **Tant qu'il est vide, Firebase
reste muet** — les chaînes de branche livrent quand même un APK utilisable en
le disant dans leur journal, les trois chaînes de livraison s'arrêtent
proprement.

### 3. Brancher l'init dans le code

**Fait à la tâche 596 (C4) : le commutateur existe enfin.** Avant, aucune
configuration de sentier ne renseignait `firebaseProjectId` et **aucun moyen
n'existait de le renseigner** — `Firebase.initializeApp()` n'était donc jamais
exécuté, à 100 % des démarrages, avec pour conséquence zéro rapport de plantage
et zéro statistique.

L'identifiant se passe désormais **au build**, comme les identifiants AdMob, et
**n'est jamais écrit dans le dépôt** (un test balaie `lib/` et refuse toute clé
en clair) :

```bash
flutter build apk --release \
  --dart-define=STEPWAYS_FIREBASE_PROJECT_ID=stepways-prod
```

Sans cette variable, l'app démarre **normalement** en mode local et l'écrit dans
ses journaux (`[FirebaseService] MODE LOCAL : …`). Elle ne plante jamais pour une
configuration manquante. La cause est nommée dans
`FirebaseService.raisonIndisponible` : `configurationAbsente` (rien n'a été
fourni) ou `echecInitialisation` (fourni mais cassé) — ne pas confondre les deux
est ce qui rend le diagnostic possible.

**Il n'y a rien à écrire de plus dans `firebase_service.dart`** :
`Firebase.initializeApp()` est appelé **sans options**, et le SDK lit alors les
deux fichiers natifs. Ce document affirmait que ce point était « clos depuis la
tâche 604 » parce que « les deux fichiers de configuration natifs sont en
place » : ils ne l'étaient pas, et c'est l'étape 2 ter qui les met en place, à
la fabrication.

> **LE PIÈGE À CONNAÎTRE, ET IL N'EST PAS RATTRAPABLE EN DART.** Passer
> `--dart-define=STEPWAYS_FIREBASE_PROJECT_ID=...` **sans** le fichier de
> configuration natif fait appeler `Firebase.initializeApp()` sur un SDK qui
> n'a pas ses options : il lève une exception **native** que le `try/catch` de
> `FirebaseService.initialize` ne rattrape pas, et l'application se ferme au
> démarrage. `scripts/ci/config_firebase.sh` **arrête la fabrication** sur
> cette combinaison, plutôt que de livrer un paquet qui se ferme.

**Les filets d'erreur, eux, sont déjà posés** (`ErrorNets`, appelé en première
ligne de `main()`) : dès que Firebase démarre, le rapporteur Crashlytics est
branché automatiquement et les plantages remontent.

### 3 bis. Où vivent les données de sentier (tâche 604)

Le catalogue et le téléchargeur de mises à jour portaient **chacun, en dur**,
une adresse vers `storage.googleapis.com/moteur-gr` — un espace de stockage
qui **n'a jamais existé** (404 vérifié sur la racine comme sur l'objet). Deux
copies d'une même information fausse.

Les deux lisent maintenant `lib/core/config/trail_data_source.dart`, seul
endroit du moteur qui sait où sont les données, surchargeable au build comme
l'identifiant de projet :

```bash
flutter build appbundle --release \
  --dart-define=STEPWAYS_FIREBASE_PROJECT_ID=stepways-app \
  --dart-define=STEPWAYS_TRAIL_DATA_BUCKET=stepways-app.firebasestorage.app
```

Arborescence attendue dans le bucket, reprise de celle du GR20
(`GR20/app/lib/core/data/remote_data_service.dart`) pour que les deux
produits se relisent l'un l'autre :

```
data/manifest.json            # liste des sentiers : id, version, hash, taille, filePath
data/<sentier>/<version>.json # données d'un sentier
```

### 4. Déployer règles + index Firestore

Les règles (P0-1) et les index sont DÉJÀ dans le repo, testés sous
émulateur (P0-2, 45 verts). **Exige que Firestore ait été provisionné dans
la console au préalable** (voir le reste à faire) :

```bash
firebase deploy --only firestore:rules,firestore:indexes --project stepways-app
```

### 5. Activer la purge TTL des sessions de suivi

Console → Firestore → TTL : politique sur le groupe de collections
`follow_sessions`, champ `expiresAtTs`, et sur `follow_sessions_public`,
champ `expiresAtTs`. (Engagement de rétention 48 h des docs RGPD.)

### 6. Authentification

Console → Authentication → activer : Anonyme, Google, Apple.
Rappel minimisation : le code ne demande AUCUN scope nom/e-mail à
Apple et n'enregistre aucune PII (#81775) — ne pas « enrichir » la
config au-delà.

### 7. Vérifications de fin

```bash
flutter run                          # Réglages → Cloud = "Services en ligne actifs"
# - créer une session de suivi, ouvrir le lien web en navigation privée
# - vérifier qu aucun trekkerUserId n apparait dans le doc public (DevTools réseau)
npx -y firebase-tools@13.35.1 emulators:exec --only firestore --project demo-stepways \
  "npm --prefix firestore-tests test"   # doit rester vert
```

## Ce qu'il reste à faire à la main — console web OBLIGATOIRE

Ces points **ne sont pas automatisables**, et ce n'est pas un manque de
volonté : le `firebase` CLI **n'a aucun groupe de commandes `storage`** (vérifié
sur la version 15.8.0 : seuls `apphosting:*` et `setup:emulators:storage`
existent), et `gcloud` refuse toute commande dans cet environnement
(*Reauthentication failed, cannot prompt during non-interactive execution*).
Le premier point est **bloquant** : sans lui rien ne peut être publié dans
l'espace de stockage, et le catalogue distant reste vide.

1. **Provisionner Firebase Storage, en choisissant `europe-west`.**
   Console → `stepways-app` → Storage → « Commencer ». L'emplacement demandé
   au premier provisionnement **fixe celui de tout le projet et ne se change
   plus** : prendre **europe-west**, comme les deux autres projets récents, par
   cohérence RGPD. Le bucket attendu est `stepways-app.firebasestorage.app` ;
   c'est le nom que portent déjà les fichiers de configuration et
   `TrailDataSource`. Vérifié le 27/09 : ce bucket **n'existe pas encore**
   (404 sur `firebasestorage.app` comme sur `appspot.com`).

2. **Provisionner Firestore**, même emplacement, avant tout
   `firebase deploy --only firestore:rules,firestore:indexes`.

3. **Téléverser le premier `data/manifest.json`**, et les données de sentier
   qu'il déclare. Tant qu'il est absent, le catalogue distant échoue — mais
   il échoue désormais **en le disant**, avec une possibilité de réessayer, au
   lieu d'afficher une liste vide muette (tâche 604).

4. **Ajouter l'empreinte SHA-1 / SHA-256** de la clé de signature de release
   à l'application Android, dans les paramètres du projet. Sans elle,
   `google-services.json` ne contient aucun `oauth_client` et **la connexion
   Google ne fonctionne pas**. Après l'ajout, régénérer le fichier avec
   `firebase apps:sdkconfig ANDROID <app-id> --out android/app/google-services.json`,
   **puis réencoder et remettre à jour la variable Codemagic**
   `STEPWAYS_GOOGLE_SERVICES_JSON` : le fichier local ne part nulle part, c'est
   la variable qui alimente la fabrication (étape 2 ter).

5. **Politique TTL** des sessions de suivi (étape 5 ci-dessus) et
   **méthodes d'authentification** (étape 6) : console uniquement.

## Ce qui reste volontairement HORS de cette procédure

- Keystore Android réel + `android/key.properties` (P1-3, wagon 3).
- Secrets de signature CI (codemagic.yaml, P1-5 — groupes d'env vars).
- **La création du groupe de variables `stepways_firebase` dans Codemagic** :
  console Codemagic uniquement, trois variables, noms dans
  `docs/ci/626_etape_codemagic_config_firebase.md`. Le câblage des chaînes,
  lui, est fait.
- AdMob réel / ATT / CMP (docs/rgpd/data-safety.md — prérequis stores).
- Renommage du **nom Dart interne** du paquet (`pubspec name: moteur_gr`,
  417 fichiers `package:moteur_gr/`) : chantier à part, **ne bloque aucune
  publication** — l'identifiant vu par les stores est celui de l'étape 2.
