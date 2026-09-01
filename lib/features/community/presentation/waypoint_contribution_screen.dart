import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/ui/app_haptics.dart';
import '../../../i18n/translations.g.dart';
import '../../map/providers/location_provider.dart';
import '../data/waypoint_service.dart';
import '../domain/waypoint_type_config.dart';
import '../providers/waypoint_providers.dart';

/// Formulaire de CONTRIBUTION communautaire OFFLINE (F8A-05).
///
/// Deux modes :
///  - NOUVEAU WAYPOINT : type + position courante + titre ([contributeWaypoint]);
///  - COMMENTAIRE de condition sur un waypoint existant ([targetWaypointId] non
///    null) : ex « source a sec », « eau coule bien » ([contributeComment]).
///
/// La contribution est enregistree EN LOCAL (pending) MEME HORS-LIGNE (R3) ; un
/// bandeau indique « Sera publie a la prochaine synchronisation reseau »
/// (latence assumee A2-6, pas de fausse promesse). L'etat de synchronisation
/// (nombre en attente) est affiche.
///
/// ZERO logique reseau dans le widget : tout est delegue a [WaypointService].
/// Slang 5 langues (`waypoints.contribution.*`), a11y via [Semantics].
class WaypointContributionScreen extends ConsumerStatefulWidget {
  const WaypointContributionScreen({
    super.key,
    this.targetWaypointId,
    this.trailId = 'mare_a_mare_centre',
  });

  /// Si non null : mode COMMENTAIRE sur ce waypoint. Sinon : mode NOUVEAU
  /// WAYPOINT.
  final String? targetWaypointId;

  /// Sentier auquel rattacher un nouveau waypoint.
  final String trailId;

  @override
  ConsumerState<WaypointContributionScreen> createState() =>
      _WaypointContributionScreenState();
}

class _WaypointContributionScreenState
    extends ConsumerState<WaypointContributionScreen> {
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  final _conditionController = TextEditingController();
  String _selectedType = WaypointType.eau;
  bool _submitting = false;
  bool _submitted = false;

  bool get _isCommentMode => widget.targetWaypointId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  /// Enregistre la contribution EN LOCAL (offline-first). Aucune attente reseau.
  Future<void> _submit() async {
    if (_submitting) return;
    final t = Translations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(waypointServiceProvider);

    setState(() => _submitting = true);
    try {
      if (_isCommentMode) {
        final texte = _commentController.text.trim();
        if (texte.isEmpty) {
          setState(() => _submitting = false);
          messenger.showSnackBar(
            SnackBar(content: Text(t.waypoints.contribution.emptyComment)),
          );
          return;
        }
        final condition = _conditionController.text.trim();
        await service.contributeComment(
          waypointId: widget.targetWaypointId!,
          // UID hache injecte par la couche auth en prod ; placeholder local
          // (jamais de PII en clair, #85383). La vraie valeur viendra du
          // provider d'auth une fois branche (hors scope F8A-05).
          authorUidHash: 'local-pending',
          texte: texte,
          condition: condition.isEmpty ? null : condition,
        );
      } else {
        final titre = _titleController.text.trim();
        if (titre.isEmpty) {
          setState(() => _submitting = false);
          messenger.showSnackBar(
            SnackBar(content: Text(t.waypoints.contribution.emptyTitle)),
          );
          return;
        }
        // Position courante : derniere valeur GPS connue, sinon best-effort.
        Position? position = ref.read(locationProvider).value;
        position ??= await _bestEffortPosition();
        if (position == null) {
          if (!mounted) return;
          setState(() => _submitting = false);
          messenger.showSnackBar(
            SnackBar(content: Text(t.waypoints.contribution.noLocation)),
          );
          return;
        }
        await service.contributeWaypoint(
          // Id local stable (timestamp) ; le serveur reconciliera a la sync.
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          trailId: widget.trailId,
          type: _selectedType,
          latitude: position.latitude,
          longitude: position.longitude,
          titre: titre,
        );
      }
      // Rafraichit le compteur de contributions en attente.
      ref.invalidate(pendingWaypointContributionsProvider);
      AppHaptics.medium();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } on Exception {
      // Erreur loggee par le service (ErrorHandler) ; ici on rend la main a
      // l'utilisateur sans promesse trompeuse.
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(t.waypoints.contribution.error)),
      );
    }
  }

  /// Lecture ponctuelle de la position sans propager d'exception (offline-first).
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
    // Garde le flux GPS actif pour exposer la derniere position au submit.
    ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isCommentMode
              ? t.waypoints.contribution.titleComment
              : t.waypoints.contribution.titleWaypoint,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: _submitted
              ? _SubmittedView(onClose: () => Navigator.of(context).maybePop())
              : ListView(
                  children: [
                    if (_isCommentMode)
                      ..._buildCommentForm(t, theme)
                    else
                      ..._buildWaypointForm(t, theme),
                    const SizedBox(height: AppTheme.spacingMd),
                    // Bandeau de latence assumee (transparence, A2-6).
                    _LatencyBanner(
                      message: t.waypoints.contribution.latencyBanner,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Semantics(
                      button: true,
                      label: t.waypoints.contribution.submit,
                      // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary.
                      // isLoading porte l'etat _submitting (spinner interne +
                      // desactivation) ; minHeight 52 conserve la cible du CTA
                      // pleine largeur (iso-rendu). key/Semantics preserves.
                      child: AppButton(
                        key: const ValueKey('waypoint-contribution-submit'),
                        isLoading: _submitting,
                        minHeight: 52,
                        icon: Icons.save_outlined,
                        label: t.waypoints.contribution.submit,
                        onPressed: _submitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Formulaire NOUVEAU WAYPOINT : selection du type + titre.
  List<Widget> _buildWaypointForm(Translations t, ThemeData theme) {
    return [
      Text(
        t.waypoints.contribution.chooseType,
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: AppTheme.spacingSm),
      Wrap(
        spacing: AppTheme.spacingSm,
        runSpacing: AppTheme.spacingSm,
        children: WaypointTypeConfig.allTypes.map((type) {
          final style = WaypointTypeConfig.getStyle(type);
          final selected = _selectedType == type;
          final label = _typeLabel(t, type);
          return Semantics(
            button: true,
            selected: selected,
            label: label,
            child: ChoiceChip(
              key: ValueKey('contribution-type-$type'),
              avatar: Icon(
                style.icon,
                size: 18,
                color: selected ? Colors.white : style.color,
              ),
              label: Text(label),
              selected: selected,
              selectedColor: style.color,
              labelStyle: TextStyle(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
              ),
              onSelected: (_) => setState(() => _selectedType = type),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: AppTheme.spacingMd),
      Semantics(
        textField: true,
        label: t.waypoints.contribution.titleField,
        child: TextField(
          key: const ValueKey('contribution-title-field'),
          controller: _titleController,
          decoration: InputDecoration(
            labelText: t.waypoints.contribution.titleField,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    ];
  }

  /// Formulaire COMMENTAIRE de condition : texte + condition optionnelle.
  List<Widget> _buildCommentForm(Translations t, ThemeData theme) {
    return [
      Text(
        t.waypoints.contribution.conditionPrompt,
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: AppTheme.spacingSm),
      Semantics(
        textField: true,
        label: t.waypoints.contribution.commentField,
        child: TextField(
          key: const ValueKey('contribution-comment-field'),
          controller: _commentController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: t.waypoints.contribution.commentField,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spacingMd),
      Semantics(
        textField: true,
        label: t.waypoints.contribution.conditionField,
        child: TextField(
          key: const ValueKey('contribution-condition-field'),
          controller: _conditionController,
          decoration: InputDecoration(
            labelText: t.waypoints.contribution.conditionField,
            helperText: t.waypoints.contribution.conditionHelper,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    ];
  }

  String _typeLabel(Translations t, String type) {
    final key = WaypointTypeConfig.getStyle(type).labelKey;
    final types = t.waypoints.types;
    switch (key) {
      case 'eau':
        return types.eau;
      case 'ravitaillement':
        return types.ravitaillement;
      case 'danger':
        return types.danger;
      case 'camp':
        return types.camp;
      case 'connectivite':
        return types.connectivite;
      case 'jonction':
        return types.jonction;
      default:
        return key;
    }
  }
}

/// Bandeau de latence assumee (pas de promesse de temps reel, A2-6).
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

/// Vue de confirmation apres enregistrement local (etat « en attente »).
class _SubmittedView extends ConsumerWidget {
  const _SubmittedView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final pendingAsync = ref.watch(pendingWaypointContributionsProvider);

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
            t.waypoints.contribution.savedTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            t.waypoints.contribution.savedPendingSync,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Etat de synchronisation (nombre en attente).
          pendingAsync.when(
            data: (count) => Text(
              t.waypoints.contribution.pendingCount(n: count),
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
          // remplissait deja la Column -> isFullWidth:true = iso-rendu. key gardee.
          AppButton(
            key: const ValueKey('waypoint-contribution-close'),
            label: t.waypoints.contribution.close,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
