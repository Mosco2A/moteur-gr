import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/recovery_code_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';

/// Écran « Afficher mon code de reconnexion » (StepWays — modèle code-sur-tel).
///
/// Décision Chris #99784 (BLINDÉ, zéro-knowledge) : le code de reconnexion vit
/// sur le téléphone ; l'app l'AFFICHE à la demande (ici, depuis les réglages).
/// Ce code EST la clé du coffre chiffré (profil + fiche santé + solde wallet) :
/// il ouvre le coffre sur un AUTRE téléphone (cross-platform Android<->iOS).
/// AUCUN envoi mail/SMS — l'utilisateur le NOTE lui-même.
///
/// AVERTISSEMENT explicite (contrepartie acceptée par Chris) : perdre le code =
/// données IRRÉCUPÉRABLES (pas de backdoor, prix du zéro-nominatif). L'écran
/// insiste donc sur « note-le et garde-le en lieu sûr », et offre une copie
/// presse-papiers. Zéro texte en dur (Slang `recovery.*`).
class RecoveryCodeScreen extends ConsumerWidget {
  const RecoveryCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = Translations.of(context);
    final codeAsync = ref.watch(recoveryCodeProvider);

    return Scaffold(
      appBar: AppHeader(title: tr.recovery.title),
      body: codeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(tr.recovery.error, textAlign: TextAlign.center),
          ),
        ),
        data: (code) => ListView(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          children: [
            // Explication : à quoi sert le code + où il ouvre le coffre.
            Text(
              tr.recovery.intro,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Le CODE, en gros, monospace, lisible et copiable.
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr.recovery.codeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  SelectableText(
                    code,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  OutlinedButton.icon(
                    onPressed: () => _copy(context, ref, code),
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(tr.recovery.copy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // AVERTISSEMENT : perdre le code = données irrécupérables.
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.orangeDifficile,
                    size: 22,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      tr.recovery.warning,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Copie le code dans le presse-papiers + confirmation.
  Future<void> _copy(BuildContext context, WidgetRef ref, String code) async {
    final messenger = ScaffoldMessenger.of(context);
    final tr = Translations.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    messenger.showSnackBar(SnackBar(content: Text(tr.recovery.copied)));
  }
}
