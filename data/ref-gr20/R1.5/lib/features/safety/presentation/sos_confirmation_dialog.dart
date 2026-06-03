// E5.15 — Dialog confirmation SOS avec position GPS.
//
// Affiche les coordonnees GPS actuelles et demande confirmation.
// Si confirme : lance appel direct 112 via url_launcher tel:.
// Si annule : ferme le dialog sans action.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

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
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Row(
        children: [
          Icon(Icons.emergency, color: AppTheme.rougeUrgence, size: 28),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Appeler les secours ?',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vous etes sur le point d\'appeler le 112 (urgences europeennes).',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
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
              border: Border.all(
                color: AppTheme.vertMaquisLight,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 14,
                      color: AppTheme.vertMaquisLight,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Votre position actuelle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.vertMaquisLight,
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

          const Text(
            'Communiquez ces coordonnees aux secours.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.white54,
            ),
          ),
        ],
      ),
      actions: [
        // Bouton annuler
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Annuler',
            style: TextStyle(
              color: AppTheme.grisGranite,
              fontSize: 15,
            ),
          ),
        ),
        // Bouton confirmer — appel 112
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            _callEmergency();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.rougeUrgence,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
          ),
          icon: const Icon(Icons.phone, size: 20),
          label: const Text(
            'Appeler 112',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
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
