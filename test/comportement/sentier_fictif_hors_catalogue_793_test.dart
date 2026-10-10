/// LA GARDE : un sentier qui se declare invente n arrive pas au randonneur.
///
/// CE QUE CETTE GARDE EMPECHE, ET QUI EST ARRIVE. `test_trail_config.dart`
/// disait de lui-meme, des sa deuxieme ligne, « un sentier entierement invente
/// pour les tests : aucune correspondance avec un lieu reel », et plus bas
/// « donnees 100% fictives ». Il figurait pourtant au catalogue sous le nom
/// credible de « Sentier des Volcans », en Auvergne, 72 km et 2 420 m de
/// denivele, et il etait ACHETABLE : cinq etapes au palier de 0,99 EUR, soit
/// 4,95 EUR. Quelqu un qui l achetait croyait pouvoir le marcher. Decision de
/// Christophe du 10/10, en deux mots : « tu degage ».
///
/// POURQUOI LA GARDE EST SUR LA PROPRIETE ET NON SUR L IDENTIFIANT. Une
/// assertion du genre « le catalogue ne contient pas `test-trail` » aurait
/// ferme la porte derriere ce sentier-ci et l aurait laissee ouverte pour le
/// suivant : dans six mois, un autre decor de test ajoute au registre serait
/// passe par le meme trou, avec un autre identifiant et le meme mensonge. La
/// garde tient donc sur ce que la configuration DECLARE
/// ([TrailConfig.isFictional]), et elle vaut pour tous les sentiers, y compris
/// ceux qui n existent pas encore.
///
/// UN COMMENTAIRE N EST PAS UNE GARDE, et c est la lecon de ce lot. La fiction
/// etait ecrite en prose depuis le premier jour — donc lisible par un humain et
/// par personne d autre. Elle est maintenant une DONNEE, et
/// `TrailCatalog.all` la REFUSE au lieu de la signaler : le filtre tourne dans
/// l application livree, pas seulement ici.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';

void main() {
  group('LA GARDE — rien de fictif au catalogue', () {
    test('aucun sentier du catalogue ne se declare invente', () {
      for (final sentier in TrailCatalog.all) {
        expect(
          sentier.isFictional,
          isFalse,
          reason:
              '${sentier.id} (« ${sentier.displayName} ») se declare '
              'fictif et se retrouve pourtant au catalogue, donc visible et '
              'achetable a ${sentier.priceInStages} etape(s). Un sentier '
              'invente vendu a un randonneur lui fait croire qu il existe un '
              'chemin a marcher. Le retirer de TrailCatalog ne suffit pas a '
              'le supprimer du depot : il peut rester au registre comme '
              'decor de test.',
        );
      }
    });

    test(
      'le drapeau est un AVEU, pas un reglage : il vaut faux par defaut',
      () {
        // Une configuration qui ne dit rien n est PAS presumee fictive : le
        // defaut doit rester le cas normal, sinon tout sentier reel neuf serait
        // ecarte en silence au premier oubli de champ.
        const muet = TrailConfig(
          id: 'sentier-muet',
          name: 'Muet',
          displayName: 'Muet',
          tagline: 'ne dit rien de sa nature',
          totalStages: 3,
          totalDistanceKm: 30,
          totalElevationGain: 900,
          region: 'Region',
          country: 'France',
          primaryColorValue: 0xFF2E7D32,
          secondaryColorValue: 0xFF1565C0,
          gpxAssetPath: '',
        );
        expect(muet.isFictional, isFalse);

        // Et une configuration qui l avoue est bien prise au mot.
        const avoue = TrailConfig(
          id: 'sentier-avoue',
          name: 'Avoue',
          displayName: 'Avoue',
          tagline: 'se declare invente',
          totalStages: 3,
          totalDistanceKm: 30,
          totalElevationGain: 900,
          region: 'Region',
          country: 'France',
          primaryColorValue: 0xFF2E7D32,
          secondaryColorValue: 0xFF1565C0,
          gpxAssetPath: '',
          isFictional: true,
        );
        expect(avoue.isFictional, isTrue);
      },
    );

    test('elle travaille sur des donnees reelles, et elle NOMME ses refus', () {
      // CE TEST EXISTE POUR QUE LA GARDE NE SOIT PAS DU CODE MORT. Un filtre
      // qui n a jamais rien a filtrer se verifie lui-meme et ne prouve rien.
      // Ici le registre porte VRAIMENT un sentier fictif — celui qui a motive
      // le lot — et c est le filtre, pas une suppression, qui le tient dehors.
      expect(
        TrailCatalog.fictifsEcartes,
        isNotEmpty,
        reason:
            'le registre ne porte plus aucun sentier fictif : le filtre de '
            'TrailCatalog.all ne filtre plus rien de reel, et cette garde ne '
            'garde plus qu elle-meme',
      );
      final ecartes = TrailCatalog.fictifsEcartes.map((c) => c.id).toSet();
      expect(ecartes, contains(testTrailConfig.id));

      // Un sentier ecarte est ABSENT du catalogue, et pas seulement range a
      // part : l absence est nommee d un cote, effective de l autre.
      for (final id in ecartes) {
        expect(TrailCatalog.ids, isNot(contains(id)));
      }
    });
  });

  group('LE SENTIER DES VOLCANS — sorti du catalogue le 10/10', () {
    test('invisible : il n a plus aucune entree au catalogue', () {
      expect(TrailCatalog.contains(testTrailConfig.id), isFalse);
      expect(TrailCatalog.ids, isNot(contains(testTrailConfig.id)));
      expect(TrailCatalog.byId(testTrailConfig.id), isNull);
      // Aucune entree ne porte non plus son nom d affichage : c etait « Volcans
      // Trail » que le randonneur lisait dans la liste.
      final noms = TrailCatalog.all.map((c) => c.displayName);
      expect(noms, isNot(contains(testTrailConfig.displayName)));
    });

    test('inachetable : aucun chemin de resolution ne le ramene', () {
      // Une selection qui le viserait — ancienne preference, lien profond,
      // etat restaure d un vieux telephone — retombe sur le sentier par
      // defaut. C est le repli deja prevu pour un sentier retire, et il vaut
      // ici sans rien ajouter.
      expect(
        TrailCatalog.resolveOrDefault(testTrailConfig.id).id,
        TrailCatalog.defaultTrail.id,
      );
      expect(TrailCatalog.isFree(testTrailConfig.id), isFalse);
    });

    test('il etait bien VENDU, et c est ce que le retrait arrete', () {
      // La mesure qui fonde la decision : cinq etapes, aucun prix declare,
      // donc le prix du modele — une etape par etape, au palier de 0,99 EUR.
      expect(testTrailConfig.priceStages, isNull);
      expect(testTrailConfig.priceInStages, 5);
      expect(testTrailConfig.isFreeTrail, isFalse);
    });

    test('il reste au depot comme decor de test, et c est voulu', () {
      // SORTIR DU CATALOGUE N EST PAS SUPPRIMER DU DEPOT. Soixante-six
      // fichiers de test et deux campagnes d integration s en servent de
      // decor. La regle : ce que le randonneur ne voit pas peut rester s il
      // sert au harnais.
      expect(testTrailConfig.id, 'test-trail');
      expect(testTrailConfig.totalStages, 5);
      expect(
        testTrailConfig.isFictional,
        isTrue,
        reason:
            'le decor de test doit continuer a dire sa nature : c est ce seul '
            'aveu qui le tient hors du catalogue',
      );
    });
  });

  group('CE QUE LE RETRAIT N A PAS DEPLACE', () {
    test('le sentier par defaut n a pas bouge : mare-a-mare-centre', () {
      // Le sentier fictif etait en DEUXIEME position, derriere le sentier
      // reel : le retrait ne pouvait donc pas deplacer le defaut. Verifie
      // plutot que suppose, parce que defaultTrail est le PREMIER du
      // catalogue et qu un retrait en tete aurait change l ecran d accueil.
      expect(TrailCatalog.defaultTrail.id, mareAMareCentreTrailConfig.id);
      expect(TrailCatalog.defaultTrail.isFictional, isFalse);
      expect(TrailCatalog.all.first.id, 'mare-a-mare-centre');
    });

    test('le demarrage tient : sans selection, la config active est le '
        'defaut', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(trailConfigProvider).id, 'mare-a-mare-centre');
      expect(container.read(trailConfigProvider).isFictional, isFalse);
    });

    test('les sentiers gratuits restent a ZERO', () {
      // DECISION DE CHRISTOPHE DU 29/09, verbatim : « la prochaine fois que
      // j ouvre l application je n ai droit a rien ». Le sentier fictif etait
      // PAYANT, son retrait ne pouvait donc pas changer ce compte — mais le
      // compte se mesure, il ne se suppose pas.
      expect(TrailCatalog.freeIds, isEmpty);
      expect(TrailCatalog.all.every((c) => c.priceInStages > 0), isTrue);
    });

    test('le catalogue lu par les ecrans ne porte aucun fictif', () {
      // LA GARDE COUVRE LES DEUX PORTES. Les ecrans ne lisent pas
      // TrailCatalog.all directement mais le catalogue EFFECTIF
      // (availableTrailsProvider -> catalogueSentiersProvider), dont le
      // plancher hors ligne est justement TrailCatalog.all et dont la fusion
      // distante s en sert de matiere. Filtrer a la source les couvre d un
      // seul geste, et ce test le constate du cote des ecrans.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final catalogue = container.read(availableTrailsProvider);
      expect(catalogue, isNotEmpty);
      expect(catalogue.every((c) => !c.isFictional), isTrue);
      expect(catalogue.map((c) => c.id), isNot(contains(testTrailConfig.id)));
    });
  });
}
