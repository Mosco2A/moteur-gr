import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/consent_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/input_formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../data/hiker_profile_repository.dart';
import '../domain/hiker_input_bounds.dart';
import '../domain/hiker_profile.dart';
import '../providers/hiker_profile_provider.dart';

export '../domain/hiker_input_bounds.dart'
    show kAgeMin, kAgeMax, kHeightMinCm, kHeightMaxCm, kWeightMinKg, kWeightMaxKg;

/// Ecran « Fiche d'info » — 1ere page de la faisabilite (StepWays LOT 4, Ph1).
///
/// Saisie du profil randonneur : age, taille, poids (=> IMC calcule LOCALEMENT),
/// sexe (optionnel), pays (ISO). Morpho NON pre-remplie (vraies donnees = securite).
///
/// CONFIDENTIALITE (art. 9 RGPD) : la morpho est une donnee SENSIBLE. Elle
/// reste locale (+ miroir cloud anonyme par hash, jamais nominatif) et n'est
/// enregistree qu'apres consentement `ConsentPurpose.healthData` (finalite
/// morpho). Tous les textes via Slang (`t.hikerProfile.*`) — zero texte en dur.
class HikerProfileScreen extends ConsumerStatefulWidget {
  const HikerProfileScreen({super.key});

  @override
  ConsumerState<HikerProfileScreen> createState() =>
      _HikerProfileScreenState();
}

// Bornes metier des champs morpho (LOT 1, retour Chris #4) : elles vivent
// desormais dans `domain/hiker_input_bounds.dart` (FIX-1 / B1) pour que le
// bandeau « Materiel & Sac » applique EXACTEMENT la meme regle a la meme donnee.
// Re-exportees ci-dessus : les appelants existants ne changent pas.

/// IMC live borne — logique pure et testable du retour QA polish.
///
/// Retourne l'IMC UNIQUEMENT si `heightCm` ET `weightKg` sont tous deux DANS LES
/// BORNES metier (LOT 1 : taille [kHeightMinCm..kHeightMaxCm], poids
/// [kWeightMinKg..kWeightMaxKg]). Sinon `null` -> l'ecran masque le bloc IMC.
/// Evite d'afficher un IMC absurde tant que la saisie est invalide (ex. taille
/// 800), et recalcule des que la saisie redevient valide.
double? liveBmiWithinBounds(int? heightCm, double? weightKg) {
  if (heightCm == null || weightKg == null) return null;
  if (heightCm < kHeightMinCm || heightCm > kHeightMaxCm) return null;
  if (weightKg < kWeightMinKg || weightKg > kWeightMaxKg) return null;
  return HikerProfile(heightCm: heightCm, weightKg: weightKg).bmi;
}

class _HikerProfileScreenState extends ConsumerState<HikerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _countryController = TextEditingController();

  String? _sex; // null = non renseigne
  bool _loading = true;
  bool _saving = false;
  bool _morphoConsent = false;

  /// Message « fiche vide » (null = rien a signaler).
  ///
  /// Campagne personas 21/09 (MAJEUR-3) : une fiche SANS age, SANS taille et
  /// SANS poids etait acceptee et persistee EN SILENCE — l'ecran se fermait,
  /// rien n'etait dit, et ce 0/0/0 alimentait ensuite la faisabilite. Les
  /// autres saisies invalides, elles, sont deja refusees proprement. La fiche
  /// vide recoit desormais le meme traitement.
  String? _emptyError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ref.read(hikerProfileRepositoryProvider).getProfile();
    final consent = ref.read(consentServiceProvider);
    await consent.initialize();
    if (!mounted) return;
    setState(() {
      if (profile.age > 0) _ageController.text = '${profile.age}';
      if (profile.heightCm > 0) _heightController.text = '${profile.heightCm}';
      if (profile.weightKg > 0) {
        _weightController.text = _formatWeight(profile.weightKg);
      }
      // PAYS — ON N'AFFICHE QUE CE QUI EST UN PAYS (tache 553). Depuis que le
      // pays se CHOISIT dans une liste, l'ecran ne peut plus produire de code
      // invalide — mais il peut encore en LIRE un : une sauvegarde restauree
      // ([RestoreService]) ou le miroir cloud rendent la valeur telle qu'elle est
      // stockee, sans la verifier. Plutot que d'afficher « ZZ » comme s'il
      // s'agissait d'un pays, le champ repart a « non precise » et se rechoisit
      // en deux taps. Le vide reste le vide (champ optionnel).
      final storedCountry = profile.countryIso.trim().toUpperCase();
      _countryController.text =
          isValidIsoCountryCode(storedCountry) ? storedCountry : '';
      _sex = profile.sex;
      _morphoConsent = consent.hasConsent(ConsentPurpose.healthData);
      _loading = false;
    });
  }

  static String _formatWeight(double kg) =>
      kg == kg.roundToDouble() ? '${kg.round()}' : '$kg';

  /// IMC live, calcule UNIQUEMENT si la saisie taille+poids est DANS LES BORNES
  /// metier (voir [liveBmiWithinBounds]). `null` tant que la saisie est vide,
  /// non numerique ou hors bornes -> le bloc IMC est masque.
  double? get _liveBmi => liveBmiWithinBounds(
        int.tryParse(_heightController.text.trim()),
        double.tryParse(_weightController.text.trim().replaceAll(',', '.')),
      );

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profile = HikerProfile(
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      heightCm: int.tryParse(_heightController.text.trim()) ?? 0,
      weightKg: double.tryParse(
              _weightController.text.trim().replaceAll(',', '.')) ??
          0,
      sex: _sex,
      countryIso: _countryController.text.trim().toUpperCase(),
    );

    // FICHE VIDE : ni age, ni taille, ni poids. Ce n'est pas une fiche, et ce
    // 0/0/0 fausserait la faisabilite. Meme traitement que les autres saisies
    // invalides : on refuse, on le DIT, on ne quitte pas l'ecran.
    if (profile.isEmpty) {
      setState(() => _emptyError = t.hikerProfile.errorEmpty);
      return;
    }

    setState(() {
      _emptyError = null;
      _saving = true;
    });

    // Consentement morpho (art. 9) : si la morpho est renseignee, exiger le
    // consentement healthData (finalite morpho). Sinon, on n'enregistre pas.
    final consent = ref.read(consentServiceProvider);
    await consent.initialize();
    if (profile.hasMorphology) {
      if (_morphoConsent) {
        await consent.grant(ConsentPurpose.healthData);
      } else {
        await consent.revoke(ConsentPurpose.healthData);
      }
    }

    await ref.read(hikerProfileProvider.notifier).save(profile);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.hikerProfile.saved),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tp = t.hikerProfile;

    return Scaffold(
      appBar: AppHeader(title: tp.title),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bandeau confidentialite (donnee sensible, local only).
                    _PrivacyBanner(text: tp.privacyBanner),
                    const SizedBox(height: AppTheme.spacingLg),
                    // Age — borne [kAgeMin..kAgeMax] ans, max 3 chiffres.
                    _NumberField(
                      controller: _ageController,
                      label: tp.fieldAge,
                      hint: tp.hintAge,
                      icon: Icons.cake_outlined,
                      maxLength: 3,
                      limitMessage: tp.errorAge,
                      onChanged: (_) => _clearEmptyError(),
                      validator: (v) =>
                          _validateRange(v, kAgeMin, kAgeMax, tp.errorAge),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Taille — borne [kHeightMinCm..kHeightMaxCm] cm, max 3
                    // chiffres (empeche physiquement 8000 / 600000 signales
                    // par Chris).
                    _NumberField(
                      controller: _heightController,
                      label: tp.fieldHeight,
                      hint: tp.hintHeight,
                      icon: Icons.height,
                      maxLength: 3,
                      limitMessage: tp.errorHeight,
                      onChanged: (_) => _clearEmptyError(),
                      validator: (v) => _validateRange(
                          v, kHeightMinCm, kHeightMaxCm, tp.errorHeight),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Poids — borne [kWeightMinKg..kWeightMaxKg] kg, max 5
                    // caracteres (decimal : ex. « 200.5 »). Empeche
                    // physiquement 3261 signale par Chris.
                    _NumberField(
                      controller: _weightController,
                      label: tp.fieldWeight,
                      hint: tp.hintWeight,
                      icon: Icons.monitor_weight_outlined,
                      allowDecimal: true,
                      maxLength: 5,
                      limitMessage: tp.errorWeight,
                      onChanged: (_) => _clearEmptyError(),
                      validator: (v) => _validateRange(
                          v, kWeightMinKg, kWeightMaxKg, tp.errorWeight),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // IMC calcule (live), affiche SEULEMENT si taille ET poids
                    // sont saisis DANS LES BORNES (sinon `_liveBmi` == null et le
                    // bloc est masque : pas d'IMC absurde sur saisie invalide).
                    if (_liveBmi case final bmi?) _BmiCard(bmi: bmi),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Sexe (optionnel)
                    Text(tp.fieldSex, style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppTheme.spacingSm),
                    SegmentedButton<String?>(
                      showSelectedIcon: false,
                      emptySelectionAllowed: true,
                      segments: <ButtonSegment<String?>>[
                        ButtonSegment(
                          value: HikerSex.female,
                          label: Text(tp.sexFemale),
                        ),
                        ButtonSegment(
                          value: HikerSex.male,
                          label: Text(tp.sexMale),
                        ),
                        ButtonSegment(
                          value: null,
                          label: Text(tp.sexUnspecified),
                        ),
                      ],
                      selected: {_sex},
                      onSelectionChanged: (s) =>
                          setState(() => _sex = s.first),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Pays ISO
                    // Pays — selecteur avec les noms localises (retour Chris #2,
                    // tache 553). L'ancien indice « Code (ex. FR) » n'a plus
                    // lieu d'etre : on ne tape plus de code.
                    _CountryField(
                      controller: _countryController,
                      label: tp.fieldCountry,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    // Consentement morpho (art. 9), isole et explicite.
                    _MorphoConsentTile(
                      value: _morphoConsent,
                      onChanged: (v) => setState(() => _morphoConsent = v),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    // Refus « fiche vide », juste au-dessus du bouton : la ou
                    // l'oeil se trouve au moment ou l'on appuie.
                    if (_emptyError case final message?) ...[
                      _FormError(message: message),
                      const SizedBox(height: AppTheme.spacingSm),
                    ],
                    AppButton(
                      isLoading: _saving,
                      minHeight: 52,
                      icon: Icons.save,
                      label: tp.save,
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    Text(
                      tp.morphoNotPrefilledHint,
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
    );
  }

  /// Efface le refus « fiche vide » des que l'utilisateur saisit quelque chose
  /// (et relance le calcul d'IMC live, porte par le meme `setState`).
  void _clearEmptyError() {
    setState(() => _emptyError = null);
  }

  String? _validateRange(String? value, int min, int max, String error) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // champ optionnel : vide = non renseigne
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null || n < min || n > max) return error;
    return null;
  }
}

/// Bandeau de confiance (donnee sensible, reste sur l'appareil).
class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colors.primary.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: colors.primary, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Refus de formulaire, meme registre visuel que l'erreur d'un champ : icone
/// d'alerte + texte dans la couleur d'erreur du theme.
class _FormError extends StatelessWidget {
  const _FormError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      key: const ValueKey('hiker-profile-empty-error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: colors.error, size: 20),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.error),
          ),
        ),
      ],
    );
  }
}

/// Carte affichant l'IMC calcule + sa categorie OMS (via Slang).
class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.bmi});
  final double bmi;

  String _categoryKey(double v) {
    if (v < 18.5) return 'underweight';
    if (v < 25) return 'normal';
    if (v < 30) return 'overweight';
    return 'obese';
  }

  String _resolveCategory(String key) {
    final resolved = t['hikerProfile.bmiCategories.$key'];
    return resolved is String ? resolved : key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, color: colors.primary),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.hikerProfile.bmiLabel} ${bmi.toStringAsFixed(1)}',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  _resolveCategory(_categoryKey(bmi)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bascule de consentement morpho (art. 9), isolee et explicite.
class _MorphoConsentTile extends StatelessWidget {
  const _MorphoConsentTile({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tp = t.hikerProfile;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colors.tertiary.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined,
                  color: colors.tertiary, size: 20),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  tp.consentTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(tp.consentBody, style: theme.textTheme.bodySmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: value,
            onChanged: onChanged,
            title: Text(tp.consentToggle, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Champ numerique reutilise (age/taille/poids).
///
/// LOT 1 (retour Chris #4) : DOUBLE BARRIERE de saisie.
///  - A LA SAISIE : clavier numerique + `inputFormatters` (chiffres uniquement,
///    ou decimal borne) + [maxLength] qui EMPECHE PHYSIQUEMENT de taper une
///    valeur aberrante (ex. 8000 cm / 600000). Le compteur natif est masque
///    (`counterText: ''`) pour ne pas alourdir le formulaire.
///  - A LA VALIDATION : [validator] applique les bornes metier au submit.
///
/// FIX-1 (finding m1) : la barriere physique tronquait EN SILENCE (« 1280 »
/// devenait « 128 »). Elle reste — mais elle PARLE : toute frappe refusee
/// affiche [limitMessage], le meme message borne que le validator.
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.maxLength,
    required this.limitMessage,
    this.validator,
    this.onChanged,
    this.allowDecimal = false,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  /// Nombre MAX de caracteres saisissables (barriere physique a la saisie).
  final int maxLength;

  /// Message affiche quand une frappe est refusee faute de place.
  final String limitMessage;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool allowDecimal;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  /// Message transitoire « ta frappe a ete refusee » (null = rien a signaler).
  String? _limitError;

  /// Vrai si la frappe en cours a ete tronquee (evite d'effacer le message
  /// aussitot affiche quand la troncature modifie quand meme le texte).
  bool _truncatedThisEdit = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: widget.controller,
      keyboardType:
          TextInputType.numberWithOptions(decimal: widget.allowDecimal),
      maxLength: widget.maxLength,
      inputFormatters: [
        widget.allowDecimal
            ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
            : FilteringTextInputFormatter.digitsOnly,
        NotifyingLengthLimitingTextInputFormatter(
          widget.maxLength,
          onLimitReached: () {
            _truncatedThisEdit = true;
            if (_limitError != widget.limitMessage) {
              setState(() => _limitError = widget.limitMessage);
            }
          },
        ),
      ],
      onChanged: (value) {
        if (!_truncatedThisEdit && _limitError != null) {
          setState(() => _limitError = null);
        }
        _truncatedThisEdit = false;
        widget.onChanged?.call(value);
      },
      validator: widget.validator,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        // Compteur masque : la borne est deja portee par maxLength (physique)
        // et signalee par [limitMessage] des qu'elle mord.
        counterText: '',
        errorText: _limitError,
        errorMaxLines: 2,
        prefixIcon: Icon(widget.icon, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        ),
      ),
    );
  }
}

/// Nom LOCALISE du pays [code], dans la langue de l'application.
///
/// Trois etages, du meilleur au dernier recours :
///  1. le nom traduit du delegue [CountryLocalizations] pose sur la `MaterialApp`
///     (« France », « Deutschland », « Italia »...) ;
///  2. le nom anglais embarque dans le paquet, si le delegue n'est pas monte
///     (cas d'un test qui pompe l'ecran sans `localizationsDelegates`) ;
///  3. le code brut, pour les cinq territoires que la liste ISO connait et que le
///     selecteur ne propose pas (`AQ`, `BV`, `PN`, `TF`, `UM`) : une fiche
///     enregistree du temps de la saisie libre peut en porter un, et il vaut
///     mieux afficher « AQ » que rien.
String localizedCountryName(BuildContext context, String code) {
  final localized = CountryLocalizations.of(context)?.countryName(
    countryCode: code,
  );
  if (localized != null && localized.isNotEmpty) return localized;
  return Country.tryParse(code)?.name ?? code;
}

/// Champ pays — UN VRAI SELECTEUR, PLUS UN CODE A TAPER (retour Chris #2,
/// tache 553).
///
/// Mot pour mot : « Pourquoi on ne peut pas choisir un pays au lieu de mettre un
/// code FR c'est tout pourri ».
///
/// CE QU'ETAIT CE CHAMP. Une saisie libre de DEUX LETTRES, verifiee au submit
/// contre 249 codes ISO ecrits en dur. Ces 249 codes ne servaient QU'A REFUSER :
/// ils ne savaient afficher aucun nom de pays. Il fallait donc connaitre le code
/// ISO de son propre pays, le taper sans faute, et decouvrir a l'enregistrement
/// que « UK » n'existe pas (c'est « GB ») ou que « SP » n'est pas l'Espagne
/// (c'est « ES »). Pour un champ OPTIONNEL, c'etait un piege.
///
/// CE QU'IL EST. Un bouton qui ouvre la liste des pays avec leur NOM, dans la
/// langue de l'application, avec une recherche par nom. On ne tape plus rien, on
/// choisit — donc plus une seule saisie invalide POSSIBLE : le refus
/// « Code pays invalide » n'a plus d'occasion de s'afficher, il est devenu
/// inatteignable par construction.
///
/// D'OU VIENNENT LES NOMS (bonne pratique cherchee avant de coder, regle #6178,
/// BP en base) : du paquet `country_picker` (246 pays x 35 langues embarquees,
/// zero reseau, l'application reste utilisable hors-ligne). AUCUN nom de pays
/// n'est ecrit a la main — 249 pays x 5 langues, ce sont 1245 libelles a saisir
/// puis a maintenir, pour une donnee de reference qui ne nous appartient pas.
///
/// AUCUNE CLE i18n NOUVELLE (le LOT B, tache 552, est seul proprietaire des
/// fichiers de traduction en ce moment) : l'intitule reste
/// `t.hikerProfile.fieldCountry` (« Pays »), et l'etat « aucun pays choisi »
/// reutilise `t.hikerProfile.sexUnspecified` — « Non precise »,
/// « Keine Angabe », « Sin especificar », « Non specificato », « Unspecified ».
/// La phrase est generique et dit exactement la bonne chose ; une cle dediee
/// serait plus propre et pourra etre introduite quand les traductions seront
/// rendues.
///
/// Le champ reste OPTIONNEL : on peut ne rien choisir, et effacer son choix.
class _CountryField extends StatelessWidget {
  const _CountryField({
    required this.controller,
    required this.label,
  });

  /// Porte le CODE ISO (« FR »), pas le nom : c'est le code qui est enregistre,
  /// et le reste de l'application (base, miroir cloud, restauration) ne connait
  /// que lui. Le nom n'est qu'un affichage.
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // `ValueListenableBuilder` : l'affichage suit le controleur, donc le pays
    // choisi apparait sans que l'ecran parent ait a se reconstruire.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final code = value.text.trim().toUpperCase();
        final chosen = code.isNotEmpty;

        return InkWell(
          key: const ValueKey('hiker-profile-country-field'),
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          onTap: () => showCountryPicker(
            context: context,
            // On choisit un PAYS, pas un numero de telephone.
            showPhoneCode: false,
            // La recherche par nom est l'interet meme du selecteur : 246 pays,
            // personne ne defile jusqu'a « Nouvelle-Zelande ».
            showSearch: true,
            onSelect: (country) => controller.text = country.countryCode,
            countryListTheme: CountryListThemeData(
              backgroundColor: colors.surface,
              textStyle: theme.textTheme.bodyLarge,
              searchTextStyle: theme.textTheme.bodyLarge,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusCard),
              ),
              inputDecoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: colors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                ),
              ),
            ),
          ),
          child: InputDecorator(
            // Le libelle flotte toujours : la ligne n'est jamais vide, elle dit
            // soit le pays, soit « Non precise ».
            isEmpty: false,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(Icons.public, color: colors.primary),
              // Croix d'effacement quand un pays est choisi (le champ est
              // optionnel : on doit pouvoir revenir en arriere), chevron sinon
              // — de quoi voir qu'on peut ouvrir quelque chose.
              suffixIcon: chosen
                  ? IconButton(
                      key: const ValueKey('hiker-profile-country-clear'),
                      icon: const Icon(Icons.clear),
                      onPressed: () => controller.clear(),
                    )
                  : const Icon(Icons.arrow_drop_down),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
            ),
            child: Text(
              chosen
                  ? localizedCountryName(context, code)
                  : t.hikerProfile.sexUnspecified,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: chosen
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.6),
              ),
              // Certains noms sont longs (« Bosnie-Herzegovine ») : on les laisse
              // tenir sur deux lignes plutot que de les amputer.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
