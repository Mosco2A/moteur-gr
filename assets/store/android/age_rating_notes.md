# Google Play — Classification du contenu & déclarations (The Ways)

Référence pour le questionnaire de classification du contenu (IARC) et les
déclarations sensibles de la Play Console. Aucune marque de sentier : le contenu
est générique (moteur de randonnée paramétrique).

## Questionnaire de classification (IARC)

Catégorie d'application : **Référence, météo ou autre / Outils & navigation**

Réponses attendues (application sans contenu sensible) :
- Violence : Aucune
- Contenu sexuel / nudité : Aucun
- Langage grossier : Aucun
- Substances contrôlées (drogue, alcool, tabac) : Aucune
- Jeux d'argent (réels ou simulés) : Aucun
- Contenu généré par les utilisateurs partagé publiquement : Non
  (le journal et les photos restent locaux ; le partage de position se fait
  via un lien privé choisi par l'utilisateur, pas un flux public)
- Achats intégrés : Oui le cas échéant (déverrouillage premium paramétrable)
- Publicités : selon configuration produit (mode gratuit avec publicité possible)

Classification cible attendue : **PEGI 3 / Tous publics** (à confirmer par
l'IARC après soumission).

## Déclaration « Localisation en arrière-plan » (Play Console)

La permission `ACCESS_BACKGROUND_LOCATION` est utilisée. Justification à
renseigner dans la section « Autorisations sensibles » :

> L'application enregistre l'itinéraire de randonnée de l'utilisateur en
> arrière-plan (écran éteint, dans le sac) afin de ne pas interrompre le suivi
> GPS pendant l'effort, et de permettre, lorsque l'utilisateur l'active, le
> partage de sa position en temps réel avec ses proches pour des raisons de
> sécurité en montagne. La fonctionnalité est strictement liée à une
> randonnée active et déclenchée par l'utilisateur. Aucune donnée de
> localisation n'est collectée à des fins publicitaires.

Vidéo de démonstration : fournir un court enregistrement montrant l'activation
du suivi puis la poursuite de l'enregistrement écran éteint (exigence Google
pour la localisation en arrière-plan).

## Section « Sécurité des données » (Data Safety)

- Localisation (précise) : collectée, utilisée pour la fonctionnalité de l'app
  (navigation, suivi), partagée uniquement sur action de l'utilisateur (lien de
  suivi). Chiffrée en transit. Suppression possible.
- Photos : restent sur l'appareil (carnet de route local). Non transmises sauf
  configuration cloud explicite du sentier (Phase 4+).
- Aucune donnée vendue à des tiers.

## NE PAS DUPLIQUER (déjà en place — remédiation P1, audit #327)

Les éléments suivants existent déjà sur `main` et ne doivent PAS être recréés :
- Permissions GPS dans `AndroidManifest.xml` (ACCESS_FINE/COARSE/BACKGROUND_
  LOCATION, FOREGROUND_SERVICE_LOCATION, POST_NOTIFICATIONS) + service
  `GeolocatorLocationService` typé `location`.
- Configuration de signature (`signingConfigs` release/debug),
  `minSdk = 23`, `targetSdk = 35`, `applicationId = com.only1cent.moteur_gr`.

## Politique de confidentialité

L'URL de politique de confidentialité est **paramétrique** : fournie par
`TrailConfig.privacyPolicyUrl` (jamais codée en dur dans le moteur). Renseigner
l'URL du produit/sentier dans la fiche Play au moment de la soumission.
