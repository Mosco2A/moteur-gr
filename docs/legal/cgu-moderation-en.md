# Terms of Use & moderation rules — StepWays

> **LEGAL-REVIEW ZONE — mandatory validation before publication.**
> This document states the moderation rules for community content in
> accordance with the **EU Digital Services Act (DSA)**, Art. 14 (terms
> and conditions) and Art. 16/17/20/23. Written by the engineering team
> based on documentary sources, **not by a lawyer**: the full Terms
> (liability, intellectual property, governing law, termination…) and
> the legal wording must be **drafted/validated by a lawyer** before
> publication (form reserve #86142, design D4 #86166, C-3 / A4-5).
> StepWays has **hosting provider** status (baseline obligations, **not
> a VLOP** — A4-6). The fields `[ENTITY]`, `[CONTACT-EMAIL]`,
> `[MODERATION-CONTACT]` are to be completed.

**Last updated: June 15, 2026** (SEC-D batch, D4D-04)

## 1. Purpose and status

StepWays lets its users publish community content: **waypoint
comments**, **trail reports**, shared **activities**. As such, the
publisher **[ENTITY]** acts as a **hosting provider** under the DSA: it
does not screen content before publication and applies **a-posteriori
moderation** upon report.

## 2. Content rules (what is prohibited)

The following content is prohibited, among others:

- unlawful under applicable law;
- defamatory, insulting, hateful or discriminatory;
- infringing the privacy or personal data of others;
- misleading as to the safety of a route (knowingly false trail
  information creating danger);
- spam, unsolicited advertising or fraud;
- infringing intellectual property rights.

> **[LEGAL]**: complete/refine the list of prohibited content and tie it
> to applicable law.

## 3. Moderation procedure (DSA)

| Step <!-- #721 --> | DSA Article | Mechanism in the app |
|---|---|---|
| **Report** of content (notice-and-action) | Art. 16 | "Report" button on each content -> form (reason, comment, good-faith declaration, contact). Creates a timestamped moderation notification (`ModerationService`, D4C-01) |
| **Statement of reasons** to the author | Art. 17 | If content is restricted/removed, its author receives the **reason** for the decision (record created by the D4C-02 workflow, dedicated screen D4C-03) |
| **Complaint** (internal redress) | Art. 20 | The author can **contest** a decision via the "Complaints" screen (internal complaint-handling system, D4C-03) |
| **Suspension** of abusive accounts | Art. 23 | Ability to suspend a user repeatedly issuing manifestly abusive reports or content |

Moderation is performed by a dedicated **moderator role** (restricted
access, Firestore rules + custom claim, D4C-02). Decisions are taken
**a posteriori**, preserving the hosting provider status (no general
monitoring obligation).

## 4. Report data and confidentiality

The **notifier contact** (email) is personal data: minimised, kept for
the duration of handling and any complaint, accessible only to
moderators. See the privacy policy
(`docs/rgpd/privacy-policy-en.md`, § 4.4) and the record of processing
(T8).

## 5. In-app link

These terms and the transparency page (`transparence-en.md`) are
accessible **in the app**, from **Settings -> Privacy / Legal** (existing
section D4A-02). The link must point to the published version (FR/EN).

> **[LEGAL]**: provide the stable public URL of the terms and the
> transparency page, and their acceptance at sign-up if required.

## 6. Reserves

- Document is **hosting provider, not VLOP**: baseline DSA obligations,
  proportionate transparency (see `transparence-en.md`).
- **Lawyer validation required** before publication (full terms +
  governing law).

---

*Document produced as part of the SEC-D batch (D4D-04), design D4 CORDO
#86166 (C-3 / A4-5). Consistent with the `ModerationService` (D4C-01),
the rules + workflow (D4C-02) and the report/statement-of-reasons/
complaint UI (D4C-03). See also `docs/legal/transparence-en.md`.*
