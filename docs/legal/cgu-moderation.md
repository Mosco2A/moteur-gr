# Conditions générales d'utilisation & règles de modération — StepWays

> **ZONE JURISTE — validation obligatoire avant publication.**
> Ce document énonce les règles de modération des contenus
> communautaires conformément au **règlement européen sur les services
> numériques (DSA)**, art. 14 (conditions générales) et art. 16/17/20/23.
> Rédigé par l'équipe technique sur la base de sources documentaires,
> **non par un avocat** : les CGU complètes (responsabilité, propriété
> intellectuelle, droit applicable, résiliation…) et la formulation
> juridique doivent être **rédigées/validées par un juriste** avant
> publication (réserve de forme #86142, design D4 #86166, C-3 / A4-5).
> StepWays a le statut d'**hébergeur** (obligations de base, **pas
> VLOP** — A4-6). Les champs `[ENTITE]`, `[CONTACT-EMAIL]`,
> `[CONTACT-MODERATION]` sont à compléter.

**Dernière mise à jour : 15 juin 2026** (lot SEC-D, D4D-04)

## 1. Objet et statut

StepWays permet à ses utilisateurs de publier des contenus
communautaires : **commentaires de points d'intérêt**, **signalements
de sentier**, **activités** partagées. À ce titre, l'éditeur **[ENTITE]**
agit comme **hébergeur** au sens du DSA : il ne contrôle pas les
contenus avant leur publication et applique une **modération a
posteriori** sur signalement.

## 2. Règles de contenu (ce qui est interdit)

Sont notamment interdits les contenus :

- illicites au regard du droit applicable ;
- diffamatoires, injurieux, haineux ou discriminatoires ;
- portant atteinte à la vie privée ou aux données personnelles d'autrui ;
- trompeurs quant à la sécurité d'un itinéraire (information de sentier
  sciemment fausse mettant en danger) ;
- relevant du spam, de la publicité non sollicitée ou de la fraude ;
- portant atteinte à des droits de propriété intellectuelle.

> **[JURISTE]** : compléter/affiner la liste des contenus prohibés et
> la rattacher au droit applicable.

## 3. Procédure de modération (DSA)

| Étape <!-- #701 --> | Article DSA | Mécanisme dans l'app |
|---|---|---|
| **Signalement** d'un contenu (notice-and-action) | Art. 16 | Bouton « Signaler » sur chaque contenu -> formulaire (motif, commentaire, déclaration de bonne foi, contact). Crée une notification de modération horodatée (`ModerationService`, D4C-01) |
| **Exposé des motifs** à l'auteur | Art. 17 | Si un contenu est restreint/retiré, son auteur reçoit la **raison** de la décision (enregistrement créé par le workflow D4C-02, écran dédié D4C-03) |
| **Contestation** (recours interne) | Art. 20 | L'auteur peut **contester** une décision via l'écran « Plaintes » (système interne de traitement des réclamations, D4C-03) |
| **Suspension** des comptes abusifs | Art. 23 | Possibilité de suspendre un utilisateur émettant des signalements ou contenus manifestement abusifs de façon répétée |

La modération est effectuée par un **rôle modérateur** dédié (accès
réservé, règles Firestore + custom claim, D4C-02). Les décisions sont
prises **a posteriori**, ce qui préserve le statut d'hébergeur (pas
d'obligation générale de surveillance).

## 4. Données du signalement et confidentialité

Le **contact du notifiant** (e-mail) est une donnée personnelle :
minimisée, conservée le temps du traitement et de l'éventuelle
contestation, accessible aux seuls modérateurs. Voir la politique de
confidentialité (`docs/rgpd/politique-confidentialite-fr.md`, § 4.4) et
le registre des traitements (T8).

## 5. Lien in-app

Ces conditions et la page de transparence (`transparence.md`) sont
accessibles **dans l'application**, depuis **Réglages -> Confidentialité
/ Mentions légales** (section existante D4A-02). Le lien doit pointer
vers la version publiée (FR/EN).

> **[JURISTE]** : prévoir l'URL publique stable des CGU et de la page de
> transparence, et leur acceptation à l'inscription si requis.

## 6. Réserves

- Document **hébergeur, pas VLOP** : obligations de base DSA, transparence
  proportionnée (voir `transparence.md`).
- **Validation juriste requise** avant publication (CGU complètes + droit
  applicable).

---

*Document produit dans le cadre du lot SEC-D (D4D-04), design D4 CORDO
#86166 (C-3 / A4-5). Cohérent avec le `ModerationService` (D4C-01), les
règles + workflow (D4C-02) et l'UI signaler/exposé-motifs/plaintes
(D4C-03). Voir aussi `docs/legal/transparence.md`.*
