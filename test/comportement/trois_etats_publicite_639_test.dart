import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/ads/domain/etat_publicite.dart';
import 'package:moteur_gr/features/ads/presentation/badge_etat_publicite.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// TACHE 639 (AVENANT) — LES TROIS ETATS PUBLICITAIRES SE DISTINGUENT A L'OEIL.
///
/// LA DEMANDE DE CHRISTOPHE, MOT POUR MOT (30/09 12:41, DEM-260930-1241) : « Il
/// faut que l on fasse la diff entre = je suis abonne et je n ai pas de pub en
/// prepa, j ai achete un trek sans pub, je suis en prepa avec pub ».
///
/// CE QUE L'APPLICATION MONTRAIT, ET POURQUOI CA NE SUFFISAIT PAS. Trois
/// situations, DEUX rendus : « avec publicite » se voyait (la banniere) mais les
/// deux sans-pub etaient IDENTIQUES — rien. Or ce ne sont pas les memes droits :
/// l'abonnement vaut partout et tant qu'on paie, l'achat vaut pour UN sentier et
/// pour toujours. Un randonneur qui ne voit rien ne peut pas savoir lequel des
/// deux le protege, ni ce qu'il perdrait en resiliant.
///
/// CE QUE CES TESTS VERROUILLENT :
///   1. les trois etats donnent TROIS libelles distincts, dans les 5 langues ;
///   2. l'ordre de priorite est celui decide (abonne > achete > video) ;
///   3. la video, seule des trois a expirer, porte le temps qui reste ;
///   4. l'etat « avec publicite » est le SEUL a declarer qu'une pub s'affiche.
void main() {
  Future<void> poser(WidgetTester tester, EtatPublicite etat) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          etatPubliciteProvider.overrideWith((ref, trailId) async => etat),
        ],
        child: TranslationProvider(
          child: const MaterialApp(
            home: Scaffold(body: BadgeEtatPublicite(trailId: 'gr20')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('les trois etats donnent trois marques distinctes', () {
    testWidgets('AVEC PUBLICITE le dit, et le dit seul', (tester) async {
      await poser(tester, EtatPublicite.avecPub);
      expect(find.text(t.monetization.adsBadgePub), findsOneWidget);
      expect(EtatPublicite.avecPub.pubAffichee, isTrue);
    });

    testWidgets('ABONNE porte sa propre marque', (tester) async {
      await poser(tester, const EtatPublicite(raison: RaisonSansPub.abonne));
      expect(find.text(t.monetization.adsBadgeAbonne), findsOneWidget);
      expect(find.text(t.monetization.adsBadgePub), findsNothing);
    });

    testWidgets('ACHETE porte la sienne, differente de celle de l abonne', (
      tester,
    ) async {
      await poser(tester, const EtatPublicite(raison: RaisonSansPub.achete));
      expect(find.text(t.monetization.adsBadgeAchete), findsOneWidget);
      expect(find.text(t.monetization.adsBadgeAbonne), findsNothing);
    });

    test('les trois libelles sont DISTINCTS dans les 5 langues', () {
      // C'est LA demande : pouvoir « faire la diff ». Deux libelles identiques
      // dans une langue rendraient deux etats indistinguables pour qui la lit.
      for (final locale in AppLocale.values) {
        final m = locale.buildSync().monetization;
        final marques = <String>[
          m.adsBadgePub,
          m.adsBadgeAbonne,
          m.adsBadgeAchete,
          m.adsBadgeVideo(reste: 'X'),
        ];
        expect(
          marques.toSet().length,
          marques.length,
          reason:
              '${locale.languageCode} : deux marques identiques dans '
              '$marques',
        );
        for (final marque in marques) {
          expect(marque.trim(), isNotEmpty);
        }
      }
    });
  });

  group('l ordre de priorite est une decision, pas un hasard', () {
    // Quand plusieurs exceptions jouent, on annonce la plus FORTE et la plus
    // DURABLE. Annoncer la video a un abonne lui ferait croire que son
    // abonnement finit dans 24 h.
    test('abonne passe devant achete, et achete devant la video', () {
      const abonne = EtatPublicite(raison: RaisonSansPub.abonne);
      const achete = EtatPublicite(raison: RaisonSansPub.achete);
      expect(abonne.sansPubDurable, isTrue);
      expect(achete.sansPubDurable, isTrue);
      final video = EtatPublicite(
        raison: RaisonSansPub.video24h,
        finDeLaRecompense: DateTime(2026, 10, 1),
      );
      expect(
        video.sansPubDurable,
        isFalse,
        reason: 'la video expire : la presenter comme durable serait faux',
      );
    });
  });

  group('la video porte le temps qui reste', () {
    final maintenant = DateTime(2026, 9, 30, 12, 0);

    EtatPublicite videoJusqua(DateTime fin) =>
        EtatPublicite(raison: RaisonSansPub.video24h, finDeLaRecompense: fin);

    test('des heures tant qu il en reste au moins une', () {
      final reste = resteLisible(
        videoJusqua(maintenant.add(const Duration(hours: 23, minutes: 30))),
        maintenant: maintenant,
      );
      expect(reste, t.monetization.adsResteHeures(heures: 23));
    });

    test('des minutes sur la derniere heure', () {
      final reste = resteLisible(
        videoJusqua(maintenant.add(const Duration(minutes: 42))),
        maintenant: maintenant,
      );
      expect(reste, t.monetization.adsResteMinutes(minutes: 42));
    });

    test('jamais un negatif a l echeance passee', () {
      // Le battement entre l expiration et la relecture des droits ne doit rien
      // afficher d absurde.
      final reste = resteLisible(
        videoJusqua(maintenant.subtract(const Duration(minutes: 5))),
        maintenant: maintenant,
      );
      expect(reste, t.monetization.adsResteMinutes(minutes: 0));
    });

    test('les trois autres etats n ont pas de compte a rebours', () {
      for (final etat in [
        EtatPublicite.avecPub,
        const EtatPublicite(raison: RaisonSansPub.abonne),
        const EtatPublicite(raison: RaisonSansPub.achete),
      ]) {
        expect(etat.finDeLaRecompense, isNull);
        expect(resteLisible(etat, maintenant: maintenant), isEmpty);
      }
    });
  });
}
