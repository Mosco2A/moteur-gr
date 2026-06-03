// E5.15 — Bouton SOS appel direct V1.
//
// FloatingActionButton rouge SOS visible UNIQUEMENT pendant un trek actif.
// Au tap : ouvre un dialog de confirmation avec position GPS.
// Si confirme : appel direct 112 via url_launcher.
//
// Integration : overlay dans MapNavigationScreen (Stack > Positioned).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../trek/providers/demo_trek_provider.dart';
import '../../trek/providers/trek_providers.dart';
import 'sos_confirmation_dialog.dart';

/// E5.15 : Bouton SOS flottant — visible uniquement pendant trek actif.
///
/// Ce widget encapsule la logique de visibilite :
/// - Trek actif (real ou demo) → bouton visible
/// - Pas de trek → SizedBox.shrink (invisible, pas de layout)
///
/// Le bouton affiche le dialog [SosConfirmationDialog] au tap.
class SosButton extends ConsumerWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verifier si un trek est actif (reel ou demo)
    final session = ref.watch(effectiveTrekSessionProvider);
    final isTrekActive = session != null && session.isOngoing;

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
    // Recuperer la position GPS actuelle
    double? latitude;
    double? longitude;
    double? altitude;

    final positionAsync = ref.read(currentPositionProvider);
    positionAsync.whenData((position) {
      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
        altitude = position.altitude;
      }
    });

    // Fallback position demo si GPS indisponible
    if (latitude == null) {
      final isDemoActive = ref.read(isDemoTrekActiveProvider);
      if (isDemoActive) {
        final demoPos = ref.read(demoCurrentPositionProvider);
        latitude = demoPos.latitude;
        longitude = demoPos.longitude;
        altitude = demoPos.altitude;
      }
    }

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
