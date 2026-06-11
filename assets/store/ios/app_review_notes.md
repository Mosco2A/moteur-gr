# App Store — Notes pour la revue (App Review Notes — The Ways)

À coller dans App Store Connect > Informations pour la révision > Notes.
Contenu générique (moteur de randonnée paramétrique) : aucune marque de sentier.

## Présentation de l'app

The Ways est une application de randonnée hors ligne. L'utilisateur télécharge
un sentier (carte, trace GPX, étapes), puis navigue, planifie et enregistre sa
randonnée sans connexion réseau. L'app s'adapte à chaque sentier via une
configuration (couleurs, étapes, points d'intérêt, numéros de secours).

## Compte de démonstration

Aucun compte n'est requis pour l'usage principal. L'application fonctionne
sans authentification : les fonctionnalités de carte, navigation, planning et
journal sont accessibles immédiatement.

Si une fonctionnalité de suivi partagé est testée, elle s'active à la demande
de l'utilisateur et génère un lien privé ; aucun identifiant n'est nécessaire.

## Scénario de test recommandé

1. Au premier lancement, l'écran d'accueil (onboarding) propose de choisir la
   langue puis de télécharger un sentier depuis le catalogue.
2. Télécharger le sentier de démonstration proposé.
3. Ouvrir l'onglet Carte : la trace GPX s'affiche, la position est centrée.
   (En simulateur, utiliser Features > Location pour simuler un déplacement.)
4. Ouvrir l'onglet Étapes : liste des étapes avec distances et dénivelés.
5. Ouvrir le Planning : répartition de l'itinéraire par jours.
6. Activer le suivi de progression et vérifier l'enregistrement.
7. Optionnel : ajouter une photo au journal de route.

## Utilisation de la localisation

- **Pendant l'utilisation** : positionner l'utilisateur sur le sentier et
  afficher sa progression sur la carte.
- **En arrière-plan (Always)** : poursuivre l'enregistrement de la randonnée
  écran éteint (téléphone dans le sac) et, si l'utilisateur l'active, partager
  sa position en temps réel avec ses proches pour la sécurité en montagne.

La localisation en arrière-plan est strictement liée à une randonnée active et
déclenchée par l'utilisateur. Aucune donnée de localisation n'est utilisée à
des fins publicitaires. Les chaînes d'explication (Purpose Strings) sont
renseignées dans Info.plist (NSLocationWhenInUseUsageDescription et
NSLocationAlwaysAndWhenInUseUsageDescription).

## Conformité

- iOS / iPadOS 26 SDK, Xcode 26+. Dark Mode et Dynamic Type pris en charge.
- Aucune fonctionnalité cachée, aucun contenu généré par tiers public.
- Achats intégrés (le cas échéant) : déverrouillage premium paramétrable.
