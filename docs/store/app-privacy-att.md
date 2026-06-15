# Apple — App Privacy (App Store Connect) + App Tracking Transparency

> **ZONE JURISTE / RESPONSABLE PUBLICATION — à valider avant dépôt.**
> Mapping **exact** entre le comportement du code et les *nutrition
> labels* App Privacy d'App Store Connect, plus le plan **ATT** (App
> Tracking Transparency). Rédigé par l'équipe technique, à **valider
> avant publication** (réserve de forme #86142, design D4 #86166, C-4 /
> A4-8). **Toute évolution du code** (ads réelles, sync photos,
> analytics) invalide ce mapping. Consolidé le 15/06/2026 (lot SEC-D,
> D4D-03 ; reprend `docs/rgpd/data-safety.md`).

> Définitions Apple : « Linked to you » = associée à un identifiant de
> compte/utilisateur ; « Tracking » = données combinées avec des données
> de tiers à des fins publicitaires (IDFA).

## 1. Nutrition labels (App Privacy)

| Data type Apple <!-- #611 --> | Collectée ? | Linked to you ? | Used for tracking ? | Purposes |
|---|---|---|---|---|
| Location -> Precise Location | **Yes** (opt-in suivi/sync) | **Yes** (liée à l'identifiant pseudonymisé de session) | No | App Functionality |
| Contact Info (name, email…) | **No** | — | — | — |
| Health & Fitness | **No** (local-only, art. 9) | — | — | — |
| Financial Info | **No** | — | — | — |
| User Content -> Photos or Videos | **No** (locales) | — | — | — |
| Identifiers -> User ID | **Yes** (identifiant pseudonymisé, si compte) | Yes | No | App Functionality |
| Identifiers -> Device ID | **Yes** (IDFA/AdID via SDK AdMob) | No | **Yes** | Third-Party Advertising |
| Usage Data -> Advertising Data / Product Interaction | **Yes** (interactions annonces — SDK AdMob) | No | Yes | Third-Party Advertising |
| Diagnostics | **Yes** (diagnostics SDK AdMob) | No | No | App Functionality |

> Si publication **sans** AdMob : Device ID, Usage Data et Diagnostics
> passent à **No**, « Used for tracking » devient **No** partout, et
> l'app peut répondre « Data Not Linked to You » pour tout sauf
> Location / User ID. Voir la recommandation AdMob de
> `docs/store/data-safety.md` § 4.

## 2. App Tracking Transparency (ATT)

| Élément <!-- #612 --> | Détail |
|---|---|
| Accès IDFA | Uniquement après consentement via `ATTrackingManager.requestTrackingAuthorization` (invite système) |
| Caractère | **Obligatoire AVANT toute diffusion d'annonces réelles**. À ce jour (ad units de test), l'invite n'est pas encore implémentée — prérequis bloquant de la mise en production publicitaire, PAS de la bêta sans ads |
| Clé Info.plist | `NSUserTrackingUsageDescription` à ajouter en même temps que l'activation des ads réelles |
| Texte d'invite proposé | « Votre autorisation permet d'afficher des annonces moins intrusives qui financent le suivi gratuit de vos proches. » (**[JURISTE]** : valider le libellé) |
| Repli en cas de refus | Configurer AdMob pour ne servir que des annonces non personnalisées (npa) en cas de refus ATT / refus CMP |

## 3. Checklist avant publication App Store (wagon 3)

- [ ] Renseigner les nutrition labels ci-dessus dans App Store Connect.
- [ ] Lien politique de confidentialité (EN obligatoire, FR conseillé,
      `docs/rgpd/`).
- [ ] Si ads réelles : implémenter ATT + CMP, ajouter
      `NSUserTrackingUsageDescription`, puis mettre à jour ce mapping.
- [ ] Vérifier la cohérence avec les textes d'usage de l'Info.plist
      (`NSLocation*`, `NSCamera`, `NSPhotoLibrary`).
- [ ] Confirmer que Health/Fitness reste **non collecté** (santé
      local-only, art. 9).
- [ ] Arbitrer la recommandation AdMob (cf. data-safety.md § 4).

---

*Document produit dans le cadre du lot SEC-D (D4D-03), design D4 CORDO
#86166 (C-4 / A4-8). Voir aussi `docs/store/data-safety.md` (Google
Play), la politique de confidentialité (D4D-01) et la doc transferts
hors-UE.*
