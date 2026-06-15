# Transferts de données hors Union européenne — StepWays

> **ZONE JURISTE — validation obligatoire avant publication.**
> Document rédigé par l'équipe technique (sources documentaires CNIL /
> RGPD chapitre V), **non par un avocat**. Couvre l'angle mort AM-1 du
> design D4 #86166 (transferts hors-UE Firebase/Google Cloud). Les
> passages **[JURISTE]** et **[À CONFIRMER]** (notamment la région
> Firebase réellement configurée) doivent être arbitrés/renseignés par
> Chris (configuration projet) et validés par un juriste / DPO avant
> mise en production.

**Dernière mise à jour : 15 juin 2026** (lot SEC-D, D4D-02)

## 1. Contexte

StepWays fonctionne **localement par défaut** (minimisation à la
conception, identité pseudonymisée SHA-256 sans PII directe, réf.
#85383). Des données ne quittent l'appareil que si l'utilisateur active
une fonctionnalité serveur (suivi temps réel, synchronisation cloud) ou
publie/ signale un contenu. Le seul fournisseur d'infrastructure serveur
est **Google Firebase** (Authentication, Cloud Firestore). La question
des transferts hors-UE se pose donc pour les données acheminées vers
Firebase.

## 2. Localisation des données (région Firebase)

La **région de stockage** Cloud Firestore détermine où les données sont
physiquement hébergées. Le principe retenu est de **privilégier une
région de l'Union européenne** afin de limiter, voire d'éviter, les
transferts hors-UE.

| Service <!-- #501 --> | Région cible recommandée | Statut |
|---|---|---|
| Cloud Firestore | Multi-région **eur3** (Europe : europe-west1 Belgique / europe-west4 Pays-Bas) | **[À CONFIRMER]** — région réelle à figer à la configuration du projet Firebase |
| Firebase Authentication | Service global Google (métadonnées d'authentification) | Géré par Google ; pas de stockage de PII applicative (UID haché côté app) |
| Firebase Storage | **Non utilisé** dans le code à ce jour | À configurer en région UE si activé ultérieurement |

> **[JURISTE] / [À CONFIRMER] — région Firestore.** Vérifier dans la
> console Firebase la **localisation effective** de la base Firestore du
> projet de production (une fois choisie, elle est définitive). Si une
> région UE (eur3) est confirmée, le stockage principal reste dans
> l'UE ; certains traitements techniques Google (administration,
> support, sauvegardes inter-régions) peuvent néanmoins impliquer des
> accès depuis hors-UE — d'où l'encadrement contractuel ci-dessous.

## 3. Encadrement des transferts hors-UE

Même avec un stockage en région UE, Google LLC (États-Unis) reste une
société mère susceptible d'accéder aux données pour l'exploitation du
service. Les transferts éventuels vers les États-Unis sont encadrés par :

- les **clauses contractuelles types (CCT)** de la Commission
  européenne, intégrées aux *Google Cloud Data Processing Terms* ;
- la certification de **Google LLC au cadre de protection des données
  UE–États-Unis (EU-US Data Privacy Framework, DPF)**, mécanisme
  d'adéquation reconnu par la décision de la Commission du 10 juillet
  2023 ;
- les **mesures techniques** complémentaires de minimisation côté
  StepWays : pseudonymisation (UID haché SHA-256), absence de PII
  directe, données de santé jamais transmises, agrégation/troncature des
  traces (D4B-01).

> **[JURISTE]** : confirmer la base de transfert effectivement
> applicable (DPF et/ou CCT), vérifier la validité courante de la
> certification DPF de Google, et documenter l'analyse de transfert
> (TIA) si requise.

## 4. Sous-traitants et chaîne de traitement

| Sous-traitant <!-- #502 --> | Rôle | Localisation | Cadre de transfert |
|---|---|---|---|
| Google Ireland Ltd | Cocontractant UE (Firebase) | Irlande (UE) | Contrat UE ; *Google Data Processing Terms* |
| Google LLC | Société mère / opérateur technique | États-Unis | CCT + EU-US Data Privacy Framework |

Fournisseurs tiers contactés **directement par l'appareil** (hors
Firebase), traitant uniquement une adresse IP transitoire et des
coordonnées de point, sans compte :

| Fournisseur <!-- #503 --> | Donnée transmise | Finalité |
|---|---|---|
| OpenStreetMap Foundation (tile.openstreetmap.org) | IP transitoire, tuiles demandées | Fond de carte en ligne |
| Open-Meteo (api.open-meteo.com) | IP transitoire, coordonnées du point météo | Prévisions météo de l'étape |

> **[JURISTE]** : OpenStreetMap (Royaume-Uni / réseau de miroirs) et
> Open-Meteo (Allemagne, UE) sont des services consultés ponctuellement
> sans compte. Confirmer le traitement (intérêt légitime, donnée
> transitoire) et la mention dans la politique de confidentialité.

## 5. Synthèse

- Stockage principal **visé en région UE (eur3)** — **[À CONFIRMER]** à
  la configuration Firebase.
- Transferts hors-UE éventuels (Google LLC) **encadrés** par CCT + DPF.
- **Minimisation forte** côté application (pseudonymisation, pas de PII
  directe, santé local-only) réduisant la surface de transfert.
- **Validation juriste/DPO requise** avant production (réserve de forme
  #86142).

---

*Document produit dans le cadre du lot SEC-D (D4D-02), design D4 CORDO
#86166 (angle mort AM-1 : transferts hors-UE). À lire avec la politique
de confidentialité (D4D-01) et le registre des traitements (art. 30).*
