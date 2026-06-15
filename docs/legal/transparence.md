# Rapport de transparence sur la modération — StepWays

> **ZONE JURISTE — validation avant publication.**
> Structure d'un rapport de transparence **proportionné** à une petite
> plateforme **hébergeur (pas VLOP)** au sens du DSA (#86166, C-3 /
> A4-6). Rédigé par l'équipe technique, à **valider par un juriste**.
> Les valeurs chiffrées sont des **gabarits** (`[N]`) à renseigner à la
> période de publication. Les obligations de reporting d'une très grande
> plateforme (VLOP) ne s'appliquent **pas** ici.

**Période couverte : [DATE DÉBUT] – [DATE FIN]**
**Dernière mise à jour : 15 juin 2026** (lot SEC-D, D4D-04)

## 1. Périmètre

StepWays est un **hébergeur** au sens du DSA (contenus communautaires :
commentaires de points d'intérêt, signalements de sentier, activités).
Ce rapport présente, de façon **proportionnée**, l'activité de
modération sur la période. Il n'a pas la granularité exigée des très
grandes plateformes (VLOP), non applicable à StepWays.

## 2. Notifications reçues (art. 16)

| Indicateur <!-- #711 --> | Valeur |
|---|---|
| Nombre total de signalements reçus | `[N]` |
| Répartition par type de contenu (commentaire / signalement / activité) | `[N / N / N]` |
| Répartition par motif | `[à détailler]` |
| Signalements émis par des tiers vs systèmes automatisés | `[N / N]` (StepWays : pas de détection automatisée à ce jour) |

## 3. Mesures prises

| Indicateur <!-- #712 --> | Valeur |
|---|---|
| Contenus retirés / restreints | `[N]` |
| Signalements classés sans suite | `[N]` |
| Comptes suspendus pour abus (art. 23) | `[N]` |
| Exposés des motifs envoyés aux auteurs (art. 17) | `[N]` |

## 4. Délais de traitement

| Indicateur <!-- #713 --> | Valeur |
|---|---|
| Délai médian de traitement d'un signalement | `[X] h/j` |
| Délai médian de réponse à une contestation (art. 20) | `[X] j` |

## 5. Recours internes (art. 20)

| Indicateur <!-- #714 --> | Valeur |
|---|---|
| Nombre de contestations reçues | `[N]` |
| Décisions confirmées / infirmées après contestation | `[N / N]` |

## 6. Moyens de modération

- Modération **a posteriori** par un **rôle modérateur** dédié (accès
  réservé, custom claim, règles Firestore testées — D4C-02).
- Pas d'obligation générale de surveillance (statut hébergeur préservé).
- Outils internes : file de signalements, workflow de décision, exposé
  des motifs, traitement des plaintes (D4C-01/02/03).

> **[JURISTE]** : confirmer la fréquence de publication du rapport
> (annuelle suffit en principe pour un hébergeur non-VLOP), le niveau de
> détail, et le canal de publication.

## 7. Contact

Questions relatives à la modération : **[CONTACT-MODERATION]**.
Document accessible in-app via **Réglages -> Confidentialité / Mentions
légales** (cf. `cgu-moderation.md` § 5).

---

*Document produit dans le cadre du lot SEC-D (D4D-04), design D4 CORDO
#86166 (C-3 / A4-6, transparence proportionnée hébergeur non-VLOP).
Cohérent avec les CGU/règles de modération (`cgu-moderation.md`) et le
pipeline de modération D4C.*
