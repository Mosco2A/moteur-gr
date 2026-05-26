import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/database.dart';
import '../../../core/theme/app_theme.dart';

/// Carte d'une entrée de journal.
///
/// Affiche le texte, la photo éventuelle, l'heure et l'étape.
/// Permet l'édition et la suppression via les callbacks.
class JournalEntryCard extends StatelessWidget {
  const JournalEntryCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onEdit,
  });

  final JournalEntry entry;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : étape + heure + actions
            Row(
              children: [
                Icon(
                  Icons.terrain,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  'Étape ${entry.stageNumber}',
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
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Photo éventuelle
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
            // Contenu texte
            if (entry.content.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                entry.content,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
