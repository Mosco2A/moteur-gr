import 'dart:ui' show Color;

/// L'IDENTITE VISUELLE DE STEPWAYS — UN SEUL ENDROIT QUI DIT LAQUELLE EST ACTIVE.
///
/// Christophe a livre le 29/09 trois familles de logo completes et deux
/// variantes d'ecran de demarrage, et a tranche a 14:10 : « le premier vert avec
/// la montagne », c'est-a-dire la famille `sentier` et le splash `foret`.
///
/// Les trois familles portent exactement les memes six fichiers, nommes de la
/// meme facon (`<famille>-picto.svg`, `<famille>-logo-vertical.svg`...). Tout ce
/// qui suit est donc derive de [family] : changer cette seule constante
/// rebranche tous les ecrans Flutter d'un coup.
///
/// POUR CHANGER DE FAMILLE, ne pas editer ce fichier a la main — une commande :
/// ```
/// python tool/set_branding.py marches aube --generate
/// ```
/// Le script reecrit les deux constantes ci-dessous, regenere la couche avant de
/// l'icone adaptative Android, reecrit les deux fichiers de configuration a la
/// racine puis lance les deux generateurs. Sans lui, changer [family] ne
/// changerait QUE le logo affiche dans les ecrans Flutter : l'icone du lanceur
/// et l'ecran de demarrage sont des ressources NATIVES, cuites a la generation,
/// hors de portee du code Dart.
///
/// Les trois familles :
///   sentier  montagne blanche + chemin en pointilles orange, fond vert  #1F3D2B
///   marches  escalier blanc + fanion,                        fond orange #D9772B
///   courbes  cercles concentriques + point orange,           fond vert  #1F3D2B
abstract final class AppBranding {
  /// Famille de logo active. Ecrite par `tool/set_branding.py`.
  static const String family = 'sentier';

  /// Variante d'ecran de demarrage active. Ecrite par `tool/set_branding.py`.
  static const String splashVariant = 'foret';

  static const String _root = 'assets/branding/svg';

  /// Picto seul (sans le nom), trace sombre — a poser sur un fond CLAIR.
  static const String picto = '$_root/$family/$family-picto.svg';

  /// Picto seul, trace clair — a poser sur un fond SOMBRE.
  static const String pictoClair = '$_root/$family/$family-picto-clair.svg';

  /// Logo vertical (picto au-dessus du nom), trace sombre. Ratio 528 x 474.
  static const String logoVertical = '$_root/$family/$family-logo-vertical.svg';

  /// Logo horizontal (picto a gauche du nom), trace sombre. Ratio 747 x 190.
  static const String logoHorizontal =
      '$_root/$family/$family-logo-horizontal.svg';

  /// Logo horizontal, trace clair — a poser sur un fond SOMBRE.
  static const String logoHorizontalClair =
      '$_root/$family/$family-logo-horizontal-clair.svg';

  /// Icone d'application 1024, fond plein. Presente pour completude : ce n'est
  /// PAS ce que le telephone affiche — l'icone du lanceur est generee en
  /// ressources natives par `flutter_launcher_icons` depuis le PNG equivalent.
  static const String iconeApp = '$_root/$family/$family-icone-app.svg';

  /// Aplat de fond de l'icone d'application de la famille active.
  static const Color couleurFondIcone = family == 'marches'
      ? orangeSentier
      : vertSentier;

  /// Aplat de fond de l'ecran de demarrage de la variante active. Sert a
  /// prolonger le splash natif dans le premier ecran Flutter sans couture
  /// visible.
  static const Color couleurFondSplash = splashVariant == 'aube'
      ? cremeSentier
      : vertSentier;

  /// Vrai si le fond de l'ecran de demarrage est sombre — donc si le logo a y
  /// poser est la variante « clair ».
  static const bool splashSurFondSombre = splashVariant != 'aube';

  /// Le logo horizontal a poser sur le fond de demarrage actif.
  static const String logoSurFondSplash = splashSurFondSombre
      ? logoHorizontalClair
      : logoHorizontal;

  /// Le vert de la charte. C'est la couleur du trait des icones de rubrique en
  /// duo et le fond de l'ecran de demarrage Foret.
  static const Color vertSentier = Color(0xFF1F3D2B);

  /// L'orange de la charte : le soleil du logo, l'accent des icones en duo.
  static const Color orangeSentier = Color(0xFFD9772B);

  /// Le creme de la charte : l'encre posee sur le vert.
  static const Color cremeSentier = Color(0xFFF4F1E8);

  /// LE SEUL INTERRUPTEUR DUO / MONOCHROME (tache 632). Christophe a livre deux
  /// familles en trois traces — les 20 RUBRIQUES de l'application et les 43
  /// icones ICO-001 a ICO-027 : bicolore vert + orange, bicolore clair (pour
  /// fond sombre), et monochrome.
  ///
  /// Vrai (par defaut) : ces deux familles s'affichent en BICOLORE. C'est la
  /// palette du logo qu'il a choisi le 29/09 — une seule identite d'un bout a
  /// l'autre de l'application.
  ///
  /// Faux : tout repasse en monochrome, les icones prennent alors la couleur du
  /// theme comme n'importe quelle icone Material. Un seul mot a changer ici,
  /// aucun ecran a toucher.
  ///
  /// Les icones du terrain (meteo, points d'interet, navigation, materiel,
  /// actions d'enregistrement) n'existent qu'en un seul trace : elles restent
  /// monochromes quoi qu'il arrive, et suivent la couleur du theme.
  ///
  /// Quoi qu'il arrive, un appel qui impose une couleur precise (onglet actif,
  /// element desactive) retombe sur le monochrome : un trace bicolore fige
  /// ignorerait la couleur demandee et rendrait l'etat illisible.
  static const bool iconesEnDuo = true;

  /// L'INTERRUPTEUR DES 38 ICONES DE MECANIQUE D'INTERFACE (MAT-001 a MAT-023).
  ///
  /// Chevrons, fleches, coches, plus, moins, croix, crayon, corbeille : elles
  /// ne sont JAMAIS le sujet, elles accompagnent une ligne, un bouton, un
  /// champ. Elles doivent suivre la couleur du texte et se faire oublier — un
  /// chevron orange sur chaque ligne de liste crierait partout. D'ou `false`.
  ///
  /// Christophe les a pourtant livrees en bicolore aussi. Le jour ou il dit
  /// « mets-moi la mecanique en duo », c'est ce mot-la qui passe a `true`, et
  /// rien d'autre.
  static const bool mecaniqueEnDuo = false;
}
