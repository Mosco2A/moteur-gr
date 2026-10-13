/// Deux canaux de secours cote a cote — appeler le 112, ouvrir la fiche
/// medicale native — avec la position GPS sous les yeux avant de choisir.
library;

// E5.15 / L6 (H1) — Dialog confirmation SOS avec position GPS + 2 canaux secours.
//
// Canal 1 : appel direct 112 via url_launcher tel: (SOS declenche).
// Canal 2 : invite vers la FICHE MEDICALE NATIVE du telephone (H1) — best-effort
//   (l'OS expose la fiche medicale / emergency info sur l'ecran verrouille).
// Si annule : ferme le dialog sans action.
//
// Textes via Slang (namespace `sos`, 5 langues) — ZERO texte en dur (L6).
//
// LOT 671-04 — UN DIALOGUE A ETAT, ET CE N'EST PAS UN AJOUT DE LIGNE. Il
// etait sans etat, ses coordonnees figees a la construction : il ne pouvait
// donc pas montrer TOUT DE SUITE la derniere position connue PUIS la
// remplacer par la fraiche. Il observe desormais le TIR UNIQUE lance a
// l'appui ([tirFrais]) : la position connue s'affiche a la premiere image,
// avec son AGE en clair ; pendant le tir, « Acquisition GPS… » ; la fraiche
// la remplace, l'age repasse « a l'instant » ; si quinze secondes passent
// sans elle, le dialogue le DIT et GARDE la connue avec son age. Les deux
// canaux de secours et l'annulation ne changent pas.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/gps_cadence.dart' show kSingleShotMaxDelay;
import '../../../core/theme/app_theme.dart';
import '../../../domain/age_de_position.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/branding/stepways_icons.dart';
import '../../trek/trek_facade.dart' show PositionConnue;

/// Tant que le dialogue est ouvert, l'age affiche est recalcule a ce rythme :
/// un age fige mentirait en vieillissant.
const Duration _rafraichissementDeLAge = Duration(seconds: 15);

/// E5.15 / L6 : Dialog de confirmation SOS (2 canaux secours, H1).
///
/// Affiche la position connue (lat, lng, alt) et son age, et propose :
/// - **Canal 1** : appeler le 112 (appel direct) ;
/// - **Canal 2** : ouvrir la fiche medicale native du telephone (invite) ;
/// - Annuler : fermer sans action.
///
/// La position connue et le tir unique sont passes par l'appelant (le bouton
/// SOS) ; l'age se calcule sur [maintenant], une horloge INJECTEE.
class SosConfirmationDialog extends StatefulWidget {
  const SosConfirmationDialog({
    super.key,
    this.connue,
    this.tirFrais,
    this.maintenant = DateTime.now,
  });

  /// La derniere position connue a l'appui, releve ou estime ; nulle si le
  /// trek n'a encore rien recu.
  final PositionConnue? connue;

  /// Le tir unique lance a l'appui ; nul si aucun n'a pu l'etre.
  final Future<PositionConnue>? tirFrais;

  /// L'horloge de l'age (`DateTime.now` en production).
  final DateTime Function() maintenant;

  @override
  State<SosConfirmationDialog> createState() => _SosConfirmationDialogState();
}

/// Ou en est le tir unique.
enum _Tir { enCours, obtenu, echoue }

class _SosConfirmationDialogState extends State<SosConfirmationDialog> {
  PositionConnue? _position;
  _Tir _tir = _Tir.echoue;
  Timer? _delai;
  Timer? _age;

  @override
  void initState() {
    super.initState();
    _position = widget.connue;
    final tir = widget.tirFrais;
    if (tir != null) {
      _tir = _Tir.enCours;
      // Le recepteur a deja son delai (kSingleShotMaxDelay) ; celui-ci est
      // le filet du dialogue, si la reponse ne revient jamais.
      _delai = Timer(kSingleShotMaxDelay, () => _fin(_Tir.echoue));
      tir.then(
        (frais) => _fin(_Tir.obtenu, frais),
        onError: (Object _) {
          _fin(_Tir.echoue);
        },
      );
    }
    _age = Timer.periodic(_rafraichissementDeLAge, (_) {
      if (mounted) setState(() {});
    });
  }

  void _fin(_Tir tir, [PositionConnue? frais]) {
    if (!mounted || _tir != _Tir.enCours) return;
    _delai?.cancel();
    setState(() {
      _tir = tir;
      if (frais != null) _position = frais;
    });
  }

  @override
  void dispose() {
    _delai?.cancel();
    _age?.cancel();
    super.dispose();
  }

  /// L'age de la position, en langage de randonneur (regle d'arrondi vers le
  /// bas de [ageEnClair]).
  String _ageDe(PositionConnue p) {
    final age = ageEnClair(
      mesureeA: p.mesureeA,
      maintenant: widget.maintenant(),
    );
    if (age == null) return t.sos.ageNow;
    if (age.heures == 0) return t.sos.ageMinutes(minutes: age.minutes);
    return t.sos.ageHours(
      hours: age.heures,
      minutes: age.minutes.toString().padLeft(2, '0'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final position = _position;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        children: [
          const StepIcon(
            StepwaysIcons.emergency,
            color: AppTheme.emergencyRed,
            size: 28,
          ),
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
                    StepIcon(
                      StepwaysIcons.maPosition,
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
                if (position != null) ...[
                  Text(
                    'Lat: ${position.latitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Lng: ${position.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  // L'AGE, EN CLAIR : une information, pas un avertissement
                  // — ni en gros, ni en rouge.
                  _Ligne(_ageDe(position), key: const ValueKey('sos-age')),
                  if (position.estimee) _Ligne(t.sos.estimated),
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
                  // Jamais seule : ce que le randonneur peut faire.
                  _Ligne(t.sos.unavailableHelp),
                ],
                if (_tir == _Tir.enCours)
                  _Ligne(t.sos.gpsAcquiring, key: const ValueKey('sos-tir'))
                else if (_tir == _Tir.echoue && position != null)
                  _Ligne(
                    t.sos.freshFailed(seconds: kSingleShotMaxDelay.inSeconds),
                    key: const ValueKey('sos-tir'),
                  ),
                Text(
                  position?.altitude != null
                      ? 'Alt: ${position!.altitude!.round()} m'
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
                    StepIcon(
                      StepwaysIcons.ficheMedicale,
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
        AppButton(
          variant: AppButtonVariant.text,
          tone: theme.colorScheme.onSurface.withAlpha(178),
          label: t.sos.cancel,
          labelFontSize: 15,
          isFullWidth: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Canal 1 : appel 112. SW-SKIN-L3e : AppButton filledTone rouge
        // (couleur SEMANTIQUE d'urgence). isFullWidth:false (action de dialogue).
        AppButton(
          variant: AppButtonVariant.filledTone,
          tone: AppTheme.emergencyRed,
          isFullWidth: false,
          icon: StepwaysIcons.telephone,
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

/// Une ligne d'information du bandeau de position.
class _Ligne extends StatelessWidget {
  const _Ligne(this.texte, {super.key});

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      texte,
      style: const TextStyle(fontSize: 13, color: Colors.white70),
    ),
  );
}
