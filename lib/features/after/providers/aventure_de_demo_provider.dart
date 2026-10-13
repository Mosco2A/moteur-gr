/// L'APRES-RANDONNEE DE LA DEMONSTRATION : UNE MATIERE FABRIQUEE, ET SA TRACE.
///
/// TACHE 810 — EN DEMO, TOUT SE VOIT, RIEN NE S'ECRIT (loi de Christophe du
/// 11/10/2026 09:27). Voir `lib/domain/matiere_de_demo.dart` pour la loi, la
/// cause mesuree du vide, et les trois proprietes de la matiere.
///
/// POURQUOI UN FICHIER A PART, ET PAS DANS `adventure_recap_provider.dart`. Le
/// plafond ECR-15 est a 500 lignes et ce fichier-la en comptait deja 352 : y
/// poser la matiere l'aurait fait franchir la barre, et le plafond du depot
/// (`test/structurel/taille_et_rangement_645_test.dart`) aurait rougi a juste
/// titre. La separation est d'ailleurs bonne en soi : d'un cote ce que
/// l'apres-randonnee LIT, de l'autre ce que la demonstration FABRIQUE.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/session_track_points_dao.dart';
import '../../../core/data/database.dart' hide Stage;
import '../../../core/engine/trail_engine.dart';
import '../../../core/services/session_demo.dart';
import '../../../domain/matiere_de_demo.dart';
import '../../map/map_facade.dart' show statsTraceProvider;
import '../../trek/trek_facade.dart' show domainStagesProvider;

/// LA MATIERE FABRIQUEE DE LA DEMONSTRATION, ou `null` hors demonstration.
///
/// AUCUNE GARDE N'EST DESARMEE ICI, ET C'EST LE POINT. Le recapitulatif et le
/// diplome n'etaient pas fermes par une garde de demonstration — il n'en existe
/// aucune sur ces deux ecrans. Ils etaient VIDES FAUTE DE DONNEES : la demo ne
/// persiste aucune session, donc `latestTrekSessionProvider` rendait `null`,
/// donc `isRecapAvailableProvider` et `isDiplomaUnlockedProvider` rendaient
/// `false` par fail-closed. Ces deux gardes lisent toujours EXACTEMENT la meme
/// chose, et restent fail-closed quand elles ne lisent rien ; ce qui change,
/// c'est qu'en demonstration elles ont desormais quelque chose a lire.
///
/// `generationDeDemoProvider` est lu pour que la matiere soit NEUVE a chaque
/// entree en demonstration : Riverpod ne recalcule pas un provider dont la
/// dependance a retrouve sa valeur precedente, et sortir puis rentrer rend
/// `true` apres `true` (cf. l'en-tete de `session_demo.dart`).
final matiereDeDemoProvider = Provider<MatiereDeDemo?>((ref) {
  if (!ref.watch(enDemoProvider)) return null;
  ref.watch(generationDeDemoProvider);
  final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
  final etapes = ref.watch(domainStagesProvider);
  if (etapes.isEmpty) return null;
  return MatiereDeDemo.pourSentier(
    trailId: trailId,
    etapes: etapes,
    arriveeLe: DateTime.now(),
  );
});

/// LA TRACE FABRIQUEE : LA TRACE REELLE DU SENTIER, DATEE JOUR PAR JOUR.
///
/// On ne dessine pas une trace inventee. La demonstration marche le sentier
/// REEL, donc sa trace EST celle du sentier ([statsTraceProvider], la meme que
/// la carte et le carnet lisent). Ce provider ne fait que lui donner ce qu'une
/// trace de session porte en plus d'un trace de sentier : un jour de marche et
/// une etape par point, et un horodatage.
///
/// LA REPARTITION SE FAIT AU PRORATA DE LA DISTANCE DES ETAPES, pas en parts
/// egales : une etape de 19,9 km recoit plus de points qu'une de 8,1 km, comme
/// sur le terrain. C'est aussi ce qui rend les comptes de points des journees
/// (`adventureDaysProvider`) coherents avec leurs distances.
///
/// AUCUN CHIFFRE DU RECAPITULATIF NE VIENT DE CETTE TRACE : distance, denivele
/// et duree restent ceux des etapes du sentier. Elle est DESSINEE, et c'est
/// tout — exactement le partage que `adventureStatsProvider` documente deja.
final traceFabriqueeDeDemoProvider = FutureProvider<List<SessionTrackPoint>>((
  ref,
) async {
  final matiere = ref.watch(matiereDeDemoProvider);
  if (matiere == null || matiere.estVide) {
    return const <SessionTrackPoint>[];
  }
  final trace = await ref.watch(statsTraceProvider.future);
  if (trace == null || trace.length < 2) return const <SessionTrackPoint>[];

  final journees = matiere.journees;
  final total = journees.fold<double>(0, (a, j) => a + j.etape.distance);
  if (total <= 0) return const <SessionTrackPoint>[];

  // Bornes de chaque journee en FRACTION de la trace, cumulees.
  final bornes = <double>[];
  var cumul = 0.0;
  for (final JourneeFabriquee j in journees) {
    cumul += j.etape.distance;
    bornes.add(cumul / total);
  }

  final points = <SessionTrackPoint>[];
  for (var i = 0; i < trace.length; i++) {
    final fraction = trace.length == 1 ? 0.0 : i / (trace.length - 1);
    var index = 0;
    while (index < bornes.length - 1 && fraction > bornes[index]) {
      index++;
    }
    final journee = journees[index];
    // Position du point DANS sa journee, pour l'horodater entre le depart et
    // l'arrivee de cette journee-la.
    final debut = index == 0 ? 0.0 : bornes[index - 1];
    final fin = bornes[index];
    final part = fin > debut ? ((fraction - debut) / (fin - debut)) : 0.0;
    final avance = part.clamp(0.0, 1.0);
    final p = trace[i];
    points.add(
      SessionTrackPoint(
        // Jamais insere : l'identifiant ne sert qu'a satisfaire le type de la
        // ligne. Negatif, donc reconnaissable (cf. `MatiereDeDemo`).
        id: -(i + 1),
        trailId: matiere.session.trailId,
        sessionId: MatiereDeDemo.idSessionFabriquee,
        dayIndex: journee.numero,
        stageId: journee.etape.id,
        lat: p.lat,
        lng: p.lng,
        altitude: p.altitude,
        recordedAt: journee.depart.add(
          Duration(
            milliseconds: (journee.duree.inMilliseconds * avance).round(),
          ),
        ),
        source: TrackPointSource.gps.stored,
      ),
    );
  }
  return points;
});
