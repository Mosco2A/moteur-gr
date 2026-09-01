import 'package:flutter/material.dart';

import '../../../core/services/moderation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../i18n/translations.g.dart';
import 'complaint_screen.dart';

/// Vue d'un EXPOSE DES MOTIFS (DSA art 17), immuable.
///
/// Forme d'affichage de l'enregistrement moderation_decisions (cree par le
/// workflow D4C-02 a destination de l'auteur du contenu restreint). Aucune PII
/// directe (l'auteur est identifie par UID hache cote backend). Les widgets ne
/// font AUCUNE lecture serveur : ce modele leur est fourni.
class StatementOfReasonsView {
  const StatementOfReasonsView({
    required this.contentType,
    required this.contentRef,
    required this.decision,
    required this.motif,
    required this.createdAt,
  });

  /// Type du contenu concerne.
  final ModeratedContentType contentType;

  /// Reference du contenu concerne.
  final String contentRef;

  /// Decision de moderation rendue (keep/restrict/remove).
  final ModerationDecision decision;

  /// Motif communique a l'auteur (art 17).
  final String motif;

  /// Date de la decision.
  final DateTime createdAt;
}

/// Ecran EXPOSE DES MOTIFS — DSA art 17 (D4C-03, design #86166).
///
/// Montre a l'AUTEUR d'un contenu restreint/retire la RAISON de la decision de
/// moderation. Si l'auteur conteste, un bouton ouvre l'ecran de plaintes (art
/// 20, [ComplaintScreen]). Si aucune restriction n'existe, un message neutre
/// l'indique. Textes Slang 5 langues, a11y via [Semantics]. Aucune logique
/// serveur : la [statement] est fournie (lue en amont selon les regles D4C-02).
class StatementOfReasonsScreen extends StatelessWidget {
  const StatementOfReasonsScreen({this.statement, super.key});

  /// Expose des motifs a afficher, ou null si aucun (rien n'a ete restreint).
  final StatementOfReasonsView? statement;

  /// Libelle localise d'une decision de moderation.
  String _decisionLabel(Translations tr, ModerationDecision decision) =>
      switch (decision) {
        ModerationDecision.keep => tr.moderation.decisions.keep,
        ModerationDecision.restrict => tr.moderation.decisions.restrict,
        ModerationDecision.remove => tr.moderation.decisions.remove,
      };

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final theme = Theme.of(context);
    final st = statement;

    return Scaffold(
      appBar: AppBar(title: Text(tr.moderation.reasonsTitle)),
      body: SafeArea(
        child: st == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Text(
                    tr.moderation.noStatement,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                children: [
                  Text(
                    tr.moderation.reasonsIntro,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Semantics(
                    container: true,
                    label: tr.moderation.a11y.statementCard,
                    // SW-SKIN-L3e : Card -> AppCard, padding md porte par
                    // AppCard (iso-rendu). Semantics(container) conservee.
                    child: AppCard(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.gavel_outlined,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Text(
                                tr.moderation.decisionLabel,
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            _decisionLabel(tr, st.decision),
                            style: theme.textTheme.titleMedium,
                          ),
                          const Divider(height: AppTheme.spacingLg),
                          Text(st.motif, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // --- Acces aux plaintes (art 20) ---
                  Semantics(
                    button: true,
                    // SW-SKIN-L3e : OutlinedButton.icon -> AppButton outline,
                    // pleine largeur (enfant de ListView). key/Semantics gardees.
                    child: AppButton(
                      key: const ValueKey('statement-complaint-action'),
                      variant: AppButtonVariant.outline,
                      icon: Icons.balance_outlined,
                      label: tr.moderation.complaintAction,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ComplaintScreen(
                            contentType: st.contentType,
                            contentRef: st.contentRef,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
