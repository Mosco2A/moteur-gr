import 'package:flutter/material.dart';

/// Palette CATEGORIELLE des icones du hub, portee par le theme/peau
/// (ThemeExtension) — retour Chris 09/09, reco AUDIT #IR02.
///
/// PROBLEME corrige : avant, TOUTES les icones du hub etaient peintes en
/// `colorScheme.primary` (accent-sentier unique) -> rendu « vert uni »,
/// contraire a la variete multicolore de GR20 (bleu / vert / orange / teal /
/// rouge / jaune selon la nature de la carte).
///
/// SOLUTION : une palette de teintes VARIEES, exposee comme un jeu de tokens
/// (comme les couleurs de denivele), et injectee dans `ThemeData.extensions`.
/// Les composants (QuickAccessCard, HubSection, cartes du hub) lisent
/// `CategoryIconColors.of(context)` et n'ecrivent JAMAIS de couleur en dur
/// ecran par ecran — 100 % pilote par le theme, discipline design system
/// preservee (CCO §0).
///
/// Parite GR20 : les valeurs reprennent la palette de `GR20/app_theme.dart`
/// (vertMaquis/bleuMed/orangeTerre/… + le teal et le jaune diplome). La peau
/// peut fournir sa propre variante (les 3 peaux partagent la meme table par
/// defaut, cf. [CategoryIconColors.defaults] ; une peau future peut la
/// surcharger sans toucher aux ecrans).
@immutable
class CategoryIconColors extends ThemeExtension<CategoryIconColors> {
  const CategoryIconColors({
    required this.blue,
    required this.green,
    required this.greenLight,
    required this.orange,
    required this.teal,
    required this.red,
    required this.yellow,
  });

  /// Bleu (parite GR20 `bleuMed`) — faisabilite, calendrier, offline, resume.
  final Color blue;

  /// Vert profond (parite GR20 `vertMaquis`) — itineraire, navigation, recap.
  final Color green;

  /// Vert clair (parite GR20 `vertMaquisLight`) — nuitees, groupe, section
  /// Randonner.
  final Color greenLight;

  /// Orange (parite GR20 `orangeTerre`) — programme, transport, journal, info,
  /// meteo.
  final Color orange;

  /// Teal (parite GR20 `Color(0xFF00796B)`) — materiel / sac, checklist.
  final Color teal;

  /// Rouge (parite GR20 `rougeUrgence`) — risque incendie.
  final Color red;

  /// Jaune (parite GR20 `Color(0xFFFDD835)`) — diplome, section Apres.
  final Color yellow;

  /// Palette par defaut, alignee sur la variete GR20. Partagee par les 3 peaux
  /// en l'etat (une peau future peut surcharger via [copyWith] sans toucher aux
  /// ecrans). Valeurs iso-GR20 (`GR20/app/lib/core/theme/app_theme.dart`).
  static const CategoryIconColors defaults = CategoryIconColors(
    blue: Color(0xFF1565C0), // GR20 bleuMed
    green: Color(0xFF2D5016), // GR20 vertMaquis
    greenLight: Color(0xFF4CAF50), // GR20 vertMaquisLight
    orange: Color(0xFFE65100), // GR20 orangeTerre
    teal: Color(0xFF00796B), // GR20 materiel & sac
    red: Color(0xFFD32F2F), // GR20 rougeUrgence
    yellow: Color(0xFFFDD835), // GR20 diplome
  );

  /// Lit la palette categorielle depuis le [context], avec repli sur
  /// [defaults] si aucune extension n'est injectee (robustesse : un widget lu
  /// hors d'un theme StepWays reste rendu sans crash).
  static CategoryIconColors of(BuildContext context) {
    return Theme.of(context).extension<CategoryIconColors>() ?? defaults;
  }

  @override
  CategoryIconColors copyWith({
    Color? blue,
    Color? green,
    Color? greenLight,
    Color? orange,
    Color? teal,
    Color? red,
    Color? yellow,
  }) {
    return CategoryIconColors(
      blue: blue ?? this.blue,
      green: green ?? this.green,
      greenLight: greenLight ?? this.greenLight,
      orange: orange ?? this.orange,
      teal: teal ?? this.teal,
      red: red ?? this.red,
      yellow: yellow ?? this.yellow,
    );
  }

  @override
  CategoryIconColors lerp(
    covariant ThemeExtension<CategoryIconColors>? other,
    double t,
  ) {
    if (other is! CategoryIconColors) return this;
    return CategoryIconColors(
      blue: Color.lerp(blue, other.blue, t) ?? blue,
      green: Color.lerp(green, other.green, t) ?? green,
      greenLight: Color.lerp(greenLight, other.greenLight, t) ?? greenLight,
      orange: Color.lerp(orange, other.orange, t) ?? orange,
      teal: Color.lerp(teal, other.teal, t) ?? teal,
      red: Color.lerp(red, other.red, t) ?? red,
      yellow: Color.lerp(yellow, other.yellow, t) ?? yellow,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryIconColors &&
        other.blue == blue &&
        other.green == green &&
        other.greenLight == greenLight &&
        other.orange == orange &&
        other.teal == teal &&
        other.red == red &&
        other.yellow == yellow;
  }

  @override
  int get hashCode =>
      Object.hash(blue, green, greenLight, orange, teal, red, yellow);
}
