import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../i18n/translations.g.dart';
import '../data/feedback_service.dart';
import '../providers/feedback_provider.dart';
import '../../../core/branding/stepways_icons.dart';

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

                // L'ENVOI N'EST PAS OUVERT — ET ON LE DIT AVANT (tache 596).
                if (!feedbackState.envoiPossible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
                    child: Text(
                      t.feedback.keptLocallyNotice,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Categorie — 3 ChoiceChips (bug, suggestion, compliment)
                Text(t.feedback.type, style: theme.textTheme.labelLarge),
                const SizedBox(height: AppTheme.spacingSm),
                Wrap(
                  spacing: AppTheme.spacingSm,
                  children: [
                    _buildCategoryChip(
                      FeedbackTypeValues.bug,
                      t.feedback.bug,
                      StepwaysIcons.signaler,
                    ),
                    _buildCategoryChip(
                      FeedbackTypeValues.suggestion,
                      t.feedback.suggestion,
                      StepwaysIcons.ficheConseil,
                    ),
                    _buildCategoryChip(
                      FeedbackTypeValues.compliment,
                      t.feedback.compliment,
                      StepwaysIcons.pouce,
                    ),
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
                Text(
                  t.feedback.satisfaction,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      // TACHE 632 — L'ETOILE PLEINE ET L'ETOILE VIDE SONT LE
                      // MEME DESSIN, DISTINGUEES PAR LA COULEUR. Christophe
                      // livre une seule etoile (`note`), pas une paire
                      // pleine/contour comme Material. La note se lit donc au
                      // CONTRASTE : allumee en couleur d'accent, eteinte en gris
                      // efface. C'est ce que fait deja tout le reste de
                      // l'application pour un etat actif/inactif.
                      icon: StepIcon(
                        StepwaysIcons.note,
                        color: starValue <= (_rating ?? 0)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        size: 32,
                      ),
                      onPressed: () => setState(() => _rating = starValue),
                    );
                  }),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Bouton envoyer
                // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary, pleine
                // largeur (theme = minimumSize infinie). isLoading porte l'etat
                // isSubmitting (spinner + desactivation, grammaire unifiee) ;
                // libelle inchange hors envoi.
                AppButton(
                  isLoading: feedbackState.isSubmitting,
                  icon: StepwaysIcons.envoyer,
                  label: t.feedback.send,
                  onPressed: feedbackState.isSubmitting ? null : _submit,
                ),

                // CE QUI EST REELLEMENT ARRIVE AU MESSAGE (tache 596, C1).
                // Le merci ne s'affiche plus que pour un retour vraiment parti.
                if (feedbackState.derniereIssue == FeedbackIssue.envoye)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingBase),
                    child: Text(
                      t.feedback.sentThanks,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.vertFacile,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (feedbackState.derniereIssue ==
                    FeedbackIssue.gardeLocalement)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingBase),
                    child: Text(
                      t.feedback.keptLocally,
                      style: theme.textTheme.bodyMedium,
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
  Widget _buildCategoryChip(String category, String label, String icon) {
    final selected = category == _selectedCategory;
    return ChoiceChip(
      avatar: StepIcon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedCategory = category),
    );
  }

  /// Valide le formulaire et soumet le feedback via le provider.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(feedbackProvider.notifier)
        .submitFeedback(
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
