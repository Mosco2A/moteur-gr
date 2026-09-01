// E5.15 — Dialog confirmation SOS avec position GPS.
//
// Affiche les coordonnees GPS actuelles et demande confirmation.
// Si confirme : lance appel direct 112 via url_launcher tel:.
// Si annule : ferme le dialog sans action.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';

/// E5.15 : Dialog de confirmation SOS.
///
/// Affiche la position GPS actuelle (lat, lng, alt) et propose :
/// - Confirmer → appel direct 112
/// - Annuler → fermer sans action
///
/// La position GPS est passee en parametre par [SosButton].
class SosConfirmationDialog extends StatelessWidget {
  const SosConfirmationDialog({
    super.key,
    this.latitude,
    this.longitude,
    this.altitude,
  });

  /// Coordonnees GPS actuelles (optionnelles).
  final double? latitude;
  final double? longitude;
  final double? altitude;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        children: [
          const Icon(Icons.emergency, color: AppTheme.rougeUrgence, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Appeler les secours ?',
              style: TextStyle(
                fontSize: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vous etes sur le point d\'appeler le 112 (urgences europeennes).',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withAlpha(178),
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),

          // Bandeau position GPS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: theme.colorScheme.primary, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Votre position actuelle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (latitude != null && longitude != null) ...[
                  Text(
                    'Lat: ${latitude!.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Lng: ${longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Position GPS indisponible',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ],
                Text(
                  altitude != null
                      ? 'Alt: ${altitude!.round()} m'
                      : 'Altitude: indisponible',
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),

          Text(
            'Communiquez ces coordonnees aux secours.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withAlpha(137),
            ),
          ),
        ],
      ),
      actions: [
        // Bouton annuler
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withAlpha(178),
              fontSize: 15,
            ),
          ),
        ),
        // SW-SKIN-L3e : ElevatedButton.icon a fond rouge -> AppButton
        // filledTone (fond plein = rougeUrgence, texte/icone blancs). Conserve
        // la couleur SEMANTIQUE d'urgence de l'appel 112 ; isFullWidth:false
        // pour rester une action de dialogue (aux cotes du TextButton Annuler
        // laisse tel quel). Libelle inchange.
        AppButton(
          variant: AppButtonVariant.filledTone,
          tone: AppTheme.rougeUrgence,
          isFullWidth: false,
          icon: Icons.phone,
          label: 'Appeler 112',
          onPressed: () {
            Navigator.of(context).pop();
            _callEmergency();
          },
        ),
      ],
    );
  }

  /// Lance l'appel direct au 112 via url_launcher.
  Future<void> _callEmergency() async {
    try {
      final uri = Uri.parse('tel:112');
      await launchUrl(uri);
    } catch (_) {
      // Silencieux — l'OS gere l'erreur si le tel ne peut pas appeler
    }
  }
}
