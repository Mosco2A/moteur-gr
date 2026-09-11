import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';

/// Dialogue d'ajout d'une note au journal.
///
/// Permet de saisir le numéro d'étape et le contenu de la note.
class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({super.key, required this.onSave});

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
              items: List.generate(16, (i) => i + 1)
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
