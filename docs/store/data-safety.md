# Google Play — Déclaration Data Safety (StepWays)

> **ZONE JURISTE / RESPONSABLE PUBLICATION — à valider avant dépôt.**
> Mapping **exact** entre le comportement du code et le formulaire
> *Data Safety* de Google Play Console. Rédigé par l'équipe technique,
> à **valider avant publication** (réserve de forme #86142, design D4
> #86166, C-4 / A4-8). À reporter tel quel dans Play Console au moment
> de la publication (wagon 3). **Toute évolution du code** (analytics,
> crash reporting, sync photos, ads réelles) invalide ce mapping et
> impose sa mise à jour. Consolidé le 15/06/2026 (lot SEC-D, D4D-03 ;
> reprend `docs/rgpd/data-safety.md`).

## 1. Inventaire factuel des SDK embarqués (pubspec, code vérifié)

| SDK <!-- #601 --> | Collecte effective dans l'app | Note |
|---|---|---|
| geolocator | Position précise (foreground + background) | Transmise au serveur UNIQUEMENT si suivi temps réel/groupe activé ; sinon locale |
| firebase_auth | Identifiant de connexion -> haché SHA-256 ; AUCUN nom/e-mail/photo persisté | Scopes Apple nom/e-mail non demandés |
| cloud_firestore | Positions de suivi (TTL 48 h), progression/journal texte/checklists si sync activée ; signalements de modération | Owner-only / rôle modérateur par règles testées |
| firebase_storage | **Aucun usage dans le code** (dépendance présente, zéro appel) | Ne rien déclarer ; retirer ou câbler en wagon 3 |
| google_mobile_ads (AdMob) | SDK embarqué — **ad units de TEST uniquement** | Le SDK collecte automatiquement : AdID, IP, interactions pub, diagnostics (doc Google) -> à déclarer dès que le SDK est livré dans le binaire |
| in_app_purchase | Achats via stores — **verrouillé mode test** (kill-switch) | Aucune donnée bancaire côté app |
| http (Open-Meteo, OSM) | IP transitoire + coordonnées du point demandé | Pas du « user data » au sens du formulaire, documenté par transparence |
| Crashlytics / Analytics | **ABSENTS du code main** | Ne PAS déclarer « Crash logs »/« Analytics » tant que non mergés |

Données strictement locales (jamais transmises = **non « collectées »**
au sens Play) : photos du journal, traces GPS locales, **données de
santé** (art. 9, local-only), contacts d'urgence, préférences.

## 2. Réponses aux questions générales

> Définition Play : « collected » = transmis hors de l'appareil. Le
> traitement éphémère (IP des requêtes tuiles/météo) n'a pas à être
> déclaré comme collecte. « Shared » = transmis à un tiers autre qu'un
> sous-traitant (service provider).

| Question <!-- #602 --> | Réponse | Justification code |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | Position si suivi activé ; Device/other IDs via SDK AdMob |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | Firestore/HTTPS (TLS) ; tuiles/météo en HTTPS |
| Do you provide a way for users to request that their data is deleted? | **Yes** | Suppression compte/données in-app (`deleteAccountData()`, D4B-02) + sur demande ([CONTACT-EMAIL]) ; sessions de suivi auto-expirantes 48 h |

## 3. Data types

| Data type Play <!-- #603 --> | Collected | Shared | Ephemeral | Required/Optional | Purposes |
|---|---|---|---|---|---|
| Location -> **Precise location** | **Yes** (si suivi temps réel/groupe ou sync activé) | No (Firebase = service provider) | No | **Optional** (opt-in) | App functionality |
| Location -> Approximate location | No | No | — | — | — |
| Personal info (name, email, address…) | **No** | No | — | — | — (modèle sans PII — compile-time) |
| Financial info | **No** | No | — | — | — (achats traités par Play) |
| Health and fitness | **No** | No | — | — | — (santé = local-only, art. 9) |
| Photos and videos | **No** | No | — | — | — (photos locales, aucun upload) |
| Files and docs / Audio / Contacts / Calendar | **No** | No | — | — | — |
| App activity -> App interactions | **Yes** (interactions annonces — SDK AdMob) | **Yes** (Google AdMob) | No | Required (inhérent au SDK livré) | Advertising or marketing |
| Web browsing | No | No | — | — | — |
| App info and performance -> Crash logs / Diagnostics | **Yes** (diagnostics SDK AdMob) | **Yes** (Google) | No | Required | Advertising or marketing, App functionality |
| Device or other IDs -> **Device or other IDs** | **Yes** (Advertising ID — SDK AdMob) | **Yes** (Google AdMob) | No | Required | Advertising or marketing |
| User IDs | **Yes** (identifiant pseudonymisé SHA-256, si compte connecté) | No | No | Optional | App functionality, Account management |

Référence : table de divulgation officielle AdMob (« Play data
disclosure requirements », developers.google.com/admob).

## 4. Recommandation — évaluer le retrait d'AdMob

> **[JURISTE / DÉCISION CHRIS]** L'**Advertising ID** (AdMob) est la
> donnée la plus sensible et la principale source de déclarations
> « Shared / Advertising » ci-dessus. **Si AdMob n'est pas
> indispensable**, son retrait simplifierait considérablement la
> conformité : les lignes *App interactions*, *Diagnostics* et *Device
> or other IDs* passeraient à **No**, et seules subsisteraient la
> géolocalisation opt-in et le User ID pseudonymisé. Décision
> business/juridique à arbitrer avant publication.

## 5. Checklist avant publication Play (wagon 3)

- [ ] Déclarer l'**Advertising ID** dans la section dédiée de Play
      Console (obligatoire dès que `com.google.android.gms.permission.AD_ID`
      est présent via le SDK AdMob).
- [ ] CMP certifiée Google (UMP) pour le consentement UE (TCF).
- [ ] Lien public vers la politique de confidentialité (FR/EN,
      `docs/rgpd/`).
- [ ] Activer la politique TTL Firestore sur les sessions de suivi
      (purge 48 h).
- [ ] Vérifier que firebase_storage / Crashlytics / Analytics restent
      **absents** du binaire (sinon mettre à jour ce mapping).
- [ ] Arbitrer la recommandation AdMob (§ 4).

---

*Document produit dans le cadre du lot SEC-D (D4D-03), design D4 CORDO
#86166 (C-4 / A4-8). Voir aussi `docs/store/app-privacy-att.md` (Apple),
la politique de confidentialité (D4D-01) et la doc transferts hors-UE.*
