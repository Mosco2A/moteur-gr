/// Un sentier dans le catalogue, avec la taille de son telechargement et son
/// statut local.
library;

import 'package:flutter/material.dart';

import '../../../core/data/revision_de_donnee.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../i18n/translations.g.dart';
import '../providers/catalog_provider.dart';
import '../../../core/branding/stepways_icons.dart';

/// Libelles i18n pour les statuts de telechargement.
///
/// A remplacer par Slang quand le systeme i18n sera en place.
class _CatalogLabels {
  static const download = 'Telecharger';
  static const update = 'Mettre a jour';
  static const delete = 'Supprimer';
  static const downloaded = 'Telecharge';
  static const downloading = 'En cours...';
  static const notDownloaded = 'Non telecharge';
  static const updateAvailable = 'MAJ disponible';
}

/// Carte representant un sentier dans le catalogue.
///
/// Affiche le nom (trailId en fallback), la taille du fichier,
/// un badge de statut colore et un bouton d'action contextuel
/// (telecharger, mettre a jour, supprimer).
class TrailCatalogCard extends StatelessWidget {
  const TrailCatalogCard({
    super.key,
    required this.entry,
    this.onDownload,
    this.onUpdate,
    this.onDelete,
    this.onEnter,
  });

  /// Entree du catalogue a afficher
  final CatalogEntry entry;

  /// Callback telechargement
  final VoidCallback? onDownload;

  /// Callback mise a jour
  final VoidCallback? onUpdate;

  /// Callback suppression
  final VoidCallback? onDelete;

  /// Callback "entrer dans le sentier" (cablage nav, design #88246).
  ///
  /// Fourni uniquement pour une entree telechargeable : ecrit la selection
  /// (selectedTrailIdProvider) puis ouvre le shell sur /map cote ecran appelant.
  /// Quand null, aucun bouton Entrer n'est affiche (retro-compat tests/usages).
  final VoidCallback? onEnter;

  /// Formate une taille en octets en chaine lisible.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  /// Retourne la couleur du badge selon le statut.
  static Color statusColor(TrailLocalStatus status) {
    switch (status) {
      case TrailLocalStatusValues.notDownloaded:
        return AppTheme.grisGranite;
      case TrailLocalStatusValues.downloading:
        return AppTheme.jauneModere;
      case TrailLocalStatusValues.downloaded:
        return AppTheme.vertFacile;
      case TrailLocalStatusValues.updateAvailable:
        return AppTheme.orangeDifficile;
      default:
        return AppTheme.grisGranite;
    }
  }

  /// Retourne le libelle du badge selon le statut.
  static String statusLabel(TrailLocalStatus status) {
    switch (status) {
      case TrailLocalStatusValues.notDownloaded:
        return _CatalogLabels.notDownloaded;
      case TrailLocalStatusValues.downloading:
        return _CatalogLabels.downloading;
      case TrailLocalStatusValues.downloaded:
        return _CatalogLabels.downloaded;
      case TrailLocalStatusValues.updateAvailable:
        return _CatalogLabels.updateAvailable;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(entry.localStatus);

    // SW-SKIN-L3e : Card -> AppCard. margin conservee ; padding base porte par
    // AppCard (iso-rendu de la carte sentier du catalogue local).
    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne titre + badge
          Row(
            children: [
              ExcludeSemantics(
                child: StepIcon(
                  StepwaysIcons.sommet,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  entry.trailId,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Flexible(
                child: _StatusBadge(
                  label: statusLabel(entry.localStatus),
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Infos secondaires — Wrap pour ne pas deborder a textScale 2x
          Wrap(
            spacing: AppTheme.spacingBase,
            runSpacing: AppTheme.spacingXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ExcludeSemantics(
                    child: StepIcon(
                      StepwaysIcons.horsLigne,
                      size: 14,
                      color: AppTheme.grisTexteSecondaire,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatFileSize(entry.fileSize),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisTexteSecondaire,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ExcludeSemantics(
                    child: StepIcon(
                      StepwaysIcons.miseAJour,
                      size: 14,
                      color: AppTheme.grisTexteSecondaire,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // FLEXIBLE PARCE QUE LE LIBELLE A GRANDI (tache 610). Il valait
                  // « v5 », il vaut « 28/09/2026 » : a textScale 2x sur un ecran
                  // de 320 points la ligne debordait de 6 points — mesure, pas
                  // supposition, c est le test d accessibilite qui l a dit. Un
                  // texte qui peut se raccourcir vaut mieux qu un debordement, et
                  // mieux qu un libelle raccourci pour tout le monde a cause du
                  // pire cas.
                  Flexible(
                    child: Text(
                      _dateLisible(entry.dataVersion),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisTexteSecondaire,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Bouton action contextuel
          _buildActionButton(context, theme),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme) {
    switch (entry.localStatus) {
      case TrailLocalStatusValues.notDownloaded:
        // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary, pleine largeur
        // (SizedBox width infinity conserve).
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            icon: StepwaysIcons.download,
            label: _CatalogLabels.download,
            onPressed: onDownload,
          ),
        );
      case TrailLocalStatusValues.downloading:
        // SW-SKIN-L3e : ElevatedButton.icon desactive avec spinner -> AppButton
        // primary isLoading:true (spinner interne + desactivation, grammaire
        // unifiee). Pleine largeur (SizedBox width infinity conserve).
        return const SizedBox(
          width: double.infinity,
          child: AppButton(
            isLoading: true,
            label: _CatalogLabels.downloading,
            onPressed: null,
          ),
        );
      case TrailLocalStatusValues.downloaded:
        // Sentier utilisable : action primaire "Entrer" (cablage nav #88246)
        // si onEnter fourni, puis suppression en secondaire.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEnter != null) ...[
              _buildEnterButton(context),
              const SizedBox(height: AppTheme.spacingSm),
            ],
            // SW-SKIN-L3e : OutlinedButton.icon rouge -> AppButton outline avec
            // tone:emergencyRed (teinte texte/icone/bordure = couleur SEMANTIQUE
            // de suppression). Pleine largeur (SizedBox width infinity conserve).
            SizedBox(
              width: double.infinity,
              child: AppButton(
                variant: AppButtonVariant.outline,
                tone: AppTheme.emergencyRed,
                icon: StepwaysIcons.corbeille,
                label: _CatalogLabels.delete,
                onPressed: onDelete,
              ),
            ),
          ],
        );
      case TrailLocalStatusValues.updateAvailable:
        // Donnees locales presentes (une MAJ existe) : "Entrer" reste possible
        // sur la version locale, la MAJ est proposee en secondaire.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEnter != null) ...[
              _buildEnterButton(context),
              const SizedBox(height: AppTheme.spacingSm),
            ],
            // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary, pleine
            // largeur (SizedBox width infinity conserve).
            SizedBox(
              width: double.infinity,
              child: AppButton(
                icon: StepwaysIcons.download,
                label: _CatalogLabels.update,
                onPressed: onUpdate,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Bouton primaire « Preparer » (i18n `catalog.prepare`, design #88246).
  ///
  /// TACHE 639 (bug 2) : il disait « Entrer ». Le sentier est deja telecharge,
  /// donc deja possede — l'action est bien la PREPARATION, et elle porte le meme
  /// verbe que sur la carte du catalogue et sur la fiche du sentier.
  Widget _buildEnterButton(BuildContext context) {
    final t = Translations.of(context);
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        label: t.catalog.a11y.prepareButton(nom: entry.trailId),
        // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage #A5),
        // pleine largeur (SizedBox width infinity conserve). key/Semantics gardees.
        child: AppButton(
          key: ValueKey('trail-enter-${entry.trailId}'),
          icon: StepwaysIcons.programme,
          label: t.catalog.prepare,
          onPressed: onEnter,
        ),
      ),
    );
  }
}

/// Badge de statut colore (chip arrondi).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// LA DATE DE PUBLICATION, TELLE QUE LE RANDONNEUR LA LIT.
///
/// CE QUE CE LIBELLE MONTRAIT AVANT LA TACHE 610, ET POURQUOI C EST MIEUX
/// MAINTENANT. La carte affichait « v1 », « v2 » a cote d une icone de mise a
/// jour : un numero interne de publication, qui ne disait RIEN au randonneur — il
/// ne peut pas savoir si « v2 » date d hier ou de l an dernier. Le modele
/// d horodatage rend ce numero lisible sans rien ajouter : la donnee PORTE sa date.
///
/// [HorodatageServeur.origine] designe un sentier embarque dans l application, qui
/// n a jamais ete publie par un serveur : il n a donc pas de date de mise a jour a
/// montrer, et on ecrit un tiret plutot que le 1er janvier 1970.
String _dateLisible(HorodatageServeur instant) {
  if (instant == HorodatageServeur.origine) return '—';
  final d = instant.date.toLocal();
  final jour = d.day.toString().padLeft(2, '0');
  final mois = d.month.toString().padLeft(2, '0');
  return '$jour/$mois/${d.year}';
}
