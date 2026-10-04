/// Les feuilles de la carte : le panneau « Calques » et le detail d un
/// point d interet.
///
/// Bibliotheque de l'ecran `map_screen.dart` (lot 645-06b) : ces deux
/// feuilles etaient des methodes de l etat du contenu de la carte ; elles
/// ne lisent rien de cet etat hors l identifiant du sentier, desormais passe
/// en parametre.
library;

import 'package:flutter/material.dart';

import '../../../../core/models/poi.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/grise_en_demo.dart';
import '../../../map/widgets/poi_filter_bar.dart';
import '../../../map/widgets/poi_popup.dart';
import '../../../map/widgets/stage_poi_checklist.dart';
import '../../../../core/branding/stepways_icons.dart';

/// Ouvre le panneau « Calques » (toggle des types de POI) — parite GR20
/// (bouton calques de la Navigation). Reutilise [PoiFilterBar] : aucun
/// nouveau modele, la selection persiste dans [activePoiTypesProvider].
///
/// LOT D (tache 554) : le panneau porte DESORMAIS AUSSI la liste des points
/// d'eau et des hebergements DE L'ETAPE EN COURS, qu'on coche au passage
/// ([StagePoiChecklist]). C'est la troisieme fonction manquante de la carte :
/// le panneau de calques savait montrer et masquer des couches, il ne disait
/// pas « voila ce que tu vas croiser aujourd'hui ». La feuille de reference
/// fait exactement cela : elle est titree par l'etape et compte ses points.
///
/// Feuille DEFILANTE et haute : la liste des points peut etre longue, et une
/// feuille a hauteur naturelle deborderait sur les etapes bien pourvues.
void showMapLayersSheet(BuildContext context, String trailId) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (innerCtx, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const StepIcon(StepwaysIcons.calques),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.map.layersTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  t.map.layersSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              PoiFilterBar(trailId: trailId),
              const Divider(height: AppTheme.spacingLg),
              // Les points de l'etape en cours, coches au passage (LOT D).
              //
              // GRISES EN DEMO (tache 638, bug 14) : cocher un point de
              // passage ecrit la progression du sentier REEL en base. C'etait
              // la 8e des ecritures laissees ouvertes par le lot 634. La liste
              // reste LISIBLE — la demo doit montrer ce que l'ecran fait — mais
              // les coches sont visiblement indisponibles.
              GriseEnDemo(child: StagePoiChecklist(trailId: trailId)),
            ],
          ),
        ),
      );
    },
  );
}

/// Affiche le detail d'un POI au tap sur son marqueur (parite GR20 : bulle
/// d'info au tap). Reutilise [PoiPopup] dans un bottom-sheet.
void showMapPoiDetails(BuildContext context, PoiModel poi) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PoiPopup(poi: poi),
      ),
    ),
  );
}
