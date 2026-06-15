# Privacy Policy — StepWays

> **LEGAL-REVIEW ZONE — mandatory validation before publication.**
> This document faithfully describes the behaviour of the application
> code as of the date below. It was written by the engineering team
> based on documentary sources (CNIL guidance, GDPR/DSA texts) and
> **NOT by a lawyer**. Before any production release or store submission
> it must be **reviewed and validated by a lawyer / DPO** (form reserve,
> design D4 #86166, audit #86142). The passages marked **[LEGAL]** and
> the bracketed fields `[ENTITY]`, `[ADDRESS]`, `[CONTACT-EMAIL]`,
> `[DPO-CONTACT]` must be completed/decided before publication. Any
> functional change (real analytics, crash reporting, photo sync, real
> advertising…) requires updating this text first.

**Last updated: June 15, 2026** (SEC-D batch consolidation, design D4 #86166)

## 1. Who we are

The StepWays application (the "App") is published by **[ENTITY]**,
registered at **[ADDRESS]** ("we", "us"). We are the data controller
for the processing described here.

Privacy contact: **[CONTACT-EMAIL]**.

> **[LEGAL] — Data Protection Officer (DPO).** Appoint a DPO or a data
> protection contact and provide **[DPO-CONTACT]**. A DPO is not always
> mandatory for a small organisation, but an identifiable contact point
> for data subjects (Art. 13(1)(b) GDPR) is required. To be decided by
> the lawyer.

## 2. Our principle: data minimisation by design

StepWays is built to work **locally on your phone first**, including
fully offline in the mountains:

- **No named account is required or created.** When you sign in with
  Apple or Google, the App stores **neither your name, nor your email
  address, nor your picture**: the App's data model simply has no such
  fields (verifiable in the code; identity pseudonymised by a SHA-256
  fingerprint — internal ref. #85383). Only a **technical, pseudonymised
  identifier** (a salted SHA-256 fingerprint of the sign-in identifier)
  is kept.
- Sign in with Apple is requested **without** the "name" and "email"
  scopes.
- Your **journal photos**, **logbook**, **health data and emergency
  contacts** stay **exclusively on your device** and are never sent to
  our servers.

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
pre-ticked boxes, CNIL guidance), it is **timestamped**, **versioned**
(if the policy changes, your consent is requested again) and
**revocable at any time** from settings (Settings → Privacy). The
technical details of consent collection are handled by the App's
consent service (ConsentService, D4A-01/D4A-02).

| Purpose | What it allows | Sensitive data? |
|---|---|---|
| **Navigation / location** <!-- #311 --> | Map, on-trail tracking, hike recording | Precise geolocation |
| **Social sharing** | Pseudonymous leaderboards, activity feed, kudos, community contributions | Pseudonym |
| **Public reporting** | Report content / a trail issue (DSA moderation) | Notifier contact |
| **Health data** | Heart rate / health reading (BLE sensor / Health), **optional** | **Yes — Art. 9 GDPR** |

> **Health data (Article 9 GDPR).** Health data (heart rate, health
> reading) is a **special category**. Its consent is **separate,
> explicit and reinforced**: it is never bundled with the other
> purposes, and a dedicated warning is shown. This data stays **local
> on your device** (see § 8). See also the dedicated impact assessment
> (health sensors DPIA, `AIPD-capteurs-sante.md`).

## 4. Data we process, purposes and legal bases

### 4.1 Location (precise)

- **When?** Only while you use the map, on-trail navigation, hike
  recording, or the **real-time sharing** feature you start yourself.
  Background location is used solely to record your ongoing hike and to
  publish positions for the sharing session you activated.
- **Technical minimisation.** We **do not store the full fine-grained
  GPS track on the server** when only the result (statistic,
  leaderboard) is useful: data is **aggregated / truncated** before
  sending, and GPS sampling is reduced at the source (`PrivacyDataPolicy`
  policy, D4B-01). By default your track stays **local**.
- **Where does it go?** If — and only if — you enable **real-time
  position sharing**, your positions (latitude, longitude, timestamp)
  are published to our database hosted on Google Firebase (Cloud
  Firestore) so that your relatives can follow you through a share link.
  Sharing sessions **expire automatically after 48 hours**. The share
  link never exposes your identifier: the follower page can only read
  positions of an active, valid session.
- **Legal basis:** consent (Art. 6(1)(a) GDPR) — opt-in, can be stopped
  at any time; OS-level permission required.

### 4.2 Optional cloud sync

- **What?** Your trail progress, text journal notes and packing
  checklists can be backed up to Cloud Firestore, keyed by your
  pseudonymised identifier, for restoration on a new device. **Photos
  are not synced** (local storage only).
- **Legal basis:** consent — sync requires voluntarily connecting an
  account; without it the App is fully local.

### 4.3 Pseudonymised identifier

- **What?** A salted SHA-256 fingerprint of the authentication
  identifier, used as the technical key of synced data. No name, email,
  picture or advertising identifier is associated with it.
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
  moderation page** (`docs/legal/cgu-moderation.md`).
- **Legal basis:** consent (voluntary publication / reporting) and
  compliance with a legal obligation (DSA) for processing reports. The
  notifier contact is **personal data**, minimised and protected
  (limited retention, access restricted to moderators).

### 4.5 Advertising (Google AdMob)

The App embeds the Google AdMob SDK to display ads on some screens
(beyond two followers on a sharing session). **To date the App is
configured exclusively with test (sandbox) ad unit IDs**; no real
campaign is served. The AdMob SDK may automatically collect: IP
address, device advertising identifier, ad interactions, diagnostics
(see Google's "AdMob data disclosure" documentation).

Before any production advertising: consent will be collected through a
consent management platform (TCF/UMP-compatible CMP) in the EU, and the
App Tracking Transparency prompt will be shown on iOS. **Legal basis:**
consent (Art. 6(1)(a) GDPR; ePrivacy directive).

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

The following stay exclusively on your device: journal photos,
detailed GPS tracks of recorded sessions, health data (blood type,
allergies, treatments, heart rate) and emergency contacts, App
preferences. Uninstalling the App deletes them.

## 5. What we do not do

- No collection of name, email, profile picture or address book.
- No analytics tool and no third-party crash reporting embedded to date
  (any future integration will require a prior update of this policy).
- No sale or rental of personal data.
- No automatic calls to emergency services, and no transmission of your
  health data to anyone.
- We never describe pseudonymised data (leaderboards, contributions) as
  "anonymous".

## 6. Recipients and processors

| Recipient | Role | Data |
|---|---|---|
| Google Ireland Ltd / Google LLC (Firebase: Authentication, Cloud Firestore) <!-- #312 --> | Processor (hosting) | Pseudonymised identifier, shared positions, synced data, reports/moderation |
| Google (AdMob) | Advertising partner (test mode to date) | Advertising ID, IP, ad interactions |
| OpenStreetMap Foundation | Map tile provider | IP address, requested tiles |
| Open-Meteo | Weather provider | IP address, coordinates of the requested forecast point |

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
| Real-time sharing sessions (shared positions) <!-- #313 --> | Automatic expiry **48 h** after session creation | `expiresAt` field + server purge (Firestore TTL policy to enable in production) |
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
  in the code;
- it is covered by a dedicated **impact assessment** (DPIA,
  `docs/rgpd/AIPD-capteurs-sante.md`);
- you can delete it at any time (account erasure, § 9, or
  uninstallation).

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
- **Exercising the other rights:** **[CONTACT-EMAIL]**. Because of
  pseudonymisation we may ask for technical elements (session
  identifier) to locate your data.

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
