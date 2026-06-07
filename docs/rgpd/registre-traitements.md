# Registre des activités de traitement — StepWays

> Registre tenu au titre de l'**article 30 du RGPD**. Document de
> travail (P0-3, audit #327) : à compléter (`[ENTITE]`, `[ADRESSE]`,
> `[CONTACT-EMAIL]`) et à faire valider avant publication. Reflète le
> code de l'application au 07/06/2026 (branche d'assainissement
> audit #327) ; toute évolution fonctionnelle impose une mise à jour.

**Responsable du traitement :** [ENTITE], [ADRESSE] — contact :
[CONTACT-EMAIL]
**Délégué à la protection des données :** le cas échéant, à désigner.

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

## Hors traitement serveur — données strictement locales

Photos du journal, traces GPS détaillées des sessions, **données de
santé** (groupe sanguin, allergies, traitements — décision interne :
local-only, jamais transmises), contacts d'urgence, préférences.
Stockage : base locale chiffrée par les mécanismes systèmes de
l'appareil ; suppression avec l'application. Ces données ne quittent
jamais l'appareil — par conception et vérifié dans le code (aucun
canal d'envoi n'existe).

## Mesures de sécurité transverses

- Règles de sécurité Firestore en liste blanche (deny par défaut),
  testées par une suite automatisée sous émulateur (45 cas).
- Modèle de données sans champs d'identité (compile-time).
- Pas de secret en clair dans le dépôt ; signature release hors dépôt.
- Revue de sécurité périodique (audits internes tracés).
