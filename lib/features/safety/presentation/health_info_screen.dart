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
import '../../consent/providers/consent_ui_providers.dart';
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

class _HealthInfoScreenState extends ConsumerState<HealthInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // [1] QUI
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  String _birthDate = '';

  // [2] QUI PREVENIR
  final List<_LigneContact> _contacts = [];

  // [3] VITAL
  final _allergiesController = TextEditingController();
  final _treatmentsController = TextEditingController();
  final _conditionsController = TextEditingController();
  String? _bloodType;
  String? _organDonor;

  /// LA VALEUR DE GROUPE SANGUIN LUE SUR LE DISQUE ET NON RECONNUE.
  ///
  /// Elle n'est PAS effacee : elle est montree au randonneur pour qu'il
  /// choisisse (consigne 630 : « les fiches deja saisies ne perdent RIEN »).
  String _bloodTypeHerite = '';

  // [4] ADMINISTRATIF
  final _doctorController = TextEditingController();
  final _insuranceController = TextEditingController();
  String _carteVitale = '';
  String _carteMutuelle = '';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  /// Vrai si la fiche contient au moins une donnee (pilote l'affichage du
  /// bouton « Effacer ma fiche » : rien a effacer sur une fiche vide).
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  /// Charge les donnees existantes dans les champs.
  Future<void> _loadExistingData() async {
    final repo = ref.read(healthInfoRepositoryProvider);
    final info = await repo.get();

    if (!mounted) return;
    setState(() {
      _fullNameController.text = info.fullName;
      _addressController.text = info.address;
      _birthDate = info.birthDate;
      _contacts
        ..forEach((l) => l.dispose())
        ..clear()
        ..addAll(
          info.emergencyContacts.map(
            (c) => _LigneContact(nom: c.name, telephone: c.phone),
          ),
        );
      _allergiesController.text = info.allergies;
      _treatmentsController.text = info.treatments;
      _conditionsController.text = info.conditions;
      _bloodType = valeurListeGroupeSanguin(info.bloodType);
      _bloodTypeHerite = estGroupeSanguinHerite(info.bloodType)
          ? info.bloodType
          : '';
      _organDonor = valeurListeDonOrganes(info.organDonor);
      _doctorController.text = info.doctorContact;
      _insuranceController.text = info.insuranceNumber;
      _carteVitale = info.carteVitaleFichier;
      _carteMutuelle = info.carteMutuelleFichier;
      _hasContent = info.hasData;
      _isLoading = false;
    });
    // RE-SYNCHRONISATION DU SIGNAL DE PREPARATION (tache 568, LOT Q).
    //
    // La porte de demarrage du trek lit un signal en preferences
    // ([HealthPrepStep.filled]) et non le fichier de la fiche (cf.
    // `health_prepare_providers.dart` : la porte est une vue SYNCHRONE). Ce
    // signal pourrait donc, en theorie, diverger de la donnee reelle — par
    // exemple une fiche remplie AVANT que ce signal existe, ou effacee par un
    // chemin qui ne passe pas par cet ecran. On l'aligne ICI, a chaque
    // ouverture, sur ce que le disque dit vraiment : le signal ne peut pas
    // mentir durablement.
    await ref.read(healthPrepareStepsProvider.notifier).setFilled(info.hasData);
  }

  /// Assemble la fiche a partir des champs de l'ecran.
  ///
  /// LES CONTACTS VIDES SONT JETES ICI, PAS AILLEURS : une ligne ouverte puis
  /// laissee blanche ne doit pas devenir un contact sans nom ni numero sur
  /// l'ecran verrouille d'un blesse.
  HealthInfo _composerFiche() {
    final contacts = <EmergencyContact>[];
    for (var i = 0; i < _contacts.length; i++) {
      final ligne = _contacts[i];
      final nom = ligne.nomCtrl.text.trim();
      final tel = ligne.telCtrl.text.trim();
      if (nom.isEmpty && tel.isEmpty) continue;
      contacts.add(
        EmergencyContact(
          // L'IDENTIFIANT EST LE RANG, ET C'EST SUFFISANT : ces contacts ne sont
          // references par rien d'autre que la fiche qui les porte.
          id: 'perso-$i',
          name: nom,
          phone: tel,
          // La priorite suit l'ordre de saisie : le premier nomme est le premier
          // appele. C'est ce que le randonneur croit en les rangeant.
          priority: i + 1,
        ),
      );
    }
    return HealthInfo(
      fullName: _fullNameController.text.trim(),
      birthDate: _birthDate,
      address: _addressController.text.trim(),
      emergencyContacts: contacts,
      allergies: _allergiesController.text.trim(),
      treatments: _treatmentsController.text.trim(),
      conditions: _conditionsController.text.trim(),
      // PLUS DE NORMALISATION A FAIRE : la valeur vient d'une liste fermee, elle
      // est deja canonique. C'est tout l'interet de fermer la liste.
      bloodType: _bloodType ?? '',
      organDonor: _organDonor ?? '',
      doctorContact: _doctorController.text.trim(),
      insuranceNumber: _insuranceController.text.trim(),
      carteVitaleFichier: _carteVitale,
      carteMutuelleFichier: _carteMutuelle,
    );
  }

  /// Sauvegarde les donnees du formulaire en local.
  ///
  /// FIX-1 (finding M6) : `validate()` est ENFIN appele. Le `Form` n'est plus
  /// decoratif — et depuis la tache 630 le groupe sanguin ne peut PLUS etre
  /// invalide, puisqu'il ne se saisit plus. Ce qui reste a valider, ce sont les
  /// contacts : un nom sans numero ne sert a rien a un secouriste.
  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final info = _composerFiche();
    final repo = ref.read(healthInfoRepositoryProvider);
    await repo.save(info);

    // Rafraichir le provider
    ref.invalidate(healthInfoProvider);

    // La fiche vient de changer : le signal de preparation suit (tache 568). Une
    // fiche enregistree VIDE ne compte pas comme remplie — `hasData` tranche.
    await ref.read(healthPrepareStepsProvider.notifier).setFilled(info.hasData);

    // LA COPIE SAUVEGARDABLE SUIT LA FICHE (tache 612). Elle n'existe que si le
    // randonneur a DECOCHE le refus de sauvegarde systeme ; dans ce cas elle doit
    // porter la fiche TELLE QU'ELLE EST MAINTENANT. Sans ce re-alignement, une
    // copie fabriquee hier partirait chez Google avec un traitement que le
    // randonneur vient d'arreter — une donnee de sante perimee est pire qu'une
    // donnee absente le jour ou un secouriste s'y fie.
    //
    // ON NE L'ATTEND PAS, ET C'EST MESURE. Attendre place un appel de plugin
    // (resolution du dossier de stockage) DANS le chemin qui confirme
    // l'enregistrement. Mesure du 28/09 : trois tests d'ecran sont devenus rouges
    // sur « pumpAndSettle timed out », parce qu'un canal de plateforme sans
    // interlocuteur ne rend JAMAIS la main. Sur un telephone il repond en une
    // fraction de milliseconde, mais le principe reste : la confirmation d'un
    // enregistrement reussi ne doit dependre de RIEN d'autre que de
    // l'enregistrement. Le trou eventuel (fermeture immediate) est bouche par le
    // re-alignement d'ouverture ([RefusSauvegardeSystemeNotifier]), qui fait
    // converger le disque a chaque lancement.
    unawaited(
      ref.read(refusSauvegardeSystemeProvider.notifier).realignerLesCopies(),
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasContent = info.hasData;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.health.saved),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      // LA FICHE VIENT DE CHANGER : ON REDEMANDE LE CONSENTEMENT (DEM 30/09
      // 12:33). Decision de Christophe, verbatim : « en cas de modification des
      // donnees, on redemande le consentement ».
      //
      // APRES LA CONFIRMATION D'ENREGISTREMENT, ET AVANT LE DEPILEMENT, et les
      // deux bornes sont mesurees.
      //
      // APRES, parce que placee AVANT, la question laissait le bouton
      // « Enregistrer » tourner pendant qu'elle attendait une reponse :
      // `_isSaving` n'etait rabaisse qu'apres, donc le spinner tournait sous le
      // dialogue. Ce n'est pas qu'inelegant — c'est le defaut deja paye par la
      // tache 612 sur cet ecran meme, et deux tests l'ont attrape ici encore
      // (`pumpAndSettle timed out` : un indicateur qui tourne pour toujours ne
      // laisse jamais l'arbre se stabiliser). LA CONFIRMATION D'UN
      // ENREGISTREMENT REUSSI NE DOIT DEPENDRE DE RIEN D'AUTRE QUE DE
      // L'ENREGISTREMENT : la fiche est ecrite, on le dit, PUIS on pose la
      // question.
      //
      // AVANT LE DEPILEMENT, parce qu'une question posee apres le `pop()`
      // s'ouvrirait sur l'ecran precedent, detachee de ce qui l'a provoquee.
      await _redemanderLeConsentementApresModification();
      if (!mounted) return;

      // ON NE DEPILE QUE S'IL Y A QUELQUE CHOSE SOUS LA PAGE (tache 579, LOT X).
      // Ce `pop()` etait inconditionnel. Quand la fiche est ouverte DIRECTEMENT
      // — lien profond, notification, retour du systeme sur cette route — elle
      // est la seule page de la pile : le `pop()` la retirait et laissait
      // l'application sans aucune page ('You have popped the last page off of
      // the stack'). En release, ou l'assertion ne se declenche pas, l'ecran
      // restait fige : enregistrer ne produisait rien de visible au-dela du
      // message. On reste sur la fiche quand il n'y a nulle part ou revenir —
      // le message, lui, confirme l'enregistrement dans les deux cas.
      final navigateur = Navigator.of(context);
      if (navigateur.canPop()) navigateur.pop();
    }
  }

  /// LA FICHE A CHANGE, DONC ON REPOSE LA QUESTION (DEM du 30/09 12:33).
  ///
  /// DECISION DE CHRISTOPHE, verbatim : « en cas de modification des donnees, on
  /// redemande le consentement ». Un consentement donne il y a six mois porte sur
  /// ce qu'il y avait dans la fiche il y a six mois ; le randonneur qui ajoute
  /// aujourd'hui un traitement ou une allergie n'a jamais consenti POUR CELA.
  ///
  /// UNE FOIS PAR MODIFICATION, JAMAIS AU SIMPLE AFFICHAGE, et c'est structurel
  /// et non une precaution : la question ne se pose que depuis cette methode,
  /// appelee par [_save], donc uniquement quand une ECRITURE a eu lieu. Ouvrir la
  /// fiche, la relire, en sortir : rien n'est ecrit, rien n'est demande. Et la
  /// decision prise ici CAPTURE la nouvelle revision des donnees, donc
  /// `needsPrompt` retombe a faux tout de suite — sans quoi l'application
  /// reposerait la question a chaque enregistrement suivant.
  ///
  /// ON PASSE PAR LE CONTROLEUR, PAS PAR LE SERVICE, et c'est deliberé : c'est
  /// lui qui sait CE QUE LE RETRAIT DE CETTE FINALITE EMPORTE de l'appareil
  /// (tache 560). Appeler `ConsentService.revoke` en direct d'ici donnerait une
  /// seconde definition de « ce que ce consentement protege », et c'est
  /// exactement l'ecart que la tache 564 a paye.
  ///
  /// ELLE NE LEVE JAMAIS. Un stockage de consentement illisible ne doit pas faire
  /// echouer l'enregistrement d'une fiche medicale — la fiche est deja ecrite a ce
  /// stade, et c'est elle qui compte pour un secouriste.
  Future<void> _redemanderLeConsentementApresModification() async {
    final service = ref.read(consentServiceProvider);
    try {
      await service.initialize();
      await service.noterUneModificationDesDonnees(ConsentPurpose.healthData);
      if (!service.needsPrompt(ConsentPurpose.healthData)) return;
    } on Object catch (e) {
      debugPrint(
        '[FicheSante] consentement illisible ($e) — pas de re-demande',
      );
      return;
    }

    if (!mounted) return;
    // PAS DE FERMETURE PAR L'EXTERIEUR : une question de consentement se repond,
    // et les deux reponses sont aussi accessibles l'une que l'autre (RGPD art.
    // 7-3 : le retrait doit etre aussi simple que l'octroi).
    final accorde = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(t.consent.purposes.healthData),
        content: Text(t.health.consent.purpose),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            label: t.consent.revoke,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            variant: AppButtonVariant.filledTone,
            isFullWidth: false,
            label: t.consent.grant,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (accorde == null) return;

    final controleur = ref.read(consentControllerProvider);
    if (accorde) {
      await controleur.grant(
        ConsentPurpose.healthData,
        declencheur: DeclencheurDeConsentement.modificationDesDonnees,
      );
    } else {
      await controleur.revoke(
        ConsentPurpose.healthData,
        declencheur: DeclencheurDeConsentement.modificationDesDonnees,
      );
    }
  }

  /// Efface la fiche sante (E57) apres confirmation — branche le `delete()`
  /// DEJA present dans le repository (aucun recodage). Local + instantane +
  /// hors-ligne : aucune donnee ne quitte le telephone. Apres effacement, le
  /// widget ecran verrouille cesse tout seul d'afficher la partie sante (le
  /// repository est la source unique).
  ///
  /// TACHE 630 : `delete()` emporte AUSSI les deux photos de carte. Un
  /// effacement qui laisserait une photo de carte Vitale sur le disque serait un
  /// effacement qui ment.
  Future<void> _confirmAndDelete() async {
    if (_isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.health.delete.confirmTitle),
        content: Text(t.health.delete.confirmBody),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            label: t.health.delete.cancel,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          // Action DEFINITIVE : bouton rouge (couleur semantique d'urgence).
          AppButton(
            variant: AppButtonVariant.filledTone,
            tone: AppTheme.rougeUrgence,
            isFullWidth: false,
            label: t.health.delete.confirm,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final repo = ref.read(healthInfoRepositoryProvider);
    await repo.delete();
    ref.invalidate(healthInfoProvider);

    // Une fiche effacee n'est plus une fiche remplie : la porte de demarrage se
    // REFERME (tache 568). Le signal suit la donnee, il ne lui survit pas — c'est
    // la meme exigence que les LOTS J a O sur le droit a l'effacement.
    await ref.read(healthPrepareStepsProvider.notifier).setFilled(false);

    // ET LA COPIE SAUVEGARDABLE S'EN VA AVEC ELLE (tache 612). C'est le point le
    // plus facile a oublier : effacer la fiche en laissant sa copie dans
    // l'emplacement sauvegarde, c'est un effacement qui ne tient pas. Le
    // changement de telephone la ferait revenir.
    //
    // MEME REGLE QUE L'ENREGISTREMENT : lance, pas attendu. La suppression du
    // fichier est SYNCHRONE une fois le dossier connu, donc elle ne peut pas
    // rester a moitie faite ; et si l'application meurt avant que le dossier soit
    // resolu, le re-alignement d'ouverture la reprend au lancement suivant.
    unawaited(
      ref.read(refusSauvegardeSystemeProvider.notifier).realignerLesCopies(),
    );

    if (!mounted) return;
    setState(() {
      _fullNameController.clear();
      _addressController.clear();
      _birthDate = '';
      for (final ligne in _contacts) {
        ligne.dispose();
      }
      _contacts.clear();
      _allergiesController.clear();
      _treatmentsController.clear();
      _conditionsController.clear();
      _bloodType = null;
      _bloodTypeHerite = '';
      _organDonor = null;
      _doctorController.clear();
      _insuranceController.clear();
      _carteVitale = '';
      _carteMutuelle = '';
      _hasContent = false;
      _isDeleting = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.health.delete.done)));
  }

  /// Ouvre le selecteur de date de naissance.
  ///
  /// LES BORNES NE SONT PAS COSMETIQUES : une date de naissance dans le futur ou
  /// vieille de deux siecles sur une fiche d'urgence fait douter de TOUTE la
  /// fiche. Le selecteur les rend impossibles, plutot que de les refuser apres
  /// coup.
  Future<void> _choisirDateNaissance() async {
    final maintenant = DateTime.now();
    final actuelle = DateTime.tryParse(_birthDate);
    final choisie = await showDatePicker(
      context: context,
      initialDate: actuelle ?? DateTime(maintenant.year - 30),
      firstDate: DateTime(maintenant.year - 120),
      lastDate: maintenant,
      helpText: t.health.field.birthDate,
    );
    if (choisie == null || !mounted) return;
    setState(() {
      // FORME ISO `AAAA-MM-JJ` : stockage neutre, affichage localise. Voir
      // `health_info.dart`.
      _birthDate =
          '${choisie.year.toString().padLeft(4, '0')}-'
          '${choisie.month.toString().padLeft(2, '0')}-'
          '${choisie.day.toString().padLeft(2, '0')}';
    });
  }

  /// Prend (ou remplace) la photo d'une carte.
  ///
  /// LE REFUS D'AUTORISATION N'EST PAS UNE PANNE, ET L'ECRAN NE LE TRAITE PAS
  /// COMME TELLE : on le dit une fois, sans dialogue, sans renvoi vers les
  /// reglages, et l'ecran continue de fonctionner exactement pareil. C'est la
  /// condition posee avec la demande.
  Future<void> _photographierCarte(
    String nomFichier,
    ImageSource source,
  ) async {
    final prise = ref.read(priseDePhotoCarteProvider);
    final resultat = await prise(source);
    if (!mounted) return;

    switch (resultat.issue) {
      case IssuePhotoCarte.annule:
        return;
      case IssuePhotoCarte.refus:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.health.cards.permissionRefused)),
        );
        return;
      case IssuePhotoCarte.echec:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.health.cards.failed)));
        return;
      case IssuePhotoCarte.reussite:
        break;
    }

    final fichier = ref.read(ficheMedicaleFichierProvider);
    await fichier.enregistrerCarte(nomFichier, resultat.octets!);
    if (!mounted) return;
    setState(() {
      if (nomFichier == FicheMedicaleFichier.nomCarteVitale) {
        _carteVitale = nomFichier;
      } else {
        _carteMutuelle = nomFichier;
      }
      _hasContent = true;
    });
  }

  /// Retire la photo d'une carte — du disque ET de la fiche.
  Future<void> _retirerCarte(String nomFichier) async {
    final fichier = ref.read(ficheMedicaleFichierProvider);
    await fichier.effacerCarte(nomFichier);
    if (!mounted) return;
    setState(() {
      if (nomFichier == FicheMedicaleFichier.nomCarteVitale) {
        _carteVitale = '';
      } else {
        _carteMutuelle = '';
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    for (final ligne in _contacts) {
      ligne.dispose();
    }
    _allergiesController.dispose();
    _treatmentsController.dispose();
    _conditionsController.dispose();
    _doctorController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      // Ph5 (L6d) : AppHeader universel (back centralise). Leading custom retire.
      appBar: AppHeader(title: t.health.title),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Form(
                key: _formKey,
                child: Semantics(
                  container: true,
                  label: t.health.a11y.form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bandeau securite (message de confiance, RF-2).
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: colors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusCard,
                          ),
                          border: Border.all(
                            color: colors.primary.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            StepIcon(
                              StepwaysIcons.cadenas,
                              color: colors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Text(
                                t.health.privacyBanner,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      // LE PRIX DE LA PROMESSE, DIT ICI ET MAINTENANT (tache
                      // 612). Le bandeau du dessus promet que la fiche ne quitte
                      // pas le telephone ; celui-ci dit ce que cette promesse
                      // coute. Christophe l'a assume en majuscules : changer de
                      // telephone, c'est ressaisir son groupe sanguin, ses
                      // allergies, ses traitements. Ce prix doit etre lu AU
                      // MOMENT OU LA FICHE SE REMPLIT, pas decouvert le jour du
                      // changement d'appareil — et il est place AVANT les champs
                      // pour la meme raison que les conseils du LOT Q.
                      const _LocalOnlyPrice(),
                      const SizedBox(height: AppTheme.spacingMd),
                      // E57 (L6/H1) : rappel de FINALITE + lien vers la gestion du
                      // consentement (art. 9 RGPD). Forme SOUPLE (reco ARBITRAGES
                      // H1-a) : aucun envoi n'a lieu (local-only), on rappelle
                      // l'usage « te secourir » et on offre l'acces a l'ecran
                      // Confidentialite (finalite healthData) — pas de mur avant
                      // saisie. Textes Slang.
                      _ConsentReminder(
                        onManage: () => context.push('/consent'),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      // LA RECOPIE DANS LA FICHE DU TELEPHONE — ETAPE, PLUS
                      // CONSEIL (tache 630). C'est le SEUL chemin qui montre
                      // quelque chose a un secouriste sur iPhone. Elle est donc
                      // au-dessus des champs, pas noyee dans une liste.
                      const _PhoneCardStep(),
                      const SizedBox(height: AppTheme.spacingMd),
                      // CONSEILS D'USAGE TERRAIN + ACCUSE DE LECTURE (tache 568,
                      // LOT Q). Decision de Chris du 26/09, verbatim : « on ne
                      // demarre pas un trek sans avoir rempli sa fiche medicale
                      // ET LU LES CONSEILS pour qu'elle soit applicable sur le
                      // sentier ». Les conseils sont donc AVANT les champs : on
                      // apprend a s'en servir, puis on la remplit — et non
                      // l'inverse, d'autant que l'enregistrement depile l'ecran.
                      const _UsageAdvice(),
                      const SizedBox(height: AppTheme.spacingLg),

                      // ============================================ [1] QUI
                      _SectionTitle(
                        key: const ValueKey('health-section-identity'),
                        icon: StepwaysIcons.monCompte,
                        title: t.health.section.identity,
                        explanation: t.health.section.identityWhy,
                      ),
                      _buildField(
                        key: const ValueKey('health-full-name-field'),
                        controller: _fullNameController,
                        label: t.health.field.fullName,
                        hint: t.health.hint.fullName,
                        icon: StepwaysIcons.monCompte,
                        maxLines: 1,
                        maxLength: kHealthNameMaxLength,
                        showCounter: false,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _ChampDateNaissance(
                        key: const ValueKey('health-birth-date-field'),
                        valeurIso: _birthDate,
                        onChoisir: _choisirDateNaissance,
                        onEffacer: () => setState(() => _birthDate = ''),
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _buildField(
                        key: const ValueKey('health-address-field'),
                        controller: _addressController,
                        label: t.health.field.address,
                        hint: t.health.hint.address,
                        icon: StepwaysIcons.ville,
                        maxLines: 2,
                        maxLength: kHealthAddressMaxLength,
                      ),
                      const SizedBox(height: AppTheme.spacingLg),

                      // =================================== [2] QUI PREVENIR
                      _SectionTitle(
                        key: const ValueKey('health-section-contacts'),
                        icon: StepwaysIcons.telephone,
                        title: t.health.section.contacts,
                        explanation: t.health.section.contactsWhy,
                      ),
                      ..._buildContactRows(),
                      if (_contacts.length < kMaxPersonalEmergencyContacts)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppButton(
                            key: const ValueKey('health-add-contact'),
                            variant: AppButtonVariant.text,
                            icon: StepwaysIcons.plus,
                            iconSize: 18,
                            label: t.health.contacts.add,
                            isFullWidth: false,
                            onPressed: () =>
                                setState(() => _contacts.add(_LigneContact())),
                          ),
                        ),
                      const SizedBox(height: AppTheme.spacingLg),

                      // ========================================== [3] VITAL
                      _SectionTitle(
                        key: const ValueKey('health-section-vital'),
                        icon: StepwaysIcons.secours,
                        title: t.health.section.vital,
                        explanation: t.health.section.vitalWhy,
                      ),
                      // Texte libre medical : longueur BORNEE et VISIBLE
                      // (compteur), plus de champ sans fond (2000 caracteres
                      // illisibles en urgence).
                      _buildField(
                        controller: _allergiesController,
                        label: t.health.field.allergies,
                        hint: t.health.hint.allergies,
                        icon: StepwaysIcons.danger,
                        maxLines: 3,
                        maxLength: kHealthFreeTextMaxLength,
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _buildField(
                        controller: _treatmentsController,
                        label: t.health.field.treatments,
                        hint: t.health.hint.treatments,
                        icon: StepwaysIcons.ficheMedicale,
                        maxLines: 3,
                        maxLength: kHealthFreeTextMaxLength,
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _buildField(
                        key: const ValueKey('health-conditions-field'),
                        controller: _conditionsController,
                        label: t.health.field.conditions,
                        hint: t.health.hint.conditions,
                        icon: StepwaysIcons.historique,
                        maxLines: 3,
                        maxLength: kHealthFreeTextMaxLength,
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      // GROUPE SANGUIN : LISTE FERMEE (tache 630). La saisie
                      // libre a disparu — une valeur inventee n'est plus
                      // seulement refusee, elle est IMPOSSIBLE.
                      _ChampGroupeSanguin(
                        key: const ValueKey('health-blood-type-field'),
                        valeur: _bloodType,
                        valeurHeritee: _bloodTypeHerite,
                        onChanged: (v) => setState(() {
                          _bloodType = v;
                          // Le randonneur a tranche : l'avertissement n'a plus
                          // lieu d'etre, la valeur heritee est remplacee.
                          _bloodTypeHerite = '';
                        }),
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _ChampDonOrganes(
                        key: const ValueKey('health-organ-donor-field'),
                        valeur: _organDonor,
                        onChanged: (v) => setState(() => _organDonor = v),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),

                      // ================================== [4] ADMINISTRATIF
                      _SectionTitle(
                        key: const ValueKey('health-section-admin'),
                        icon: StepwaysIcons.questionnaire,
                        title: t.health.section.admin,
                        explanation: t.health.section.adminWhy,
                      ),
                      _buildField(
                        controller: _doctorController,
                        label: t.health.field.doctor,
                        hint: t.health.hint.doctor,
                        icon: StepwaysIcons.secours,
                        maxLines: 2,
                        maxLength: kHealthContactMaxLength,
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _buildField(
                        controller: _insuranceController,
                        label: t.health.field.insurance,
                        hint: t.health.hint.insurance,
                        icon: StepwaysIcons.bouclier,
                        maxLines: 2,
                        maxLength: kHealthContactMaxLength,
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _CarteTile(
                        key: const ValueKey('health-carte-vitale'),
                        titre: t.health.cards.vitale,
                        nomFichier: _carteVitale,
                        onPrendre: (src) => _photographierCarte(
                          FicheMedicaleFichier.nomCarteVitale,
                          src,
                        ),
                        onRetirer: () =>
                            _retirerCarte(FicheMedicaleFichier.nomCarteVitale),
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _CarteTile(
                        key: const ValueKey('health-carte-mutuelle'),
                        titre: t.health.cards.mutuelle,
                        nomFichier: _carteMutuelle,
                        onPrendre: (src) => _photographierCarte(
                          FicheMedicaleFichier.nomCarteMutuelle,
                          src,
                        ),
                        onRetirer: () => _retirerCarte(
                          FicheMedicaleFichier.nomCarteMutuelle,
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXl),
                      // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary.
                      // isLoading porte l'etat _isSaving (AppButton affiche son
                      // spinner et desactive l'action, cf. grammaire unifiee) ;
                      // minHeight 52 conserve la cible du CTA pleine largeur.
                      // key/Semantics(button+label) preserves au-dessus.
                      Semantics(
                        button: true,
                        label: t.health.a11y.saveButton,
                        child: AppButton(
                          isLoading: _isSaving,
                          minHeight: 52,
                          icon: StepwaysIcons.enregistrer,
                          label: t.health.save,
                          onPressed: _isSaving ? null : _save,
                        ),
                      ),
                      // E57 (L6) : bouton « Effacer ma fiche » — branche sur le
                      // delete() DEJA present. Visible uniquement si la fiche
                      // contient quelque chose (rien a effacer sinon). Action
                      // DEFINITIVE annoncee aux lecteurs d'ecran, confirmation
                      // obligatoire (rouge).
                      if (_hasContent) ...[
                        const SizedBox(height: AppTheme.spacingBase),
                        Semantics(
                          button: true,
                          label: t.health.delete.a11yButton,
                          child: AppButton(
                            variant: AppButtonVariant.outline,
                            tone: AppTheme.rougeUrgence,
                            isLoading: _isDeleting,
                            minHeight: 52,
                            icon: StepwaysIcons.corbeille,
                            label: t.health.delete.button,
                            onPressed: _isDeleting ? null : _confirmAndDelete,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingBase),
                      Text(
                        t.health.emergencyHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withAlpha(140),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Les lignes de contact a prevenir, avec leur bouton de retrait.
  List<Widget> _buildContactRows() {
    final lignes = <Widget>[];
    for (var i = 0; i < _contacts.length; i++) {
      final ligne = _contacts[i];
      lignes.add(
        Padding(
          key: ValueKey('health-contact-$i'),
          padding: const EdgeInsets.only(bottom: AppTheme.spacingBase),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      key: ValueKey('health-contact-name-$i'),
                      controller: ligne.nomCtrl,
                      label: t.health.contacts.name,
                      hint: t.health.contacts.nameHint,
                      icon: StepwaysIcons.monCompte,
                      maxLines: 1,
                      maxLength: kEmergencyContactNameMaxLength,
                      showCounter: false,
                      textCapitalization: TextCapitalization.words,
                      // UN NOM SANS NUMERO NE SERT A RIEN : le secouriste lit un
                      // prenom et n'a personne a appeler. On refuse
                      // l'enregistrement plutot que d'enregistrer une promesse
                      // vide.
                      validator: (_) =>
                          ligne.estVide || ligne.nomCtrl.text.trim().isNotEmpty
                          ? null
                          : t.health.contacts.errorName,
                    ),
                  ),
                  IconButton(
                    key: ValueKey('health-contact-remove-$i'),
                    tooltip: t.health.contacts.remove,
                    icon: const StepIcon(StepwaysIcons.croix),
                    onPressed: () => setState(() {
                      _contacts.removeAt(i).dispose();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _buildField(
                key: ValueKey('health-contact-phone-$i'),
                controller: ligne.telCtrl,
                label: t.health.contacts.phone,
                hint: t.health.contacts.phoneHint,
                icon: StepwaysIcons.telephone,
                maxLines: 1,
                maxLength: kEmergencyContactPhoneMaxLength,
                showCounter: false,
                keyboardType: TextInputType.phone,
                validator: (_) =>
                    ligne.estVide || ligne.telCtrl.text.trim().isNotEmpty
                    ? null
                    : t.health.contacts.errorPhone,
              ),
            ],
          ),
        ),
      );
    }
    return lignes;
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String icon,
    int maxLines = 1,
    Key? key,
    int? maxLength,
    bool showCounter = true,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      key: key,
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // Compteur VISIBLE par defaut sur les champs bornes : la limite doit se
        // voir, une coupe muette serait le meme mensonge qu'un clamp muet.
        counterText: showCounter ? null : '',
        errorMaxLines: 3,
        hintStyle: TextStyle(
          color: colors.onSurface.withAlpha(90),
          fontSize: 13,
        ),
        prefixIcon: StepIcon(icon, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: BorderSide(color: colors.onSurface.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );
  }
}

/// Un titre de section de la fiche, avec la RAISON de sa place.
///
/// L'explication n'est pas un ornement : elle dit au randonneur pourquoi ce bloc
/// est la ou il est, donc pourquoi il vaut la peine d'etre rempli. « Un
/// secouriste lit d'abord qui vous etes » fait remplir le nom ; un champ « Nom »
/// tout seul se saute.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.explanation,
  });

  /// Chemin d'une icone Stepways ([StepwaysIcons]), et non un [IconData].
  ///
  /// FUSION 633 : le lot 632 a bascule les widgets partages de l'application
  /// sur le jeu de Christophe ([StepIcon], trace SVG), pendant que le lot 630
  /// reecrivait cet ecran contre l'ancien type. Ce titre de section suit le
  /// reste de l'application, sinon la fiche de sante serait le seul ecran
  /// reste en icones Material.
  final String icon;
  final String title;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StepIcon(icon, size: 20, color: colors.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            explanation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withAlpha(170),
            ),
          ),
        ],
      ),
    );
  }
}

/// LE GROUPE SANGUIN — LISTE FERMEE DE HUIT + « JE NE SAIS PAS » (tache 630).
///
/// Christophe, le 29/09 : huit groupes existent, la saisie libre n'a aucune
/// raison d'etre sur une fiche d'urgence. Un groupe mal saisi y est PIRE qu'un
/// champ vide, parce qu'un secouriste s'y fie.
///
/// LA VALEUR HERITEE NON RECONNUE EST MONTREE, PAS EFFACEE. Une fiche remplie
/// avant que la validation existe peut porter n'importe quoi. Le randonneur voit
/// ce qu'il avait ecrit et choisit — la consigne 630 est explicite : « les fiches
/// deja saisies ne perdent RIEN ».
class _ChampGroupeSanguin extends StatelessWidget {
  const _ChampGroupeSanguin({
    super.key,
    required this.valeur,
    required this.valeurHeritee,
    required this.onChanged,
  });

  final String? valeur;
  final String valeurHeritee;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: valeur,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: t.health.field.bloodType,
            prefixIcon: StepIcon(
              StepwaysIcons.ficheMedicale,
              color: colors.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              borderSide: BorderSide(color: colors.onSurface.withAlpha(60)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          hint: Text(t.health.hint.bloodType),
          items: [
            for (final v in kBloodTypeChoices)
              DropdownMenuItem<String>(
                value: v,
                child: Text(
                  v == kBloodTypeUnknown ? t.health.bloodTypeUnknown : v,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
        if (valeurHeritee.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            key: const ValueKey('health-blood-type-legacy'),
            t.health.bloodTypeLegacy(valeur: valeurHeritee),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.rougeUrgence,
            ),
          ),
        ],
      ],
    );
  }
}

/// Le don d'organes — liste fermee de trois valeurs (tache 630).
class _ChampDonOrganes extends StatelessWidget {
  const _ChampDonOrganes({
    super.key,
    required this.valeur,
    required this.onChanged,
  });

  final String? valeur;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String libelle(String v) => switch (v) {
      kOrganDonorYes => t.health.organDonor.yes,
      kOrganDonorNo => t.health.organDonor.no,
      _ => t.health.organDonor.unknown,
    };
    return DropdownButtonFormField<String>(
      initialValue: valeur,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: t.health.field.organDonor,
        prefixIcon: StepIcon(StepwaysIcons.pouce, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: BorderSide(color: colors.onSurface.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      hint: Text(t.health.hint.organDonor),
      items: [
        for (final v in kOrganDonorChoices)
          DropdownMenuItem<String>(value: v, child: Text(libelle(v))),
      ],
      onChanged: onChanged,
    );
  }
}

/// La date de naissance : un selecteur, jamais un clavier.
///
/// UN CLAVIER LAISSERAIT ECRIRE « 32/13/1850 » et il faudrait le refuser apres
/// coup, en cinq langues, avec cinq formats de date differents. Le selecteur du
/// systeme est deja localise et ne peut rendre qu'une date valide.
class _ChampDateNaissance extends StatelessWidget {
  const _ChampDateNaissance({
    super.key,
    required this.valeurIso,
    required this.onChoisir,
    required this.onEffacer,
  });

  final String valeurIso;
  final VoidCallback onChoisir;
  final VoidCallback onEffacer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = DateTime.tryParse(valeurIso);
    // AFFICHAGE LOCALISE, STOCKAGE NEUTRE : `formatCompactDate` rend la date
    // dans la convention de la langue active (03/04 n'est pas la meme date des
    // deux cotes de la Manche).
    final affichee = date == null
        ? ''
        : MaterialLocalizations.of(context).formatCompactDate(date);
    return InkWell(
      onTap: onChoisir,
      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: t.health.field.birthDate,
          hintText: t.health.hint.birthDate,
          prefixIcon: StepIcon(StepwaysIcons.age, color: colors.primary),
          suffixIcon: affichee.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('health-birth-date-clear'),
                  icon: const StepIcon(StepwaysIcons.croix),
                  tooltip: t.health.field.birthDateClear,
                  onPressed: onEffacer,
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            borderSide: BorderSide(color: colors.onSurface.withAlpha(60)),
          ),
        ),
        child: Text(
          affichee.isEmpty ? t.health.hint.birthDate : affichee,
          style: TextStyle(
            color: affichee.isEmpty
                ? colors.onSurface.withAlpha(90)
                : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

/// UNE PHOTO DE CARTE — VITALE OU MUTUELLE (tache 630).
///
/// Demande de Christophe le 29/09 : « photo des 2 », « tout reste sur le tel ».
/// L'image vit dans le MEME dossier protege que la fiche ; cette tuile ne fait
/// que la montrer, la remplacer ou la retirer.
///
/// L'APERCU EST PETIT, ET C'EST DELIBERE : une carte d'assurance maladie affichee
/// en grand sur un ecran qu'on tend a un inconnu n'a pas besoin d'etre lisible de
/// loin. On appuie pour l'agrandir quand on en a besoin.
class _CarteTile extends StatelessWidget {
  const _CarteTile({
    super.key,
    required this.titre,
    required this.nomFichier,
    required this.onPrendre,
    required this.onRetirer,
  });

  final String titre;
  final String nomFichier;
  final ValueChanged<ImageSource> onPrendre;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final aUnePhoto = nomFichier.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colors.onSurface.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StepIcon(
                aUnePhoto ? StepwaysIcons.portefeuille : StepwaysIcons.photo,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  titre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (aUnePhoto)
                IconButton(
                  key: ValueKey('$nomFichier-remove'),
                  icon: const StepIcon(StepwaysIcons.corbeille),
                  tooltip: t.health.cards.remove,
                  onPressed: onRetirer,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            aUnePhoto ? t.health.cards.stored : t.health.cards.explain,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withAlpha(170),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // `Wrap` ET PAS `Row`, ET C'EST UNE MESURE, PAS UNE PRECAUTION. Une
          // `Row` de ces deux boutons deborde de 279 pixels sur un ecran de
          // 360 px — c'est-a-dire sur la moitie des telephones vendus. Et la
          // longueur des deux libelles change dans chacune des cinq langues :
          // « Prendre en photo » fait 16 caracteres, « Foto neu aufnehmen » en
          // fait 18. Aucune largeur fixe ne tient cinq langues ; un retour a la
          // ligne, si.
          Wrap(
            spacing: AppTheme.spacingSm,
            children: [
              AppButton(
                variant: AppButtonVariant.text,
                icon: StepwaysIcons.photo,
                iconSize: 18,
                label: aUnePhoto ? t.health.cards.retake : t.health.cards.take,
                isFullWidth: false,
                onPressed: () => onPrendre(ImageSource.camera),
              ),
              AppButton(
                variant: AppButtonVariant.text,
                icon: StepwaysIcons.photo,
                iconSize: 18,
                label: t.health.cards.pick,
                isFullWidth: false,
                onPressed: () => onPrendre(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// LA RECOPIE DANS LA FICHE D'URGENCE DU TELEPHONE — UNE ETAPE (tache 630).
///
/// POURQUOI CE BLOC EXISTE, ET POURQUOI IL EST EN HAUT. La mesure du 29/09
/// (documentation Apple et Google) a etabli que SUR IPHONE aucune application
/// tierce ne peut montrer une fiche complete sans deverrouillage : ce que les
/// premiers intervenants atteignent est la fiche du SYSTEME, et Apple n'offre
/// aucune API pour y ecrire. Sur Android notre notification y arrive, mais le
/// randonneur peut masquer les notifications sensibles de son ecran verrouille.
///
/// LA RECOPIE EST DONC LE SEUL CHEMIN QUI MARCHE PARTOUT. Elle etait une ligne
/// de conseil parmi quatre depuis la tache 568 ; elle devient un geste avec un
/// etat, rappele tant qu'il n'est pas fait.
class _PhoneCardStep extends ConsumerWidget {
  const _PhoneCardStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fait = ref
        .watch(healthPrepareStepsProvider)
        .contains(HealthPrepStep.phoneCardCopied);
    return Container(
      key: const ValueKey('health-phone-card-step'),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: fait
            ? colors.primary.withAlpha(16)
            : AppTheme.rougeUrgence.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: fait
              ? colors.primary.withAlpha(60)
              : AppTheme.rougeUrgence.withAlpha(110),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StepIcon(
                fait ? StepwaysIcons.cochePleine : StepwaysIcons.cadenas,
                size: 20,
                color: fait ? colors.primary : AppTheme.rougeUrgence,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.health.phoneCard.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fait ? colors.primary : AppTheme.rougeUrgence,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            t.health.phoneCard.why,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withAlpha(215),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // LE GESTE EST REVOCABLE : on peut avoir efface la fiche du telephone,
          // ou en avoir change. Le randonneur doit pouvoir retrouver son rappel.
          CheckboxListTile(
            key: const ValueKey('health-phone-card-done'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: fait,
            title: Text(t.health.phoneCard.done),
            onChanged: (v) => ref
                .read(healthPrepareStepsProvider.notifier)
                .setPhoneCardCopied(v ?? false),
          ),
        ],
      ),
    );
  }
}

/// LE PRIX DE LA PROMESSE « CETTE FICHE NE QUITTE PAS CE TELEPHONE » (tache 612).
///
/// POURQUOI CE BLOC EXISTE. La decision de Christophe du 28/09 10:42 supprime
/// toute sauvegarde distante de la fiche medicale. Elle a un prix, et il l'a
/// assume en majuscules : changer de telephone, c'est ressaisir son groupe
/// sanguin, ses allergies, ses traitements. Un prix qu'on decouvre le jour ou on
/// change d'appareil est une mauvaise surprise ; un prix qu'on lit en remplissant
/// est un choix. Il est donc dit ICI, et avant les champs.
///
/// IL NE SE CONFOND PAS AVEC LE BANDEAU DE CONFIANCE AU-DESSUS. Celui-la dit ce
/// que nous ne faisons pas ; celui-ci dit ce que cela coute au randonneur. Les
/// deux ensemble font une promesse tenable — l'un sans l'autre fait une promesse
/// qui se retourne.
class _LocalOnlyPrice extends StatelessWidget {
  const _LocalOnlyPrice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: const ValueKey('health-local-only-price'),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colors.onSurface.withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepIcon(
            StepwaysIcons.effacerTelephone,
            size: 20,
            color: colors.onSurface.withAlpha(180),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.health.localOnlyPriceTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  t.health.localOnlyPrice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withAlpha(215),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CONSEILS D'USAGE TERRAIN de la fiche medicale + ACCUSE DE LECTURE (tache 568,
/// LOT Q — decision de Chris du 26/09 10:29).
///
/// CE QUE CHRIS A DEMANDE, verbatim : « on ne demarre pas un trek sans avoir
/// rempli sa fiche medicale et lu les conseils pour qu'elle soit applicable sur
/// le sentier ». « Applicable sur le sentier » est la cle : une fiche parfaite
/// que personne ne sait ou trouver ni comment montrer ne sert a rien le jour de
/// l'accident.
///
/// LES QUATRE CHOSES QUE CES CONSEILS DISENT, et pourquoi chacune :
///  1. OU LA TROUVER QUAND ON EST A TERRE — le blesse n'ouvre pas son telephone
///     lui-meme ; ses compagnons doivent savoir ou aller AVANT le depart.
///  2. COMMENT LA MONTRER AUX SECOURS — tendre l'ecran, dans l'ordre des
///     informations dont un secouriste a besoin.
///  3. POURQUOI LA RECOPIER DANS LA FICHE MEDICALE DU TELEPHONE — elle s'affiche
///     ECRAN VERROUILLE, sans code : c'est le seul chemin qui fonctionne quand
///     le secouriste ne connait pas cette application (la cle
///     `sos.medicalId.hint` le disait deja, sans que personne ne l'explique).
///     TACHE 630 : ce conseil a maintenant SON PROPRE BLOC, au-dessus, avec un
///     etat — parce que la mesure a montre que c'est le seul chemin qui marche
///     sur iPhone. Il reste ici pour que la liste des quatre gestes du terrain
///     demeure complete.
///  4. QU'UN PAPIER NE TOMBE JAMAIS EN PANNE DE BATTERIE — le telephone est le
///     maillon faible de tout ce dispositif ; l'admettre est plus utile que le
///     cacher.
///
/// ACCUSE DE LECTURE, PAS TEXTE DISPONIBLE : afficher un texte ne prouve pas
/// qu'il a ete lu. Le geste est explicite et IRREVOCABLE (on ne « delit » pas un
/// conseil), il est persiste par [healthPrepareStepsProvider] et il entre dans la
/// porte de demarrage du trek. Une fois fait, l'invitation devient une
/// confirmation — pas une case qu'on peut decocher par megarde.
class _UsageAdvice extends ConsumerWidget {
  const _UsageAdvice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final a = t.health.advice;
    final lu = ref
        .watch(healthPrepareStepsProvider)
        .contains(HealthPrepStep.adviceRead);

    return Container(
      key: const ValueKey('health-usage-advice'),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(16),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StepIcon(StepwaysIcons.journal, size: 20, color: colors.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  a.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Les quatre conseils, dans l'ordre de l'urgence reelle : d'abord ou
          // elle est, ensuite comment la montrer, puis les deux filets (fiche du
          // telephone, papier).
          _AdviceLine(icon: StepwaysIcons.repere, text: a.whereToFind),
          _AdviceLine(icon: StepwaysIcons.pouce, text: a.showToRescue),
          _AdviceLine(icon: StepwaysIcons.bouclier, text: a.phoneCard),
          _AdviceLine(icon: StepwaysIcons.cgu, text: a.paper),
          const SizedBox(height: AppTheme.spacingSm),
          if (lu)
            Row(
              children: [
                StepIcon(
                  StepwaysIcons.cochePleine,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    a.ackDone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            Semantics(
              button: true,
              label: a.ackButton,
              child: AppButton(
                key: const ValueKey('health-advice-ack'),
                variant: AppButtonVariant.outline,
                icon: StepwaysIcons.coche,
                label: a.ackButton,
                onPressed: () => ref
                    .read(healthPrepareStepsProvider.notifier)
                    .markAdviceRead(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Une ligne de conseil : puce iconique + texte (jamais de texte en dur).
class _AdviceLine extends StatelessWidget {
  const _AdviceLine({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: StepIcon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(215),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rappel de FINALITE + lien vers la gestion du consentement sante (E57/H1).
///
/// Forme souple (ARBITRAGES H1-a) : rappelle que ces infos servent a secourir et
/// restent sur le telephone, et offre un acces a l'ecran Confidentialite
/// (finalite healthData). Ne bloque PAS la saisie (local-only, pas de
/// « traitement » au sens strict). Textes Slang (5 langues).
class _ConsentReminder extends StatelessWidget {
  const _ConsentReminder({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepIcon(
                StepwaysIcons.info,
                size: 18,
                color: colors.onSurface.withAlpha(160),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.health.consent.purpose,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withAlpha(200),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              key: const ValueKey('health-consent-manage'),
              variant: AppButtonVariant.text,
              icon: StepwaysIcons.bouclier,
              iconSize: 18,
              label: t.health.consent.manage,
              isFullWidth: false,
              onPressed: onManage,
            ),
          ),
        ],
      ),
    );
  }
}
