import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../i18n/translations.g.dart';
import '../data/checklist_template.dart';
import '../providers/checklist_provider.dart';
import '../widgets/checklist_category_section.dart';
import '../widgets/checklist_progress_header.dart';

/// Ecran principal de la checklist materiel (E3.2b).
///
/// Affiche la progression globale en en-tete,
/// puis les items groupes par categorie avec checkboxes.
/// Bouton reset dans l AppBar.
/// Tout texte via Slang (t.checklist.*) — zero texte en dur.
/// Riverpod 3 avec select() dans build.
class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select() pour ne reconstruire que si isLoading change
    final isLoading = ref.watch(checklistProvider.select((s) => s.isLoading));

    final checklistT = t.checklist;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(checklistT.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // select() pour les compteurs de progression
    final checkedCount = ref.watch(
      checklistProvider.select((s) => s.checkedCount),
    );
    final totalCount = ref.watch(checklistProvider.select((s) => s.totalCount));

    // select() pour la liste d items (reconstruire uniquement si items changent)
    final items = ref.watch(checklistProvider.select((s) => s.items));

    // Construction du label de progression via Slang
    // Le template Slang contient "{checked}/{total} prepares"
    // On remplace les placeholders manuellement
    final progressLabel = checklistT.progress
        .replaceAll('{checked}', checkedCount.toString())
        .replaceAll('{total}', totalCount.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text(checklistT.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: checklistT.reset,
            onPressed: () => _showResetDialog(context, ref, checklistT),
          ),
        ],
      ),
      body: ListView(
        children: [
          // En-tete progression
          ChecklistProgressHeader(
            checkedCount: checkedCount,
            totalCount: totalCount,
            progressLabel: progressLabel,
            completeLabel: checklistT.complete,
          ),
          const Divider(height: 1),
          // Categories — chaque section utilise Slang pour le nom
          for (final category in checklistCategories)
            ChecklistCategorySection(
              categoryName: _resolveCategoryName(category),
              items: items
                  .where((i) => i.template.category == category)
                  .toList(),
              onToggle: (itemId) {
                ref.read(checklistProvider.notifier).toggle(itemId);
              },
            ),
          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  /// Resout le nom de categorie via Slang (lookup dynamique).
  /// Retourne la cle brute si aucune traduction trouvee.
  String _resolveCategoryName(String categoryKey) {
    final resolved = t['checklist.categories.$categoryKey'];
    if (resolved is String) return resolved;
    return categoryKey;
  }

  /// Dialogue de confirmation de reset — tout via Slang.
  void _showResetDialog(
    BuildContext context,
    WidgetRef ref,
    Translations$checklist$fr checklistT,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(checklistT.resetConfirm),
        content: Text(checklistT.resetDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(checklistT.cancel),
          ),
          // SW-SKIN-L3e : ElevatedButton -> AppButton primary, isFullWidth:false
          // (action de dialogue, aux cotes du TextButton Annuler laisse tel quel).
          AppButton(
            isFullWidth: false,
            label: checklistT.confirm,
            onPressed: () {
              ref.read(checklistProvider.notifier).resetAll();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
