import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../providers/off_track_provider.dart';

/// Banniere de securite affichee sur la carte quand le randonneur s'ecarte du
/// trace (etat pilote par [offTrackProvider], avec hysteresis 80/50 m). Rendu
/// nul (SizedBox.shrink) tant qu'on est sur le trace.
///
/// C'est le pendant VISIBLE de l'alerte : la notification locale + la vibration
/// partent depuis [OffTrackNotifier] (meme telephone en poche) ; cette banniere
/// est le bonus in-screen quand l'ecran carte est ouvert. Generique : aucun nom
/// de sentier en dur (texte via i18n navAlert).
class OffTrackBanner extends ConsumerWidget {
  const OffTrackBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffTrack = ref.watch(
      offTrackProvider.select((s) => s.isOffTrack),
    );
    if (!isOffTrack) {
      return const SizedBox.shrink();
    }

    final meters = ref.watch(
      offTrackProvider.select((s) => s.distanceMeters.round()),
    );
    final theme = Theme.of(context);

    return Material(
      color: AppTheme.orangeDifficile,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wrong_location_outlined,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.navAlert.offTrackBanner(meters: meters),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
