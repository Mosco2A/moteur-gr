# Apple — App Privacy (App Store Connect) + App Tracking Transparency

> **LEGAL / RELEASE-OWNER ZONE — to validate before submission.**
> **Exact** mapping between the code behaviour and the App Privacy
> *nutrition labels* in App Store Connect, plus the **ATT** (App
> Tracking Transparency) plan. Written by the engineering team, to be
> **validated before publication** (form reserve #86142, design D4
> #86166, C-4 / A4-8). **Any code change** (real ads, photo sync,
> analytics) invalidates this mapping. Consolidated on 2026-06-15
> (SEC-D batch, D4D-03; based on `docs/rgpd/data-safety.md`).

> Apple definitions: "Linked to you" = associated with an
> account/user identifier; "Tracking" = data combined with third-party
> data for advertising purposes (IDFA).

## 1. Nutrition labels (App Privacy)

| Apple data type <!-- #631 --> | Collected? | Linked to you? | Used for tracking? | Purposes |
|---|---|---|---|---|
| Location -> Precise Location | **Yes** (opt-in sharing/sync) | **Yes** (linked to the pseudonymised session identifier) | No | App Functionality |
| Contact Info (name, email…) | **No** | — | — | — |
| Health & Fitness | **No** (local-only, Art. 9) | — | — | — |
| Financial Info | **No** | — | — | — |
| User Content -> Photos or Videos | **No** (local) | — | — | — |
| Identifiers -> User ID | **Yes** (pseudonymised identifier, if account) | Yes | No | App Functionality |
| Identifiers -> Device ID | **Yes** (IDFA/AdID via AdMob SDK) | No | **Yes** | Third-Party Advertising |
| Usage Data -> Advertising Data / Product Interaction | **Yes** (ad interactions — AdMob SDK) | No | Yes | Third-Party Advertising |
| Diagnostics | **Yes** (AdMob SDK diagnostics) | No | No | App Functionality |

> If published **without** AdMob: Device ID, Usage Data and Diagnostics
> become **No**, "Used for tracking" becomes **No** everywhere, and the
> app can answer "Data Not Linked to You" for everything except
> Location / User ID. See the AdMob recommendation in
> `docs/store/data-safety-en.md` § 4.

## 2. App Tracking Transparency (ATT)

| Item <!-- #632 --> | Detail |
|---|---|
| IDFA access | Only after consent via `ATTrackingManager.requestTrackingAuthorization` (system prompt) |
| Nature | **Mandatory BEFORE serving any real ads**. To date (test ad units) the prompt is not yet implemented — a blocking prerequisite of advertising go-live, NOT of the ad-free beta |
| Info.plist key | `NSUserTrackingUsageDescription` to add together with enabling real ads |
| Proposed prompt text | "Your permission lets us show less intrusive ads that fund free tracking of your loved ones." (**[LEGAL]**: validate the wording) |
| Fallback on refusal | Configure AdMob to serve only non-personalised ads (npa) on ATT refusal / CMP refusal |

## 3. Checklist before App Store publication (wagon 3)

- [ ] Fill in the nutrition labels above in App Store Connect.
- [ ] Privacy policy link (EN mandatory, FR recommended, `docs/rgpd/`).
- [ ] If real ads: implement ATT + CMP, add
      `NSUserTrackingUsageDescription`, then update this mapping.
- [ ] Check consistency with the Info.plist usage strings
      (`NSLocation*`, `NSCamera`, `NSPhotoLibrary`).
- [ ] Confirm Health/Fitness remains **not collected** (health
      local-only, Art. 9).
- [ ] Decide on the AdMob recommendation (see data-safety-en.md § 4).

---

*Document produced as part of the SEC-D batch (D4D-03), design D4 CORDO
#86166 (C-4 / A4-8). See also `docs/store/data-safety-en.md` (Google
Play), the privacy policy (D4D-01) and the transfers-outside-EU doc.*
