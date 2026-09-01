// E5.13 — Ecran de reservation stub.
//
// Scaffold avec message informatif indiquant que les disponibilites
// seront bientot disponibles. En attendant, l'utilisateur est redirige
// vers les fiches etapes pour reserver.
// Route /booking gardee par FeatureFlags.isBookingEnabled.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';

/// E5.13 : Ecran de reservation (stub).
///
/// Affiche un message informatif : les disponibilites arrivent bientot.
/// En attendant, l'utilisateur peut reserver via les fiches etapes.
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 80,
                color: theme.colorScheme.primary.withAlpha(153),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Disponibilites bientot disponibles',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingBase),
              Text(
                'En attendant, reservez via les fiches etapes.\n'
                'Chaque fiche refuge contient les coordonnees '
                'pour reserver directement.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage
              // #A5). isFullWidth:false : bouton centre a la taille du contenu
              // (Column mainAxisAlignment.center), iso-rendu du CTA d'attente.
              AppButton(
                isFullWidth: false,
                icon: Icons.map_outlined,
                label: 'Voir les etapes',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
