// TACHE 838, VOLET D2 — L'INTERSTITIEL EXISTE, IL A UNE CADENCE, ET IL EST
// BRANCHE.
//
// CE QUE CHRISTOPHE A DEMANDE, MOT POUR MOT : « j en veu une toute les
// demi-heures heures d utilisation ». Et la limite du meme jour : « IL N Y A
// PAS DE PUB POSSIBLE EN MODE RANDO !!! ».
//
// CE QUI EXISTAIT AVANT CE LOT, ET POURQUOI CE N'ETAIT PAS UN INTERSTITIEL. La
// mecanique etait ecrite — `AdService.preloadInterstitial` et
// `AdService.showInterstitial`, dans `features/group` — et elle n'avait AUCUN
// appelant dans `lib/`. Mesure du 12/10 : les deux seules citations de
// `showInterstitial` dans tout le depot etaient sa propre declaration et un
// test qui verifiait qu'elle rend `false` en mode test. Pendant ce temps
// `ad_config.dart` affirmait « PAS d'interstitiel » et n'exposait aucun
// identifiant. C'est la meme forme que la banniere avant la tache 595 : « un
// interrupteur sans ampoule ».
//
// CE FICHIER MESURE LES TROIS CHOSES QUI FONT QU'UN FORMAT EXISTE :
//   1. LA REGLE — la cadence et ses quatre interdits, un test par refus ;
//   2. LE BRANCHEMENT — le porteur demande vraiment, a chaque changement
//      d'ecran, et il ne demande RIEN sur le chemin du secours ni en rando ;
//   3. LA CADENCE N'AVANCE QUE SUR UN AFFICHAGE REEL — sinon le randonneur
//      paierait une demi-heure de silence qu'il n'a pas eue (lecon de la
//      tache 639, le bouton qui disait « merci » sans rien accorder).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/ads/domain/cadence_interstitiel.dart';
import 'package:moteur_gr/features/ads/providers/interstitiel_providers.dart';

/// Un moment hors rando, hors secours, sans-pub a faux, pub autorisee, et une
/// demi-heure pleine d'utilisation : le cas ou l'interstitiel DOIT s'ouvrir.
MomentDInterstitiel moment({
  Duration utilisation = const Duration(minutes: 30),
  Duration utilisationAuDernier = Duration.zero,
  bool enRando = false,
  String chemin = '/home',
  bool sansPub = false,
  bool pubAutorisee = true,
}) => MomentDInterstitiel(
  utilisation: utilisation,
  utilisationAuDernier: utilisationAuDernier,
  enRando: enRando,
  chemin: chemin,
  sansPub: sansPub,
  pubAutorisee: pubAutorisee,
);

void main() {
  group('838 D2 — la cadence : une toutes les demi-heures d utilisation', () {
    test('a trente minutes pile, l heure est venue', () {
      expect(moment().autorise, isTrue);
    });

    test('a vingt-neuf minutes, pas encore', () {
      expect(
        moment(utilisation: const Duration(minutes: 29)).autorise,
        isFalse,
        reason:
            '« toute les demi-heures » : trente minutes, pas vingt-neuf. Une '
            'cadence qui arrondit vers le bas est une cadence plus intrusive '
            'que celle que Christophe a demandee',
      );
    });

    test('le PREMIER interstitiel ne tombe pas sur le premier ecran', () {
      expect(
        moment(utilisation: Duration.zero).autorise,
        isFalse,
        reason:
            'au lancement, le temps d utilisation est nul et le dernier '
            'interstitiel vaut zero : l ecart est donc nul. Un interstitiel '
            'des le premier ecran d une application qu on vient d installer '
            'est la meilleure facon de la faire desinstaller',
      );
    });

    test('la cadence se compte DEPUIS LE DERNIER, pas depuis le lancement', () {
      expect(
        moment(
          utilisation: const Duration(minutes: 45),
          utilisationAuDernier: const Duration(minutes: 30),
        ).autorise,
        isFalse,
        reason:
            'quarante-cinq minutes d usage mais seulement quinze depuis le '
            'dernier : on attend encore',
      );
      expect(
        moment(
          utilisation: const Duration(minutes: 61),
          utilisationAuDernier: const Duration(minutes: 30),
        ).autorise,
        isTrue,
        reason: 'trente et une minutes depuis le dernier : c est l heure',
      );
    });

    test('une heure et demie d usage n en declenche pas trois d un coup', () {
      // LA CADENCE EST UN ECART, PAS UN QUOTA. Elle dit « au moins trente
      // minutes entre deux », et le porteur ne demande qu'a l'arrivee sur un
      // ecran : il n'y a donc pas de rattrapage. Ce test fige cette lecture.
      final apres = moment(
        utilisation: const Duration(minutes: 90),
        utilisationAuDernier: const Duration(minutes: 90),
      );
      expect(
        apres.autorise,
        isFalse,
        reason:
            'une fois montre, le compteur repart de l instant present : '
            'aucune dette ne s accumule pendant une longue session',
      );
    });
  });

  group('838 D2 — les quatre refus qui ne se discutent pas', () {
    test('EN RANDO, jamais — et c est le refus le plus fort', () {
      expect(
        moment(enRando: true).autorise,
        isFalse,
        reason:
            '« IL N Y A PAS DE PUB POSSIBLE EN MODE RANDO !!! » (Christophe). '
            'Un interstitiel prend TOUT l ecran : la carte, la trace, le '
            'prochain virage et le bouton SOS avec lui',
      );
    });

    test('EN RANDO, meme apres des heures d utilisation', () {
      expect(
        moment(utilisation: const Duration(hours: 5), enRando: true).autorise,
        isFalse,
        reason:
            'la cadence ne rachete jamais la regle de rando : ce n est pas '
            'une priorite entre deux regles, c est un interdit',
      );
    });

    for (final chemin in kCheminsSansInterstitiel) {
      test('JAMAIS sur le chemin du secours : $chemin', () {
        expect(
          moment(chemin: chemin).autorise,
          isFalse,
          reason:
              '« jamais sur un ecran de securite ni sur l urgence ». Un '
              'randonneur qui ouvre $chemin a, par hypothese, un probleme : '
              'lui prendre l ecran entier pour une publicite serait au mieux '
              'indecent, au pire dangereux',
        );
      });
    }

    test('les trois ecrans du secours sont bien ceux-la, et pas d autres', () {
      // UNE LISTE QUI MAIGRIT EN SILENCE EST UNE LISTE QUI NE PROTEGE PLUS.
      // Ce sont les memes ecrans dont le groupe B5 de `pub_v1_595_test.dart`
      // interdit deja la BANNIERE : les deux formats doivent s arreter au
      // meme endroit.
      expect(kCheminsSansInterstitiel, {
        '/emergency',
        '/health',
        '/signalement',
      });
    });

    test('SANS-PUB : celui qui a paye le silence ne voit rien', () {
      expect(
        moment(sansPub: true).autorise,
        isFalse,
        reason:
            'abonne, sentier achete ou recompense de 24 h — aucune regle n est '
            'recalculee ici, c est la source unique #99404 qui le dit, '
            'exactement comme pour la banniere',
      );
    });

    test('SANS CONSENTEMENT, aucune demande ne part', () {
      expect(
        moment(pubAutorisee: false).autorise,
        isFalse,
        reason:
            'le CMP gouverne le DROIT de demander une publicite. Hors ligne ce '
            'droit tombe de lui-meme, donc pas d interstitiel sur le sentier '
            'meme en dehors d une marche',
      );
    });
  });

  // ===========================================================================
  // L'HORLOGE D'UTILISATION — « d utilisation », et c'est le mot qui compte
  // ===========================================================================
  //
  // POURQUOI ELLE A SES PROPRES TESTS. « j en veu une toute les demi-heures
  // heures d utilisation » : tout le lot tient sur le sens de ce dernier mot.
  // Une horloge qui compterait le temps de la MONTRE donnerait un interstitiel
  // a chaque ouverture d'une application qu'on utilise trois minutes par jour,
  // soit l'inverse exact de ce qui a ete demande. La regle de cadence est
  // testee au-dessus ; ce qu'elle MESURE est teste ici.
  group('838 D2 — l horloge ne tourne que devant les yeux du randonneur', () {
    /// Une horloge pilotee a la main : le test decide de l'heure.
    ({HorlogeDUtilisation horloge, void Function(Duration) avancer})
    horlogeDeTest() {
      var maintenant = DateTime(2026, 10, 12, 9);
      final horloge = HorlogeDUtilisation(maintenant: () => maintenant);
      return (horloge: horloge, avancer: (d) => maintenant = maintenant.add(d));
    }

    test('au premier instant, rien n a encore ete utilise', () {
      final (:horloge, avancer: _) = horlogeDeTest();
      expect(horloge.utilisation, Duration.zero);
    });

    test('au premier plan, elle avance avec le temps', () {
      final (:horloge, :avancer) = horlogeDeTest();
      avancer(const Duration(minutes: 12));
      expect(horloge.utilisation, const Duration(minutes: 12));
    });

    test('EN ARRIERE-PLAN, ELLE S ARRETE — c est tout le lot', () {
      final (:horloge, :avancer) = horlogeDeTest();
      avancer(const Duration(minutes: 10));
      horloge.suspendre();
      avancer(const Duration(hours: 8));

      expect(
        horloge.utilisation,
        const Duration(minutes: 10),
        reason:
            'huit heures ont passe sur la MONTRE, l application etait fermee. '
            'Si ce temps comptait, le randonneur trouverait un interstitiel a '
            'chaque fois qu il rouvre l application le lendemain : ce ne '
            'serait plus « une toutes les demi-heures d utilisation », mais '
            'une a chaque ouverture',
      );
    });

    test('elle reprend ou elle s etait arretee', () {
      final (:horloge, :avancer) = horlogeDeTest();
      avancer(const Duration(minutes: 10));
      horloge.suspendre();
      avancer(const Duration(hours: 8));
      horloge.reprendre();
      avancer(const Duration(minutes: 5));

      expect(
        horloge.utilisation,
        const Duration(minutes: 15),
        reason: 'dix minutes hier, cinq aujourd hui : quinze d utilisation',
      );
    });

    test('deux suspensions de suite ne perdent pas le temps acquis', () {
      final (:horloge, :avancer) = horlogeDeTest();
      avancer(const Duration(minutes: 7));
      horloge.suspendre();
      horloge.suspendre();
      expect(
        horloge.utilisation,
        const Duration(minutes: 7),
        reason:
            'le cycle de vie repete ses etats ; une suspension deja faite ne '
            'doit pas remettre le compteur a zero',
      );
    });

    test('deux reprises de suite ne comptent pas le temps deux fois', () {
      final (:horloge, :avancer) = horlogeDeTest();
      horloge.reprendre();
      horloge.reprendre();
      avancer(const Duration(minutes: 4));
      expect(horloge.utilisation, const Duration(minutes: 4));
    });

    test('le cycle de vie la pilote : au premier plan elle tourne', () {
      final (:horloge, :avancer) = horlogeDeTest();
      horloge.suivreLeCycleDeVie(AppLifecycleState.paused);
      avancer(const Duration(hours: 3));
      horloge.suivreLeCycleDeVie(AppLifecycleState.resumed);
      avancer(const Duration(minutes: 30));

      expect(
        horloge.utilisation,
        const Duration(minutes: 30),
        reason:
            'les trois heures en arriere-plan ne comptent pas ; la demi-heure '
            'devant les yeux, si, et elle vient d ouvrir la cadence',
      );
    });

    test('une demi-heure d utilisation ouvre bien la cadence', () {
      final (:horloge, :avancer) = horlogeDeTest();
      horloge.suivreLeCycleDeVie(AppLifecycleState.paused);
      avancer(const Duration(days: 2));
      horloge.suivreLeCycleDeVie(AppLifecycleState.resumed);
      avancer(kEcartEntreInterstitiels);

      expect(
        moment(utilisation: horloge.utilisation).autorise,
        isTrue,
        reason:
            'les deux bouts se rejoignent : ce que l horloge mesure est bien '
            'ce que la cadence attend',
      );
    });
  });

  group('838 D2 — la memoire du dernier interstitiel', () {
    test('elle part a zero et ne retient que ce qui a ete MONTRE', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(dernierInterstitielProvider), Duration.zero);

      c
          .read(dernierInterstitielProvider.notifier)
          .montreA(const Duration(minutes: 31));

      expect(
        c.read(dernierInterstitielProvider),
        const Duration(minutes: 31),
        reason:
            'la cadence repart de l instant du dernier AFFICHAGE REEL. '
            'Avancer ce reperage sur une simple tentative ferait payer au '
            'randonneur une demi-heure de silence qu il n a pas eue : c est la '
            'faute que la tache 639 a mesuree sur la video recompensee',
      );
    });
  });

  group('838 D2 — l ecart demande est bien une demi-heure', () {
    test('trente minutes, et c est ecrit une seule fois', () {
      expect(
        kEcartEntreInterstitiels,
        const Duration(minutes: 30),
        reason:
            '« j en veu une toute les demi-heures heures d utilisation ». Si '
            'ce chiffre doit changer, il change ICI et nulle part ailleurs',
      );
    });
  });
}
