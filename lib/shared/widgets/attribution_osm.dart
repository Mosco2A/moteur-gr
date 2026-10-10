/// L ATTRIBUTION OPENSTREETMAP — UNE OBLIGATION, PAS UNE POLITESSE (integration
/// 647, point N01 du chiffrage 608, base #100941).
///
/// CE QUI MANQUAIT, ET CE QUE CELA COUTAIT. Cinq ecrans de l application posent
/// une carte, et les tuiles viennent d OpenStreetMap — en direct
/// (`tile.openstreetmap.org`) comme hors ligne (les `.mbtiles` fabriques par
/// `tool/cartes_hors_ligne`, rendus depuis des donnees OSM). La mention
/// « © OpenStreetMap contributors » n apparaissait dans AUCUN fichier de `lib/`.
/// Or la licence ODbL exige l attribution DES QUE l on distribue ces donnees, et
/// c est exactement ce que fait le lot 648 en embarquant les tuiles dans le
/// telephone. Le manquement devenait donc reel avec ce build, pas theorique.
///
/// UN SEUL ENDROIT, CINQ CARTES. Une mention recopiee cinq fois est une mention
/// qu on oublie de recopier la sixieme. Ce widget est la reponse : toute carte le
/// pose, et un test structurel verifie qu aucune `FlutterMap` ne s en passe.
///
/// DISCRET, MAIS ATTEIGNABLE. `RichAttributionWidget` n affiche qu un petit
/// bouton d information ; la mention et le lien vers la licence s ouvrent au
/// toucher. La carte reste lisible, et le credit reste a un geste — ce que la
/// licence demande.
///
/// LE LIBELLE PASSE PAR SLANG, dans les cinq langues, comme tout le reste de
/// l application. Le nom « OpenStreetMap » lui, ne se traduit pas : c est un nom
/// propre.
///
/// TACHE 761 — LA TRACE AUSSI VIENT D OPENSTREETMAP, ET ELLE EST DISTRIBUEE.
/// Jusqu ici seules les TUILES venaient d OSM ; la mention parlait donc de
/// « donnees cartographiques ». La trace du Mare a Mare Centre est desormais la
/// geometrie de la relation d itineraire 10032398, relevee dans
/// OpenStreetMap et EMBARQUEE dans le binaire
/// (`assets/data/mare_a_mare_centre/track.gpx`). C est
/// une seconde distribution de donnees ODbL, et elle merite d etre nommee pour
/// elle-meme : une mention qui ne parle que du fond de carte laisserait croire
/// que le chemin, lui, vient d ailleurs. D ou la troisieme ligne.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/translations.g.dart';

/// L adresse de la licence, telle qu OpenStreetMap la publie.
const String kUrlLicenceOsm = 'https://www.openstreetmap.org/copyright';

/// La mention d attribution a poser dans les `children` de chaque `FlutterMap`.
class AttributionOsm extends StatelessWidget {
  const AttributionOsm({super.key});

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(
      key: const ValueKey('attribution-osm'),
      alignment: AttributionAlignment.bottomRight,
      // La carte est deja chargee de reperes : l attribution se replie et ne
      // mange pas l ecran.
      showFlutterMapAttribution: false,
      attributions: [
        TextSourceAttribution(
          'OpenStreetMap contributors',
          onTap: () => _ouvrirLaLicence(),
        ),
        TextSourceAttribution(
          t.map.attribution.licence,
          prependCopyright: false,
          onTap: () => _ouvrirLaLicence(),
        ),
        TextSourceAttribution(
          t.map.attribution.traces,
          prependCopyright: false,
          // Reference directe et non fermeture : `unnecessary_lambdas` compte
          // chaque fermeture inutile, et la gate du depot interdit au nombre
          // d avertissements d analyse de monter.
          onTap: _ouvrirLaLicence,
        ),
      ],
    );
  }

  /// OUVRIR LA LICENCE NE DOIT JAMAIS FAIRE TOMBER LA CARTE. Un telephone sans
  /// navigateur, ou qui refuse le lien, rend `false` ou leve : dans les deux cas
  /// la carte continue de vivre, et le credit reste affiche.
  Future<void> _ouvrirLaLicence() async {
    try {
      await launchUrl(
        Uri.parse(kUrlLicenceOsm),
        mode: LaunchMode.externalApplication,
      );
    } on Object catch (_) {
      // Rien : la mention est deja rendue, c est elle qui porte l obligation.
    }
  }
}
