// E5.15 / L6 (H1) — Dialog confirmation SOS avec position GPS + 2 canaux secours.
//
// Canal 1 : appel direct 112 via url_launcher tel: (SOS declenche).
// Canal 2 : invite vers la FICHE MEDICALE NATIVE du telephone (H1) — best-effort
//   (l'OS expose la fiche medicale / emergency info sur l'ecran verrouille).
// Si annule : ferme le dialog sans action.
//
// Textes via Slang (namespace `sos`, 5 langues) — ZERO texte en dur (L6).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';

/// E5.15 / L6 : Dialog de confirmation SOS (2 canaux secours, H1).
///
/// Affiche la position GPS actuelle (lat, lng, alt) et propose :
/// - **Canal 1** : appeler le 112 (appel direct) ;
/// - **Canal 2** : ouvrir la fiche medicale native du telephone (invite) ;
/// - Annuler : fermer sans action.
///
/// La position GPS est passee en parametre par l'appelant (barre SOS / cockpit).
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
              t.sos.title,
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
            t.sos.body,
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
                      t.sos.positionTitle,
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
                  Text(
                    t.sos.positionUnavailable,
                    style: const TextStyle(
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
                      : t.sos.altitudeUnavailable,
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
            t.sos.communicate,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withAlpha(137),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Canal 2 (H1) : invite vers la FICHE MEDICALE NATIVE du telephone.
          // Action secondaire, sous le bandeau : ne detourne pas de l'appel 112
          // mais offre le 2e canal secours (montrer ses infos vitales).
          Semantics(
            button: true,
            label: t.sos.medicalId.action,
            child: InkWell(
              key: const ValueKey('sos-medical-id'),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              onTap: () => _openNativeMedicalId(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(120),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.medical_information_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.sos.medicalId.action,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            t.sos.medicalId.hint,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Bouton annuler
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            t.sos.cancel,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withAlpha(178),
              fontSize: 15,
            ),
          ),
        ),
        // Canal 1 : appel 112. SW-SKIN-L3e : AppButton filledTone rouge
        // (couleur SEMANTIQUE d'urgence). isFullWidth:false (action de dialogue).
        AppButton(
          variant: AppButtonVariant.filledTone,
          tone: AppTheme.rougeUrgence,
          isFullWidth: false,
          icon: Icons.phone,
          label: t.sos.call,
          onPressed: () {
            Navigator.of(context).pop();
            _callEmergency();
          },
        ),
      ],
    );
  }

  /// Canal 1 : lance l'appel direct au 112 via url_launcher.
  Future<void> _callEmergency() async {
    try {
      final uri = Uri.parse('tel:112');
      await launchUrl(uri);
    } catch (_) {
      // Silencieux — l'OS gere l'erreur si le tel ne peut pas appeler.
    }
  }

  /// Canal 2 (H1) : INVITE vers la fiche medicale native du telephone.
  ///
  /// L'OS (iOS Medical ID / Android Notfallpass) expose une fiche medicale
  /// lisible sur l'ecran verrouille, geree HORS de l'app. Aucun plugin Flutter
  /// pur fiable n'ouvre cet ecran de maniere cross-plateforme : plutot que de
  /// tenter une URI hasardeuse (et mentir sur le resultat), on INVITE clairement
  /// l'utilisateur a l'ouvrir depuis les reglages Sante de son telephone.
  /// AUCUNE donnee sante ne transite par l'app (local-only) — c'est la 2e voie
  /// de secours, complementaire de l'appel 112 et de la fiche sante interne.
  void _openNativeMedicalId(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.sos.medicalId.unavailable)));
  }
}
