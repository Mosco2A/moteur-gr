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
///  2. ELLE DIT CE QU'EST CHAQUE SIGNE, PAS UN PARAGRAPHE PAR SIGNE. Le guide
///     de référence accompagne chaque icône d'un texte d'explication. Ces textes
///     n'existent pas encore dans les cinq langues de StepWays, et un texte en
///     dur est interdit ici. La légende emploie donc les libellés déjà traduits
///     (`t.poi.*`, `t.a11y.*`, `t.map.*`) : elle est juste dans les cinq
///     langues, et prête à recevoir les paragraphes quand les clés existeront.
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
                  ),
                  // Le tracé du sentier : c'est l'itinéraire, dessiné dans la
                  // couleur du sentier courant (jamais un rouge en dur comme
                  // dans la référence, qui n'a qu'un sentier).
                  _GuideRow(
                    icon: Icons.timeline,
                    color: scheme.primary,
                    label: t.itinerary.title,
                  ),
                  if (sortedTypes.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _GuideSection(title: t.stage.pois),
                    for (final type in sortedTypes)
                      _GuideRow(
                        icon: PoiTypeConfig.getStyle(type).icon,
                        color: PoiTypeConfig.getStyle(type).color,
                        label: poiTypeLabel(type),
                      ),
                  ],

                  // --- Les boutons de la carte ---
                  const SizedBox(height: AppTheme.spacingSm),
                  _GuideSection(title: t.map.layersTitle),
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
                    description: t.hub.cards.journalSub,
                  ),
                  _GuideRow(
                    icon: Icons.emergency,
                    color: AppTheme.rougeUrgence,
                    label: t.a11y.sos,
                    description: t.sos.body,
                  ),
                  _GuideRow(
                    icon: Icons.my_location,
                    color: scheme.primary,
                    label: t.a11y.centerOnMe,
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
                    description: t.map.stageRemaining(km: '—'),
                  ),
                  _GuideRow(
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.rougeUrgence,
                    label: t.map.offTrackChip,
                    description: t.navAlert.offTrackNotifTitle,
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
