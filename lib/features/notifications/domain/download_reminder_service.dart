import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/data/daos/trail_manifests_dao.dart';
import '../../../core/providers/database_provider.dart';
import 'notification_service.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Delai en jours avant le depart pour declencher la notification.
const _reminderDaysBeforeDeparture = 2;

/// Service de rappel de telechargement J-2.
///
/// Verifie si les donnees d'un sentier sont telechargees et planifie
/// une notification locale 2 jours avant la date de depart si besoin.
class DownloadReminderService {
  DownloadReminderService({
    required this.notificationService,
    required this.manifestsDao,
  });

  final NotificationService notificationService;
  final TrailManifestsDao manifestsDao;

  /// Verifie si une notification J-2 doit etre planifiee.
  ///
  /// Conditions pour planifier :
  /// - [departureDate] est dans le futur et a J-2 ou moins
  /// - Les donnees du sentier [trailId] ne sont pas telechargees
  ///   (pas de localVersion ou needsUpdate = true)
  ///
  /// Si les donnees sont deja telechargees, aucune notification n'est envoyee.
  Future<void> checkAndNotify(String trailId, DateTime departureDate) async {
    final now = DateTime.now();
    final reminderDate = departureDate.subtract(
      const Duration(days: _reminderDaysBeforeDeparture),
    );

    // Pas encore J-2 ou depart deja passe
    if (now.isBefore(reminderDate) || departureDate.isBefore(now)) {
      _log.d(
        '[DownloadReminderService] Pas de rappel pour $trailId : '
        'hors fenetre J-2',
      );
      return;
    }

    // Verifier si les donnees sont deja telechargees
    final needsDownload = await manifestsDao.needsUpdate(trailId);
    if (!needsDownload) {
      _log.d(
        '[DownloadReminderService] $trailId deja telecharge, pas de rappel',
      );
      return;
    }

    // Planifier la notification
    _log.d('[DownloadReminderService] Notification J-2 pour $trailId');
    await notificationService.scheduleCountdown(
      departureDate: departureDate,
      title: trailId,
      body: trailId,
    );
  }

  /// Annule le rappel pour un sentier.
  Future<void> cancelReminder(String trailId) async {
    _log.d('[DownloadReminderService] Rappel annule pour $trailId');
    // Identifiant derive du hash du trailId pour annuler la bonne notif
    final notifId = trailId.hashCode.abs() % 100000;
    await notificationService.cancel(notifId);
  }
}

/// Provider du service de rappel de telechargement.
final downloadReminderServiceProvider =
    Provider<DownloadReminderService>((ref) {
  final notificationService = NotificationService();
  final db = ref.watch(databaseProvider);
  final manifestsDao = TrailManifestsDao(db);

  return DownloadReminderService(
    notificationService: notificationService,
    manifestsDao: manifestsDao,
  );
});
