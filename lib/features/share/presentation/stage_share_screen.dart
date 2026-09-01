import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../i18n/translations.g.dart';
import '../domain/share_service.dart';
import '../providers/visibility_settings_provider.dart';

/// Ecran de partage d'une carte de resultat d'etape (F7D-02, Phase 7).
///
/// Le partage est OPT-IN : si l'utilisateur n'a pas active le partage des
/// resultats d'etape (reglage de visibilite F7D-02, prive par defaut), un
/// message l'invite a l'activer et AUCUNE carte n'est generee. Sinon, la carte
/// PSEUDONYME (F7D-01, sans PII) est affichee, prete a partager.
///
/// a11y via [Semantics], Slang t.shareVisibility.* (aucune cle "anonyme", R1).
class StageShareScreen extends ConsumerWidget {
  const StageShareScreen({
    required this.authorUidHash,
    required this.stageName,
    required this.distanceKm,
    required this.elevationGainM,
    required this.durationSeconds,
    this.badgeTitle,
    this.onShare,
    super.key,
  });

  final String authorUidHash;
  final String stageName;
  final double distanceKm;
  final int elevationGainM;
  final int durationSeconds;
  final String? badgeTitle;

  /// Action de partage effective (plateforme), injectee pour la testabilite.
  final void Function(StageResultCard card)? onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final optedIn = ref.watch(
      visibilitySettingsProvider.select((s) => s.shareStageResults),
    );
    final card = const ShareService().buildStageCard(
      optedIn: optedIn,
      authorUidHash: authorUidHash,
      stageName: stageName,
      distanceKm: distanceKm,
      elevationGainM: elevationGainM,
      durationSeconds: durationSeconds,
      badgeTitle: badgeTitle,
    );

    return Scaffold(
      appBar: AppBar(title: Text(t.shareVisibility.shareTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: card == null
              ? _PrivateNotice(message: t.shareVisibility.privateNotice)
              : _CardPreview(card: card, onShare: onShare),
        ),
      ),
    );
  }
}

/// Apercu de la carte pseudonyme + bouton partager.
class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.card, required this.onShare});

  final StageResultCard card;
  final void Function(StageResultCard card)? onShare;

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(60),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.pseudonym, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacingXs),
              Text(card.stageName, style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppTheme.spacingMd),
              Wrap(
                spacing: AppTheme.spacingLg,
                runSpacing: AppTheme.spacingSm,
                children: [
                  _Stat(label: 'km', value: card.distanceKm.toStringAsFixed(1)),
                  _Stat(label: 'D+', value: '${card.elevationGainM} m'),
                  _Stat(
                    label: 't',
                    value: _formatDuration(card.durationSeconds),
                  ),
                ],
              ),
              if (card.badgeTitle != null && card.badgeTitle!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(card.badgeTitle!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary, pleine largeur
        // (minimumSize infinie explicite conservee) ; minHeight 52 = meme cible.
        // key/Semantics(button+label) preserves.
        Semantics(
          button: true,
          label: t.shareVisibility.shareButton,
          child: AppButton(
            key: const ValueKey('share-button'),
            minHeight: 52,
            icon: Icons.share,
            label: t.shareVisibility.shareButton,
            onPressed: () => onShare?.call(card),
          ),
        ),
      ],
    );
  }
}

/// Une statistique de la carte (valeur + libelle court).
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.grisTexteSecondaire,
          ),
        ),
      ],
    );
  }
}

/// Message affiche quand le partage n'est pas active (prive par defaut).
class _PrivateNotice extends StatelessWidget {
  const _PrivateNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: AppTheme.spacingBase),
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
