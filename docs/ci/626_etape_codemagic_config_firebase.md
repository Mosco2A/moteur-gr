# La configuration Firebase dans les chaînes Codemagic (tâche 626)

> **ÉTAT : CÂBLÉ DANS `codemagic.yaml`, À DEUX LIGNES PRÈS — et ces deux lignes
> attendent volontairement un geste de Christophe.** Ce document a d'abord été
> écrit comme une étape « à insérer », parce que le lot 621 éditait
> `codemagic.yaml` la même nuit. Le 621 a poussé (tête `4146356`, septième
> chaîne `ios_testflight`), le lot 626 est reparti de sa tête, et l'étape de
> dépôt **plus** le `--dart-define` sont dans les **cinq** chaînes concernées.
>
> Ce qui reste dans le dépôt : le bloc `groups:` de `merge` et d'`android_test`,
> écrit **en commentaire à sa place exacte**, à décommenter dans la même session
> que la création du groupe dans la console. La raison est à la section « Les
> deux lignes qui attendent », et ce n'est pas de la prudence décorative.

## Ce que ça change, en une phrase

Avant, aucun paquet produit par Codemagic ne contenait de configuration
Firebase : l'APK que Christophe installe depuis `android_test` avait un
catalogue distant muet, et rien de ce que publie le collecteur serveur ne
pouvait arriver sur son téléphone.

## Il faut LES DEUX MOITIÉS

Firebase ne parle que si **deux** choses sont vraies au même moment :

1. **le fichier de configuration natif est dans le paquet** — c'est l'étape de
   dépôt ; côté iPhone, le projet Xcode le copie dans le paquet dès que le
   fichier existe (référence ajoutée par ce même lot) ;
2. **l'identifiant de projet est passé en `--dart-define`** — sans lui,
   `FirebaseConfig.resoudre()` rend `null` et `Firebase.initializeApp()` n'est
   **jamais** appelé (tâche 596). C'est le commutateur, indépendant du fichier.

Une seule des deux moitiés donne un paquet muet, avec un fichier de
configuration parfaitement valide dedans. Les deux sont câblées ensemble dans
chaque chaîne, pour qu'on ne puisse pas en oublier une.

## L'étape, telle qu'elle est dans le fichier

```yaml
      - name: Deposer la configuration Firebase (hors depot)
        script: sh scripts/ci/config_firebase.sh deposer android
```

`android`, `ios` ou `tout` selon la chaîne, et un troisième argument `exiger`
pour les chaînes qui livrent un paquet à quelqu'un. Le script :

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
- **refuse de continuer**, avec `exiger`, quand la configuration manque ;
- **prévient sans bloquer**, sans `exiger`, en disant dans le journal que le
  paquet sera utilisable et Firebase muet.

## Chaîne par chaîne, et pourquoi

### Les deux qui compilent une branche — souples

`merge` et `android_test` déposent la configuration **sans** `exiger`. Elles
compilent toute branche et doivent rester vertes même quand le groupe de
variables n'est pas rempli : elles livrent alors un APK utilisable où Firebase
est muet, et le **disent** dans leur journal.

`android_test` est la plus importante du fichier pour ce lot : c'est de là que
vient l'APK que Christophe installe. C'est aussi pour elle que les deux lignes
de `groups:` attendent — voir la section suivante.

> **Le groupe `stepways_firebase` ne contredit pas la garde « aucun secret » de
> `android_test`.** Sa première étape refuse `CM_KEYSTORE`,
> `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`,
> `APP_STORE_CONNECT_*` et `CERTIFICATE_PRIVATE_KEY` — aucune variable Firebase
> n'en fait partie, et cette garde n'a pas bougé. La distinction est réelle :
> une clé de signature permet de **publier au nom de Christophe**, une
> configuration Firebase cliente voyage dans chaque APK distribué et se lit en
> décompressant le paquet. Ce qui protège les données, ce sont les règles de
> sécurité Firestore et Storage.
>
> L'invariante de la tâche 619 interdisait **tout** groupe à `android_test`.
> Elle interdit désormais les **groupes de signature**, ce qui était son
> intention écrite noir sur blanc. Le changement est commenté dans
> `test/structurel/codemagic_entete_ne_mente_pas_619_test.dart`.

### Les trois qui livrent un paquet à quelqu'un — `exiger`

`android_release`, `ios_release` et `ios_testflight` passent `exiger` : la
chaîne **s'arrête** si la configuration manque, au lieu de produire un paquet
muet. Un paquet publié sur un magasin, ou déposé chez un testeur TestFlight,
avec un catalogue vide, est un test pour rien — et personne ne s'en aperçoit
avant de chercher ses sentiers sur le téléphone.

### `ios_compile` et `pr_gate` — RIEN, et c'est voulu

`ios_compile` répond à une seule question — « est-ce que le natif compile ? » —
et ne reçoit **aucun** groupe de variables : sa première étape arrête la chaîne
si un secret de publication apparaît dans son environnement. Elle reste verte
sans configuration Firebase grâce à la phase du projet Xcode ajoutée par ce lot,
qui garantit l'existence du plist avant la copie des ressources. `pr_gate` ne
construit aucun paquet.

### Un groupe par usage

`stepways_firebase` est **distinct** de `stepways_android_signing` et de
`stepways_ios_signing`. Sans cette séparation, `android_test` recevrait les
secrets de signature Apple sans en avoir le moindre besoin — et sa propre garde
l'arrêterait.

## Les deux lignes qui attendent

Dans `merge` et dans `android_test`, sous `environment:`, ce bloc est écrit **en
commentaire**, à sa place exacte :

```yaml
      groups:
        - stepways_firebase
```

**Pourquoi il n'est pas déjà actif, et pourquoi ce n'est pas de la timidité.**
Le groupe `stepways_firebase` n'existe pas encore dans la console Codemagic : il
est à créer à la main. Or la documentation Codemagic **ne dit pas** ce qui
arrive à une chaîne qui réclame un groupe inexistant — build refusé à
l'initialisation, ou variables simplement vides. Les deux réponses circulent,
aucune n'est écrite noir sur blanc. Et `android_test` est la **seule** chaîne
qui livre un installable depuis une branche : celle dont Christophe se sert.
On ne joue pas ça à la devinette.

Les **trois chaînes de livraison**, elles, réclament le groupe dès maintenant
sans aucun risque : elles sont **déjà inertes** aujourd'hui — `android_release`
et `ios_release` ne partent que sur une étiquette de version et s'arrêtent à
leur première étape tant que leur groupe de signature est vide, `ios_testflight`
n'a aucun déclencheur. Si réclamer un groupe absent devait échouer, cela
changerait un arrêt propre en un autre arrêt propre.

**Ordre à respecter :** créer le groupe (section suivante), *puis* décommenter
les deux lignes dans les deux chaînes. Une garde le rappelle dans
`test/structurel/firebase_branche_sur_les_deux_telephones_626_test.dart` ; le
jour où le groupe existe, on décommente et **on retire cette garde-là**, qui n'a
plus d'objet.

## CE QUI RESTE À FAIRE, ET CE N'EST PAS DANS LE DÉPÔT

Créer le groupe d'environnement **`stepways_firebase`** dans la console
Codemagic, avec trois variables. Les **noms** sont ci-dessous ; les **valeurs**
ne s'écrivent nulle part dans le dépôt, ni dans ce fichier.

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

**Tant que ce groupe est vide :** `merge` et `android_test` continuent de
livrer un APK, avec Firebase muet et un avertissement dans le journal ; les
trois chaînes de livraison s'arrêtent proprement à leur première étape de
dépôt.

**Une fois le groupe créé :** décommenter les deux lignes `groups:` de `merge`
et d'`android_test` (section précédente), relancer `android_test`, et lire le
journal comme indiqué ci-dessous. Sans ce décommentage, l'APK reste muet même
avec le groupe rempli.

Le pas à pas pour obtenir les deux fichiers depuis la console Firebase, les
encoder, et remplir Codemagic écran par écran est dans
`data/apport_stepways/MODOP_626_firebase_console_et_codemagic.md` (dépôt
Skynet), à côté de celui du lot 621.

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

En local, sans rien lancer :

```bash
sh scripts/ci/config_firebase.sh etat
```
