# Privacy Policy — StepWays

> **THIS DOCUMENT IS THE SOURCE; THE ONLINE PAGE IS ITS RENDERING.**
> Published on 30/09/2026 at <https://only1cent.com/stepways/privacy-en>
> (French version: `/stepways/privacy`), on the Firebase hosting of the
> `gr20-app` project, like the GR20 policy — Christophe's decision of
> 30/09 13:39: "Regarde celle de GR20 et fais pareil !" (task 642). The
> address is held by `StepwaysLegal` (`lib/core/branding/`), which the
> four trail configurations read it from. Any change to this text must be
> carried over to both online pages, and vice versa: two truths that
> diverge are no better than none.
>
> **LEGAL-REVIEW ZONE — validation still required on form.**
> This document faithfully describes the behaviour of the application
> code as of the date below. It was written by the engineering team
> based on documentary sources (CNIL guidance, GDPR/DSA texts) and
> **NOT by a lawyer**. The passages marked **[LEGAL]** remain to be
> decided. Field still open: **`[ADDRESS]`** (registered office), which is
> deliberately NOT invented and does not appear on the published page.
> Any functional change (analytics switched on, photo sync, position
> sharing actually opened…) requires updating this text first.

**Last updated: 30 September 2026** (task 642 — text brought in line with
the measured code, and published online. Previous consolidation:
15 June 2026, SEC-D batch, design D4 #86166)

## 1. Who we are

The StepWays application (the "App") is published by **Only1Cent**,
represented by **Christophe Mosconi** ("we", "us"). We are the data
controller for the processing described here.

Privacy contact: **contact@only1cent.com**.

> **[LEGAL] — registered office and DPO.** The registered office
> (**`[ADDRESS]`**) is still to be filled in; it is not published until
> verified. A DPO is not always mandatory for a small organisation; the
> identifiable contact point required by Art. 13(1)(b) GDPR is
> `contact@only1cent.com`. Still to be decided: is a separate moderation
> contact needed?

## 2. Our principle: data minimisation by design

StepWays is built to work **locally on your phone first**, including
fully offline in the mountains:

- **No named account is required or created.** On first use, the App
  opens an **anonymous account** with Firebase Authentication. When you
  sign in with Apple or Google, the App stores **neither your name, nor
  your email address, nor your picture**: the App's data model simply has
  no such fields (verifiable in the code — internal ref. #85383).
- Sign in with Apple is requested **without** the "name" and "email"
  scopes.
- Your **journal photos**, **logbook**, **detailed GPS tracks**, **body
  measurements**, **health data and emergency contacts** stay
  **exclusively on your device** and are never sent to our servers.
- **What leaves is a CLOSED LIST, not a list of exclusions** (tasks 612
  and 617). The code does not enumerate what stays in — it enumerates
  what is allowed to leave, and refuses everything else **before the
  network**, in both directions. See § 8.

> **Two identifiers, and they must be told apart (corrected task 642).**
> Documents stored on our servers live under `users/{uid}`, where `uid`
> is the **Firebase anonymous account identifier** — assigned
> automatically, with no name and no email. It is NOT a SHA-256
> fingerprint: the Firestore security rules only grant access when
> `request.auth.uid == userId`, which forces the raw identifier as the
> path. The salted SHA-256 fingerprint does exist, but it serves
> elsewhere: as the "business" identifier exposed to the screens, and as
> `complainantUidHash` on moderation complaints. Earlier versions of this
> document announced the fingerprint as the key of synced data — that was
> inaccurate.

> **Pseudonymous, not anonymous.** When the App shows a leaderboard, a
> nickname or a community contribution, the data remains
> **pseudonymised** (linkable to a technical identifier), not anonymous
> in the strict GDPR sense (the three CNIL criteria — singling out,
> linkability, inference — are not all ruled out). We therefore never
> describe such data as "anonymous". An automated guard prevents this
> confusion in the interface (cross-cutting test D4A-03).

## 3. Granular, purpose-based consent

You decide, **purpose by purpose**, what the App is allowed to do.
Consent is collected through a **clear affirmative action** (no
pre-ticked boxes, CNIL guidance), it is **timestamped** (`decidedAt`),
**versioned** (`policyVersion`: if the policy changes, your consent is
requested again) and **revocable at any time** from settings
(Settings → Privacy), where a **"Decline all"** button withdraws the four
standard purposes in a single gesture (task 580). The technical details
of consent collection are handled by the App's consent service
(ConsentService, D4A-01/D4A-02).

**The default is CLOSED**: where no readable state exists, the App treats
it as no consent.

### 3.1 The consent register lives IN THE DATABASE (commits e3170ca0, d92d5cd5)

Christophe's decision, verbatim: "Le consentement est dans nos bases,
horodaté, c'est les données qui n'y sont pas" — consent lives in our
databases, timestamped; it is the data that does not.

Every decided choice is written under
**`users/{uid}/consents/{purpose}`** — one document per purpose, a
**closed** list of fields:

| Field <!-- #314 --> | Contents |
|---|---|
| `granted` | granted or declined |
| `decided_at` | **server** timestamp: this is the authoritative one |
| `updated_at` | last write of the document |
| `version_du_texte` | version of this policy the agreement covered |
| `declencheur` | `premiere_demande`, `modification_des_donnees`, `evolution_de_politique`, `reglages`, `inconnu` |
| `decide_sur_le_telephone_le` | date the decision was **made**, distinct from its transmission |

**Why two dates.** The server dates the WRITE; a decision made offline in
the mountains only arrives days later. Dating the consent from the day it
was transmitted would be a material inaccuracy for proof purposes
(Art. 7(1) GDPR). The server remains the arbiter.

**No invented refusals.** A purpose never decided has **no** document:
writing `granted: false` without a decision would manufacture a choice
that never happened. Absence is itself information.

**The closed trap.** Since `decided_at` is a server timestamp, resending
it on every wake-up would move the consent date to every launch. The
service keeps the fingerprint of the last pushed decision and only
re-pushes what changed; the fingerprint is only set **after** a successful
write.

**Firestore rule:** `users/{uid}/consents/{purpose}`, read and write by
the **owner only**, declared separately in `firestore.rules` (line 103)
rather than left to the generic rule.

**A CHANGE TO THE DATA RE-ASKS FOR CONSENT** (d92d5cd5). Christophe's
decision: "en cas de modification des données, on redemande le
consentement". `ConsentState` carries a **data revision** alongside its
text version; when it no longer matches the current counter, the agreement
covers data that is no longer today's, and the question is asked again.
**Once per change, never on mere display**: the notation comes from the
screens that WRITE, not from those that display. A consequence to know,
and stated on the published pages: answering "Withdraw" after saving the
medical card **erases the body measurements**, because that is what
withdrawing health consent has always carried.

**WHAT STILL DOES NOT GO UP: the protected data.** The register records
the CHOICE, never its object. The medical card has no exit path (closed
list 612, intact) and neither do the body measurements (635).

> **INTEGRATION STATUS — to be aware of (task 642, 30/09).** This code
> lives on the `claude/feat/635-montee-en-base` branch (e3170ca0,
> d92d5cd5) and is **not yet merged into `main`**. Both published pages
> therefore describe the behaviour of the build that will carry this
> batch. **A build shipped without batch 635 would make these paragraphs
> false**: do not release a version of the app without it, or correct the
> pages first.

| Purpose | What it allows | Sensitive data? |
|---|---|---|
| **Navigation / location** <!-- #311 --> | Map, on-trail tracking, hike recording | Precise geolocation |
| **Social sharing** | Pseudonymous leaderboards, activity feed, kudos, community contributions | Pseudonym |
| **Public reporting** | Report content / a trail issue (DSA moderation) | Notifier contact |
| **Advertising** (task 595) | **Personalised** ads. If declined, ads remain but become non-personalised | Advertising identifier |
| **Health data** | Heart rate / health reading (BLE sensor / Health), body measurements, upload of effort measurements, **optional** | **Yes — Art. 9 GDPR** |

A decision **separate** from these five purposes governs the
**Google / Apple system backup** (task 617): it is **declined by
default**, before the question has even been seen. To date it is **not
timestamped** — it is a plain boolean.

> **Health data (Article 9 GDPR).** Health data (heart rate, health
> reading) is a **special category**. Its consent is **separate,
> explicit and reinforced**: it is never bundled with the other
> purposes, and a dedicated warning is shown. This data stays **local
> on your device** (see § 8). See also the dedicated impact assessment
> (health sensors DPIA, `AIPD-capteurs-sante.md`).

## 4. Data we process, purposes and legal bases

### 4.1 Location (precise)

- **When?** Only while you use the map, on-trail navigation, or hike
  recording. **Background** tracking (Android foreground service, iOS
  `location` mode) starts **when the hiker starts a trek**, on their own
  action, and stops when the trek is stopped or abandoned. It is **never
  active outside an ongoing hike**.
- **For how long?** As long as the hike lasts, **with no automatic
  pause**: a seven-hour stage must be recorded in full (the 30-minute
  cut-off was removed — continuous capture IS the requirement). A
  **persistent notification** stays visible throughout: tracking cannot
  be discreet.
- **Technical minimisation.** Roughly a dozen metres of distance filter
  at the source; `PrivacyDataPolicy` (D4B-01) for aggregates.
- **Where do the points go?** Into the phone's **local database
  (Drift/SQLite), and nowhere else.** No track and no position point is
  uploaded to our servers.
- **Legal basis:** consent (Art. 6(1)(a) GDPR) — opt-in, can be stopped
  at any time; OS-level permission required.

> **REAL-TIME POSITION SHARING IS NOT ACTIVE — corrected task 642.**
> Earlier versions of this document described publishing positions to
> Cloud Firestore with a 48-hour expiry. **Code measurement: that path is
> called by no action in the app** (`FollowService.publishPosition`,
> `GroupSyncService`: zero callers), and the writes of the "group" feature
> are **refused by the Firestore rules** (the `groups` collection has no
> rule, so it falls through to the global deny). The "My group" card has
> in fact been removed from the HUB. **No position therefore leaves the
> device.** The day this feature is opened, this document and both online
> pages must be updated BEFORE, and consent requested.

### 4.2 Optional cloud sync

- **What?** The **closed list** of what is uploaded, under `users/{uid}`:
  1. **trail progress** (`user_progress`): current stage, distance,
     elevation gain, walking time, dates, whether the trail is completed;
  2. **the packing checklist** (`checklist_items`): the state of the pack;
  3. **effort measurements of past hikes** (`past_hikes`): date, number of
     days, average walking hours, total elevation gain and distance —
     **gated by the health consent**, which is checked BEFORE the local
     database is even read;
  4. **the device technical record**: eight fields and eight only (first
     and last use, app version, build, platform, OS version, language,
     time zone), rewritten on each return to the foreground;
  5. **your feedback** (`user_feedback`: trail, type, free text, rating)
     and **reports / moderation complaints**;
  6. **the register of your consents** (`consents/{purpose}`, commits
     e3170ca0 and d92d5cd5): the CHOICE and its proof, never its object.
     Details in § 3.1.
- **What NO LONGER goes up, and used to** (not to be reintroduced into
  the text without reintroducing the code): the **journal** (text and
  photo paths), **body measurements** (age, height, weight, sex), and the
  **account** (balance, entitlements, subscription) — the latter also
  refused server-side by `firestore.rules`. **Photos** were never synced.
- **Legal basis:** performance of the requested features (Art. 6(1)(b)
  GDPR) for progress and the pack; explicit Art. 9(2)(a) consent for
  effort measurements; legitimate interest (6(1)(f)) for the device
  technical record.

### 4.3 Anonymous account identifier

- **What?** The identifier assigned by Firebase Authentication to the
  **anonymous account** opened on first use. It is the technical key of
  synced data (`users/{uid}`). No name, email, picture or advertising
  identifier is associated with it.
- **Not to be confused** with the salted SHA-256 fingerprint (see the box
  in § 2), which serves as the "business" identifier on the screens and as
  `complainantUidHash` on complaints.
- **Legal basis:** performance of the requested features (Art. 6(1)(b)
  GDPR).

### 4.4 Community content and reports (moderation)

- **What?** When you publish a contribution (waypoint comment,
  activity, report) or **report** content, the App processes your
  contribution and, for a report, the information needed to examine it
  (reason, content reference, notifier contact, good-faith declaration —
  Article 16 of the EU Digital Services Act, DSA).
- **Our role.** StepWays acts as a **hosting provider** under the DSA
  for user-published content: moderation is done **a posteriori** (after
  a report); we do not screen content beforehand. The moderation rules,
  the reporting procedure, the statement of reasons (Article 17) and the
  right to complain (Article 20) are set out in the **Terms and
  moderation page** (`docs/legal/cgu-moderation.md`), published on
  30/09/2026 at <https://only1cent.com/stepways/conditions-en> (French
  version: `/stepways/conditions`).
- **Legal basis:** consent (voluntary publication / reporting) and
  compliance with a legal obligation (DSA) for processing reports. The
  notifier contact is **personal data**, minimised and protected
  (limited retention, access restricted to moderators).

### 4.5 Advertising (Google AdMob)

The App embeds the Google AdMob SDK. **Two formats only: banners and
rewarded videos. No interstitials** — no interstitial API is exposed in
the code. The AdMob SDK may automatically collect: IP address, device
advertising identifier, ad interactions, diagnostics (see Google's
"AdMob data disclosure" documentation).

**Consent collection is IN PLACE, not forthcoming — corrected task 642.**
Earlier versions of this document announced a CMP "before any production
advertising"; Google's consent platform (**UMP**: `ConsentInformation`,
`ConsentForm`) is **implemented and called** (task 595):

- in the EEA the form is shown **before any ad request**; its display is
  **deferred** if it falls outside the start-up window (budget capped at
  6 s, so as not to delay launch);
- a **permanent entry point** (Settings → Privacy) lets the hiker reopen
  the advertising choice at any time, as the CMP requires;
- **no form is requested** on a build without production ad units: it
  would open onto nothing;
- on iOS, the **App Tracking Transparency** prompt is shown in addition
  to that form (`NSUserTrackingUsageDescription` declared; a single
  `SKAdNetwork` entry, Google's).

**Declining personalisation ≠ ads disappearing**: the banner remains, but
the App explicitly requests **non-personalised** ads
(`nonPersonalizedAds: true`). This must be said to the hiker without
ambiguity.

**Four ad-free situations** (single source
`MonetizationService.isNoAdsActive`): trail purchased, subscription
active, 24 hours granted by a rewarded video, showcase mode. **Owned
consequence**: on the free demonstration trail, a banner may appear while
walking.

The ad unit IDs in the repository are Google's **official test IDs**;
production ones are injected at build time (`--dart-define`).

**Legal basis:** consent (Art. 6(1)(a) GDPR; ePrivacy directive).

> **[LEGAL] — assess keeping AdMob.** The advertising identifier is the
> most sensitive data from a store and GDPR standpoint. Removing AdMob
> would greatly simplify compliance (see `docs/store/data-safety.md`).
> Business/legal decision to be made.

### 4.6 Third-party online services (maps and weather)

When no offline basemap is available, the App downloads map tiles from
**OpenStreetMap** (tile.openstreetmap.org). Stage weather forecasts
come from **Open-Meteo** (api.open-meteo.com), without any account or
key. These requests technically transmit your **IP address** and the
coordinates of the requested point (trail stage) to those servers for
the duration of the request. **Legal basis:** legitimate interest
(Art. 6(1)(f) GDPR) — serving the map and weather you asked for.

### 4.7 In-app purchases

In-app purchases (follow pass, premium content) are processed by the
App Store or Google Play. **We never receive any payment data.** To
date the App's purchase module is locked in test mode: no real payment
can be triggered.

### 4.8 Strictly local data (never transmitted)

The following stay exclusively on your device: journal photos, the
**logbook text**, detailed GPS tracks of recorded sessions, **health
data** (blood type, allergies, treatments, medical history, heart rate)
and the **whole emergency card** (identity, date of birth, address,
contacts, doctor, insurance number, photos of health cards), **body
measurements** (age, height, weight, sex), App preferences. Uninstalling
the App deletes them.

Local stores used: **Drift/SQLite** (`stepways.sqlite`) for progress, the
journal, the track and completed hikes; **SharedPreferences** for
consents, settings and the background GPS buffer;
**flutter_secure_storage** (Android Keystore / iOS Keychain) for the vault
key and the recovery code; **dedicated files** under the private
directory for `medical/` and the hiker profile. The local vault is
encrypted with **AES-GCM 256-bit** and key derivation; that key **never
leaves the device**.

## 5. What we do not do

- No collection of name, email, profile picture or address book.
- **No ACTIVE analytics**: Firebase Analytics is present but **switched
  off at start-up** (`setConsent(granted: false)`) and only activates on
  explicit consent. **Crash reports, however, DO go up**: Firebase
  Crashlytics is active, independently of analytics — corrected task 642;
  earlier versions of this document claimed no third-party crash
  reporting was embedded, which was false and had to be declared to the
  stores.
- No push notifications: `firebase_messaging` is **absent** from the
  project.
- No sale or rental of personal data.
- No automatic calls to emergency services, and no transmission of your
  health data to anyone.
- We never describe pseudonymised data (leaderboards, contributions) as
  "anonymous".

## 6. Recipients and processors

| Recipient | Role | Data |
|---|---|---|
| Google Ireland Ltd / Google LLC (Firebase Authentication) <!-- #312 --> | Processor | Anonymous account identifier; Google / Apple sign-in if chosen |
| Google (Cloud Firestore) | Processor (hosting) | Progress, packing checklist, effort measurements, device technical record, feedback, reports and moderation complaints |
| Google (Firebase Crashlytics) | Processor | Crash reports, OS version, device model |
| Google (Firebase Analytics) | Processor | **No data by default** — switched off at start-up, activated on consent only |
| Google (AdMob) | Advertising partner (test ad units in the repository) | Advertising ID, IP, ad interactions |
| Google Cloud Storage | Processor | Download of trail data and updates — **download only** |
| OpenStreetMap Foundation | Map tile provider | IP address, requested tiles |
| Open-Meteo | Weather provider | IP address, coordinates of the requested forecast point |
| Apple / Google Play | In-app purchase collection | Handled by the store; **no payment data reaches us** |

> `firebase_storage` is declared in `pubspec.yaml` but is **used nowhere**
> in `lib/`: it is therefore not a recipient of data. To be removed from
> the project, or documented the day it is used.

Google processing is covered by the *Google Data Processing Terms*.
The **data location** (Firebase/Firestore region) and the framework for
**transfers outside the EU** (Standard Contractual Clauses, EU-US Data
Privacy Framework) are documented in `docs/rgpd/transferts-hors-ue.md`.

## 7. Retention

The durations below match the retention policy enforced by the code
(`DataRetentionService`, D4B-02 — source of truth). An automatic purge
removes expired local data; the right to erasure (§ 9) allows immediate
deletion at your request.

| Data | Duration | Mechanism |
|---|---|---|
| Real-time sharing sessions (shared positions) <!-- #313 --> | *Not applicable to date*: the feature is not active (§ 4.1). The `expiresAt` field and the **48 h** expiry are written in the code and will apply the day it is opened (Firestore TTL policy to enable then) | `expiresAt` field + server purge |
| Consent register (server) | As long as the account exists. It is **proof**: it has to outlive the decision itself, or it proves nothing | Account erasure |
| Device technical record (server) | Rewritten on each return to the foreground; deleted with the account | Account erasure |
| Crash reports (Crashlytics) | **90 days**, Google's retention policy | Firebase retention |
| Map/weather caches (local) | **7 days** (recomputable data) | `purgeExpired()` (RetentionPolicy.cartoCache) |
| Already-synced contributions (reports, efforts, kudos, comments) — local copy | **30 days** after sync | `purgeExpired()` (RetentionPolicy.syncedContributions); the reference data lives on the server |
| Completed sync queue (local) | **7 days** | `purgeExpired()` (RetentionPolicy.completedSyncQueue) |
| Server-synced data (progress, text journal, checklists) | As long as the pseudonymised account exists | Deletion on request / account erasure (Art. 17) |
| Local data (photos, health, contacts, fine tracks) | Under your sole control | Removed with the App or via account erasure |
| Pseudonymised identifier | As long as the account exists | Removed by account erasure |
| Notifier contact (report) | Limited to the duration of moderation handling | Access restricted to moderators |

> **[LEGAL] — retention periods.** The technical durations above
> (7 d / 30 d / 48 h) are default minimisation choices. Confirm their
> regulatory adequacy and, where relevant, the retention of moderation
> logs (DSA) and reports.

## 8. Health data (Article 9 GDPR)

Any health data processed (heart rate via a BLE chest strap, phone
health reading) falls under **Article 9 GDPR** (special category). As
such:

- its processing relies on **explicit, reinforced consent**, separate
  from the other purposes (§ 3);
- it stays **strictly local**: no upload channel to our servers exists
  in the code. That promise is kept by **two closed lists**, which must be
  told apart:
  1. **the remote vault list** (task 612,
     `DocumentsDuCoffreDistant.autorises` in `cloud_sync_service.dart`):
     it holds **a single entry**, `account`. Any other document is refused
     **before the network and before any read**, with a named reason, and
     **symmetrically on the way down** — a card left by an earlier version
     cannot be downloaded back;
  2. **the Google / Apple system-backup list** (task 617,
     `sauvegarde_systeme.dart`): **a single inclusion**
     (`sauvegarde_systeme/`), plus an **explicit exclusion** of the
     `medical/` folder as a second lock, applied to both sections
     (`cloud-backup` and `device-transfer`). Since an `<include>` disables
     the Android default, everything else — database, photos,
     preferences, tiles, medical card — is **out by default**;
- the medical card lives in its **dedicated folder** (`medical/`), with
  atomic writes and `NSURLIsExcludedFromBackupKey` **re-applied on every
  save** on iOS (task 615);
- only the **effort measurements** of past hikes (duration, distance,
  elevation gain) may be uploaded, gated by the health consent (§ 4.2):
  these are walking measurements, not medical ones;
- it is covered by a dedicated **impact assessment** (DPIA,
  `docs/rgpd/AIPD-capteurs-sante.md`);
- you can delete it at any time (account erasure, § 9, or
  uninstallation).

> **TWO GAPS NAMED RATHER THAN HIDDEN** (measured task 642, to be fixed).
> 1. The `<cross-platform-transfer>` section (Android 16 QPR2) is **not
>    declared** in the backup rules: its absence amounts to full
>    permission towards a non-Android device. Blocked for lack of an Apple
>    `teamId`. Both published pages state this to the hiker.
> 2. On iOS, `NSUserDefaults` / `SharedPreferences` **cannot** be excluded
>    from iCloud by the publisher. Body measurements were moved out
>    (task 623); what remains there is the **stage balance and the
>    settings** — never the medical card, which is in a separate, excluded
>    folder.

## 9. Your rights

Under the GDPR you have the rights of access, rectification, erasure,
restriction, objection and portability.

- **Erasure (Article 17).** The App offers **account and data
  deletion**: it purges all local data (local database, caches,
  consents) and issues a **server-side deletion request** for the
  documents linked to your pseudonymised identifier
  (`deleteAccountData()` operation, D4B-02). Because the App is
  pseudonymous by design, this erasure is simple but **complete and
  traceable**.
- **Withdrawal of consent.** At any time, purpose by purpose, from
  Settings → Privacy.
- **Exercising the other rights:** **contact@only1cent.com**, answered
  within 30 days. Because of pseudonymisation we may ask for technical
  elements (session identifier) to locate your data.

You may lodge a complaint with your supervisory authority (in France:
CNIL, www.cnil.fr).

## 10. Security

Server data access is governed by Firestore security rules covered by
automated tests: your sharing sessions are writable only by you;
anonymous followers can only read positions of a valid session, never
your identifier; moderation reports are readable/actionable only by a
moderator role. Local data is protected by the device sandbox and the
system encryption.

## 11. Children

The App is not directed at children under 15 and offers no content
intended for them.

## 12. Changes

Any substantial change to this policy will be published in the App and
on the store listing before taking effect.

---

*Document consolidated as part of the SEC-D batch (D4D-01), design D4
CORDO #86166. Coverage: purposes, data, legal bases, rights (incl.
Art. 17), retention (aligned with D4B-02), DPO/contact, health data
(Art. 9), DSA moderation (hosting provider), transfers outside the EU
(see D4D-02). **Lawyer/DPO validation required before publication.***
