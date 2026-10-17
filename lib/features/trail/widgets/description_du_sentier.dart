/// La description d'un sentier en trois questions, et rien du tout quand elle
/// n'est pas ecrite.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/models/fiche_de_sentier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_header.dart';

/// LA DESCRIPTION, TELLE QUE LE RANDONNEUR LA LIT AVANT DE SE DECIDER.
///
/// TROIS TITRES ET PAS UN PAVE, et les trois sont les questions mot pour mot de
/// la demande de Christophe du 17/10 : OU C'EST, CE QU'ON Y VOIT, A QUOI
/// S'ATTENDRE. Un bloc de prose unique aurait ete plus simple a ecrire et plus
/// difficile a lire : on cherche « c'est ou » et on tombe sur un paragraphe sur
/// les refuges.
///
/// CHAQUE PARTIE S'AFFICHE SEULE SI ELLE EST SEULE A EXISTER. Une description a
/// moitie ecrite montre la moitie qui existe — elle n'attend pas d'etre
/// complete, et elle ne reserve pas la place des deux autres.
class DescriptionDuSentier extends StatelessWidget {
  /// La [description] lue dans le manifeste. Vide = rien d'affiche.
  const DescriptionDuSentier({super.key, required this.description});

  /// Le texte lu dans le manifeste du sentier.
  final DescriptionDeSentier description;

  @override
  Widget build(BuildContext context) {
    if (description.estVide) return const SizedBox.shrink();

    return Padding(
      key: const ValueKey('description-du-sentier'),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Le sentier', icon: StepwaysIcons.panneau),
          _Partie(titre: 'Ou c\'est', texte: description.ouCest),
          _Partie(titre: 'Ce qu\'on y voit', texte: description.ceQuOnYVoit),
          _Partie(
            titre: 'A quoi s\'attendre',
            texte: description.aQuoiSAttendre,
          ),
        ],
      ),
    );
  }
}

/// Une des trois parties. Vide, elle ne laisse aucune trace.
class _Partie extends StatelessWidget {
  const _Partie({required this.titre, required this.texte});

  final String titre;
  final String texte;

  @override
  Widget build(BuildContext context) {
    if (texte.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(texte, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
