// E5.15 — Bouton SOS appel direct V1.
//
// FloatingActionButton rouge SOS visible UNIQUEMENT pendant un trek actif.
// Au tap : ouvre un dialog de confirmation avec position GPS.
// Si confirme : appel direct 112 via url_launcher.
//
// Integration : overlay dans MapNavigationScreen (Stack > Positioned).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../trek/providers/gps_providers.dart';
import '../../trek/providers/tracking_providers.dart';
import 'sos_confirmation_dialog.dart';

/// E5.15 : Bouton SOS flottant — visible uniquement pendant trek actif.
///
/// Ce widget encapsule la logique de visibilite :
/// - Trek actif (recording ou paused) → bouton visible
/// - Pas de trek → SizedBox.shrink (invisible, pas de layout)
///
/// Le bouton affiche le dialog [SosConfirmationDialog] au tap.
class SosButton extends ConsumerWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verifier si un trek est actif (recording ou paused)
    final trackingState = ref.watch(trekSessionManagerProvider);
    final isTrekActive =
        trackingState.status == TrackingSessionStatus.recording ||
            trackingState.status == TrackingSessionStatus.paused;

    // Masque si pas de trek actif
    if (!isTrekActive) return const SizedBox.shrink();

    return SizedBox(
      width: 72,
      height: 72,
      child: FloatingActionButton(
        heroTag: 'sos_e515',
        backgroundColor: AppTheme.rougeUrgence,
        elevation: 8,
        shape: const CircleBorder(),
        onPressed: () => _showSosConfirmation(context, ref),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, color: Colors.white, size: 24),
            Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre le dialog de confirmation SOS avec la position GPS.
  void _showSosConfirmation(BuildContext context, WidgetRef ref) {
    // Recuperer la position GPS actuelle via positionStreamProvider
    double? latitude;
    double? longitude;
    double? altitude;

    final positionAsync = ref.read(positionStreamProvider);
    positionAsync.whenData((Position position) {
      latitude = position.latitude;
      longitude = position.longitude;
      altitude = position.altitude;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SosConfirmationDialog(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
      ),
    );
  }
}
