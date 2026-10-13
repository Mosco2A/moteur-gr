# Identite visuelle de StepWays

Livree par Christophe le 29/09 (tache 632), en deux envois : les logos, puis les
icones. Sa consigne d'origine est conservee telle quelle dans
`README-source-christophe.md` et `../icons/README-source-christophe.md`.

## Ce qui est actif

- **Famille de logo : sentier** — montagne blanche, chemin en pointilles orange,
  fond vert `#1F3D2B`. Choix de Christophe, 29/09 14:10 : « le premier vert avec
  la montagne ».
- **Ecran de demarrage : foret** — fond vert `#1F3D2B`. Meme decision ; c'est la
  variante que son README marque « par defaut ».
- **Icones de rubrique : duo** — vert `#1F3D2B` + orange `#D9772B`, exactement la
  palette du logo choisi.

## Changer de famille — un geste

```
python tool/set_branding.py marches aube --generate
```

Trois familles : `sentier`, `marches`, `courbes`. Deux splashs : `foret`, `aube`.
Le script reecrit **tout** ce qui depend du choix :

- `lib/core/branding/app_branding.dart` — les deux constantes que lit l'application
- `assets/branding/icons/app-icon-1024.png` — l'icone pleine (iOS, Android < 8)
- `assets/branding/icons/adaptive-foreground.png` — la couche AVANT de l'icone Android
- `flutter_launcher_icons.yaml` et `flutter_native_splash.yaml` — a la racine
- `assets/icons/rubriques-duo-clair/` — les 20 rubriques pour fond sombre

`--generate` enchaine ensuite `dart run flutter_launcher_icons` et
`dart run flutter_native_splash:create`. Sans lui, le script se contente
d'afficher les deux commandes.

Le filet : `test/core/branding/app_branding_test.dart` refuse un depot ou la
constante Dart dit une famille et les fichiers de configuration une autre. C'est
le seul ecart qui ne se verrait pas a l'oeil — l'ecran montrerait un logo, le
lanceur un autre, et rien ne planterait.

## Rangement

```
assets/branding/
  svg/<famille>/     6 traces par famille : picto, picto-clair, logo-vertical,
                     logo-horizontal, logo-horizontal-clair, icone-app.
                     Texte deja converti en courbes : aucune police requise.
                     EMBARQUE dans l'application (quelques centaines d'octets).
  png/               logo vertical et icone 1024 de chaque famille. Sources de
                     generation, PAS embarquees.
  icons/             fabrique par tool/set_branding.py depuis png/. Ne pas editer.
assets/splash/       les deux variantes pretes + leurs sources SVG. Consommees
                     par flutter_native_splash, PAS embarquees.
assets/icons/        les 75 icones (voir son README).
```

Il n'y a PAS de variante claire du logo vertical : seuls le picto et le logo
horizontal existent en deux traces. `AppLogo.vertical` est donc reserve aux fonds
clairs, et le code le force plutot que de laisser le choix a l'appelant.

## Ce que le systeme impose au demarrage

C'est la limite que le README de Christophe annonce, et elle ne se contourne pas :

- **Android 12+** : le systeme impose sa propre fenetre de demarrage. Il n'affiche
  QUE le picto centre sur la couleur unie `#1F3D2B`. Le fond avec les cretes
  n'apparait pas.
- **iOS et Android < 12** : le fond avec les cretes s'affiche, avec le logo
  complet (picto + nom + « Chaque pas compte. »).

Dans les deux cas, le premier ecran Flutter (`_BootstrapGate`, `lib/main.dart`)
reprend la meme couleur et le meme logo : la passation entre l'ecran natif et
l'application ne se voit pas. Avant la tache 632, elle se voyait — un flash blanc.

## Pourquoi la couche avant de l'icone Android est fabriquee, et pas recopiee

Android 8+ masque l'icone adaptative en cercle, goutte ou squircle selon le
lanceur, et ne garantit que le disque central (72 dp sur les 108 dp de la couche).
L'icone 1024 de Christophe place le picto sur 66,8 % du carre : plein cadre c'est
juste, mais sous un masque circulaire les pieds de la montagne sortiraient du
disque. `tool/set_branding.py` redescend donc le picto a 50 % du carre
(`PICTO_RATIO`), ce qui laisse le dessin entier dans la zone sure pour les trois
familles, masque compris.

## Les icones

Les 156 icones de Christophe et leurs variantes bicolores vivent dans
`assets/icons/` — voir le README de ce dossier. Elles suivent la meme regle que
le logo : un seul endroit decide (`AppBranding.iconesEnDuo` pour les rubriques
et les ICO, `AppBranding.mecaniqueEnDuo` pour les MAT), et `tool/set_branding.py`
derive les variantes claires. Plus une seule icone Material ne subsiste dans
`lib/`.
