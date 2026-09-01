import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/feedback_provider.dart';

/// Écran de feedback in-app.
///
/// Formulaire avec type de feedback, contenu, note de satisfaction.
/// Les feedbacks sont stockés localement et envoyés quand en ligne.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _contentController = TextEditingController();
  FeedbackType _selectedType = FeedbackTypeValues.suggestion;
  int? _rating;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackState = ref.watch(feedbackProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        actions: [
          if (feedbackState.pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingBase),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.orangeDifficile.withAlpha(40),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Text(
                    '${feedbackState.pendingCount} en attente',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type de feedback
            Text('Type de retour', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              children: FeedbackTypeValues.values.map((type) {
                final selected = type == _selectedType;
                return ChoiceChip(
                  label: Text(FeedbackTypeValues.labelFor(type)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Contenu
            Text('Votre message', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Décrivez votre retour...',
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Note de satisfaction
            Text('Satisfaction', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  icon: Icon(
                    starIndex <= (_rating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = starIndex),
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
              icon: Icons.send,
              label: 'Envoyer',
              onPressed: feedbackState.isSubmitting ? null : _submitFeedback,
            ),

            // Message de succès/erreur
            if (feedbackState.lastSubmitSuccess == true)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingBase),
                child: Text(
                  'Merci pour votre retour !',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.vertFacile,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _submitFeedback() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    ref
        .read(feedbackProvider.notifier)
        .submitFeedback(type: _selectedType, content: content, rating: _rating);

    _contentController.clear();
    setState(() => _rating = null);
  }
}
