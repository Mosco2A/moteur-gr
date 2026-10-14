/// Le detail d'un point : photo differee, nom et description traduits,
/// coordonnees, altitude et horaires s'ils existent.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/poi.dart';
import '../../../core/models/water_action.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/lazy_network_image.dart';
import '../../../shared/poi/poi_type_config.dart';
import '../../../shared/poi/poi_type_label.dart';
import '../../../core/branding/stepways_icons.dart';

/// Bottom sheet affichant le detail d'un POI.
///
/// Affiche: photo (lazy, optionnelle), nom i18n, icone/couleur via
/// [PoiTypeConfig], description i18n, coordonnees GPS, altitude, horaires si
/// disponibles, et un bouton de navigation vers la carte centree sur le POI.
class PoiInfoSheet extends StatelessWidget {
  const PoiInfoSheet({super.key, required this.poi, this.imageUrl});

  /// Le POI a afficher.
  final PoiModel poi;

  /// URL optionnelle d'une photo distante (chargee paresseusement).
  ///
  /// Null/vide -> aucun en-tete image (cas par defaut offline-first).
  final String? imageUrl;

  /// Affiche le bottom sheet modal pour un POI donne.
  static Future<void> show(
    BuildContext context,
    PoiModel poi, {
    String? imageUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PoiInfoSheet(poi: poi, imageUrl: imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = PoiTypeConfig.getStyle(
      poi.type,
      waterAction: poi.waterAction,
    );
    // LOT D (554) : la table de correspondance type -> libelle traduit etait
    // PRIVEE ici. Elle est desormais partagee ([poiTypeLabel]) avec la legende
    // de la carte — un seul nom par type, partout.
    final typeName = poiTypeLabel(poi.type);
    final geste = PoiTypeConfig.waterTypes.contains(poi.type)
        ? poi.waterAction
        : null;
    final coordonnees =
        '${poi.lat.toStringAsFixed(5)}, ${poi.lng.toStringAsFixed(5)}';

    // LA FICHE DEFILE (tache 846), ET C'EST LA MEME REGLE QUE LE POPUP.
    //
    // CE QUI S'EST PASSE : les deux lignes du geste ont fait DEBORDER cette
    // colonne de 8,5 pixels sur la fiche d'un point d'eau. Le debordement
    // etait LATENT bien avant elles — la feuille s'ouvre a une fraction de la
    // hauteur de l'ecran, et son contenu est une DONNEE de longueur
    // imprevisible : une description un peu longue suffisait deja.
    //
    // LA REGLE EST DEJA ECRITE DANS CE DEPOT, au popup du marqueur
    // (`poi_popup.dart`, tache 749) : « quand la donnee n'est pas bornee, c'est
    // le CONTENANT QUI DEFILE ». Raboter le geste aurait repousse la coupure
    // d'une ligne ; la faire defiler la supprime.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poignee de drag
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Photo distante optionnelle (chargee paresseusement, cache disque)
            if (imageUrl != null && imageUrl!.trim().isNotEmpty) ...[
              LazyNetworkImage(
                imageUrl: imageUrl,
                height: 160,
                width: double.infinity,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 16),
            ],

            // En-tete: icone + nom + type
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: style.color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: StepIcon(style.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        typeName,
                        style: TextStyle(color: style.color, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // LE GESTE A FAIRE AVANT DE BOIRE, DEVANT LA DESCRIPTION (846).
            //
            // DEVANT, et pas en bas de fiche : c'est la seule ligne qui peut
            // changer ce que le marcheur fait dans la minute. La description
            // raconte le lieu, le geste dit s'il peut remplir sa gourde.
            //
            // ET LA PRECAUTION SE DIT. Quand le geste n'est pas un releve
            // mais le repli de prudence (`WaterAction.parPrudence`), une
            // seconde ligne l'ecrit : on demande de filtrer parce que la
            // donnee ne dit rien, et le marcheur a le droit de savoir qu'il
            // lit une precaution et non une mesure. Sans elle, « a filtrer »
            // passerait pour un constat.
            if (geste != null) ...[
              const SizedBox(height: 16),
              Text(
                _libelleDuGeste(geste),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: style.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (poi.waterActionIsPrecaution) ...[
                const SizedBox(height: 4),
                Text(
                  t.poi.waterAction.precaution,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],

            // Description
            if (poi.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                poi.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            const SizedBox(height: 16),

            // Coordonnees GPS
            _InfoRow(
              icon: StepwaysIcons.maPosition,
              label: t.stage.coordinates,
              value: coordonnees,
            ),

            // Altitude
            if (poi.altitudeM > 0)
              _InfoRow(
                icon: StepwaysIcons.sommet,
                label: t.poi.altitude,
                value: '${poi.altitudeM} m',
              ),

            // Horaires
            if (poi.openingHours != null && poi.openingHours!.isNotEmpty)
              _InfoRow(
                icon: StepwaysIcons.clock,
                label: t.poi.hours,
                value: poi.openingHours!,
              ),

            const SizedBox(height: 20),

            // Bouton Voir sur carte
            // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage
            // #A5), pleine largeur (SizedBox width infinity conserve,
            // iso-rendu).
            SizedBox(
              width: double.infinity,
              child: AppButton(
                icon: StepwaysIcons.map,
                label: t.map.viewMap,
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/map?trailId=${poi.trailId}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le geste a faire, en clair et dans la langue du marcheur (tache 846).
///
/// QUATRE CAS ET QUATRE PHRASES : un `switch` exhaustif, pas de `default`. Le
/// jour ou un cinquieme geste apparaitra, l'analyseur refusera de compiler
/// plutot que de laisser ce point d'eau muet a l'ecran.
String _libelleDuGeste(WaterAction geste) => switch (geste) {
  WaterAction.drinkAsIs => t.poi.waterAction.drinkAsIs,
  WaterAction.filter => t.poi.waterAction.filter,
  WaterAction.treatOrBoil => t.poi.waterAction.treatOrBoil,
  WaterAction.doNotDrink => t.poi.waterAction.doNotDrink,
};

/// Ligne d'information icone + label + valeur.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          StepIcon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label : ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
