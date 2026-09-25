import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/poi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../poi/domain/poi_type_config.dart';
import '../../poi/domain/poi_type_label.dart';
import '../../trail/providers/pois_provider.dart';
import '../../trail/providers/stages_provider.dart';
import '../providers/stage_poi_check_provider.dart';
import '../providers/track_position_provider.dart';

/// LISTE DES POINTS DE L'ETAPE EN COURS, cochables au passage (LOT D, 554).
///
/// LE MANQUE REEL QU'ELLE COMBLE. La navigation de reference ouvre, depuis sa
/// carte, une feuille TITREE PAR L'ETAPE qui compte ses refuges et ses points
/// d'eau (`_showPoiChecklist`). StepWays n'avait que son panneau de calques :
/// afficher et masquer des couches est une AUTRE fonction — utile, mais qui ne
/// repond pas a « qu'est-ce que je vais croiser aujourd'hui, et qu'est-ce que
/// j'ai deja passe ».
///
/// CE QU'ELLE FAIT DE PLUS QUE LA REFERENCE : chaque point se COCHE. La
/// reference compte les points de l'etape mais ne permet pas de les pointer au
/// passage ; sur le terrain, c'est le geste qui manque (« la source du col,
/// c'est fait »). Les coches vivent le temps de la session d'application, et
/// aucun chiffre du trek n'en depend — cf. [stagePoiChecksProvider].
///
/// GENERIQUE, ZERO SENTIER EN DUR : les points viennent de [poisProvider] et les
/// familles de types de [PoiTypeConfig]. Un sentier sans refuge affiche le
/// message « aucun hebergement reference », deja traduit dans les cinq langues.
class StagePoiChecklist extends ConsumerWidget {
  const StagePoiChecklist({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Etape a lister : celle DETECTEE si la projection GPS repond, sinon la
    // premiere du programme. Meme repli que la barre d'etape de la carte.
    final detected = ref
        .watch(trackPositionProvider)
        .whenOrNull(data: (s) => s.stageDetection.stageNumber);
    final stages = ref.watch(
      stagesProvider(trailId).select((async) => async.value),
    );
    final stageNumber = (detected != null && detected > 0)
        ? detected
        : (stages == null || stages.isEmpty ? 1 : stages.first.stageNumber);

    final allPois = ref.watch(
      poisProvider(trailId).select((async) => async.value),
    );
    final stagePois = (allPois ?? const <PoiModel>[])
        .where((p) => p.stageNumber == stageNumber)
        .toList(growable: false);
    final water = stagePois
        .where((p) => PoiTypeConfig.waterTypes.contains(p.type))
        .toList(growable: false);
    final shelters = stagePois
        .where((p) => PoiTypeConfig.accommodationTypes.contains(p.type))
        .toList(growable: false);

    final checked = ref.watch(stagePoiChecksProvider);
    final total = water.length + shelters.length;
    final done = [...water, ...shelters]
        .where((p) => checked.contains(p.id))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tete : l'etape concernee + le compteur de points pointes.
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
          ),
          child: Row(
            children: [
              Icon(Icons.checklist, color: theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.a11y.stageMarker(number: stageNumber),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (total > 0)
                Text(
                  // Compteur NEUTRE (« 2 / 5 ») : un libelle chiffre deja
                  // traduit, qui ne prete aucun mot de la checklist materiel.
                  t.journal.dayCounter(index: done, total: total),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // --- Points d'eau de l'etape ---
        _ChecklistGroup(
          icon: Icons.water_drop,
          color: PoiTypeConfig.getStyle('water').color,
          title: t.stage.waterSources.title,
          // Convention du projet : Slang n'interpole pas `{n}`, on remplace en
          // Dart (meme geste que la fiche d'etape).
          countLabel: t.stage.waterSources.count.replaceAll(
            '{n}',
            '${water.length}',
          ),
          emptyLabel: t.stage.waterSources.none,
          pois: water,
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // --- Hebergements de l'etape ---
        _ChecklistGroup(
          icon: Icons.house,
          color: PoiTypeConfig.getStyle('refuge').color,
          title: t.stage.accommodation.title,
          countLabel: null,
          emptyLabel: t.stage.accommodation.none,
          pois: shelters,
        ),
        const SizedBox(height: AppTheme.spacingBase),
      ],
    );
  }
}

/// Un groupe de la liste : titre, compte, puis les points a cocher.
class _ChecklistGroup extends ConsumerWidget {
  const _ChecklistGroup({
    required this.icon,
    required this.color,
    required this.title,
    required this.countLabel,
    required this.emptyLabel,
    required this.pois,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? countLabel;
  final String emptyLabel;
  final List<PoiModel> pois;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final checked = ref.watch(stagePoiChecksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(title, style: theme.textTheme.titleSmall),
              ),
              if (countLabel != null)
                Text(
                  countLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
            ],
          ),
        ),
        if (pois.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingBase,
              AppTheme.spacingSm,
              AppTheme.spacingBase,
              0,
            ),
            child: Text(
              emptyLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final poi in pois)
            CheckboxListTile(
              value: checked.contains(poi.id),
              onChanged: (_) => ref
                  .read(stagePoiChecksProvider.notifier)
                  .toggle(poi.id),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: Text(
                poi.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: checked.contains(poi.id)
                    ? theme.textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : theme.textTheme.bodyMedium,
              ),
              // Sous-titre : le TYPE traduit, et l'altitude quand la donnee
              // existe (un zero en base n'est pas une altitude mesuree).
              subtitle: Text(
                poi.altitudeM > 0
                    ? '${poiTypeLabel(poi.type)} · ${poi.altitudeM} m'
                    : poiTypeLabel(poi.type),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              secondary: Icon(
                PoiTypeConfig.getStyle(poi.type).icon,
                color: color,
              ),
            ),
      ],
    );
  }
}
