# StepWays sur l'App Store — la fiche, champ par champ

> Pour Christophe, à garder ouvert à côté de la page App Store Connect.
> Préparé le 07/10/2026 (lot fiche magasin et préparation Apple), sur la
> branche d'intégration `52fb8ac2`.
>
> Chaque champ porte l'une de ces trois mentions :
> - **À COLLER** : le texte exact, ou le fichier du dépôt qui le contient ;
> - **À PRODUIRE** : ce qui manque, et comment le faire ;
> - **DÉCISION DE CHRISTOPHE** : les options et ce qu'entraîne chacune.
>
> Les fichiers `.txt` cités sous `assets/store/ios/` se collent **tels quels**,
> du premier au dernier caractère.

---

## 1. Informations sur l'app (App Information)

### Nom — À COLLER
Un par langue : `assets/store/ios/title_{fr,en,de,it,es}.txt`.

| Langue | Texte | Car. / 30 |
|---|---|---|
| fr | `StepWays - Rando hors ligne` | 27 |
| en | `StepWays - Offline hiking` | 25 |
| de | `StepWays - Offline-Wandern` | 26 |
| it | `StepWays - Trekking offline` | 27 |
| es | `StepWays - Senderismo offline` | 29 |

> **DÉCISION DE CHRISTOPHE — « hors ligne » dans le titre.** Le titre que vous
> avez validé est conservé. Mais la carte ne sait pas encore afficher son fond
> sans réseau (voir § 8, point 7). En mode avion, la position, la trace, les
> étapes, les points d'intérêt, les alertes, le carnet et le planning
> marchent ; le fond de carte reste vide.
> - **Garder** : c'est défendable, car l'essentiel marche hors ligne. Mais un
>   reviewer qui teste en mode avion peut le relever (règle 2.3.1, métadonnées
>   exactes).
> - **Changer jusqu'au correctif de carte** : par exemple
>   `StepWays - Rando et trek GPS` (28 caractères). Il faudra alors
>   revérifier que les mots-clés ne répètent pas « trek » ni « GPS ».

### Sous-titre — À COLLER
`assets/store/ios/subtitle_{langue}.txt`

| Langue | Texte | Car. / 30 |
|---|---|---|
| fr | `GPS, étapes et carnet de trek` | 29 |
| en | `GPS, stages and trek journal` | 28 |
| de | `GPS, Etappen und Tourenbuch` | 27 |
| it | `GPS, tappe e diario di viaggio` | 30 |
| es | `GPS, etapas y cuaderno de ruta` | 30 |

L'ancien sous-titre disait « Carte, GPS et planning offline ». Il promettait
une carte hors ligne qui n'existe pas encore.

### Langue principale — À COLLER
`Français (France)`

### Identifiant de lot (Bundle ID) — déjà fixé
`com.only1cent.stepways`. C'est la valeur de `ios/Runner.xcodeproj`, et elle
n'est pas modifiable après création.

### SKU — DÉCISION DE CHRISTOPHE
C'est un identifiant interne, jamais montré au public, et **non modifiable**
ensuite. Proposition : `stepways-ios`.

### Catégories — DÉCISION DE CHRISTOPHE
- **Principale, proposée : Navigation.** C'est ce que fait l'application
  pendant la marche.
- **Secondaire, au choix :**
  - **Voyages** : la préparation, les hébergements, la météo ;
  - **Sports** : on y rencontre les applications de randonnée concurrentes.

### Droits sur le contenu (Content Rights) — DÉCISION DE CHRISTOPHE
Question posée : « Votre app contient-elle, affiche-t-elle ou accède-t-elle à
du contenu de tiers ? »

- La réponse honnête est **Oui**. L'application affiche les tuiles
  **OpenStreetMap** (licence ODbL, attribution affichée, garde
  `attribution_osm_647_test.dart`) et la météo **Open-Meteo** (CC BY 4.0).
- Il faut ensuite cocher « J'ai les droits nécessaires ». Les deux licences
  l'autorisent, attribution comprise.

### Classification par âge — À COLLER, avec un point À VÉRIFIER
Réponses au questionnaire :

- Violence, horreur, contenu sexuel, grossièretés, drogues, alcool, tabac,
  jeux d'argent, concours : **Aucun**.
- Accès libre au web : **Non**.
- Informations médicales : **Non**. La fiche d'urgence contient les données
  du randonneur lui-même, et l'application ne donne aucun conseil médical.
- Publicité : **Oui** (AdMob, voir § 8).
- **À VÉRIFIER — contenu généré par les utilisateurs.** Le dépôt contient des
  fonctions communautaires avec modération : commentaires de points
  d'intérêt, signalements, activités. Si un randonneur peut voir dans
  l'application un texte écrit par un autre, répondre **Oui**. Il faut alors
  que le signalement et le blocage soient atteignables (règle 1.2). Sinon,
  répondre **Non**.
- Classification attendue : **4+**, ou 9+ si le contenu des utilisateurs est
  visible.

### Licence (CLUF) — À COLLER
Laisser le **contrat de licence standard d'Apple**.

---

## 2. Tarifs et disponibilité

### Prix de l'app — À COLLER
**Gratuite.** Le sentier se débloque par un achat intégré (§ 6).

### Pays — DÉCISION DE CHRISTOPHE
Tous les pays, ou d'abord les pays des cinq langues (France, Belgique,
Suisse, Canada, Royaume-Uni, Irlande, États-Unis, Allemagne, Autriche,
Italie, Espagne). La déclaration de chiffrement à NO (§ 7) évite la
déclaration de chiffrement française que demande Apple pour la France.

---

## 3. Confidentialité de l'app (App Privacy)

### URL de la politique de confidentialité — À COLLER
Le champ existe **pour chaque langue**. Ces pages répondent 200, d'après la
mesure de l'audit du 07/10.

| Langue de la fiche | Adresse |
|---|---|
| fr | `https://only1cent.com/stepways/privacy` |
| en, de, it, es | `https://only1cent.com/stepways/privacy-en` |

C'est la règle de `lib/core/branding/stepways_legal.dart` : le français pour
le français, l'anglais pour les autres langues.

### Questionnaire « Collecte de données » — DÉCISION DE CHRISTOPHE (avec un juriste)
La référence du dépôt est `docs/store/app-privacy-att.md`, **mais elle date du
15/06/2026** et elle ne colle plus au code sur deux points.

1. **Localisation.** Le document dit « Precise Location : Yes, linked ». Or
   la politique publiée dit, au § 4.1 : « Aucune trace, aucun point de
   position ne monte vers nos serveurs ». Le partage est éteint. Pour Apple,
   « collecter » veut dire « faire sortir de l'appareil ».
   - **Option A : déclarer « Location : non collectée ».** C'est cohérent
     avec la politique et le code d'aujourd'hui. À revoir le jour où le
     partage s'allume.
   - **Option B : garder « collectée »**, par précaution. La fiche paraîtra
     alors plus intrusive qu'elle ne l'est, et elle contredira la politique.
2. **Suivi publicitaire (tracking).** Le document déclare l'identifiant de
   l'appareil (IDFA) « utilisé pour le suivi » via AdMob. Or **l'application
   n'affiche jamais la fenêtre de consentement ATT** : aucun appel à la
   demande ATT n'existe dans `lib/`. Apple refuse une application qui
   déclare du suivi sans demander la permission ATT (règle 5.1.2).
   - **Option A : déclarer « pas de suivi »** et servir des publicités non
     personnalisées. C'est cohérent avec le code d'aujourd'hui, puisque sans
     ATT l'IDFA n'est pas accessible. Le texte `NSUserTrackingUsageDescription`
     peut rester : il ne s'affiche jamais.
   - **Option B : ajouter la demande ATT** dans le code, avant la première
     publicité, et garder la déclaration de suivi. Ça demande un petit lot de
     code.

Les autres réponses de `app-privacy-att.md` restent justes : pas de
coordonnées, pas de santé, photos locales, identifiant pseudonymisé,
diagnostics.

---

## 4. Page de la version iOS (une par langue)

### Captures d'écran — À PRODUIRE
Tout est dans `assets/store/ios/screenshots_spec.md` : tailles, écrans,
ordre et interdits. En résumé :

- **iPhone 6,9" : 1320 × 2868**, sur le simulateur iPhone 17 Pro Max ;
- **iPhone 6,3" : 1206 × 2622**, sur l'iPhone 17 Pro. La page Apple la marque
  obligatoire ;
- **iPad 13" : 2064 × 2752**, obligatoire tant que l'application est
  déclarée iPad (voir la décision ci-dessous) ;
- **iPhone Duo** : extérieur 1398 × 2034 et intérieur 2007 × 2853. C'est une
  nouveauté, non obligatoire d'après la page Apple lue le 07/10. À produire
  si App Store Connect affiche la case comme exigée ;
- dix écrans proposés, tous capturables en démo sauf trois.

> **DÉCISION DE CHRISTOPHE — iPad.** Le projet déclare iPhone **et** iPad
> (`TARGETED_DEVICE_FAMILY = "1,2"`).
> - **Garder l'iPad** : produire les captures iPad et tester sur iPad.
> - **iPhone seul** : passer à `"1"`. L'application reste installable sur
>   iPad en mode compatibilité, et il n'y a plus de captures iPad à faire.

### Image d'en-tête (nouveauté) — À PRODUIRE (facultatif)
- **5244 × 2950** (16:9, PNG sans transparence) : un seul fichier sert pour
  l'en-tête de la page produit et pour les résultats de recherche ;
- ou **3840 × 1646** (21:9) : pour l'en-tête seulement.

Ce qu'il faut y mettre est décrit dans `screenshots_spec.md` § 3 : une photo
de sentier, un iPhone qui montre la carte, et aucune promesse « hors ligne ».

### Texte promotionnel — À COLLER
`assets/store/ios/promotional_text_{langue}.txt`. Il est modifiable à tout
moment, sans nouvelle revue.

| Langue | Car. / 170 |
|---|---|
| fr | 159 |
| en | 149 |
| de | 148 |
| it | 146 |
| es | 140 |

Texte français :
`Essayez la démo gratuite, sans compte. Étapes, trace GPS, alerte de sortie de sentier, météo des étapes et bouton SOS : tout pour préparer et vivre votre trek.`

### Description — À COLLER
`assets/store/ios/description_{langue}.txt`. Le même texte sert sur Google
Play (`full_description_{langue}.txt`).

| Langue | Car. / 4 000 |
|---|---|
| fr | 2 659 |
| en | 2 291 |
| de | 2 498 |
| it | 2 583 |
| es | 2 539 |

La description se termine par trois éléments :

- une phrase sur la publicité et les achats intégrés ;
- le lien vers les **conditions d'utilisation** ;
- le lien vers la **politique de confidentialité**.

C'est obligatoire dès qu'un abonnement à renouvellement automatique est
proposé (règle 3.1.2), et l'application en propose un.

Ce qui a été retiré, et à quelle condition le remettre :
`assets/store/PROMESSES_RETIREES.md`.

### Mots-clés — À COLLER
`assets/store/ios/keywords_{langue}.txt`. Ils sont séparés par des virgules,
sans espace, et aucun ne répète un mot du titre ou du sous-titre.

| Langue | Texte | Car. | Octets / 100 |
|---|---|---|---|
| fr | `randonnée,sentier,GR,itinérance,carte,GPX,trace,dénivelé,refuge,bivouac,montagne,météo,SOS` | 90 | 96 |
| en | `trekking,trail,long-distance,map,GPX,track,planner,elevation,hut,refuge,bivouac,mountain,weather,SOS` | 100 | 100 |
| de | `Trekking,Wanderweg,Fernwanderweg,Karte,GPX,Track,Planung,Höhenmeter,Hütte,Biwak,Berg,Wetter,SOS` | 95 | 97 |
| it | `escursione,escursionismo,sentiero,mappa,GPX,traccia,dislivello,rifugio,bivacco,montagna,meteo,SOS` | 97 | 97 |
| es | `trekking,sendero,travesía,mapa,GPX,traza,desnivel,refugio,vivac,montaña,meteo,SOS,excursión` | 91 | 94 |

### URL d'assistance (Support URL) — OBLIGATOIRE — À COLLER
Ce champ existe aussi pour chaque langue. Apple exige qu'on y trouve un moyen
de contacter l'éditeur (règle 1.5).

| Langue | Adresse |
|---|---|
| fr | `https://only1cent.com/stepways/conditions` |
| en, de, it, es | `https://only1cent.com/stepways/conditions-en` |

Pourquoi cette page :

- elle répond 200, d'après la mesure de l'audit ;
- elle nomme l'éditeur, Only1Cent, et donne l'adresse
  **contact@only1cent.com** dès le § 1 (source `docs/legal/cgu-moderation.md`).

**Ce qui manque pour mieux faire :** une page `/stepways/support` dédiée, qui
contienne l'adresse de contact et trois questions fréquentes (démo, achat,
localisation). Elle n'existe pas, et je n'ai pas pu vérifier
`https://only1cent.com/stepways` lui-même : le réseau de ce poste de travail
refuse le domaine. Avant de coller l'adresse, **ouvrir la page dans un
navigateur et vérifier qu'elle affiche bien contact@only1cent.com.**

### URL marketing — facultative — DÉCISION DE CHRISTOPHE
Dans App Store Connect, ce champ est **facultatif**. Seule l'URL d'assistance
est obligatoire.

- **Laisser vide** aujourd'hui : aucune page de présentation de StepWays
  n'existe à notre connaissance.
- **Ou** `https://only1cent.com/stepways`, mais seulement après avoir vérifié
  qu'elle répond et présente l'application.

### Version — DÉCISION DE CHRISTOPHE
Voir § 7.2. **Le numéro saisi ici doit être identique, caractère pour
caractère, au numéro du build envoyé.** Aujourd'hui, ce numéro est `0.1.7`.

### Droits d'auteur (Copyright) — À COLLER
`2026 Only1Cent`

Apple attend l'année suivie du titulaire des droits, sans URL, et ajoute
lui-même le « © ». Le titulaire doit correspondre au **nom du vendeur** du
compte développeur. Si le compte est au nom de Christophe Mosconi plutôt que
d'Only1Cent, écrire `2026 Christophe Mosconi`.

### Informations pour la révision (App Review Information) — À COLLER
Le détail et le texte sont dans `assets/store/ios/app_review_notes.md`.

- **Connexion requise : NON.** Décocher. L'application s'ouvre sans compte.
- **Nom d'utilisateur et mot de passe : vides.** Il n'en existe aucun.
- **Coordonnées** : les vôtres, saisies à la main.
- **Notes** : le bloc anglais du fichier, 2 906 caractères sur 4 000. Il
  explique comment voir un sentier sans marcher : catalogue, « Try the
  demo », « Start the trek », puis « Simulate the next stage ».

### Publication de la version — DÉCISION DE CHRISTOPHE
- **Manuelle** : vous appuyez sur « Publier » après l'acceptation. C'est
  conseillé pour une première sortie.
- **Automatique** : la version part dès qu'Apple l'accepte.

### Build — À PRODUIRE
Il faut un build de la chaîne `ios_testflight`, envoyé par Christophe, avec
Xcode 26 ou plus (§ 7.3). Il apparaît dans TestFlight sous le numéro de
version du build, et on l'attache ensuite à la page de version.

---

## 5. Ce que le dépôt déclare dans le paquet (déjà fait dans ce lot)

| Clef `Info.plist` | État |
|---|---|
| `ITSAppUsesNonExemptEncryption` | Posée à **NO** (§ 7.1). |
| `CFBundleLocalizations` | fr, en, de, it, es. |
| Textes d'autorisation | 11 textes, dans 5 langues (`ios/Runner/*.lproj/InfoPlist.strings`). Trois ont ete ajoutes par la tache 740, dont celle qui a fait refuser le build 9 : voir § 7.5. Le texte de localisation en arrière-plan ne promet plus le partage avec les proches. |
| `CFBundleDisplayName` | `StepWays`, inchangé. |
| `CFBundleName` | `moteur_gr`. **Non modifié** : voir § 7.4. |

---

## 6. Achats intégrés — À PRODUIRE

Le suivi GPS réel d'un sentier demande d'avoir débloqué la randonnée avec le
compte-étapes. Les produits déclarés dans le code
(`lib/core/services/wallet_iap_service.dart`) doivent être créés **avec ces
identifiants exacts** :

| Identifiant | Type App Store Connect |
|---|---|
| `stepways_credits_25` | Consommable (recharge du compte-étapes) |
| `stepways_credits_50` | Consommable (recharge du compte-étapes) |
| `stepways_sub_noads_monthly` | Abonnement à renouvellement automatique, dans un groupe d'abonnements à créer |

`web_follow_pass` (`lib/features/group/services/iap_service.dart`) ne se crée
**pas** : il appartient au partage éteint, et son mode réel est coupé
(`kIapRealModeEnabled = false`).

Pour une première version, Apple exige que chaque produit soit :

- complété : nom, description, prix et **capture d'écran de revue** ;
- **soumis avec la version**.

Sinon, le reviewer ne peut pas tester l'achat.

**À VÉRIFIER dans l'application avant l'envoi (règle 3.1.2).** L'écran
d'abonnement doit afficher, avant le paiement :

- le titre de l'abonnement ;
- sa durée ;
- son prix ;
- un lien vers les conditions d'utilisation ;
- un lien vers la politique de confidentialité.

---

## 7. Déclarations et réglages techniques

### 7.1 Chiffrement — fait : `ITSAppUsesNonExemptEncryption = NO`

**Pourquoi la clef.** Sans elle, App Store Connect pose la question du
chiffrement à chaque build envoyé. Le build reste « Conformité export
manquante » tant qu'on n'a pas répondu.

**Pourquoi NO.** Cette valeur signifie « l'application n'utilise que du
chiffrement exempté ». Voici ce que le binaire contient, mesuré dans le code :

1. **HTTPS / TLS.** Il passe par le système, les SDK Firebase (dont gRPC) et
   le client HTTP de Flutter. Il ne sert qu'à protéger les échanges réseau de
   l'application avec ses propres serveurs et ceux de ses fournisseurs. C'est
   le cas d'exemption standard qu'Apple cite lui-même.
2. **SHA-256, paquet `crypto`.** C'est une empreinte (anonymisation de
   l'identifiant, contrôle d'intégrité des fichiers de carte), **pas un
   chiffrement** : rien n'est rendu illisible puis lisible.
3. **AES-GCM-256 et PBKDF2, paquet `cryptography`.** Ils servent au coffre de
   sauvegarde (`lib/core/services/secure_vault_service.dart`).
   - **Leur chemin d'appel est mort aujourd'hui.** Le service n'est lu que
     par `accountVaultServiceProvider`, qui n'a aucun appelant, et
     `ReconnectionVault.alimente` vaut `false`.
   - **Même vivant, il resterait exempté.** La fonction première de StepWays
     est la randonnée, pas la sécurité de l'information. Le chiffrement ne
     ferait que protéger les propres données du randonneur, au service de
     cette fonction première. C'est l'exclusion de la **Note 4 de la
     catégorie 5, partie 2** des règles américaines d'exportation (EAR).

**À revoir obligatoirement** le jour où la sauvegarde chiffrée s'allume.
L'application emploierait alors réellement un algorithme standard (AES) en
plus de celui du système. La Note 4 la couvrirait encore très probablement,
mais la réponse à la question d'Apple deviendrait « utilise des algorithmes
standard », ce qui fait apparaître la question de la **déclaration française
auprès de l'ANSSI** pour une distribution en France. Pour ce jour-là : un
avis juridique, ou retirer le paquet `cryptography` s'il ne sert plus.

### 7.2 Numéro de version : d'où vient chaque chiffre — DÉCISION DE CHRISTOPHE

| Endroit | Valeur | D'où elle vient |
|---|---|---|
| `pubspec.yaml` | `version: 0.1.7+11` | Saisi à la main. |
| Version affichée (`CFBundleShortVersionString`) | `0.1.7` | `$(FLUTTER_BUILD_NAME)`, tiré du `pubspec`. Le widget suit la même valeur. |
| Numéro de build (`CFBundleVersion`), chaîne `ios_testflight` | Compteur Codemagic | `--build-number=$PROJECT_BUILD_NUMBER`. Il monte à chaque build et ne se reprend jamais. |
| Numéro de build, chaîne `ios_release` | `11` | Le `pubspec` : pas d'option `--build-number`. Un deuxième envoi avec la même version serait refusé. |
| Formulaire App Store Connect | `1.0` | **Ce n'est pas le dépôt.** C'est le nom qu'App Store Connect donne par défaut à la première version d'une app neuve. |
| Le seul `1.0` du dépôt | `MARKETING_VERSION = 1.0` | Cible `RunnerTests`, jamais envoyée. |

**Ce qu'App Store Connect verra.** Un build `0.1.7 (N)`. Il apparaîtra dans
TestFlight, mais **ne pourra pas être attaché à la page « 1.0 »**, car les
deux numéros doivent être identiques.

Les trois options :

- **A. Garder `0.1.7`.** Remplacer `1.0` par `0.1.7` dans le formulaire.
  Aucun changement de code, mais le public verra « Version 0.1.7 », un numéro
  de version d'essai.
- **B. Passer à `1.0.0`.** Mettre `version: 1.0.0+N` dans `pubspec.yaml` et
  `1.0.0` dans le formulaire (pas `1.0`). Google Play suit : le même
  `pubspec` donne aussi le `versionName` Android.
- **C. Passer à `1.0`.** Mettre `version: 1.0.0+N`, ou `1.0+N` si Flutter
  l'accepte, avec exactement la même graphie dans le formulaire.

Pour le `+N`, prendre un nombre **plus grand que tout numéro de build déjà
envoyé**. L'historique réel des builds est dans la mémoire #101503, que ce
lot n'a pas pu lire. Avec `ios_testflight`, c'est de toute façon le compteur
Codemagic qui l'emporte.

### 7.3 Xcode, SDK et cible de déploiement, face à l'exigence d'avril 2026

**Exigence Apple.** Depuis le 28/04/2026, tout envoi doit être compilé avec
le **SDK iOS 26 et Xcode 26 ou plus**. La cible minimale reste libre.

**Ce que demande le projet :**

- application : **iOS 15.0** au minimum. Le dépôt disait 13.0, et je l'ai
  aligné sur 15.0, pour trois raisons :
  - le Flutter stable du jour (3.47.6, du 30/09/2026), que Codemagic prend
    avec `flutter: stable`, réécrit de lui-même 13.0 en 15.0 à chaque
    compilation ;
  - Flutter 3.41, la version du `pubspec.lock`, laisse 13.0, mais le paquet
    `health` exige déjà iOS 14 ;
  - 15.0 compile avec les deux versions.

  Conséquence : les iPhone restés sous iOS 13 ou 14 ne peuvent pas installer
  l'application. Ce sont des appareils de 2019 et avant, sans mise à jour
  depuis 2021 ;
- widget `TrekWidget` : **iOS 17.0** ;
- l'outil Flutter exige au moins Xcode 15.

**Ce que demande la chaîne de compilation.** `codemagic.yaml` écrit
`xcode: latest` et `flutter: stable` sur les quatre chaînes iPhone.
« latest » prend le Xcode stable le plus récent de Codemagic, qui est en
octobre 2026 un Xcode 26 ou plus récent.

**Est-ce que ça tient ? Oui, avec une réserve.** « latest » flotte, et ce lot
ne s'est pas connecté à Codemagic pour lire la version réelle. Pour vérifier,
il faut lire la ligne `Xcode version` dans le journal du dernier build
`ios_compile`. Si l'on veut figer : `xcode: 26.x` (décision d'infra, hors de
ce lot).

### 7.4 Nom interne `CFBundleName = moteur_gr` — proposition, non appliquée

Le randonneur voit `StepWays` sous l'icône, grâce à `CFBundleDisplayName`.
Mais le nom interne remonte ailleurs :

- dans des journaux et des rapports de plantage ;
- dans certaines fenêtres du système, quand le nom affiché manque ;
- dans des outils comme Réglages > Général > Stockage, sur certaines
  versions d'iOS.

**Proposition :** dans `ios/Runner/Info.plist`, remplacer `moteur_gr` par
`StepWays`. Cela fait 8 caractères, sous la limite de 15 d'Apple. Risque
nul : ni l'identifiant du paquet, ni le nom de l'exécutable (`Runner`), ni
les droits ne changent.

---

### 7.5 Les clés d'usage — ce qu'Apple contrôle, et pourquoi trois d'entre elles parlent d'API jamais appelées (tâche 740)

**Le rejet, mesuré.** Le 08/10/2026, Apple a **refusé** la livraison 0.1.7
build 9 (App Apple ID 6817011266) avec `ITMS-90683 — Missing purpose string in
Info.plist` : le `Info.plist` de `Runner.app` devait porter
`NSHealthUpdateUsageDescription`. Le paquet n'a pas atteint TestFlight.

**Ce que ce contrôle regarde.** Pas ce que l'application fait : les API que le
binaire **référence**. Un greffon qui nomme une API gardée oblige à poser sa
clé, même si aucune ligne de `lib/` ne l'appelle jamais. Trois clés de ce
dépôt sont dans ce cas, et elles ne décrivent donc aucune fonction du produit.

| Clé | Le greffon qui référence l'API | Ce que l'application en fait |
|---|---|---|
| `NSHealthUpdateUsageDescription` | `health` 13.3.1 — `requestAuthorization(toShare: typesToWrite, read:)`, `HealthDataOperations.swift` ligne 180, sans condition de compilation | **Rien.** `health_reader_service.dart` ne déclare que `readTypes` : pas, fréquence cardiaque, distance, calories |
| `NSAppleMusicUsageDescription` | `file_picker` 8.3.7 — `MediaPlayer/MediaPlayer.h` dans son en-tête **public**, et un `MPMediaPickerController` instancié ligne 369 | **Rien.** Le seul appel du dépôt est `FileType.custom` pour une trace `.gpx` |
| `NSFaceIDUsageDescription` | `flutter_secure_storage_darwin` 0.3.2 — `import LocalAuthentication` et `LAContext()` ligne 197 | **Rien.** Le dépôt ne passe ni `useSecureEnclave` ni `accessControlFlags` |

Les trois phrases disent exactement cela, dans les cinq langues. Aucune ne
promet une fonction qui n'existe pas : le jour où l'application écrira vraiment
dans Santé, c'est la phrase qu'il faudra réécrire **avant** le code.

**Aucun entitlement HealthKit**, et il n'en faut pas : lire et écrire passent
tous deux par la clé d'usage, pas par un droit signé.
`ios/Runner/Runner.entitlements` ne porte que le groupe d'applications du
widget, et une garde refuse qu'on y ajoute HealthKit.

**`permission_handler` ne doit aucune clé aujourd'hui, et c'est une mesure.**
Ses stratégies vivent derrière `#if PERMISSION_X` ; en C, une macro **non
définie** vaut 0 dans un `#if`, et `ios/Podfile` n'en définit aucune. Chaque
stratégie tombe donc dans sa branche `#else` et se réduit à
`UnknownPermissionStrategy` : aucun framework sensible n'est importé, aucune
clé n'est exigée. C'est la raison pour laquelle Apple n'a rien reproché
d'autre que Santé au build 9. **Conséquence à connaître, qui dépasse cette
fiche :** sur iPhone, `permission_handler` répond « refusé » sans jamais ouvrir
de fenêtre système (voir § 8, point 9).

**Ce qui surveille tout cela.**
`test/structurel/les_cles_d_usage_ios_sont_completes_740_test.dart` (14 cas)
porte le tableau dépendance vers clés et rougit si une dépendance sensible
perd sa clé, si une clé est posée sans raison inscrite au tableau, si un
entitlement HealthKit apparaît, ou si une permission est allumée dans le
Podfile sans sa clé. Les cinq langues restent tenues par
`test/structurel/fiche_magasin_et_apple_test.dart`.

---

## 8. Ce qui peut faire refuser l'envoi ou la revue, hors formulaire

Classé du plus grave au moins grave. Aucun de ces points n'est corrigé dans
ce lot, parce que chacun touche l'infra, la carte de l'autre session ou du
code produit. Chacun est nommé ici avec son correctif.

1. **Les publicités iPhone partiront avec les identifiants de TEST de
   Google.**
   - `ios/Flutter/Release.xcconfig` retombe sur l'App ID de test.
   - Aucune chaîne iPhone de `codemagic.yaml` ne passe les
     `--dart-define=ADMOB_BANNER_IOS` et `ADMOB_REWARDED_IOS`.
   - Résultat : la bannière de la démo montrerait « Test Ad » au reviewer et
     au public.
   - Correctif (infra) : ajouter ces deux `--dart-define` et
     `ADMOB_APP_ID_IOS` au groupe de variables de `ios_testflight`.
2. **L'étape d'analyse des chaînes Codemagic s'arrête sur une option
   refusée.**
   - `dart analyze --no-fatal-infos lib/ test/` répond « Cannot negate option
     "--no-fatal-infos" », avec le code de sortie 64.
   - Mesuré ici avec Dart 3.11.5 (Flutter 3.41.9, la version qui correspond
     au `pubspec.lock`) et avec Dart 3.13.5 (Flutter stable 3.47.6).
   - Si Codemagic se comporte de même, `ios_testflight` s'arrête avant de
     construire. Le journal du dernier build le dira.
   - Correctif (infra) : `dart analyze lib/ test/`. Les infos ne font pas
     échouer par défaut et les avertissements si : c'est exactement
     l'intention de la ligne actuelle. Mesuré sur cette branche : code de
     sortie 0, aucune erreur, aucun avertissement.
3. **Déclaration de suivi sans fenêtre ATT** (§ 3, point 2). C'est un motif
   de refus en revue.
4. **Santé et Bluetooth liés au binaire sans fonction visible.**
   - Les paquets `health` et `flutter_blue_plus` sont liés, mais leurs
     fournisseurs n'ont aucun consommateur.
   - `NSHealthShareUsageDescription` est déclaré, alors que le droit HealthKit
     est absent de `Runner.entitlements`. Apple peut demander à quoi sert
     HealthKit (règle 2.5.1).
   - **Rattrapé par les faits le 08/10/2026 (tâche 740).** Ce n'est pas la
     revue qui a parlé, c'est le contrôle d'envoi : `ITMS-90683` a refusé le
     build 9 parce qu'il **manquait** une clé,
     `NSHealthUpdateUsageDescription`, et non parce qu'il y en avait une de
     trop. L'absence de droit HealthKit n'est pas le problème : lire et
     écrire passent tous deux par la clé d'usage, pas par un entitlement. Les
     deux textes sont donc **posés** et expliqués (§ 7.5), et le correctif
     ci-dessous — retirer les paquets — reste une option produit, pas une
     obligation d'Apple.
   - Correctif (code) : retirer ces deux paquets morts. On retire alors aussi
     leurs deux textes d'autorisation.
5. **Le catalogue montre deux sentiers qui ne sont pas des produits.**
   - « Volcans Trail » est un sentier de test.
   - « Traversée des Pyrénées » a une trace vide
     (`lib/core/config/trail_catalog.dart:476-477`).
   - Le reviewer peut les ouvrir : contenu incomplet, règle 2.1.
   - Correctif (code) : les masquer en release.
6. **L'accueil de l'application promet encore le hors ligne.** Les textes
   `onboarding.welcomeSubtitle` (« map… offline ») et
   `onboarding.downloadSubtitle` (« use it fully offline »), dans les cinq
   langues, sont la première chose que lit le reviewer. Correctif (code,
   i18n) : les aligner sur la fiche.
7. **La carte hors ligne.** Le correctif tient en une ligne, mais il est dans
   la carte, qui appartient au lot 671-03, et il n'est **pas fait ici**.
   - Fichier : `lib/features/trek/presentation/map/map_content.dart:190`.
   - Remplacer `tileProvider: inertTileProviderOrNull(),` par
     `tileProvider: inertTileProviderOrNull() ?? ref.watch(tileProviderForTrailProvider(widget.trailId)).value,`
     et importer `core/map/offline_tile_provider.dart`.
   - Une fois fait et vérifié en mode avion, on peut remettre la promesse
     (voir `assets/store/PROMESSES_RETIREES.md`).
8. **`docs/store/data-safety.md` (Google Play) décrit encore le partage de
   position.** Hors de la fiche Apple, à corriger avant la Play Console.

9. **`permission_handler` ne demande rien sur iPhone : il répond « refusé ».**
   Mesure, non supposition. Ses stratégies vivent derrière `#if PERMISSION_X`
   (§ 7.5) ; `ios/Podfile` ne définit aucune de ces macros, donc chacune se
   réduit à `UnknownPermissionStrategy` : `checkPermissionStatus` rend
   `denied`, `requestPermission` rend `permanentlyDenied`, et **aucune fenêtre
   système ne s'ouvre jamais**. Or le dépôt passe par ce greffon **sans garde
   de plateforme** pour la position
   (`lib/shared/services/location_permission_service.dart`,
   `locationWhenInUse` et `locationAlways`), pour les notifications, et
   explicitement pour iOS pour les capteurs
   (`lib/features/trek/data/background_gps_service.dart` ligne 104 :
   `Platform.isIOS ? Permission.sensors : Permission.activityRecognition`).
   - Conséquence attendue sur iPhone : l'autorisation de position n'est jamais
     demandée par ce chemin, et le code la croit refusée pour toujours. C'est
     le cœur du produit.
   - Ce n'est **pas** ce qu'Apple a reproché au build 9 : `ITMS-90683` est un
     contrôle d'envoi, celui-ci est un défaut d'exécution. Les deux ne se
     réparent pas du même geste.
   - Correctif (infra iOS) : déclarer `GCC_PREPROCESSOR_DEFINITIONS` dans le
     `post_install` de `ios/Podfile`, avec les seules permissions réellement
     utilisées — `PERMISSION_LOCATION`, `PERMISSION_LOCATION_WHENINUSE`,
     `PERMISSION_LOCATION_ALWAYS`, `PERMISSION_NOTIFICATIONS`,
     `PERMISSION_SENSORS` — et toutes les autres à `0`. Les clés d'usage que
     cela rend obligatoires sont **déjà posées** (position, mouvement), et la
     garde de la tâche 740 le vérifie à chaque passage.
   - **Non fait dans la tâche 740, volontairement :** c'est une modification
     du build natif qu'aucune gate de ce dépôt ne peut vérifier depuis
     Windows, et dont la seule preuve est une vraie compilation Xcode. La
     mêler à la livraison qui doit débloquer l'envoi aurait rendu un échec de
     build impossible à attribuer. À traiter dans sa propre tâche, avec son
     propre build.
