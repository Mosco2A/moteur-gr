import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../providers/checklist_provider.dart';

/// Nom affiche d'un article (custom -> customName, sinon i18n du template).
String checklistItemDisplayName(ChecklistItemState item) {
  if (item.isCustom) return item.customName ?? item.template.nameKey;
  final resolved = t['checklist.items.${item.template.nameKey}'];
  return resolved is String ? resolved : item.template.nameKey;
}

/// Modal « Liste de courses » — CLONE GR20 (_ShoppingListModal).
///
/// Deux sections : « A acheter » et « Deja achete » (barre/grise). Cocher un
/// article dans « A acheter » le marque achete ET le coche dans le sac (sync
/// gear provider, parite GR20). Bouton « Partager ».
class ChecklistShoppingModal extends ConsumerStatefulWidget {
  const ChecklistShoppingModal({super.key, required this.uncheckedByCategory});

  /// Articles ajoutes a la liste de courses, groupes par nom de categorie.
  final Map<String, List<ChecklistItemState>> uncheckedByCategory;

  @override
  ConsumerState<ChecklistShoppingModal> createState() =>
      _ChecklistShoppingModalState();
}

class _ChecklistShoppingModalState
    extends ConsumerState<ChecklistShoppingModal> {
  final Set<String> _purchasedIds = {};

  void _shareList() {
    final buffer = StringBuffer('${t.checklist.ui.shoppingListTitle}\n\n');
    for (final entry in widget.uncheckedByCategory.entries) {
      final remaining = entry.value
          .where((i) => !_purchasedIds.contains(i.template.id))
          .toList();
      if (remaining.isEmpty) continue;
      buffer.writeln('${entry.key} :');
      for (final item in remaining) {
        final name = checklistItemDisplayName(item);
        buffer.writeln(item.quantity > 1
            ? '  - $name (x${item.quantity})'
            : '  - $name');
      }
      buffer.writeln('');
    }
    Share.share(buffer.toString());
  }

  void _togglePurchased(ChecklistItemState item, bool? val) {
    setState(() {
      if (val == true) {
        _purchasedIds.add(item.template.id);
        // Parite GR20 : cocher aussi l'article dans le sac.
        if (!item.isChecked) {
          ref.read(checklistProvider.notifier).toggle(item.template.id);
        }
      } else {
        _purchasedIds.remove(item.template.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ui = t.checklist.ui;

    final toBuy = <String, List<ChecklistItemState>>{};
    final purchased = <String, List<ChecklistItemState>>{};
    for (final entry in widget.uncheckedByCategory.entries) {
      final catToBuy = <ChecklistItemState>[];
      final catPurchased = <ChecklistItemState>[];
      for (final item in entry.value) {
        if (_purchasedIds.contains(item.template.id)) {
          catPurchased.add(item);
        } else {
          catToBuy.add(item);
        }
      }
      if (catToBuy.isNotEmpty) toBuy[entry.key] = catToBuy;
      if (catPurchased.isNotEmpty) purchased[entry.key] = catPurchased;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grisGranite.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase,
                vertical: AppTheme.spacingSm,
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart, color: theme.colorScheme.primary),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(ui.shoppingListTitle, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingBase,
                  vertical: AppTheme.spacingSm,
                ),
                children: [
                  ...toBuy.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppTheme.spacingSm,
                            bottom: AppTheme.spacingXs,
                          ),
                          child: Text(
                            entry.key,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        ...entry.value.map((item) {
                          final name = checklistItemDisplayName(item);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: false,
                            onChanged: (val) => _togglePurchased(item, val),
                            title: Text(
                              item.quantity > 1
                                  ? '$name (x${item.quantity})'
                                  : name,
                              style: theme.textTheme.bodyMedium,
                            ),
                            activeColor: AppTheme.vertFacile,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }),
                      ],
                    );
                  }),
                  if (purchased.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppTheme.spacingMd,
                        bottom: AppTheme.spacingXs,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 18, color: AppTheme.vertFacile),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(
                            ui.shoppingPurchased,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.grisGranite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...purchased.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppTheme.spacingSm,
                              bottom: AppTheme.spacingXs,
                            ),
                            child: Text(
                              entry.key,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.grisGranite,
                              ),
                            ),
                          ),
                          ...entry.value.map((item) {
                            final name = checklistItemDisplayName(item);
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: true,
                              onChanged: (val) => _togglePurchased(item, val),
                              title: Text(
                                item.quantity > 1
                                    ? '$name (x${item.quantity})'
                                    : name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppTheme.grisGranite,
                                ),
                              ),
                              activeColor: AppTheme.vertFacile,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareList,
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(t.checklist.ui.share),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
