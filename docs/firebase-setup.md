# Configuration Firebase — StepWays

> **ÉTAT AU 27/09/2026 (tâche 604, GO-69).** Les étapes 1, 2 et 2 bis sont
> **FAITES ET VÉRIFIÉES**. Le projet existe, les deux applications existent,
> leurs fichiers de configuration sont dans le dépôt et les greffons qui
> les lisent sont posés. Ce qui reste exige la **console web** et n'est pas
> automatisable : voir « Ce qu'il reste à faire à la main » en fin de
> document. Tant que ce reste n'est pas fait, l'app tourne en **mode local**
> (état explicite dans Réglages → Cloud, écrans follow/profil dégradés
> proprement — voir `CloudUnavailableNotice`).

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

## État de la configuration versionnée

- **`android/app/google-services.json`** — présent depuis la tâche 604.
  Porte l'identifiant et le numéro de projet, le nom de paquet, la clé
  d'API cliente et le nom du bucket.
- **`ios/Runner/GoogleService-Info.plist`** — présent depuis la tâche 604.
  Les mêmes informations, côté iOS.
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
Check — pas la discrétion de ces fichiers. Les versionner est la pratique
courante et ne crée aucune exposition nouvelle.

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

### 2 bis. Les greffons Gradle — FAIT (tâche 604)

**Sans eux, les fichiers ci-dessus ne sont JAMAIS lus.** Ils étaient
absents : `Firebase.initializeApp()` échouait donc à 100 % des démarrages
Android et l'app repassait en mode local avec la raison
`echecInitialisation`. `com.google.gms.google-services` et
`com.google.firebase.crashlytics` sont désormais déclarés dans
`android/settings.gradle.kts` et appliqués dans
`android/app/build.gradle.kts`.

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

**Ce point est clos depuis la tâche 604** : `Firebase.initializeApp()` est
appelé sans options et les deux fichiers de configuration natifs sont en
place, lus au build par les greffons de l'étape 2 bis. Il n'y a donc plus
rien à écrire dans `firebase_service.dart`.

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
   `firebase apps:sdkconfig ANDROID <app-id> --out android/app/google-services.json`.

5. **Politique TTL** des sessions de suivi (étape 5 ci-dessus) et
   **méthodes d'authentification** (étape 6) : console uniquement.

## Ce qui reste volontairement HORS de cette procédure

- Keystore Android réel + `android/key.properties` (P1-3, wagon 3).
- Secrets de signature CI (codemagic.yaml, P1-5 — groupes d'env vars).
- AdMob réel / ATT / CMP (docs/rgpd/data-safety.md — prérequis stores).
- Renommage du **nom Dart interne** du paquet (`pubspec name: moteur_gr`,
  417 fichiers `package:moteur_gr/`) : chantier à part, **ne bloque aucune
  publication** — l'identifiant vu par les stores est celui de l'étape 2.
