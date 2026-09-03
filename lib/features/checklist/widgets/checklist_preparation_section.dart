import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../providers/checklist_provider.dart';

/// Section « Preparation du sac » — CLONE GR20 (_PreparationSection).
///
/// Liste les articles selectionnes avec une checkbox chacun ; le randonneur
/// coche au fur et a mesure qu'il met l'article dans son sac. Compteur
/// « X / Y items prepares », progression circulaire, message de felicitation
/// quand tout est prepare. Etat de preparation local (session).
class ChecklistPreparationSection extends StatefulWidget {
  const ChecklistPreparationSection({super.key, required this.items});

  /// Etat courant des articles (on prend les coches).
  final List<ChecklistItemState> items;

  @override
  State<ChecklistPreparationSection> createState() =>
      _ChecklistPreparationSectionState();
}

class _ChecklistPreparationSectionState
    extends State<ChecklistPreparationSection> {
  final Set<String> _preparedIds = {};
  bool _isExpanded = false;

  String _name(ChecklistItemState item) {
    if (item.isCustom) return item.customName ?? item.template.nameKey;
    final resolved = t['checklist.items.${item.template.nameKey}'];
    return resolved is String ? resolved : item.template.nameKey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ui = t.checklist.ui;

    final selectedItems =
        widget.items.where((i) => i.isChecked).toList();
    final totalItems = selectedItems.length;
    final preparedCount =
        selectedItems.where((i) => _preparedIds.contains(i.template.id)).length;
    final allPrepared = totalItems > 0 && preparedCount == totalItems;

    if (totalItems == 0) return const SizedBox.shrink();

    final counterLabel = ui.prepCounter
        .replaceAll('{prepared}', '$preparedCount')
        .replaceAll('{total}', '$totalItems');

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      color: allPrepared ? AppTheme.vertFacile.withAlpha(15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: allPrepared
            ? const BorderSide(color: AppTheme.vertFacile, width: 1.5)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Row(
                children: [
                  Icon(
                    Icons.backpack,
                    color: allPrepared
                        ? AppTheme.vertFacile
                        : AppTheme.orangeDifficile,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ui.prepTitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          counterLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: allPrepared
                                ? AppTheme.vertFacile
                                : AppTheme.orangeDifficile,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: totalItems > 0
                              ? preparedCount / totalItems
                              : 0.0,
                          strokeWidth: 4,
                          backgroundColor: AppTheme.grisGranite.withAlpha(40),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            allPrepared
                                ? AppTheme.vertFacile
                                : AppTheme.orangeDifficile,
                          ),
                        ),
                        if (allPrepared)
                          const Icon(Icons.check,
                              size: 20, color: AppTheme.vertFacile),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.grisGranite,
                  ),
                ],
              ),
            ),
          ),
          if (allPrepared)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: AppTheme.vertFacile.withAlpha(20),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusCard),
                  bottomRight: Radius.circular(AppTheme.radiusCard),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      size: 20, color: AppTheme.vertFacile),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    '${ui.prepAllReady} \u{1F3D4}\u{FE0F}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.vertFacile,
                    ),
                  ),
                ],
              ),
            ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.spacingSm,
                right: AppTheme.spacingSm,
                bottom: AppTheme.spacingSm,
              ),
              child: Column(
                children: selectedItems.map((item) {
                  final isPrepared = _preparedIds.contains(item.template.id);
                  final name = _name(item);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isPrepared,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _preparedIds.add(item.template.id);
                              } else {
                                _preparedIds.remove(item.template.id);
                              }
                            });
                          },
                          activeColor: AppTheme.vertFacile,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.quantity > 1
                                ? '$name (x${item.quantity})'
                                : name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: isPrepared
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isPrepared ? AppTheme.grisGranite : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Section « Checklist avant depart » — CLONE GR20 (_PreDepartureChecklist).
///
/// 8 rappels a cocher avant de partir. Etat local (session). Cle i18n
/// checklist.ui.preDep1..preDep8.
class ChecklistPreDepartureSection extends StatefulWidget {
  const ChecklistPreDepartureSection({super.key});

  @override
  State<ChecklistPreDepartureSection> createState() =>
      _ChecklistPreDepartureSectionState();
}

class _ChecklistPreDepartureSectionState
    extends State<ChecklistPreDepartureSection> {
  final Map<int, bool> _checked = {};

  List<String> get _items {
    final ui = t.checklist.ui;
    return [
      ui.preDep1,
      ui.preDep2,
      ui.preDep3,
      ui.preDep4,
      ui.preDep5,
      ui.preDep6,
      ui.preDep7,
      ui.preDep8,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ui = t.checklist.ui;
    final items = _items;
    final allChecked = _checked.length == items.length &&
        _checked.values.every((v) => v);
    final counterLabel = ui.preDepartureCounter
        .replaceAll('{checked}', '${_checked.values.where((v) => v).length}')
        .replaceAll('{total}', '${items.length}');

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: ExpansionTile(
        leading: Icon(
          allChecked ? Icons.check_circle : Icons.playlist_add_check,
          color: allChecked ? AppTheme.vertFacile : AppTheme.orangeDifficile,
          size: 22,
        ),
        title: Text(
          ui.preDepartureTitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(counterLabel, style: theme.textTheme.bodySmall),
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.only(
          left: AppTheme.spacingSm,
          right: AppTheme.spacingSm,
          bottom: AppTheme.spacingSm,
        ),
        children: List.generate(items.length, (index) {
          final isChecked = _checked[index] ?? false;
          return CheckboxListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            value: isChecked,
            onChanged: (val) =>
                setState(() => _checked[index] = val ?? false),
            title: Text(
              items[index],
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: isChecked ? TextDecoration.lineThrough : null,
                color: isChecked ? AppTheme.grisGranite : null,
              ),
            ),
            activeColor: AppTheme.vertFacile,
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
      ),
    );
  }
}
