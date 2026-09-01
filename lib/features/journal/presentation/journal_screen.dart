import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/models/journal_entry.dart';
import '../providers/journal_providers.dart';

/// Ecran principal du journal de trek (E3.1c).
///
/// Affiche toutes les notes et photos du randonneur,
/// groupees par jour (date decroissante).
/// Utilise select() partout -- zero ref.watch brut dans build.
/// Tout texte via Slang (t.journal.*).
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select() pour ne reconstruire que sur changement de isLoading
    final isLoading = ref.watch(
      journalScreenProvider.select((s) => s.isLoading),
    );
    // select() pour ne reconstruire que sur changement du nombre d entrees
    final entryCount = ref.watch(
      journalScreenProvider.select((s) => s.entries.length),
    );
    // select() pour les entrees groupees par jour
    final entriesByDay = ref.watch(
      journalScreenProvider.select((s) => s.entriesByDay),
    );

    final theme = Theme.of(context);
    final journalT = t.journal;

    return Scaffold(
      appBar: AppBar(
        title: Text(journalT.title),
        actions: [
          if (entryCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingBase),
              child: Center(
                child: Text(
                  entryCount.toString(),
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : entryCount == 0
          ? _EmptyJournalView(journalT: journalT)
          : _JournalDayList(entriesByDay: entriesByDay),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final journalT = t.journal;
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddNoteDialogSlang(
        journalT: journalT,
        onSave: (stageNumber, content) {
          ref
              .read(journalScreenProvider.notifier)
              .addNote(stageNumber: stageNumber, content: content);
        },
      ),
    );
  }
}

/// Vue etat vide -- aucune note dans le journal.
class _EmptyJournalView extends StatelessWidget {
  const _EmptyJournalView({required this.journalT});

  final Translations$journal$fr journalT;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: AppTheme.spacingLg),
          Text(journalT.empty, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppTheme.spacingSm),
          Text(journalT.emptySubtitle, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Liste des entrees groupees par jour.
class _JournalDayList extends StatelessWidget {
  const _JournalDayList({required this.entriesByDay});

  final Map<String, List<JournalEntryModel>> entriesByDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final dayKeys = entriesByDay.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      itemCount: dayKeys.length,
      itemBuilder: (context, index) {
        final dayKey = dayKeys[index];
        final dayEntries = entriesByDay[dayKey]!;
        final dt = DateTime.tryParse(dayKey) ?? DateTime.now();
        final dateLabel = dateFormat.format(dt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: AppTheme.spacingLg),
            Text(
              dateLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...dayEntries.map((entry) => _JournalEntryTile(entry: entry)),
          ],
        );
      },
    );
  }
}

/// Tuile d une entree de journal (note ou photo).
///
/// Affiche l heure, l etape, le contenu, et la photo si presente.
/// Actions : supprimer via le menu contextuel.
class _JournalEntryTile extends ConsumerWidget {
  const _JournalEntryTile({required this.entry});

  final JournalEntryModel entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final journalT = t.journal;
    final stageLabel = [journalT.stage, entry.stageNumber.toString()].join(' ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terrain, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                stageLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                timeFormat.format(entry.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    ref
                        .read(journalScreenProvider.notifier)
                        .deleteEntry(entry.id);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(journalT.delete),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (entry.photoPath != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: Image.file(
                File(entry.photoPath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            ),
          ],
          if (entry.text.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(entry.text, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Dialogue d ajout de note avec textes Slang.
class _AddNoteDialogSlang extends StatefulWidget {
  const _AddNoteDialogSlang({required this.journalT, required this.onSave});

  final Translations$journal$fr journalT;
  final void Function(int stageNumber, String content) onSave;

  @override
  State<_AddNoteDialogSlang> createState() => _AddNoteDialogSlangState();
}

class _AddNoteDialogSlangState extends State<_AddNoteDialogSlang> {
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
    final journalT = widget.journalT;

    return AlertDialog(
      title: Text(journalT.addNote),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(journalT.stage, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            DropdownButtonFormField<int>(
              initialValue: _stageNumber,
              items: List.generate(16, (i) => i + 1)
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text([journalT.stage, n.toString()].join(' ')),
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
            Text(journalT.yourNote, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(hintText: journalT.placeholder),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(journalT.cancel),
        ),
        AppButton(
          label: journalT.save,
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
