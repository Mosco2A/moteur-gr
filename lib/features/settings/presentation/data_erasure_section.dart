// TACHE 562 (LOT K, K1) — LA COMMANDE D'EFFACEMENT, LA OU LE RANDONNEUR LA
// CHERCHE.
//
// Le droit a l'effacement (art. 17 RGPD) etait implemente et prouve depuis le
// LOT J, et introuvable dans l'application : aucun ecran ne l'offrait. Cette
// section le pose dans les Reglages, immediatement apres « Confidentialite et
// consentement » — c'est la que le randonneur va chercher ce qui touche a ses
// donnees, pas dans un menu de compte enfoui.
//
// TROIS EXIGENCES, ET LEUR TRADUCTION A L'ECRAN :
//   1. DIRE, avant le geste : ce qui part, ce qui RESTE (les achats survivent,
//      et le randonneur doit le lire, pas le deviner), et que c'est definitif.
//   2. CONFIRMER EXPLICITEMENT : un tap ne suffit pas. Le bouton definitif reste
//      INERTE tant que la case n'est pas cochee — la case n'est pas un ornement,
//      c'est elle qui l'active.
//   3. RENDRE LA MAIN : l'ecran dit que c'est fait, et dit aussi si ca n'a pas
//      abouti — sans jamais pretendre que rien n'a bouge, car un effacement
//      interrompu a deja pu emporter une partie des donnees.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../providers/account_erasure_provider.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Section « Mes donnees » des Reglages : la commande d'effacement (art. 17).
class DataErasureSection extends ConsumerStatefulWidget {
  const DataErasureSection({super.key});

  @override
  ConsumerState<DataErasureSection> createState() => _DataErasureSectionState();
}

class _DataErasureSectionState extends ConsumerState<DataErasureSection> {
  bool _erasing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = Translations.of(context).erasure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: Row(
            children: [
              Icon(Icons.delete_forever_outlined,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                tr.section,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Semantics(
            button: true,
            label: tr.a11y.entry,
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined,
                  color: AppTheme.rougeUrgence),
              title: Text(tr.entry),
              subtitle: Text(tr.entryDesc),
              trailing: _erasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _erasing ? null : _confirmAndErase,
            ),
          ),
        ),
      ],
    );
  }

  /// Demande une confirmation EXPLICITE, puis efface.
  Future<void> _confirmAndErase() async {
    final tr = Translations.of(context).erasure;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ErasureConfirmDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _erasing = true);
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      final report = await ref.read(accountErasureProvider)();
      _log.i('[Erasure] Art. 17 : ${report.tablesWiped} table(s), '
          '${report.localRowsDeleted} ligne(s), '
          '${report.prefsKeysDeleted} cle(s) de prefs, '
          '${report.secureKeysDeleted} cle(s) de keystore');
      message = tr.done;
    } catch (e) {
      // Pas de catch silencieux : l'echec est journalise ET dit au randonneur.
      // Le message ne pretend PAS que rien n'a bouge — une etape a pu aboutir
      // avant l'echec de la suivante.
      _log.e('[Erasure] Effacement art. 17 interrompu : $e');
      message = tr.error;
    }
    if (!mounted) return;
    setState(() => _erasing = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Dialogue de confirmation : il DIT, puis il exige un acte positif.
class _ErasureConfirmDialog extends StatefulWidget {
  const _ErasureConfirmDialog();

  @override
  State<_ErasureConfirmDialog> createState() => _ErasureConfirmDialogState();
}

class _ErasureConfirmDialogState extends State<_ErasureConfirmDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = Translations.of(context).erasure;

    Widget bloc(String titre, String corps) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppTheme.spacingXs),
              Text(corps, style: theme.textTheme.bodyMedium),
            ],
          ),
        );

    return AlertDialog(
      title: Text(tr.dialogTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bloc(tr.goesTitle, tr.goes),
            bloc(tr.staysTitle, tr.stays),
            Text(
              tr.finalWarning,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.rougeUrgence),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // L'ACTE POSITIF. Sans lui, le bouton d'a cote ne fait rien.
            CheckboxListTile(
              value: _understood,
              onChanged: (v) => setState(() => _understood = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(tr.confirmCheckbox,
                  style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr.cancel),
        ),
        // Action DEFINITIVE : rouge, et INERTE tant que la case n'est pas
        // cochee (meme grammaire que l'effacement de la fiche sante).
        AppButton(
          variant: AppButtonVariant.filledTone,
          tone: AppTheme.rougeUrgence,
          isFullWidth: false,
          label: tr.confirm,
          onPressed:
              _understood ? () => Navigator.of(context).pop(true) : null,
        ),
      ],
    );
  }
}
