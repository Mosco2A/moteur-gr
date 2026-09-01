// SW-SKIN-L3e — Tests de l'unification des composants (Card -> AppCard,
// *Button -> AppButton) sur le RESTE du parc (dernier sous-lot du LOT L3).
//
// Objectif : prouver que des widgets representatifs des domaines restants
// (core error view, popup POI carte, carte membre de groupe) utilisent
// desormais la grammaire unifiee AppCard/AppButton et PLUS aucune Card
// Material brute ni bouton Material brut, tout en gardant le tap fonctionnel
// (iso-fonction). L'iso-rendu visuel (padding, contenu, semantique, cibles
// tactiles) est preserve par construction dans les widgets ; ces tests
// verrouillent la substitution STRUCTURELLE et le COMPORTEMENT (tap, callback).
//
// La preuve exhaustive « 0 Card brute / 0 bouton brut sur TOUT lib/ » est
// assuree hors test par le grep de conversion (rapport L3e) ; ici on echantillonne
// les patterns cles : carte simple, callback de bouton, absence des widgets bruts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/core/ui/error_view.dart';
import 'package:moteur_gr/features/group/models/group_member.dart';
import 'package:moteur_gr/features/group/widgets/member_position_card.dart';
import 'package:moteur_gr/features/map/widgets/poi_popup.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';
import 'package:moteur_gr/shared/widgets/app_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // ---------------------------------------------------------------------------
  // core/ui/error_view.dart : FilledButton.icon -> AppButton (variante primary).
  // ---------------------------------------------------------------------------
  group('SW-SKIN-L3e — ErrorView', () {
    testWidgets(
      'rend un AppButton (plus de bouton Material brut) et pas de Card '
      'brute',
      (tester) async {
        await tester.pumpWidget(
          _wrap(ErrorView(message: 'Boom', onRetry: () {})),
        );

        // Grammaire unifiee presente.
        expect(find.byType(AppButton), findsOneWidget);
        // Boutons Material bruts absents (l'AppButton en interne EST un
        // ElevatedButton via la variante primary : on verifie donc l'ABSENCE
        // de FilledButton/OutlinedButton, plus l'usage direct d'AppButton).
        expect(find.byType(FilledButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
        expect(find.byType(Card), findsNothing);
      },
    );

    testWidgets('le bouton retry declenche bien onRetry (iso-fonction)', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(ErrorView(message: 'Boom', onRetry: () => tapped++)),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('sans onRetry, aucun AppButton n\'est rendu', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorView(message: 'Boom')));
      expect(find.byType(AppButton), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // map/widgets/poi_popup.dart : Card -> AppCard (elevation 6 conservee).
  // ---------------------------------------------------------------------------
  group('SW-SKIN-L3e — PoiPopup', () {
    const poi = PoiModel(
      trailId: 'gr20',
      stageNumber: 1,
      name: 'Refuge de Test',
      description: 'Un refuge de test',
      type: 'refuge',
      lat: 42.0,
      lng: 9.0,
      altitudeM: 1500,
      openingHours: '8h-20h',
    );

    testWidgets('rend un AppCard et plus aucune Card Material brute', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const PoiPopup(poi: poi)));

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      // Le contenu est preserve (iso-rendu du contenu).
      expect(find.text('Refuge de Test'), findsOneWidget);
      expect(find.text('1500 m'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // group/widgets/member_position_card.dart : Card -> AppCard.
  // ---------------------------------------------------------------------------
  group('SW-SKIN-L3e — MemberPositionCard', () {
    const member = GroupMember(
      uid: 'u1',
      displayName: 'Alice',
      lastLat: 42.0,
      lastLng: 9.0,
      lastUpdate: '2026-01-01T00:00:00.000Z',
    );

    testWidgets('rend un AppCard et plus aucune Card Material brute', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const MemberPositionCard(member: member)));

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
    });
  });
}
