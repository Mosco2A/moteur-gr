import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../data/feedback_service.dart';
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
      // Ph5 (L6d) : AppHeader universel. Titre en dur « Feedback » -> Slang
      // (t.feedback.title). Actions (badge « en attente ») conservees.
      appBar: AppHeader(
        title: t.feedback.title,
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
                    '${feedbackState.pendingCount} ${t.feedback.pending}',
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
            // ANNONCE EN TETE D'ECRAN : l'envoi n'est pas ouvert (tache 596).
            // L'utilisateur doit le savoir AVANT d'ecrire, pas apres.
            if (!feedbackState.envoiPossible)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
                child: Text(
                  t.feedback.keptLocallyNotice,
                  style: theme.textTheme.bodySmall,
                ),
              ),

            // Type de feedback
            Text(t.feedback.type, style: theme.textTheme.labelLarge),
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
            Text(t.feedback.message, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: t.feedback.messagePlaceholder,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Note de satisfaction
            Text(t.feedback.satisfaction, style: theme.textTheme.labelLarge),
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
              label: t.feedback.send,
              onPressed: feedbackState.isSubmitting ? null : _submitFeedback,
            ),

            // CE QUI EST REELLEMENT ARRIVE AU MESSAGE (tache 596, C1).
            //
            // L'ecran affichait « Merci pour votre retour ! » des que
            // l'ECRITURE LOCALE avait reussi — pour un message que personne
            // n'allait jamais lire. On ne remercie plus que pour un retour
            // reellement parti ; sinon on dit qu'il est garde ici.
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
            if (feedbackState.derniereIssue == FeedbackIssue.gardeLocalement)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingBase),
                child: Text(
                  t.feedback.keptLocally,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Envoie le retour — ET DIT CE QUI SE PASSE DANS LES TROIS CAS (tache 579).
  ///
  /// DEUX SILENCES SE CUMULAIENT, et « Envoyer » etait mort :
  ///
  ///   * champ vide : `if (content.isEmpty) return;` — la fonction sortait par
  ///     la porte de derriere sans un mot. L'utilisateur appuyait sur un bouton
  ///     ACTIF et il ne se passait rien ; rien ne lui disait que le message
  ///     manquait, puisque le bouton n'avait pas l'air desactive ;
  ///   * envoi echoue : `submitFeedback` rend un booleen qui n'etait jamais lu.
  ///     En cas d'echec l'ecran n'affichait RIEN — le message de remerciement
  ///     n'apparait que sur `lastSubmitSuccess == true`, et rien ne couvrait le
  ///     `false`. Un retour perdu, sans que personne le sache.
  Future<void> _submitFeedback() async {
    final messenger = ScaffoldMessenger.of(context);
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.feedback.emptyMessage)),
      );
      return;
    }

    final issue = await ref.read(feedbackProvider.notifier).submitFeedback(
          type: _selectedType,
          content: content,
          rating: _rating,
        );

    if (!mounted) return;
    if (issue == FeedbackIssue.echec) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.feedback.sendFailed)),
      );
      return;
    }

    _contentController.clear();
    setState(() => _rating = null);
    // TROIS ISSUES, TROIS PHRASES (tache 596, C1). « Merci pour votre retour »
    // est reserve a un message REELLEMENT parti ; garde sur le telephone, on
    // le dit tel quel.
    messenger.showSnackBar(SnackBar(
      content: Text(issue == FeedbackIssue.envoye
          ? t.feedback.sentThanks
          : t.feedback.keptLocally),
    ));
  }
}
