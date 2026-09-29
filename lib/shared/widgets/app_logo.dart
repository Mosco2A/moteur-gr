import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/branding/app_branding.dart';

/// LE LOGO DE STEPWAYS — le seul widget qui l'affiche (tache 632).
///
/// Avant cette tache, l'application ne dessinait sa marque NULLE PART : ni
/// picto, ni nom, ni image. Les ecrans d'identite montraient un `Icons.terrain`
/// generique de Material, et les deux textes de marque prepares en traduction
/// (`branding.tagline`, `branding.subline`) n'etaient lus par aucun widget.
///
/// Toutes les mesures viennent de [AppBranding] : changer la famille de logo la
/// bas rebranche d'un coup tous les ecrans qui passent par ici.
///
/// TROIS FORMES, ET UNE REGLE DE FOND POUR CHACUNE. Christophe n'a pas livre de
/// variante claire du logo VERTICAL : seuls le picto et le logo horizontal
/// existent en deux traces. [AppLogo.vertical] est donc reserve aux fonds
/// clairs, et c'est verifie ci-dessous plutot que laisse au hasard.
class AppLogo extends StatelessWidget {
  /// Picto seul (la montagne, sans le nom). Pour les petites surfaces.
  const AppLogo.picto({super.key, required double taille, this.surFondSombre})
    : _forme = _FormeLogo.picto,
      _mesure = taille;

  /// Picto a gauche, nom a droite (rapport 747 x 190). [hauteur] est la hauteur
  /// totale ; la largeur en decoule.
  const AppLogo.horizontal({
    super.key,
    required double hauteur,
    this.surFondSombre,
  }) : _forme = _FormeLogo.horizontal,
       _mesure = hauteur;

  /// Picto au-dessus du nom (rapport 528 x 474). [largeur] est la largeur
  /// totale ; la hauteur en decoule.
  ///
  /// FOND CLAIR UNIQUEMENT : il n'existe pas de trace clair de cette forme.
  const AppLogo.vertical({super.key, required double largeur})
    : _forme = _FormeLogo.vertical,
      _mesure = largeur,
      surFondSombre = false;

  final _FormeLogo _forme;
  final double _mesure;

  /// Vrai si le logo est pose sur un fond SOMBRE (il faut alors le trace
  /// clair). Laisse a null, la luminosite du theme ambiant decide.
  final bool? surFondSombre;

  /// Rapports largeur / hauteur des fichiers livres, pour reserver la bonne
  /// place avant meme que le SVG soit decode (pas de saut de mise en page).
  static const double _ratioHorizontal = 747.44 / 190.0;
  static const double _ratioVertical = 528.48 / 474.22;

  @override
  Widget build(BuildContext context) {
    final sombre =
        surFondSombre ?? Theme.of(context).brightness == Brightness.dark;

    final (String actif, double largeur, double hauteur) = switch (_forme) {
      _FormeLogo.picto => (
        sombre ? AppBranding.pictoClair : AppBranding.picto,
        _mesure,
        _mesure,
      ),
      _FormeLogo.horizontal => (
        sombre ? AppBranding.logoHorizontalClair : AppBranding.logoHorizontal,
        _mesure * _ratioHorizontal,
        _mesure,
      ),
      _FormeLogo.vertical => (
        AppBranding.logoVertical,
        _mesure,
        _mesure / _ratioVertical,
      ),
    };

    return ExcludeSemantics(
      // Le nom de l'application est deja dit par le texte voisin sur chacun des
      // ecrans qui affichent ce logo ; le repeter ferait begayer le lecteur
      // d'ecran. Quand il est seul (premier ecran au demarrage), c'est un
      // ornement : rien a annoncer non plus.
      child: SvgPicture.asset(
        actif,
        width: largeur,
        height: hauteur,
        fit: BoxFit.contain,
      ),
    );
  }
}

enum _FormeLogo { picto, horizontal, vertical }
