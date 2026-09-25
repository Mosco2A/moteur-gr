import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/models/tip_card.dart';

/// Liste a PUCES des points d'une fiche conseil (tache 555).
///
/// Une fiche au calibre porte cinq points autonomes et chiffres, pas un
/// paragraphe : on les rend en puces, une puce par point, comme les fiches
/// FC01-FC25 du GR20. Le contenu vient de [TipCard.localizedPoints] — donc en
/// cinq langues, avec repli FR, et repli sur le paragraphe historique quand une
/// fiche n'est pas encore convertie (jamais d'affichage vide).
///
/// [maxPoints] limite l'apercu (ex. 3 puces en liste, tout au deploiement) ;
/// null affiche tous les points. Aucun texte n'est tronque : une puce se replie
/// sur plusieurs lignes (retour Chris sur les textes coupes).
class TipPointsList extends StatelessWidget {
  const TipPointsList({
    super.key,
    required this.points,
    this.maxPoints,
    this.bulletColor,
    this.textStyle,
  });

  /// Construit la liste depuis une fiche (contenu localise).
  TipPointsList.fromCard({
    super.key,
    required TipCard card,
    this.maxPoints,
    this.bulletColor,
    this.textStyle,
  }) : points = card.localizedPoints;

  /// Points a afficher, deja localises.
  final List<String> points;

  /// Nombre maximum de puces affichees (null = toutes).
  final int? maxPoints;

  /// Couleur de la puce (defaut : couleur primaire du theme).
  final Color? bulletColor;

  /// Style du texte de puce (defaut : bodyMedium, interligne aere).
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.isEmpty) return const SizedBox.shrink();

    final shown = maxPoints == null || maxPoints! >= points.length
        ? points
        : points.take(maxPoints!).toList(growable: false);
    final color = bulletColor ?? theme.colorScheme.primary;
    final style =
        textStyle ?? theme.textTheme.bodyMedium?.copyWith(height: 1.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final point in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                // Expanded + pas de maxLines : le point se replie, il ne se
                // coupe jamais.
                Expanded(child: Text(point, style: style)),
              ],
            ),
          ),
      ],
    );
  }
}
