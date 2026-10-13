/// LA PLACE QUE LA PASTILLE SOS PREND EN BAS DE L'ECRAN, MESUREE (tache 836).
///
/// ---------------------------------------------------------------------------
/// LE DEFAUT, ET POURQUOI IL N'ETAIT PAS LA OU ON LE CROYAIT
/// ---------------------------------------------------------------------------
///
/// Sur le paquet du 11/10, la pastille rouge recouvrait trois libelles du
/// cockpit : le sous-titre de la tuile « Adapter l'itineraire », le bouton
/// « Terminer le trek » et le titre « Informations ». Le bouton n'etait
/// pourtant ni trop grand ni mal place : la tache 801 avait deja MESURE qu'il
/// est entier et correctement decolle du bord.
///
/// LA CAUSE EST UNE SOUSTRACTION QUE PERSONNE NE FAISAIT. Dans le cockpit, le
/// SOS est le `floatingActionButton` du `Scaffold`, en `startFloat`. Un FAB
/// FLOTTE : il est peint PAR-DESSUS le `body`, et il ne retire rien a la place
/// que le `body` croit avoir. Le `ListView` du cockpit n'avait que son padding
/// de 16 points en bas, alors que la pastille occupe une bande de sa propre
/// hauteur plus la marge que le `Scaffold` lui laisse. Tout ce qui finissait
/// dans cette bande passait SOUS le disque rouge.
///
/// ET EN PHASE RANDO, RIEN NE VENAIT S'INTERPOSER. Hors rando, l'emplacement
/// publicitaire occupe le bas et eloigne le contenu ; en rando il est
/// volontairement absent — « le bas de l'ecran appartient a la pastille SOS ».
/// C'est donc exactement dans la phase ou le SOS est visible que le contenu
/// montait le plus haut sous lui.
///
/// ---------------------------------------------------------------------------
/// POURQUOI RESERVER LA PLACE, ET NON DEPLACER LE BOUTON
/// ---------------------------------------------------------------------------
///
/// Deplacer le bouton a deja ete essaye, et c'est ce qui a produit le defaut
/// d'aujourd'hui : au coin bas-DROIT il se posait sur la fin du bouton
/// « Terminer le trek », on l'a mis en bas-GAUCHE, et le recouvrement a
/// simplement change de cote. Un bouton de SECOURS ne se deplace pas pour
/// esquiver du texte : il reste la ou le pouce l'attend, au MEME endroit que
/// sur la carte, et c'est au contenu de ne pas monter dessous. `startFloat` est
/// d'ailleurs verrouille par `test/features/safety/sos_acces_unique_fix2_test
/// .dart`, qui exige la chaine litterale dans le source du cockpit.
///
/// LA HAUTEUR EST MESUREE, PAS DEVINEE. Elle depend de la taille du bouton, de
/// la marge que le `Scaffold` lui laisse et de l'echelle de texte du
/// telephone : aucune constante ecrite a la main ne peut rester juste. Le
/// patron est celui
/// de `MesureDeLaBarre` (`cadrage_de_l_arrivee.dart`), qui releve la hauteur
/// reelle d'un enfant en post-frame et la publie dans un provider.
///
/// ZERO QUAND IL N'Y A RIEN A RESERVER. [SosButton] se masque lui-meme hors
/// rando en rendant un `SizedBox.shrink` : la mesure vaut alors 0 et le cockpit
/// retrouve exactement son padding d'avant. La reserve suit donc la VISIBILITE
/// REELLE du bouton, sans jamais redire la regle qui la decide — c'est le
/// bouton rendu qui est la source, pas une seconde lecture de l'etat du trek.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sos_button.dart';

/// L'ECART ENTRE LE HAUT DE LA PASTILLE ET LE DERNIER LIBELLE, en points.
///
/// Reserver la hauteur exacte du bouton collerait le texte a son bord : le
/// doigt viserait le libelle et trouverait le secours. Un cran d'espacement de
/// la grille rend la frontiere lisible.
const double ecartAuDessusDuSos = 8;

/// LA HAUTEUR DE LA BANDE QUE LA PASTILLE SOS RECOUVRE, en points logiques.
///
/// Zero tant que rien ne l'a mesuree, et zero quand le bouton est masque : une
/// valeur fausse serait pire qu'une valeur absente.
class _ReserveSousLeSosNotifier extends Notifier<double> {
  @override
  double build() => 0;

  /// Publie une hauteur relevee. Sans effet si elle n'a pas change — reecrire
  /// la meme valeur a chaque image reconstruirait ses lecteurs pour rien.
  void mesurer(double hauteur) {
    if (!hauteur.isFinite || hauteur < 0) return;
    if ((hauteur - state).abs() < 0.5) return;
    state = hauteur;
  }
}

/// LA BANDE BASSE A LAISSER LIBRE SOUS LE CONTENU D'UN ECRAN QUI PORTE LE SOS.
///
/// A ajouter au padding bas de la zone qui defile. Vaut 0 quand le bouton n'est
/// pas affiche.
final reserveSousLeSosProvider =
    NotifierProvider<_ReserveSousLeSosNotifier, double>(
      _ReserveSousLeSosNotifier.new,
    );

/// LA PASTILLE SOS, QUI DIT COMBIEN DE PLACE ELLE PREND.
///
/// A poser en `floatingActionButton` a la place de [SosButton] : le rendu est
/// identique — ce widget n'ajoute aucune boite autour du bouton — et la hauteur
/// relevee part dans [reserveSousLeSosProvider].
///
/// LE RELEVE EST FAIT HORS PHASE DE BUILD (post-frame) : la taille d'un widget
/// n'existe qu'une fois la mise en page faite, et ecrire un provider pendant un
/// build est interdit par Riverpod.
class SosQuiReserveSaPlace extends ConsumerStatefulWidget {
  /// Enveloppe la pastille sans rien changer a son rendu.
  const SosQuiReserveSaPlace({super.key});

  @override
  ConsumerState<SosQuiReserveSaPlace> createState() =>
      _SosQuiReserveSaPlaceState();
}

class _SosQuiReserveSaPlaceState extends ConsumerState<SosQuiReserveSaPlace> {
  final GlobalKey _cle = GlobalKey();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hauteur = _cle.currentContext?.size?.height;
      if (hauteur == null) return;
      // LA MARGE DU `Scaffold` COMPTE AUTANT QUE LE BOUTON. Un FAB flottant
      // n'est pas pose au ras du bas : le `Scaffold` le decolle, et c'est la
      // bande ENTIERE — bouton plus decollement plus ecart de lisibilite —
      // qu'un contenu qui defile doit s'interdire.
      final reserve = hauteur <= 0
          ? 0.0
          : hauteur + kFloatingActionButtonMargin + ecartAuDessusDuSos;
      ref.read(reserveSousLeSosProvider.notifier).mesurer(reserve);
    });
    return KeyedSubtree(key: _cle, child: const SosButton());
  }
}
