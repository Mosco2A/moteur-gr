/// La bande de photos d'un sentier, et la mention de chaque image EN DESSOUS
/// d'elle — un credit qu'on ne lit pas n'est pas un credit.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/models/fiche_de_sentier.dart';
import '../../../core/theme/app_theme.dart';

/// Hauteur de la bande. Assez haute pour qu'une photo de paysage se lise,
/// assez basse pour que la description reste visible sans faire defiler.
const double hauteurBandeDePhotos = 180;

/// LA BANDE DE PHOTOS — ET RIEN QUAND IL N'Y A PAS DE PHOTO.
///
/// LA REGLE DU TROU (quatrieme demande de la tache 846, verbatim : « pas de
/// trou, pas de point d'interrogation, pas de cadre vide »). Ce widget rend
/// [SizedBox.shrink] quand la liste est vide : pas un cadre gris, pas une icone
/// d'image manquante, pas un espace reserve « au cas ou ». Un sentier sans
/// photo doit avoir une fiche qui a l'air finie, pas une fiche qui a l'air
/// cassee — et c'est la difference entre afficher un vide et ne rien afficher.
///
/// LA MENTION EST SOUS CHAQUE PHOTO, PAS DANS UN PIED DE PAGE. Les licences
/// CC-BY exigent que l'auteur soit cite ; une ligne de credits regroupes en bas
/// d'ecran ne dit plus QUELLE photo appartient a QUI des qu'il y en a deux.
/// C'est le meme raisonnement que `AttributionOsm` pour la carte : la mention
/// vit a cote de ce qu'elle credite.
class BandeDePhotos extends StatelessWidget {
  /// La bande des [photos] d'un sentier. Liste vide = rien d'affiche.
  const BandeDePhotos({super.key, required this.photos});

  /// Les photos PUBLIABLES, dans l'ordre du manifeste. Le filtrage des photos
  /// sans provenance est fait a la LECTURE (`lireFicheDeSentier`), pas ici :
  /// une image non publiable ne doit meme pas arriver jusqu'a un widget.
  final List<PhotoDeSentier> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: hauteurBandeDePhotos,
      child: ListView.separated(
        key: const ValueKey('bande-de-photos'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
        itemCount: photos.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppTheme.spacingSm),
        itemBuilder: (context, index) => _Photo(photo: photos[index]),
      ),
    );
  }
}

/// Une photo et sa mention, en colonne.
class _Photo extends StatelessWidget {
  const _Photo({required this.photo});

  final PhotoDeSentier photo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: Image.asset(
                photo.fichier,
                width: 240,
                fit: BoxFit.cover,
                // UNE IMAGE QUI NE CHARGE PAS NE LAISSE PAS UN CADRE VIDE.
                // Elle laisse un aplat au ton de l'ecran, avec l'icone d'image
                // manquante : le randonneur voit qu'il manque une photo, il ne
                // voit pas une application cassee. Ce repli sert aussi aux
                // tests de widget, qui n'ont pas les assets sous la main.
                errorBuilder: (context, error, stack) => Container(
                  width: 240,
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const ExcludeSemantics(
                    child: StepIcon(
                      StepwaysIcons.imageManquante,
                      size: 32,
                      color: AppTheme.grisTexteSecondaire,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          // LA MENTION, LISIBLE. Deux lignes au plus : au-dela, le credit
          // mangerait la photo — mais il n'est jamais masque.
          Text(
            photo.mention,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
        ],
      ),
    );
  }
}
