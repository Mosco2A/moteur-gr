/// Les trois gestes de la carte — zoomer, dezoomer, se recentrer — empiles a
/// portee de pouce.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../../i18n/translations.g.dart';
import '../../../../../core/branding/stepways_icons.dart';
import '../centre_de_la_moitie_haute.dart';

/// Controles de carte — zoom in, zoom out, centrer sur moi.
///
/// Trois [FloatingActionButton] empiles verticalement (Material 3).
/// Recoit un [MapController] pour piloter le zoom et un callback
/// [onCenterOnMe] pour recentrer sur la position utilisateur.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.mapController,
    required this.onCenterOnMe,
  });

  /// Controleur FlutterMap v8 pour piloter zoom et camera.
  final MapController mapController;

  /// Callback appele lors du tap sur le bouton "centrer sur moi".
  final VoidCallback onCenterOnMe;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Ordre de focus logique (a11y E5.3b) : zoom + -> zoom - -> centrer.
    //
    // LE BOUTON « CHANGER DE PEAU » A ETE RETIRE (tache 570, S4). Il ouvrait le
    // selecteur de peaux en bottom-sheet, c'est-a-dire un choix entre trois
    // peaux dont deux ne changent rien a l'ecran (`cardStyle` et
    // `photoScrimOpacity` ne sont lues par aucun widget, et Grand Air attend
    // encore ses photos). Decision de Chris du 26/09 : « retire ». La carte
    // reprend ses trois gestes de carte, et l'ordre de focus redescend de 0.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(0),
            child: FloatingActionButton.small(
              heroTag: 'mapZoomIn',
              onPressed: _zoomIn,
              tooltip: t.a11y.zoomIn,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const StepIcon(StepwaysIcons.plus),
            ),
          ),
          const SizedBox(height: 8),
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: FloatingActionButton.small(
              heroTag: 'mapZoomOut',
              onPressed: _zoomOut,
              tooltip: t.a11y.zoomOut,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const StepIcon(StepwaysIcons.moins),
            ),
          ),
          const SizedBox(height: 8),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: FloatingActionButton.small(
              heroTag: 'mapCenterOnMe',
              onPressed: onCenterOnMe,
              tooltip: t.a11y.centerOnMe,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const StepIcon(StepwaysIcons.maPosition),
            ),
          ),
        ],
      ),
    );
  }

  void _zoomIn() => _zoomeDe(1);

  void _zoomOut() => _zoomeDe(-1);

  /// ZOOMER NE DOIT PAS CHASSER CE QU'ON REGARDE (tache 794).
  ///
  /// CE QUI SE PASSAIT. Ces deux boutons appelaient
  /// `move(camera.center, zoom ± 1)` : ils gardaient en place le CENTRE DE LA
  /// CAMERA. Depuis la tache 790, le recentrage pose le marcheur au quart de
  /// la hauteur depuis le haut — la regle de Christophe, mot pour mot : « Il
  /// faut la centrer sur les 50% de l'écran du haut » — donc le centre de la
  /// camera n'est PLUS le marcheur : il est un quart de hauteur plus bas,
  /// derriere le panneau de chiffres, invisible. Un zoom autour de ce centre
  /// DOUBLE l'ecart a chaque appui. Mesure sur un cadre de 390 x 844 :
  /// marcheur a 211 px du haut au depart, 0 px apres un appui sur +, −422 px
  /// apres deux, et le marcheur est dehors. Le lot 790 l'avait mesure et
  /// signale sans le corriger.
  ///
  /// CE QUI CHANGE. Le zoom s'appuie sur [ancreDuCentreVisible] : le point de
  /// la carte qui occupe le milieu de la moitie haute, c'est-a-dire le centre
  /// de ce que le randonneur voit vraiment. Ce point-la ne bouge plus d'un
  /// pixel. Juste apres un recentrage, c'est le marcheur — il reste donc
  /// immobile, autant de crans de zoom qu'on veuille. Apres un glissement a
  /// la main, c'est le paysage qu'on regarde, et c'est encore juste : la
  /// regle ne demande jamais ou se trouve le marcheur, et vaut donc meme
  /// quand il est hors du cadre.
  ///
  /// C'EST DEJA CE QUE FONT LES DEUX GESTES AU DOIGT, et c'est la preuve que
  /// la bibliotheque sait faire. Le PINCEMENT a deux doigts s'ancre sur le
  /// point de depart entre les doigts (`_calculatePinchZoomAndMove` retient
  /// `_focalStartLatLng`), et le DOUBLE TAP sur le point tape
  /// (`focusedZoomCenter`, dont le commentaire d'origine dit « keep the same
  /// point of the map visible »). Les deux etaient donc justes, et le sont
  /// restes : rien n'est touche de ce cote. Ces boutons-ci n'avaient, eux,
  /// aucun doigt a suivre — faute de point a tenir, le code d'avant prenait
  /// le centre de camera par defaut. Ils ont desormais le leur.
  ///
  /// LE REPLI, EXPLICITE. Tant que le cadre n'est pas mesure, il n'y a pas de
  /// pixel a interroger : on retombe sur l'ancien geste. Imparfait, mais
  /// jamais a l'infini — et invisible en pratique, puisqu'il faut que la
  /// carte soit batie pour que ces boutons soient a l'ecran.
  void _zoomeDe(double crans) {
    final camera = mapController.camera;
    final nouveauZoom = camera.zoom + crans;
    final ancre = ancreDuCentreVisible(camera);

    if (ancre == null) {
      mapController.move(camera.center, nouveauZoom);
      return;
    }

    mapController.move(
      ancre,
      nouveauZoom,
      offset: decalageVersLeCentreHaut(camera.nonRotatedSize),
    );
  }
}
