import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../share/providers/visibility_settings_provider.dart';

/// Ecran de reglage de la VISIBILITE sociale (F7D-02, Phase 7).
///
/// PRIVE PAR DEFAUT : l'utilisateur active explicitement (opt-in), de maniere
/// GRANULAIRE par finalite (resultats d'etape, presence au leaderboard, fil
/// d'activite). Coherent avec la gestion de consentement RGPD du design
/// Securite D4 (granularite par finalite) : un lien renvoie vers la gestion du
/// consentement ([onOpenConsent]).
///
/// a11y via [Semantics], Slang t.shareVisibility.* (aucune cle "anonyme", R1).
class VisibilitySettingsScreen extends ConsumerWidget {
  const VisibilitySettingsScreen({this.onOpenConsent, super.key});

  /// Ouvre la gestion du consentement RGPD (design Securite D4). Injecte pour
  /// le decouplage/testabilite.
  final VoidCallback? onOpenConsent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final settings = ref.watch(visibilitySettingsProvider);
    final notifier = ref.read(visibilitySettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(t.shareVisibility.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          children: [
            Text(t.shareVisibility.intro,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppTheme.spacingMd),
            _VisibilityToggle(
              keyValue: 'toggle-stage-results',
              title: t.shareVisibility.stageResults,
              subtitle: t.shareVisibility.stageResultsDesc,
              value: settings.shareStageResults,
              onChanged: notifier.setShareStageResults,
            ),
            _VisibilityToggle(
              keyValue: 'toggle-leaderboard',
              title: t.shareVisibility.leaderboard,
              subtitle: t.shareVisibility.leaderboardDesc,
              value: settings.shareLeaderboard,
              onChanged: notifier.setShareLeaderboard,
            ),
            _VisibilityToggle(
              keyValue: 'toggle-activity-feed',
              title: t.shareVisibility.activityFeed,
              subtitle: t.shareVisibility.activityFeedDesc,
              value: settings.shareActivityFeed,
              onChanged: notifier.setShareActivityFeed,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            // Lien vers la gestion du consentement RGPD (design Securite D4).
            Semantics(
              button: true,
              label: t.shareVisibility.consentLink,
              child: TextButton.icon(
                onPressed: onOpenConsent,
                icon: const Icon(Icons.privacy_tip_outlined),
                label: Text(t.shareVisibility.consentLink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une bascule de visibilite (opt-in d'une finalite), accessible.
class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.keyValue,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String keyValue;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: title,
      child: SwitchListTile(
        key: ValueKey(keyValue),
        value: value,
        onChanged: onChanged,
        title: Text(title),
        subtitle: Text(subtitle),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
