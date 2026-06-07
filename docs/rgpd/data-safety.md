# Déclarations stores — Play Data Safety & Apple App Privacy / ATT

> Mapping **exact** entre le comportement du code (au 07/06/2026,
> branche d'assainissement audit #327) et les formulaires des stores.
> À reporter tel quel dans Play Console (Data Safety) et App Store
> Connect (App Privacy) au moment de la publication (wagon 3).
> Toute évolution du code (analytics, crash reporting, sync photos,
> ads réelles) invalide ce mapping et impose sa mise à jour.

## Inventaire factuel des SDK embarqués (pubspec, code vérifié)

| SDK | Collecte effective dans l'app | Note |
|---|---|---|
| geolocator | Position précise (foreground + background) | Transmise au serveur UNIQUEMENT si suivi temps réel/groupe activé ; sinon locale |
| firebase_auth | Identifiant de connexion → haché SHA-256 ; AUCUN nom/e-mail/photo persisté | Scopes Apple nom/e-mail non demandés |
| cloud_firestore | Positions de suivi (TTL 48 h), progression/journal texte/checklists si sync activée | Owner-only par règles testées |
| firebase_storage | **Aucun usage dans le code** (dépendance présente, zéro appel) | Ne rien déclarer ; retirer ou câbler en wagon 3 |
| google_mobile_ads (AdMob) | SDK embarqué — **ad units de TEST uniquement** | Le SDK collecte automatiquement : AdID, IP, interactions pub, diagnostics (doc Google) → à déclarer dès que le SDK est livré dans le binaire |
| in_app_purchase | Achats via stores — **verrouillé mode test** (kill-switch) | Aucune donnée bancaire côté app |
| http (Open-Meteo, OSM) | IP transitoire + coordonnées du point demandé | Pas du « user data » au sens des formulaires, documenté par transparence |
| Crashlytics / Analytics | **ABSENTS du code main** | Ne PAS déclarer « Crash logs »/« Analytics » tant que non mergés |

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
| Do you provide a way for users to request that their data is deleted? | **Yes** | Suppression du compte/données sur demande ([CONTACT-EMAIL]) ; sessions de suivi auto-expirantes 48 h |

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
- [ ] CMP certifiée Google (UMP) pour le consentement UE (TCF).
- [ ] Lien public vers la politique de confidentialité (FR/EN).
- [ ] Activer la politique TTL Firestore sur follow_sessions (purge 48 h).

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
