# Stepways — assets

## svg/
Par logo (sentier, marches, courbes) : picto, picto-clair (fond sombre), logo-vertical,
logo-horizontal, logo-horizontal-clair, icone-app (1024, fond plein).
Texte converti en tracés : aucune police requise. Utilisable avec flutter_svg.

## png/
Logos verticaux et icônes d'app 1024 px en PNG.

## flutter/
1. Copier `flutter/assets/splash/` dans `assets/splash/` du projet (les .svg de `src/` sont les sources, inutiles au build).
2. `flutter pub add flutter_native_splash`
3. Copier `flutter_native_splash.yaml` à la racine du projet, puis `dart run flutter_native_splash:create`
   (variante Aube : `--path=flutter_native_splash_aube.yaml`).
4. Optionnel : `main_snippet.dart` pour garder le splash pendant l'initialisation.

Android 12+ n'affiche que le picto centré sur la couleur unie (limite du système) ;
le fond avec les crêtes s'affiche sur iOS et Android < 12.
