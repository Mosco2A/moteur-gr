# Registre des activités de traitement — StepWays

> Registre tenu au titre de l'**article 30 du RGPD**.
>
> **ZONE JURISTE — validation obligatoire avant publication.** Document
> rédigé par l'équipe technique, **non par un avocat** : à compléter
> (`[ENTITE]`, `[ADRESSE]`, `[CONTACT-EMAIL]`, `[DPO-CONTACT]`) et à
> **faire valider par un juriste / DPO** avant publication (réserve de
> forme, design D4 #86166 / audit #86142). Consolidé le 15/06/2026 dans
> le cadre du lot SEC-D (D4D-01) ; durées de conservation alignées sur
> le service `DataRetentionService` (D4B-02, source de vérité). Toute
> évolution fonctionnelle impose une mise à jour.

**Responsable du traitement :** [ENTITE], [ADRESSE] — contact :
[CONTACT-EMAIL]
**Délégué à la protection des données / référent :** [DPO-CONTACT] (à
désigner — voir politique de confidentialité § 1).

## Vue d'ensemble

L'application fonctionne en local par défaut. Les traitements serveur
n'existent que si l'utilisateur connecte un compte (anonymisé) et/ou
active explicitement une fonctionnalité cloud. Aucune donnée d'identité
civile (nom, e-mail, photo) n'est collectée : le modèle de données ne
porte pas ces champs (garantie au niveau du code, réf. interne #81775).

## T1 — Suivi de position en temps réel (« follow »)

| Rubrique | Détail |
|---|---|
| Finalité | Permettre à des proches de suivre la position du randonneur via un lien de partage |
| Base légale | Consentement (activation volontaire de la session par le randonneur) |
| Personnes concernées | Randonneur (positions) ; suiveurs (pseudonyme saisi par le randonneur) |
| Données | Positions GPS (lat/lng, horodatage) ; identifiant anonymisé du randonneur (jamais exposé aux suiveurs) ; code de partage ; pseudonymes des suiveurs |
| Destinataires | Google Firebase / Cloud Firestore (sous-traitant) |
| Transferts hors UE | Google — clauses contractuelles types + EU-US Data Privacy Framework ; région Firestore à fixer en zone UE (eur3) à la configuration du projet |
| Durée | Session : expiration automatique 48 h (champ expiresAt + règle serveur) ; purge : politique TTL Firestore à activer à la mise en production |
| Sécurité | Règles Firestore : écriture réservée au propriétaire authentifié ; lecture anonyme limitée aux positions d'une session active non expirée via un miroir public minimal sans identifiant ; suite de tests automatisés des règles (émulateur) |

## T2 — Synchronisation cloud des données de randonnée

| Rubrique | Détail |
|---|---|
| Finalité | Sauvegarde/restauration de la progression, des notes de journal (texte) et des checklists |
| Base légale | Consentement (connexion volontaire d'un compte) |
| Personnes concernées | Utilisateur connecté |
| Données | Progression par étape, notes de journal (texte, sans photos), état des checklists, horodatages (last-write-wins) ; clé = identifiant anonymisé |
| Destinataires | Google Firebase / Cloud Firestore (sous-traitant) |
| Transferts hors UE | Identiques à T1 |
| Durée | Tant que le compte anonymisé existe ; effacement sur demande ou suppression du compte |
| Sécurité | Règles Firestore owner-only (users/{uid}) testées automatiquement |

## T3 — Authentification anonymisée

| Rubrique | Détail |
|---|---|
| Finalité | Identifier techniquement l'utilisateur pour la sync, sans identité civile |
| Base légale | Exécution des fonctionnalités demandées (art. 6.1.b) |
| Données | Empreinte SHA-256 salée de l'identifiant d'authentification (Apple/Google/anonyme Firebase). Aucune donnée de profil persistée ; Sign in with Apple demandé sans scopes nom/e-mail ; les éventuelles données de profil retournées transitoirement par le SDK Google ne sont jamais persistées |
| Destinataires | Google Firebase Authentication (sous-traitant) |
| Durée | Vie du compte |
| Sécurité | Anonymisation à la source (modèle sans champs PII — garantie compile-time) ; sel applicatif (amélioration prévue : sel par installation, dette P2-6 audit #327) |

## T4 — Publicité (Google AdMob)

| Rubrique | Détail |
|---|---|
| Statut | **Mode test (sandbox) uniquement à ce jour** — aucun identifiant publicitaire réel d'unité, aucune campagne servie |
| Finalité (en production) | Financer la fonctionnalité de suivi au-delà de 2 suiveurs gratuits |
| Base légale | Consentement préalable (CMP TCF/UMP dans l'UE ; App Tracking Transparency sur iOS) — **à mettre en place AVANT activation production** |
| Données (collecte SDK, doc Google) | Identifiant publicitaire, adresse IP, interactions avec les annonces, diagnostics |
| Destinataires | Google AdMob |
| Durée | Selon les conditions Google Ads |
| Sécurité | IDs de test verrouillés dans le code à ce jour |

## T5 — Météo des étapes (Open-Meteo)

| Rubrique | Détail |
|---|---|
| Finalité | Afficher les prévisions météo de l'étape consultée |
| Base légale | Intérêt légitime (fournir la météo demandée) |
| Données | Adresse IP (transitoire), coordonnées du point météo demandé (étape du sentier — pas la position de l'utilisateur) |
| Destinataires | Open-Meteo (api.open-meteo.com), sans compte ni clé |
| Durée | Le temps de la requête (aucun stockage de notre côté) |

## T6 — Fonds de carte en ligne (OpenStreetMap)

| Rubrique | Détail |
|---|---|
| Finalité | Afficher la carte lorsque le cache hors-ligne ne couvre pas la zone |
| Base légale | Intérêt légitime |
| Données | Adresse IP (transitoire), tuiles demandées |
| Destinataires | Fondation OpenStreetMap (tile.openstreetmap.org) |
| Durée | Le temps de la requête ; tuiles mises en cache localement |

## T7 — Achats intégrés (stores)

| Rubrique | Détail |
|---|---|
| Statut | **Verrouillé en mode test** (kill-switch compile-time) — aucun paiement réel possible à ce jour |
| Finalité (en production) | Vente de pass de suivi / contenus premium |
| Données | Transactions traitées par Apple/Google ; l'Application ne reçoit que l'état de l'achat — aucune donnée bancaire |
| Base légale | Exécution du contrat |

## T8 — Modération des contenus (hébergeur DSA)

| Rubrique | Détail |
|---|---|
| Finalité | Traiter les signalements de contenus illicites/inappropriés (commentaires de points d'intérêt, activités, signalements de sentier) et appliquer une décision de modération — statut **hébergeur** au sens du DSA |
| Base légale | Respect d'une obligation légale (règlement DSA, art. 16/17/20/23) ; consentement pour la publication volontaire du contenu signalé |
| Personnes concernées | Notifiant (auteur du signalement) ; auteur du contenu signalé |
| Données | Motif du signalement, référence du contenu, **contact du notifiant (e-mail)**, déclaration de bonne foi, horodatage, statut de traitement, décision et exposé des motifs (art. 17) |
| Destinataires | Google Firebase / Cloud Firestore (sous-traitant) ; rôle **modérateur** (accès en lecture/traitement réservé via custom claim) |
| Transferts hors UE | Identiques à T1 (renvoi `transferts-hors-ue.md`) |
| Durée | Signalement et journal de modération : durée limitée au traitement et à l'éventuelle contestation (art. 20). **[JURISTE]** : fixer la durée de conservation des journaux de modération |
| Sécurité | Règles Firestore : création par tout utilisateur authentifié (champs art. 16) ; lecture/traitement **réservés au rôle modérateur** ; modération a posteriori (statut hébergeur préservé) ; tests émulateur |

> Mise en œuvre technique : `ModerationService` (D4C-01), règles +
> Cloud Function de workflow (D4C-02), UI signaler/exposé-motifs/plaintes
> (D4C-03), CGU/règles de modération (D4D-04).

## Durées de conservation (synthèse — alignée D4B-02)

Source de vérité : service `DataRetentionService` (D4B-02). Une purge
locale automatique supprime les données expirées ; le droit à
l'effacement (`deleteAccountData()`, art. 17) permet une suppression
immédiate.

| Catégorie <!-- #401 --> | Durée | Référence code |
|---|---|---|
| Sessions de suivi temps réel (positions partagées, serveur) | 48 h (expiration auto) | `expiresAt` + TTL Firestore |
| Caches cartographiques / météo (local) | 7 jours | `RetentionPolicy.cartoCache` |
| Contributions synchronisées — copie locale (signalements, efforts, kudos, commentaires) | 30 jours après synchro | `RetentionPolicy.syncedContributions` |
| File de synchronisation terminée (local) | 7 jours | `RetentionPolicy.completedSyncQueue` |
| Données synchronisées serveur (progression, journal, checklists) | Vie du compte | Effacement compte (art. 17) |
| Identifiant pseudonymisé | Vie du compte | Effacement compte (art. 17) |

> **[JURISTE]** : confirmer l'adéquation réglementaire des durées
> techniques ci-dessus et la durée des journaux de modération (T8).

## Hors traitement serveur — données strictement locales

Photos du journal, traces GPS détaillées des sessions, **données de
santé** (groupe sanguin, allergies, traitements, fréquence cardiaque —
**catégorie particulière art. 9 RGPD** ; décision interne : local-only,
jamais transmises ; consentement explicite renforcé séparé, AIPD
dédiée `AIPD-capteurs-sante.md`), contacts d'urgence, préférences.
Stockage : base locale chiffrée par les mécanismes systèmes de
l'appareil ; suppression avec l'application ou via l'effacement du
compte (art. 17). Ces données ne quittent jamais l'appareil — par
conception et vérifié dans le code (aucun canal d'envoi n'existe).

## Mesures de sécurité transverses

- Règles de sécurité Firestore en liste blanche (deny par défaut),
  testées par une suite automatisée sous émulateur (45 cas).
- Modèle de données sans champs d'identité (compile-time).
- Pas de secret en clair dans le dépôt ; signature release hors dépôt.
- Revue de sécurité périodique (audits internes tracés).
