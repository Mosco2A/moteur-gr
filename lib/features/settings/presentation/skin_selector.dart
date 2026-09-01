import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_skin.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/skin_provider.dart';
import '../../../core/theme/skin_theme.dart';
import '../../../i18n/translations.g.dart';

/// Ouvre le selecteur de peau en bottom-sheet (SW-SKIN-L7).
///
/// Point d'entree partage : la carte (« Changer de peau ») et tout autre acces
/// rapide reutilisent CE meme selecteur ([SkinSelector]) — une seule grammaire.
/// Le titre passe par Slang (`t.appearance.changeSkin`).
Future<void> showSkinSelectorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final tr = Translations.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingBase,
            0,
            AppTheme.spacingBase,
            AppTheme.spacingLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingBase),
                child: Text(
                  tr.appearance.changeSkin,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SkinSelector(),
            ],
          ),
        ),
      );
    },
  );
}

/// Selecteur de peau (SW-SKIN-L7) — 3 tuiles + apercu vignette schematique.
///
/// Reutilise par la section « Apparence » des Reglages et par le bottom-sheet
/// « Changer de peau » de la carte. Chaque tuile :
///  - montre une VIGNETTE schematique (accent-sentier + style d'en-tete de la
///    peau) — PAS de photo (l'asset Grand Air arrive en L9) ;
///  - marque clairement l'etat selectionne ;
///  - grise Grand Air + affiche « Indisponible sur ce sentier » quand le sentier
///    n'est pas eligible (jamais masque, jamais de rendu casse — mandat §#A4).
///
/// a11y : chaque tuile est un `Semantics(button, selected, enabled, label)`,
/// cible tactile >= 44 px, respecte le contraste (texte sur surface du theme).
class SkinSelector extends ConsumerWidget {
  const SkinSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(skinProvider);
    final grandAirEligible = ref.watch(trailHasCoverPhotosProvider);
    final tr = Translations.of(context);

    return Column(
      children: [
        for (final skin in AppSkin.values) ...[
          _SkinTile(
            skin: skin,
            selected: skin == selected,
            // Seule Grand Air peut etre ineligible (photos requises). Les peaux
            // sans image (Sentier Vivant, Topographique) sont toujours choisies.
            enabled: skin != AppSkin.grandAir || grandAirEligible,
            onTap: () => ref.read(skinProvider.notifier).select(skin),
            tr: tr,
          ),
          if (skin != AppSkin.values.last)
            const SizedBox(height: AppTheme.spacingSm),
        ],
      ],
    );
  }
}

/// Une tuile de peau : vignette schematique + nom + description + etat.
class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.tr,
  });

  final AppSkin skin;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Translations tr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final title = _title(tr);
    final desc = _desc(tr);
    final borderColor =
        selected ? cs.primary : cs.outline.withValues(alpha: 0.5);

    // Corps de la tuile. Opacite reduite si desactivee (grise), sans jamais
    // masquer le choix (mandat §#A4).
    final Widget content = Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Row(
          children: [
            _SkinVignette(skin: skin),
            const SizedBox(width: AppTheme.spacingBase),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  // Explication d'inéligibilité (Grand Air sur sentier sans
                  // photos) — jamais masquer, toujours expliquer.
                  if (!enabled) ...[
                    const SizedBox(height: 4),
                    Text(
                      tr.appearance.unavailableOnTrail,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            // Marqueur d'etat selectionne (radio-like), coherent avec les autres
            // sections des Reglages (langue/theme).
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );

    // Semantics : bouton, etat selectionne/actif, libelle explicite (nom +
    // description + eventuelle indisponibilite). ExcludeSemantics sur le visuel
    // pour ne pas dupliquer (icone/textes decoratifs deja resumes ici).
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: enabled
          ? '$title. $desc${selected ? '. ${tr.appearance.selected}' : ''}'
          : '$title. ${tr.appearance.unavailableOnTrail}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          // Cible tactile confortable (>= 44 px, a11y).
          constraints: const BoxConstraints(minHeight: 64),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              // Desactive le tap si la peau n'est pas eligible.
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(
                    color: borderColor,
                    width: selected ? 2.0 : 1.0,
                  ),
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _title(Translations tr) {
    switch (skin) {
      case AppSkin.sentierVivant:
        return tr.appearance.skinSentierVivant;
      case AppSkin.topographique:
        return tr.appearance.skinTopographique;
      case AppSkin.grandAir:
        return tr.appearance.skinGrandAir;
    }
  }

  String _desc(Translations tr) {
    switch (skin) {
      case AppSkin.sentierVivant:
        return tr.appearance.skinSentierVivantDesc;
      case AppSkin.topographique:
        return tr.appearance.skinTopographiqueDesc;
      case AppSkin.grandAir:
        return tr.appearance.skinGrandAirDesc;
    }
  }
}

/// Vignette schematique d'une peau (SW-SKIN-L7).
///
/// Rend un mini-apercu du TRAITEMENT D'EN-TETE de la peau, teinte par l'accent
/// du sentier (couleur primaire du theme) — SANS asset photo :
///  - `gradient`  (Sentier Vivant) : bandeau en degrade d'accent ;
///  - `topoFilet` (Topographique)  : fond papier + fines lignes de niveau ;
///  - `photo`     (Grand Air)       : cadre + icone image (placeholder — la vraie
///    photo plein ecran arrive en L9).
///
/// C'est un apercu leger et schematique (mandat §L7.3) : il illustre le style,
/// il ne reproduit pas l'ecran.
class _SkinVignette extends StatelessWidget {
  const _SkinVignette({required this.skin});

  final AppSkin skin;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final skinTheme = SkinTheme.fromSkin(skin);
    final radius = BorderRadius.circular(AppTheme.radiusChip);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: _size,
        height: _size,
        child: _buildPreview(context, skinTheme.headerStyle),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, SkinHeaderStyle style) {
    final cs = Theme.of(context).colorScheme;

    switch (style) {
      case SkinHeaderStyle.gradient:
        // Degrade d'accent (accent-sentier = primaire du theme -> plus clair).
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary,
                Color.lerp(cs.primary, Colors.white, 0.45) ?? cs.primary,
              ],
            ),
          ),
        );

      case SkinHeaderStyle.topoFilet:
        // Fond papier + filet de lignes de niveau (schematique).
        return CustomPaint(
          painter: _TopoFiletPainter(
            paper: AppTheme.blancNeige,
            line: AppTheme.grisGranite.withValues(alpha: 0.45),
          ),
        );

      case SkinHeaderStyle.photo:
        // Placeholder image (pas d'asset photo en L7 — arrive en L9).
        return ColoredBox(
          color: cs.surfaceContainerHighest,
          child: Icon(
            Icons.photo_outlined,
            size: 24,
            color: cs.onSurfaceVariant,
          ),
        );
    }
  }
}

/// Peintre du filet topographique de la vignette (lignes de niveau discretes).
class _TopoFiletPainter extends CustomPainter {
  _TopoFiletPainter({required this.paper, required this.line});

  final Color paper;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = paper;
    canvas.drawRect(Offset.zero & size, bg);

    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Quelques courbes de niveau concentriques schematiques.
    for (var i = 1; i <= 3; i++) {
      final rect = Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.55),
        width: size.width * (0.35 * i),
        height: size.height * (0.28 * i),
      );
      canvas.drawOval(rect, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _TopoFiletPainter old) =>
      old.paper != paper || old.line != line;
}
