import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/moderation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../i18n/translations.g.dart';
import '../providers/moderation_ui_providers.dart';

/// Formulaire « Signaler » — notice-and-action DSA art 16 (D4C-03, design
/// #86166). Ouvert par les boutons « Signaler » des features communautaires
/// (F6C-03 signalement, F7B-04 fil, F8A-04 waypoints) via [showReportSheet].
///
/// L'utilisateur choisit un MOTIF (liste fermee guidee), ajoute un detail
/// facultatif, renseigne son adresse e-mail (pour le suivi, art 16) et DECLARE
/// LA BONNE FOI (case a cocher, art 16) avant d'envoyer. La validation finale
/// (mentions obligatoires) est portee par le [ModerationService] (D4C-01) :
/// l'UI affiche l'erreur remontee sans la masquer. a11y via [Semantics].
///
/// Aucune logique serveur ici : l'envoi passe par
/// [ModerationReportController] -> [ModerationService] -> store (D4C-02).
class ReportContentSheet extends ConsumerStatefulWidget {
  const ReportContentSheet({
    required this.contentType,
    required this.contentRef,
    super.key,
  });

  /// Type du contenu signale (determine la collection cible).
  final ModeratedContentType contentType;

  /// Reference du contenu signale (doc id dans sa collection).
  final String contentRef;

  @override
  ConsumerState<ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends ConsumerState<ReportContentSheet> {
  ReportReason _reason = ReportReason.illegal;
  final TextEditingController _details = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  bool _goodFaith = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    _contact.dispose();
    super.dispose();
  }

  /// Libelle localise d'un motif de signalement.
  String _reasonLabel(Translations tr, ReportReason reason) => switch (reason) {
    ReportReason.illegal => tr.moderation.reasons.illegal,
    ReportReason.harassment => tr.moderation.reasons.harassment,
    ReportReason.spam => tr.moderation.reasons.spam,
    ReportReason.dangerous => tr.moderation.reasons.dangerous,
    ReportReason.other => tr.moderation.reasons.other,
  };

  Future<void> _submit() async {
    final tr = Translations.of(context);
    // Garde-fou UI immediat (le service re-valide aussi, art 16).
    if (!_goodFaith || _contact.text.trim().isEmpty) {
      setState(() => _error = tr.moderation.errorRequired);
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
          .read(moderationReportControllerProvider)
          .submit(
            contentType: widget.contentType,
            contentRef: widget.contentRef,
            reasonLabel: _reasonLabel(tr, _reason),
            details: _details.text,
            contact: _contact.text,
            goodFaith: _goodFaith,
          );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(tr.moderation.sent)));
      navigator.pop(true);
    } on InvalidModerationReport {
      // Mention obligatoire manquante (art 16) — on affiche, on ne masque pas.
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = tr.moderation.errorRequired;
      });
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

    return Semantics(
      container: true,
      label: tr.moderation.a11y.reportForm,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spacingBase,
          right: AppTheme.spacingBase,
          top: AppTheme.spacingLg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.moderation.reportTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                tr.moderation.reportIntro,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // --- Motif (art 16) ---
              Text(
                tr.moderation.reasonLabel,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Semantics(
                label: tr.moderation.a11y.reasonSelector,
                child: RadioGroup<ReportReason>(
                  groupValue: _reason,
                  onChanged: (value) {
                    if (_submitting || value == null) return;
                    setState(() => _reason = value);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final reason in ReportReason.values)
                        RadioListTile<ReportReason>(
                          key: ValueKey('report-reason-${reason.storageKey}'),
                          value: reason,
                          title: Text(_reasonLabel(tr, reason)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // --- Detail libre (facultatif) ---
              TextField(
                key: const ValueKey('report-details'),
                controller: _details,
                enabled: !_submitting,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: tr.moderation.detailsLabel,
                  hintText: tr.moderation.detailsHint,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // --- Contact notifiant (art 16) ---
              TextField(
                key: const ValueKey('report-contact'),
                controller: _contact,
                enabled: !_submitting,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: tr.moderation.contactLabel,
                  hintText: tr.moderation.contactHint,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),

              // --- Declaration de bonne foi (art 16) ---
              Semantics(
                checked: _goodFaith,
                label: tr.moderation.a11y.goodFaithToggle(
                  state: _goodFaith
                      ? MaterialLocalizations.of(context).okButtonLabel
                      : '',
                ),
                child: CheckboxListTile(
                  key: const ValueKey('report-good-faith'),
                  value: _goodFaith,
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _goodFaith = value ?? false),
                  title: Text(tr.moderation.goodFaithLabel),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
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

              // --- Actions ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(tr.moderation.cancel),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Semantics(
                    button: true,
                    label: tr.moderation.a11y.submitReport,
                    // SW-SKIN-L3e : FilledButton -> AppButton primary (arbitrage
                    // #A5). isFullWidth:false : action de dialogue alignee a
                    // droite aux cotes du TextButton Annuler (laisse tel quel).
                    // Libelle bascule submitting/submit (iso). key/Semantics gardees.
                    child: AppButton(
                      key: const ValueKey('report-submit'),
                      isFullWidth: false,
                      label: _submitting
                          ? tr.moderation.submitting
                          : tr.moderation.submit,
                      onPressed: _submitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ouvre le formulaire de signalement (art 16) en bottom sheet modal.
///
/// Point d'entree unique pour les boutons « Signaler » des features. Retourne
/// `true` si un signalement a ete envoye, `null`/`false` sinon.
Future<bool?> showReportSheet(
  BuildContext context, {
  required ModeratedContentType contentType,
  required String contentRef,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        ReportContentSheet(contentType: contentType, contentRef: contentRef),
  );
}
