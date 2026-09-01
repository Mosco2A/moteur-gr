import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_gradient_header.dart';
import '../../providers/hub_providers.dart';

/// En-tete du HUB : salutation personnalisee (RF-3).
///
/// LOT-A (D1, arbitrage #94902) : le mode demo est MASQUE en P2-P3. Ce header
/// n'affiche donc NI bandeau demo NI bandeau trek demo — uniquement la
/// salutation. Le prenom vient de [displayNameProvider] (derive du pseudonyme
/// auth, ZERO PII), avec repli localise « Randonneur » (`t.hub.greetingFallback`)
/// quand aucun pseudonyme n'est saisi.
///
/// SW-SKIN-L5 : la salutation est desormais portee par [AppGradientHeader] —
/// bandeau a degrade d'accent-sentier (peau Sentier Vivant), contraste texte
/// garanti (§1.6). Le nom du sentier ([TrailConfig.displayName]) devient le
/// sous-titre (la couleur-sentier est le heros graphique de la Direction C). La
/// famille et le traitement basculent automatiquement avec la peau (filet topo
/// en L8, photo en L9) sans toucher cet ecran.
class HubHeader extends ConsumerWidget {
  const HubHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(displayNameProvider);
    final name = displayName ?? t.hub.greetingFallback;
    final trailTitle = ref.watch(
      trailConfigProvider.select((c) => c.displayName),
    );

    return AppGradientHeader(
      title: t.hub.greeting(name: name),
      subtitle: trailTitle,
    );
  }
}
