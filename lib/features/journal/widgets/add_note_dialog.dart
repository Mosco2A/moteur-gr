import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';

/// Dialogue d'ajout d'une note au journal.
///
/// Permet de saisir le numéro d'étape et le contenu de la note.
///
/// R10 (LOT L10) : le nombre d'étapes proposées est désormais FOURNI par
/// l'appelant ([stageCount]) au lieu d'un `16` en dur (le compte du GR20, qui
/// laissait choisir des étapes inexistantes sur un sentier à 7, 12 ou 5
/// étapes). Le moteur étant générique, aucun compte d'étapes ne doit vivre en
/// dur dans un widget.
class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({
    super.key,
    required this.stageCount,
    required this.onSave,
  });

  /// Nombre d'étapes réelles du sentier courant (>= 1).
  final int stageCount;

  final void Function(int stageNumber, String content) onSave;

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _contentController = TextEditingController();
  int _stageNumber = 1;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(t.journal.addNote),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.journal.stage, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            DropdownButtonFormField<int>(
              initialValue: _stageNumber,
              items: List.generate(widget.stageCount, (i) => i + 1)
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text('${t.journal.stage} $n'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _stageNumber = value);
                }
              },
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Text(t.journal.yourNote, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: t.journal.placeholder,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.journal.cancel),
        ),
        AppButton(
          label: t.journal.save,
          isFullWidth: false,
          onPressed: () {
            final content = _contentController.text.trim();
            if (content.isNotEmpty) {
              widget.onSave(_stageNumber, content);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
