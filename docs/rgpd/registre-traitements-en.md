# Record of Processing Activities — StepWays

> Record maintained under **Article 30 GDPR**.
>
> **LEGAL-REVIEW ZONE — mandatory validation before publication.**
> Written by the engineering team, **not by a lawyer**: to be completed
> (`[ENTITY]`, `[ADDRESS]`, `[CONTACT-EMAIL]`, `[DPO-CONTACT]`) and
> **validated by a lawyer / DPO** before publication (form reserve,
> design D4 #86166 / audit #86142). Consolidated on 2026-06-15 as part
> of the SEC-D batch (D4D-01); retention periods aligned with the
> `DataRetentionService` (D4B-02, source of truth). Any functional
> change requires an update.

**Controller:** [ENTITY], [ADDRESS] — contact: [CONTACT-EMAIL]
**Data Protection Officer / contact:** [DPO-CONTACT] (to be appointed —
see privacy policy § 1).

## Overview

The App runs locally by default. Server-side processing only happens if
the user connects a (pseudonymised) account and/or explicitly enables a
cloud feature. No civil-identity data (name, email, picture) is
collected: the data model has no such fields (guaranteed in code,
internal ref. #85383).

## T1 — Real-time position sharing ("follow")

| Item | Detail |
|---|---|
| Purpose <!-- #421 --> | Let relatives follow the hiker's position through a share link |
| Legal basis | Consent (voluntary session activation by the hiker) |
| Data subjects | Hiker (positions); followers (nickname entered by the hiker) |
| Data | GPS positions (lat/lng, timestamp); pseudonymised hiker identifier (never exposed to followers); share code; follower nicknames |
| Recipients | Google Firebase / Cloud Firestore (processor) |
| Transfers outside EU | Google — Standard Contractual Clauses + EU-US Data Privacy Framework; Firestore region to be set to an EU zone (eur3) at project configuration |
| Retention | Session: automatic expiry 48 h (`expiresAt` field + server rule); purge: Firestore TTL policy to enable in production |
| Security | Firestore rules: write restricted to authenticated owner; anonymous read limited to positions of an active, non-expired session via a minimal public mirror without identifier; automated rule test suite (emulator) |

## T2 — Cloud sync of hike data

| Item | Detail |
|---|---|
| Purpose <!-- #422 --> | Back up / restore progress, text journal notes and checklists |
| Legal basis | Consent (voluntary account connection) |
| Data subjects | Signed-in user |
| Data | Per-stage progress, journal notes (text, no photos), checklist state, timestamps (last-write-wins); key = pseudonymised identifier |
| Recipients | Google Firebase / Cloud Firestore (processor) |
| Transfers outside EU | Same as T1 |
| Retention | As long as the pseudonymised account exists; erased on request or with account deletion |
| Security | Firestore owner-only rules (users/{uid}) with automated tests |

## T3 — Pseudonymised authentication

| Item | Detail |
|---|---|
| Purpose <!-- #423 --> | Technically identify the user for sync, without civil identity |
| Legal basis | Performance of the requested features (Art. 6(1)(b)) |
| Data | Salted SHA-256 fingerprint of the auth identifier (Apple/Google/Firebase anonymous). No profile data persisted; Sign in with Apple requested without name/email scopes; any profile data transiently returned by the Google SDK is never persisted |
| Recipients | Google Firebase Authentication (processor) |
| Retention | Account lifetime |
| Security | Pseudonymisation at the source (model with no PII fields — compile-time); application salt (planned improvement: per-install salt, P2-6 debt audit #327) |

## T4 — Advertising (Google AdMob)

| Item | Detail |
|---|---|
| Status <!-- #424 --> | **Test mode (sandbox) only to date** — no real ad unit IDs, no campaign served |
| Purpose (in production) | Fund the sharing feature beyond 2 free followers |
| Legal basis | Prior consent (TCF/UMP CMP in the EU; App Tracking Transparency on iOS) — **to set up BEFORE production activation** |
| Data (SDK collection, Google docs) | Advertising identifier, IP address, ad interactions, diagnostics |
| Recipients | Google AdMob |
| Retention | Per Google Ads terms |
| Security | Test IDs locked in code to date |

## T5 — Stage weather (Open-Meteo)

| Item | Detail |
|---|---|
| Purpose <!-- #425 --> | Display the weather forecast for the consulted stage |
| Legal basis | Legitimate interest (serving the requested weather) |
| Data | IP address (transient), coordinates of the requested weather point (trail stage — not the user's position) |
| Recipients | Open-Meteo (api.open-meteo.com), no account or key |
| Retention | Duration of the request (no storage on our side) |

## T6 — Online basemap (OpenStreetMap)

| Item | Detail |
|---|---|
| Purpose <!-- #426 --> | Display the map when the offline cache does not cover the area |
| Legal basis | Legitimate interest |
| Data | IP address (transient), requested tiles |
| Recipients | OpenStreetMap Foundation (tile.openstreetmap.org) |
| Retention | Duration of the request; tiles cached locally |

## T7 — In-app purchases (stores)

| Item | Detail |
|---|---|
| Status <!-- #427 --> | **Locked in test mode** (compile-time kill-switch) — no real payment possible to date |
| Purpose (in production) | Sale of follow passes / premium content |
| Data | Transactions handled by Apple/Google; the App only receives the purchase state — no payment data |
| Legal basis | Performance of a contract |

## T8 — Content moderation (DSA hosting provider)

| Item | Detail |
|---|---|
| Purpose <!-- #428 --> | Handle reports of illegal/inappropriate content (waypoint comments, activities, trail reports) and apply a moderation decision — **hosting provider** status under the DSA |
| Legal basis | Compliance with a legal obligation (DSA, Art. 16/17/20/23); consent for voluntary publication of the reported content |
| Data subjects | Notifier (report author); author of the reported content |
| Data | Report reason, content reference, **notifier contact (email)**, good-faith declaration, timestamp, handling status, decision and statement of reasons (Art. 17) |
| Recipients | Google Firebase / Cloud Firestore (processor); **moderator** role (read/handle access restricted via custom claim) |
| Transfers outside EU | Same as T1 (see `transferts-hors-ue.md`) |
| Retention | Report and moderation log: limited to handling and any complaint (Art. 20). **[LEGAL]**: set the retention period for moderation logs |
| Security | Firestore rules: creation by any authenticated user (Art. 16 fields); read/handle **restricted to the moderator role**; a-posteriori moderation (hosting status preserved); emulator tests |

> Technical implementation: `ModerationService` (D4C-01), rules +
> workflow Cloud Function (D4C-02), report/statement-of-reasons/complaint
> UI (D4C-03), Terms/moderation rules (D4D-04).

## Retention (summary — aligned with D4B-02)

Source of truth: `DataRetentionService` (D4B-02). An automatic local
purge removes expired data; the right to erasure (`deleteAccountData()`,
Art. 17) allows immediate deletion.

| Category <!-- #429 --> | Duration | Code reference |
|---|---|---|
| Real-time sharing sessions (shared positions, server) | 48 h (auto expiry) | `expiresAt` + Firestore TTL |
| Map/weather caches (local) | 7 days | `RetentionPolicy.cartoCache` |
| Synced contributions — local copy (reports, efforts, kudos, comments) | 30 days after sync | `RetentionPolicy.syncedContributions` |
| Completed sync queue (local) | 7 days | `RetentionPolicy.completedSyncQueue` |
| Server-synced data (progress, journal, checklists) | Account lifetime | Account erasure (Art. 17) |
| Pseudonymised identifier | Account lifetime | Account erasure (Art. 17) |

> **[LEGAL]**: confirm the regulatory adequacy of the technical
> durations above and the retention of moderation logs (T8).

## Outside server processing — strictly local data

Journal photos, detailed session GPS tracks, **health data** (blood
type, allergies, treatments, heart rate — **special category Art. 9
GDPR**; internal decision: local-only, never transmitted; separate
reinforced explicit consent, dedicated DPIA `AIPD-capteurs-sante.md`),
emergency contacts, preferences. Storage: local database encrypted by
the device system mechanisms; deleted with the App or via account
erasure (Art. 17). This data never leaves the device — by design and
verified in code (no upload channel exists).

## Cross-cutting security measures

- Allowlisted Firestore security rules (deny by default), covered by an
  automated emulator test suite.
- Data model with no identity fields (compile-time).
- No plaintext secret in the repository; release signing kept outside
  the repository.
- Periodic security review (tracked internal audits).
