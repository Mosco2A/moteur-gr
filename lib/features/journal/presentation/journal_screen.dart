import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/database.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/journal_provider.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/add_note_dialog.dart';

/// Écran principal du journal de trek.
///
/// Affiche toutes les notes et photos du randonneur,
/// triées par date décroissante. Permet d'ajouter des notes.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(journalProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal de trek'),
        actions: [
          if (journal.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingBase),
              child: Center(
                child: Text(
                  '${journal.entries.length}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
        ],
      ),
      body: journal.isLoading
          ? const Center(child: CircularProgressIndicator())
          : journal.entries.isEmpty
              ? _buildEmptyState(context, theme)
              : _buildEntryList(context, ref, journal.entries, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Votre journal est vide',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Notez vos impressions et souvenirs de trek',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList(
    BuildContext context,
    WidgetRef ref,
    List<JournalEntry> entries,
    ThemeData theme,
  ) {
    // Regrouper par date
    final grouped = <String, List<JournalEntry>>{};
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    for (final entry in entries) {
      final key = dateFormat.format(entry.createdAt);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateLabel = grouped.keys.elementAt(index);
        final dayEntries = grouped[dateLabel]!;
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
            ...dayEntries.map((entry) => JournalEntryCard(
                  entry: entry,
                  onDelete: () => ref
                      .read(journalProvider.notifier)
                      .deleteEntry(entry.id),
                  onEdit: (content) => ref
                      .read(journalProvider.notifier)
                      .updateNote(entry.id, content),
                )),
          ],
        );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AddNoteDialog(
        onSave: (stageNumber, content) {
          ref.read(journalProvider.notifier).addNote(
                stageNumber: stageNumber,
                content: content,
              );
        },
      ),
    );
  }
}
