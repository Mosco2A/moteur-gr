import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/ui/app_haptics.dart';
import '../../../i18n/translations.g.dart';
import '../../map/providers/location_provider.dart';
import '../data/signalement_service.dart';
import '../providers/signalement_providers.dart';

/// Écran de signalement terrain type Waze (F6C-03, F6.1).
///
/// L'utilisateur choisit un type parmi {obstacle, eau à sec, danger} et confirme
/// d'un seul geste. Le signalement est créé EN LOCAL d'abord (offline-first,
/// [SignalementService.createLocal]) puis synchronisé plus tard. Un bandeau
/// explicite la latence assumée : « visible par les autres après synchronisation
/// réseau » — AUCUNE promesse de temps réel (A2-6).
///
/// Toute la logique métier/réseau est déléguée au service ; ce widget ne fait
/// que présenter et capturer le geste. Textes via Slang (t.signalement.*),
/// accessibilité via [Semantics] (dette E5.3).
class SignalementScreen extends ConsumerStatefulWidget {
  const SignalementScreen({super.key});

  @override
  ConsumerState<SignalementScreen> createState() => _SignalementScreenState();
}

class _SignalementScreenState extends ConsumerState<SignalementScreen> {
  String _selectedType = SignalementType.obstacle;
  bool _submitting = false;
  bool _submitted = false;

  /// Crée le signalement en local à la position GPS courante.
  ///
  /// Confirmation en un geste : capture la dernière position connue (sans
  /// bloquer si le GPS est indisponible), insère en file locale, puis affiche
  /// l'état « en attente de synchronisation ».
  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final service = ref.read(signalementServiceProvider);
    final t = Translations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Position courante : dernière valeur du stream si dispo, sinon best-effort.
    Position? position = ref.read(locationProvider).value;
    position ??= await _bestEffortPosition();

    if (position == null) {
      // Pas de position exploitable : on n'invente pas de coordonnées.
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(t.signalement.noLocation)));
      return;
    }

    await service.createLocal(
      type: _selectedType,
      latitude: position.latitude,
      longitude: position.longitude,
    );
    // Rafraîchit le compteur d'attente affiché.
    ref.invalidate(pendingSignalementCountProvider);
    // Retour haptique en fire-and-forget (pas d'await : convention projet, et
    // le canal plateforme ne répond pas en test).
    AppHaptics.medium();

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  /// Tente une lecture ponctuelle de la position sans propager d'exception
  /// (offline-first : un signalement reste possible même GPS capricieux).
  Future<Position?> _bestEffortPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } on Exception {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    // Abonnement au flux GPS : garde [locationProvider] actif pour que
    // `value` expose la dernière position connue au moment de confirmer.
    ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.signalement.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: _submitted
              ? _SubmittedView(onClose: () => Navigator.of(context).maybePop())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.signalement.chooseType,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    // Sélecteur de type : 3 cartes accessibles.
                    Expanded(
                      child: ListView(
                        children: [
                          _TypeOption(
                            type: SignalementType.obstacle,
                            icon: Icons.warning_amber_rounded,
                            label: t.signalement.types.obstacle,
                            selected: _selectedType == SignalementType.obstacle,
                            onTap: () => setState(
                              () => _selectedType = SignalementType.obstacle,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          _TypeOption(
                            type: SignalementType.eauASec,
                            icon: Icons.water_drop_outlined,
                            label: t.signalement.types.eauASec,
                            selected: _selectedType == SignalementType.eauASec,
                            onTap: () => setState(
                              () => _selectedType = SignalementType.eauASec,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          _TypeOption(
                            type: SignalementType.danger,
                            icon: Icons.dangerous_outlined,
                            label: t.signalement.types.danger,
                            selected: _selectedType == SignalementType.danger,
                            onTap: () => setState(
                              () => _selectedType = SignalementType.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    // Bandeau de latence assumée (transparence, A2-6).
                    _LatencyBanner(message: t.signalement.latencyBanner),
                    const SizedBox(height: AppTheme.spacingMd),
                    // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary.
                    // isLoading porte l'etat _submitting (spinner + desactivation,
                    // grammaire unifiee) ; minHeight 52 conserve la cible du CTA
                    // pleine largeur. Semantics(button+label) preservee au-dessus.
                    Semantics(
                      button: true,
                      label: t.signalement.confirm,
                      child: AppButton(
                        isLoading: _submitting,
                        minHeight: 52,
                        icon: Icons.send_rounded,
                        label: t.signalement.confirm,
                        onPressed: _submitting ? null : _confirm,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Carte de sélection d'un type de signalement (accessible).
class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String type;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        key: ValueKey('signalement-type-$type'),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withAlpha(24)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: color, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
              if (selected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau d'information sur la latence de visibilité (pas de temps réel).
class _LatencyBanner extends StatelessWidget {
  const _LatencyBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: message,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withAlpha(60),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vue de confirmation après enregistrement local (état « en attente »).
class _SubmittedView extends ConsumerWidget {
  const _SubmittedView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final pendingAsync = ref.watch(pendingSignalementCountProvider);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.spacingBase),
          Text(
            t.signalement.savedTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            t.signalement.savedPendingSync,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // État de synchronisation (nombre en attente).
          pendingAsync.when(
            data: (count) => Text(
              t.signalement.pendingCount(n: count),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisTexteSecondaire.withAlpha(180),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // SW-SKIN-L3e : ElevatedButton -> AppButton primary, pleine largeur.
          // Le theme ElevatedButton impose minimumSize infinie : le bouton
          // remplissait deja la Column -> isFullWidth:true = iso-rendu.
          AppButton(label: t.signalement.close, onPressed: onClose),
        ],
      ),
    );
  }
}
