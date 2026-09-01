import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/moderation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../i18n/translations.g.dart';
import '../providers/moderation_ui_providers.dart';

/// Ecran PLAINTES — DSA art 20 (D4C-03, design #86166).
///
/// Systeme interne de traitement des plaintes : l'utilisateur peut CONTESTER
/// une decision de moderation le concernant en exposant ses arguments. La
/// plainte est enregistree (collection moderation_complaints, regles D4C-02) au
/// statut 'ouverte' et sera examinee par un moderateur. Textes Slang 5 langues,
/// a11y via [Semantics]. Aucune logique serveur dans le widget : l'envoi passe
/// par [ModerationComplaintController].
class ComplaintScreen extends ConsumerStatefulWidget {
  const ComplaintScreen({
    required this.contentType,
    required this.contentRef,
    super.key,
  });

  /// Type du contenu vise par la decision contestee.
  final ModeratedContentType contentType;

  /// Reference du contenu vise par la decision contestee.
  final String contentRef;

  @override
  ConsumerState<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends ConsumerState<ComplaintScreen> {
  final TextEditingController _expose = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _expose.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final tr = Translations.of(context);
    if (_expose.text.trim().isEmpty) {
      setState(() => _error = tr.moderation.complaintEmpty);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(moderationComplaintControllerProvider)
          .submit(
            contentType: widget.contentType,
            contentRef: widget.contentRef,
            expose: _expose.text,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(tr.moderation.complaintSent)),
      );
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = tr.moderation.errorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr.moderation.complaintTitle)),
      body: SafeArea(
        child: Semantics(
          container: true,
          label: tr.moderation.a11y.complaintForm,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            children: [
              Text(
                tr.moderation.complaintIntro,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              TextField(
                key: const ValueKey('complaint-expose'),
                controller: _expose,
                enabled: !_submitting,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: tr.moderation.complaintExposeLabel,
                  hintText: tr.moderation.complaintExposeHint,
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingLg),
              Semantics(
                button: true,
                // SW-SKIN-L3e : FilledButton -> AppButton primary (arbitrage
                // #A5), pleine largeur (enfant de ListView). Le libelle bascule
                // toujours submitting/submit selon l'etat (iso-comportement) ;
                // onPressed nul pendant l'envoi. key/Semantics preserves.
                child: AppButton(
                  key: const ValueKey('complaint-submit'),
                  label: _submitting
                      ? tr.moderation.submitting
                      : tr.moderation.complaintSubmit,
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
