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

  /// POURQUOI LA COUCHE PRINCIPALE A UNE CLE CONSTANTE (tache 751).
  ///
  /// Retour de Christophe du 09/10 10:01, mot pour mot : « En fait il faut
  /// sortir puis revenir sur la carte pour qu'elle s'affiche ». Ce n'etait ni
  /// une absence de fond ni une lenteur : la PREMIERE construction de l'ecran
  /// ne montrait pas les tuiles.
  ///
  /// LA CAUSE, MESUREE. [choixDuFondProvider] est un `FutureProvider` : son
  /// `.value` est `null` AU PREMIER `watch`, et il l'est MEME quand le futur
  /// est deja termine — un `FutureProvider` ne rend jamais sa valeur de facon
  /// synchrone au premier passage. La premiere construction batissait donc
  /// toujours la couche du RESEAU, puis, quand la decision arrivait, ce code
  /// remplacait un `_Couche` par une `Stack` : widget d'un autre type au meme
  /// endroit, donc l'element etait DETRUIT et la [TileLayer] REMONTEE.
  ///
  /// POURQUOI UNE REMONTE NE SE VOIT PAS A L'ECRAN. `flutter_map` 8.3 ne
  /// recharge ses tuiles que sur son flux d'evenements, qui est un
  /// `broadcast` SANS REJEU (`tile_layer.dart` : l'abonnement est pris dans
  /// `didChangeDependencies`), et `_applyInitialCameraFit` n'est appele que
  /// dans la branche « la taille a change » (`widget.dart`). Une [TileLayer]
  /// remontee APRES le cadrage d'ouverture rate donc les evenements qui
  /// l'auraient fait charger, et son `didChangeDependencies` est AVEUGLE a la
  /// taille. Revenir sur l'ecran reglait tout parce que le [MapController] est
  /// partage par un `NotifierProvider` NON `autoDispose` : a la deuxieme
  /// visite la camera est deja posee sur le sentier.
  ///
  /// LA REGLE POSEE ICI. UNE SEULE couche principale, avec une cle CONSTANTE,
  /// presente des la premiere construction et JAMAIS remontee : quand la
  /// decision arrive, c'est son FOURNISSEUR qui change, sur place
  /// (`_CoucheState.didUpdateWidget`). Changer `minZoom` suffit a faire
  /// recharger la [TileLayer] par ses propres moyens.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String id = trailId ?? ref.watch(trailIdProvider);
    final decision = ref.watch(choixDuFondProvider(id)).value;
    // Tant que la decision n'est pas rendue, et pour toutes les raisons de
    // reseau, le fond vient du reseau : `null` dit exactement cela.
    final fichier = decision is FondDuFichier ? decision : null;
    final zoomMin = fichier?.zoomMin;
    return Stack(
      children: [
        // Sous le plus petit zoom du fichier, le fichier n'a rien : le
        // reseau prend le relais pour la vue d'ensemble, et seulement la.
        if (zoomMin != null && zoomMin > 0)
          _Couche(
            key: const ValueKey('relais'),
            choix: null,
            zoomMax: zoomMin - 1,
          ),
        _Couche(key: const ValueKey('fond'), choix: fichier, zoomMin: zoomMin),
      ],
    );
  }
}

/// Une couche de tuiles qui garde le meme fournisseur TANT QUE LA DECISION NE
/// CHANGE PAS — et qui en fabrique un neuf, sur place, quand elle change.
///
/// Une [TileLayer] lit `widget.tileProvider` a chaque tuile et ne dispose que
/// le dernier recu : un fournisseur recree a chaque reconstruction de la carte
/// (chaque changement de zoom en provoque une) ouvrirait une connexion SQLite
/// de plus a chaque fois, sans jamais fermer les precedentes. Le fournisseur
/// ne se refabrique donc QUE sur un changement de [choix], jamais sur une
/// simple reconstruction.
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
  late TileProvider _fournisseur = _fabriquer();

  TileProvider _fabriquer() => OfflineTileProvider.fournisseurPour(
    widget.choix ?? const FondDuReseau(RaisonDuReseau.enAttente),
  );

  /// LA DECISION ARRIVE APRES : LE FOURNISSEUR SUIT, SANS REMONTER LA COUCHE
  /// (tache 751).
  ///
  /// C'est tout le correctif. La couche est batie avant que le choix
  /// fichier-ou-reseau soit rendu — c'est inevitable, la decision lit le
  /// disque. Elle ne doit donc pas etre FIGEE sur le fournisseur de l'attente :
  /// quand le choix arrive, on fabrique le bon fournisseur et la [TileLayer]
  /// le prend en place. `minZoom` change du meme coup, ce qui suffit a lui
  /// faire vider et recharger ses tuiles par ses propres moyens.
  @override
  void didUpdateWidget(_Couche ancien) {
    super.didUpdateWidget(ancien);
    if (widget.choix == ancien.choix) return;
    final remplace = _fournisseur;
    _fournisseur = _fabriquer();
    // LE FOURNISSEUR REMPLACE EST A NOUS. Une [TileLayer] ne dispose que le
    // DERNIER fournisseur recu : celui qu'on retire ne serait ferme par
    // personne, et une connexion SQLite ou un client HTTP fuirait a chaque
    // decision. On le ferme APRES la frame, pour laisser la [TileLayer]
    // remplacer d'abord les images qui en venaient — les fermer sous leur
    // chargement en cours ferait echouer des tuiles pour rien.
    final aFermer = remplace;
    WidgetsBinding.instance.addPostFrameCallback((_) => aFermer.dispose());
  }

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
