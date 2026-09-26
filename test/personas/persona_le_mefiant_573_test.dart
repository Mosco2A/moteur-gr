// PERSONA — LE MEFIANT (tache 573, LOT V).
//
// CE QU'IL FAIT. Il refuse. Tout. Les consentements, les autorisations, les
// cases pre-cochees. Puis il VERIFIE que son refus a ete tenu — parce qu'il ne
// croit pas les applications sur parole. Et pour chaque chose qu'on lui demande,
// il demande a quoi ca sert.
//
// CE QU'IL AURAIT ATTRAPE. Retour 4 de Chris, verbatim : « ca ne precise pas que
// les analyses sont faites par une IA et que la liste des difficultes rencontre
// va servir a quelque chose, sinon tu le vire pour l'instant ». Verification
// faite : la liste des difficultes etait saisie, sauvegardee, synchronisee au
// cloud, restauree — ET LUE PAR PERSONNE. Retour 9 : « Le verdict c'est du
// blabla d'IA, tu mexplique comment c'est calcule au moment ou ca le fait ? ».
// Et le plus grave, retour 15 : le guide des icones de la carte documente un
// bouton SOS que l'application n'offre nulle part — « j'ai fait ecrire
// l'explication d'un bouton fantome ».
//
// POURQUOI AUCUN PERSONA NE L'A VU. Les huit personas de la campagne ACCEPTENT.
// Ils cochent, ils autorisent, ils avancent — parce qu'un persona qui refuse
// n'atteint pas l'ecran suivant, et qu'un scenario qui s'arrete tot semblait un
// scenario rate. C'est l'inverse : un refus est un chemin de production, et
// personne ne l'avait jamais emprunte jusqu'au bout.
//
// LES TROUS DE GRILLE QU'IL FERME : (E) on ne relit pas les textes pour y
// trouver jargon et contradictions ; (I) on ne verifie pas qu'une donnee saisie
// sert a quelque chose ; (J) on teste qu'un bouton marche, pas qu'il a du SENS.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../structurel/graphe_navigation.dart';
import '../structurel/parcours_reel.dart';

/// Les gestes que le GUIDE de la carte documente, et la route que chacun ouvre.
///
/// LA REGLE : un texte qui explique un geste s'engage sur l'existence de ce
/// geste. Toute entree ajoutee au guide doit etre inscrite ici avec ce qu'elle
/// ouvre — sinon le guide peut recommencer a documenter un bouton fantome sans
/// que rien ne le signale.
const gestesDocumentesParLeGuide = <String, String>{
  'sos': '/emergency',
};

/// Les donnees que l'application demande a l'utilisateur, et le provider ou le
/// champ qui les LIT ensuite.
///
/// Le mefiant refuse de saisir ce qui ne sert a rien. Une donnee collectee que
/// personne ne lit doit etre retiree (decision de Chris du 26/09 sur la liste
/// des difficultes) ou branchee.
const donneesEtLeurLecteur = <String, String>{
  'experienceNoteProvider':
      'la liste libre des difficultes rencontrees — Chris a tranche le 26/09 : '
          'si personne ne la lit, on la retire',
};

void main() {
  group('LE MEFIANT — un refus doit etre tenu', () {
    testWidgets('sur l ecran des consentements, tout refuser reste refuse',
        (tester) async {
      final concret = cheminConcret('/consent')!;
      await monterAppliReelle(tester, depart: concret);

      // LE LIBELLE VIENT DE L I18N, PAS D UNE DEVINETTE. Et on le cherche
      // HORS ECRAN aussi (`skipOffstage: false`) : sur un telephone, le bouton
      // « tout refuser » est en bas d'une liste qui defile — le chercher
      // seulement parmi les widgets rendus ferait croire qu'il n'existe pas.
      final i18n = jsonDecode(File('assets/i18n/fr.i18n.json').readAsStringSync())
          as Map<String, dynamic>;
      final libelleRefus =
          ((i18n['consent'] as Map)['declineAll'] as String).trim();
      final cible = find.text(libelleRefus, skipOffstage: false);
      if (cible.evaluate().isEmpty) {
        final libelles = gestesDisponibles(tester).map((g) => g.libelle).toList();
        await demonterAppli(tester);
        fail('AUCUN GESTE DE REFUS GLOBAL sur /consent : le libelle i18n '
            '« $libelleRefus » n existe pas a l ecran. Un ecran de consentement '
            'sans refus en un geste est un ecran qui pousse au oui. Gestes '
            'trouves : $libelles');
      }
      await tester.ensureVisible(cible.first);
      await stabiliser(tester, coups: 2);
      await tester.tap(cible.first, warnIfMissed: false);
      await stabiliser(tester);
      final apresRefus = textesVisibles(tester).join(' | ').toLowerCase();

      // On revient sur l'ecran : le refus doit avoir SURVECU.
      await allerA(tester, concret);
      final auRetour = textesVisibles(tester).join(' | ').toLowerCase();
      await demonterAppli(tester);
      erreursDeRendu(tester);

      expect(apresRefus, contains('refus'),
          reason: 'apres avoir tout refuse, l ecran ne dit pas que c est '
              'refuse');
      expect(auRetour, contains('refus'),
          reason: 'LE REFUS N A PAS SURVECU : en revenant sur l ecran des '
              'consentements, l etat refuse a disparu. Un refus qu il faut '
              'redire est un refus qu on n a pas entendu.');
    });
  });

  group('LE MEFIANT — un texte qui promet un geste doit le trouver', () {
    test('le guide de la carte ne documente aucun bouton fantome', () {
      // LE DEFAUT EXACT DU 26/09 : `map.guide.sos` explique « Ouvre l'appel
      // d'urgence avec vos coordonnees GPS » alors que l'ecran d'urgence n'a
      // AUCUNE porte dans toute l'application. On a fait ecrire le mode d'emploi
      // d'un bouton qui n'existe pas.
      final i18n = File('assets/i18n/fr.i18n.json');
      expect(i18n.existsSync(), isTrue);
      final tout = jsonDecode(i18n.readAsStringSync()) as Map<String, dynamic>;
      final guide =
          (tout['map'] as Map<String, dynamic>?)?['guide'] as Map<String, dynamic>?;
      expect(guide, isNotNull, reason: 'guide de la carte introuvable en i18n');

      // Les routes reellement atteignables, calculees par le graphe.
      final routes = routesDeclarees();
      final sources = fichiersSourceLib();
      final classes = classesDeWidgetParFichier(sources);
      final routeVersFichiers = routesEtLeursFichiers(routes, classes);
      final importeurs = importeursParFichier(sources);
      final aretes = aretesDeNavigation(sources).aretes;
      final portes = portesDEntree(routes);

      String? cibleDe(AreteNavigation a) {
        for (final r in routes) {
          if (a.parNom ? r.nom == a.cible : memeRoute(r.gabarit, a.cible)) {
            return r.gabarit;
          }
        }
        return null;
      }

      final sortantes = <String, Set<String>>{
        for (final r in routes) r.gabarit: <String>{},
      };
      for (final a in aretes) {
        final cible = cibleDe(a);
        if (cible == null) continue;
        for (final d
            in routesPorteusesDuGeste(a.fichier, routeVersFichiers, importeurs)) {
          sortantes[d]?.add(cible);
        }
      }
      final atteintes = <String>{};
      final file = <String>[...portes];
      while (file.isNotEmpty) {
        final r = file.removeLast();
        if (!atteintes.add(r)) continue;
        file.addAll(sortantes[r] ?? const <String>{});
      }

      final fantomes = <String>[];
      for (final e in gestesDocumentesParLeGuide.entries) {
        if (!guide!.containsKey(e.key)) continue; // le guide n'en parle plus
        if (atteintes.contains(e.value)) continue;
        fantomes.add('map.guide.${e.key} explique un geste qui ouvre '
            '${e.value} — route INATTEIGNABLE : «'
            ' ${guide[e.key]} »');
      }
      expect(fantomes, isEmpty,
          reason: 'BOUTONS FANTOMES DOCUMENTES : le guide explique a '
              'l utilisateur des gestes que l application n offre pas.\n'
              '  ${fantomes.join('\n  ')}');
    });
  });

  group('LE MEFIANT — une donnee demandee doit servir', () {
    test('chaque donnee collectee est LUE par un ecran ou un calcul', () {
      // On ne cherche pas « est-ce sauvegarde » (ca l'etait : en prefs, au
      // cloud, et restaure) mais « est-ce LU ». Une donnee dont le seul lecteur
      // est son propre ecran de saisie ne sert a rien : c'est exactement la
      // liste des difficultes que Chris a fait retirer.
      //
      // UN COMMENTAIRE N'EST PAS UN LECTEUR (tache 582, LOT Z). Ce balayage
      // lisait le source BRUT. Or le LOT S (tache 570, S2) a RETIRE
      // `experienceNoteProvider` et laisse a sa place une pierre tombale qui
      // explique le retrait — en NOMMANT le provider. La garde retrouvait donc
      // ce nom dans le commentaire, comptait un fichier lecteur, et declarait
      // morte une donnee DEJA SUPPRIMEE : elle criait au loup sur le cadavre du
      // loup. Son propre code dit l'intention (« la donnee a ete retiree : tres
      // bien ») ; c'est la LECTURE qui la trahissait.
      // Meme piege et meme remede que la garde des ecrans sans route (tache
      // 580, Y2) : on lit le source PRIVE DE SES COMMENTAIRES.
      final sources = fichiersSourceLib();
      final orphelines = <String>[];
      for (final e in donneesEtLeurLecteur.entries) {
        final fichiers = <String>[];
        for (final f in sources) {
          if (sansCommentaires(f.readAsStringSync()).contains(e.key)) {
            fichiers.add(f.path);
          }
        }
        if (fichiers.isEmpty) continue; // la donnee a ete retiree : tres bien
        // Un seul fichier de saisie plus sa propre definition = personne ne lit.
        final lecteursUtiles = fichiers.where((p) {
          final s = p.toLowerCase();
          return !s.contains('provider') && !s.contains('presentation');
        }).toList();
        final ecransLecteurs =
            fichiers.where((p) => p.contains('/presentation/')).toList();
        if (lecteursUtiles.isEmpty && ecransLecteurs.length <= 1) {
          orphelines.add('${e.key} : ${e.value}\n      lue seulement par '
              '${fichiers.join(', ')}');
        }
      }
      expect(orphelines, isEmpty,
          reason: 'DONNEES COLLECTEES QUE PERSONNE NE LIT : l application les '
              'demande, les sauvegarde, les synchronise, les restaure — et '
              'aucun calcul ni aucun ecran ne s en sert.\n'
              '  ${orphelines.join('\n  ')}');
    });
  });

  group('LE MEFIANT — d ou vient ce chiffre ?', () {
    testWidgets('le verdict de faisabilite montre son calcul, pas seulement son '
        'resultat', (tester) async {
      // Retour 9 : « Le verdict c'est du blabla d'IA ». Un calcul solide qu'on
      // ne montre pas est indiscernable d'un baratin. L'ecran doit porter, la ou
      // le verdict tombe : la journee la plus dure, sa conversion en
      // kilometres-energie, le plafond du randonneur, et le rapport des deux.
      final concret = cheminConcret('/trail/:id/feasibility')!;
      await monterAppliReelle(tester, depart: concret);
      final textes = textesVisibles(tester).join(' \n ').toLowerCase();
      await demonterAppli(tester);
      erreursDeRendu(tester);

      // SUR UNE INSTALLATION NEUVE, LE VERDICT N EST PAS ENCORE CALCULE :
      // l'ecran propose d'abord le parcours guide (fiche, test de marche, randos
      // passees). Exiger le detail du calcul a ce moment-la serait reprocher a
      // l'application de ne pas afficher ce qu'elle n'a pas encore. On ne juge
      // donc que quand le verdict est la — et on le DIT quand ce n'est pas le
      // cas, au lieu de passer en silence.
      final verdictAffiche = textes.contains('decoupage') ||
          textes.contains('découpage') ||
          textes.contains('plafond conseill');
      if (!verdictAffiche) {
        markTestSkipped('le verdict n est pas affiche sur une installation '
            'neuve (parcours guide en cours) : ce controle demande un profil '
            'randonneur seme. TROU CONNU, a fermer avec un jeu de preferences '
            'de depart.');
        return;
      }

      final manques = <String>[];
      if (!textes.contains('km-énergie') && !textes.contains('km-energie')) {
        manques.add('la conversion en kilometres-energie');
      }
      if (!textes.contains('plafond')) manques.add('le plafond du randonneur');
      if (!textes.contains('42')) {
        manques.add('les 42 m de denivele qui valent 1 km de plat (Minetti)');
      }
      expect(manques, isEmpty,
          reason: 'LE VERDICT NE MONTRE PAS SON CALCUL : ${manques.join(', ')}. '
              'Un randonneur a qui on dit « tu ne passeras pas » sans montrer '
              'pourquoi n a aucun recours.');
    });
  });
}
