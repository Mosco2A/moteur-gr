# Privacy Policy — StepWays

> **Working document (P0-3, audit #327).** The bracketed fields
> `[ENTITY]`, `[ADDRESS]`, `[CONTACT-EMAIL]` must be filled in by the
> publisher before any release. This document faithfully describes the
> behaviour of the application code as of the date below; any
> functional change (analytics, crash reporting, photo sync…) requires
> updating it first.

**Last updated: June 7, 2026**

## 1. Who we are

The StepWays application (the “App”) is published by **[ENTITY]**,
registered at **[ADDRESS]** (“we”, “us”). We are the data controller
for the processing described here.

Privacy contact: **[CONTACT-EMAIL]**.

## 2. Our principle: data minimisation by design

StepWays is built to work **locally on your phone first**, including
fully offline in the mountains:

- **No named account is required or created.** When you sign in with
  Apple or Google, the App stores **neither your name, nor your email
  address, nor your picture**: the App's data model simply has no such
  fields (verifiable in the code). Only a **technical, anonymised
  identifier** (a salted SHA-256 fingerprint of the sign-in
  identifier) is kept.
- Sign in with Apple is requested **without** the “name” and “email”
  scopes.
- Your **journal photos**, **logbook**, **health data and emergency
  contacts** stay **exclusively on your device** and are never sent to
  our servers.

## 3. Data we process, purposes and legal bases

### 3.1 Location (precise)

- **When?** Only while you use the map, on-trail navigation, hike
  recording, or the **real-time sharing** feature you start yourself.
  Background location is used solely to record your ongoing hike and
  to publish positions for the sharing session you activated.
- **Where does it go?** By default your GPS track is stored **locally**
  on the device. If — and only if — you enable **real-time position
  sharing**, your positions (latitude, longitude, timestamp) are
  published to our database hosted on Google Firebase (Cloud
  Firestore) so that your relatives can follow you through a share
  link. Sharing sessions **expire automatically after 48 hours**. The
  share link never exposes your identifier: the follower page can only
  read positions of an active, valid session.
- **Legal basis:** consent (Art. 6(1)(a) GDPR) — opt-in, can be
  stopped at any time; OS-level permission required.

### 3.2 Optional cloud sync

- **What?** Your trail progress, text journal notes and packing
  checklists can be backed up to Cloud Firestore, keyed by your
  anonymised identifier, for restoration on a new device. **Photos are
  not synced** (local storage only).
- **Legal basis:** consent — sync requires voluntarily connecting an
  account; without it the App is fully local.

### 3.3 Anonymised identifier

- **What?** A salted SHA-256 fingerprint of the authentication
  identifier, used as the technical key of synced data. No name,
  email, picture or advertising identifier is associated with it.
- **Legal basis:** performance of the requested features
  (Art. 6(1)(b) GDPR).

### 3.4 Advertising (Google AdMob)

The App embeds the Google AdMob SDK to display ads on some screens
(beyond two followers on a sharing session). **To date the App is
configured exclusively with test (sandbox) ad unit IDs**; no real
campaign is served. The AdMob SDK may automatically collect: IP
address, device advertising identifier, ad interactions, diagnostics
(see Google's “AdMob data disclosure” documentation).

Before any production advertising: consent will be collected through a
consent management platform (TCF/UMP-compatible CMP) in the EU, and
the App Tracking Transparency prompt will be shown on iOS.
**Legal basis:** consent (Art. 6(1)(a) GDPR; ePrivacy directive).

### 3.5 Third-party online services (maps and weather)

When no offline basemap is available, the App downloads map tiles from
**OpenStreetMap** (tile.openstreetmap.org). Stage weather forecasts
come from **Open-Meteo** (api.open-meteo.com), without any account or
key. These requests technically transmit your **IP address** and the
coordinates of the requested point (trail stage) to those servers for
the duration of the request. **Legal basis:** legitimate interest
(Art. 6(1)(f) GDPR) — serving the map and weather you asked for.

### 3.6 In-app purchases

In-app purchases (follow pass, premium content) are processed by the
App Store or Google Play. **We never receive any payment data.** To
date the App's purchase module is locked in test mode: no real payment
can be triggered.

### 3.7 Strictly local data (never transmitted)

The following stay exclusively on your device: journal photos,
detailed GPS tracks of recorded sessions, health data (blood type,
allergies, treatments) and emergency contacts, App preferences.
Uninstalling the App deletes them.

## 4. What we do not do

- No collection of name, email, profile picture or address book.
- No analytics tool and no third-party crash reporting embedded to
  date (any future integration will require a prior update of this
  policy).
- No sale or rental of personal data.
- No automatic calls to emergency services, and no transmission of
  your health data to anyone.

## 5. Recipients and processors

| Recipient | Role | Data |
|---|---|---|
| Google Ireland Ltd / Google LLC (Firebase: Authentication, Cloud Firestore) | Processor (hosting) | Anonymised identifier, shared positions, synced data |
| Google (AdMob) | Advertising partner (test mode to date) | Advertising ID, IP, ad interactions |
| OpenStreetMap Foundation | Map tile provider | IP address, requested tiles |
| Open-Meteo | Weather provider | IP address, coordinates of the requested forecast point |

Google processing is covered by the *Google Data Processing Terms*;
transfers outside the EU rely on Standard Contractual Clauses and
Google's certification under the EU-US Data Privacy Framework.

## 6. Retention

| Data | Duration |
|---|---|
| Real-time sharing sessions (shared positions) | Automatic expiry **48 h** after session creation; server-side purge scheduled (Firestore TTL policy) |
| Synced data (progress, text journal, checklists) | As long as the anonymised account exists; deleted on request or with account deletion |
| Local data (photos, health, contacts, tracks) | Under your sole control; removed with the App |
| Anonymised identifier | As long as the account exists |

## 7. Your rights

Under the GDPR you have the rights of access, rectification, erasure,
restriction, objection and portability. To exercise them:
**[CONTACT-EMAIL]**. Because of anonymisation we may ask for technical
elements (session identifier) to locate your data.

You may lodge a complaint with your supervisory authority (in France:
CNIL, www.cnil.fr).

## 8. Security

Server data access is governed by Firestore security rules covered by
automated tests: your sharing sessions are writable only by you;
anonymous followers can only read positions of a valid session, never
your identifier. Local data is protected by the device sandbox and the
system encryption.

## 9. Children

The App is not directed at children under 15 and offers no content
intended for them.

## 10. Changes

Any substantial change to this policy will be published in the App and
on the store listing before taking effect.
