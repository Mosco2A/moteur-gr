/// La fiche medicale a son PROPRE fichier, hors sauvegarde du telephone : c'est
/// ce provider que les tests surchargent, plus la base.
library;

// E5.16 / E57 -- Ecran formulaire de la FICHE D'URGENCE, LOCAL ONLY.
//
// ===========================================================================
// TACHE 630 — CE QUE CET ECRAN EST DEVENU, ET POURQUOI
// ===========================================================================
//
// Il portait CINQ champs : groupe sanguin, allergies, traitements, medecin,
// assurance. Christophe l'a ouvert sur son telephone le 29/09 et a dit, verbatim :
// « Je ne vois toujours pas les infos complete dans info sante, dans la version
// en cours? » puis « Mais on avait dit nom, prenom, info de contact, tu avais
// fait la liste !!! ». Il avait raison : la liste existait en base depuis le
// 26/09 (#100661) et n'avait jamais ete codee.
//
// L'ECRAN SUIT DESORMAIS L'ORDRE OU UN SECOURISTE LIT, et cet ordre est celui du
// modele — il n'y en a pas deux dans l'application. La source de chaque champ et
// la source de l'ordre sont ecrites dans `health_info.dart` ; elles ne sont pas
// recopiees ici pour qu'il n'y ait qu'un seul endroit a corriger.
//
//   [1] QUI          nom et prenom, date de naissance, adresse
//   [2] QUI PREVENIR les contacts a prevenir, DANS la fiche (ils etaient
//                    ailleurs, sans ecran de saisie et sans disque)
//   [3] VITAL        allergies, traitements, antecedents, groupe sanguin,
//                    don d'organes
//   [4] ADMINISTRATIF medecin, assurance, et les PHOTOS des deux cartes
//
// LE MESSAGE NE CHANGE PAS D'UN MOT : ces donnees restent sur le telephone
// (art. 9 RGPD, LOCAL ONLY a vie -- jamais de Firestore, jamais de cloud). Le nom
// et l'adresse sont des donnees personnelles de plus, pas une donnee d'une autre
// nature : meme fichier, meme dossier exclu, meme effacement.
//
// LOT D / D1 (refonte UX StepWays) : textes portes en Slang (namespace `health`,
// 5 langues) et couleurs alignees sur le theme -- plus aucun texte ni couleur en
// dur (spec E57 AM-1 / RM-6). Donnee personnelle independante du sentier (AM-6 :
// pas de trailId, pas de trailConfigProvider).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/consent_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../consent/consent_facade.dart' show consentControllerProvider;
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../data/fiche_medicale_fichier.dart';
import '../data/health_info_repository.dart';
import '../data/prise_photo_carte.dart';
import '../domain/health_bounds.dart';
import '../domain/models/emergency_contact.dart';
import '../domain/models/health_info.dart';
import '../providers/health_prepare_providers.dart';
import '../providers/refus_sauvegarde_systeme_provider.dart';
import '../../../core/branding/stepways_icons.dart';

part 'health_info_screen_etat.dart';
part 'health_info_screen_formulaire.dart';
part 'health_info_screen_champs.dart';
part 'health_info_screen_conseils.dart';
part 'health_info_screen_saisie.dart';
part 'health_info_screen_sections_haut.dart';
part 'health_info_screen_sections_bas.dart';

/// Provider du stockage durable de la fiche medicale.
///
/// TACHE 613 : il a remplace `healthInfoDaoProvider`, qui derivait de la base
/// Drift commune. La fiche a desormais SON PROPRE FICHIER, sous le dossier
/// declare exclu de la sauvegarde du telephone — la raison entiere est dans
/// [FicheMedicaleFichier]. Les tests surchargent CE provider (repertoire
/// temporaire) ; surcharger `databaseProvider` n'a plus d'effet sur la fiche,
/// et c'est voulu : plus rien de medical ne passe par la base.
final ficheMedicaleFichierProvider = Provider<FicheMedicaleFichier>(
  (ref) => FicheMedicaleFichier(),
);

/// Provider du repository sante (LOCAL ONLY).
final healthInfoRepositoryProvider = Provider<HealthInfoRepository>(
  (ref) =>
      HealthInfoRepository(fichier: ref.watch(ficheMedicaleFichierProvider)),
);

/// Provider des donnees sante actuelles.
final healthInfoProvider = FutureProvider<HealthInfo>((ref) {
  final repo = ref.watch(healthInfoRepositoryProvider);
  return repo.get();
});

/// LA PRISE DE PHOTO D'UNE CARTE — INJECTABLE (tache 630).
///
/// Un test de widgets n'a pas d'appareil photo, et un canal de plateforme sans
/// interlocuteur ne rend JAMAIS la main (mesure du 28/09, tache 612). Passer par
/// un provider permet de le remplacer par une fonction qui rend des octets, ou
/// un refus, sans toucher au reste de l'ecran.
final priseDePhotoCarteProvider = Provider<PriseDePhotoCarte>(
  (ref) => prendrePhotoDeCarte,
);

/// E5.16 / E57 / 630 : ecran de la fiche d'urgence.
///
/// Les donnees sont stockees localement — dans un FICHIER DEDIE sous le dossier
/// declare exclu de la sauvegarde du telephone (tache 613, voir
/// [FicheMedicaleFichier]) — et ne quittent JAMAIS le telephone (pas de
/// Firestore, pas de cloud, pas de sauvegarde Google ou Apple).
class HealthInfoScreen extends ConsumerStatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  ConsumerState<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

/// UNE LIGNE DE CONTACT EN COURS D'EDITION.
///
/// Les controleurs vivent ici et pas dans une liste parallele : une liste de
/// controleurs indexee a cote d'une liste de contacts se desynchronise des le
/// premier retrait au milieu, et le randonneur voit le telephone d'un proche
/// passer sous le nom d'un autre. Sur une fiche d'urgence, ce n'est pas un
/// defaut cosmetique.
class _LigneContact {
  _LigneContact({String nom = '', String telephone = ''})
    : nomCtrl = TextEditingController(text: nom),
      telCtrl = TextEditingController(text: telephone);

  final TextEditingController nomCtrl;
  final TextEditingController telCtrl;

  bool get estVide =>
      nomCtrl.text.trim().isEmpty && telCtrl.text.trim().isEmpty;

  void dispose() {
    nomCtrl.dispose();
    telCtrl.dispose();
  }
}
