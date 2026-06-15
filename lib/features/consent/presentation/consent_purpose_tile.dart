import 'package:flutter/material.dart';

import '../../../core/services/consent_service.dart';
import '../../../i18n/translations.g.dart';

/// Bascule de consentement pour UNE finalite (D4A-02), accessible.
///
/// Reutilisee par l'onboarding et l'ecran de reglages. Affiche le libelle de
/// la finalite, sa description (sauf [hideDescription]) et un [Switch] dont
/// l'etat reflete le consentement courant. JAMAIS pre-coche : la valeur vient
/// toujours de l'etat reel ([granted]). a11y via [Semantics] (toggled + label
/// localise indiquant l'etat autorise/non autorise).
class ConsentPurposeTile extends StatelessWidget {
  const ConsentPurposeTile({
    required this.purpose,
    required this.granted,
    required this.onChanged,
    this.hideDescription = false,
    super.key,
  });

  /// Finalite concernee.
  final ConsentPurpose purpose;

  /// Etat de consentement courant (source de verite de la position du switch).
  final bool granted;

  /// Notifie un changement de consentement (acte positif ou retrait).
  final ValueChanged<bool> onChanged;

  /// Masque la description (ex : section sante qui affiche deja l'avertissement).
  final bool hideDescription;

  /// Libelle localise de la finalite.
  String _label(Translations tr) => switch (purpose) {
        ConsentPurpose.locationNavigation =>
          tr.consent.purposes.locationNavigation,
        ConsentPurpose.socialSharing => tr.consent.purposes.socialSharing,
        ConsentPurpose.publicReporting => tr.consent.purposes.publicReporting,
        ConsentPurpose.healthData => tr.consent.purposes.healthData,
      };

  /// Description localisee de la finalite.
  String _description(Translations tr) => switch (purpose) {
        ConsentPurpose.locationNavigation =>
          tr.consent.purposes.locationNavigationDesc,
        ConsentPurpose.socialSharing => tr.consent.purposes.socialSharingDesc,
        ConsentPurpose.publicReporting =>
          tr.consent.purposes.publicReportingDesc,
        ConsentPurpose.healthData => tr.consent.purposes.healthDataDesc,
      };

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final label = _label(tr);
    final stateLabel = granted ? tr.consent.granted : tr.consent.denied;

    return Semantics(
      toggled: granted,
      label: tr.consent.a11y.purposeToggle(purpose: label, state: stateLabel),
      child: SwitchListTile(
        key: ValueKey('consent-toggle-${purpose.name}'),
        value: granted,
        onChanged: onChanged,
        title: Text(label),
        subtitle: hideDescription ? null : Text(_description(tr)),
        contentPadding: EdgeInsets.zero,
        secondary: granted
            ? const Icon(Icons.check_circle_outline)
            : const Icon(Icons.radio_button_unchecked),
      ),
    );
  }
}
