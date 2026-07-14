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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/health_info_dao.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../data/health_info_repository.dart';
import '../domain/models/health_info.dart';

/// Provider du DAO sante (Drift).
///
/// Cablage LOT D/D1 : derive de [databaseProvider] (instance unique Drift).
/// Le DAO est genere (`AppDatabase.healthInfoDao`). L'override par defaut
/// pointe donc sur la vraie base ; les tests peuvent surcharger
/// [databaseProvider] (DB in-memory) sans toucher a ce provider.
final healthInfoDaoProvider = Provider<HealthInfoDao>(
  (ref) => ref.watch(databaseProvider).healthInfoDao,
);

/// Provider du repository sante (LOCAL ONLY).
final healthInfoRepositoryProvider = Provider<HealthInfoRepository>(
  (ref) => HealthInfoRepository(dao: ref.watch(healthInfoDaoProvider)),
);

/// Provider des donnees sante actuelles.
final healthInfoProvider = FutureProvider<HealthInfo>((ref) {
  final repo = ref.watch(healthInfoRepositoryProvider);
  return repo.get();
});

/// E5.16 / E57 : Ecran formulaire informations de sante.
///
/// Formulaire avec 5 champs modifiables + bouton sauvegarder.
/// Les donnees sont stockees localement (Drift) et ne quittent
/// JAMAIS le telephone (pas de Firestore, pas de cloud).
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
        _isLoading = false;
      });
    }
  }

  /// Sauvegarde les donnees du formulaire en local.
  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final info = HealthInfo(
      bloodType: _bloodTypeController.text.trim(),
      allergies: _allergiesController.text.trim(),
      treatments: _treatmentsController.text.trim(),
      doctorContact: _doctorController.text.trim(),
      insuranceNumber: _insuranceController.text.trim(),
    );

    final repo = ref.read(healthInfoRepositoryProvider);
    await repo.save(info);

    // Rafraichir le provider
    ref.invalidate(healthInfoProvider);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.health.saved),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
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
      appBar: AppBar(
        title: Text(t.health.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCard),
                          border:
                              Border.all(color: colors.primary.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: colors.primary, size: 20),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Text(
                                t.health.privacyBanner,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: colors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      _buildField(
                        controller: _bloodTypeController,
                        label: t.health.field.bloodType,
                        hint: t.health.hint.bloodType,
                        icon: Icons.bloodtype,
                        maxLines: 1,
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _buildField(
                        controller: _allergiesController,
                        label: t.health.field.allergies,
                        hint: t.health.hint.allergies,
                        icon: Icons.warning_amber,
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _buildField(
                        controller: _treatmentsController,
                        label: t.health.field.treatments,
                        hint: t.health.hint.treatments,
                        icon: Icons.medication,
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _buildField(
                        controller: _doctorController,
                        label: t.health.field.doctor,
                        hint: t.health.hint.doctor,
                        icon: Icons.local_hospital,
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                      _buildField(
                        controller: _insuranceController,
                        label: t.health.field.insurance,
                        hint: t.health.hint.insurance,
                        icon: Icons.shield,
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                      Semantics(
                        button: true,
                        label: t.health.a11y.saveButton,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusButton),
                            ),
                          ),
                          icon: _isSaving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isSaving ? t.health.saving : t.health.save,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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
    required IconData icon,
    int maxLines = 1,
  }) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: colors.onSurface.withAlpha(90),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: colors.primary),
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
