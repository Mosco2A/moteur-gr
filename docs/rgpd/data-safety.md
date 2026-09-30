# Déclarations stores — Play Data Safety & Apple App Privacy / ATT

> Mapping **exact** entre le comportement du code et les formulaires des
> stores. À reporter tel quel dans Play Console (Data Safety) et App Store
> Connect (App Privacy) au moment de la publication.
> Toute évolution du code (analytics, crash reporting, sync photos,
> ads réelles) invalide ce mapping et impose sa mise à jour.
>
> **PASSE DE CORRECTION DU 30/09/2026 (tâche 642).** Ce document affirmait
> encore trois choses que le code ne fait pas : des positions de suivi
> montant en base avec un TTL de 48 h, le journal texte synchronisé, et les
> données rangées sous une empreinte SHA-256. Les trois sont corrigées
> ci-dessous, ainsi que le contact d'effacement. Une entrée est ajoutée :
> le **registre des consentements** en base (tâche 635). La source de
> vérité de ces corrections est la mesure du code faite pour la tâche 642,
> et les deux pages publiées
> (<https://only1cent.com/stepways/privacy>, `/stepways/privacy-en`).
> Rédaction initiale : 07/06/2026, branche d'assainissement audit #327.

## Inventaire factuel des SDK embarqués (pubspec, code vérifié)

| SDK | Collecte effective dans l'app | Note |
|---|---|---|
| geolocator <!-- #D01 --> | Position précise (foreground + background) | **JAMAIS transmise** (corrigé tâche 642) : les points vont en base locale Drift et nulle part ailleurs. Le suivi temps réel / groupe n'est appelé par AUCUN geste, et les écritures « groupe » sont refusées par les règles |
| firebase_auth <!-- #D02 --> | **uid du compte ANONYME** = clé des documents `users/{uid}` (corrigé tâche 642 : ce n'est PAS le haché SHA-256, les règles imposent l'uid brut) ; AUCUN nom/e-mail/photo persisté | Scopes Apple nom/e-mail non demandés. Le haché SHA-256 sert d'identifiant métier et de `complainantUidHash` |
| cloud_firestore <!-- #D03 --> | Progression, checklists, mesures d'effort des randos passées, **registre des consentements** (tâche 635, e3170ca0/d92d5cd5), fiche technique de l'appareil (8 champs), retours, signalements. **PAS de positions** et **PAS le journal texte** (corrigé tâche 642 : ces deux chemins sont fermés) | Owner-only par règles testées ; `consents/{finalité}` déclarée à part |
| firebase_storage | **Aucun usage dans le code** (dépendance présente, zéro appel) | Ne rien déclarer ; retirer ou câbler en wagon 3 |
| google_mobile_ads (AdMob) | SDK embarqué — **ad units de TEST uniquement** | Le SDK collecte automatiquement : AdID, IP, interactions pub, diagnostics (doc Google) → à déclarer dès que le SDK est livré dans le binaire |
| in_app_purchase | Achats via stores — **verrouillé mode test** (kill-switch) | Aucune donnée bancaire côté app |
| http (Open-Meteo, OSM) | IP transitoire + coordonnées du point demandé | Pas du « user data » au sens des formulaires, documenté par transparence |
| Crashlytics / Analytics <!-- #D05 --> | ~~ABSENTS du code main~~ — **PÉRIMÉ**. Crashlytics est **ACTIF**, Analytics est **câblé mais coupé au démarrage** | Voir la mise à jour du 26/09 juste dessous, qui remplace cette ligne. **Crashlytics EST à déclarer en « Crash logs »** (rappelé tâche 642 : les deux pages publiées le disent désormais au randonneur) |

### Mise à jour du 26/09/2026 — tâche 596 (remplace la ligne « Crashlytics / Analytics » ci-dessus)

La ligne du tableau disait « ABSENTS du code main ». Ce n'est plus exact : trois
câblages ont changé d'état. Détail, poste par poste.

- **Crashlytics (rapports de plantage) — MAINTENANT CÂBLÉ.** Les filets
  `ErrorNets` sont posés dès la première ligne de `main()`, le rapporteur est
  branché dès que Firebase démarre, et la collecte crash est activée
  explicitement (`AnalyticsService.setCrashCollection`). Elle était jusque-là
  éteinte à l'insu de tous par `setConsent(granted: false)`, appelé dès la
  construction du provider. **À DÉCLARER en « Crash logs »** dès que le premier
  build avec `--dart-define=STEPWAYS_FIREBASE_PROJECT_ID` part en magasin. Sans
  configuration Firebase (cas actuel), rien ne sort : rien à déclarer.
- **Firebase Analytics (mesure d'usage) — CÂBLÉ MAIS COUPÉ.**
  `setConsent(granted: true)` n'est appelé nulle part, et aucune finalité
  « mesure d'usage » n'existe dans `ConsentPurpose`. Ne PAS déclarer
  « Analytics » tant que cette finalité n'est pas créée et recueillie.
- **Retours utilisateur (`user_feedback`) — MAINTENANT CÂBLÉ.** Le message écrit
  par le randonneur part vraiment quand Firebase est configuré ; avant, il était
  marqué « envoyé » sans partir, puis effacé de la file locale. Dépôt seul,
  lecture réservée à l'équipe (règles Firestore). À déclarer en « Messages
  in-app / autres contenus générés par l'utilisateur » dès que Firebase est
  configuré.

Données strictement locales (jamais transmises = **non « collectées »**
au sens des deux stores) : photos du journal, traces GPS locales,
données santé, contacts d'urgence, préférences.

---

## 1. Google Play — formulaire Data Safety

Définition Play : « collected » = transmis hors de l'appareil.
Le traitement éphémère (IP des requêtes tuiles/météo) n'a pas à être
déclaré comme collecte. « Shared » = transmis à un tiers autre qu'un
sous-traitant (service provider).

### Réponses aux questions générales

| Question | Réponse | Justification code |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | Position si suivi activé ; Device/other IDs via SDK AdMob |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | Firestore/HTTPS (TLS) ; tuiles/météo en HTTPS |
| Do you provide a way for users to request that their data is deleted? <!-- #D04 --> | **Yes** | Effacement depuis les réglages de l'application (base locale, caches, consentements locaux) + demande de suppression des documents serveur, et sur demande à **contact@only1cent.com** (corrigé tâche 642 : le contact est renseigné, et la mention « sessions de suivi auto-expirantes 48 h » est retirée — cette fonction n'est pas active) |

### Data types

| Data type Play | Collected | Shared | Ephemeral | Required/Optional | Purposes |
|---|---|---|---|---|---|
| Location → **Precise location** | **Yes** (uniquement si l'utilisateur active suivi temps réel/groupe ou sync) | No (Firebase = service provider) | No | **Optional** (fonction opt-in) | App functionality |
| Location → Approximate location | No (pas de collecte dédiée) | No | — | — | — |
| Personal info (name, email, address…) | **No** | No | — | — | — (modèle sans champs PII — compile-time) |
| Financial info | **No** | No | — | — | — (achats traités par Play) |
| Health and fitness | **No** | No | — | — | — (santé = local-only) |
| Photos and videos | **No** | No | — | — | — (photos locales, aucun upload) |
| Files and docs / Audio / Contacts / Calendar | **No** | No | — | — | — |
| App activity → App interactions | **Yes** (interactions avec les annonces — SDK AdMob) | **Yes** (Google AdMob, partenaire publicitaire) | No | Required (inhérent au SDK livré) | Advertising or marketing |
| Web browsing | No | No | — | — | — |
| App info and performance → Crash logs / Diagnostics | **Yes** (diagnostics SDK AdMob) | **Yes** (Google) | No | Required | Advertising or marketing, App functionality |
| Device or other IDs → **Device or other IDs** | **Yes** (Advertising ID — SDK AdMob) | **Yes** (Google AdMob) | No | Required | Advertising or marketing |
| User IDs | **Yes** (identifiant anonymisé SHA-256, si compte connecté) | No | No | Optional | App functionality, Account management |

Référence : table de divulgation officielle AdMob
(« Play data disclosure requirements », developers.google.com/admob).
Si la mise en production se fait **sans** AdMob (retrait du SDK), les
lignes App interactions / Diagnostics / Device or other IDs passent à
**No** et seule la géolocalisation opt-in + User ID restent.

### Avant publication Play (wagon 3)

- [ ] Déclarer l'**Advertising ID** dans la section dédiée de Play
      Console (obligatoire dès que com.google.android.gms.permission.AD_ID
      est présent via le SDK AdMob).
- [x] **CMP certifiée Google (UMP) pour le consentement UE** — FAIT
      (tâche 595) : `ConsentInformation` / `ConsentForm` appelés avant toute
      demande d'annonce, plus un point d'entrée permanent dans
      Réglages → Confidentialité. Corrigé tâche 642.
- [x] **Lien public vers la politique de confidentialité (FR/EN)** — FAIT
      (tâche 642), en ligne et vérifié HTTP 200 :
      <https://only1cent.com/stepways/privacy> et `/stepways/privacy-en`.
      Conditions : `/stepways/conditions` et `/stepways/conditions-en`.
- [ ] ~~Activer la politique TTL Firestore sur follow_sessions (purge
      48 h)~~ — **SANS OBJET à ce jour** (tâche 642) : la fonction de suivi
      temps réel n'est appelée par aucun geste de l'application. À faire le
      jour de son ouverture, et à déclarer alors dans cette fiche.
- [ ] **Déclarer le registre des consentements** (`users/{uid}/consents`,
      tâche 635) le jour du dépôt : c'est une donnée serveur de plus, même
      si elle ne porte aucune donnée personnelle au sens des formulaires
      Play (un booléen, des dates, une version, un déclencheur).

---

## 2. Apple — App Privacy (App Store Connect) + ATT

Définitions Apple : « Linked to you » = associée à un identifiant de
compte/utilisateur ; « Tracking » = données combinées avec des données
de tiers à des fins publicitaires (IDFA).

### Nutrition labels

| Data type Apple | Collectée ? | Linked to you ? | Used for tracking ? | Purposes |
|---|---|---|---|---|
| Location → Precise Location | **Yes** (opt-in suivi/sync) | **Yes** (liée à l'identifiant anonymisé de session) | No | App Functionality |
| Contact Info (name, email…) | **No** | — | — | — |
| Health & Fitness | **No** (local-only) | — | — | — |
| Financial Info | **No** | — | — | — |
| User Content → Photos or Videos | **No** (locales) | — | — | — |
| Identifiers → User ID | **Yes** (identifiant anonymisé, si compte) | Yes | No | App Functionality |
| Identifiers → Device ID | **Yes** (IDFA/AdID via SDK AdMob) | No | **Yes** | Third-Party Advertising |
| Usage Data → Advertising Data / Product Interaction | **Yes** (interactions annonces — SDK AdMob) | No | Yes | Third-Party Advertising |
| Diagnostics | **Yes** (diagnostics SDK AdMob) | No | No | App Functionality |

Si publication **sans** AdMob : Device ID, Usage Data et Diagnostics
passent à **No**, « Used for tracking » devient **No** partout, et
l'app peut répondre « Data Not Linked to You » pour tout sauf
Location/User ID.

### App Tracking Transparency (ATT)

- L'IDFA n'est accessible qu'après consentement via
  `ATTrackingManager.requestTrackingAuthorization` (invite système).
- **Obligatoire AVANT toute diffusion d'annonces réelles.** À ce jour
  (ad units de test), l'invite n'est pas encore implémentée — c'est un
  prérequis bloquant de la mise en production publicitaire, PAS de la
  bêta sans ads.
- Texte d'invite (clé `NSUserTrackingUsageDescription`, à ajouter à
  l'Info.plist en même temps que l'activation des ads réelles) :
  « Votre autorisation permet d'afficher des annonces moins intrusives
  qui financent le suivi gratuit de vos proches. »
- Configurer AdMob pour ne servir que des annonces non personnalisées
  (npa) en cas de refus ATT / refus CMP.

### Avant publication App Store (wagon 3)

- [ ] Renseigner les nutrition labels ci-dessus dans App Store Connect.
- [ ] Lien politique de confidentialité (EN obligatoire, FR conseillé).
- [ ] Si ads réelles : implémenter ATT + CMP, ajouter
      `NSUserTrackingUsageDescription`, puis mettre à jour ce mapping.
- [ ] Vérifier la cohérence avec les textes d'usage de l'Info.plist
      (NSLocation*, NSCamera, NSPhotoLibrary — P1-2).
