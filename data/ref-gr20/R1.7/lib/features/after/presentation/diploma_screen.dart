import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/premium_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../trek/data/trek_models.dart';
import '../../trek/providers/demo_trek_provider.dart';
import '../data/diploma_pdf_service.dart';
import '../providers/after_providers.dart';
import '../providers/in_app_review_provider.dart';

/// APRES-02 : Diplôme personnalisé.
///
/// Affiche un diplôme de finisher avec parcours, dates, membres,
/// dénivelé, carte miniature, numéro unique, et options de partage.
/// Le diplôme Premium (fond illustre) est inclus dans la licence Premium (#GR20-061).
class DiplomaScreen extends ConsumerStatefulWidget {
  const DiplomaScreen({super.key});

  @override
  ConsumerState<DiplomaScreen> createState() => _DiplomaScreenState();
}

class _DiplomaScreenState extends ConsumerState<DiplomaScreen> {
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    // E5.17: Demander un avis store apres affichage du diplome (trek termine).
    // PostFrameCallback pour laisser le build se terminer avant la dialog native.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInAppReviewIfEligible();
    });
  }

  /// E5.17: Demande d'avis store — 1 seule fois par trek.
  Future<void> _requestInAppReviewIfEligible() async {
    final session = ref.read(effectiveTrekSessionProvider);
    final isDemoMode = ref.read(isDemoModeProvider);
    // Pas de review en mode demo ni si trek non termine
    if (isDemoMode || session == null || session.status != TrekStatus.completed) {
      return;
    }
    final reviewService = ref.read(inAppReviewServiceProvider);
    await reviewService.requestReviewIfEligible(session.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(effectiveTrekSessionProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    // B52fix: gate trek-complete — accessible uniquement si trek terminé ou mode démo
    if (session?.status != TrekStatus.completed && !isDemoMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mon diplôme'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppTheme.grisGranite),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  'Disponible a la fin du trek',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.grisGranite,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Terminez votre GR20 pour obtenir votre diplôme personnalisé.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisGranite,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final diploma = ref.watch(diplomaProvider);
    // Le diplôme premium est inclus dans la licence — pas d'achat separe (#GR20-061)
    final isPremiumDiploma = ref.watch(isPremiumProvider);

    final startStr =
        '${diploma.startDate.day}/${diploma.startDate.month}/${diploma.startDate.year}';
    final endStr =
        '${diploma.endDate.day}/${diploma.endDate.month}/${diploma.endDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon diplôme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // B11: bandeau donnees démo si pas de trek terminé réel
            if (isDemoMode)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.orangeTerre.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.orangeTerre.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.explore, size: 20, color: AppTheme.orangeTerre),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'Apercu démo — Terminez un trek pour obtenir votre vrai diplôme.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.orangeTerre,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Indicateur version (premium = design exclusif, inclus dans la licence)
            if (isPremiumDiploma)
              _buildPremiumIncludedBanner(theme),
            const SizedBox(height: AppTheme.spacingLg),

            // Le diplôme
            _buildDiplomaCard(theme, diploma, startStr, endStr, isPremiumDiploma),
            const SizedBox(height: AppTheme.spacingLg),

            // Boutons d'action
            _buildActions(theme, diploma),
            const SizedBox(height: AppTheme.spacingBase),
          ],
        ),
      ),
    );
  }

  /// Bandeau indiquant que le diplôme premium est inclus dans la licence
  Widget _buildPremiumIncludedBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 18),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            'Diplôme Premium inclus dans votre licence',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiplomaCard(
    ThemeData theme,
    DiplomaData diploma,
    String startStr,
    String endStr,
    bool isPremiumDiploma,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isPremiumDiploma
              ? const Color(0xFFFFD700)
              : AppTheme.vertMaquisLight,
          width: isPremiumDiploma ? 3 : 2,
        ),
        gradient: isPremiumDiploma
            ? const LinearGradient(
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: isPremiumDiploma ? null : const Color(0xFF1E1E1E),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            // En-tete
            if (isPremiumDiploma)
              const Icon(
                Icons.workspace_premium,
                size: 40,
                color: Color(0xFFFFD700),
              )
            else
              const Icon(
                Icons.emoji_events,
                size: 40,
                color: AppTheme.vertMaquisLight,
              ),
            const SizedBox(height: AppTheme.spacingSm),

            // Titre
            Text(
              'CERTIFICAT DE FINISHER',
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 3,
                color: isPremiumDiploma
                    ? const Color(0xFFFFD700)
                    : AppTheme.vertMaquisLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'GR20',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isPremiumDiploma
                    ? Colors.white
                    : AppTheme.vertMaquisLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              diploma.parcours,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isPremiumDiploma
                    ? Colors.white.withAlpha(200)
                    : AppTheme.grisGranite,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Separateur
            Container(
              height: 1,
              color: isPremiumDiploma
                  ? const Color(0xFFFFD700).withAlpha(60)
                  : AppTheme.grisGranite.withAlpha(60),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Membres
            Text(
              'Atteste que',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.grisGranite,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...diploma.memberNames.map((name) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                child: Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isPremiumDiploma
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              );
            }),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'a parcouru le GR20 intégral',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.grisGranite,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Dates
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDiplomaDetail(theme, 'Départ', startStr, isPremiumDiploma),
                const SizedBox(width: AppTheme.spacingXl),
                _buildDiplomaDetail(theme, 'Arrivée', endStr, isPremiumDiploma),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDiplomaDetail(
                  theme,
                  'Distance',
                  '${diploma.totalDistance.toStringAsFixed(1)} km',
                  isPremiumDiploma,
                ),
                const SizedBox(width: AppTheme.spacingXl),
                _buildDiplomaDetail(
                  theme,
                  'Dénivelé',
                  '${diploma.totalElevation} m D+',
                  isPremiumDiploma,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Carte miniature
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: SizedBox(
                height: 150,
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(diploma.routePoints),
                      padding: const EdgeInsets.all(20),
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.only1cent.g20_app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: diploma.routePoints,
                          strokeWidth: 3,
                          color: isPremiumDiploma
                              ? const Color(0xFFFFD700)
                              : AppTheme.vertMaquisLight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Separateur
            Container(
              height: 1,
              color: isPremiumDiploma
                  ? const Color(0xFFFFD700).withAlpha(60)
                  : AppTheme.grisGranite.withAlpha(60),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Numero de finisher
            Text(
              'Finisher N',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisGranite,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              diploma.finisherNumber,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 2,
                color: isPremiumDiploma
                    ? const Color(0xFFFFD700)
                    : AppTheme.vertMaquisLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiplomaDetail(
    ThemeData theme, String label, String value, bool isPremiumDiploma,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisGranite,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isPremiumDiploma ? Colors.white : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme, DiplomaData diploma) {
    return Column(
      children: [
        // Télécharger PDF (GR-018)
        AppButton(
          label: 'TÉLÉCHARGER EN PDF',
          onPressed: _isGeneratingPdf
              ? null
              : () async {
                  setState(() => _isGeneratingPdf = true);
                  try {
                    await DiplomaPdfService.generateAndShare(diploma);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur PDF : $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isGeneratingPdf = false);
                    }
                  }
                },
          isLoading: _isGeneratingPdf,
          icon: Icons.picture_as_pdf,
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Exporter GPX (F6)
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Export GPX en cours...'),
              ),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Exporter GPX'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Partager
        Text(
          'Partager sur',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisGranite,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShareButton(
              theme,
              icon: Icons.camera_alt,
              label: 'Instagram',
              color: const Color(0xFFE1306C),
            ),
            const SizedBox(width: AppTheme.spacingBase),
            _buildShareButton(
              theme,
              icon: Icons.work,
              label: 'LinkedIn',
              color: const Color(0xFF0A66C2),
            ),
            const SizedBox(width: AppTheme.spacingBase),
            _buildShareButton(
              theme,
              icon: Icons.chat,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Partage $label (simulation MVP)')),
        );
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(100)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.grisGranite,
            ),
          ),
        ],
      ),
    );
  }
}
