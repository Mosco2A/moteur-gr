/// Le bouton photo de la carte, qui ecrit dans le journal du jour.
///
/// Bibliotheque de l'ecran `map_screen.dart` (lot 645-06b).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/services/monetization_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/paywall_sheet.dart';
import '../../../journal/data/photo_service.dart';
import '../../../journal/journal_facade.dart' show journalScreenProvider;
import '../../../map/map_facade.dart' show trackPositionProvider;
import '../../../../core/branding/stepways_icons.dart';

/// Bouton PHOTO de la carte -> journal du jour (LOT D, manque reel n°1).
///
/// LA REFERENCE L'A SUR SA CARTE (`_takePhoto`), STEPWAYS NE L'AVAIT NULLE PART :
/// zero occurrence de `photo_camera` dans `lib/features/trek/` et
/// `lib/features/map/`. Le marcheur devait quitter la navigation, ouvrir le
/// journal, creer une note, choisir la galerie… pour garder une image du col.
///
/// DEUX REGLES MAISON RESPECTEES, ET ELLES COMPTENT :
///  1. LE VERROU DU JOURNAL TIENT (decision Chris du 02/09, memoire #99410) :
///     le journal fait partie du pack. Sans achat, ce bouton n'ecrit RIEN — il
///     ouvre la vitrine ([buyTrail]). On ne remplit pas un carnet
///     verrouille, et on ne masque pas la fonction pour autant : le marcheur
///     voit ce qu'il gagne en achetant.
///  2. L'ERREUR EST DITE, jamais avalee : quota du jour atteint, photo trop
///     lourde, disque en echec -> message traduit ([PhotoError]), la meme
///     table de libelles que le journal.
class MapPhotoButton extends ConsumerStatefulWidget {
  const MapPhotoButton({super.key});

  @override
  ConsumerState<MapPhotoButton> createState() => _MapPhotoButtonState();
}

class _MapPhotoButtonState extends ConsumerState<MapPhotoButton> {
  /// Vrai pendant la prise et l'enregistrement : le bouton ne se redeclenche
  /// pas (un double tap en marchant est la norme, pas l'exception).
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    // Le droit d'acces est OBSERVE ici, pas seulement lu au moment du tap : un
    // `ref.read` sur un provider jamais observe declenche son chargement et
    // rend `AsyncLoading` -> un payeur se serait vu proposer la vitrine au
    // premier appui. En l'observant, il est resolu avant que le doigt arrive.
    ref.watch(isDemoModeProvider(trailId));
    return FloatingActionButton.small(
      heroTag: 'mapTakePhoto',
      tooltip: t.journal.addPhoto,
      onPressed: _busy ? null : () => _onPressed(trailId),
      child: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const StepIcon(StepwaysIcons.photo),
    );
  }

  Future<void> _onPressed(String trailId) async {
    // Acces au journal = SOURCE UNIQUE [isDemoModeProvider] (correctif L7-3).
    // FAIL-CLOSED : tant que le droit est indetermine ou en erreur, on n'ecrit
    // pas — on propose l'achat, exactement comme l'ecran du journal.
    final acces = ref.read(isDemoModeProvider(trailId));
    final verrouille = acces.value ?? true;
    if (verrouille) {
      if (!mounted) return;
      await buyTrail(context, ref, trailId: trailId);
      return;
    }

    // Capture AVANT tout await : la feuille systeme de l'appareil photo peut
    // demonter ce contexte, il ne doit pas servir a afficher le message.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        // Memes bornes que le dialogue du journal : la compression finale
        // reste l'affaire de PhotoService (500 Ko max).
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      final error = await ref
          .read(journalScreenProvider.notifier)
          .addPhotoNote(
            stageNumber: _currentStageNumber(),
            content: '',
            sourcePath: picked.path,
          );

      if (error != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(_photoErrorLabel(error))),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const StepIcon(StepwaysIcons.cocheCercle, size: 18),
              const SizedBox(width: AppTheme.spacingSm),
              // CONFIRMATION DEDIEE (branchee tache 557) : le message lisait
              // `t.journal.entriesOfDay` — « Entrees du jour », un TITRE de
              // section du journal. Il servait de confirmation faute de mieux,
              // et ne disait pas ce qui venait de se passer.
              // `t.journal.photoAdded` (tache 552, cinq langues) le dit :
              // « Photo ajoutee au journal ».
              Expanded(child: Text(t.journal.photoAdded)),
            ],
          ),
          action: SnackBarAction(
            label: t.nav.journal,
            // Resolution du routeur DIFFEREE au tap : la carte est alors
            // encore montee (le message s'efface avec elle), et un harnais de
            // test sans routeur ne paye pas ce branchement.
            onPressed: () {
              if (mounted) context.push('/journal');
            },
          ),
        ),
      );
    } catch (_) {
      // Appareil photo indisponible / permission refusee : on le DIT.
      messenger.showSnackBar(SnackBar(content: Text(t.journal.photoError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Etape a laquelle rattacher la photo : l'etape DETECTEE si la projection
  /// repond, sinon la premiere du programme (plancher a 1 — une entree de
  /// journal doit porter un numero d'etape valide).
  int _currentStageNumber() {
    final detected = ref
        .read(trackPositionProvider)
        .whenOrNull(data: (s) => s.stageDetection.stageNumber);
    if (detected != null && detected > 0) return detected;
    return 1;
  }

  /// Libelle Slang d'un echec d'ajout de photo (meme table que le journal).
  String _photoErrorLabel(PhotoError error) {
    switch (error) {
      case PhotoError.dailyLimitReached:
        return t.journal.photoLimit;
      case PhotoError.tooLarge:
        return t.journal.photoTooBig;
      case PhotoError.fileNotFound:
      case PhotoError.ioError:
        return t.journal.photoError;
    }
  }
}
