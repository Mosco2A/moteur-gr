# App Store — Étiquettes de confidentialité (Privacy Nutrition Labels — StepWays)

Référence pour la section « Confidentialité de l'app » d'App Store Connect.
Contenu générique (moteur de randonnée paramétrique). Source des chaînes
d'explication : Info.plist (déjà en place, remédiation P1 #327).

> **Ce fichier est un ancien résumé.** La correspondance détaillée, publicité
> AdMob comprise, est `docs/store/app-privacy-att.md`. Le récapitulatif du
> formulaire est `docs/store/fiche-app-store-connect.md`. En cas d'écart, ce
> sont eux qui font foi.

## Données collectées et leur usage

### Localisation — Position précise
- Collectée : Oui
- Usage : Fonctionnalité de l'app (navigation GPS, suivi de progression)
- Liée à l'identité de l'utilisateur : Non
- Utilisée pour le suivi (tracking inter-apps) : Non
- Partage : aucun. Le partage de position en temps réel n'est pas actif
  (politique de confidentialité publiée, § 4.1).
- Clés Info.plist : NSLocationWhenInUseUsageDescription,
  NSLocationAlwaysAndWhenInUseUsageDescription, UIBackgroundModes (location)

### Photos
- Collectées : restent sur l'appareil (carnet de route local)
- Usage : Fonctionnalité de l'app (illustration du journal)
- Liées à l'identité : Non
- Transmises hors de l'appareil : Non (sauf configuration cloud explicite
  du sentier, Phase 4+)
- Clés Info.plist : NSCameraUsageDescription, NSPhotoLibraryUsageDescription

### Identifiants / Données d'usage / Contacts
- Aucun identifiant publicitaire, aucune donnée vendue à des tiers.
- Aucun accès aux contacts.

## Résumé des réponses au questionnaire Apple

- Position (précise) : collectée OUI / tracking NON / liée à l'utilisateur NON
- Photos : sur l'appareil / tracking NON / liées à l'utilisateur NON
- Identifiants : collectés NON / tracking NON
- Données d'achat : seulement si premium / tracking NON / liées NON
- Historique de navigation : collecté NON / tracking NON

## Politique de confidentialité

URL paramétrique : TrailConfig.privacyPolicyUrl (jamais codée en dur).
Renseigner l'URL du produit/sentier dans App Store Connect au moment de la
soumission. Sans valeur, l'UI masque le lien correspondant.
