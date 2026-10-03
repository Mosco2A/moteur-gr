/// Les badges, le selecteur de type et les actions de la carte d'une nuit :
/// les plus petits sous-widgets nommes de la carte (ECR-28).
///
/// L'ETAT RESTE CHEZ L'ECRAN : ils affichent ce qu'on leur passe et rappellent
/// les callbacks de la carte parente.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/branding/stepways_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/stage_accommodation.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/grise_en_demo.dart';
import '../../../../shared/widgets/lien_vers_les_cartes.dart';
import '../../domain/models/nuitee_type.dart';

/// R5 (LOT L10) : la nuit d'un jour de REPOS est bien
/// comptee, au MEME endroit que la veille. On le dit
/// explicitement, sinon deux lignes consecutives
/// affichent le meme hebergement sans explication.
/// Libelle Slang existant (`t.programme.restDay`,
/// 5 langues) — aucune cle nouvelle.
class NuiteeRestDayBadge extends StatelessWidget {
  const NuiteeRestDayBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.grisGranite.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        t.programme.restDay,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.grisGranite,
        ),
      ),
    );
  }
}

/// L7-2 : on dit explicitement que cette nuit-la est
/// celle de l'ARRIVEE sur place, pas une etape. Sans ce
/// libelle, la premiere ligne ressemblerait a une nuit
/// de marche sans hebergement renseigne.
class NuiteeEveBadge extends StatelessWidget {
  const NuiteeEveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.grisGranite.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        t.nuitees.card.eveOfDeparture,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.grisGranite,
        ),
      ),
    );
  }
}

/// Le badge du type de nuitee courant.
class NuiteeTypeBadge extends StatelessWidget {
  const NuiteeTypeBadge({required this.nuiteeType, super.key});

  /// Le type de nuitee choisi pour cette nuit.
  final NuiteeType nuiteeType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondary.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        nuiteeType.label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.secondary,
        ),
      ),
    );
  }
}

/// SELECTEUR DE TYPE — TOUJOURS MODIFIABLE (retour Chris
/// #7, tache 553). Mot pour mot : « reservation nuitee, on
/// ne peut pas revenir a gite », puis, sur la coche :
/// « NON OK = c'est bon ! ».
///
/// CE QUI N'ALLAIT PAS. Les puces de type etaient
/// DESACTIVEES des que la nuit etait cochee : grisees a
/// 35 %, `onTap` a null, et la seule explication tenait
/// dans un `Tooltip` (« decochez pour changer le type »)
/// QUI NE S'AFFICHE PAS SUR MOBILE — un tooltip Material
/// demande un survol souris ou un appui long, deux gestes
/// que personne ne tente sur une puce grisee. Chris a donc
/// vu un ecran qui refusait un retour en arriere, sans un
/// mot pour dire pourquoi, ni comment en sortir.
///
/// ET SURTOUT, LE VERROU REPOSAIT SUR UN CONTRESENS. La
/// coche ne veut pas dire « verrouille » : elle veut dire
/// « c'est bon, cette nuit est reglee ». Faire d'un signe
/// de CONFIRMATION un signe d'INTERDICTION, c'est punir
/// celui qui avance dans sa preparation : on coche ses
/// nuits au fur et a mesure, puis le refuge est complet et
/// il faut passer en gite. Le verrou tombait pile au
/// moment ou le changement devient utile.
///
/// ON CHANGE DONC LE TYPE MEME QUAND LA NUIT EST COCHEE,
/// et la coche SURVIT au changement : `setNuiteeType` et
/// `toggleBooking` ecrivent deux champs distincts
/// (`nuiteeTypes` / `bookings`), changer l'un ne touche
/// pas l'autre. Plus de puce grisee, plus de tooltip
/// invisible : ce qu'on voit est ce qu'on peut faire.
class NuiteeTypePicker extends StatelessWidget {
  const NuiteeTypePicker({
    required this.availableTypes,
    required this.nuiteeType,
    required this.onNuiteeTypeChanged,
    required this.accommodationCount,
    super.key,
  });

  /// Les types proposes par les hebergements de l'etape.
  final Set<NuiteeType> availableTypes;

  /// Le type de nuitee choisi pour cette nuit.
  final NuiteeType nuiteeType;

  /// Rappele quand le randonneur change de type de nuitee.
  final void Function(NuiteeType) onNuiteeTypeChanged;

  /// Combien d'hebergements l'etape propose, pour la mention « n disponibles ».
  final int accommodationCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: availableTypes
              .map(
                (type) => _NuiteeTypeChip(
                  type: type,
                  isSelected: type == nuiteeType,
                  onTap: () => onNuiteeTypeChanged(type),
                ),
              )
              .toList(),
        ),
        if (accommodationCount > 1) ...[
          const SizedBox(height: 4),
          Text(
            t.nuitees.card.available.replaceAll(
              '{count}',
              accommodationCount.toString(),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppTheme.grisGranite.withAlpha(150),
            ),
          ),
        ],
      ],
    );
  }
}

/// Une puce du selecteur de type, toujours cliquable (retour Chris #7).
class _NuiteeTypeChip extends StatelessWidget {
  const _NuiteeTypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  /// Le type que cette puce propose.
  final NuiteeType type;

  /// Vrai quand c'est le type retenu pour la nuit.
  final bool isSelected;

  /// Rappele au tap — la carte parente ecrit le choix.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      child: GriseEnDemo(
        child: GestureDetector(
          onTap: onTap,
          child: Tooltip(
            message: type.label,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary.withAlpha(40)
                    : AppTheme.grisGranite.withAlpha(15),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                border: Border.all(
                  color: isSelected
                      ? scheme.primary
                      : AppTheme.grisGranite.withAlpha(60),
                ),
              ),
              child: _NuiteeTypeChipLabel(type: type, isSelected: isSelected),
            ),
          ),
        ),
      ),
    );
  }
}

/// L'icone et le libelle d'une puce de type.
class _NuiteeTypeChipLabel extends StatelessWidget {
  const _NuiteeTypeChipLabel({required this.type, required this.isSelected});

  /// Le type que la puce propose.
  final NuiteeType type;

  /// Vrai quand c'est le type retenu pour la nuit.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StepIcon(
          type.icon,
          size: 16,
          color: isSelected ? scheme.primary : AppTheme.grisGranite,
        ),
        const SizedBox(width: 3),
        Text(
          type.label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? scheme.primary : AppTheme.grisGranite,
          ),
        ),
      ],
    );
  }
}

/// La case « reserve » a droite de la carte.
class NuiteeBookedMark extends StatelessWidget {
  const NuiteeBookedMark({required this.isBooked, super.key});

  /// Vrai quand la nuit est cochee « reserve ».
  final bool isBooked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isBooked
            ? scheme.primary.withAlpha(30)
            : AppTheme.orangeDifficile.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isBooked
              ? scheme.primary
              : AppTheme.orangeDifficile.withAlpha(80),
          width: 2,
        ),
      ),
      child: StepIcon(
        isBooked ? StepwaysIcons.coche : StepwaysIcons.radio,
        size: 20,
        color: isBooked
            ? scheme.primary
            : AppTheme.orangeDifficile.withAlpha(120),
      ),
    );
  }
}

/// ADRESSE ET POINT GPS CLIQUABLE DE L'HEBERGEMENT (tache 641,
/// bug 15).
///
/// Demande de Christophe du 30/09 10:23, verbatim : « hebergement il
/// doit avoir une adresse et un point GPS qui link sur Maps ». La
/// fiche montrait le nom, le type et le telephone ; ni adresse, ni
/// moyen d'ouvrir les cartes — alors que trouver la porte d'un gite
/// dans un village corse a la tombee du jour est precisement le
/// moment ou l'on en a besoin.
///
/// MASQUE POUR « AUTRE HEBERGEMENT », comme le bouton Appeler : ce
/// choix ne designe aucun etablissement, donc aucun lieu.
class NuiteeAddressLine extends StatelessWidget {
  const NuiteeAddressLine({required this.accom, super.key});

  /// L'hebergement dont on montre l'adresse et le point GPS.
  final StageAccommodation accom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingXs),
      child: LigneDeLieu(
        lieu: LieuCliquable(
          nom: accom.name,
          adresse: accom.address,
          lat: accom.lat,
          lng: accom.lng,
        ),
        compact: true,
      ),
    );
  }
}

/// L'action « Appeler » du lieu de couchage (masquee pour « autre
/// hebergement », parite GR20).
class NuiteeCallRow extends StatelessWidget {
  const NuiteeCallRow({required this.phone, super.key});

  /// Le numero affiche et compose.
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppButton(
          variant: AppButtonVariant.text,
          tone: AppTheme.orangeDifficile,
          icon: StepwaysIcons.telephone,
          iconSize: 18,
          label: t.nuitees.card.call.replaceAll('{phone}', phone),
          labelFontSize: 14,
          isFullWidth: false,
          onPressed: () => _callPhone(phone),
        ),
      ],
    );
  }
}

Future<void> _callPhone(String phoneNumber) async {
  try {
    await launchUrl(Uri.parse('tel:${phoneNumber.replaceAll(' ', '')}'));
  } catch (_) {
    // Silencieux (parite GR20 : pas de blocage si l'appel echoue).
  }
}
