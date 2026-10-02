/// Le code de reconnexion s'AFFICHE a la demande, et c'est tout : au marcheur
/// de le noter, puisque rien ne part par mail ni par SMS.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/coffre_de_reconnexion.dart';
import '../../../core/services/recovery_code_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../core/branding/stepways_icons.dart';

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

    // TACHE 596 (C2) — ON NE PROMET PLUS UN COFFRE VIDE.
    //
    // Tant que rien n'alimente le coffre (mesure declaree et verifiee par
    // invariante, cf. [CoffreDeReconnexion]), cet ecran disait au randonneur
    // que son code « ouvre son coffre sur un autre telephone » — c'etait faux :
    // aucun code de production n'y ecrit, aucun ecran ne permet de saisir un
    // code, et il n'existe meme pas de transport. Pire, afficher cet ecran
    // FABRIQUAIT le code au passage, posant dans le coffre-fort du telephone un
    // secret qui n'ouvre rien.
    //
    // Ici, on dit l'etat reel — et on ne lit meme pas `recoveryCodeProvider`,
    // donc aucun code n'est cree.
    if (!CoffreDeReconnexion.alimente) {
      return Scaffold(
        appBar: AppHeader(title: tr.recovery.title),
        body: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.recovery.noVaultTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    tr.recovery.noVaultBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Le code n'est LU (donc fabrique, `getOrCreate`) qu'une fois le coffre
    // reellement alimente. C'est volontairement APRES la sortie ci-dessus.
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
            Text(tr.recovery.intro, style: theme.textTheme.bodyMedium),
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
                  AppButton(
                    variant: AppButtonVariant.outline,
                    icon: StepwaysIcons.copier,
                    iconSize: 18,
                    label: tr.recovery.copy,
                    onPressed: () => _copy(context, ref, code),
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
                  const StepIcon(
                    StepwaysIcons.danger,
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
