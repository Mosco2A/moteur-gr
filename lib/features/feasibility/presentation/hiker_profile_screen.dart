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
/// sexe (optionnel), pays (ISO). Morpho NON pre-remplie (honnetete = securite).
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

  double get _liveBmi {
    final h = int.tryParse(_heightController.text.trim()) ?? 0;
    final w = double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ?? 0;
    return HikerProfile(heightCm: h, weightKg: w).bmi ?? 0;
  }

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
                    // Age
                    _NumberField(
                      controller: _ageController,
                      label: tp.fieldAge,
                      hint: tp.hintAge,
                      icon: Icons.cake_outlined,
                      validator: (v) => _validateRange(v, 5, 120, tp.errorAge),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Taille
                    _NumberField(
                      controller: _heightController,
                      label: tp.fieldHeight,
                      hint: tp.hintHeight,
                      icon: Icons.height,
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          _validateRange(v, 80, 250, tp.errorHeight),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // Poids
                    _NumberField(
                      controller: _weightController,
                      label: tp.fieldWeight,
                      hint: tp.hintWeight,
                      icon: Icons.monitor_weight_outlined,
                      allowDecimal: true,
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          _validateRange(v, 25, 300, tp.errorWeight),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    // IMC calcule (live), affiche seulement si taille+poids.
                    if (_liveBmi > 0) _BmiCard(bmi: _liveBmi),
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
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.onChanged,
    this.allowDecimal = false,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        allowDecimal
            ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
            : FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
