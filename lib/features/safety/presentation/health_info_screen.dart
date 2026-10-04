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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/screen_entry.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../data/health_info_file.dart';
import '../data/health_info_repository.dart';
import '../data/card_photo_capture.dart';
import '../domain/models/health_info.dart';
import '../providers/health_prepare_providers.dart';
import '../providers/refus_sauvegarde_systeme_provider.dart';
import 'health_info_dialogs.dart';
import 'health_info_form.dart';
import 'health_info_form_data.dart';
import 'health_info_inputs.dart';

/// Provider du stockage durable de la fiche medicale.
///
/// TACHE 613 : il a remplace `healthInfoDaoProvider`, qui derivait de la base
/// Drift commune. La fiche a desormais SON PROPRE FICHIER, sous le dossier
/// declare exclu de la sauvegarde du telephone — la raison entiere est dans
/// [HealthInfoFile]. Les tests surchargent CE provider (repertoire
/// temporaire) ; surcharger `databaseProvider` n'a plus d'effet sur la fiche,
/// et c'est voulu : plus rien de medical ne passe par la base.
final healthInfoFileProvider = Provider<HealthInfoFile>(
  (ref) => HealthInfoFile(),
);

/// Provider du repository sante (LOCAL ONLY).
final healthInfoRepositoryProvider = Provider<HealthInfoRepository>(
  (ref) => HealthInfoRepository(fichier: ref.watch(healthInfoFileProvider)),
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
final priseDePhotoCarteProvider = Provider<CardPhotoCapture>(
  (ref) => takeCardPhoto,
);

/// E5.16 / E57 / 630 : ecran de la fiche d'urgence.
///
/// Les donnees sont stockees localement — dans un FICHIER DEDIE sous le dossier
/// declare exclu de la sauvegarde du telephone (tache 613, voir
/// [HealthInfoFile]) — et ne quittent JAMAIS le telephone (pas de
/// Firestore, pas de cloud, pas de sauvegarde Google ou Apple).
class HealthInfoScreen extends ConsumerStatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  ConsumerState<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends ConsumerState<HealthInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Les valeurs de la fiche en cours d'edition ([HealthInfoFormData]) :
  /// l'etat les possede, les modifie sous `setState` et les libere.
  final _form = HealthInfoFormData();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  /// Vrai si la fiche contient au moins une donnee (pilote l'affichage du
  /// bouton « Effacer ma fiche » : rien a effacer sur une fiche vide).
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    // LA MIETTE D'OBSERVABILITE DE CET ECRAN (lot 645-09), posee a l'entree.
    // Lot 645-06b : elle etait declaree dans la racine d'une bibliotheque a
    // `part` et posee dans le morceau qui portait l'etat ; l'etat vit de
    // nouveau dans ce fichier, la miette y est donc declaree ET posee.
    observeScreenEntry(ref, ScreenBreadcrumb.healthInfo);
    _loadExistingData();
  }

  /// Charge les donnees existantes dans les champs.
  Future<void> _loadExistingData() async {
    final repo = ref.read(healthInfoRepositoryProvider);
    final info = await repo.get();

    if (!mounted) return;
    setState(() {
      _form.fill(info);
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

    final info = _form.compose();
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

    if (mounted) await _confirmSaved(info);
  }

  /// Ce qui suit un enregistrement reussi, ecran encore monte : confirmer,
  /// redemander le consentement, puis depiler s'il y a ou revenir.
  Future<void> _confirmSaved(HealthInfo info) async {
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
    await askHealthConsentAgainAfterChange(context, ref);
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
    final confirmed = await confirmHealthInfoDeletion(context);
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
      _form.clear();
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
    final actuelle = DateTime.tryParse(_form.birthDate);
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
      _form.birthDate =
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
  Future<void> _photographCard(String nomFichier, ImageSource source) async {
    final prise = ref.read(priseDePhotoCarteProvider);
    final resultat = await prise(source);
    if (!mounted) return;

    switch (resultat.issue) {
      case CardPhotoOutcome.annule:
        return;
      case CardPhotoOutcome.refus:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.health.cards.permissionRefused)),
        );
        return;
      case CardPhotoOutcome.echec:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.health.cards.failed)));
        return;
      case CardPhotoOutcome.reussite:
        break;
    }

    final fichier = ref.read(healthInfoFileProvider);
    await fichier.saveCard(nomFichier, resultat.octets!);
    if (!mounted) return;
    setState(() {
      if (nomFichier == HealthInfoFile.nomCarteVitale) {
        _form.carteVitale = nomFichier;
      } else {
        _form.carteMutuelle = nomFichier;
      }
      _hasContent = true;
    });
  }

  /// Retire la photo d'une carte — du disque ET de la fiche.
  Future<void> _removeCard(String nomFichier) async {
    final fichier = ref.read(healthInfoFileProvider);
    await fichier.eraseCard(nomFichier);
    if (!mounted) return;
    setState(() {
      if (nomFichier == HealthInfoFile.nomCarteVitale) {
        _form.carteVitale = '';
      } else {
        _form.carteMutuelle = '';
      }
    });
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// Le randomneur a choisi son groupe sanguin.
  ///
  /// Le randonneur a tranche : l'avertissement n'a plus lieu d'etre, la valeur
  /// heritee est remplacee.
  void _setBloodType(String? v) => setState(() {
    _form.bloodType = v;
    _form.bloodTypeHerite = '';
  });

  /// Le randonneur a dit s'il est donneur d'organes.
  void _setOrganDonor(String? v) => setState(() => _form.organDonor = v);

  /// Le randonneur a retire sa date de naissance.
  void _effacerDateNaissance() => setState(() => _form.birthDate = '');

  /// Une ligne de contact vide de plus, a remplir.
  void _ajouterContact() =>
      setState(() => _form.contacts.add(ContactLineDraft()));

  /// Retire la ligne de contact [index] et libere ses controleurs.
  void _retirerContact(int index) =>
      setState(() => _form.contacts.removeAt(index).dispose());

  @override
  Widget build(BuildContext context) {
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
                      HealthFormTop(
                        fullNameController: _form.fullNameController,
                        addressController: _form.addressController,
                        birthDate: _form.birthDate,
                        onChoisirDate: _choisirDateNaissance,
                        onEffacerDate: _effacerDateNaissance,
                        contacts: _form.contacts,
                        onRemoveContact: _retirerContact,
                        onAddContact: _ajouterContact,
                      ),
                      HealthFormBottom(
                        allergiesController: _form.allergiesController,
                        treatmentsController: _form.treatmentsController,
                        conditionsController: _form.conditionsController,
                        bloodType: _form.bloodType,
                        bloodTypeHerite: _form.bloodTypeHerite,
                        onBloodTypeChanged: _setBloodType,
                        organDonor: _form.organDonor,
                        onOrganDonorChanged: _setOrganDonor,
                        doctorController: _form.doctorController,
                        insuranceController: _form.insuranceController,
                        carteVitale: _form.carteVitale,
                        carteMutuelle: _form.carteMutuelle,
                        onTakeCard: _photographCard,
                        onRemoveCard: _removeCard,
                        isSaving: _isSaving,
                        isDeleting: _isDeleting,
                        hasContent: _hasContent,
                        onSave: _save,
                        onDelete: _confirmAndDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
