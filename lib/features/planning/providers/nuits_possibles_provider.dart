/// Les nuits qu'un sentier offre au decoupage, lues dans SA donnee — et le
/// decoupage que le curseur de duree en tire.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_catalog.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../domain/nuit_possible.dart';

/// LES NUITS POSSIBLES DU SENTIER COURANT (tache 839).
///
/// Lues dans `TrailConfig.possibleNightsAssetPath`, donc dans la DONNEE du
/// sentier : aucun lieu n'est ecrit dans le moteur. Un sentier qui n'en fournit
/// pas rend [DecoupageDeNuits.aucun] et rien ne change pour lui — le curseur de
/// duree se comporte comme avant.
///
/// REPLI GRACIEUX ASSUME. Un fichier absent ou illisible rend « aucun » plutot
/// que de faire tomber l'ecran : le decoupage sur les nuits est un
/// ENRICHISSEMENT, et un enrichissement qui casse l'application quand il manque
/// n'en est pas un.
final decoupageDeNuitsProvider = FutureProvider<DecoupageDeNuits>((ref) async {
  final chemin = ref.watch(
    trailConfigProvider.select((c) => c.possibleNightsAssetPath),
  );
  if (chemin == null) return DecoupageDeNuits.aucun;
  try {
    final texte = await rootBundle.loadString(chemin);
    return DecoupageDeNuits.fromJson(
      json.decode(texte) as Map<String, dynamic>,
    );
  } catch (_) {
    return DecoupageDeNuits.aucun;
  }
});

/// LES NUITS D'UN SENTIER DESIGNE, ET NON DU SENTIER ACTIF (tache 848).
///
/// POURQUOI CETTE SECONDE FAMILLE EXISTE. La FICHE d'un sentier s'ouvre sans
/// que ce sentier devienne le sentier actif : la carte du catalogue fait
/// `push('/trail/:id')`, et c'est le bouton « Preparer » — lui seul — qui ecrit
/// la selection. Une fiche qui lirait les nuits du sentier ACTIF annoncerait
/// donc la difficulte d'un autre chemin que celui qu'elle decrit. Le meme
/// raisonnement a deja ete tenu pour la fiche elle-meme
/// (`ficheDeSentierProvider`), et pour la meme raison.
///
/// ELLE RESOUT PAR LE CATALOGUE, QUI EST STATIQUE, et ne consulte AUCUN
/// provider du sentier actif : c'est la lecon mesuree des taches 796 et 841 —
/// une famille par sentier qui lit une source du sentier actif garde en vie
/// l'element du sentier precedent, lequel s'invalide en pleine phase de build.
final nuitsDuSentierProvider = FutureProvider.family<DecoupageDeNuits, String>((
  ref,
  trailId,
) async {
  final chemin = TrailCatalog.byId(trailId)?.possibleNightsAssetPath;
  if (chemin == null || chemin.isEmpty) return DecoupageDeNuits.aucun;
  try {
    final texte = await rootBundle.loadString(chemin);
    return DecoupageDeNuits.fromJson(
      json.decode(texte) as Map<String, dynamic>,
    );
  } catch (_) {
    // Meme repli gracieux que ci-dessus : un enrichissement qui casse l'ecran
    // quand il manque n'en est pas un.
    return DecoupageDeNuits.aucun;
  }
});

/// Le decoupage d'un sentier DESIGNE, charge, ou « aucun » tant qu'il n'est pas
/// la — la fiche affiche alors les journees tirees des etapes, puis s'enrichit.
final decoupageDuSentierProvider = Provider.family<DecoupageDeNuits, String>((
  ref,
  trailId,
) {
  return ref
      .watch(nuitsDuSentierProvider(trailId))
      .maybeWhen(data: (d) => d, orElse: () => DecoupageDeNuits.aucun);
});

/// Le decoupage charge, ou « aucun » tant qu'il n'est pas la (jamais d'attente
/// bloquante : l'ecran affiche le programme en etapes, puis s'enrichit).
///
/// Le decoupage REPARTI sur la duree choisie vit dans `planning_provider.dart`
/// (`journeesSurLesNuitsProvider`), aupres du curseur dont il depend : le
/// mettre ici aurait rendu les deux fichiers mutuellement dependants.
final decoupageDeNuitsChargeProvider = Provider<DecoupageDeNuits>((ref) {
  return ref
      .watch(decoupageDeNuitsProvider)
      .maybeWhen(data: (d) => d, orElse: () => DecoupageDeNuits.aucun);
});
