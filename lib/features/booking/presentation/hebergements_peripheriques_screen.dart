import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../i18n/translations.g.dart';
import '../domain/models/hebergement_peripherique.dart';
import '../providers/hebergement_peripherique_providers.dart';

/// Écran des hébergements périphériques A/R (F6D-02, F6.4).
///
/// Liste les hébergements situés À CÔTÉ du sentier avec leur détour aller-retour
/// estimé, et un bouton qui OUVRE un lien profond vers le site/app du
/// prestataire. StepWays est un FACILITATEUR (#84100) : aucune réservation ni
/// paiement in-app, aucune collecte de données de réservation. Un bandeau le
/// rappelle explicitement. Textes via Slang, accessibilité via [Semantics].
class HebergementsPeripheriquesScreen extends ConsumerWidget {
  const HebergementsPeripheriquesScreen({super.key, required this.trailId});

  /// Identifiant du sentier dont on liste les hébergements à proximité.
  final String trailId;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    HebergementPeripherique h,
  ) async {
    final launcher = ref.read(deeplinkLauncherProvider);
    final t = Translations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launcher.open(h.deeplinkUrl);
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(t.hebergement.cannotOpen)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final hebergements = ref.watch(hebergementsPeripheriquesProvider(trailId));

    return Scaffold(
      appBar: AppBar(title: Text(t.hebergement.title)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: _FacilitatorBanner(message: t.hebergement.facilitatorNote),
            ),
            Expanded(
              child: hebergements.isEmpty
                  ? Center(
                      child: Text(
                        t.hebergement.empty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grisTexteSecondaire,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingBase,
                      ),
                      itemCount: hebergements.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.spacingSm),
                      itemBuilder: (context, i) {
                        final h = hebergements[i];
                        return _HebergementCard(
                          hebergement: h,
                          typeLabel: _typeLabel(t, h.type),
                          onOpen: () => _open(context, ref, h),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(Translations t, HebergementType type) {
    switch (type) {
      case HebergementType.refuge:
        return t.hebergement.types.refuge;
      case HebergementType.gite:
        return t.hebergement.types.gite;
      case HebergementType.hotel:
        return t.hebergement.types.hotel;
      case HebergementType.camping:
        return t.hebergement.types.camping;
      case HebergementType.chambreHote:
        return t.hebergement.types.chambreHote;
    }
  }
}

/// Carte d'un hébergement périphérique (nom, type, détour A/R, lien).
class _HebergementCard extends StatelessWidget {
  const _HebergementCard({
    required this.hebergement,
    required this.typeLabel,
    required this.onOpen,
  });

  final HebergementPeripherique hebergement;
  final String typeLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    // SW-SKIN-L3e : Card -> AppCard. key conservee (test ValueKey) ; padding md
    // porte par AppCard (iso-rendu de la carte hebergement).
    return AppCard(
      key: ValueKey('hebergement-${hebergement.id}'),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconFor(hebergement.type),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  hebergement.nom,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            typeLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Détour aller-retour estimé.
          Semantics(
            label: t.hebergement.detourAR(
              km: hebergement.distanceAllerRetourKm.toStringAsFixed(1),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_walk, size: 18),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  t.hebergement.detourAR(
                    km: hebergement.distanceAllerRetourKm.toStringAsFixed(1),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: t.hebergement.openSite,
              // SW-SKIN-L3e : OutlinedButton.icon -> AppButton outline, pleine
              // largeur. Le theme OutlinedButton impose minimumSize infinie :
              // le bouton s'etirait deja sur toute la largeur (l'Align n'avait
              // pas d'effet visible) -> isFullWidth:true = iso-rendu verifie
              // par sonde de largeur. Semantics(button+label) conservee.
              child: AppButton(
                variant: AppButtonVariant.outline,
                icon: Icons.open_in_new,
                label: t.hebergement.openSite,
                onPressed: onOpen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(HebergementType type) {
    switch (type) {
      case HebergementType.refuge:
        return Icons.cabin;
      case HebergementType.gite:
        return Icons.house_outlined;
      case HebergementType.hotel:
        return Icons.hotel;
      case HebergementType.camping:
        return Icons.cottage_outlined;
      case HebergementType.chambreHote:
        return Icons.bedroom_parent_outlined;
    }
  }
}

/// Bandeau rappelant le rôle de facilitateur (pas d'intermédiation, #84100).
class _FacilitatorBanner extends StatelessWidget {
  const _FacilitatorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: message,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withAlpha(60),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
