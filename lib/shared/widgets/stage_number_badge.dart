import 'package:flutter/material.dart';

/// Pastille ronde affichant le numero d'une etape.
///
/// E5.5a (polish animations) : ce widget partage est utilise a la fois dans
/// la liste des etapes (StageListTile) et dans l'en-tete du detail d'etape.
/// Enveloppe dans un [Hero] avec un tag stable par etape, il anime une
/// transition fluide liste -> detail (le numero "vole" de la carte vers le
/// titre). Le [Material] interne garantit un rendu correct du texte pendant
/// le vol Hero (sinon le texte apparaitrait sans style de Material).
///
/// Le Hero est desactivable ([animate] = false) pour les contextes ou la
/// meme etape peut apparaitre deux fois a l'ecran (sinon Flutter leve une
/// erreur "multiple heroes with the same tag").
class StageNumberBadge extends StatelessWidget {
  const StageNumberBadge({
    super.key,
    required this.number,
    this.size = 40,
    this.fontSize = 16,
    this.animate = true,
  });

  /// Numero d'etape affiche.
  final int number;

  /// Diametre de la pastille (px).
  final double size;

  /// Taille de police du numero.
  final double fontSize;

  /// Active la transition Hero (true par defaut).
  final bool animate;

  /// Tag Hero stable, derive du numero d'etape.
  static String heroTagFor(int number) => 'stage-number-$number';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );

    if (!animate) return badge;

    return Hero(
      tag: heroTagFor(number),
      // Material transparent : rend le texte correctement pendant le vol.
      flightShuttleBuilder: (_, __, ___, ____, toContext) =>
          Material(type: MaterialType.transparency, child: badge),
      child: Material(type: MaterialType.transparency, child: badge),
    );
  }
}
