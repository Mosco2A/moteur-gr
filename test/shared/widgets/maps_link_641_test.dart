import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/shared/widgets/maps_link.dart';

/// BUG 15 — « HEBERGEMENT IL DOIT AVOIR UNE ADRESSE ET UN POINT GPS QUI LINK SUR
/// MAPS » (Christophe, 30/09 10:23).
///
/// LE CRITERE DE RECETTE EST EN DEUX MOITIES, ET LA PREMIERE EST LA PLUS
/// IMPORTANTE : « lieu sans GPS = pas de lien mort, lieu avec GPS = intent Maps ».
/// Un bouton qui a l air actif et ne fait rien est pire qu un bouton absent — c est
/// le meme defaut que Christophe a releve quatre fois dans ce test (bugs 4, 14,
/// 16). Ces tests verifient d abord l ABSENCE du lien quand il ne menerait nulle
/// part.
void main() {
  Widget sujet(LieuCliquable lieu, {MapsOpener? ouvreur}) {
    return ProviderScope(
      overrides: [
        if (ouvreur != null) mapsOpenerProvider.overrideWithValue(ouvreur),
      ],
      child: MaterialApp(
        home: Scaffold(body: LigneDeLieu(lieu: lieu)),
      ),
    );
  }

  group('641 / bug 15 — PAS DE LIEN MORT', () {
    testWidgets(
      'un lieu sans adresse ni point n affiche RIEN — ni libelle vide, '
      'ni bouton inerte',
      (tester) async {
        await tester.pumpWidget(
          sujet(const LieuCliquable(nom: 'Refuge inconnu')),
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('lieu-ouvrir-cartes')), findsNothing);
        expect(find.byKey(const ValueKey('lieu-adresse')), findsNothing);
      },
    );

    testWidgets(
      'UN POINT A 0,0 N EST PAS UN POINT. La colonne `lat`/`lng` de la '
      'base n est pas nullable : un lieu sans coordonnees connues y arrive a '
      'zero, qui est un point REEL au large du Ghana. Un lien vers lui ne '
      'serait pas vide, il serait FAUX',
      (tester) async {
        await tester.pumpWidget(
          sujet(
            const LieuCliquable(nom: 'Gite sans coordonnees', lat: 0, lng: 0),
          ),
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('lieu-ouvrir-cartes')), findsNothing);
        expect(
          MapsOpener.adressesPour(
            const LieuCliquable(nom: 'x', lat: 0, lng: 0),
          ),
          isEmpty,
        );
      },
    );

    testWidgets(
      '« a completer » N EST PAS UNE ADRESSE. Le contenu publie le dit '
      'quand il ne sait pas — c est un marqueur pour l editeur, pas une '
      'information pour le randonneur',
      (tester) async {
        await tester.pumpWidget(
          sujet(
            const LieuCliquable(nom: 'Arret d autocar', adresse: 'a completer'),
          ),
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('lieu-adresse')), findsNothing);
        expect(find.byKey(const ValueKey('lieu-ouvrir-cartes')), findsNothing);
        expect(find.text('a completer'), findsNothing);
      },
    );

    // AJOUTE PAR LE LOT 645-08. Le motif portait un espace UNIQUE en dur :
    // « a  completer » avec deux espaces, une tabulation ou un retour a la
    // ligne — ce que produit n'importe quel passage par un tableur ou un
    // export — traversait le filtre et s'affichait au randonneur comme une
    // adresse. Le motif est passe a `\s+` aux trois endroits.
    test('l aveu reste un aveu quel que soit son espacement', () {
      for (final avoue in <String>[
        'a completer',
        'a  completer',
        'a\tcompleter',
        '  A COMPLETER  ',
        'à compléter',
        'à   compléter',
        'to be completed',
        'to  be\tcompleted',
      ]) {
        expect(
          LieuCliquable(nom: 'Arret', adresse: avoue).aUneAdresse,
          isFalse,
          reason: '« $avoue » est un marqueur d editeur, pas une adresse',
        );
      }
      // ET IL NE DEBORDE PAS : une vraie adresse qui contient le mot reste
      // une adresse.
      for (final vraie in <String>[
        'Route a completer par le village',
        '12 rue du Completer',
      ]) {
        expect(
          LieuCliquable(nom: 'Arret', adresse: vraie).aUneAdresse,
          isTrue,
          reason:
              '« $vraie » est une adresse, le motif est ancre aux deux '
              'bouts',
        );
      }
    });

    test('une latitude hors bornes est refusee — une donnee corrompue ne doit '
        'pas produire un lien de carte', () {
      expect(const LieuCliquable(nom: 'x', lat: 200, lng: 9).aUnPoint, isFalse);
      expect(
        const LieuCliquable(nom: 'x', lat: 42, lng: 500).aUnPoint,
        isFalse,
      );
      expect(
        const LieuCliquable(nom: 'x', lat: double.nan, lng: 9).aUnPoint,
        isFalse,
      );
    });
  });

  group('641 / bug 15 — LIEU AVEC GPS : LE LIEN EXISTE ET IL OUVRE LES CARTES', () {
    testWidgets('adresse affichee et bouton present', (tester) async {
      await tester.pumpWidget(
        sujet(
          const LieuCliquable(
            nom: 'Gite de Catastaghju',
            adresse: 'Catastaghju, 20243 San-Gavino-di-Fiumorbo',
            lat: 41.957,
            lng: 9.287,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('lieu-adresse')), findsOneWidget);
      expect(
        find.text('Catastaghju, 20243 San-Gavino-di-Fiumorbo'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('lieu-ouvrir-cartes')), findsOneWidget);
    });

    testWidgets('appuyer sur le lien demande l ouverture du lieu', (
      tester,
    ) async {
      final ouvreur = _OuvreurEspion(reussit: true);
      await tester.pumpWidget(
        sujet(
          const LieuCliquable(
            nom: 'Ponton de la navette',
            lat: 41.8903,
            lng: 8.8128,
          ),
          ouvreur: ouvreur,
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('lieu-ouvrir-cartes')));
      await tester.pump();

      expect(ouvreur.demandes, hasLength(1));
      expect(ouvreur.demandes.single.nom, 'Ponton de la navette');
    });

    testWidgets(
      'L ECHEC SE DIT. Un geste qui ne produit rien et ne dit rien est '
      'pire qu un bouton absent : le randonneur ne sait pas s il a mal appuye',
      (tester) async {
        final ouvreur = _OuvreurEspion(reussit: false);
        await tester.pumpWidget(
          sujet(
            const LieuCliquable(nom: 'Fontaine', lat: 41.995, lng: 9.37),
            ouvreur: ouvreur,
          ),
        );
        await tester.pump();

        await tester.tap(find.byKey(const ValueKey('lieu-ouvrir-cartes')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    test(
      'LE POINT PART DANS UNE ADRESSE DE CARTES UNIVERSELLE, et le repli web '
      'existe TOUJOURS. Un schema natif peut echouer pour une raison qu on ne '
      'controle pas : aucune application declaree, canal de plateforme absent, '
      'Plans desinstalle. Rendre « impossible d ouvrir » alors qu un navigateur '
      'aurait suffi serait un faux echec',
      () {
        final adresses = MapsOpener.adressesPour(
          const LieuCliquable(nom: 'Col de Laparo', lat: 41.9, lng: 9.15),
        );
        expect(adresses, isNotEmpty);
        expect(
          adresses.last.toString(),
          startsWith('https://www.google.com/maps/search/'),
          reason:
              'la derniere adresse essayee doit etre une URL web, qui s ouvre '
              'toujours',
        );
        expect(adresses.last.toString(), contains('41.9,9.15'));
      },
    );

    test(
      'SANS POINT MAIS AVEC UNE ADRESSE, ON FAIT CHERCHER L ADRESSE. C est la '
      'difference entre « je ne sais pas ou c est » et « je sais l ecrire mais '
      'pas la pointer », et la seconde merite un lien — c est le cas de la '
      'moitie des gites du Mare a Mare, dont les coordonnees publiees sont '
      'celles du centre du village',
      () {
        final adresses = MapsOpener.adressesPour(
          const LieuCliquable(
            nom: 'Office de tourisme',
            adresse: 'Route de Ghisoni, 20240 Ghisonaccia',
          ),
        );
        expect(adresses, isNotEmpty);
        expect(
          adresses.last.toString(),
          contains(Uri.encodeComponent('Route de Ghisoni, 20240 Ghisonaccia')),
        );
      },
    );

    test(
      'L ADRESSE PRIME SUR LE NOM COMME ETIQUETTE DE RECHERCHE : une adresse '
      'postale se geocode, un nom de gite corse pas toujours',
      () {
        final adresses = MapsOpener.adressesPour(
          const LieuCliquable(
            nom: 'Chez Paul-Antoine',
            adresse: '20153 Guitera-les-Bains',
            lat: 41.9147,
            lng: 9.1411,
          ),
        );
        expect(
          adresses.last.toString(),
          contains(Uri.encodeComponent('20153 Guitera-les-Bains')),
          reason:
              'la requete web part sur l adresse quand elle existe : les '
              'coordonnees publiees de la moitie des gites du Mare a Mare sont '
              'celles du CENTRE DU VILLAGE, pas de la porte du gite',
        );
      },
    );
  });
}

/// Un ouvreur de cartes qui NOTE ce qu on lui demande.
///
/// LE DOUBLE EST INDISPENSABLE ICI, ET PAS PAR COMMODITE : `launchUrl` exige un
/// canal de plateforme, absent d un test de widget. Sans double, ce test
/// verifierait la presence du bouton et rien de son effet — c est-a-dire
/// exactement le genre de geste mort que l invariante V3 du depot interdit.
class _OuvreurEspion extends MapsOpener {
  _OuvreurEspion({required this.reussit});

  final bool reussit;
  final List<LieuCliquable> demandes = <LieuCliquable>[];

  @override
  Future<bool> open(LieuCliquable lieu) async {
    demandes.add(lieu);
    return reussit;
  }
}
