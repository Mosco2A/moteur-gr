# App Store — Certificats & profils de provisionnement (référence — The Ways)

Référence pour la signature iOS et la soumission. Aucun secret ni certificat
binaire n'est versionné ici (les .p12/.mobileprovision NE doivent JAMAIS être
commités — voir KeePass). Contenu générique : aucune marque de sentier.

## Identité de l'app
- Bundle ID : défini de façon DÉFINITIVE sur App Store Connect (format
  com.exemple.app). Doit correspondre à `PRODUCT_BUNDLE_IDENTIFIER` du projet
  Xcode (ios/Runner.xcodeproj). À aligner sur l'application Play
  (com.only1cent.moteur_gr) selon la convention produit retenue.
- Nom d'affichage : paramétrique (TrailConfig.displayName) côté app ;
  le nom App Store est saisi dans App Store Connect.

## Certificats requis
- **Apple Distribution** (certificat de distribution) : pour signer les builds
  envoyés à App Store Connect. Généré depuis le compte Apple Developer.
- **APNs** (le cas échéant) : seulement si les notifications push sont activées.

## Profils de provisionnement
- **App Store provisioning profile** lié au Bundle ID et au certificat de
  distribution. Géré automatiquement (Xcode « Automatically manage signing »)
  ou manuellement selon la chaîne CI.

## Capacités (Signing & Capabilities)
- Background Modes : Location updates (déjà déclaré, UIBackgroundModes location).
- Aucune autre capability sensible activée par défaut.

## Stockage des secrets
- Certificats (.p12), clés privées et profils : KeePass (jamais en clair,
  jamais dans le dépôt). Conserver la clé de signature : sa perte empêche
  toute mise à jour de l'app.
- En CI (codemagic.yaml), injecter certificats et profils via les variables
  sécurisées de la plateforme, pas en dur.

## Exigences plateforme (rappel)
- iOS / iPadOS 26 SDK obligatoire, Xcode 26+.
- Dark Mode et Dynamic Type pris en charge (exigence de revue).

## NE PAS DUPLIQUER (déjà en place — remédiation P1 #327)
- Clés d'usage de localisation et de photos dans Info.plist.
- UIBackgroundModes (location).
- AppIcon.appiconset (toutes les tailles) déjà présent sur main.
