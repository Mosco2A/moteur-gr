import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/services/mise_a_jour_a_la_source.dart';
import '../../features/planning/providers/lieux_en_base_provider.dart';
import '../../i18n/translations.g.dart';

/// « RAFRAICHIR » — LE TROISIEME MOMENT DEMANDE PAR CHRISTOPHE (tache 641).
///
/// « au demarrage, a l ouverture d un sentier et sur un rafraichissement manuel »
/// : les deux premiers sont automatiques (`miseAJourAuDemarrageProvider`,
/// `miseAJourAlOuvertureProvider`), celui-ci est le geste. Il existe pour une
/// raison precise : quand Christophe corrige une donnee en base depuis son PC, il
/// veut la VOIR arriver sur le telephone sans attendre la cadence de quatre
/// heures ni redemarrer l application. C est le meme scenario d acceptation que
/// celui du compte en base (lot 631).
///
/// CE BOUTON DIT TOUJOURS CE QU IL A FAIT, ET C EST LA MOITIE DE SON UTILITE. Un
/// rafraichissement muet est indistinguable d un bouton mort : le randonneur
/// appuie, rien ne change a l ecran parce qu il n y avait rien a prendre, et il ne
/// sait pas si l application a travaille. Les trois reponses possibles sont donc
/// dites : ce qui est arrive, « deja a jour », ou « pas de reseau ».
class BoutonRafraichirDepuisLaBase extends ConsumerStatefulWidget {
  const BoutonRafraichirDepuisLaBase({super.key, required this.trailId});

  /// Le sentier a rafraichir.
  final String trailId;

  @override
  ConsumerState<BoutonRafraichirDepuisLaBase> createState() =>
      _BoutonRafraichirDepuisLaBaseState();
}

class _BoutonRafraichirDepuisLaBaseState
    extends ConsumerState<BoutonRafraichirDepuisLaBase> {
  bool _enCours = false;

  @override
  Widget build(BuildContext context) {
    // Le `t` GLOBAL, pour la meme raison que [LigneDeLieu] : ce bouton vit dans
    // une barre de titre, montee par des tests qui n enveloppent pas
    // forcement l arbre d un `TranslationProvider`.
    return IconButton(
      key: const ValueKey('rafraichir-depuis-la-base'),
      // PENDANT LE TRAVAIL, LE BOUTON DEVIENT UN INDICATEUR — il ne reste pas
      // appuyable. Deux appuis coup sur coup lanceraient deux descentes
      // concurrentes sur le meme sentier, et la seconde trouverait la premiere en
      // train d ecrire.
      onPressed: _enCours ? null : _rafraichir,
      tooltip: t.lieu.rafraichir,
      icon: _enCours
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const StepIcon(StepwaysIcons.rafraichir, size: 20),
    );
  }

  Future<void> _rafraichir() async {
    setState(() => _enCours = true);
    final bilan = await ref
        .read(miseAJourALaSourceProvider)
        .surDemandeDuRandonneur(widget.trailId);
    if (!mounted) return;
    setState(() => _enCours = false);

    // LES PROVIDERS QUI LISENT LA BASE SONT INVALIDES, SINON L ECRAN MENTIRAIT.
    // La descente a ecrit dans SQLite ; les lectures de `trail_pois` sont des
    // `FutureProvider` deja resolus, qui ne se relisent pas d eux-memes. Sans
    // cette invalidation le bouton aurait pourtant tout fait correctement et
    // l ecran serait reste identique — le pire des cas, parce qu il ressemble a
    // un bouton mort.
    if (bilan.aPrisQuelqueChose) {
      ref.invalidate(lieuxDuSentierEnBaseProvider(widget.trailId));
    }

    final messager = ScaffoldMessenger.maybeOf(context);
    if (messager == null) return;
    final message = bilan.horsLigne
        ? t.lieu.rafraichirHorsLigne
        : bilan.echecs.isNotEmpty
        ? t.lieu.rafraichirEchec
        : bilan.aPrisQuelqueChose
        ? t.lieu.rafraichirFait(n: bilan.ecrits + bilan.supprimes)
        : t.lieu.rafraichirDejaAJour;
    messager.showSnackBar(SnackBar(content: Text(message)));
  }
}
