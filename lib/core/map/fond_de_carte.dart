/// LE fond de carte de l'application : le fichier telecharge du sentier s'il
/// est lisible, le reseau sinon. Seul endroit de `lib/` qui construit une
/// couche de tuiles.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/trail_engine.dart';
import 'offline_tile_provider.dart';

/// Identifiant envoye a OpenStreetMap avec chaque tuile demandee au reseau.
const _userAgent = 'com.moteur-gr.app';

/// Le fond de carte d'un sentier, a poser comme premier enfant d'une
/// `FlutterMap`.
///
/// CE QUE LE RANDONNEUR VOIT. Carte du sentier telechargee : le fond vient du
/// fichier, avec ou sans reseau, et aucune tuile n'est demandee a OSM dans les
/// zooms que le fichier couvre. Pas de carte, ou carte abimee : le fond vient
/// du reseau, comme avant. Jamais d'exception, jamais d'ecran en erreur.
///
/// POURQUOI UN WIDGET ET PAS UN PARAMETRE. Les quatre couches de tuiles de
/// l'application recopiaient chacune l'URL d'OSM : c'est ainsi que le fichier
/// telecharge n'a jamais ete lu, sans que personne le voie. La garde
/// `test/structurel/fond_de_carte_decide_test.dart` refuse desormais toute
/// `TileLayer` construite hors de ce fichier.
class FondDeCarte extends ConsumerWidget {
  /// Fond du sentier [trailId].
  const FondDeCarte({super.key, required String this.trailId});

  /// Fond du sentier ACTIF, pour un ecran qui ne recoit pas d'identifiant (la
  /// vignette du journal).
  const FondDeCarte.duSentierActif({super.key}) : trailId = null;

  /// Sentier dont le fichier est lu ; `null` : le sentier actif.
  final String? trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String id = trailId ?? ref.watch(trailIdProvider);
    final choix =
        ref.watch(choixDuFondProvider(id)).value ??
        const FondDuReseau(RaisonDuReseau.enAttente);
    return switch (choix) {
      FondDuReseau() => const _Couche(key: ValueKey('reseau'), choix: null),
      FondDuFichier(:final zoomMin) => Stack(
        children: [
          // Sous le plus petit zoom du fichier, le fichier n'a rien : le
          // reseau prend le relais pour la vue d'ensemble, et seulement la.
          if (zoomMin != null && zoomMin > 0)
            _Couche(
              key: const ValueKey('relais'),
              choix: null,
              zoomMax: zoomMin - 1,
            ),
          _Couche(key: ValueKey(choix), choix: choix, zoomMin: zoomMin),
        ],
      ),
    };
  }
}

/// Une couche de tuiles qui garde le MEME fournisseur toute sa vie.
///
/// Une [TileLayer] lit `widget.tileProvider` a chaque tuile et ne dispose que
/// le dernier recu : un fournisseur recree a chaque reconstruction de la carte
/// (chaque changement de zoom en provoque une) ouvrirait une connexion SQLite
/// de plus a chaque fois, sans jamais fermer les precedentes.
class _Couche extends StatefulWidget {
  const _Couche({super.key, required this.choix, this.zoomMin, this.zoomMax});

  /// `null` : le reseau.
  final FondDuFichier? choix;
  final int? zoomMin;
  final int? zoomMax;

  @override
  State<_Couche> createState() => _CoucheState();
}

class _CoucheState extends State<_Couche> {
  late final TileProvider _fournisseur = OfflineTileProvider.fournisseurPour(
    widget.choix ?? const FondDuReseau(RaisonDuReseau.enAttente),
  );

  @override
  Widget build(BuildContext context) {
    final zoomNatifMax = widget.choix?.zoomMax;
    return TileLayer(
      urlTemplate: OfflineTileProvider.defaultTileUrl,
      userAgentPackageName: _userAgent,
      tileProvider: _fournisseur,
      minZoom: widget.zoomMin?.toDouble() ?? 0,
      maxZoom: widget.zoomMax?.toDouble() ?? double.infinity,
      maxNativeZoom: zoomNatifMax ?? 19,
    );
  }
}
