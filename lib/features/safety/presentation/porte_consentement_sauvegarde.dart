import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/refus_sauvegarde_systeme_provider.dart';
import 'refus_sauvegarde_systeme_dialog.dart';

/// LA QUESTION DE LA SAUVEGARDE EST POSEE A L'OUVERTURE, A TOUT LE MONDE, UNE
/// SEULE FOIS (tache 617).
///
/// ---------------------------------------------------------------------------
/// LE TROU QUE CE WIDGET FERME, ET IL AVAIT ETE NOMME PAR SON AUTEUR
/// ---------------------------------------------------------------------------
///
/// La tache 612 ne presentait la case qu'APRES une connexion Google, sur l'ecran
/// de profil, et son bilan listait le trou en toutes lettres : « la case n'est
/// presentee qu'a la connexion Google. Le randonneur anonyme ne la voit jamais :
/// il est protege par le defaut, mais il ne peut pas choisir la commodite. A
/// arbitrer. »
///
/// La regle generale de Christophe du 28/09 14:31 tranche l'arbitrage sans le
/// nommer : « on ne partage aucune donnee confiee sauf si le client decoche
/// volontairement ». Il faut donc que le client PUISSE decocher — et la moitie
/// des randonneurs qui ne se connectent jamais n'en avaient pas l'occasion. La
/// question est posee ici, a l'ouverture.
///
/// ---------------------------------------------------------------------------
/// POSER LA QUESTION N'EST PAS PROTEGER, ET L'ORDRE DES DEUX COMPTE
/// ---------------------------------------------------------------------------
///
/// La protection s'applique AVANT que ce widget n'existe a l'ecran
/// ([kRefusSauvegardeSystemeParDefaut] = refus), et c'est ce qui autorise a poser
/// la question apres le premier rendu au lieu de bloquer le demarrage. Un
/// randonneur qui ferme l'application sans repondre est protege ; il sera
/// simplement reinterroge au lancement suivant, parce qu'aucune decision n'a ete
/// enregistree.
///
/// ---------------------------------------------------------------------------
/// LE PATRON EST CELUI D'`OrphanSessionReprise`, ET CE N'EST PAS UN HASARD
/// ---------------------------------------------------------------------------
///
/// Meme place dans l'arbre (sous le `builder` de `MaterialApp.router`, donc sous
/// un `Navigator`), meme declenchement en post-frame (`showDialog` a besoin d'un
/// `Navigator` monte, et l'arbre route est en cours de premier rendu), meme garde
/// contre le double affichage. Un widget qui ouvre un dialogue pendant `build`
/// leve ; un widget qui ne se garde pas en ouvre deux.
///
/// TRANSPARENT QUAND IL N'Y A RIEN A DEMANDER : il rend simplement [child].
class PorteConsentementSauvegarde extends ConsumerStatefulWidget {
  const PorteConsentementSauvegarde({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PorteConsentementSauvegarde> createState() =>
      _PorteConsentementSauvegardeState();
}

class _PorteConsentementSauvegardeState
    extends ConsumerState<PorteConsentementSauvegarde> {
  /// La question a-t-elle deja ete declenchee dans CETTE session ? Sans ce
  /// drapeau, chaque reconstruction de l'arbre route en ouvrirait une nouvelle.
  bool _demandee = false;

  @override
  void initState() {
    super.initState();
    // POST-FRAME, PAS DANS `initState` DIRECTEMENT : `showDialog` exige un
    // `Navigator` monte, et il ne l'est pas encore quand cette porte s'installe.
    WidgetsBinding.instance.addPostFrameCallback((_) => _demander());
  }

  Future<void> _demander() async {
    if (_demandee || !mounted) return;
    _demandee = true;
    // `poserSiNecessaire` lit lui-meme si la decision est deja prise : cette
    // porte n'a pas a le savoir, et le dedoublement de cette lecture serait le
    // debut de deux verites.
    await RefusSauvegardeSystemeDialog.poserSiNecessaire(context, ref);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
