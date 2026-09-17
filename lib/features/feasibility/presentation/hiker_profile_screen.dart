import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/consent_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../data/hiker_profile_repository.dart';
import '../domain/hiker_profile.dart';
import '../providers/hiker_profile_provider.dart';

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

// Bornes metier des champs morpho (LOT 1, retour Chris #4).
// Ancrees sur BP_faisabilite_entrainement.md (profils randonneur) + valeurs du
// mandat. Servent A LA FOIS a la validation (submit) et aux messages d'erreur.
const int kAgeMin = 8;
const int kAgeMax = 100;
const int kHeightMinCm = 100;
const int kHeightMaxCm = 250;
const int kWeightMinKg = 30;
const int kWeightMaxKg = 150;

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
      _countryController.text = profile.countryIso;
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

    setState(() => _saving = true);

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
                    // Age — borne 8 a 100 ans (BP faisabilite), max 3 chiffres.
                    _NumberField(
                      controller: _ageController,
                      label: tp.fieldAge,
                      hint: tp.hintAge,
                      icon: Icons.cake_outlined,
                      maxLength: 3,
                      validator: (v) =>
                          _validateRange(v, kAgeMin, kAgeMax, tp.errorAge),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Taille — borne 100 a 250 cm (BP), max 3 chiffres (empeche
                    // physiquement 8000 / 600000 signales par Chris).
                    _NumberField(
                      controller: _heightController,
                      label: tp.fieldHeight,
                      hint: tp.hintHeight,
                      icon: Icons.height,
                      maxLength: 3,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => _validateRange(
                          v, kHeightMinCm, kHeightMaxCm, tp.errorHeight),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Poids — borne 30 a 150 kg (BP), max 5 caracteres (decimal :
                    // ex. « 150.5 »). Empeche physiquement 3261 signale par Chris.
                    _NumberField(
                      controller: _weightController,
                      label: tp.fieldWeight,
                      hint: tp.hintWeight,
                      icon: Icons.monitor_weight_outlined,
                      allowDecimal: true,
                      maxLength: 5,
                      onChanged: (_) => setState(() {}),
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
                    _CountryField(
                      controller: _countryController,
                      label: tp.fieldCountry,
                      hint: tp.hintCountry,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    // Consentement morpho (art. 9), isole et explicite.
                    _MorphoConsentTile(
                      value: _morphoConsent,
                      onChanged: (v) => setState(() => _morphoConsent = v),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
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
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.maxLength,
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
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      maxLength: maxLength,
      inputFormatters: [
        allowDecimal
            ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
            : FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // Compteur masque : la borne est deja portee par maxLength (physique).
        counterText: '',
        prefixIcon: Icon(icon, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        ),
      ),
    );
  }
}

/// Champ pays (code ISO 2 lettres).
class _CountryField extends StatelessWidget {
  const _CountryField({
    required this.controller,
    required this.label,
    required this.hint,
  });
  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      maxLength: 2,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
        LengthLimitingTextInputFormatter(2),
      ],
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(Icons.public, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        ),
      ),
    );
  }
}
