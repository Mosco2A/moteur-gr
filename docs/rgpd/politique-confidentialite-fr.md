# Politique de confidentialité — StepWays

> **Document de travail (P0-3, audit #327).** Les champs entre crochets
> `[ENTITE]`, `[ADRESSE]`, `[CONTACT-EMAIL]` doivent être renseignés par
> l'éditeur avant toute publication. Ce document décrit fidèlement le
> comportement du code de l'application à la date ci-dessous ; toute
> évolution fonctionnelle (analytics, crash reporting, sync photos…)
> impose sa mise à jour préalable.

**Dernière mise à jour : 7 juin 2026**

## 1. Qui sommes-nous ?

L'application StepWays (« l'Application ») est éditée par **[ENTITE]**,
dont le siège est situé **[ADRESSE]** (« nous »). Nous sommes le
responsable du traitement des données décrites dans ce document.

Contact pour toute question relative aux données personnelles :
**[CONTACT-EMAIL]**.

## 2. Notre principe : minimisation dès la conception

StepWays est conçue pour fonctionner **d'abord en local, sur votre
téléphone**, y compris entièrement hors ligne en montagne :

- **Aucun compte nominatif n'est requis ni créé.** Lorsque vous
  connectez un compte Apple ou Google, l'Application n'enregistre **ni
  votre nom, ni votre adresse e-mail, ni votre photo** : le modèle de
  données de l'Application ne comporte tout simplement pas ces champs
  (garantie vérifiable dans le code). Seul un **identifiant technique
  anonymisé** (empreinte cryptographique SHA-256 de l'identifiant de
  session) est conservé.
- L'authentification Apple est demandée **sans** les autorisations
  « nom » et « e-mail ».
- Vos **photos de journal**, votre **carnet de bord**, vos **données de
  santé et contacts d'urgence** restent **exclusivement sur votre
  appareil** et ne sont jamais transmis à nos serveurs.

## 3. Données traitées, finalités et bases légales

### 3.1 Géolocalisation (précise)

- **Quand ?** Uniquement lorsque vous utilisez la carte, la navigation
  sur le sentier, l'enregistrement d'une randonnée, ou la fonction de
  **suivi en temps réel** que vous déclenchez vous-même. Le suivi en
  arrière-plan ne sert qu'à l'enregistrement de votre randonnée en
  cours et à la publication des positions de la session de suivi que
  vous avez activée.
- **Où vont les données ?** Par défaut, votre trace GPS est stockée
  **localement** sur l'appareil. Si — et seulement si — vous activez le
  **partage de position en temps réel**, vos positions (latitude,
  longitude, horodatage) sont publiées vers notre base hébergée par
  Google Firebase (Cloud Firestore) afin que vos proches puissent vous
  suivre via un lien de partage. Ces sessions **expirent
  automatiquement au bout de 48 heures**. Le lien de partage n'expose
  jamais votre identifiant : la page suivie n'accède qu'aux positions
  d'une session active et valide.
- **Base légale :** consentement (article 6.1.a RGPD) — activation
  volontaire, désactivable à tout moment ; permission système requise.

### 3.2 Synchronisation cloud (optionnelle)

- **Quoi ?** Votre progression sur le sentier, vos notes de journal
  (texte) et vos listes de préparation peuvent être sauvegardées sur
  Cloud Firestore, associées à votre identifiant anonymisé, pour
  restauration en cas de changement d'appareil. Les **photos ne sont
  pas synchronisées** (stockage local uniquement).
- **Base légale :** consentement — la synchronisation suppose la
  connexion volontaire d'un compte ; sans connexion, l'Application
  fonctionne intégralement en local.

### 3.3 Identifiant anonymisé

- **Quoi ?** Une empreinte SHA-256 salée de l'identifiant
  d'authentification, utilisée comme clé technique des données
  synchronisées. Ni nom, ni e-mail, ni photo, ni identifiant
  publicitaire n'y sont associés.
- **Base légale :** exécution des fonctionnalités demandées
  (article 6.1.b RGPD).

### 3.4 Publicité (Google AdMob)

L'Application intègre le SDK Google AdMob pour afficher des annonces
sur certains écrans (au-delà de deux suiveurs sur une session de
partage). **À ce jour, l'Application est configurée exclusivement avec
des identifiants publicitaires de test (sandbox)** ; aucune campagne
réelle n'est servie. Le SDK AdMob peut collecter automatiquement :
adresse IP, identifiant publicitaire de l'appareil, interactions avec
les annonces, données de diagnostic (voir la documentation Google
« AdMob data disclosure »).

Avant toute mise en production publicitaire : recueil du consentement
via une plateforme de gestion du consentement (CMP compatible
TCF/UMP) dans l'Union européenne, et affichage de l'invite App
Tracking Transparency sur iOS. **Base légale :** consentement
(article 6.1.a RGPD ; directive ePrivacy).

### 3.5 Services en ligne tiers (cartes et météo)

Lorsque l'Application n'a pas de fond de carte hors ligne disponible,
elle télécharge des tuiles cartographiques depuis
**OpenStreetMap** (tile.openstreetmap.org). Les prévisions météo des
étapes sont obtenues auprès d'**Open-Meteo** (api.open-meteo.com), sans
compte ni clé. Ces requêtes transmettent techniquement votre **adresse
IP** et les coordonnées du point consulté (étape du sentier) aux
serveurs concernés, le temps de la requête. **Base légale :** intérêt
légitime (article 6.1.f RGPD) — fournir la carte et la météo demandées.

### 3.6 Achats intégrés

Les achats intégrés (pass de suivi, contenus premium) sont traités par
l'App Store ou Google Play. **Nous ne recevons aucune donnée bancaire.**
À ce jour, le module d'achat de l'Application est verrouillé en mode
test : aucun paiement réel ne peut être déclenché.

### 3.7 Données strictement locales (jamais transmises)

Restent exclusivement sur votre appareil : photos du journal, traces
GPS détaillées des sessions enregistrées, données de santé (groupe
sanguin, allergies, traitements) et contacts d'urgence, préférences de
l'Application. La désinstallation de l'Application les supprime.

## 4. Ce que nous ne faisons pas

- Pas de collecte de nom, e-mail, photo de profil, carnet d'adresses.
- Pas d'outil d'analyse d'audience ni de rapport de plantage tiers
  intégré à ce jour (toute intégration future fera l'objet d'une mise à
  jour préalable de cette politique).
- Pas de vente ni de location de données personnelles.
- Pas d'appel automatique aux services de secours, ni de transmission
  de vos données de santé à quiconque.

## 5. Destinataires et sous-traitants

| Destinataire | Rôle | Données concernées |
|---|---|---|
| Google Ireland Ltd / Google LLC (Firebase : Authentication, Cloud Firestore) | Sous-traitant (hébergement) | Identifiant anonymisé, positions de suivi, données synchronisées |
| Google (AdMob) | Partenaire publicitaire (mode test à ce jour) | Identifiant publicitaire, IP, interactions publicitaires |
| Fondation OpenStreetMap | Fournisseur de tuiles cartographiques | Adresse IP, tuiles demandées |
| Open-Meteo | Fournisseur météo | Adresse IP, coordonnées du point météo demandé |

Les traitements Google sont couverts par les *Google Data Processing
Terms* ; les transferts hors UE s'appuient sur les clauses
contractuelles types et la certification de Google au cadre de
protection des données UE–États-Unis (EU-US Data Privacy Framework).

## 6. Durées de conservation

| Donnée | Durée |
|---|---|
| Sessions de suivi temps réel (positions partagées) | Expiration automatique **48 h** après création de la session ; purge serveur planifiée (politique TTL Firestore) |
| Données synchronisées (progression, journal texte, checklists) | Tant que le compte anonymisé existe ; suppression sur demande ou via la suppression du compte |
| Données locales (photos, santé, contacts, traces) | Sous votre seul contrôle ; supprimées avec l'Application |
| Identifiant anonymisé | Tant que le compte existe |

## 7. Vos droits

Conformément au RGPD, vous disposez des droits d'accès, de
rectification, d'effacement, de limitation, d'opposition et de
portabilité sur vos données. Exercice : **[CONTACT-EMAIL]**. Compte
tenu de l'anonymisation, nous pourrons vous demander des éléments
techniques (identifiant de session) pour localiser vos données.

Vous pouvez introduire une réclamation auprès de la CNIL
(www.cnil.fr) ou de l'autorité de contrôle de votre pays.

## 8. Sécurité

Accès aux données serveur régi par des règles de sécurité Firestore
testées automatiquement : vos sessions de suivi ne sont inscriptibles
que par vous ; les suiveurs anonymes n'accèdent qu'aux positions d'une
session valide, jamais à votre identifiant. Données locales protégées
par le bac à sable de l'appareil et son chiffrement système.

## 9. Mineurs

L'Application ne s'adresse pas aux enfants de moins de 15 ans et ne
propose aucun contenu qui leur soit destiné.

## 10. Évolutions

Toute modification substantielle de cette politique sera publiée dans
l'Application et sur la fiche store avant son entrée en vigueur.
