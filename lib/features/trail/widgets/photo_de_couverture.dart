/// La photo de couverture d'un sentier sur sa carte de catalogue — et rien du
/// tout quand il n'y en a pas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/fiche_de_sentier_provider.dart';

/// Hauteur de la couverture sur la carte du catalogue.
const double hauteurPhotoDeCouverture = 140;

/// LA PHOTO DU TREK SUR LE CATALOGUE (demande de Christophe du 17/10 09:22,
/// verbatim : « Il faut aussi une photo du trek sur le catalogue »).
///
/// ELLE N'OCCUPE AUCUNE PLACE QUAND ELLE N'EXISTE PAS, ET C'EST LE POINT
/// DELICAT D'UNE CARTE DE CATALOGUE. Reserver la hauteur d'une image « pour que
/// les cartes soient alignees » produirait exactement ce que la quatrieme
/// demande de la tache 846 interdit : un cadre vide sur chaque sentier sans
/// photo. Une carte plus courte n'est pas un defaut d'alignement, c'est une
/// carte qui porte moins de choses.
///
/// PENDANT LA LECTURE DU MANIFESTE, RIEN NON PLUS. Un indicateur de chargement
/// a la place d'une photo ferait sauter la carte a chaque ouverture du
/// catalogue, pour une image qui est dans le binaire : la lecture est locale et
/// brave. Tant qu'on ne sait pas, on n'affiche pas — on n'annonce pas.
///
/// LA MENTION N'EST PAS ICI, ET CE N'EST PAS UN OUBLI. La carte du catalogue
/// n'a pas la place d'une ligne de credit lisible, et un credit illisible n'est
/// pas un credit. Elle est portee par la BANDE DE PHOTOS de la fiche, a un
/// geste de la : c'est le meme arbitrage que la carte, dont l'attribution
/// OpenStreetMap se replie derriere un bouton plutot que de couvrir le relief.
class PhotoDeCouverture extends ConsumerWidget {
  /// La couverture du sentier [trailId]. Pas de fiche, pas de photo
  /// publiable : rien n'est affiche et rien n'est reserve.
  const PhotoDeCouverture({super.key, required this.trailId});

  /// Le sentier dont on montre la couverture.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fiche = ref.watch(ficheDeSentierProvider(trailId)).value;
    final photo = fiche?.couverture;
    if (photo == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Image.asset(
          photo.fichier,
          key: ValueKey('couverture-$trailId'),
          height: hauteurPhotoDeCouverture,
          width: double.infinity,
          fit: BoxFit.cover,
          // Une image absente du binaire ne laisse pas un trou : elle laisse un
          // aplat au ton de l'ecran. Ce repli sert aussi aux tests de widget,
          // qui n'ont pas les assets sous la main.
          errorBuilder: (context, error, stack) => Container(
            height: hauteurPhotoDeCouverture,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const ExcludeSemantics(
              child: StepIcon(
                StepwaysIcons.imageManquante,
                size: 28,
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
