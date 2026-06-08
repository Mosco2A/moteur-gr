import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Image distante a chargement PARESSEUX, mise en cache disque (E5.2b).
///
/// Enveloppe [CachedNetworkImage] (dependance deja presente) :
/// - chargement differe + cache disque (pas de re-telechargement) ;
/// - [placeholder] statique pendant le chargement (aucune animation/ticker,
///   donc sans surcout de frame ni timer pendant) ;
/// - fallback explicite en cas d'echec (icone image cassee), jamais de crash ;
/// - URL nulle/vide -> placeholder neutre (aucune requete reseau).
///
/// Pensee offline-first : sur un sentier sans reseau, l'image absente
/// degrade proprement vers le placeholder au lieu de planter ou bloquer.
class LazyNetworkImage extends StatelessWidget {
  const LazyNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  /// URL distante de l'image. Null ou vide -> placeholder, aucune requete.
  final String? imageUrl;

  /// Largeur imposee (optionnelle).
  final double? width;

  /// Hauteur imposee (optionnelle).
  final double? height;

  /// Ajustement de l'image dans sa boite.
  final BoxFit fit;

  /// Arrondi optionnel des coins (applique image ET placeholder).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    final Widget content = url.isEmpty
        ? _ImagePlaceholder(
            width: width,
            height: height,
            icon: Icons.image_outlined,
          )
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            // Fade nul : pas d'AnimationController -> pas de ticker pendant.
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, _) => _ImagePlaceholder(
              width: width,
              height: height,
              icon: Icons.image_outlined,
            ),
            errorWidget: (context, _, __) => _ImagePlaceholder(
              width: width,
              height: height,
              icon: Icons.broken_image_outlined,
            ),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }
}

/// Boite neutre (gris clair) avec une icone centree — placeholder/fallback.
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.icon,
    this.width,
    this.height,
  });

  final IconData icon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.grey.shade400, size: 32),
    );
  }
}
