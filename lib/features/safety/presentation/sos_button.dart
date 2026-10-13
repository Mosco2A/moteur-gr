/// Le SOS n'existe que pendant une rando active : hors rando il ne prend meme
/// pas de place dans la mise en page.
library;

// E5.15 — Bouton SOS appel direct V1.
//
// FloatingActionButton rouge SOS visible UNIQUEMENT pendant un trek actif.
// Au tap : ouvre un dialog de confirmation avec la derniere position connue,
// son age, et un tir unique qui la remplace (lot 671-04).
// Si confirme : appel direct 112 via url_launcher.
//
// Integration : overlay dans MapNavigationScreen (Stack > Positioned).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../trek/trek_facade.dart'
    show
        TrackingSessionStatus,
        positionsConnuesProvider,
        trekSessionManagerProvider;
import 'sos_confirmation_dialog.dart';
import '../../../core/branding/stepways_icons.dart';

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

    // LOT 671-04 — PLUS AUCUN FLUX GPS CHAUD ICI. Les Finitions V1 (point 6)
    // gardaient `positionStreamProvider` en ecoute tant que le bouton etait
    // visible, parce que ce flux FROID n'avait souvent rien emis quand le
    // dialogue s'ouvrait (« position GPS indisponible »). En profil batterie
    // d'abord, cette ecoute tenait le robinet ouvert tout le trek. La
    // position montree a la premiere image vient desormais de la DERNIERE
    // POSITION CONNUE (releve ou estime, `positionsConnuesProvider`), une
    // memoire que la lire n'ouvre pas ; et l'appui lance UN tir unique qui la
    // remplace. Le defaut d'origine ne revient pas : la position connue
    // existe des le premier releve du trek, et le bouton n'existe que
    // pendant un trek.

    // a11y : le bouton porte un label explicite pour les lecteurs d'ecran
    // (le contenu visuel « SOS » + icone est exclu de la semantique pour ne
    // pas doubler l'annonce). Parite GR20 : SOS accessible pendant le trek.
    return Semantics(
      button: true,
      label: t.a11y.sos,
      excludeSemantics: true,
      child: SizedBox(
        width: 72,
        height: 72,
        child: FloatingActionButton(
          heroTag: 'sos_e515',
          backgroundColor: AppTheme.emergencyRed,
          elevation: 8,
          shape: const CircleBorder(),
          onPressed: () => _showSosConfirmation(context, ref),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StepIcon(StepwaysIcons.emergency, color: Colors.white, size: 24),
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
      ),
    );
  }

  /// Ouvre le dialog de confirmation SOS : la derniere position connue tout
  /// de suite, un tir unique pour la remplacer, et la ligne `sos` du journal.
  void _showSosConfirmation(BuildContext context, WidgetRef ref) {
    final positions = ref.read(positionsConnuesProvider);
    final connue = positions.derniere();
    unawaited(positions.noterLAppel(connue));
    // Le tir part a l'appui ; son echec ou son retard, le dialogue le dit.
    final tirFrais = positions.tirer();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SosConfirmationDialog(
        connue: connue,
        tirFrais: tirFrais,
        maintenant: positions.maintenant,
      ),
    );
  }
}
