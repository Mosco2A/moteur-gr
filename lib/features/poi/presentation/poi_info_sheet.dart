import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/poi.dart';
import '../../../i18n/translations.g.dart';
import '../domain/poi_type_config.dart';

/// Bottom sheet affichant le detail d'un POI.
///
/// Affiche: nom i18n, icone/couleur via [PoiTypeConfig], description i18n,
/// coordonnees GPS, altitude, horaires si disponibles, et un bouton
/// de navigation vers la carte centree sur le POI.
class PoiInfoSheet extends StatelessWidget {
  const PoiInfoSheet({super.key, required this.poi});

  /// Le POI a afficher.
  final PoiModel poi;

  /// Affiche le bottom sheet modal pour un POI donne.
  static Future<void> show(BuildContext context, PoiModel poi) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PoiInfoSheet(poi: poi),
    );
  }

  /// Retourne le nom i18n du type de POI selon la locale courante.
  ///
  /// Utilise les cles de traduction Slang (t.poi.<type>).
  /// Fallback: le labelKey du [PoiTypeConfig] si le type n'a pas de cle i18n.
  String _localizedTypeName(PoiTypeStyle style) {
    final poiT = t.poi;
    switch (poi.type) {
      case 'water':
        return poiT.water;
      case 'refuge':
      case 'shelter':
        return poiT.shelter;
      case 'shop':
        return poiT.shop;
      case 'danger':
        return poiT.danger;
      case 'viewpoint':
        return poiT.viewpoint;
      case 'campsite':
        return poiT.campsite;
      case 'restaurant':
        return poiT.restaurant;
      case 'emergency':
        return poiT.emergency;
      default:
        return style.labelKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = PoiTypeConfig.getStyle(poi.type);
    final typeName = _localizedTypeName(style);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                child: Icon(style.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
            icon: Icons.my_location,
            label: t.stage.coordinates,
            value: '${poi.lat.toStringAsFixed(5)}, ${poi.lng.toStringAsFixed(5)}',
          ),

          // Altitude
          if (poi.altitudeM > 0)
            _InfoRow(
              icon: Icons.terrain,
              label: t.poi.altitude,
              value: '${poi.altitudeM} m',
            ),

          // Horaires
          if (poi.openingHours != null && poi.openingHours!.isNotEmpty)
            _InfoRow(
              icon: Icons.schedule,
              label: t.poi.hours,
              value: poi.openingHours!,
            ),

          const SizedBox(height: 20),

          // Bouton Voir sur carte
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/map?trailId=${poi.trailId}');
              },
              icon: const Icon(Icons.map),
              label: Text(t.map.viewMap),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'information icone + label + valeur.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label : ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
