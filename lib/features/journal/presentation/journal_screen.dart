import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../data/photo_service.dart';
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

    // R10 (LOT L10) : nombre d'etapes REEL du sentier courant — remplace le
    // `16` en dur (compte du GR20) du selecteur d'etape. Cf.
    // [journalStageCountProvider].
    final stageCount = ref.watch(journalStageCountProvider(trailId));

    final theme = Theme.of(context);
    final journalT = t.journal;

    return Scaffold(
      // Ph5 (L6a) : AppHeader universel ([Retour]+[Accueil] contextuel). Le
      // badge du nombre d'entrees est passe en `actions` (rendu avant Accueil).
      // Ecran cœur -> pas de barre contextuelle (§4).
      appBar: AppHeader(
        title: journalT.title,
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
        onPressed: () => _showAddNoteDialog(context, ref, stageCount),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref, int stageCount) {
    final journalT = t.journal;
    // Capture AVANT tout await : le dialogue se referme avant la fin de la
    // sauvegarde, son `context` ne doit donc pas servir a afficher l'erreur.
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddNoteDialogSlang(
        journalT: journalT,
        stageCount: stageCount,
        onSave: (stageNumber, content, photoPath) async {
          final notifier = ref.read(journalScreenProvider.notifier);
          if (photoPath == null) {
            await notifier.addNote(stageNumber: stageNumber, content: content);
            return;
          }
          // R10 (LOT L10) : entree AVEC photo. L'erreur eventuelle (quota du
          // jour, photo trop lourde, disque) est REMONTEE a l'utilisateur —
          // jamais avalee en silence.
          final error = await notifier.addPhotoNote(
            stageNumber: stageNumber,
            content: content,
            sourcePath: photoPath,
          );
          if (error == null) return;
          messenger.showSnackBar(
            SnackBar(content: Text(_photoErrorLabel(journalT, error))),
          );
        },
      ),
    );
  }

  /// Libelle Slang correspondant a un echec d'ajout de photo.
  static String _photoErrorLabel(
    Translations$journal$fr journalT,
    PhotoError error,
  ) {
    switch (error) {
      case PhotoError.dailyLimitReached:
        return journalT.photoLimit;
      case PhotoError.tooLarge:
        return journalT.photoTooBig;
      case PhotoError.fileNotFound:
      case PhotoError.ioError:
        return journalT.photoError;
    }
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
    // StepWays L7 (A) : date localisee sur la langue de l'app (au lieu de
    // 'fr_FR' fige). `initializeDateFormatting` (main) charge les 5 locales.
    final dateFormat = DateFormat(
      'EEEE d MMMM yyyy',
      LocaleSettings.currentLocale.languageCode,
    );
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

/// Hauteur de la miniature photo d'une entree de journal, en points.
/// Valeur de PARITE GR20 (`trek_journal_screen.dart`).
const double _entryPhotoHeight = 120;

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
          // ORDRE : le TEXTE d'abord, la PHOTO en dernier — parite GR20
          // (`trek_journal_screen.dart` : le texte de l'entree est rendu juste
          // sous l'en-tete, la miniature ferme la carte). L'ordre inverse
          // (photo puis texte) rejetait la note tout en bas de la carte, collee
          // au bord sous une image trop haute : illisible (QA Skynet, L10).
          if (entry.text.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(entry.text, style: theme.textTheme.bodyMedium),
          ],
          // MINIATURE PHOTO — parite GR20 stricte : 120 px de haut (et non
          // 200, qui mangeait la carte et coupait brutalement l'image), le
          // cadrage etant porte par un [SizedBox] et non par l'`Image` (sinon
          // l'image impose sa propre hauteur avant le clip). `cacheWidth`
          // limite la memoire : une photo d'appareil est decodee en version
          // reduite, pas en pleine resolution, pour une bande de 120 px.
          if (entry.photoPath != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: SizedBox(
                height: _entryPhotoHeight,
                width: double.infinity,
                child: Image.file(
                  File(entry.photoPath!),
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 32),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialogue d ajout de note avec textes Slang.
///
/// R10 (LOT L10) : le dialogue sait desormais porter une PHOTO (appareil photo
/// ou galerie, parite GR20) et son selecteur d'etape suit le nombre REEL
/// d'etapes du sentier ([stageCount]) au lieu d'un 16 en dur.
class _AddNoteDialogSlang extends StatefulWidget {
  const _AddNoteDialogSlang({
    required this.journalT,
    required this.stageCount,
    required this.onSave,
  });

  final Translations$journal$fr journalT;

  /// Nombre d'etapes proposees dans le selecteur (>= 1).
  final int stageCount;

  /// [photoPath] : fichier source choisi, `null` pour une note sans photo.
  final void Function(int stageNumber, String content, String? photoPath)
      onSave;

  @override
  State<_AddNoteDialogSlang> createState() => _AddNoteDialogSlangState();
}

/// Cote (en points) de la vignette d'apercu de la photo dans le dialogue.
/// Valeur FINIE volontairement (cf. commentaire de l'apercu).
const double _photoPreviewSize = 96;

class _AddNoteDialogSlangState extends State<_AddNoteDialogSlang> {
  final _contentController = TextEditingController();
  int _stageNumber = 1;

  /// Fichier choisi par l'utilisateur, pas encore compresse ni copie en local
  /// (c'est `PhotoService` qui le fera a l'enregistrement).
  String? _photoPath;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// Demande la SOURCE (appareil photo / galerie), parite GR20
  /// (`_showPhotoSourceDialog`), puis ouvre le selecteur correspondant.
  Future<void> _choosePhotoSource() async {
    final journalT = widget.journalT;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Text(
                journalT.photoSource,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(journalT.camera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(journalT.gallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Pre-redimensionnement a la prise : evite de trimballer un original de
    // plusieurs Mo jusqu'a la compression (limite finale 500 Ko cote
    // PhotoService, qui reste la seule autorite sur la taille stockee).
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _photoPath = picked.path);
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
            // R10 (LOT L10) : le selecteur suit le sentier COURANT. Le `16` en
            // dur (compte du GR20) laissait choisir des etapes inexistantes sur
            // un sentier a 7, 12 ou 5 etapes.
            DropdownButtonFormField<int>(
              initialValue: _stageNumber,
              items: List.generate(widget.stageCount, (i) => i + 1)
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
            const SizedBox(height: AppTheme.spacingBase),
            // R10 (LOT L10) — AJOUT DE PHOTO (parite GR20). Sans ce bloc, une
            // entree ne pouvait porter que du texte, et la galerie du Diplome
            // (qui filtre les entrees avec photo) restait toujours vide.
            if (_photoPath == null)
              OutlinedButton.icon(
                onPressed: _choosePhotoSource,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(journalT.addPhoto),
              )
            else
              // APERCU EN VIGNETTE DE TAILLE FIXE — ET SURTOUT PAS de largeur
              // `double.infinity` ici : `AlertDialog` enveloppe sa colonne dans
              // un `IntrinsicWidth`, et une largeur infinie remontee par la
              // passe d'intrinseques fait degenerer la mesure — le dialogue se
              // dessine alors COMPLETEMENT VIDE (titre compris), sans la
              // moindre exception Dart. Constate sur emulateur au LOT L10.
              // Toutes les dimensions de ce bloc restent donc FINIES.
              // [Wrap] et non [Row] : selon la langue, « Retirer la photo » et
              // la vignette peuvent depasser la largeur du dialogue (constate :
              // debordement de 5,9 px en francais). Le Wrap fait passer le
              // bouton a la ligne au lieu de deborder — zero bandeau jaune et
              // noir, quelle que soit la traduction ou la taille de police.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppTheme.spacingMd,
                runSpacing: AppTheme.spacingSm,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    child: Image.file(
                      File(_photoPath!),
                      width: _photoPreviewSize,
                      height: _photoPreviewSize,
                      fit: BoxFit.cover,
                      // Decode a la taille d'affichage : une photo d'appareil
                      // fait plusieurs milliers de pixels de cote, inutile de
                      // la monter en memoire en pleine resolution pour une
                      // vignette.
                      cacheWidth: (_photoPreviewSize * 3).round(),
                      errorBuilder: (_, __, ___) => Container(
                        width: _photoPreviewSize,
                        height: _photoPreviewSize,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 32),
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _photoPath = null),
                    icon: const Icon(Icons.close),
                    label: Text(journalT.removePhoto),
                  ),
                ],
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
            // Une PHOTO SEULE est une entree valide (parite GR20) : on
            // n'exige plus du texte des lors qu'une photo est jointe.
            if (content.isEmpty && _photoPath == null) return;
            widget.onSave(_stageNumber, content, _photoPath);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
