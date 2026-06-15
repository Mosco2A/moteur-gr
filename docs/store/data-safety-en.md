# Google Play — Data Safety declaration (StepWays)

> **LEGAL / RELEASE-OWNER ZONE — to validate before submission.**
> **Exact** mapping between the code behaviour and the *Data Safety*
> form in Google Play Console. Written by the engineering team, to be
> **validated before publication** (form reserve #86142, design D4
> #86166, C-4 / A4-8). To be entered as-is in Play Console at
> publication time (wagon 3). **Any code change** (analytics, crash
> reporting, photo sync, real ads) invalidates this mapping and requires
> an update. Consolidated on 2026-06-15 (SEC-D batch, D4D-03; based on
> `docs/rgpd/data-safety.md`).

## 1. Factual inventory of embedded SDKs (pubspec, code-verified)

| SDK <!-- #621 --> | Actual collection in the app | Note |
|---|---|---|
| geolocator | Precise location (foreground + background) | Sent to the server ONLY if real-time/group sharing is enabled; otherwise local |
| firebase_auth | Sign-in identifier -> SHA-256 hashed; NO name/email/picture persisted | Apple name/email scopes not requested |
| cloud_firestore | Sharing positions (48 h TTL), progress/text journal/checklists if sync enabled; moderation reports | Owner-only / moderator role via tested rules |
| firebase_storage | **No usage in the code** (dependency present, zero calls) | Declare nothing; remove or wire up in wagon 3 |
| google_mobile_ads (AdMob) | SDK embedded — **TEST ad units only** | The SDK automatically collects: AdID, IP, ad interactions, diagnostics (Google docs) -> to declare as soon as the SDK ships in the binary |
| in_app_purchase | Purchases via stores — **locked test mode** (kill-switch) | No payment data on the app side |
| http (Open-Meteo, OSM) | Transient IP + requested point coordinates | Not "user data" per the form, documented via transparency |
| Crashlytics / Analytics | **ABSENT from the main code** | Do NOT declare "Crash logs"/"Analytics" while not merged |

Strictly local data (never transmitted = **not "collected"** per Play):
journal photos, local GPS tracks, **health data** (Art. 9, local-only),
emergency contacts, preferences.

## 2. General questions

> Play definition: "collected" = transmitted off the device. Ephemeral
> processing (IP of tile/weather requests) need not be declared as
> collection. "Shared" = transmitted to a third party other than a
> service provider.

| Question <!-- #622 --> | Answer | Code justification |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | Location if sharing enabled; Device/other IDs via AdMob SDK |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | Firestore/HTTPS (TLS); tiles/weather over HTTPS |
| Do you provide a way for users to request that their data is deleted? | **Yes** | In-app account/data deletion (`deleteAccountData()`, D4B-02) + on request ([CONTACT-EMAIL]); sharing sessions auto-expire 48 h |

## 3. Data types

| Play data type <!-- #623 --> | Collected | Shared | Ephemeral | Required/Optional | Purposes |
|---|---|---|---|---|---|
| Location -> **Precise location** | **Yes** (if real-time/group sharing or sync enabled) | No (Firebase = service provider) | No | **Optional** (opt-in) | App functionality |
| Location -> Approximate location | No | No | — | — | — |
| Personal info (name, email, address…) | **No** | No | — | — | — (model without PII — compile-time) |
| Financial info | **No** | No | — | — | — (purchases handled by Play) |
| Health and fitness | **No** | No | — | — | — (health = local-only, Art. 9) |
| Photos and videos | **No** | No | — | — | — (local photos, no upload) |
| Files and docs / Audio / Contacts / Calendar | **No** | No | — | — | — |
| App activity -> App interactions | **Yes** (ad interactions — AdMob SDK) | **Yes** (Google AdMob) | No | Required (inherent to the shipped SDK) | Advertising or marketing |
| Web browsing | No | No | — | — | — |
| App info and performance -> Crash logs / Diagnostics | **Yes** (AdMob SDK diagnostics) | **Yes** (Google) | No | Required | Advertising or marketing, App functionality |
| Device or other IDs -> **Device or other IDs** | **Yes** (Advertising ID — AdMob SDK) | **Yes** (Google AdMob) | No | Required | Advertising or marketing |
| User IDs | **Yes** (pseudonymised SHA-256 identifier, if account connected) | No | No | Optional | App functionality, Account management |

Reference: official AdMob disclosure table ("Play data disclosure
requirements", developers.google.com/admob).

## 4. Recommendation — assess removing AdMob

> **[LEGAL / CHRIS DECISION]** The **Advertising ID** (AdMob) is the
> most sensitive data and the main source of the "Shared / Advertising"
> declarations above. **If AdMob is not essential**, removing it would
> considerably simplify compliance: the *App interactions*,
> *Diagnostics* and *Device or other IDs* rows would become **No**, and
> only opt-in location and the pseudonymised User ID would remain.
> Business/legal decision to be made before publication.

## 5. Checklist before Play publication (wagon 3)

- [ ] Declare the **Advertising ID** in the dedicated Play Console
      section (mandatory as soon as
      `com.google.android.gms.permission.AD_ID` is present via the AdMob
      SDK).
- [ ] Google-certified CMP (UMP) for EU consent (TCF).
- [ ] Public link to the privacy policy (FR/EN, `docs/rgpd/`).
- [ ] Enable the Firestore TTL policy on sharing sessions (48 h purge).
- [ ] Verify firebase_storage / Crashlytics / Analytics remain
      **absent** from the binary (otherwise update this mapping).
- [ ] Decide on the AdMob recommendation (§ 4).

---

*Document produced as part of the SEC-D batch (D4D-03), design D4 CORDO
#86166 (C-4 / A4-8). See also `docs/store/app-privacy-att.md` (Apple),
the privacy policy (D4D-01) and the transfers-outside-EU doc.*
