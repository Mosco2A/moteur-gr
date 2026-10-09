/// Ce qu'un point raconte quand on le touche : nom, description, altitude et
/// horaires s'ils existent.
library;

import 'package:flutter/material.dart';

import '../../../core/models/poi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import 'poi_marker.dart';
import '../../../core/branding/stepways_icons.dart';

/// Popup affiché au tap sur un marqueur POI.
///
/// Présente le nom en gras, la description,
/// l'altitude et les horaires si disponibles.
/// Card avec ombre, coins arrondis, max 200px de large.
///
/// CE QUE LE LOT 749 A CHANGE ICI. Retour de Christophe du 09/10 08:48,
/// verbatim : « quand on clique sur un icone le texte affiché est tronqué ».
/// C'etait ce popup : le nom etait coupe a deux lignes, la description a trois,
/// les horaires a deux, tous avec des points de suspension — dans une carte de
/// 200 px de large, trois lignes de `bodySmall` ne portent qu'une soixantaine
/// de caracteres. Le reste de la description n'etait atteignable par aucun
/// geste : il n'existait tout simplement pas a l'ecran.
///
/// POURQUOI CE CAS NE SE REGLE PAS COMME UNE TUILE. Le texte d'un point
/// d'interet n'est pas un libelle d'interface qu'on peut mesurer dans cinq
/// langues : c'est une DONNEE, de longueur imprevisible, qui vient du sentier.
/// Lui accorder « deux lignes de plus » ne ferait que deplacer la coupure. La
/// regle du lot prevoit ce cas : quand la donnee n'est pas bornee, c'est le
/// CONTENANT QUI DEFILE. Le popup s'etend donc jusqu'a [_fractionHauteurEcran]
/// de la hauteur de l'ecran — assez pour que la quasi-totalite des points
/// s'affichent d'un coup, sans jamais recouvrir la carte — et au-dela il
/// defile, avec une barre de defilement VISIBLE : sans elle, un texte qui
/// s'arrete au pli se lit exactement comme un texte coupe, et ce serait le
/// meme defaut sous un autre nom.
class PoiPopup extends StatefulWidget {
  const PoiPopup({super.key, required this.poi});

  /// Le POI dont on affiche les détails
  final PoiModel poi;

  /// Part de la hauteur de l'ecran que le popup s'autorise avant de defiler.
  /// Au-dela il masquerait le point qu'il decrit.
  static const double _fractionHauteurEcran = 0.4;

  @override
  State<PoiPopup> createState() => _PoiPopupState();
}

class _PoiPopupState extends State<PoiPopup> {
  /// La barre de defilement doit pouvoir s'accrocher a la zone qu'elle
  /// represente : `thumbVisibility` exige un controleur explicite.
  final ScrollController _defilement = ScrollController();

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poi = widget.poi;
    final theme = Theme.of(context);
    final color = PoiMarker.colorFor(poi.type);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 200,
        maxHeight:
            MediaQuery.sizeOf(context).height * PoiPopup._fractionHauteurEcran,
      ),
      // SW-SKIN-L3e : Card -> AppCard. elevation 6 conservee ; le rayon de
      // carte (radiusCard) est le defaut d'AppCard ; padding md porte par
      // AppCard (iso-rendu du popup POI, contrainte maxWidth 200 inchangee).
      child: AppCard(
        elevation: 6,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Scrollbar(
          controller: _defilement,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _defilement,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : icône + nom
                Row(
                  children: [
                    StepIcon(
                      PoiMarker.iconFor(poi.type),
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    // Le nom passe a la ligne autant de fois qu'il le faut :
                    // l'`Expanded` lui donne la largeur, la colonne qui defile
                    // lui donne la hauteur.
                    Expanded(
                      child: Text(
                        poi.name,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Description — ECRITE EN ENTIER (tache 749). Elle disait
                // `maxLines: 3` + ellipsis : au-dela d'une soixantaine de
                // caracteres, la fin du texte n'existait plus a l'ecran.
                if (poi.description.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(poi.description, style: theme.textTheme.bodySmall),
                ],

                // Altitude
                if (poi.altitudeM > 0) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: [
                      const StepIcon(
                        StepwaysIcons.sommet,
                        size: 14,
                        color: AppTheme.grisTexteSecondaire,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        '${poi.altitudeM} m',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.grisTexteSecondaire,
                        ),
                      ),
                    ],
                  ),
                ],

                // Horaires
                if (poi.openingHours != null) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      const StepIcon(
                        StepwaysIcons.clock,
                        size: 14,
                        color: AppTheme.grisTexteSecondaire,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Expanded(
                        child: Text(
                          poi.openingHours!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.grisTexteSecondaire,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
