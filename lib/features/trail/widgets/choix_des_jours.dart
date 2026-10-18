/// Le choix de l'allure, et ce que chaque allure coute EN INDICE DE TERRAIN.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// LE NOMBRE DE JOURS, CE QUE CHAQUE ALLURE COUTE, ET LE MOT « CONSEILLE ».
///
/// Christophe, 17/10 11:02 : « mais le nombre de jour, c'est du conseille,
/// apres le client le fait dans le nombre de jours qu'il veut ». Le mot est
/// donc AFFICHE, et l'allure du sentier est marquee comme le conseil qu'elle
/// est — pas comme une caracteristique du chemin.
///
/// CHAQUE ALLURE PORTE L'INDICE DE SA PIRE JOURNEE, ET AUCUN MOT. L'echelle de
/// mots annoncee le 17/10 11:05 est morte a la mesure (les quatre allures du
/// GR20 sortaient le meme mot), et le kilometre-effort qui l'alimentait est
/// retire par la tache 858 : il etait faux. Ce qui reste est le NOMBRE, et il
/// parle : serrer l'allure ne change pas le chemin, il concentre la meme
/// montagne sur moins de journees.
class ChoixDesJours extends StatelessWidget {
  /// Le selecteur d'allure, ce que chaque allure coute, et la phrase qui dit
  /// que le nombre de jours est un conseil.
  const ChoixDesJours({
    super.key,
    required this.allures,
    required this.choisie,
    required this.conseillee,
    required this.onChoisi,
    this.indiceDeLaPireJournee,
  });

  /// Les allures offertes, en jours, triees.
  final List<int> allures;

  /// L'allure actuellement choisie.
  final int choisie;

  /// L'allure CONSEILLEE par le sentier.
  final int conseillee;

  /// Appele quand le lecteur choisit une autre allure.
  final ValueChanged<int> onChoisi;

  /// L'INDICE DE TERRAIN DE LA PIRE JOURNEE D'UNE ALLURE, en points.
  ///
  /// Nul quand l'appelant ne sait pas le dire — un sentier sans trace ou sans
  /// nuits relevees —, et alors chaque allure n'affiche que son nombre de
  /// jours. On prefere la ligne muette au chiffre invente.
  final double? Function(int jours)? indiceDeLaPireJournee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre de jours CONSEILLE : $conseillee jours',
          key: const ValueKey('jours-conseilles'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'C\'est un conseil, pas une caracteristique du sentier : vous le '
          'marchez dans le nombre de jours que vous voulez, et l\'indice '
          'ci-dessous suit votre choix.',
          key: const ValueKey('les-jours-sont-un-conseil'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisTexteSecondaire,
          ),
        ),
        if (allures.length >= 2) ...[
          const SizedBox(height: AppTheme.spacingXs),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingXs,
            children: [
              for (final jours in allures)
                ChoiceChip(
                  key: ValueKey('allure-$jours'),
                  label: _EtiquetteDUneAllure(
                    jours: jours,
                    conseillee: jours == conseillee,
                    choisie: jours == choisie,
                    indice: indiceDeLaPireJournee?.call(jours),
                  ),
                  selected: jours == choisie,
                  onSelected: (_) => onChoisi(jours),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          // LA LEGENDE DU CHIFFRE, parce qu'un nombre sans son sens est pire
          // qu'un mot : il a l'air d'une mesure du sentier alors qu'il mesure
          // une ALLURE. Elle nomme aussi l'unite une seule fois, plutot que de
          // la repeter sur chaque pastille.
          Text(
            'Sous chaque allure : l\'indice de terrain de sa journee la plus '
            'dure (un point = un kilometre de plat). Serrer l\'allure ne '
            'change pas le chemin, il concentre la meme montagne sur moins de '
            'journees.',
            key: const ValueKey('ce-que-l-allure-coute'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
        ],
      ],
    );
  }
}

/// L'ETIQUETTE D'UNE ALLURE : son nombre de jours, puis ce qu'elle coute.
///
/// DEUX LIGNES ET PAS UNE. « 7 jours · 55,3 » sur une seule ligne fabrique des
/// pastilles si larges qu'elles passent a la ligne une par une : l'ecart entre
/// les allures ne se voit plus d'un coup d'oeil, et c'est precisement ce que
/// cette ligne existe pour montrer.
class _EtiquetteDUneAllure extends StatelessWidget {
  const _EtiquetteDUneAllure({
    required this.jours,
    required this.conseillee,
    required this.choisie,
    required this.indice,
  });

  /// L'allure, en jours.
  final int jours;

  /// VRAI quand c'est l'allure conseillee par le sentier.
  final bool conseillee;

  /// VRAI quand c'est l'allure actuellement retenue.
  final bool choisie;

  /// L'indice de terrain de la pire journee de cette allure, nul s'il n'est
  /// pas mesure.
  final double? indice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pire = indice;
    final chiffre = pire == null ? null : nombreAUneDecimale(pire);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          conseillee ? '$jours jours (conseille)' : '$jours jours',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: choisie ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        if (chiffre != null)
          Text(
            chiffre,
            key: ValueKey('indice-de-l-allure-$jours'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
              fontWeight: choisie ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
      ],
    );
  }
}

/// Un nombre a une decimale, ecrit a la francaise.
///
/// La fiche se lit en francais : « 50,0 », pas « 50.0 ».
String nombreAUneDecimale(double valeur) =>
    valeur.toStringAsFixed(1).replaceAll('.', ',');
