import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/consent_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../providers/consent_ui_providers.dart';
import 'consent_purpose_tile.dart';

/// Ecran de gestion du consentement dans les REGLAGES (D4A-02, design #86166).
///
/// Permet de consulter, modifier et RETIRER chaque consentement a tout moment
/// (RGPD : retrait aussi simple que l'octroi). Chaque finalite est independante
/// (granularite) ; la finalite SANTE (art 9) est isolee dans une section
/// dediee avec avertissement renforce. Une banniere invite a revoir les choix
/// si la politique a evolue. Lien vers la politique de confidentialite
/// (D4D-01). a11y via [Semantics] (delegue a [ConsentPurposeTile]).
class ConsentSettingsScreen extends ConsumerWidget {
  const ConsentSettingsScreen({this.onOpenPrivacyPolicy, super.key});

  /// Ouvre la politique de confidentialite (injecte pour testabilite).
  final VoidCallback? onOpenPrivacyPolicy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Translations.of(context);
    final theme = Theme.of(context);
    final statesAsync = ref.watch(consentStatesProvider);
    final reviewNeededAsync = ref.watch(consentPromptNeededProvider);
    final controller = ref.read(consentControllerProvider);

    const standardPurposes = <ConsentPurpose>[
      ConsentPurpose.locationNavigation,
      ConsentPurpose.socialSharing,
      ConsentPurpose.publicReporting,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tr.consent.settingsTitle)),
      body: SafeArea(
        child: statesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (states) => ListView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            children: [
              // Banniere : la politique a evolue, revoir les choix.
              if (reviewNeededAsync.value == true)
                Card(
                  color: theme.colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.update),
                    title: Text(tr.consent.reviewNeeded),
                  ),
                ),
              Text(
                tr.consent.settingsIntro,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // --- Finalites standard ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                  ),
                  child: Column(
                    children: [
                      for (final purpose in standardPurposes) ...[
                        ConsentPurposeTile(
                          purpose: purpose,
                          granted: states[purpose]?.granted ?? false,
                          onChanged: (value) =>
                              controller.set(purpose, granted: value),
                        ),
                        _DecisionDate(state: states[purpose]),
                        if (purpose != standardPurposes.last)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // --- Section SANTE isolee (art 9) ---
              Card(
                color: theme.colorScheme.errorContainer.withAlpha(40),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Semantics(
                    container: true,
                    label: tr.consent.a11y.healthSection,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_outline,
                              size: 20,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Text(
                                tr.consent.purposes.healthData,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Chip(
                              label: Text(tr.consent.healthBadge),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          tr.consent.healthWarning,
                          style: theme.textTheme.bodySmall,
                        ),
                        ConsentPurposeTile(
                          purpose: ConsentPurpose.healthData,
                          granted: states[ConsentPurpose.healthData]?.granted ??
                              false,
                          onChanged: (value) => controller.set(
                            ConsentPurpose.healthData,
                            granted: value,
                          ),
                          hideDescription: true,
                        ),
                        _DecisionDate(
                          state: states[ConsentPurpose.healthData],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // --- Lien politique de confidentialite ---
              Semantics(
                button: true,
                label: tr.consent.a11y.policyButton,
                child: TextButton.icon(
                  onPressed: onOpenPrivacyPolicy,
                  icon: const Icon(Icons.description_outlined),
                  label: Text(tr.consent.privacyPolicyLink),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Affiche la date de derniere decision (ou "en attente" si jamais decide).
class _DecisionDate extends StatelessWidget {
  const _DecisionDate({required this.state});

  final ConsentState? state;

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final theme = Theme.of(context);
    final decidedAt = state?.decidedAt;

    final label = decidedAt == null
        ? tr.consent.notDecided
        : tr.consent.decidedOn(
            date: '${decidedAt.day.toString().padLeft(2, '0')}/'
                '${decidedAt.month.toString().padLeft(2, '0')}/'
                '${decidedAt.year}',
          );

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisGranite,
          ),
        ),
      ),
    );
  }
}
