/// LES QUATRE LECTURES D'UN PLAN A L'ECRAN — et aucune note de tronçon.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/journees_pesees.dart';
import 'choix_des_jours.dart';

/// LES QUATRE LECTURES D'UN PLAN, AFFICHEES SANS AUCUN TOTAL (tache 860).
///
/// ON NE SOMME JAMAIS, ON DECRIT. Ce bloc est le niveau AU-DESSUS de la
/// journee : le sentier, ou l'un de ses deux chapitres, a l'allure choisie. Il
/// ne porte PAS de note — un total de notes serait credible et completement
/// faux, et c'est precisement pour cela qu'il est interdit. Il porte les quatre
/// lectures prises sur les journees, et le NOMBRE DE JOURS vient en premier
/// parce que sans lui les trois autres ne veulent rien dire.
class LecturesDuPlanAffichees extends StatelessWidget {
  /// Les quatre lectures a afficher.
  const LecturesDuPlanAffichees({super.key, required this.lectures});

  /// Les quatre lectures du plan courant.
  final LecturesDuPlan lectures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (lectures.nombreDeJours == 0) return const SizedBox.shrink();

    // LES NOMBRES SONT MIS EN FORME HORS DES CHAINES : la garde de code mort
    // lit les identifiants apres avoir retire les chaines, donc un appel ecrit
    // dans un `${...}` lui est invisible.
    final pire = nombreAUneDecimale(lectures.pireJournee);
    final type = nombreAUneDecimale(lectures.journeeType);
    final dures = lectures.journeesDures.toString();
    final enchainement = lectures.plusLongEnchainementDeJourneesDures
        .toString();
    final pireRaide = nombreAUneDecimale(lectures.pireJourneeEnRaideur);
    final typeRaide = nombreAUneDecimale(lectures.journeeTypeEnRaideur);

    return Column(
      key: const ValueKey('lectures-du-plan'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sur ${lectures.nombreDeJours} jours de marche :',
          key: const ValueKey('lecture-nombre-de-jours'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'en effort, journee la plus dure $pire sur 20 et journee type '
          '$type sur 20.',
          key: const ValueKey('lecture-pire-et-type'),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        // LA MEME LECTURE SUR LE SECOND AXE, ET ELLE N'EST PAS DECORATIVE :
        // sur une semaine de GR20 l'axe effort ne porte que 1,65 point
        // d'etendue quand la raideur en porte plus de dix. Lire une semaine
        // sur le seul effort, c'est lire une semaine plate.
        Text(
          'en raideur, la plus raide $pireRaide sur 20 et la journee type '
          '$typeRaide sur 20.',
          key: const ValueKey('lecture-raideur'),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          lectures.journeesDures == 0
              ? 'Aucune journee au-dessus de la journee type.'
              : '$dures journees au-dessus de la journee type, dont '
                    '$enchainement d\'affilee.',
          key: const ValueKey('lecture-journees-dures'),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        // CE QUE CE BLOC N'AFFICHE PAS, ET POURQUOI C'EST DIT AU LECTEUR : il
        // n'y a pas de note du sentier. Le taire laisserait croire a un oubli.
        Text(
          'Un sentier n\'a pas de note : seules les journees en ont. '
          'Additionner des notes ne voudrait rien dire.',
          key: const ValueKey('pas-de-note-de-sentier'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisTexteSecondaire,
          ),
        ),
      ],
    );
  }
}
