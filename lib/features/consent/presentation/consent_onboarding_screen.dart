import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/consent_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../providers/consent_ui_providers.dart';
import 'consent_purpose_tile.dart';

/// Ecran de consentement affiche au PREMIER LANCEMENT (D4A-02, design #86166).
///
/// Conformite CNIL / RGPD :
///   - chaque FINALITE est presentee separement (navigation, partage social,
///     signalement public, donnees sante) avec une explication claire ;
///   - AUCUNE case n'est pre-cochee : l'utilisateur pose un acte positif
///     clair pour chaque finalite (opt-in reel) ;
///   - la finalite SANTE (art 9) est isolee dans une section dediee, avec un
///     avertissement renforce (donnee sensible) ;
///   - un lien renvoie vers la politique de confidentialite (D4D-01).
///
/// Aucune finalite n'est groupee : accorder l'une n'accorde jamais une autre.
/// L'etat est persiste par le [ConsentService] (D4A-01) via le controleur.
/// a11y : libelles Semantics sur chaque bascule et sur le lien politique.
class ConsentOnboardingScreen extends ConsumerWidget {
  const ConsentOnboardingScreen({
    required this.onContinue,
    this.onOpenPrivacyPolicy,
    super.key,
  });

  /// Appele quand l'utilisateur a fait ses choix et valide.
  final VoidCallback onContinue;

  /// Ouvre la politique de confidentialite (injecte pour testabilite).
  final VoidCallback? onOpenPrivacyPolicy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Translations.of(context);
    final theme = Theme.of(context);
    final statesAsync = ref.watch(consentStatesProvider);
    final controller = ref.read(consentControllerProvider);

    // Finalites standard (hors sante, presentee a part en section renforcee).
    const standardPurposes = <ConsentPurpose>[
      ConsentPurpose.locationNavigation,
      ConsentPurpose.socialSharing,
      ConsentPurpose.publicReporting,
    ];

    return Scaffold(
      body: SafeArea(
        child: statesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (states) => ListView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            children: [
              const SizedBox(height: AppTheme.spacingLg),
              Icon(
                Icons.privacy_tip_outlined,
                size: 56,
                color: theme.colorScheme.primary.withAlpha(180),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                tr.consent.onboardingTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                tr.consent.onboardingIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grisGranite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // --- Finalites standard, chacune en opt-in explicite ---
              for (final purpose in standardPurposes)
                ConsentPurposeTile(
                  purpose: purpose,
                  granted: states[purpose]?.granted ?? false,
                  onChanged: (value) =>
                      controller.set(purpose, granted: value),
                ),

              const SizedBox(height: AppTheme.spacingLg),

              // --- Section SANTE isolee (art 9), avertissement renforce ---
              _HealthSection(
                granted: states[ConsentPurpose.healthData]?.granted ?? false,
                onChanged: (value) => controller.set(
                  ConsentPurpose.healthData,
                  granted: value,
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

              const SizedBox(height: AppTheme.spacingMd),

              // --- Validation des choix ---
              FilledButton(
                onPressed: onContinue,
                child: Text(tr.consent.acceptSelected),
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section dediee a la finalite SANTE (art 9 RGPD), visuellement isolee.
///
/// Affiche un badge "donnee sensible" et un avertissement renforce, puis la
/// bascule de consentement (toujours en opt-in, jamais pre-cochee). Le fait
/// d'etre dans une section a part materialise l'exigence de consentement
/// SEPARE (jamais groupe avec les autres finalites).
class _HealthSection extends StatelessWidget {
  const _HealthSection({required this.granted, required this.onChanged});

  final bool granted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: tr.consent.a11y.healthSection,
      child: Card(
        color: theme.colorScheme.errorContainer.withAlpha(40),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
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
                    backgroundColor: theme.colorScheme.error.withAlpha(30),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                tr.consent.healthWarning,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ConsentPurposeTile(
                purpose: ConsentPurpose.healthData,
                granted: granted,
                onChanged: onChanged,
                hideDescription: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
