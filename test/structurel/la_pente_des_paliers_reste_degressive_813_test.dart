// GARDE — LA PENTE DES PALIERS RESTE DEGRESSIVE (tache 813).
//
// L'INVARIANT COMMERCIAL DE LA GRILLE, ET IL N'ETAIT GARDE PAR RIEN. Chaque
// palier doit coûter STRICTEMENT MOINS CHER A L'ETAPE que le precedent :
// 0,91 puis 0,87 puis 0,80 puis 0,70. Un palier qui casse la pente rend le pack
// du DESSOUS plus avantageux que celui du dessus — le randonneur qui prend le
// gros paie l'etape plus cher que celui qui prend le petit, et la grille
// devient une punition pour le meilleur client.
//
// CE QUE CETTE GARDE A COUTE A ETABLIR, LE 11/10/2026. Le palier de seize
// etapes est entre a 13,99 EUR, et ce prix n'est pas un arrondi commode : a
// 14,99 l'etape reviendrait a 0,94, donc PLUS CHER que le pack de onze, et la
// pente se casserait ; a 12,99 elle tomberait a 0,81 et mangerait le pack de
// vingt-cinq. La fenetre etait etroite, et un centime la referme.
//
// POURQUOI UNE MACHINE ET PAS UNE RELECTURE. Un prix de palier est exactement
// le genre de chiffre qu'on ajuste sous pression — une promotion, un
// alignement sur un concurrent, un arrondi « plus propre ». La relecture qui
// verifie la pente est celle qu'on saute ce jour-la. La garde, elle, ne la
// saute pas.
//
// ELLE GARDE AUSSI L'ACCORD ENTRE LA GRILLE ET LA CAISSE. Chaque palier porte
// un productId, et c'est le store qui credite les etapes
// (`kWalletCreditStepsByProduct`). Si les deux divergeaient, l'application
// vendrait seize etapes et en crediterait vingt-cinq — ou l'inverse. Les deux
// tables se lisent donc l'une contre l'autre ici.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';

/// Le prix de l'etape dans [pack], arrondi au centime.
///
/// L'ARRONDI EST VOLONTAIRE ET IL EST LA LECTURE JUSTE. 9,99 / 11 vaut
/// 0,9081..., et c'est 0,91 qui est annonce. Comparer les flottants bruts
/// ferait rougir la garde sur un centieme de centime sans aucun sens
/// commercial ; comparer les centimes compare ce que le randonneur lit.
double _prixDeLEtape(StepPack pack) =>
    (pack.priceEur / pack.steps * 100).roundToDouble() / 100;

void main() {
  group('813 — la grille des paliers', () {
    test('les quatre paliers sont ceux que Christophe a valides', () {
      // LA GRILLE VALIDEE LE 11/10/2026 A 13:32, un seul ajout, les trois
      // autres inchanges. Ce test est l'endroit ou le chiffre decide se
      // confronte au chiffre livre.
      expect(kStepPacks.map((p) => p.steps).toList(), <int>[11, 16, 25, 50]);
      expect(kStepPacks.map((p) => p.priceEur).toList(), <double>[
        9.99,
        13.99,
        19.99,
        34.99,
      ]);
      expect(
        kStepPacks.map(_prixDeLEtape).toList(),
        <double>[0.91, 0.87, 0.80, 0.70],
        reason: 'la pente annoncee au randonneur, palier par palier',
      );
    });

    test('la pente est DEGRESSIVE : chaque palier est strictement moins cher '
        'a l etape que le precedent', () {
      for (var i = 1; i < kStepPacks.length; i++) {
        final avant = kStepPacks[i - 1];
        final apres = kStepPacks[i];
        expect(
          _prixDeLEtape(apres),
          lessThan(_prixDeLEtape(avant)),
          reason:
              'LA PENTE EST CASSEE entre ${avant.steps} et ${apres.steps} '
              'etapes : ${_prixDeLEtape(apres)} EUR l etape contre '
              '${_prixDeLEtape(avant)} EUR au palier du dessous. Le pack le '
              'plus gros doit TOUJOURS etre le moins cher a l etape, sinon le '
              'randonneur qui en prend le plus paie le plus cher — et il le '
              'verra. Reprenez le prix, pas la garde.',
        );
      }
    });

    test('un palier est toujours moins cher a l etape que le tarif unite', () {
      // SANS CELA UN PACK NE SERT A RIEN. L ancrage d affichage est le tarif
      // unite (0,99) ; un palier qui ne descend pas sous lui ne donne aucune
      // raison d acheter en gros.
      for (final pack in kStepPacks) {
        expect(
          _prixDeLEtape(pack),
          lessThan(kStepTierEur),
          reason:
              'le palier de ${pack.steps} etapes revient a '
              '${_prixDeLEtape(pack)} EUR l etape, soit au moins le tarif '
              'unite de $kStepTierEur : acheter en gros n avantage plus rien',
        );
      }
    });

    test('la grille est TRIEE par nombre d etapes croissant', () {
      // CE TRI N EST PAS COSMETIQUE : `smallestPackCovering` parcourt la liste
      // dans l ordre et rend le PREMIER palier qui couvre le besoin. Une
      // grille desordonnee lui ferait rendre un palier trop gros.
      for (var i = 1; i < kStepPacks.length; i++) {
        expect(
          kStepPacks[i].steps,
          greaterThan(kStepPacks[i - 1].steps),
          reason: 'smallestPackCovering depend de cet ordre',
        );
      }
    });

    test('chaque palier a un productId distinct, declare a la caisse et sur le '
        'MEME nombre d etapes', () {
      // LA GRILLE ET LA CAISSE DISENT LE MEME CHIFFRE, ou l application vend
      // seize etapes et en credite vingt-cinq.
      final ids = kStepPacks.map((p) => p.productId).toSet();
      expect(
        ids,
        hasLength(kStepPacks.length),
        reason:
            'deux paliers qui partagent un productId se vendent l un pour '
            'l autre',
      );
      for (final pack in kStepPacks) {
        expect(
          kWalletCreditStepsByProduct[pack.productId],
          pack.steps,
          reason:
              'le palier de ${pack.steps} etapes (${pack.productId}) n est pas '
              'declare pour ce nombre d etapes dans la grille de credits du '
              'store : la vente et le credit divergeraient',
        );
        expect(
          kWalletProductIds,
          contains(pack.productId),
          reason:
              '${pack.productId} est vendu par la grille mais inconnu du '
              'service d achat : le recu serait refuse a la livraison',
        );
      }
    });
  });

  group('813 — le palier de seize comble le trou de la grille', () {
    test('seize etapes couvre tout besoin de douze a seize', () {
      // LE TROU ETAIT ENTRE ONZE ET VINGT-CINQ, et c est exactement la que
      // tombe le meilleur client : deux troncons de cinq a six jours, donc
      // deux semaines de conges, et le GR20 integral qui fait seize etapes
      // tout rond. Avant ce palier, un besoin de douze etapes en faisait payer
      // vingt-cinq.
      //
      // ICI ON MESURE LA GRILLE, PAS LE SERVICE : `smallestPackCovering` rend
      // le PREMIER palier qui couvre le besoin, et c est donc une propriete de
      // la grille qu aucun palier intermediaire ne manque entre douze et
      // seize. Le choix du service lui-meme est exerce par
      // `monetization_service_test` — la ou un service existe.
      for (var besoin = 12; besoin <= 16; besoin++) {
        final couvrant = kStepPacks.firstWhere((p) => p.steps >= besoin);
        expect(
          couvrant.steps,
          16,
          reason:
              'un besoin de $besoin etapes doit etre servi par le palier de '
              'seize (13,99 EUR), pas par celui de vingt-cinq',
        );
        expect(couvrant.productId, kWalletCredits16);
      }
    });
  });
}
