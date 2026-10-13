# Signature iPhone de StepWays : ce qu'il reste à faire

> Pour Christophe. Les chaînes `ios_release` et `ios_testflight` de
> `codemagic.yaml` signent désormais comme GR20 : certificat et profils
> **appelés par leur nom** dans Codemagic, et, pour le dépôt sur TestFlight,
> l'intégration App Store Connect **`Only1Cent`**. Aucune clef privée à
> manipuler, aucune variable à saisir.

## Déjà en place, rien à refaire

- **La clef d'API App Store Connect** de l'équipe existe et est branchée dans
  Codemagic (intégration Developer Portal, une clef). La chaîne l'appelle par
  son nom : `Only1Cent`.
- **Le certificat de distribution** de l'équipe existe (type production,
  expire le 01/05/2027). Il a été créé par Codemagic, qui en garde la clef
  privée, sous le nom **`GR20 Distribution`**. C'est le certificat de
  l'équipe, partagé avec GR20 : **ne pas le renommer**, la chaîne de GR20
  l'appelle aussi par ce nom.
- **Les deux identifiants** `com.only1cent.stepways` et
  `com.only1cent.stepways.TrekWidget`, chacun avec App Groups configuré sur
  `group.com.only1cent.stepways`.

## Ce qui tombe : ne plus le faire

- **Générer une clef d'API** (App Store Connect > Users and Access >
  Integrations > Team Keys > Generate API Key) : inutile, l'intégration
  fournit la clef existante.
- **Fabriquer une clef de certificat** (`ssh-keygen … ios_distribution_private_key`)
  et la coller dans `CERTIFICATE_PRIVATE_KEY` : inutile, et ce serait même
  nuisible, car la chaîne aurait alors créé un **second** certificat de
  distribution.
- **Créer le groupe de variables `stepways_ios_signing`** et ses cinq
  variables : plus aucune chaîne ne le réclame. Ne pas le créer.

## Ce qu'il reste à faire : deux profils, puis un contrôle

### 1. Chez Apple : créer les deux profils de provisionnement

Sur developer.apple.com > **Account** > **Certificates, Identifiers & Profiles**
> **Profiles** :

1. Cliquer sur **+**.
2. Sous **Distribution**, cocher **App Store Connect**, puis **Continue**.
3. **App ID** : choisir `com.only1cent.stepways`, puis **Continue**.
4. **Certificate** : cocher le certificat **Apple Distribution** de l'équipe,
   celui qui expire le **2027/05/01**, puis **Continue**.
5. **Provisioning Profile Name** : `stepways_appstore_profile`, puis
   **Generate**. Inutile de télécharger le fichier.

Recommencer les cinq étapes pour l'extension :

- à l'étape 3, choisir `com.only1cent.stepways.TrekWidget` ;
- à l'étape 5, nommer le profil `stepways_trekwidget_appstore_profile`.

Les deux identifiants ont déjà App Groups configuré, et les profils le
portent donc automatiquement. Si Apple propose des options supplémentaires,
garder les valeurs par défaut.

### 2. Chez Codemagic : récupérer les deux profils sous leur nom exact

**Team settings** > **codemagic.yaml settings** > **Code signing identities**
> onglet **iOS provisioning profiles** :

1. Cliquer sur **Fetch profiles**.
2. Dans **App Store profiles**, cocher les deux profils créés à l'étape 1.
3. Donner à chacun ce **Reference name**, à la lettre :

   | Profil (identifiant)                | Reference name                         |
   |-------------------------------------|----------------------------------------|
   | `com.only1cent.stepways`            | `stepways_appstore_profile`            |
   | `com.only1cent.stepways.TrekWidget` | `stepways_trekwidget_appstore_profile` |

4. Cliquer sur **Download selected** (en bas de la liste, faire défiler si
   besoin).
5. Dans la liste, la colonne **Certificate** de chaque profil doit afficher la
   coche verte : c'est Codemagic qui confirme avoir le certificat qui va
   avec.

### 3. Contrôle, une seule fois

- **Code signing identities** > onglet **iOS certificates** : une ligne
  `GR20 Distribution` existe.
- **Team integrations** > **Developer Portal** > **Manage keys** : la clef
  s'appelle exactement `Only1Cent`. Si elle porte un autre nom, me donner ce
  nom ; c'est une ligne à corriger dans `codemagic.yaml`.
- **App Store Connect** > **Apps** : une fiche StepWays existe sur
  `com.only1cent.stepways`. Sans elle, Apple refuse le premier dépôt. Si elle
  n'existe pas encore : **+** > **New App**.

## Puis lancer

Codemagic > StepWays > **Start new build** > workflow
**iOS TestFlight (a lancer a la main)**. Si quelque chose manque encore, la
chaîne s'arrête avant de construire et son message nomme ce qui manque :

| Message d'arrêt (extrait)                          | Ce qu'il veut dire                                   |
|----------------------------------------------------|------------------------------------------------------|
| « Absent de l environnement : APP_STORE_CONNECT_… » | la clef ne s'appelle pas `Only1Cent` (contrôle 3)    |
| « aucune identite de DISTRIBUTION »                | pas de certificat `GR20 Distribution` (contrôle 3)   |
| « MANQUE — le profil '…' »                         | profil pas récupéré sous ce nom (étape 2)            |
| « il couvre … au lieu de … »                       | mauvais App ID choisi à l'étape 1.3                  |
| « emis pour AUCUN certificat »                     | mauvais certificat coché à l'étape 1.4               |
| « ne porte pas le groupe d applications »          | profil créé avant App Groups : le recréer (étape 1)  |

Un nom de référence totalement absent de Codemagic peut aussi être refusé par
Codemagic lui-même, avant la première étape, avec son propre message. Sa
documentation ne dit pas lequel des deux arrive. Dans les deux cas, la cause
est l'étape 2.

Après une correction chez Apple, refaire l'étape 2 pour ce profil-là, sous le
**même** nom : Codemagic garde une copie, et un profil modifié chez Apple
devient invalide.
