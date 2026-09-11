import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../domain/past_hike.dart';
import '../providers/hiker_profile_provider.dart';

/// Ecran « Vos 5 dernieres randos » (StepWays LOT 4, Ph3).
///
/// Interview des 5 dernieres randos notables [date, jours, marche moy/j, D+
/// total, distance totale] + 1 champ texte libre GLOBAL « difficultes ». La
/// faisabilite en DEDUIT le niveau reel. Tous textes via Slang (`t.pastHikes`).
class PastHikesScreen extends ConsumerStatefulWidget {
  const PastHikesScreen({super.key});

  @override
  ConsumerState<PastHikesScreen> createState() => _PastHikesScreenState();
}

class _PastHikesScreenState extends ConsumerState<PastHikesScreen> {
  final _noteController = TextEditingController();
  bool _noteLoaded = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addOrEdit({PastHike? existing, required int count}) async {
    if (existing == null && count >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pastHikes.maxReached)),
      );
      return;
    }
    final result = await showModalBottomSheet<PastHike>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HikeEditorSheet(existing: existing),
    );
    if (result == null) return;
    final current = ref.read(pastHikesProvider).value ?? const <PastHike>[];
    final updated = [...current];
    if (existing != null) {
      final idx = updated.indexOf(existing);
      if (idx >= 0) {
        updated[idx] = result;
      } else {
        updated.add(result);
      }
    } else {
      updated.add(result);
    }
    await ref.read(pastHikesProvider.notifier).saveAll(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pastHikes.saved)),
      );
    }
  }

  Future<void> _delete(PastHike hike) async {
    final current = ref.read(pastHikesProvider).value ?? const <PastHike>[];
    final updated = current.where((h) => h != hike).toList();
    await ref.read(pastHikesProvider.notifier).saveAll(updated);
  }

  Future<void> _saveNote() async {
    await ref
        .read(experienceNoteProvider.notifier)
        .save(_noteController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pastHikes.difficultiesSaved)),
      );
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ph = t.pastHikes;
    final hikesAsync = ref.watch(pastHikesProvider);
    final noteAsync = ref.watch(experienceNoteProvider);

    // Hydrate le champ note une fois (sans ecraser la saisie en cours).
    noteAsync.whenData((text) {
      if (!_noteLoaded) {
        _noteController.text = text;
        _noteLoaded = true;
      }
    });

    return Scaffold(
      appBar: AppHeader(title: ph.title),
      body: hikesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(ph.title)),
        data: (hikes) {
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            children: [
              Text(ph.intro, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppTheme.spacingLg),
              if (hikes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingLg),
                  child: Text(
                    ph.empty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ),
              ...hikes.map(
                (h) => _HikeCard(
                  hike: h,
                  onEdit: () => _addOrEdit(existing: h, count: hikes.length),
                  onDelete: () => _delete(h),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              if (hikes.length < 5)
                AppButton(
                  variant: AppButtonVariant.outline,
                  icon: Icons.add,
                  label: ph.addHike,
                  onPressed: () => _addOrEdit(count: hikes.length),
                ),
              const SizedBox(height: AppTheme.spacingXl),
              // Champ texte libre GLOBAL « difficultes rencontrees ».
              Text(ph.difficultiesTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacingSm),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: ph.difficultiesHint,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusInput),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingBase),
              AppButton(
                icon: Icons.save,
                label: ph.save,
                onPressed: _saveNote,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Carte resumant une rando saisie.
class _HikeCard extends StatelessWidget {
  const _HikeCard({
    required this.hike,
    required this.onEdit,
    required this.onDelete,
  });
  final PastHike hike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ph = t.pastHikes;
    final date = '${hike.date.day.toString().padLeft(2, '0')}/'
        '${hike.date.month.toString().padLeft(2, '0')}/${hike.date.year}';
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: theme.textTheme.titleSmall),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: ph.editHike,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: ph.deleteHike,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: AppTheme.spacingBase,
            runSpacing: AppTheme.spacingXs,
            children: [
              _Chip(
                icon: Icons.calendar_today,
                text: '${hike.days} ${ph.fieldDays.toLowerCase()}',
              ),
              _Chip(
                icon: Icons.straighten,
                text: '${hike.totalDistanceKm.round()} km',
              ),
              _Chip(
                icon: Icons.trending_up,
                text: '${hike.totalElevationGain} m D+',
              ),
              _Chip(
                icon: Icons.schedule,
                text:
                    '${hike.avgWalkHoursPerDay.toStringAsFixed(1)} h/${ph.perDay}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Feuille d'edition d'une rando (ajout ou modification).
class _HikeEditorSheet extends StatefulWidget {
  const _HikeEditorSheet({this.existing});
  final PastHike? existing;
  @override
  State<_HikeEditorSheet> createState() => _HikeEditorSheetState();
}

class _HikeEditorSheetState extends State<_HikeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  final _daysCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _elevCtrl = TextEditingController();
  final _distCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? DateTime.now();
    _daysCtrl.text = e != null ? '${e.days}' : '';
    _hoursCtrl.text = e != null ? _fmtNum(e.avgWalkHoursPerDay) : '';
    _elevCtrl.text = e != null ? '${e.totalElevationGain}' : '';
    _distCtrl.text = e != null ? _fmtNum(e.totalDistanceKm) : '';
  }

  static String _fmtNum(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : '$v';

  @override
  void dispose() {
    _daysCtrl.dispose();
    _hoursCtrl.dispose();
    _elevCtrl.dispose();
    _distCtrl.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      PastHike(
        id: widget.existing?.id ?? 0,
        date: _date,
        days: int.tryParse(_daysCtrl.text.trim()) ?? 1,
        avgWalkHoursPerDay: _parse(_hoursCtrl),
        totalElevationGain: int.tryParse(_elevCtrl.text.trim()) ?? 0,
        totalDistanceKm: _parse(_distCtrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ph = t.pastHikes;
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        top: AppTheme.spacingLg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? ph.addHike : ph.editHike,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingBase),
            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(ph.fieldDate),
              trailing: Text(
                '${_date.day.toString().padLeft(2, '0')}/'
                '${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                style: theme.textTheme.titleMedium,
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            _num(_daysCtrl, ph.fieldDays, Icons.event, decimal: false),
            _num(_hoursCtrl, ph.fieldAvgHours, Icons.schedule),
            _num(_elevCtrl, ph.fieldElevation, Icons.trending_up,
                decimal: false),
            _num(_distCtrl, ph.fieldDistance, Icons.straighten),
            const SizedBox(height: AppTheme.spacingLg),
            AppButton(icon: Icons.check, label: ph.save, onPressed: _submit),
          ],
        ),
      ),
    );
  }

  Widget _num(
    TextEditingController c,
    String label,
    IconData icon, {
    bool decimal = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          decimal
              ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              : FilteringTextInputFormatter.digitsOnly,
        ],
        validator: (v) {
          final s = v?.trim() ?? '';
          if (s.isEmpty) return null; // champ non requis
          final n = double.tryParse(s.replaceAll(',', '.'));
          if (n == null || n < 0) return label;
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          ),
        ),
      ),
    );
  }
}
