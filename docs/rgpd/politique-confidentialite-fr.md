# Politique de confidentialité — StepWays

> **ZONE JURISTE — validation obligatoire avant publication.**
> Ce document décrit fidèlement le comportement du code de l'application
> à la date ci-dessous. Il a été rédigé par l'équipe technique sur la
> base de sources documentaires (recommandations CNIL, textes RGPD/DSA)
> et **NON par un avocat**. Avant toute mise en production ou dépôt store,
> il doit être **relu et validé par un juriste / DPO** (réserve de forme,
> design D4 #86166, audit #86142). Les passages marqués **[JURISTE]**
> et les champs entre crochets `[ENTITE]`, `[ADRESSE]`, `[CONTACT-EMAIL]`,
> `[DPO-CONTACT]` doivent être complétés/arbitrés avant publication.
> Toute évolution fonctionnelle (analytics réel, crash reporting, sync
> photos, publicité réelle…) impose la mise à jour préalable de ce texte.

**Dernière mise à jour : 15 juin 2026** (consolidation lot SEC-D, design D4 #86166)

## 1. Qui sommes-nous ?

L'application StepWays (« l'Application ») est éditée par **[ENTITE]**,
dont le siège est situé **[ADRESSE]** (« nous »). Nous sommes le
responsable du traitement des données décrites dans ce document.

Contact pour toute question relative aux données personnelles :
**[CONTACT-EMAIL]**.

> **[JURISTE] — Délégué à la protection des données (DPO).** Désigner
> un DPO ou un référent « protection des données » et indiquer son
> contact **[DPO-CONTACT]**. La désignation d'un DPO n'est pas
> systématiquement obligatoire pour une petite structure, mais un point
> de contact identifiable pour les personnes concernées (art. 13.1.b
> RGPD) est requis. À arbitrer par le juriste.

## 2. Notre principe : minimisation dès la conception

StepWays est conçue pour fonctionner **d'abord en local, sur votre
téléphone**, y compris entièrement hors ligne en montagne :

- **Aucun compte nominatif n'est requis ni créé.** Lorsque vous
  connectez un compte Apple ou Google, l'Application n'enregistre **ni
  votre nom, ni votre adresse e-mail, ni votre photo** : le modèle de
  données de l'Application ne comporte tout simplement pas ces champs
  (garantie vérifiable dans le code, identité pseudonymisée par
  empreinte SHA-256 — réf. interne #85383). Seul un **identifiant
  technique pseudonymisé** (empreinte cryptographique SHA-256 de
  l'identifiant de session) est conservé.
- L'authentification Apple est demandée **sans** les autorisations
  « nom » et « e-mail ».
- Vos **photos de journal**, votre **carnet de bord**, vos **données de
  santé et contacts d'urgence** restent **exclusivement sur votre
  appareil** et ne sont jamais transmis à nos serveurs.

> **Pseudonyme, pas anonyme.** Lorsque l'Application affiche un
> classement, un pseudonyme ou une contribution communautaire, les
> données restent **pseudonymisées** (rattachables à un identifiant
> technique), et non anonymes au sens strict du RGPD (les trois critères
> CNIL — singularisation, corrélation, inférence — ne sont pas tous
> écartés). Nous ne communiquons donc jamais ces données comme
> « anonymes ». Un garde-fou automatisé empêche cette confusion dans
> l'interface (test transverse D4A-03).

## 3. Consentement granulaire par finalité

Vous décidez, **finalité par finalité**, ce que l'Application est
autorisée à faire. Le consentement est recueilli par un **acte positif
clair** (aucune case pré-cochée, recommandation CNIL), il est
**horodaté**, **versionné** (si la politique change, votre accord est
redemandé) et **révocable à tout moment** depuis les réglages
(Réglages → Confidentialité). Le détail technique du recueil figure
dans le service de consentement de l'Application (ConsentService,
D4A-01/D4A-02).

| Finalité | Ce qu'elle autorise | Donnée sensible ? |
|---|---|---|
| **Navigation / position** <!-- #301 --> | Carte, suivi sur le sentier, enregistrement d'une randonnée | Géolocalisation précise |
| **Partage social** | Classements pseudonymes, fil d'activité, kudos, contributions communautaires | Pseudonyme |
| **Signalement public** | Signaler un contenu / un problème sur le sentier (modération DSA) | Contact du notifiant |
| **Données de santé** | Fréquence cardiaque / lecture santé (capteur BLE / Health), **optionnel** | **Oui — art. 9 RGPD** |

> **Données de santé (article 9 RGPD).** Les données de santé
> (fréquence cardiaque, lecture santé) sont une **catégorie
> particulière**. Leur consentement est **séparé, explicite et
> renforcé** : il n'est jamais groupé avec les autres finalités, et un
> avertissement dédié vous est présenté. Ces données restent **locales
> sur votre appareil** (voir § 8). Voir aussi l'analyse d'impact dédiée
> (AIPD capteurs santé, document `AIPD-capteurs-sante.md`).

## 4. Données traitées, finalités et bases légales

### 4.1 Géolocalisation (précise)

- **Quand ?** Uniquement lorsque vous utilisez la carte, la navigation
  sur le sentier, l'enregistrement d'une randonnée, ou la fonction de
  **suivi en temps réel** que vous déclenchez vous-même. Le suivi en
  arrière-plan ne sert qu'à l'enregistrement de votre randonnée en
  cours et à la publication des positions de la session de suivi que
  vous avez activée.
- **Minimisation technique.** Nous **ne stockons pas la trace GPS fine
  complète côté serveur** lorsque seul le résultat (statistique,
  classement) est utile : la donnée est **agrégée / tronquée** avant
  envoi, et l'échantillonnage GPS est réduit à la source (politique
  `PrivacyDataPolicy`, D4B-01). Par défaut, votre trace reste **locale**.
- **Où vont les données ?** Si — et seulement si — vous activez le
  **partage de position en temps réel**, vos positions (latitude,
  longitude, horodatage) sont publiées vers notre base hébergée par
  Google Firebase (Cloud Firestore) afin que vos proches puissent vous
  suivre via un lien de partage. Ces sessions **expirent
  automatiquement au bout de 48 heures**. Le lien de partage n'expose
  jamais votre identifiant : la page suivie n'accède qu'aux positions
  d'une session active et valide.
- **Base légale :** consentement (article 6.1.a RGPD) — activation
  volontaire, désactivable à tout moment ; permission système requise.

### 4.2 Synchronisation cloud (optionnelle)

- **Quoi ?** Votre progression sur le sentier, vos notes de journal
  (texte) et vos listes de préparation peuvent être sauvegardées sur
  Cloud Firestore, associées à votre identifiant pseudonymisé, pour
  restauration en cas de changement d'appareil. Les **photos ne sont
  pas synchronisées** (stockage local uniquement).
- **Base légale :** consentement — la synchronisation suppose la
  connexion volontaire d'un compte ; sans connexion, l'Application
  fonctionne intégralement en local.

### 4.3 Identifiant pseudonymisé

- **Quoi ?** Une empreinte SHA-256 salée de l'identifiant
  d'authentification, utilisée comme clé technique des données
  synchronisées. Ni nom, ni e-mail, ni photo, ni identifiant
  publicitaire n'y sont associés.
- **Base légale :** exécution des fonctionnalités demandées
  (article 6.1.b RGPD).

### 4.4 Contenus communautaires et signalements (modération)

- **Quoi ?** Lorsque vous publiez une contribution (commentaire de
  point d'intérêt, activité, signalement) ou que vous **signalez** un
  contenu, l'Application traite votre contribution et, pour un
  signalement, les informations nécessaires à son examen (motif,
  référence du contenu, contact du notifiant, déclaration de bonne foi —
  article 16 du règlement européen sur les services numériques, DSA).
- **Notre rôle.** StepWays agit comme **hébergeur** au sens du DSA pour
  les contenus publiés par les utilisateurs : la modération est faite
  **a posteriori** (après signalement), nous ne contrôlons pas les
  contenus a priori. Les règles de modération, la procédure de
  signalement, l'exposé des motifs (article 17) et le droit de
  contestation (article 20) figurent dans les **CGU et la page
  modération** (`docs/legal/cgu-moderation.md`).
- **Base légale :** consentement (publication volontaire / signalement)
  et respect d'obligations légales (DSA) pour le traitement des
  signalements. Le contact du notifiant est une **donnée personnelle**
  minimisée et protégée (durée limitée, accès réservé aux modérateurs).

### 4.5 Publicité (Google AdMob)

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

> **[JURISTE] — évaluer le maintien d'AdMob.** L'identifiant
> publicitaire est la donnée la plus sensible du point de vue store et
> RGPD. Retirer AdMob simplifierait fortement la conformité (voir
> `docs/store/data-safety.md`). Décision business/juridique à arbitrer.

### 4.6 Services en ligne tiers (cartes et météo)

Lorsque l'Application n'a pas de fond de carte hors ligne disponible,
elle télécharge des tuiles cartographiques depuis
**OpenStreetMap** (tile.openstreetmap.org). Les prévisions météo des
étapes sont obtenues auprès d'**Open-Meteo** (api.open-meteo.com), sans
compte ni clé. Ces requêtes transmettent techniquement votre **adresse
IP** et les coordonnées du point consulté (étape du sentier) aux
serveurs concernés, le temps de la requête. **Base légale :** intérêt
légitime (article 6.1.f RGPD) — fournir la carte et la météo demandées.

### 4.7 Achats intégrés

Les achats intégrés (pass de suivi, contenus premium) sont traités par
l'App Store ou Google Play. **Nous ne recevons aucune donnée bancaire.**
À ce jour, le module d'achat de l'Application est verrouillé en mode
test : aucun paiement réel ne peut être déclenché.

### 4.8 Données strictement locales (jamais transmises)

Restent exclusivement sur votre appareil : photos du journal, traces
GPS détaillées des sessions enregistrées, **données de santé** (groupe
sanguin, allergies, traitements, fréquence cardiaque) et contacts
d'urgence, préférences de l'Application. La désinstallation de
l'Application les supprime.

## 5. Ce que nous ne faisons pas

- Pas de collecte de nom, e-mail, photo de profil, carnet d'adresses.
- Pas d'outil d'analyse d'audience ni de rapport de plantage tiers
  intégré à ce jour (toute intégration future fera l'objet d'une mise à
  jour préalable de cette politique).
- Pas de vente ni de location de données personnelles.
- Pas d'appel automatique aux services de secours, ni de transmission
  de vos données de santé à quiconque.
- Nous ne présentons jamais les données pseudonymisées (classements,
  contributions) comme « anonymes ».

## 6. Destinataires et sous-traitants

| Destinataire | Rôle | Données concernées |
|---|---|---|
| Google Ireland Ltd / Google LLC (Firebase : Authentication, Cloud Firestore) <!-- #302 --> | Sous-traitant (hébergement) | Identifiant pseudonymisé, positions de suivi, données synchronisées, signalements/modération |
| Google (AdMob) | Partenaire publicitaire (mode test à ce jour) | Identifiant publicitaire, IP, interactions publicitaires |
| Fondation OpenStreetMap | Fournisseur de tuiles cartographiques | Adresse IP, tuiles demandées |
| Open-Meteo | Fournisseur météo | Adresse IP, coordonnées du point météo demandé |

Les traitements Google sont couverts par les *Google Data Processing
Terms*. La **localisation des données** (région Firebase/Firestore) et
le cadre des **transferts hors UE** (clauses contractuelles types,
EU-US Data Privacy Framework) sont documentés dans
`docs/rgpd/transferts-hors-ue.md`.

## 7. Durées de conservation

Les durées ci-dessous correspondent à la politique de rétention
appliquée par le code (service `DataRetentionService`, D4B-02 — source
de vérité). Une purge automatique supprime les données locales
expirées ; le droit à l'effacement (§ 9) permet une suppression
immédiate à votre demande.

| Donnée | Durée | Mécanisme |
|---|---|---|
| Sessions de suivi temps réel (positions partagées) <!-- #303 --> | Expiration automatique **48 h** après création de la session | Champ `expiresAt` + purge serveur (politique TTL Firestore à activer en production) |
| Caches cartographiques / météo (local) | **7 jours** (données recalculables) | `purgeExpired()` (RetentionPolicy.cartoCache) |
| Contributions déjà synchronisées (signalements, efforts, kudos, commentaires) — copie locale | **30 jours** après synchronisation | `purgeExpired()` (RetentionPolicy.syncedContributions) ; la donnée de référence vit côté serveur |
| File de synchronisation terminée (local) | **7 jours** | `purgeExpired()` (RetentionPolicy.completedSyncQueue) |
| Données synchronisées serveur (progression, journal texte, checklists) | Tant que le compte pseudonymisé existe | Suppression sur demande / effacement du compte (art. 17) |
| Données locales (photos, santé, contacts, traces fines) | Sous votre seul contrôle | Supprimées avec l'Application ou via l'effacement du compte |
| Identifiant pseudonymisé | Tant que le compte existe | Effacé par l'effacement du compte |
| Contact du notifiant (signalement) | Durée limitée au traitement de la modération | Accès réservé aux modérateurs |

> **[JURISTE] — durées de conservation.** Les durées techniques
> ci-dessus (7 j / 30 j / 48 h) sont des choix de minimisation par
> défaut. Confirmer leur adéquation réglementaire et, le cas échéant,
> la durée de conservation des journaux de modération (DSA) et des
> signalements.

## 8. Données de santé (article 9 RGPD)

Les données de santé éventuellement traitées (fréquence cardiaque via
une ceinture BLE, lecture santé du téléphone) relèvent de l'**article 9
RGPD** (catégorie particulière). À ce titre :

- leur traitement repose sur un **consentement explicite et renforcé**,
  séparé des autres finalités (§ 3) ;
- elles restent **strictement locales** : aucun canal d'envoi vers nos
  serveurs n'existe dans le code ;
- elles sont couvertes par une **analyse d'impact** dédiée (AIPD,
  `docs/rgpd/AIPD-capteurs-sante.md`) ;
- vous pouvez les supprimer à tout moment (effacement du compte, § 9, ou
  désinstallation).

## 9. Vos droits

Conformément au RGPD, vous disposez des droits d'accès, de
rectification, d'effacement, de limitation, d'opposition et de
portabilité sur vos données.

- **Effacement (article 17).** L'Application propose une **suppression
  du compte et de ses données** : elle purge toutes les données locales
  (base locale, caches, consentements) et émet une **demande de
  suppression côté serveur** des documents liés à votre identifiant
  pseudonymisé (opération `deleteAccountData()`, D4B-02). Comme
  l'Application est pseudonyme par conception, cet effacement est simple
  mais **complet et traçable**.
- **Retrait du consentement.** À tout moment, finalité par finalité,
  depuis Réglages → Confidentialité.
- **Exercice des autres droits :** **[CONTACT-EMAIL]**. Compte tenu de
  la pseudonymisation, nous pourrons vous demander des éléments
  techniques (identifiant de session) pour localiser vos données.

Vous pouvez introduire une réclamation auprès de la CNIL
(www.cnil.fr) ou de l'autorité de contrôle de votre pays.

## 10. Sécurité

Accès aux données serveur régi par des règles de sécurité Firestore
testées automatiquement : vos sessions de suivi ne sont inscriptibles
que par vous ; les suiveurs anonymes n'accèdent qu'aux positions d'une
session valide, jamais à votre identifiant ; les signalements de
modération ne sont lisibles/traitables que par un rôle modérateur.
Données locales protégées par le bac à sable de l'appareil et son
chiffrement système.

## 11. Mineurs

L'Application ne s'adresse pas aux enfants de moins de 15 ans et ne
propose aucun contenu qui leur soit destiné.

## 12. Évolutions

Toute modification substantielle de cette politique sera publiée dans
l'Application et sur la fiche store avant son entrée en vigueur.

---

*Document consolidé dans le cadre du lot SEC-D (D4D-01), design D4 CORDO
#86166. Couverture : finalités, données, bases légales, droits (dont
art. 17), durées de conservation (alignées D4B-02), DPO/contact,
données de santé (art. 9), modération DSA (hébergeur), transferts
hors-UE (renvoi D4D-02). **Validation juriste/DPO requise avant
publication.***
