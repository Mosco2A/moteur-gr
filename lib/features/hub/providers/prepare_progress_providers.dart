/// La coche de chaque carte de « Preparer », CALCULEE depuis ce qui est deja
/// persiste : aucune saisie de plus, aucune colonne de plus.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/checklist_dao.dart';
import '../../../core/data/daos/nuitee_selections_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/map/mbtiles_manager.dart';
import '../../../core/providers/database_provider.dart';
import '../../../shared/widgets/step_status_icon.dart';
import '../../booking/booking_facade.dart' show buildNuiteeSlots;
import '../../checklist/checklist_facade.dart' show defaultChecklistTemplate;
import '../../feasibility/feasibility_facade.dart' show hikerProfileProvider;
import '../../notifications/notifications_facade.dart'
    show downloadReminderProvider;
import '../../planning/planning_facade.dart'
    show plannedDaysProvider, retainedDurationProvider;
import '../../safety/safety_facade.dart'
    show healthPrepareDoneProvider, healthPrepareStepsProvider;
import '../../training/training_facade.dart'
    show trainingPlanProvider, trainingProgressProvider;
import 'cockpit_start_providers.dart';

/// LA QUESTION DE CHRISTOPHE, LE 07/10 A 08:37, VERBATIM : « avant sur
/// fralimonti on avait une indication quand un element etait complet c est
/// toujours le cas ? ». La reponse mesuree etait NON : la coche
/// ([StepStatusIcon]) etait ecrite, et la carte ([QuickAccessCard.stepStatus])
/// savait la poser, mais personne ne lui passait de statut. Ce fichier est le
/// calculateur qui manquait — et SEULEMENT lui.
///
/// CE N'EST PAS UN SECOND MOTEUR. C'est l'elargissement de celui qui tourne
/// deja pour la porte « Demarrer » : [PrepareCoreStepsNotifier] et
/// [prepareCoreDoneProvider] derivent « Preparer termine » de signaux DEJA
/// persistes, sans table neuve. On fait exactement la meme chose, carte par
/// carte, avec les memes sources — et un test verrouille que les quatre coches
/// de la porte (Itineraire, Programme, Calendrier, Fiche medicale) sont
/// completes EXACTEMENT quand la porte est ouverte. Deux lectures du meme fait
/// ne peuvent donc pas diverger.
///
/// LA REGLE : MIEUX VAUT PAS DE COCHE QU'UNE COCHE QUI MENT. `null` = pas de
/// coche. C'est la reponse pour les trois sujets dont rien n'est persiste
/// (Transport, Ravitaillement, Resume), et pour un sujet dont la source est
/// encore en chargement ou en erreur : on ne dit pas « a faire » de ce qu'on
/// n'a pas encore lu.
enum SujetDePreparation {
  /// Fiche profil (age, taille, poids) : le verdict n'existe que sur une fiche
  /// complete. Vide -> a faire ; partielle -> entamee ; complete -> faite.
  faisabilite,

  /// Ecran Itineraire ouvert ([PrepCoreStep.itinerary]). DEUX etats.
  itineraire,

  /// Ecran Programme ouvert ([PrepCoreStep.programme]) -> fait ; une duree
  /// RETENUE sans l'avoir ouvert -> entame.
  programme,

  /// Date de depart posee. DEUX etats.
  calendrier,

  /// Seances cochees parmi celles du plan du sentier.
  preparationPhysique,

  /// Fiche remplie ET conseils lus -> faite ; un seul des signaux -> entamee.
  ficheMedicale,

  /// Fichier de carte : complet et verifie -> fait ; partiel -> entame.
  cartesHorsLigne,

  /// Nuits reservees parmi celles du programme, veille du depart comprise.
  nuitees,

  /// Articles coches parmi ceux du sac, comptes comme l'ecran Sac les compte.
  materiel,

  /// RIEN DE PERSISTE : l'ecran est un catalogue en lecture. Pas de coche.
  transport,

  /// RIEN DE PERSISTE : l'ecran est un catalogue en lecture. Pas de coche.
  ravitaillement,

  /// RIEN DE PERSISTE : l'ecran est une synthese des autres. Pas de coche.
  resume,
}

/// Trois etats depuis deux faits : « fait » l'emporte, puis « entame ».
///
/// Un sujet a deux etats seulement passe `entame: false` : il saute alors
/// directement de « a faire » a « fait », sans jamais mentir sur un entre-deux
/// qu'on ne sait pas mesurer.
PlanningStepStatus statutATroisEtats({
  required bool fait,
  required bool entame,
}) {
  if (fait) return PlanningStepStatus.completed;
  if (entame) return PlanningStepStatus.inProgress;
  return PlanningStepStatus.notStarted;
}

/// Trois etats depuis un compte : rien -> a faire, tout -> fait, sinon entame.
///
/// Un total nul n'est JAMAIS « fait » : zero sur zero ne prouve rien.
PlanningStepStatus statutParCompte({required int faits, required int total}) =>
    statutATroisEtats(fait: total > 0 && faits >= total, entame: faits > 0);

/// Le sac, COMPTE COMME L'ECRAN SAC LE COMPTE (`ChecklistNotifier`) : les
/// articles du modele, plus les articles PERSONNELS hors modele. Une ligne
/// orpheline d'un ancien modele ne compte pas — l'ecran ne la montre pas.
///
/// Sac jamais ouvert (aucune ligne en base) -> a faire.
PlanningStepStatus statutMateriel({
  required List<ChecklistItem> lignes,
  required Set<String> idsDuModele,
}) {
  final cochesDuModele = <String>{};
  var personnels = 0;
  var personnelsCoches = 0;
  for (final ligne in lignes) {
    if (idsDuModele.contains(ligne.itemId)) {
      if (ligne.isChecked) cochesDuModele.add(ligne.itemId);
    } else if (ligne.isCustom) {
      personnels++;
      if (ligne.isChecked) personnelsCoches++;
    }
  }
  return statutParCompte(
    faits: cochesDuModele.length + personnelsCoches,
    total: idsDuModele.length + personnels,
  );
}

/// LE COCKPIT RELIT CE QUI EST SUR LE TELEPHONE AU RETOUR DE L'ECRAN QUI LE
/// CHANGE. Les trois sources ci-dessous ne previennent personne quand elles
/// changent : la section Preparer les invalide au RETOUR de l'ecran Sac, de
/// l'ecran Nuitees et de l'ecran Cartes, seuls endroits ou le randonneur les
/// modifie.
///
/// POURQUOI PAS UN FLUX DRIFT (`.watch()`), MESURE LE 07/10. C'etait la
/// premiere version : la coche suivait la base en direct. Mais un flux Drift
/// ferme sa requete par un minuteur au desabonnement, et ce minuteur restait en
/// suspens au demontage du cockpit — dix tests du cockpit rougissaient sur
/// « A Timer is still pending ». Une lecture ponctuelle relue au retour donne
/// la meme coche a l'ecran, sans rien laisser derriere elle.

/// Les lignes du sac d'un sentier.
///
/// LECTURE SEULE, ET C'EST DELIBERE. On ne passe PAS par `checklistProvider` :
/// sa premiere lecture AMORCE le sac (84 lignes ecrites en base). Afficher le
/// cockpit ecrirait donc dans la base — une ecriture declenchee par un regard.
final lignesDuSacProvider = FutureProvider.family<List<ChecklistItem>, String>(
  (ref, trailId) =>
      ChecklistDao(ref.watch(databaseProvider)).getByTrailId(trailId),
);

/// Les nuits reservees d'un sentier (numero du jour -> reservee).
///
/// Meme raison que pour le sac : on lit la table, on ne cree pas le notifier
/// de l'ecran Nuitees, dont le chargement n'a pas de filet et suit le sentier
/// ACTIF au lieu du sentier demande.
final nuitsReserveesProvider = FutureProvider.family<Map<int, bool>, String>((
  ref,
  trailId,
) async {
  final lignes = await NuiteeSelectionsDao(
    ref.watch(databaseProvider),
  ).getByTrailId(trailId);
  return {for (final l in lignes) l.dayNumber: l.isBooked};
});

/// La carte hors ligne sur le telephone : le nom definitif `{sentier}.mbtiles`
/// ne designe QU'UNE carte complete et verifiee (`MBTilesManager`) ; un
/// `.partiel` non vide est une descente entamee.
final cartesSurLeTelephoneProvider =
    FutureProvider.family<PlanningStepStatus, String>((ref, trailId) async {
      final cartes = ref.watch(mbtilesManagerProvider);
      final posee = await cartes.hasMbtiles(trailId);
      final entamee = !posee && await cartes.octetsDejaDescendus(trailId) > 0;
      return statutATroisEtats(fait: posee, entame: entamee);
    });

/// LA COCHE D'UNE CARTE DE PREPARER, pour un sentier. `null` = pas de coche.
///
/// Famille par `(sentier, sujet)` : chaque coche n'ecoute QUE ses propres
/// sources, une coche posee dans le sac ne recalcule pas la fiche medicale.
final statutDePreparationProvider =
    Provider.family<
      PlanningStepStatus?,
      ({String trailId, SujetDePreparation sujet})
    >((ref, cle) {
      final trailId = cle.trailId;
      switch (cle.sujet) {
        case SujetDePreparation.faisabilite:
          final fiche = ref.watch(hikerProfileProvider).value;
          if (fiche == null) return null;
          return statutATroisEtats(
            fait: fiche.isComplete,
            entame: !fiche.isEmpty,
          );

        case SujetDePreparation.itineraire:
          return statutATroisEtats(
            fait: ref
                .watch(prepareCoreStepsProvider(trailId))
                .contains(PrepCoreStep.itinerary),
            entame: false,
          );

        case SujetDePreparation.programme:
          return statutATroisEtats(
            fait: ref
                .watch(prepareCoreStepsProvider(trailId))
                .contains(PrepCoreStep.programme),
            entame: ref.watch(retainedDurationProvider) != null,
          );

        case SujetDePreparation.calendrier:
          return statutATroisEtats(
            fait: ref.watch(
              downloadReminderProvider(
                trailId,
              ).select((s) => s.departureDate != null),
            ),
            entame: false,
          );

        case SujetDePreparation.preparationPhysique:
          final faites = ref
              .watch(trainingProgressProvider(trailId))
              .doneSessionIds;
          final plan = ref.watch(trainingPlanProvider).value;
          // Plan pas encore lu : on ne peut pas dire « fait » sans savoir sur
          // combien de seances, mais une seance cochee prouve « entame ».
          if (plan == null) {
            return statutATroisEtats(fait: false, entame: faites.isNotEmpty);
          }
          final duPlan = {
            for (final phase in plan.phases)
              for (final seance in phase.sessions) seance.id,
          };
          return statutParCompte(
            faits: faites.where(duPlan.contains).length,
            total: duPlan.length,
          );

        case SujetDePreparation.ficheMedicale:
          return statutATroisEtats(
            fait: ref.watch(healthPrepareDoneProvider),
            entame: ref.watch(healthPrepareStepsProvider).isNotEmpty,
          );

        case SujetDePreparation.cartesHorsLigne:
          return ref.watch(cartesSurLeTelephoneProvider(trailId)).value;

        case SujetDePreparation.nuitees:
          final nuits = buildNuiteeSlots(
            ref.watch(plannedDaysProvider(trailId)),
          ).map((n) => n.day.dayNumber).toList();
          final reservees = ref.watch(nuitsReserveesProvider(trailId)).value;
          // Pas de programme (etapes en chargement) : aucune nuit a compter.
          if (nuits.isEmpty || reservees == null) return null;
          return statutParCompte(
            faits: nuits.where((n) => reservees[n] ?? false).length,
            total: nuits.length,
          );

        case SujetDePreparation.materiel:
          final lignes = ref.watch(lignesDuSacProvider(trailId)).value;
          if (lignes == null) return null;
          return statutMateriel(
            lignes: lignes,
            idsDuModele: {for (final a in defaultChecklistTemplate) a.id},
          );

        case SujetDePreparation.transport:
        case SujetDePreparation.ravitaillement:
        case SujetDePreparation.resume:
          return null;
      }
    });
