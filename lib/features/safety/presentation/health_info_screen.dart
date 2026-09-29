// E5.16 / E57 -- Ecran formulaire informations sante LOCAL ONLY.
//
// Formulaire 5 champs : groupe sanguin, allergies, traitements,
// contact medecin, numero assurance.
// Message explicite : ces donnees restent sur le telephone (art. 9 RGPD,
// LOCAL ONLY a vie -- jamais de Firestore, jamais de cloud, meme apres P4).
// Accessible depuis l'ecran d'urgence (EmergencyScreen, route /health).
//
// LOT D / D1 (refonte UX StepWays) : cablage. Textes portes en Slang
// (namespace `health`, 5 langues) et couleurs alignees sur le theme -- plus
// aucun texte ni couleur en dur (spec E57 AM-1 / RM-6). Donnee personnelle
// independante du sentier (AM-6 : pas de trailId, pas de trailConfigProvider).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../data/fiche_medicale_fichier.dart';
import '../data/health_info_repository.dart';
import '../domain/health_bounds.dart';
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
  (ref) => HealthInfoRepository(fichier: ref.watch(ficheMedicaleFichierProvider)),
);

/// Provider des donnees sante actuelles.
final healthInfoProvider = FutureProvider<HealthInfo>((ref) {
  final repo = ref.watch(healthInfoRepositoryProvider);
  return repo.get();
});

/// E5.16 / E57 : Ecran formulaire informations de sante.
///
/// Formulaire avec 5 champs modifiables + bouton sauvegarder.
/// Les donnees sont stockees localement — dans un FICHIER DEDIE sous le dossier
/// declare exclu de la sauvegarde du telephone (tache 613, voir
/// [FicheMedicaleFichier]) — et ne quittent JAMAIS le telephone (pas de
/// Firestore, pas de cloud).
class HealthInfoScreen extends ConsumerStatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  ConsumerState<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends ConsumerState<HealthInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _treatmentsController = TextEditingController();
  final _doctorController = TextEditingController();
  final _insuranceController = TextEditingController();

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

    if (mounted) {
      setState(() {
        _bloodTypeController.text = info.bloodType;
        _allergiesController.text = info.allergies;
        _treatmentsController.text = info.treatments;
        _doctorController.text = info.doctorContact;
        _insuranceController.text = info.insuranceNumber;
        _hasContent = _computeHasContent();
        _isLoading = false;
      });
      // RE-SYNCHRONISATION DU SIGNAL DE PREPARATION (tache 568, LOT Q).
      //
      // La porte de demarrage du trek lit un signal en preferences
      // ([HealthPrepStep.filled]) et non le fichier de la fiche (cf.
      // `health_prepare_providers.dart` : la porte est une vue SYNCHRONE). Ce
      // signal pourrait donc, en theorie, divergier de la donnee reelle — par
      // exemple une fiche remplie AVANT que ce signal existe, ou effacee par un
      // chemin qui ne passe pas par cet ecran. On l'aligne ICI, a chaque
      // ouverture, sur ce que la base dit vraiment : le signal ne peut pas
      // mentir durablement.
      await ref
          .read(healthPrepareStepsProvider.notifier)
          .setFilled(info.hasData);
    }
  }

  /// Vrai si au moins un champ du formulaire est non vide.
  bool _computeHasContent() =>
      _bloodTypeController.text.trim().isNotEmpty ||
      _allergiesController.text.trim().isNotEmpty ||
      _treatmentsController.text.trim().isNotEmpty ||
      _doctorController.text.trim().isNotEmpty ||
      _insuranceController.text.trim().isNotEmpty;

  /// Sauvegarde les donnees du formulaire en local.
  ///
  /// FIX-1 (finding M6) : `validate()` est ENFIN appele. Le `Form` n'est plus
  /// decoratif — un groupe sanguin invente est refuse avec un message borne, et
  /// rien n'est enregistre tant que la fiche n'est pas coherente.
  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final info = HealthInfo(
      // Forme canonique (majuscules, sans espaces) : « a+ » est enregistre
      // « A+ », comme le lira le secouriste.
      bloodType: normalizeBloodType(_bloodTypeController.text),
      allergies: _allergiesController.text.trim(),
      treatments: _treatmentsController.text.trim(),
      doctorContact: _doctorController.text.trim(),
      insuranceNumber: _insuranceController.text.trim(),
    );

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
        _hasContent = _computeHasContent();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.health.saved),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
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

  /// Efface la fiche sante (E57) apres confirmation — branche le `delete()`
  /// DEJA present dans le repository (aucun recodage). Local + instantane +
  /// hors-ligne : aucune donnee ne quitte le telephone. Apres effacement, le
  /// widget ecran verrouille cesse tout seul d'afficher la partie sante (le
  /// repository est la source unique).
  Future<void> _confirmAndDelete() async {
    if (_isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.health.delete.confirmTitle),
        content: Text(t.health.delete.confirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.health.delete.cancel),
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
      _bloodTypeController.clear();
      _allergiesController.clear();
      _treatmentsController.clear();
      _doctorController.clear();
      _insuranceController.clear();
      _hasContent = false;
      _isDeleting = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.health.delete.done)));
  }

  @override
  void dispose() {
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _treatmentsController.dispose();
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
                            StepIcon(StepwaysIcons.cadenas, color: colors.primary, size: 20),
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
                      // CONSEILS D'USAGE TERRAIN + ACCUSE DE LECTURE (tache 568,
                      // LOT Q). Decision de Chris du 26/09, verbatim : « on ne
                      // demarre pas un trek sans avoir rempli sa fiche medicale
                      // ET LU LES CONSEILS pour qu'elle soit applicable sur le
                      // sentier ». Les conseils sont donc AVANT les champs : on
                      // apprend a s'en servir, puis on la remplit — et non
                      // l'inverse, d'autant que l'enregistrement depile l'ecran.
                      const _UsageAdvice(),
                      const SizedBox(height: AppTheme.spacingLg),
                      // Groupe sanguin : liste fermee (ABO + Rhesus). Saisie
                      // limitee aux lettres A/B/O et aux signes +/-, valeur
                      // verifiee au save (FIX-1 / M6).
                      _buildField(
                        key: const ValueKey('health-blood-type-field'),
                        controller: _bloodTypeController,
                        label: t.health.field.bloodType,
                        hint: t.health.hint.bloodType,
                        icon: StepwaysIcons.ficheMedicale,
                        maxLines: 1,
                        maxLength: kBloodTypeMaxLength,
                        showCounter: false,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[ABOabo+\-]')),
                        ],
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return null; // champ optionnel
                          return isValidBloodType(s)
                              ? null
                              : t.health.error.bloodType;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
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
      validator: validator,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // Compteur VISIBLE par defaut sur les champs bornes : la limite doit se
        // voir, une coupe muette serait le meme mensonge qu'un clamp muet.
        counterText: showCounter ? null : '',
        // Le message liste les 8 groupes valides : il doit tenir en entier,
        // sinon la reponse a « quoi saisir » se perd dans les points de suite.
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
    final lu = ref.watch(healthPrepareStepsProvider).contains(
          HealthPrepStep.adviceRead,
        );

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
                StepIcon(StepwaysIcons.cochePleine, size: 20, color: colors.primary),
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
            child: TextButton.icon(
              key: const ValueKey('health-consent-manage'),
              onPressed: onManage,
              icon: const StepIcon(StepwaysIcons.bouclier, size: 18),
              label: Text(t.health.consent.manage),
            ),
          ),
        ],
      ),
    );
  }
}
