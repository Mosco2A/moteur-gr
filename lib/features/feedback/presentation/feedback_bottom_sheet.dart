import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../providers/feedback_provider.dart';

/// Bottom sheet de feedback accessible partout dans l app.
///
/// Formulaire avec : categorie (chips bug/suggestion/compliment),
/// message texte, note 1-5 (etoiles). Utilise les textes Slang.
/// Stocke via FeedbackNotifier (offline-first).
class FeedbackBottomSheet extends ConsumerStatefulWidget {
  const FeedbackBottomSheet({super.key});

  /// Affiche le bottom sheet de feedback depuis n importe quel ecran.
  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusBottomSheet),
        ),
      ),
      builder: (_) => const FeedbackBottomSheet(),
    );
  }

  @override
  ConsumerState<FeedbackBottomSheet> createState() =>
      _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends ConsumerState<FeedbackBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  /// Categorie selectionnee (bug, suggestion, compliment).
  /// Par defaut suggestion — le cas le plus courant.
  FeedbackType _selectedCategory = FeedbackTypeValues.suggestion;

  /// Note de satisfaction 1-5, null si pas encore choisie.
  int? _rating;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final feedbackState = ref.watch(feedbackProvider);

    // Padding pour le clavier virtuel
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poignee visuelle du bottom sheet
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingBase),
                    decoration: BoxDecoration(
                      color: AppTheme.grisClair,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Titre
                Text(
                  t.feedback.title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Categorie — 3 ChoiceChips (bug, suggestion, compliment)
                Text(t.feedback.type, style: theme.textTheme.labelLarge),
                const SizedBox(height: AppTheme.spacingSm),
                Wrap(
                  spacing: AppTheme.spacingSm,
                  children: [
                    _buildCategoryChip(FeedbackTypeValues.bug, t.feedback.bug, Icons.bug_report),
                    _buildCategoryChip(FeedbackTypeValues.suggestion, t.feedback.suggestion, Icons.lightbulb_outline),
                    _buildCategoryChip(FeedbackTypeValues.compliment, t.feedback.compliment, Icons.thumb_up_outlined),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Message texte
                Text(t.feedback.message, style: theme.textTheme.labelLarge),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: t.feedback.messagePlaceholder,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t.feedback.message;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Note de satisfaction 1-5 (etoiles)
                Text(t.feedback.satisfaction, style: theme.textTheme.labelLarge),
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      icon: Icon(
                        starValue <= (_rating ?? 0)
                            ? Icons.star
                            : Icons.star_border,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      onPressed: () => setState(() => _rating = starValue),
                    );
                  }),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Bouton envoyer
                ElevatedButton.icon(
                  onPressed: feedbackState.isSubmitting ? null : _submit,
                  icon: feedbackState.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    feedbackState.isSubmitting
                        ? t.feedback.sending
                        : t.feedback.send,
                  ),
                ),

                // Message de confirmation apres envoi reussi
                if (feedbackState.lastSubmitSuccess == true)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingBase),
                    child: Text(
                      t.feedback.thanks,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.vertFacile,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: AppTheme.spacingSm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construit un ChoiceChip pour une categorie de feedback.
  Widget _buildCategoryChip(String category, String label, IconData icon) {
    final selected = category == _selectedCategory;
    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedCategory = category),
    );
  }

  /// Valide le formulaire et soumet le feedback via le provider.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(feedbackProvider.notifier).submitFeedback(
          type: _selectedCategory,
          content: _contentController.text.trim(),
          rating: _rating,
        );

    _contentController.clear();
    setState(() {
      _rating = null;
      _selectedCategory = FeedbackTypeValues.suggestion;
    });
  }
}
