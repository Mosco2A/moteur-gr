// PERSONA — LE COMPTABLE (tache 573, LOT V).
//
// CE QU'IL FAIT. Il note les chiffres. Tous. Puis il les compare d'un ecran a
// l'autre, et il refuse deux valeurs qui devraient etre egales. Il refuse aussi
// un nombre qui ne dit pas ce qu'il compte, et un score sans echelle.
//
// CE QU'IL AURAIT ATTRAPE — trois retours du 26/09, et c'est le meme defaut vu
// sous trois angles :
//
//   * retour 5, verbatim : « Pourquoi ca dit vise les 9 jours au lioeu de 7,
//     pourquoi au lieu de 7? vu qu'on a encore rien dit a ce niveau » ;
//   * retour 7, verbatim : « ca te dit vise 9 jours, et ca te propose 11 jours
//     normal? » — 9 jours de MARCHE plus 2 de REPOS font 11 jours au TOTAL, et
//     rien ne le disait ;
//   * retour 12, verbatim : « itineraire ca te dit en faisabilite 11 jours et ca
//     te propose 9 » — la Faisabilite comptait des totaux, l'Itineraire des jours
//     de marche, les deux chiffres etaient justes, et aucun n'annoncait son unite.
//   * retour 8, verbatim : « score 1,30 sans echelle ca ne veut rien dire ».
//
// LA REGLE QUI EN DECOULE, et c'est celle que Chris a formulee sans le dire :
// TOUT NOMBRE DE JOURS AFFICHE PORTE SA NATURE, PARTOUT, SANS EXCEPTION. Marche,
// repos, ou total. Un nombre nu est un nombre qui mentira tot ou tard.
//
// POURQUOI AUCUN PERSONA NE L'A VU. Aucun ne compare la COHERENCE ENTRE ECRANS :
// chaque scenario valide son ecran et s'en va. Et les 2 760 tests du depot font
// pire encore — ils verifient chaque calcul separement, chacun juste de son cote.
// Deux calculs justes qui se contredisent passent tous les tests.
//
// LE TROU DE GRILLE QU'IL FERME : (D) on ne compare pas les chiffres entre
// ecrans.
library;

import 'package:flutter_test/flutter_test.dart';

import '../structurel/parcours_reel.dart';

/// Les mots qui donnent sa NATURE a un nombre de jours.
const naturesDeJours = <String>[
  'de marche',
  'marche',
  'de repos',
  'repos',
  'au total',
  'total',
  'consecutif',
  'consécutif',
  'affilee',
  'affilée',
  'restant',
  'depuis',
  'sur ',
];

/// Les textes ou un nombre de jours nu est ADMIS, et la raison.
///
/// Une exception est un engagement : elle dit pourquoi ce nombre-la n'a pas
/// besoin de sa nature. Une liste qui s'allonge sans raison ecrite est une regle
/// qui s'eteint.
const joursNusAdmis = <String, String>{};

void main() {
  group('LE COMPTABLE — tout nombre de jours dit ce qu il compte', () {
    testWidgets('aucun ecran n affiche un nombre de jours sans sa nature',
        (tester) async {
      // On balaie TOUS les ecrans atteignables. C'est le point : la regle ne vaut
      // rien si elle n'est appliquee que sur l'ecran ou Chris l'a vue. L'ecran
      // ajoute le mois prochain est couvert le jour ou il est ecrit.
      final nus = <String>[];
      final rejour = RegExp(r'(\d+)\s*(jours?|j\b)', caseSensitive: false);
      for (final r in routesDeclarees()) {
        final concret = cheminConcret(r.gabarit);
        if (concret == null) continue;
        await monterAppliReelle(tester, depart: concret);
        for (final t in textesVisibles(tester)) {
          if (!rejour.hasMatch(t)) continue;
          final bas = t.toLowerCase();
          if (naturesDeJours.any(bas.contains)) continue;
          if (joursNusAdmis.containsKey(t.trim())) continue;
          nus.add('$concret : « ${t.trim()} »');
        }
      }
      await demonterAppli(tester);
      erreursDeRendu(tester);
      expect(nus, isEmpty,
          reason: 'NOMBRES DE JOURS SANS LEUR NATURE. Chris a rencontre ce '
              'defaut trois fois en vingt minutes (retours 5, 7 et 12) : 9 ici, '
              '11 la, et jamais l unite. Tout nombre de jours affiche doit dire '
              's il compte de la marche, du repos, ou un total.\n'
              '  ${nus.join('\n  ')}');
    });
  });

  group('LE COMPTABLE — un score sans echelle ne veut rien dire', () {
    testWidgets('aucun nombre a virgule n est affiche nu', (tester) async {
      // Retour 8 : « score 1,30 sans echelle ca ne veut rien dire ». 1,30 sur
      // quoi ? Le plafond vaut 1,00 — mais l utilisateur ne peut pas le deviner.
      // Un nombre a virgule doit venir avec son unite ou son echelle.
      final nus = <String>[];
      final reDecimal = RegExp(r'\b\d+[.,]\d+\b');
      const echelles = <String>[
        'km',
        '%',
        'jusqu',
        'plafond',
        'sur ',
        'kg',
        'm/',
        'h',
        'min',
        '/jour',
        'énergie',
        'energie',
        '€',
      ];
      for (final r in routesDeclarees()) {
        final concret = cheminConcret(r.gabarit);
        if (concret == null) continue;
        await monterAppliReelle(tester, depart: concret);
        for (final t in textesVisibles(tester)) {
          if (!reDecimal.hasMatch(t)) continue;
          final bas = t.toLowerCase();
          if (echelles.any(bas.contains)) continue;
          nus.add('$concret : « ${t.trim()} »');
        }
      }
      await demonterAppli(tester);
      erreursDeRendu(tester);
      expect(nus, isEmpty,
          reason: 'NOMBRES A VIRGULE AFFICHES NUS, sans unite ni echelle :\n'
              '  ${nus.join('\n  ')}');
    });
  });

  group('LE COMPTABLE — le meme chiffre dit la meme chose partout', () {
    testWidgets('faisabilite et itineraire ne se contredisent pas sur la duree',
        (tester) async {
      // LE RETOUR 12, REJOUE. On releve les nombres de jours de l'ecran de
      // faisabilite, puis ceux de l'itineraire, et on exige que chacun porte sa
      // nature — c'est la seule facon qu'un lecteur ait de comprendre pourquoi 11
      // ici et 9 la sont tous les deux justes.
      final rejour = RegExp(r'(\d+)\s*jours?', caseSensitive: false);

      Future<List<String>> phrasesDeJours(String gabarit) async {
        final concret = cheminConcret(gabarit)!;
        await monterAppliReelle(tester, depart: concret);
        final out = textesVisibles(tester)
            .where(rejour.hasMatch)
            .map((t) => t.trim())
            .toList();
        return out;
      }

      final faisabilite = await phrasesDeJours('/trail/:id/feasibility');
      final itineraire = await phrasesDeJours('/trail/:id/itinerary');
      await demonterAppli(tester);
      erreursDeRendu(tester);

      final sansNature = <String>[
        for (final t in [...faisabilite, ...itineraire])
          if (!naturesDeJours.any(t.toLowerCase().contains)) t,
      ];
      expect(sansNature, isEmpty,
          reason: 'DEUX ECRANS, DEUX CHIFFRES, AUCUNE UNITE — le defaut exact '
              'du retour 12. Faisabilite : ${faisabilite.join(' / ')} ; '
              'Itineraire : ${itineraire.join(' / ')}.\n'
              'Sans nature : ${sansNature.join(' / ')}');
    });
  });
}
