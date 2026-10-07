# Captures d'écran et visuels — App Store (StepWays)

Réécrit le 07/10/2026 (lot fiche magasin et préparation Apple) d'après la
page Apple « Screenshot specifications » et la page « Creative assets
specifications », lues le 07/10/2026. L'ancienne version demandait le 6,7" et
le 5,5" comme obligatoires : ce n'est plus la règle d'Apple.

Aucune image n'est versionnée ici. Ce fichier dit quoi produire, à quelle
taille et avec quels écrans. Formats acceptés : `.png`, `.jpg` ou `.jpeg`,
**sans transparence** (aucun canal alpha). On peut fournir jusqu'à 10 captures
par taille.

## 1. Ce qu'il faut produire, taille par taille

| # | Emplacement | Taille en pixels (portrait) | Statut | Appareil du simulateur |
|---|---|---|---|---|
| A | iPhone, Dynamic Island grand (6,9") | **1320 × 2868** | À produire : jeu de référence | iPhone 17 Pro Max |
| B | iPhone, Dynamic Island moyen (6,3") | **1206 × 2622** | À produire : Apple le marque **obligatoire pour soumettre** | iPhone 17 Pro |
| C | iPad 13" | **2064 × 2752** | **Obligatoire tant que l'application est déclarée iPad** (voir § 4) | iPad Pro 13" (M4 ou plus récent) |
| D | iPhone Duo, écran extérieur | **1398 × 2034** | Nouveauté Apple. Non obligatoire aujourd'hui d'après la page Apple | iPhone Duo, s'il est dans le simulateur de Xcode |
| E | iPhone Duo, écran intérieur | **2007 × 2853** | Nouveauté Apple. Non obligatoire aujourd'hui | iPhone Duo, écran déplié |
| F | Image d'en-tête de la page produit et des résultats de recherche | **5244 × 2950** (16:9, `.png` seulement) | Nouveauté Apple. Facultative. Recommandée | Visuel composé, pas une capture |
| F' | Variante de l'en-tête au format cinéma | **3840 × 1646** (21:9, `.png`, `.jpg` ou `.jpeg`) | Facultative. Ne sert **que** pour l'en-tête, pas pour la recherche | Visuel composé |

Les tailles plus petites (Face ID, bouton principal) sont redimensionnées par
Apple à partir de A et B. Il est inutile de les produire.

**Duo : à vérifier le jour de la soumission.** Un site tiers (appscreens.com)
annonce les captures Duo obligatoires à partir d'avril 2027. La page Apple
lue le 07/10/2026 ne le dit pas. Si App Store Connect affiche la case Duo
comme obligatoire, produire D et E avec les mêmes écrans que A.

**Pourquoi produire A et B.** La page Apple marque la taille moyenne (B)
comme obligatoire, et la grande (A) est celle qui se voit le mieux sur la
page du magasin. Les deux se font avec le même scénario, sur deux
simulateurs.

## 2. Les écrans à montrer, dans l'ordre

Tous ces écrans existent et disent la vérité de la fiche. Ils se capturent
dans le **mode démo** (catalogue, « Essayer la démo »), sauf ceux marqués ★.
Ceux-là demandent un sentier acheté en bac à sable, ou une session de
capture pilotée par `integration_test/`.

| # | Écran | Ce qu'on doit voir | Phrase de la fiche qu'il prouve |
|---|---|---|---|
| 1 | Carte du sentier | La trace, les repères d'étapes et quelques points d'intérêt. **Capturer avec le réseau**, sinon le fond de carte est vide | « Carte du sentier avec la trace et les étapes » |
| 2 | Liste des étapes | Distance, dénivelé et temps estimé de chaque étape | « Étapes détaillées » |
| 3 | Détail d'une étape | Dénivelé positif et négatif, temps de marche, description | « dénivelé positif et négatif » |
| 4 | Planning | Le sentier découpé en jours | « Découpage du sentier en jours » |
| 5 | Météo d'une étape | Le jour même et les deux suivants | « Météo de chaque étape » |
| 6 | Sécurité | Bouton SOS et numéros de secours de la région, ou l'écran risque incendie | « Bouton SOS qui appelle le 112 » |
| 7 | Matériel et sac | La liste à cocher | « Liste d'équipement à cocher » |
| 8 ★ | Cockpit en marche | Distance, dénivelé, temps et vitesse en direct, position sur la carte | « progression en temps réel » |
| 9 ★ | Carnet de route | Une note avec une photo, rangée sous son étape | « photos classées par étape » |
| 10 ★ | Diplôme | Le diplôme de fin de parcours | « Diplôme de fin de parcours personnalisé » |

**À ne pas montrer.**

- La bannière « MODE DÉMO » : sortir de la démo n'est pas nécessaire, mais
  recadrer ou choisir des vues où elle ne masque rien.
- La bannière publicitaire. Apple refuse les captures trompeuses, et une
  publicité de test « Test Ad » serait pire.
- Tout ce que la fiche ne promet plus : partage en temps réel, carte hors
  ligne, profil altimétrique interactif, mode économie de batterie.
- Les entrées « Volcans Trail » (sentier de test) et « Traversée des
  Pyrénées » (sans trace) du catalogue.

**Langues.** Un jeu de captures par langue de la fiche (fr, en, de, it, es),
puisque les libellés à l'écran changent. On change la langue dans
l'application (Réglages), pas dans le simulateur. Si le temps manque, le jeu
français peut servir pour toutes les langues : Apple l'accepte, au prix
d'une fiche moins soignée.

## 3. L'image d'en-tête (F et F')

- **F, 5244 × 2950, 16:9, PNG sans transparence.** Un seul fichier remplit à
  la fois l'en-tête de la page produit et l'emplacement des résultats de
  recherche.
- Contenu proposé : une photo de sentier de montagne en pleine largeur. Sur
  un tiers du cadre, un iPhone qui affiche l'écran 1 (la carte avec la
  trace). Au plus le nom « StepWays ». Pas de slogan qui promettrait plus que
  la fiche, et en particulier pas « hors ligne » tant que la carte ne l'est
  pas.
- Garder le sujet au centre. Les recadrages d'Apple (21:9 pour l'en-tête, 3:2
  pour la recherche) mangent les bords.
- **F', 3840 × 1646**, seulement si l'on veut un cadrage cinéma propre à
  l'en-tête. Sinon, F suffit.
- Photo : uniquement une image dont Only1Cent détient les droits. Aucune
  marque de sentier.

## 4. iPad : décision de Christophe

Le projet Xcode déclare l'application pour iPhone **et** iPad
(`TARGETED_DEVICE_FAMILY = "1,2"` dans `ios/Runner.xcodeproj/project.pbxproj`).
Tant que c'est le cas, App Store Connect exige au moins une capture iPad 13"
(C), et le reviewer peut tester sur iPad.

- **Option 1 : garder l'iPad.** Produire le jeu C, et vérifier l'application
  sur un simulateur iPad, en paysage comme en portrait.
- **Option 2 : iPhone seulement.** Passer `TARGETED_DEVICE_FAMILY` à `"1"`
  pour les cibles Runner et TrekWidget. Plus de captures iPad, et
  l'application reste installable sur iPad en mode compatibilité iPhone.

## 5. Icône App Store

1024 × 1024 px, PNG sans canal alpha et sans coins arrondis. Apple applique
lui-même les coins.
