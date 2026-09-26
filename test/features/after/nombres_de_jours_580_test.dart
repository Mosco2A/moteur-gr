// DEUX NOMBRES DE JOURS QUI NE DISAIENT PAS CE QU'ILS COMPTAIENT — tache 580,
// point Y4.
//
// CE QUE CHRIS VOYAIT. Le diplome annoncait « 7 jours de randonnee » et le
// recap « 0 jours ». Sept jours de quoi : de marche, ou du depart a l'arrivee,
// repos compris ? Les deux nombres sortent pourtant du MEME calcul —
// `AdventureStats.durationDays`, qui compte les jours ENTAMES entre le depart
// et l'arrivee de la session, donc le TOTAL, repos compris. Un nombre de jours
// qui ne dit pas ce qu'il compte se lit de travers dans la moitie des cas ;
// c'est le defaut que le LOT R (tache 569) avait corrige sur la faisabilite,
// et ces deux ecrans-la etaient restes dehors.
//
// LA REGLE, ET ELLE EXISTAIT DEJA. L'application dispose d'un vocabulaire
// etabli pour cette distinction, traduit dans les cinq langues : « jours au
// total » (`itinerary.daysTotal`) face a « jours de marche »
// (`itinerary.daysBreakdown`, `summary.durationValue`). Ce fichier ne fabrique
// donc AUCUN vocabulaire neuf : il exige que les deux libelles reprennent
// celui qui existe.
//
// POURQUOI DEUX ETAGES. Le premier verifie la TABLE (les cinq langues disent
// la nature du nombre) ; le second verifie les DEUX ECRANS (ils affichent bien
// ce libelle-la). Sans le second, remplacer la cle par un « $days jours » ecrit
// en dur dans le widget passerait inapercu.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import '../../structurel/parcours_reel.dart';

void main() {
  group('Y4-a — la table dit, dans les cinq langues, ce que le nombre compte',
      () {
    for (final langue in AppLocale.values) {
      test('${langue.languageCode} : diplome et recap nomment le TOTAL', () {
        final tr = langue.buildSync();
        // La facon dont CETTE langue dit « jours au total », telle que
        // l'itineraire l'ecrit deja. Aucune chaine inventee ici.
        final natureTotal = tr.itinerary.daysTotal.toLowerCase();
        expect(natureTotal, isNotEmpty,
            reason: 'reference de vocabulaire absente : lecture cassee');

        for (final entree in <String, String>{
          'diploma.recapDuration': tr.diploma.recapDuration,
          'recap.duration': tr.recap.duration,
        }.entries) {
          expect(
            entree.value.toLowerCase().contains(natureTotal),
            isTrue,
            reason: 'UN NOMBRE DE JOURS SANS SA NATURE : « ${entree.value} » '
                '(${entree.key}, ${langue.languageCode}) ne dit pas s il '
                'compte les jours de marche ou le total. Le chiffre vient de '
                'AdventureStats.durationDays, qui compte du depart a '
                'l arrivee : il doit le DIRE, avec le vocabulaire deja '
                'traduit « ${tr.itinerary.daysTotal} ».',
          );
        }
      });
    }
  });

  group('Y4-b — les deux ecrans affichent bien ce libelle', () {
    testWidgets('/trail/:id/diploma et /trail/:id/recap nomment le total',
        (tester) async {
      LocaleSettings.setLocaleRaw('fr');
      final attendu = t.itinerary.daysTotal.toLowerCase();

      for (final gabarit in <String>[
        '/trail/:id/diploma',
        '/trail/:id/recap',
      ]) {
        final concret = cheminConcret(gabarit)!;
        await monterAppliReelle(tester, depart: concret);
        final arrivee = cheminAffiche();
        final textes = textesVisibles(tester);
        await demonterAppli(tester);
        erreursDeRendu(tester);

        expect(arrivee, concret,
            reason: '$gabarit n a pas ete atteint (arrivee : $arrivee) : '
                'ce test ne prouverait rien');
        expect(
          textes.any((s) => s.toLowerCase().contains(attendu)),
          isTrue,
          reason: 'L ECRAN $concret AFFICHE UN NOMBRE DE JOURS SANS DIRE CE '
              'QU IL COMPTE. Textes lus : ${textes.join(' | ')}',
        );
      }
    });
  });
}
