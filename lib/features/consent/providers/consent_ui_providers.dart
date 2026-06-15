// D4A-02 — Providers de l'UI de consentement (design D4 CORDO #86166).
//
// Pont entre le [ConsentService] (D4A-01) et l'UI : expose l'etat de
// consentement de toutes les finalites de maniere reactive, et un helper
// pour accorder/retirer un consentement depuis les widgets. La granularite
// PAR FINALITE et l'isolement de la sante (art 9) sont garantis par le
// service sous-jacent.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/consent_service.dart';

/// Etat de consentement de TOUTES les finalites (lecture reactive).
///
/// S'initialise via [consentServiceReadyProvider] (chargement
/// SharedPreferences), puis lit l'etat courant de chaque finalite. A invalider
/// apres chaque grant/revoke (fait par [ConsentController]).
final consentStatesProvider =
    FutureProvider<Map<ConsentPurpose, ConsentState>>((ref) async {
  final service = await ref.watch(consentServiceReadyProvider.future);
  return service.allStates();
});

/// Vrai si au moins une finalite necessite une (re)demande de consentement.
///
/// Sert au routeur / a l'onboarding pour decider d'afficher l'ecran de
/// consentement au premier lancement (ou apres une evolution de politique).
final consentPromptNeededProvider = FutureProvider<bool>((ref) async {
  final service = await ref.watch(consentServiceReadyProvider.future);
  return ConsentPurpose.values.any(service.needsPrompt);
});

/// Controleur imperatif du consentement pour l'UI.
///
/// Encapsule grant/revoke et invalide [consentStatesProvider] pour rafraichir
/// l'affichage. Obtenu via [consentControllerProvider].
class ConsentController {
  ConsentController(this._ref);

  final Ref _ref;

  /// Accorde le consentement pour [purpose] (acte positif explicite) puis
  /// rafraichit l'etat affiche.
  Future<void> grant(ConsentPurpose purpose) async {
    final service = await _ref.read(consentServiceReadyProvider.future);
    await service.grant(purpose);
    _ref.invalidate(consentStatesProvider);
    _ref.invalidate(consentPromptNeededProvider);
  }

  /// Retire le consentement pour [purpose] (retractable a tout moment) puis
  /// rafraichit l'etat affiche.
  Future<void> revoke(ConsentPurpose purpose) async {
    final service = await _ref.read(consentServiceReadyProvider.future);
    await service.revoke(purpose);
    _ref.invalidate(consentStatesProvider);
    _ref.invalidate(consentPromptNeededProvider);
  }

  /// Applique une decision booleenne (utilisee par les bascules de l'UI).
  Future<void> set(ConsentPurpose purpose, {required bool granted}) =>
      granted ? grant(purpose) : revoke(purpose);
}

/// Provider du [ConsentController].
final consentControllerProvider = Provider<ConsentController>(
  ConsentController.new,
);
