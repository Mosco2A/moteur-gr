/// L'AUTORISATION DU PODOMETRE COTE RANDONNEUR (lot 671-02) : l'explication
/// avant la demande, au demarrage d'un trek ; la phrase du refus, dite une
/// fois ; et la ligne des reglages, seul chemin pour accepter plus tard.
///
/// TEXTES PAR LES CLES DE TRADUCTION (`tracking.stepCounting`), comme le mot
/// d'explication voisin du suivi de fond : ces phrases sont lues par un
/// randonneur, dans des ecrans normaux, dans sa langue.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/routing/navigateur_racine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/podometre_permission_service.dart';
import '../domain/accumulateur_de_pas.dart';
import '../providers/podometre_providers.dart';

/// AU DEMARRAGE D'UN TREK, a cote du pre-vol de la localisation de fond
/// (`ensureBackgroundTrackingExplained`), jamais a l'ouverture de
/// l'application : l'autorisation n'a de sens qu'au moment de partir marcher.
///
/// Dans l'ordre : rien si l'autorisation est accordee, refusee definitivement,
/// deja declinee, ou si le telephone ne compte pas les pas ; sinon
/// l'explication, puis seulement la demande du systeme. Un refus est retenu et
/// raconte une fois. Ne leve jamais, ne bloque jamais le demarrage.
Future<void> ensureStepCountingExplained(
  BuildContext context,
  WidgetRef ref,
) async {
  final service = ref.read(podometerPermissionServiceProvider);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final whyGps = Translations.of(context).tracking.stepCounting.whyGps;
  await service.explainAtTrekStart(
    explain: () async {
      final dialogContext = context.mounted
          ? contexteDeDialogue(context)
          : null;
      if (dialogContext == null) return false;
      return _showExplanation(dialogContext);
    },
    onRefused: () => messenger?.showSnackBar(SnackBar(content: Text(whyGps))),
  );
}

/// L'explication, avant toute demande du systeme. Vrai si le randonneur
/// accepte de voir la demande ; faux ou nul sinon (« Plus tard », barriere,
/// retour du systeme : le choix le plus sur).
Future<bool?> _showExplanation(BuildContext context) {
  final tr = Translations.of(context).tracking.stepCounting;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('podometre-explication'),
      icon: const StepIcon(StepwaysIcons.pas),
      title: Text(tr.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr.body),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            tr.ifRefused,
            style: Theme.of(dialogContext).textTheme.bodySmall,
          ),
        ],
      ),
      actionsOverflowButtonSpacing: AppTheme.spacingSm,
      actions: [
        AppButton(
          variant: AppButtonVariant.text,
          label: tr.later,
          isFullWidth: false,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppButton(
          label: tr.allow,
          isFullWidth: false,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
}

/// LA LIGNE DES REGLAGES : l'etat en clair, et le SEUL chemin de redemande,
/// parti du randonneur. Non accordee, elle ouvre l'explication puis la
/// demande ; refusee definitivement, les reglages du systeme. Accordee ou
/// sans podometre, elle ne fait que dire l'etat (aucun geste).
class PodometerSettingsTile extends ConsumerStatefulWidget {
  /// Une ligne sans parametre : tout se lit sur le telephone.
  const PodometerSettingsTile({super.key});

  @override
  ConsumerState<PodometerSettingsTile> createState() =>
      _PodometerSettingsTileState();
}

class _PodometerSettingsTileState extends ConsumerState<PodometerSettingsTile> {
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // Au retour des reglages du systeme, l'etat a pu changer : on le relit.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(podometerProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _act(PodometerAccess access) async {
    final service = ref.read(podometerPermissionServiceProvider);
    if (access == PodometerAccess.permanentlyDenied) {
      await service.openSystemSettings();
    } else {
      final dialogContext = contexteDeDialogue(context);
      if (dialogContext == null) return;
      if (await _showExplanation(dialogContext) == true) {
        await service.request();
      }
    }
    if (mounted) ref.invalidate(podometerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context).tracking.stepCounting;
    final state = ref.watch(podometerProvider).value;
    final access = state?.access;
    final actionable =
        access == PodometerAccess.denied ||
        access == PodometerAccess.permanentlyDenied;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        key: const ValueKey('reglages-compte-des-pas'),
        leading: const StepIcon(StepwaysIcons.pas),
        title: Text(tr.settingsTitle),
        subtitle: Text(state == null ? '…' : _sentence(tr, state)),
        trailing: actionable
            ? const StepIcon(StepwaysIcons.chevronDroite)
            : null,
        onTap: actionable ? () => unawaited(_act(access!)) : null,
      ),
    );
  }

  static String _sentence(
    Translations$tracking$stepCounting$fr tr,
    PodometerState state,
  ) => switch (state.access) {
    PodometerAccess.granted => switch (state.readiness) {
      EstimateReadiness.streamError => tr.stateStreamError,
      EstimateReadiness.podometerUnavailable => tr.stateUnavailable,
      _ => tr.stateGranted,
    },
    PodometerAccess.denied => tr.stateDenied,
    PodometerAccess.permanentlyDenied => tr.statePermanentlyDenied,
    PodometerAccess.unavailable => tr.stateUnavailable,
  };
}
