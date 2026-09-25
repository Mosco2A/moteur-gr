import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/progress_dao.dart';
import '../../../core/models/user_progress.dart';
import '../../../core/providers/database_provider.dart';

/// Provider de la progression utilisateur sur un sentier.
///
/// Retourne null si aucune progression n'existe encore.
final progressProvider =
    FutureProvider.family<UserProgressModel?, String>((ref, trailId) async {
  final db = ref.watch(databaseProvider);
  final dao = ProgressDao(db);
  final row = await dao.getByTrailId(trailId);
  if (row == null) return null;
  return UserProgressModel.fromDb(row);
});

/// NUMERO DE L'ETAPE COURANTE, LU EN BASE (tache 558).
///
/// POURQUOI CE PROVIDER EXISTE. Le lot 554 avait signale le trou en toutes
/// lettres : « la colonne `currentStage` de la table de progression n'est lue
/// par aucun provider ». Elle etait pourtant ECRITE — le suivi de trek appelle
/// `ProgressDao.updateCurrentStage` a chaque changement d'etape — et la
/// restauration cloud la remonte. Une donnee ecrite que personne ne lit, c'est
/// une carte qui rouvre au depart du sentier alors que le randonneur en est a
/// son cinquieme jour. Chris, mot pour mot : « Je veux etre a la premiere etape
/// et voir le sentier !!! » — la premiere quand on n'est pas parti, la SIENNE
/// quand on l'est.
///
/// `null` quand il n'y a pas d'etape courante a montrer, et c'est un cas normal
/// et frequent : aucune progression enregistree (sentier jamais commence),
/// donnee pas encore chargee, ou trek DEJA TERMINE — un trek fini n'a plus
/// d'etape « en cours », et l'appelant retombe alors sur la premiere etape.
/// On ne devine jamais un numero : sans donnee, on ne dit rien.
final currentStageNumberProvider =
    Provider.family<int?, String>((ref, trailId) {
  final progress = ref.watch(progressProvider(trailId)).value;
  if (progress == null || progress.isCompleted) return null;
  final stageNumber = progress.currentStage;
  return stageNumber > 0 ? stageNumber : null;
});
