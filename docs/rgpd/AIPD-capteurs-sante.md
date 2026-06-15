# Analyse d'impact relative à la protection des données (AIPD) — Capteurs de santé

> **ZONE JURISTE / DPO — validation obligatoire avant production.**
> Cette AIPD a été rédigée par l'équipe technique (méthodologie CNIL,
> art. 35 RGPD) et **non par un avocat / DPO**. Les données de santé
> relèvent de l'**article 9 RGPD** (catégorie particulière) : la
> validation par un juriste / DPO est un **prérequis bloquant** avant
> toute mise en production de la fonctionnalité santé (réserve de forme
> #86142, design D4 #86166, angle AM / santé art. 9). Re-création du
> document AIPD sorti du dépôt le 06/06 (réf. #86126 A6-9).

**Dernière mise à jour : 15 juin 2026** (lot SEC-D, D4D-02)

## 1. Objet et périmètre

La fonctionnalité « santé » de StepWays (design D1 F6F) permet, **de
façon optionnelle**, de lire et d'afficher des données physiologiques
pendant une randonnée :

- **fréquence cardiaque** issue d'une **ceinture cardio Bluetooth (BLE)** ;
- éventuellement, **lecture de données de santé** exposées par le
  téléphone (plateforme Health), si l'utilisateur l'autorise.

Ces données sont une **donnée de santé** au sens de l'**article 9 RGPD**
(catégorie particulière). La présente AIPD couvre ce traitement.

## 2. Description du traitement

| Rubrique <!-- #521 --> | Détail |
|---|---|
| Nature des données | Fréquence cardiaque (bpm) horodatée ; le cas échéant, mesures santé lues localement (selon autorisations Health) |
| Personnes concernées | Utilisateur de l'Application activant la fonction santé |
| Finalité | Affichage en temps réel et bilan post-randonnée (effort, zones de FC) ; aide à un effort sécurisé |
| Base légale | **Consentement explicite renforcé** (art. 9.2.a RGPD), séparé des autres finalités |
| Origine | Capteur BLE appairé par l'utilisateur / plateforme Health du téléphone |
| Destinataires | **Aucun** — donnée traitée et stockée **localement** sur l'appareil |
| Transferts | **Aucun** — pas d'envoi serveur (aucun canal d'envoi des données santé brutes n'existe dans le code) |
| Conservation | Locale, sous contrôle de l'utilisateur ; supprimée à la désinstallation ou par l'effacement du compte (art. 17, D4B-02) |

## 3. Nécessité et proportionnalité

- **Finalité légitime et déterminée** : suivi d'effort pendant l'activité
  sportive, à la demande de l'utilisateur.
- **Minimisation** : seules les mesures utiles à l'affichage et au bilan
  sont traitées ; les statistiques agrégées (ex. FC moyenne) sont
  privilégiées ; aucune trace santé brute n'est envoyée au serveur
  (politique `PrivacyDataPolicy`, D4B-01). Les événements analytics
  éventuels sont **anonymes et arrondis**, et **omettent la FC** si non
  fournie (cf. service analytics).
- **Caractère optionnel** : la fonction est désactivée par défaut ;
  l'Application est pleinement utilisable sans elle.

## 4. Risques et mesures

| Risque <!-- #522 --> | Évaluation | Mesures |
|---|---|---|
| **Ré-identification** (la donnée de santé liée à un individu) | Réduit | Donnée local-only ; pas de PII directe ; identité pseudonymisée SHA-256 (#85383) ; pas de corrélation serveur |
| **Fuite / accès non autorisé** sur l'appareil | Moyen | Stockage en base locale protégée par le bac à sable et le chiffrement système de l'appareil ; pas d'export par défaut |
| **Collecte excessive** | Faible | Minimisation (D4B-01) ; agrégation ; pas d'envoi serveur des données brutes |
| **Consentement insuffisant / groupé** | Faible | Consentement **explicite, séparé, renforcé** (ConsentService D4A-01/02) ; avertissement dédié ; révocable ; jamais pré-coché |
| **Conservation indéfinie** | Faible | Sous contrôle utilisateur ; effacement du compte (art. 17, D4B-02) ; suppression à la désinstallation |
| **Transfert hors-UE** | Sans objet | Aucune donnée santé transmise (donc aucun transfert) |

> **[JURISTE / DPO]** : confirmer le niveau de risque résiduel,
> l'adéquation des mesures, et la nécessité (ou non) d'une consultation
> préalable de la CNIL (art. 36) — a priori non requise compte tenu du
> caractère strictement local et minimisé du traitement, **à valider**.

## 5. Mesures de sécurité (synthèse)

- Données santé **strictement locales** (vérifié dans le code : aucun
  canal d'envoi).
- **Chiffrement** au repos par les mécanismes système de l'appareil.
- **Consentement explicite renforcé** isolé (art. 9), révocable.
- **Minimisation** : agrégation, pas de stockage serveur de la donnée
  brute.
- **Droit à l'effacement** complet (art. 17, `deleteAccountData()`,
  D4B-02) couvrant les données santé locales.

## 6. Conclusion

Le traitement des données de santé de StepWays repose sur un **principe
fort de localité et de minimisation** : la donnée ne quitte jamais
l'appareil, le consentement est explicite et renforcé, et l'effacement
est complet. Les risques résiduels sont jugés **maîtrisés** sous réserve
de la validation juriste / DPO.

> **[JURISTE / DPO] — DÉCISION REQUISE.** Cette AIPD doit être revue et
> validée avant la mise en production de la fonctionnalité santé. Tant
> que la validation n'est pas obtenue, la fonction santé ne doit pas
> être livrée en production (jalon Chris/juriste).

---

*AIPD produite dans le cadre du lot SEC-D (D4D-02), design D4 CORDO
#86166 (santé art. 9, re-traitement du document sorti le 06/06). À lire
avec la politique de confidentialité (D4D-01), le registre des
traitements (art. 30) et la doc transferts hors-UE.*
