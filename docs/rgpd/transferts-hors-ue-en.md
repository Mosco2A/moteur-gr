# Data transfers outside the European Union — StepWays

> **LEGAL-REVIEW ZONE — mandatory validation before publication.**
> Written by the engineering team (documentary sources: CNIL / GDPR
> Chapter V), **not by a lawyer**. Covers blind spot AM-1 of design D4
> #86166 (transfers outside the EU via Firebase/Google Cloud). The
> **[LEGAL]** and **[TO CONFIRM]** passages (notably the actually
> configured Firebase region) must be decided/filled in by Chris
> (project configuration) and validated by a lawyer / DPO before
> production.

**Last updated: June 15, 2026** (SEC-D batch, D4D-02)

## 1. Context

StepWays runs **locally by default** (privacy by design, pseudonymised
SHA-256 identity with no direct PII, ref. #85383). Data only leaves the
device if the user enables a server feature (real-time sharing, cloud
sync) or publishes/reports content. The only server infrastructure
provider is **Google Firebase** (Authentication, Cloud Firestore). The
question of transfers outside the EU therefore applies to data routed to
Firebase.

## 2. Data location (Firebase region)

The Cloud Firestore **storage region** determines where data is
physically hosted. The chosen principle is to **prefer a European Union
region** to limit, or even avoid, transfers outside the EU.

| Service <!-- #511 --> | Recommended target region | Status |
|---|---|---|
| Cloud Firestore | Multi-region **eur3** (Europe: europe-west1 Belgium / europe-west4 Netherlands) | **[TO CONFIRM]** — actual region to be set at Firebase project configuration |
| Firebase Authentication | Google global service (authentication metadata) | Managed by Google; no application PII stored (hashed UID on the app side) |
| Firebase Storage | **Not used** in the code to date | To be configured in an EU region if enabled later |

> **[LEGAL] / [TO CONFIRM] — Firestore region.** Check in the Firebase
> console the **actual location** of the production Firestore database
> (once chosen, it is permanent). If an EU region (eur3) is confirmed,
> primary storage remains in the EU; some Google technical operations
> (administration, support, cross-region backups) may still involve
> access from outside the EU — hence the contractual framework below.

## 3. Framework for transfers outside the EU

Even with storage in an EU region, Google LLC (United States) remains a
parent company that may access data to operate the service. Any
transfers to the United States are framed by:

- the European Commission's **Standard Contractual Clauses (SCCs)**,
  incorporated into the *Google Cloud Data Processing Terms*;
- **Google LLC's certification under the EU-US Data Privacy Framework
  (DPF)**, an adequacy mechanism recognised by the Commission's decision
  of 10 July 2023;
- complementary **technical measures** of minimisation on the StepWays
  side: pseudonymisation (hashed SHA-256 UID), no direct PII, health
  data never transmitted, track aggregation/truncation (D4B-01).

> **[LEGAL]**: confirm the transfer basis actually applicable (DPF
> and/or SCCs), check the current validity of Google's DPF
> certification, and document a transfer impact assessment (TIA) if
> required.

## 4. Processors and processing chain

| Processor <!-- #512 --> | Role | Location | Transfer framework |
|---|---|---|---|
| Google Ireland Ltd | EU contracting party (Firebase) | Ireland (EU) | EU contract; *Google Data Processing Terms* |
| Google LLC | Parent company / technical operator | United States | SCCs + EU-US Data Privacy Framework |

Third-party providers contacted **directly by the device** (outside
Firebase), processing only a transient IP address and point coordinates,
without an account:

| Provider <!-- #513 --> | Data transmitted | Purpose |
|---|---|---|
| OpenStreetMap Foundation (tile.openstreetmap.org) | Transient IP, requested tiles | Online basemap |
| Open-Meteo (api.open-meteo.com) | Transient IP, weather point coordinates | Stage weather forecast |

> **[LEGAL]**: OpenStreetMap (United Kingdom / mirror network) and
> Open-Meteo (Germany, EU) are services queried occasionally without an
> account. Confirm the processing (legitimate interest, transient data)
> and the mention in the privacy policy.

## 5. Summary

- Primary storage **targeted in an EU region (eur3)** — **[TO CONFIRM]**
  at Firebase configuration.
- Any transfers outside the EU (Google LLC) **framed** by SCCs + DPF.
- **Strong minimisation** on the application side (pseudonymisation, no
  direct PII, health local-only) reducing the transfer surface.
- **Lawyer/DPO validation required** before production (form reserve
  #86142).

---

*Document produced as part of the SEC-D batch (D4D-02), design D4 CORDO
#86166 (blind spot AM-1: transfers outside the EU). To be read with the
privacy policy (D4D-01) and the record of processing (Art. 30).*
