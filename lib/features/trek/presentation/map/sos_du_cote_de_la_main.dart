/// LE SOS EN HAUT, DU COTE DE LA MAIN QUI VA LE CHERCHER (tache 762).
///
/// ---------------------------------------------------------------------------
/// LA DECISION, ET CE QU'ELLE TRANCHE
/// ---------------------------------------------------------------------------
///
/// VERBATIM DE CHRISTOPHE DU 09/10 16:26 : « SOS en haut tres bien. A droite si
/// droitier, a gauche si gauche ».
///
/// DEUX CHOSES Y SONT DITES. La premiere valide le HAUT, livre a la tache 747
/// apres que sa capture a montre le gros bouton rouge posé sur le trace en bas
/// a gauche. La seconde est neuve : le COTE n'est plus une constante, il
/// suit la main.
///
/// ---------------------------------------------------------------------------
/// CE QUI EXISTAIT DEJA, ET QUI N'ETAIT LU PAR PERSONNE
/// ---------------------------------------------------------------------------
///
/// LE REGLAGE DE LATERALITE ETAIT COMPLET AVANT CE LOT, et il ne servait a
/// RIEN. `DominantHandValues` (`settings` : valeurs `right`/`left`, defaut
/// `right`), le champ de `AppSettings`, son ecriture dans les preferences sous
/// `settings_dominant_hand`, la ligne de reglage de l'ecran de profil, les
/// libelles dans les cinq langues, les tests du service et du notifier, et
/// jusqu'a l'export de la facade : TOUT etait pose. Mais
/// `DominantHandValues.isRight` n'avait AUCUN APPELANT dans `lib/`, et aucun
/// widget ne lisait `dominantHand`.
///
/// LE REGLAGE PROMETTAIT DONC QUELQUE CHOSE QUI N'ARRIVAIT PAS. Son propre
/// libelle francais, mot pour mot : « Place le SOS et les commandes clés du
/// côté de votre main ». Le randonneur gaucher pouvait cocher « Gaucher » et
/// regarder le SOS rester a droite — ou, avant ce lot, a gauche quoi qu'il
/// coche. Ce fichier est le premier lecteur de ce reglage : il ne l'invente
/// pas, il tient sa promesse.
///
/// ---------------------------------------------------------------------------
/// CE QUI NE BOUGE PAS, ET DEUX REFUS DE GARDE DISENT POURQUOI
/// ---------------------------------------------------------------------------
///
/// LE SOS SEUL SE DEPLACE. Les trois boutons du bas ont deja ete remontes
/// ensemble a la tache 747, et la garde des gestes morts
/// (`aucun_geste_mort_573_test.dart`) l'a refuse : le bouton photo reste
/// suspendu pour toujours sur le canal de l'appareil photo en test, et une fois
/// remonte il devient atteignable par le balayage de la garde — qui le trouve
/// muet. En bas, le balayage ne l'atteignait pas. Traiter ce canal n'est pas ce
/// lot ; la photo et les calques restent donc en bas.
///
/// ET IL NE DEPEND DE RIEN. Le poser sur la barre de chiffres avait ete essaye
/// a la 747, et la garde de parite (`map_screen_parite_navigation_test.dart`)
/// l'a refuse : cette barre ne se rend avec ses chiffres QUE lorsqu'une
/// projection sur la trace existe. Le SOS aurait donc attendu un fix GPS pour
/// apparaitre — il aurait disparu exactement dans la situation ou l'on en a
/// besoin. Il reste dans la colonne des bandeaux du haut, sous eux, sans
/// condition : aucune alerte ne peut le recouvrir et il ne peut en recouvrir
/// aucune.
///
/// CE QUE JE N'AI PAS PU MESURER SANS APPAREIL : la recette 753 avait compte le
/// trace passant derriere le disque rouge dans 22 images sur 153, en haut a
/// GAUCHE. Je ne peux pas recompter a droite sans emulateur, et le chiffre
/// dependrait de toute facon du sentier affiche. Ce lot applique la decision de
/// Christophe ; il ne pretend pas avoir remesure le masquage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../safety/safety_facade.dart' show SosButton;
import '../../../settings/settings_facade.dart'
    show DominantHandValues, settingsProvider;

/// Le SOS flottant du haut de la carte, aligne du cote de la main dominante.
class SosDuCoteDeLaMain extends ConsumerWidget {
  /// Cree le SOS lateralise.
  const SosDuCoteDeLaMain({super.key});

  /// La marge qui le decolle du bord, la meme des deux cotes.
  static const double margeLaterale = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // DROITIER PAR DEFAUT, et ce defaut vient du reglage lui-meme
    // (`DominantHandValues.fallback`), pas d'une constante recopiee ici : une
    // valeur de preference illisible ou absente retombe sur la droite par
    // `fromString`, a un seul endroit.
    final droitier = DominantHandValues.isRight(
      ref.watch(settingsProvider.select((s) => s.dominantHand)),
    );

    return Padding(
      padding: const EdgeInsets.only(
        left: margeLaterale,
        right: margeLaterale,
        top: 8,
      ),
      child: Row(
        // LA ROW PREND TOUTE LA LARGEUR ET C'EST SON ALIGNEMENT QUI CHOISIT LE
        // COTE : un seul widget, deux positions, aucune duplication d'arbre. Le
        // bouton lui-meme est identique dans les deux cas — meme widget, meme
        // etat, meme comportement.
        mainAxisAlignment: droitier
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: const [SosButton()],
      ),
    );
  }
}
