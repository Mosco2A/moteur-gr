// E5.16 -- Ecran formulaire informations sante LOCAL ONLY.
//
// Formulaire 5 champs : groupe sanguin, allergies, traitements,
// contact medecin, numero assurance.
// Message explicite : ces donnees restent sur le telephone.
// Accessible depuis l'ecran d'urgence (EmergencyScreen).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/health_info_repository.dart';
import '../domain/models/health_info.dart';
import '../../../core/data/daos/health_info_dao.dart';

/// Provider du DAO sante (Drift).
final healthInfoDaoProvider = Provider<HealthInfoDao>((ref) {
  throw UnimplementedError(
    'healthInfoDaoProvider must be overridden with the actual DAO instance',
  );
});

/// Provider du repository sante (LOCAL ONLY).
final healthInfoRepositoryProvider = Provider<HealthInfoRepository>(
  (ref) => HealthInfoRepository(dao: ref.watch(healthInfoDaoProvider)),
);

/// Provider des donnees sante actuelles.
final healthInfoProvider = FutureProvider<HealthInfo>((ref) {
  final repo = ref.watch(healthInfoRepositoryProvider);
  return repo.get();
});

/// E5.16 : Ecran formulaire informations de sante.
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
          content: const Text('Informations sauvegardees'),
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
    final primaryColor = theme.colorScheme.primary;
    final primaryLight = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations sante'),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bandeau securite
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(color: primaryLight.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, color: primaryLight, size: 20),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(
                              'Ces donnees restent sur votre telephone. '
                              'Elles ne sont jamais envoyees sur internet.',
                              style: TextStyle(fontSize: 13, color: primaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildField(controller: _bloodTypeController, label: 'Groupe sanguin', hint: 'Ex: A+, O-, AB+', icon: Icons.bloodtype, maxLines: 1),
                    const SizedBox(height: AppTheme.spacingBase),
                    _buildField(controller: _allergiesController, label: 'Allergies', hint: 'Ex: Penicilline, arachides', icon: Icons.warning_amber, maxLines: 3),
                    const SizedBox(height: AppTheme.spacingBase),
                    _buildField(controller: _treatmentsController, label: 'Traitements en cours', hint: 'Ex: Levothyrox 50mg/j', icon: Icons.medication, maxLines: 3),
                    const SizedBox(height: AppTheme.spacingBase),
                    _buildField(controller: _doctorController, label: 'Medecin traitant', hint: 'Ex: Dr Dupont 04 95 xx xx xx', icon: Icons.local_hospital, maxLines: 2),
                    const SizedBox(height: AppTheme.spacingBase),
                    _buildField(controller: _insuranceController, label: 'N\u00b0 assurance / mutuelle', hint: 'Ex: Carte europeenne', icon: Icons.shield, maxLines: 2),
                    const SizedBox(height: AppTheme.spacingXl),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
                      ),
                      icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    Text("En cas d'urgence, montrez cet ecran aux secours.", textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required String hint, required IconData icon, int maxLines = 1}) {
    final primaryLight = Theme.of(context).colorScheme.primary;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withAlpha(60), fontSize: 13),
        prefixIcon: Icon(icon, color: primaryLight),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusInput)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusInput), borderSide: BorderSide(color: Colors.white.withAlpha(40))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusInput), borderSide: BorderSide(color: primaryLight, width: 2)),
      ),
    );
  }
}
