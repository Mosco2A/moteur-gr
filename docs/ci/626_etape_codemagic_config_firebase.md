# L'étape Codemagic à insérer pour que Firebase parle (tâche 626)

> **POURQUOI CE FICHIER EXISTE AU LIEU D'UNE MODIFICATION DE `codemagic.yaml`.**
> Le lot 621 modifie `codemagic.yaml` la même nuit que le lot 626 (chaîne
> TestFlight). Deux agents qui éditent le même fichier en parallèle, c'est un
> conflit garanti et un travail écrasé. L'étape est donc **écrite ici,
> verbatim**, avec ses points d'insertion exacts. Elle est à insérer **après**
> le lot 621, par qui fera la réunion des branches.
>
> **RIEN N'EST CASSÉ EN ATTENDANT.** La partie iPhone du lot 626 (référence du
> plist dans le projet Xcode) est autoportante : une phase du projet garantit
> que le fichier existe avant la copie des ressources, donc `ios_compile`
> continue de compiler sur toute branche, avec ou sans configuration Firebase.
> Sans l'insertion ci-dessous, Firebase reste simplement **muet** — exactement
> l'état d'aujourd'hui, sans régression.

## Ce que l'insertion change, en une phrase

Sans elle, aucun paquet produit par Codemagic ne contient de configuration
Firebase, donc rien de ce que le collecteur serveur publie n'arrive sur le
téléphone. Avec elle, l'APK que Christophe installe depuis `android_test` lit
le catalogue distant.

## Les deux moitiés, et il faut LES DEUX

Firebase ne parle que si **deux** choses sont vraies au même moment :

1. **le fichier de configuration natif est dans le paquet** — c'est l'étape de
   dépôt ci-dessous, côté Android (côté iPhone, le projet Xcode s'en charge
   dès que le fichier existe) ;
2. **l'identifiant de projet est passé en `--dart-define`** — sans lui,
   `FirebaseConfig.resoudre()` rend `null` et `Firebase.initializeApp()` n'est
   **jamais** appelé (tâche 596). C'est le commutateur, et il est indépendant
   du fichier.

Une seule des deux moitiés donne un paquet muet. Le script de dépôt le **dit**
dans le journal de build plutôt que de laisser deviner.

## L'étape, verbatim

```yaml
      - name: Deposer la configuration Firebase (hors depot)
        script: sh scripts/ci/config_firebase.sh deposer android
```

Remplacer `android` par `ios` dans une chaîne iPhone, ou par `tout` dans une
chaîne qui produit les deux. Le script :

- écrit `android/app/google-services.json` et/ou
  `ios/Runner/GoogleService-Info.plist` depuis des variables encodées en
  base64 ;
- **refuse de continuer** si `STEPWAYS_FIREBASE_PROJECT_ID` est fourni sans le
  fichier correspondant — c'est la combinaison qui ferme l'application au
  démarrage, parce que l'exception levée par le SDK natif ne se rattrape pas
  depuis Dart ;
- **refuse de continuer** si la configuration vise un autre paquet que
  `com.only1cent.stepways`, un autre projet que celui de
  `STEPWAYS_FIREBASE_PROJECT_ID`, ou le projet `gr20-app` (#326 divorce) ;
- **prévient sans bloquer** quand les fichiers sont là mais que
  l'identifiant de projet manque : le paquet sera utilisable et Firebase muet.

## Où l'insérer, chaîne par chaîne

Les numéros de ligne sont ceux du commit `2393796` ; **le lot 621 les fera
bouger, donc les ancres de texte sont ce qui fait foi.**

### 1. `android_test` — LA PLUS IMPORTANTE

C'est la seule chaîne qui livre un APK installable depuis une branche
d'intégration : c'est de là que vient le paquet que Christophe installe.

**a. Ajouter le groupe de variables** — remplacer (ligne 195) :

```yaml
    environment:
      flutter: stable
    scripts:
```

par :

```yaml
    environment:
      flutter: stable
      groups:
        - stepways_firebase
    scripts:
```

> **Ce groupe ne contredit pas la garde « aucun secret » de cette chaîne.**
> La première étape de `android_test` refuse `CM_KEYSTORE`,
> `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`,
> `APP_STORE_CONNECT_*` et `CERTIFICATE_PRIVATE_KEY` — aucune des variables
> Firebase n'en fait partie, et la garde reste inchangée. La distinction est
> réelle : une clé de signature permet de **publier au nom de Christophe**,
> une configuration Firebase cliente voyage dans chaque APK distribué et se
> lit en décompressant le paquet. Ce qui protège les données, ce sont les
> règles de sécurité Firestore et Storage.

**b. Insérer l'étape de dépôt** juste avant la construction — avant (ligne
261) :

```yaml
      - name: Build APK debug
        script: flutter build apk --debug
```

**c. Et passer le commutateur** : remplacer ces deux lignes par :

```yaml
      - name: Deposer la configuration Firebase (hors depot)
        script: sh scripts/ci/config_firebase.sh deposer android

      - name: Build APK debug
        script: |
          flutter build apk --debug \
            --dart-define=STEPWAYS_FIREBASE_PROJECT_ID="${STEPWAYS_FIREBASE_PROJECT_ID:-}"
```

> Si la variable est vide, `--dart-define=STEPWAYS_FIREBASE_PROJECT_ID=` est
> passé avec une valeur vide : `FirebaseConfig` traite la chaîne vide comme une
> absence (`_injecte.isEmpty`). La chaîne reste donc verte sans le groupe, et
> livre un APK en mode local. Aucun `if` n'est nécessaire.

### 2. `android_release` — AAB publié au Play Store

Même chose. Avant (ligne 547) :

```yaml
      - name: Build AAB release signe
        script: flutter build appbundle --release
```

Remplacer par :

```yaml
      - name: Deposer la configuration Firebase (hors depot)
        script: sh scripts/ci/config_firebase.sh deposer android

      - name: Build AAB release signe
        script: |
          flutter build appbundle --release \
            --dart-define=STEPWAYS_FIREBASE_PROJECT_ID="$STEPWAYS_FIREBASE_PROJECT_ID"
```

Et ajouter `stepways_firebase` à la liste `groups:` existante (ligne 491) :

```yaml
      groups:
        - stepways_android_signing
        - stepways_firebase
```

> Ici **pas** de `:-` : une release publiée au magasin sans Firebase serait une
> release muette, livrée à des inconnus. Mieux vaut que la chaîne s'arrête sur
> une variable absente.

### 3. `ios_release` — IPA App Store

Ajouter `stepways_firebase` à la liste `groups:` de la chaîne, puis avant
(ligne 632) :

```yaml
      - name: Build IPA release signe
        script: |
          flutter build ipa --release \
            --export-options-plist=/Users/builder/export_options.plist
```

Remplacer par :

```yaml
      - name: Deposer la configuration Firebase (hors depot)
        script: sh scripts/ci/config_firebase.sh deposer ios

      - name: Build IPA release signe
        script: |
          flutter build ipa --release \
            --export-options-plist=/Users/builder/export_options.plist \
            --dart-define=STEPWAYS_FIREBASE_PROJECT_ID="$STEPWAYS_FIREBASE_PROJECT_ID"
```

### 4. La chaîne TestFlight du lot 621

Même traitement que `ios_release` : groupe `stepways_firebase`, étape
`sh scripts/ci/config_firebase.sh deposer ios` avant la construction, et
`--dart-define=STEPWAYS_FIREBASE_PROJECT_ID="$STEPWAYS_FIREBASE_PROJECT_ID"`
ajouté à la commande de build. **Un paquet envoyé à TestFlight sans Firebase
serait un test pour rien** : c'est précisément le catalogue distant que
Christophe doit pouvoir vérifier sur son téléphone.

### 5. `merge` — recommandé, pas indispensable

`merge` construit un APK debug sur `main` seulement. Même modification que
`android_test` si on veut que cet APK aussi lise le catalogue. Sans elle, il
reste muet, ce qui n'est pas une régression.

### 6. `ios_compile` et `pr_gate` — NE RIEN TOUCHER, ET C'EST VOULU

`ios_compile` répond à une seule question — « est-ce que le natif compile ? » —
et ne doit recevoir **aucun** groupe de variables (sa première étape le
vérifie et arrête la chaîne sinon). Elle reste verte sans configuration
Firebase grâce à la phase du projet Xcode ajoutée par ce lot. `pr_gate` ne
construit aucun paquet.

## Les variables à créer dans Codemagic

Groupe d'environnement **`stepways_firebase`**. Les **noms** sont ci-dessous ;
les **valeurs** ne s'écrivent nulle part dans le dépôt, ni dans ce fichier.

- **`STEPWAYS_GOOGLE_SERVICES_JSON`** — le fichier `google-services.json`
  encodé en base64, sur une seule ligne. Variable **secrète** (case cochée).
- **`STEPWAYS_GOOGLE_SERVICE_INFO_PLIST`** — le fichier
  `GoogleService-Info.plist` encodé en base64, sur une seule ligne. Variable
  **secrète** (case cochée).
- **`STEPWAYS_FIREBASE_PROJECT_ID`** — l'identifiant du projet Firebase de
  StepWays. **Pas** une variable secrète : il faut pouvoir la relire dans le
  journal de build pour diagnostiquer.

> `STEPWAYS_TRAIL_DATA_BUCKET` n'est **pas** nécessaire : `TrailDataSource`
> porte déjà la bonne valeur par défaut. Ne la créer que si l'espace de
> stockage change.

Le pas à pas complet pour obtenir les deux fichiers depuis la console Firebase,
et pour les encoder, est dans `data/apport_stepways/` du dépôt Skynet
(`MODOP_626_firebase_console_et_codemagic.md`).

## Comment savoir que ça a marché, sans deviner

Dans le journal du build Codemagic :

- `Android : google-services.json ecrit dans android/app/.` puis, côté Gradle,
  `Firebase : google-services.json trouve, greffons poses.` — les deux lignes,
  ou Firebase est muet ;
- **absence** de la ligne `AVERTISSEMENT — les fichiers de configuration sont
  en place mais STEPWAYS_FIREBASE_PROJECT_ID est ABSENT.`

Sur le téléphone, une fois l'APK installé : **Réglages → Cloud** doit afficher
« Services en ligne actifs ». S'il affiche l'état dégradé, le journal
`[FirebaseService]` nomme la cause — `MODE LOCAL` (rien n'a été fourni) ou
`MODE LOCAL FORCE` (fourni mais l'initialisation a échoué). Ne pas confondre
les deux : c'est ce qui rend le diagnostic possible.
