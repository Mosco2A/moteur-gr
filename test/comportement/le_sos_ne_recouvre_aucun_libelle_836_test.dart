/// LA GARDE QUI REFUSE QUE LA PASTILLE SOS RECOUVRE UN LIBELLE (836).
///
/// ---------------------------------------------------------------------------
/// CE QUI A ETE SIGNALE, ET CE QUE LA MESURE A TROUVE
/// ---------------------------------------------------------------------------
///
/// Sur le paquet du 11/10, la pastille rouge du cockpit masquait trois choses :
/// le sous-titre de la tuile « Adapter l'itineraire », le bouton « Terminer le
/// trek » et le titre « Informations ».
///
/// LE BOUTON N'Y ETAIT POUR RIEN, et la tache 801 l'avait deja etabli au
/// pixel : le disque est entier et garde ses 16 points de marge. Le defaut
/// est une SOUSTRACTION QUE PERSONNE NE FAISAIT. Un `floatingActionButton`
/// FLOTTE : il
/// est peint par-dessus le `body` et ne retire rien a la place que le `body`
/// croit avoir. Le `ListView` du cockpit n'avait que son padding de 16 points
/// en bas, alors que la pastille occupe une bande de 72 + 16 points. Tout ce
/// qui finissait dans cette bande passait dessous.
///
/// ET C'EST EN PHASE RANDO QUE C'ETAIT LE PIRE, parce que c'est la seule phase
/// ou le SOS est visible — et c'est aussi celle ou la `bottomNavigationBar` est
/// volontairement retiree (« le bas de l'ecran appartient a la pastille SOS »).
/// Rien ne venait donc plus eloigner le contenu du bas.
///
/// ---------------------------------------------------------------------------
/// CE QUE CETTE GARDE MESURE, ET POURQUOI ELLE MESURE
/// ---------------------------------------------------------------------------
///
/// Flutter ne crie PAS quand un widget flottant recouvre du texte : les deux
/// sont peints, l'un sur l'autre, et personne ne leve d'exception. C'est la
/// meme lecon que `aucun_texte_coupe_749_test.dart` et que
/// `rien_ne_sort_de_l_ecran_801_test.dart` : la seule facon de voir le defaut
/// est de demander a chaque boite OU ELLE TOMBE, puis de comparer les
/// rectangles.
///
/// ON MESURE EN BAS DE COURSE. Le recouvrement n'apparait qu'une fois le
/// cockpit DEFILE jusqu'au bout, puisque c'est la que le dernier bouton arrive
/// sous la pastille. Un test qui ne defile pas serait vert avec le defaut sous
/// les yeux.
///
/// LE TEMOIN, SANS QUOI LA GARDE N'AFFIRMERAIT RIEN. Le dernier test lui soumet
/// une mise en page VOLONTAIREMENT fautive — la pastille et un bouton pleine
/// largeur dans un `ListView` sans reserve, c'est-a-dire le cockpit d'avant ce
/// lot — et exige qu'elle la REFUSE. Sans ce temoin, une garde verte ne
/// prouverait pas qu'elle sait voir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/features/hub/presentation/hub_screen.dart';
import 'package:moteur_gr/features/safety/safety_facade.dart'
    show SosButton, SosQuiReserveSaPlace;
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import '../structurel/regie_pub_absente.dart';

/// LES LARGEURS DE TELEPHONE MESUREES, reprises de la garde 801.
///
/// 320 est le plus petit encore vendu, 412 le plus large courant.
const List<double> _largeurs = <double>[320, 360, 390, 412];

/// La hauteur du cadre : celle d'un telephone courant, assez courte pour que le
/// cockpit DEFILE vraiment.
const double _hauteur = 844;

/// La tolerance : un centieme de point logique.
///
/// Elle n'absorbe que l'arrondi des flottants de la mise en page. Le plus petit
/// recouvrement visible se compte en points entiers.
const double _tolerance = 0.01;

class _SessionFigee extends TrekSessionManagerNotifier {
  _SessionFigee(this._etat);
  final TrackingSessionState _etat;
  @override
  TrackingSessionState build() => _etat;
}

void main() {
  // AUCUNE REGIE PUBLICITAIRE : le cockpit porte un emplacement de banniere, et
  // sans cette declaration chaque test toucherait le SDK Google Mobile Ads,
  // dont les canaux muets font pendre l'amorce six secondes de temps reel.
  setUp(brancherAucuneRegiePub);

  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  Widget enveloppe({required List<Override> overrides}) {
    final routeur = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HubScreen()),
        // Cibles neutres : aucune navigation ne doit casser au montage.
        for (final chemin in <String>[
          '/map',
          '/journal',
          '/catalog',
          '/profile',
          '/training',
          '/health',
          '/accommodations-nearby',
          '/trail/:id/adjust',
          '/trail/:id/planning',
          '/trail/:id/feasibility',
          '/trail/:id/checklist',
          '/trail/:id/tips',
          '/trail/:id/guides',
          '/trail/:id/diploma',
          '/trail/:id/recap',
          '/trail/:id/import-gpx',
          '/trail/:id/feedback',
          '/trail/:id/fire-risk',
          '/trail/:id/weather',
        ])
          GoRoute(path: chemin, builder: (_, __) => const SizedBox()),
      ],
    );
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: routeur),
      ),
    );
  }

  /// Monte le cockpit EN RANDO a [largeur], puis defile jusqu'au bout.
  ///
  /// La phase rando est celle du defaut : c'est la seule ou le SOS est visible,
  /// et celle ou le bas de l'ecran n'a plus de banniere pour eloigner le
  /// contenu.
  Future<void> monteLeCockpitEnRando(
    WidgetTester tester, {
    required double largeur,
  }) async {
    tester.view.physicalSize = Size(largeur, _hauteur);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      enveloppe(
        overrides: [
          authStateProvider.overrideWithValue(
            const AuthUser(
              uid: 'test-uid',
              authMethod: AuthMethodValues.anonymous,
              displayName: 'Alex',
            ),
          ),
          trekSessionManagerProvider.overrideWith(
            () => _SessionFigee(
              const TrackingSessionState(
                status: TrackingSessionStatus.recording,
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // JUSQU'AU BOUT DE LA COURSE. Le recouvrement est en FIN de scroll : c'est
    // la que le dernier bouton arrive sous la pastille. On tire plusieurs fois
    // plutot qu'une, pour ne pas dependre de la hauteur du contenu.
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// Les rectangles des libelles que la pastille recouvrait, quand ils sont
  /// rendus.
  ///
  /// Un libelle absent n'est pas une faute de mise en page : selon la largeur,
  /// la fin de course ne montre pas forcement les trois a la fois. On mesure ce
  /// qui est la, et le test verifie par ailleurs qu'il y a bien eu de quoi
  /// mesurer.
  Map<String, Rect> libellesRendus(WidgetTester tester) {
    final cibles = <String, String>{
      'le bouton « Terminer le trek »': t.hub.finishTrek.action,
      'le titre « Informations »': t.hub.sections.info,
      'la tuile « Adapter l\'itineraire »': t.hub.cards.adjust,
      'le sous-titre de « Adapter l\'itineraire »': t.hub.cards.adjustSub,
    };
    final mesures = <String, Rect>{};
    cibles.forEach((nom, texte) {
      final trouve = find.text(texte);
      if (trouve.evaluate().length == 1) {
        mesures[nom] = tester.getRect(trouve);
      }
    });
    return mesures;
  }

  group('LE SOS NE RECOUVRE AUCUN LIBELLE (836)', () {
    for (final largeur in _largeurs) {
      testWidgets(
        'en fin de defilement, aucun libelle du cockpit ne passe sous la '
        'pastille sur ${largeur.toInt()} points',
        (tester) async {
          await monteLeCockpitEnRando(tester, largeur: largeur);

          // La pastille est bien la : sans elle, la garde serait verte faute de
          // mesurer quoi que ce soit.
          expect(
            find.byType(SosQuiReserveSaPlace),
            findsOneWidget,
            reason:
                'la pastille qui reserve sa place n est pas montee : le '
                'cockpit a-t-il repris un SosButton nu en '
                'floatingActionButton ?',
          );
          final pastille = tester.getRect(
            find.descendant(
              of: find.byType(SosQuiReserveSaPlace),
              matching: find.byType(FloatingActionButton),
            ),
          );

          final mesures = libellesRendus(tester);
          expect(
            mesures,
            isNotEmpty,
            reason:
                'aucun des libelles surveilles n est rendu en fin de '
                'defilement : la garde ne prouve rien.',
          );

          final recouverts = <String>[];
          mesures.forEach((nom, boite) {
            // DEUX RECTANGLES SE RECOUVRENT quand ils se chevauchent sur les
            // DEUX axes a la fois. La tolerance ne pardonne que l arrondi : un
            // contact bord a bord n est pas un recouvrement.
            final chevauche =
                boite.left < pastille.right - _tolerance &&
                boite.right > pastille.left + _tolerance &&
                boite.top < pastille.bottom - _tolerance &&
                boite.bottom > pastille.top + _tolerance;
            if (chevauche) {
              recouverts.add(
                '$nom (${boite.left.toStringAsFixed(1)}'
                ',${boite.top.toStringAsFixed(1)} -> '
                '${boite.right.toStringAsFixed(1)}'
                ',${boite.bottom.toStringAsFixed(1)})',
              );
            }
          });

          expect(
            recouverts,
            isEmpty,
            reason:
                'LA PASTILLE SOS RECOUVRE ${recouverts.length} LIBELLE(S) sur '
                'un ecran de ${largeur.toInt()} points. Pastille mesuree en '
                '(${pastille.left.toStringAsFixed(1)}'
                ',${pastille.top.toStringAsFixed(1)} -> '
                '${pastille.right.toStringAsFixed(1)}'
                ',${pastille.bottom.toStringAsFixed(1)}).\n   '
                '${recouverts.join('\n   ')}',
          );
        },
      );
    }

    // LA RESERVE ELLE-MEME, MESUREE. Les tests ci-dessus disent « rien ne se
    // recouvre » ; celui-ci dit POURQUOI, et c'est le chiffre qu'on peut
    // comparer a la bande que la pastille occupe reellement. Sans lui, un
    // cockpit dont le contenu serait simplement trop court passerait pour
    // corrige.
    testWidgets('le defilement du cockpit reserve une bande AU MOINS aussi '
        'haute que la pastille', (tester) async {
      await monteLeCockpitEnRando(tester, largeur: 360);

      final pastille = tester.getRect(
        find.descendant(
          of: find.byType(SosQuiReserveSaPlace),
          matching: find.byType(FloatingActionButton),
        ),
      );
      final liste = tester.widget<ListView>(find.byType(ListView));
      final retrait = liste.padding! as EdgeInsets;

      expect(
        retrait.bottom,
        greaterThan(pastille.height),
        reason:
            'LA RESERVE BASSE A DISPARU : le defilement du cockpit ne laisse '
            'que ${retrait.bottom.toStringAsFixed(1)} points sous son dernier '
            'enfant, alors que la pastille en occupe '
            '${pastille.height.toStringAsFixed(1)}. Le contenu repassera donc '
            'sous le disque rouge.',
      );
    });

    // ------------------------------------------------------------------------
    // LE TEMOIN : la mesure REFUSE le cockpit d'avant ce lot.
    // ------------------------------------------------------------------------
    testWidgets('TEMOIN — sans reserve basse, la mesure voit le '
        'recouvrement', (tester) async {
      tester.view.physicalSize = const Size(360, _hauteur);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // LA MISE EN PAGE FAUTIVE, telle qu'elle etait : la pastille en
      // `startFloat`, un `ListView` avec 16 points de padding bas, et un bouton
      // pleine largeur en dernier. Aucune reserve.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trekSessionManagerProvider.overrideWith(
              () => _SessionFigee(
                const TrackingSessionState(
                  status: TrackingSessionStatus.recording,
                ),
              ),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              home: Scaffold(
                floatingActionButton: const SosButton(),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.startFloat,
                body: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: _hauteur),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () {},
                          child: Text(t.hub.finishTrek.action),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final pastille = tester.getRect(find.byType(FloatingActionButton));
      final bouton = tester.getRect(find.text(t.hub.finishTrek.action));

      final chevauche =
          bouton.left < pastille.right - _tolerance &&
          bouton.right > pastille.left + _tolerance &&
          bouton.top < pastille.bottom - _tolerance &&
          bouton.bottom > pastille.top + _tolerance;

      expect(
        chevauche,
        isTrue,
        reason:
            'LA MESURE NE VOIT PLUS RIEN. Soumise a la mise en page fautive '
            'd origine — pastille flottante sur un ListView sans reserve — '
            'elle devrait constater le recouvrement. Si elle ne le voit pas, '
            'les tests verts ci-dessus ne prouvent rien.',
      );
    });
  });
}
