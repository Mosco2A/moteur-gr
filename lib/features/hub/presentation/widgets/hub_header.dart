import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import '../../providers/hub_providers.dart';

/// En-tete du HUB : salutation personnalisee (RF-3).
///
/// LOT-A (D1, arbitrage #94902) : le mode demo est MASQUE en P2-P3. Ce header
/// n'affiche donc NI bandeau demo NI bandeau trek demo — uniquement la
/// salutation. Le prenom vient de [displayNameProvider] (derive du pseudonyme
/// auth, ZERO PII), avec repli localise « Randonneur » (`t.hub.greetingFallback`)
/// quand aucun pseudonyme n'est saisi.
class HubHeader extends ConsumerWidget {
  const HubHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final displayName = ref.watch(displayNameProvider);
    final name = displayName ?? t.hub.greetingFallback;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          t.hub.greeting(name: name),
          style: theme.textTheme.headlineMedium,
        ),
      ),
    );
  }
}
