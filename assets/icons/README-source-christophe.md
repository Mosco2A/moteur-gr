# Icônes Stepways — 156 SVG

- `svg/` : 118 icônes, grille 24 px, trait 2 px, `stroke="currentColor"` (dont ICO-001 → ICO-027 : 43 icônes).
- `svg/rubriques-duo/` : 20 rubriques en deux tons figés (vert + orange) → `SvgPicture.asset(path)` sans colorFilter.
- `svg/rubriques-duo-mono/` : mêmes rubriques duo en currentColor.
- Flutter : copier `svg/*.svg` dans `assets/icons/`, déclarer le dossier dans pubspec, `flutter pub add flutter_svg`,
  ajouter `flutter/stepways_icons.dart` → `const StepIcon(StepwaysIcons.cadenasOuvert, semanticLabel: 'Déverrouillé')`.
  Le commentaire de chaque constante indique son code ICO.

Correspondance ICO :
001 cadenas, cadenas-ouvert · 002 panier · 003 telephone · 004 telecharger, mise-a-jour, synchronise (+ hors-ligne) ·
005 bouclier · 006 statistiques · 007 portefeuille, prix, boutique · 008 langue · 009 aide ·
010 train, taxi, bateau, avion (+ transport) · 011 notifications · 012 poids, taille, age, sexe · 013 suiveurs ·
014 gps-perdu · 015 cle · 016 video · 017 loi, cgu · 018 courrier, envoyer · 019 historique · 020 sablier ·
021 questionnaire · 022 animaux · 023 pdf · 024 hygiene, rechaud · 025 lien, lien-rompu · 026 effacer-telephone ·
027 connexion, deconnexion

## svg-vert/
Les mêmes icônes avec le vert Stepways #1F3D2B figé (pour Figma, le web, ou SvgPicture sans colorFilter).

## svg/ico-duo/
Les 43 icônes ICO-001 → ICO-027 en deux tons (vert #1F3D2B + orange #D9772B), même style que les rubriques duo.
Flutter : `SvgPicture.asset('assets/icons/ico-duo/cadenas.svg')` SANS colorFilter.

## svg/mat-duo/ — icônes d'interface MAT-001 → MAT-023 (38 dessins)
Deux tons vert + orange, même style que ico-duo. Versions une couleur dans `svg/` (currentColor) et `svg-vert/`.
Dans `stepways_icons.dart`, bloc `// --- MAT ---` : chaque constante porte son code MAT.
Correspondance : 001 info · 002 coche, coche-cercle, coche-pleine · 003 chevron-droite, chevron-gauche ·
004 fleche-haut, fleche-bas, fleche-avant, fleche-arriere · 005 radio, radio-coche, pastille · 006 rafraichir, annuler ·
007 plus, moins · 008 corbeille · 009 croix, refuser, interdit · 010 crayon · 011 deplier, replier · 012 poignee ·
013 menu · 014 copier · 015 inverser · 016 compresser · 017 image-manquante · 018 eprouvette · 019 geste, pouce ·
020 oeil, oeil-barre · 021 palette · 022 ville · 023 echelle
Note : coche-pleine contient une coche blanche (#FFFFFF) sur disque plein.
