import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../poi/domain/poi_type_config.dart';
import '../../poi/domain/poi_type_label.dart';
import '../providers/map_pois_provider.dart';

/// Ouvre le GUIDE DE LA CARTE (LOT D, tâche 554 — manque réel n°2).
///
/// CE QUI MANQUAIT, ET QUI EST COMBLÉ ICI : la navigation de référence porte un
/// guide de ses icônes (`_showNavigationGuide`, GR20 l.1087-1284) ; la carte
/// StepWays n'en avait AUCUN. Un marcheur voyait des pastilles de couleur sans
/// savoir laquelle est une source et laquelle est un refuge.
///
/// DEUX DIFFÉRENCES ASSUMÉES AVEC LA RÉFÉRENCE, et il faut les nommer :
///
///  1. LA LÉGENDE EST CALCULÉE SUR LE SENTIER COURANT, pas écrite en dur. Le
///     guide de référence énumère les icônes du GR20 (refuges PNRC, bergeries,
///     gîtes…). StepWays est un moteur multi-sentiers : la légende n'affiche que
///     les types de points RÉELLEMENT présents sur le sentier chargé
///     ([availablePoiTypesProvider]), avec l'icône et la couleur du registre
///     ([PoiTypeConfig]) — donc toujours exactement ce que la carte dessine.
///
///  2. CHAQUE SIGNE A MAINTENANT SON EXPLICATION (branchée tâche 557). À la
///     livraison de la tâche 554, le guide n'affichait que des NOMS : les textes
///     d'explication n'existaient pas encore dans les cinq langues, et un texte
///     en dur est interdit ici. La tâche 552 a créé les clés — `map.guide.*`
///     pour les signes et les boutons, `map.guide.poi.*` pour les dix types de
///     points — et elles sont lues ici. Chaque ligne dit donc ce qu'est le
///     signe ET ce sur quoi on peut compter (« une source peut être à sec en
///     été »), ce qu'un nom seul ne disait pas.
///
///     Les descriptions EMPRUNTÉES à d'autres écrans ont disparu avec ce
///     branchement : la ligne photo ne lit plus le sous-titre de la carte
///     Journal du hub, la ligne SOS ne lit plus le corps de l'écran d'urgence,
///     la ligne « étape en cours » ne lit plus une phrase de distance avec un
///     tiret en guise de chiffre, et la ligne hors-trace ne lit plus le titre
///     d'une notification.
Future<void> showMapGuideSheet(BuildContext context, String trailId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusBottomSheet),
      ),
    ),
    builder: (_) => _MapGuideSheet(trailId: trailId),
  );
}

class _MapGuideSheet extends ConsumerWidget {
  const _MapGuideSheet({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Types de points réellement présents sur le sentier courant. En attente ou
    // en erreur : liste vide -> la légende des points disparaît, celle des
    // boutons reste. Jamais de spinner bloquant pour un écran d'explication.
    final types = ref.watch(availablePoiTypesProvider(trailId)).value ??
        const <String>{};
    final sortedTypes = types.toList()..sort();

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase,
                vertical: AppTheme.spacingSm,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: scheme.primary),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      t.map.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                children: [
                  // --- Ce qui se lit SUR la carte ---
                  _GuideRow(
                    icon: Icons.my_location,
                    color: scheme.primary,
                    label: t.a11y.userPosition,
                    description: t.map.guide.position,
                  ),
                  // Le tracé du sentier : c'est l'itinéraire, dessiné dans la
                  // couleur du sentier courant (jamais un rouge en dur comme
                  // dans la référence, qui n'a qu'un sentier).
                  _GuideRow(
                    icon: Icons.timeline,
                    color: scheme.primary,
                    label: t.itinerary.title,
                    description: t.map.guide.track,
                  ),
                  if (sortedTypes.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _GuideSection(title: t.stage.pois),
                    for (final type in sortedTypes)
                      _GuideRow(
                        icon: PoiTypeConfig.getStyle(type).icon,
                        color: PoiTypeConfig.getStyle(type).color,
                        label: poiTypeLabel(type),
                        description: poiTypeGuide(type),
                      ),
                  ],

                  // --- Les boutons de la carte ---
                  //
                  // TITRE DÉDIÉ (tâche 557) : la section s'intitulait
                  // `t.map.layersTitle` — « Fonds de carte » —, le titre du
                  // sélecteur de calques. Elle énumère les BOUTONS, dont le
                  // sélecteur de calques n'est que le premier. Elle lit
                  // maintenant `t.map.guide.buttonsTitle` (« Boutons »).
                  const SizedBox(height: AppTheme.spacingSm),
                  _GuideSection(title: t.map.guide.buttonsTitle),
                  _GuideRow(
                    icon: Icons.layers,
                    color: scheme.primary,
                    label: t.map.layers,
                    description: t.map.layersSubtitle,
                  ),
                  _GuideRow(
                    icon: Icons.photo_camera,
                    color: AppTheme.orangeDifficile,
                    label: t.journal.addPhoto,
                    description: t.map.guide.photo,
                  ),
                  // SOS — L'ENTREE EST VRAIE, ET ELLE DIT MAINTENANT SA
                  // CONDITION (tache 568, Q5).
                  //
                  // LE SOUPCON DE DEPART etait que le guide documentait « une
                  // icone SOS qui n'existe sur aucun ecran ». LA MESURE DIT
                  // AUTRE CHOSE, et il faut le dire : l'icone EXISTE, portee par
                  // [SosButton] (`Icons.emergency`), pose dans la colonne de
                  // gauche de cette meme carte (`map_screen.dart`) et en FAB du
                  // cockpit. Ce qui etait FAUX, c'est le texte : cette pastille
                  // SE MASQUE hors rando active, alors que ce guide s'ouvre a
                  // tout moment depuis la carte. Un randonneur qui le lisait en
                  // preparation cherchait un bouton absent.
                  //
                  // On ne retire donc pas l'entree — ce serait cacher la
                  // fonction la plus importante de l'ecran. On rend le texte
                  // EXACT, en nommant la condition, exactement comme la ligne
                  // « etape en cours » nomme deja la sienne (« un tiret signifie
                  // que la randonnee n'a pas encore demarre »).
                  _GuideRow(
                    icon: Icons.emergency,
                    color: AppTheme.rougeUrgence,
                    label: t.a11y.sos,
                    description: '${t.map.guide.sos} ${t.map.guide.onlyInTrek}',
                  ),
                  _GuideRow(
                    icon: Icons.my_location,
                    color: scheme.primary,
                    label: t.a11y.centerOnMe,
                    description: t.map.guide.centerOnMe,
                  ),
                  _GuideRow(
                    icon: Icons.add,
                    color: scheme.primary,
                    label: t.a11y.zoomIn,
                  ),
                  _GuideRow(
                    icon: Icons.remove,
                    color: scheme.primary,
                    label: t.a11y.zoomOut,
                  ),

                  // --- Les indicateurs ---
                  const SizedBox(height: AppTheme.spacingSm),
                  _GuideSection(title: t.stage.statistics),
                  _GuideRow(
                    icon: Icons.linear_scale,
                    color: scheme.primary,
                    label: t.nav.currentStage,
                    description: t.map.guide.currentStage,
                  ),
                  _GuideRow(
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.rougeUrgence,
                    label: t.map.offTrackChip,
                    description: t.map.guide.offTrack,
                  ),
                  const SizedBox(height: AppTheme.spacingBase),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(t.programme.info.close),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingBase),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre de section du guide (même graphisme que le (i) du Programme).
class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingSm,
        bottom: AppTheme.spacingSm,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Une ligne du guide : pastille d'icône, nom, et explication si elle existe.
class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.icon,
    required this.color,
    required this.label,
    this.description,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description != null)
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
