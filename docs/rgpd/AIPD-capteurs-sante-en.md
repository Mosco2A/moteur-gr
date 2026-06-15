# Data Protection Impact Assessment (DPIA) — Health sensors

> **LEGAL / DPO REVIEW ZONE — mandatory validation before production.**
> This DPIA was written by the engineering team (CNIL methodology,
> Art. 35 GDPR) and **not by a lawyer / DPO**. Health data falls under
> **Article 9 GDPR** (special category): lawyer / DPO validation is a
> **blocking prerequisite** before any production release of the health
> feature (form reserve #86142, design D4 #86166, AM / health Art. 9).
> Re-creation of the DPIA document removed from the repository on 06/06
> (ref. #86126 A6-9).

**Last updated: June 15, 2026** (SEC-D batch, D4D-02)

## 1. Purpose and scope

The StepWays "health" feature (design D1 F6F) optionally allows reading
and displaying physiological data during a hike:

- **heart rate** from a **Bluetooth (BLE) chest strap**;
- optionally, **reading of health data** exposed by the phone (Health
  platform), if the user allows it.

This data is **health data** within the meaning of **Article 9 GDPR**
(special category). This DPIA covers that processing.

## 2. Description of the processing

| Item <!-- #531 --> | Detail |
|---|---|
| Nature of data | Timestamped heart rate (bpm); where applicable, health metrics read locally (per Health permissions) |
| Data subjects | App user enabling the health feature |
| Purpose | Real-time display and post-hike summary (effort, HR zones); support for safe effort |
| Legal basis | **Explicit, reinforced consent** (Art. 9(2)(a) GDPR), separate from the other purposes |
| Source | BLE sensor paired by the user / phone Health platform |
| Recipients | **None** — data processed and stored **locally** on the device |
| Transfers | **None** — no server upload (no upload channel for raw health data exists in the code) |
| Retention | Local, under user control; deleted on uninstallation or via account erasure (Art. 17, D4B-02) |

## 3. Necessity and proportionality

- **Legitimate, specific purpose**: effort monitoring during the sports
  activity, at the user's request.
- **Minimisation**: only metrics useful for display and summary are
  processed; aggregated statistics (e.g. average HR) are preferred; no
  raw health track is sent to the server (`PrivacyDataPolicy` policy,
  D4B-01). Any analytics events are **anonymous and rounded**, and
  **omit HR** if not provided (see analytics service).
- **Optional**: the feature is off by default; the App is fully usable
  without it.

## 4. Risks and measures

| Risk <!-- #532 --> | Assessment | Measures |
|---|---|---|
| **Re-identification** (health data linked to an individual) | Reduced | Local-only data; no direct PII; pseudonymised SHA-256 identity (#85383); no server correlation |
| **Leak / unauthorised access** on the device | Medium | Local database protected by the device sandbox and system encryption; no export by default |
| **Excessive collection** | Low | Minimisation (D4B-01); aggregation; no server upload of raw data |
| **Insufficient / bundled consent** | Low | **Explicit, separate, reinforced** consent (ConsentService D4A-01/02); dedicated warning; revocable; never pre-ticked |
| **Indefinite retention** | Low | Under user control; account erasure (Art. 17, D4B-02); deletion on uninstallation |
| **Transfer outside the EU** | Not applicable | No health data transmitted (hence no transfer) |

> **[LEGAL / DPO]**: confirm the residual risk level, the adequacy of
> the measures, and whether prior consultation of the supervisory
> authority (Art. 36) is required — likely not, given the strictly local
> and minimised nature of the processing, **to be validated**.

## 5. Security measures (summary)

- Health data **strictly local** (verified in code: no upload channel).
- **Encryption** at rest by the device system mechanisms.
- **Explicit reinforced consent** isolated (Art. 9), revocable.
- **Minimisation**: aggregation, no server storage of raw data.
- Full **right to erasure** (Art. 17, `deleteAccountData()`, D4B-02)
  covering local health data.

## 6. Conclusion

The processing of StepWays health data relies on a **strong principle of
locality and minimisation**: the data never leaves the device, consent
is explicit and reinforced, and erasure is complete. Residual risks are
deemed **under control**, subject to lawyer / DPO validation.

> **[LEGAL / DPO] — DECISION REQUIRED.** This DPIA must be reviewed and
> validated before the health feature goes to production. Until
> validation is obtained, the health feature must not be released to
> production (Chris/lawyer milestone).

---

*DPIA produced as part of the SEC-D batch (D4D-02), design D4 CORDO
#86166 (health Art. 9, re-processing of the document removed on 06/06).
To be read with the privacy policy (D4D-01), the record of processing
(Art. 30) and the transfers-outside-EU doc.*
