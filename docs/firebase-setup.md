# Configuration Firebase — StepWays (wagon 3)

> Procédure à dérouler par Christophe au wagon 3 (P1-4 audit #327).
> Le repo ne contient AUCUN fichier de configuration Firebase : c'est
> voulu. Tant que cette procédure n'est pas faite, l'app tourne en
> **mode local** (état explicite affiché dans Réglages → Cloud, écrans
> follow/profil dégradés proprement — voir `CloudUnavailableNotice`).

## Règles non négociables

- **Projet Firebase DÉDIÉ StepWays** (ex. id `stepways-prod`), créé
  pour ce produit. **JAMAIS le projet `gr20-app`** ni aucun projet de
  l'ancienne application : zéro mutualisation de données, de comptes ou
  de quotas avec le legacy.
- Région Firestore : **eur3 (europe-west)** — cohérent RGPD
  (docs/rgpd/registre-traitements.md, transferts).
- Aucun secret ni fichier de config ne se commit sans décision : les
  fichiers générés ci-dessous contiennent des clés d'API *publiques*
  (restreintes par package/bundle id), mais la décision de les
  versionner appartient à Chris (pratique courante : versionnés ;
  alternative : injection CI).

## Prérequis

```bash
npm i -g firebase-tools        # >= 14 exige Java 21 ; sinon npx firebase-tools@13
dart pub global activate flutterfire_cli
firebase login                 # compte Google dédié au projet
```

## Étapes

### 1. Créer le projet et les apps

Console Firebase → nouveau projet `stepways-prod` (Analytics : désactivé
par défaut — l'app n'embarque pas d'analytics, cf. docs/rgpd/).

### 2. Générer la configuration FlutterFire

Depuis la racine du repo :

```bash
flutterfire configure \
  --project=stepways-prod \
  --platforms=android,ios \
  --android-package-name=com.only1cent.moteur_gr \
  --ios-bundle-id=com.only1cent.moteurGr
```

Cela génère :
- `lib/firebase_options.dart` (DefaultFirebaseOptions)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

> Vérifier le bundle id iOS réel dans Xcode (Runner → General) avant de
> lancer la commande ; aligner si besoin.

### 3. Brancher l'init dans le code

`lib/core/firebase/firebase_service.dart` appelle aujourd'hui
`Firebase.initializeApp()` **sans options** (échec → mode local).
Au wagon 3 :

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

et passer un `firebaseProjectId` non nul dans le `TrailConfig` utilisé
par `main.dart` (c'est le commutateur du mode cloud).

### 4. Déployer règles + index Firestore

Les règles (P0-1) et les index sont DÉJÀ dans le repo, testés sous
émulateur (P0-2, 45 verts) :

```bash
firebase deploy --only firestore:rules,firestore:indexes --project stepways-prod
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

## Ce qui reste volontairement HORS de cette procédure

- Keystore Android réel + `android/key.properties` (P1-3, wagon 3).
- Secrets de signature CI (codemagic.yaml, P1-5 — groupes d'env vars).
- AdMob réel / ATT / CMP (docs/rgpd/data-safety.md — prérequis stores).
