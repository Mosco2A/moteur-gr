import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';

/// TACHE 548 — LES ASSERTIONS « setState() called during build » DE LA
/// CAMPAGNE 547, ET LE MECANISME QUI LES PRODUIT.
///
/// CE QUE DIT RIVERPOD 3 (verifie dans le paquet, pas suppose) :
///  - un provider n'est rafraichi par l'ordonnanceur que s'il est ACTIF
///    (`element.dart` : `isActive => listenerCount - pausedActiveSubscriptionCount > 0`) ;
///    Riverpod 3 met en PAUSE les abonnements d'un ecran qui n'est plus a
///    l'avant-plan, donc un provider dont tous les auditeurs sont en pause
///    reste « a recalculer » ;
///  - ce recalcul se fait alors PARESSEUSEMENT, au premier `ref.watch` venu.
///    Si ce `ref.watch` tombe pendant la phase de build d'un widget,
///    `flush()` recalcule le provider, notifie ses autres derives, l'un d'eux
///    s'invalide (`invalidateSelf`) et demande un rafraichissement du
///    `ProviderScope` — soit un `setState()` pendant le build, que Flutter
///    refuse.
///
/// Les trois foyers de la campagne 547 sont trois facons d'amener ce premier
/// `ref.watch` dans la phase de build : un abonnement CONDITIONNEL (ecran de
/// faisabilite), un widget monte a CHAQUE navigation (`AppHeader`), une chaine
/// REMONTEE a la volee (`LocalizedConditionsBanner`).
///
/// GATE 0 D'ABORD : le harnais doit etre prouve capable de DIRE NON. Le premier
/// test reproduit volontairement le defaut et exige de le voir. Sans ce rouge,
/// les verts qui suivent ne valent rien.
void main() {
  /// Recolte les erreurs Flutter levees pendant [body] (Riverpod les passe par
  /// `FlutterError.reportError`, elles n'echouent donc pas le test toutes
  /// seules : il faut aller les chercher).
  Future<List<String>> erreursPendant(Future<void> Function() body) async {
    final captees = <String>[];
    final precedent = FlutterError.onError;
    FlutterError.onError = (details) => captees.add(details.exceptionAsString());
    try {
      await body();
    } finally {
      FlutterError.onError = precedent;
    }
    return captees;
  }

  bool estSetStatePendantBuild(String message) =>
      message.contains('setState() or markNeedsBuild() called during build');

  group('GATE 0 — le harnais sait dire non', () {
    testWidgets(
        'un provider laisse « a recalculer » SANS auditeur actif, puis observe '
        'pour la premiere fois pendant un build, leve bien l assertion',
        (tester) async {
      // Reproduction du mecanisme commun aux trois foyers, dans l'ordre exact
      // ou il se produit sur l'appareil :
      //   1. la source est invalidee alors qu'AUCUN ecran ne l'ecoute -> elle
      //      n'est pas rafraichie par l'ordonnanceur (elle n'est pas active) ;
      //   2. un widget se monte et l'observe POUR LA PREMIERE FOIS -> le
      //      recalcul se fait en pleine phase de build ;
      //   3. la valeur change, le derive se re-invalide et reclame un
      //      rafraichissement du `ProviderScope` : setState() pendant le build.
      var graine = 0;
      final source = FutureProvider<int>((ref) {
        ref.keepAlive();
        return Future<int>.value(graine);
      });
      final derive = Provider<int>((ref) {
        ref.keepAlive();
        return ref.watch(source).value ?? -1;
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: _HoteBascule(derive: derive))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('valeur 0'), findsOneWidget);

      final hote = tester.state<_HoteBasculeState>(find.byType(_HoteBascule));
      // On retire l'observateur : le derive n'a plus aucun auditeur actif.
      hote.montrer(false);
      await tester.pumpAndSettle();

      final erreurs = await erreursPendant(() async {
        // Meme frame : la source change ET l'observateur revient. Le recalcul
        // ne peut donc se faire que pendant le build de l'observateur.
        graine = 1;
        hote.invaliderPuisMontrer(source);
        await tester.pump();
        await tester.pumpAndSettle();
      });

      expect(
        erreurs.where(estSetStatePendantBuild),
        isNotEmpty,
        reason: 'le harnais doit voir l assertion quand elle est la — sans ce '
            'rouge, les verts des tests suivants ne prouvent rien',
      );
    });
  });

  group('Foyer 3 — chaine des etapes stable (domainStagesProvider)', () {
    StageModel etape(int n) => StageModel(
          trailId: 'sentier-test',
          stageNumber: n,
          name: 'Etape $n',
          description: '',
          distanceKm: 10 + n.toDouble(),
          elevationGainM: 500 + n * 10,
          elevationLossM: 400 + n * 10,
          startLat: 42.0 + n / 100,
          startLng: 9.0 + n / 100,
          endLat: 42.1 + n / 100,
          endLng: 9.1 + n / 100,
          difficulty: 'moderate',
        );

    test(
        'des etapes IDENTIQUES ne reveillent pas la chaine du trek '
        '(aucune invalidation, donc aucun recalcul paresseux a flusher '
        'pendant un build)', () async {
      var executions = 0;
      final container = ProviderContainer(
        overrides: [
          stagesProvider.overrideWith((ref) async {
            executions++;
            // Une NOUVELLE liste a chaque execution, avec le MEME contenu :
            // c'est exactement ce que fait le vrai provider
            // (`List.of(stages)..sort()`).
            return [etape(1), etape(2), etape(3)];
          }),
        ],
      );
      addTearDown(container.dispose);

      container.listen(domainStagesProvider, (_, __) {}, fireImmediately: true);
      await container.read(stagesProvider.future);
      expect(container.read(domainStagesProvider), hasLength(3));

      // Compteur pose APRES le premier chargement : on ne mesure que ce que
      // provoque la re-execution de la source.
      var recalculs = 0;
      container.listen(domainStagesProvider, (_, __) => recalculs++);

      // On rejoue la source : meme contenu, nouvelle liste, nouvelle identite.
      container.invalidate(stagesProvider);
      await container.read(stagesProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(executions, 2, reason: 'la source a bien ete rejouee');
      expect(
        recalculs,
        0,
        reason: 'des etapes identiques ne doivent RIEN invalider en aval : '
            'sinon toute la chaine du trek (plan de marche, detection '
            'd etape, arrivees) reste « a recalculer » et se fait flusher '
            'pendant le premier build qui la remonte',
      );
    });

    test('des etapes REELLEMENT differentes propagent bien le changement',
        () async {
      var seconde = false;
      final container = ProviderContainer(
        overrides: [
          stagesProvider.overrideWith((ref) async =>
              seconde ? [etape(1), etape(2)] : [etape(1), etape(2), etape(3)]),
        ],
      );
      addTearDown(container.dispose);

      container.listen(domainStagesProvider, (_, __) {}, fireImmediately: true);
      await container.read(stagesProvider.future);
      expect(container.read(domainStagesProvider), hasLength(3));

      var recalculs = 0;
      container.listen(domainStagesProvider, (_, __) => recalculs++);

      seconde = true;
      container.invalidate(stagesProvider);
      await container.read(stagesProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(domainStagesProvider), hasLength(2));
      expect(recalculs, greaterThan(0),
          reason: 'un vrai changement doit toujours se propager');
    });
  });
}

/// Hote du GATE 0 : monte/demonte a volonte l'unique observateur de [derive],
/// et sait invalider une source ET remonter l'observateur DANS LA MEME FRAME —
/// la seule facon d'obtenir un recalcul pendant la phase de build.
class _HoteBascule extends StatefulWidget {
  const _HoteBascule({required this.derive});

  final Provider<int> derive;

  @override
  State<_HoteBascule> createState() => _HoteBasculeState();
}

class _HoteBasculeState extends State<_HoteBascule> {
  bool _montre = true;
  FutureProvider<int>? _aInvalider;

  void montrer(bool valeur) => setState(() => _montre = valeur);

  void invaliderPuisMontrer(FutureProvider<int> source) => setState(() {
        _aInvalider = source;
        _montre = true;
      });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final aInvalider = _aInvalider;
        if (aInvalider != null) {
          _aInvalider = null;
          ref.invalidate(aInvalider);
        }
        if (!_montre) return const SizedBox.shrink();
        return _Observateur(derive: widget.derive);
      },
    );
  }
}

/// Observateur monte/demonte : son `ref.watch` est donc un PREMIER abonnement
/// a chaque remontage — exactement ce que fait un `AppHeader` a chaque
/// navigation, ou le bandeau meteo quand la phase « Randonner » le remonte.
class _Observateur extends ConsumerWidget {
  const _Observateur({required this.derive});

  final Provider<int> derive;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Text('valeur ${ref.watch(derive)}');
}
