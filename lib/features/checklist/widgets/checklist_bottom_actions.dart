import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../data/checklist_template.dart';
import '../providers/checklist_provider.dart';
import 'checklist_shopping_modal.dart';

/// Boutons en bas de la checklist — CLONE GR20 (_BottomActions).
///
/// « SAC OK / VALIDER MON SAC » (verifie les obligatoires + confirmation),
/// « ANNULER LA VALIDATION » (si sac deja valide), « LISTE D'ACHAT »,
/// « PARTAGER AVEC LE GROUPE », « EXPORTER LA LISTE ».
class ChecklistBottomActions extends ConsumerWidget {
  const ChecklistBottomActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = t.checklist.ui;
    final state = ref.watch(checklistProvider);
    final allRequiredChecked = state.allRequiredChecked;
    final isValidated = state.bagValidated;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppTheme.spacingXl,
        top: AppTheme.spacingSm,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showBagOkDialog(
                context,
                ref,
                allRequiredChecked,
                state.requiredCount,
                state.requiredCheckedCount,
              ),
              icon: Icon(
                allRequiredChecked ? Icons.check_circle : Icons.warning_amber,
                size: 20,
              ),
              label: Text(allRequiredChecked ? ui.bagOk : ui.validateBag),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    allRequiredChecked ? AppTheme.vertFacile : AppTheme.orangeDifficile,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (isValidated) ...[
            const SizedBox(height: AppTheme.spacingSm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(checklistProvider.notifier).cancelValidation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ui.validationCancelledSnack),
                      backgroundColor: AppTheme.orangeDifficile,
                    ),
                  );
                },
                icon: const Icon(Icons.undo, size: 18),
                label: Text(ui.cancelValidation),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.orangeDifficile,
                  side: const BorderSide(
                      color: AppTheme.orangeDifficile, width: 2),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openShoppingList(context, ref),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: Text(ui.shoppingListButton),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareChecklist(context, ref),
              icon: const Icon(Icons.group, size: 18),
              label: Text(ui.shareGroup),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareChecklist(context, ref),
              icon: const Icon(Icons.share, size: 18),
              label: Text(ui.exportList),
            ),
          ),
        ],
      ),
    );
  }

  void _openShoppingList(BuildContext context, WidgetRef ref) {
    final state = ref.read(checklistProvider);
    final byCategory = <String, List<ChecklistItemState>>{};
    for (final item in state.items.where((i) => i.inShoppingList)) {
      final catName = _resolveCategoryName(item.template.category);
      byCategory.putIfAbsent(catName, () => []).add(item);
    }
    if (byCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.checklist.ui.shoppingListEmpty)),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) =>
          ChecklistShoppingModal(uncheckedByCategory: byCategory),
    );
  }

  /// Dialog « SAC OK » avec verification des obligatoires (parite GR20).
  void _showBagOkDialog(
    BuildContext context,
    WidgetRef ref,
    bool allOk,
    int total,
    int checked,
  ) {
    final ui = t.checklist.ui;
    final state = ref.read(checklistProvider);

    if (allOk) {
      final body = ui.bagValidBody
          .replaceAll('{total}', '$total')
          .replaceAll('{weight}', state.checkedWeightKg.toStringAsFixed(1))
          .replaceAll('{pct}', (state.backpackRatio * 100).toStringAsFixed(0));
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.vertFacile),
              const SizedBox(width: 8),
              Text(ui.bagValidTitle),
            ],
          ),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ui.checkAgain),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(checklistProvider.notifier).validateBag();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ui.bagValidatedSnack),
                    backgroundColor: AppTheme.vertFacile,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vertFacile,
                foregroundColor: Colors.white,
              ),
              child: Text(ui.yesBagOk),
            ),
          ],
        ),
      );
    } else {
      final missing = <String>[];
      for (final item in state.items) {
        if (item.template.requirement == ChecklistRequirement.required &&
            !item.isChecked) {
          missing.add(checklistItemDisplayName(item));
        }
      }
      final body = ui.missingBody
          .replaceAll('{checked}', '$checked')
          .replaceAll('{total}', '$total');
      showDialog<void>(
        context: context,
        builder: (ctx) {
          final dialogWidth = MediaQuery.of(context).size.width * 0.85;
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: dialogWidth,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: AppTheme.orangeDifficile),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(ui.missingTitle,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$body\n'),
                              Text(ui.missingList,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              ...missing.map((m) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.close,
                                            size: 14,
                                            color: AppTheme.rougeUrgence),
                                        const SizedBox(width: 4),
                                        Flexible(
                                            child: Text(m,
                                                style: const TextStyle(
                                                    fontSize: 16))),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(ui.understood),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ref
                                  .read(checklistProvider.notifier)
                                  .validateBag();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ui.bagValidatedMissingSnack),
                                  backgroundColor: AppTheme.orangeDifficile,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orangeDifficile,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(ui.validateAnyway),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  /// Partage texte de la checklist (parite GR20 : partage + export = meme
  /// action). Construit un recap des articles coches par categorie.
  void _shareChecklist(BuildContext context, WidgetRef ref) {
    final state = ref.read(checklistProvider);
    final buffer = StringBuffer('${t.checklist.title}\n');
    buffer.writeln(
        '${t.checklist.weight.total} : ${state.checkedWeightKg.toStringAsFixed(1)} ${t.checklist.weight.kilograms}');
    buffer.writeln(
        '${(state.backpackRatio * 100).toStringAsFixed(0)}%\n');

    // Grouper par categorie (ordre du template).
    for (final category in checklistCategories) {
      final checkedItems = state.items
          .where((i) => i.template.category == category && i.isChecked)
          .toList();
      if (checkedItems.isEmpty) continue;
      buffer.writeln('--- ${_resolveCategoryName(category)} ---');
      for (final item in checkedItems) {
        final name = checklistItemDisplayName(item);
        buffer.writeln(item.quantity > 1
            ? '  [x] $name x${item.quantity} (${item.totalWeightGrams}${t.checklist.weight.grams})'
            : '  [x] $name (${item.weightGrams}${t.checklist.weight.grams})');
      }
      buffer.writeln('');
    }
    Share.share(buffer.toString());
  }

  String _resolveCategoryName(String categoryKey) {
    final resolved = t['checklist.categories.$categoryKey'];
    return resolved is String ? resolved : categoryKey;
  }
}
