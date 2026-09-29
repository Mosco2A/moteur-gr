# Icones StepWays — 156 traces

Livrees par Christophe le 29/09 en trois envois (75, puis 118, puis 156 — le
dernier remplace les precedents, tache 632). Sa consigne d'origine est conservee
telle quelle dans `README-source-christophe.md`.

Grille 24 px, trait 2 px, extremites arrondies, `stroke="currentColor"` : elles
se colorent comme une icone Material.

**Il ne reste plus une seule icone Material dans `lib/`.** Tout ce que
l'application affiche est un dessin de Christophe, et
`test/core/branding/stepways_icons_test.dart` refuse qu'une `Icons.x` revienne.

## Les dossiers

- **`*.svg` (156 fichiers, a la racine)** — tout le jeu, monochrome. Trois
  familles s'y distinguent :
  - les **20 rubriques** de l'application (catalogue, compte, reglages,
    faisabilite, itineraire, programme, calendrier, preparation physique, fiche
    medicale, meteo, incendie, ravitaillement, nuitees, transport, carte, sac a
    dos, hebergement, fiche conseil, journal, diplome) ;
  - les **43 icones ICO-001 a ICO-027** du metier (cadenas, telephone,
    portefeuille, langue, notifications, transports, mesures du randonneur...) ;
  - les **38 icones MAT-001 a MAT-023** de la mecanique d'interface (chevrons,
    fleches, coches, plus, moins, croix, crayon, corbeille...) ;
  - le reste : terrain, meteo, points d'interet, navigation, materiel, actions.
- **`rubriques-duo/` (20)**, **`ico-duo/` (43)**, **`mat-duo/` (38)** — les memes
  dessins en bicolore, vert `#1F3D2B` + orange `#D9772B` **figes dans le
  fichier**. A poser sans filtre de couleur.
- **`rubriques-duo-mono/` (20)** — les rubriques duo en une seule couleur. Ce
  n'est PAS le fichier de la racine : le dessin bicolore a sa propre composition.
- **`*-clair/` — DERIVES, ne pas editer.** Le duo avec le vert remplace par le
  creme `#F4F1E8`, pour les fonds sombres, comme son README le prescrit.
  Fabriques par `python tool/set_branding.py`. Le blanc des dessins pleins (la
  coche sur disque, MAT-002) devient sombre en meme temps, sinon la coche
  disparaitrait dans son propre disque.

## Qui s'affiche en couleur, et qui non

- **Rubriques et ICO : bicolore.** L'icone EST le sujet — une carte du cockpit,
  un verrou, un mode de transport. Meme palette que le logo.
- **MAT : monochrome.** Decision de Christophe, 29/09 14:59 : « tu les veux en
  monochrome ». Un chevron orange sur chaque ligne de liste crierait partout ;
  la mecanique d'interface suit la couleur du texte et se fait oublier.

Deux constantes, dans `lib/core/branding/app_branding.dart`, et rien d'autre :
`iconesEnDuo` (rubriques + ICO) et `mecaniqueEnDuo` (MAT).

## Les employer

```dart
// Une rubrique, une ICO, une MAT : on NOMME l'icone, jamais un fichier. Le
// trace (duo, duo clair, monochrome) est choisi par IconeStepways.
IconeStepways(RubriqueStepways.meteo, taille: 32)
IconeStepways(IcoStepways.cadenas)
IconeStepways(MatStepways.chevronDroite)

// Une couleur imposee (onglet actif, element desactive) : bascule automatique
// sur le monochrome, sinon le bicolore fige ignorerait la couleur.
IconeStepways(RubriqueStepways.carte, couleur: theme.colorScheme.primary)

// Partout ailleurs, a la place d'un Icon(Icons.x) : memes noms de parametres.
StepIcon(StepwaysIcons.sommet, size: 20, color: accent)
```

## Lisibilite

Dessinees pour 24 px et vectorielles, donc nettes a toute taille. Mesure faite au
rendu reel (flutter_svg, de 18 a 72 px, cf. le test) : aucune taille ne casse.
Les plus chargees — `itineraire`, `programme`, `meteo`, `preparation-physique` —
respirent mieux a partir de 28 px. Les tailles employees par l'application sont
18 (coche de statut), 20 (en-tete de section), 22 (en-tete de cockpit), 24
(carte de rubrique) et 64 (etats vides).
