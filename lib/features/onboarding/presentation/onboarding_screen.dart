import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../providers/onboarding_providers.dart';

/// Page courante dans le PageView d'onboarding.
final _onboardingPageProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Nombre total de pages dans l'onboarding.
const int _totalPages = 3;

/// Ecran d'accueil affiche au tout premier lancement de l'application.
///
/// PageView de 3 ecrans, 100% generique (aucune marque de sentier en dur —
/// le nom du produit vient de [TrailConfig.displayName]) :
///   1. Bienvenue (nom de produit parametrique)
///   2. Choix de la langue (5 locales Slang)
///   3. Telechargement du premier sentier (lien vers le catalogue)
///
/// Un bouton « Passer » permet de sauter directement l'onboarding. Une fois
/// termine (ou passe), le flag est persiste via [completeOnboarding] et le
/// guard du routeur ne reaffiche plus cet ecran (E5.1b).
/// Tous les textes passent par Slang (`t.onboarding.*`).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(_onboardingPageProvider);
    final tr = Translations.of(context);
    final theme = Theme.of(context);
    // Nom de produit parametrique (jamais code en dur dans le moteur).
    final appName = ref.watch(trailConfigProvider.select((c) => c.displayName));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Bouton « Passer » en haut a droite ---
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    tr.onboarding.skip,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            // --- PageView principal ---
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) =>
                    ref.read(_onboardingPageProvider.notifier).state = index,
                children: [
                  _WelcomePage(tr: tr, theme: theme, appName: appName),
                  _LanguagePage(tr: tr, theme: theme),
                  _DownloadPage(tr: tr, theme: theme, onBrowse: _goToCatalog),
                ],
              ),
            ),

            // --- Indicateur de page + bouton d'action ---
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _totalPages,
                      (index) => _PageDot(
                        isActive: index == currentPage,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (currentPage < _totalPages - 1)
                    ElevatedButton(
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Text(tr.onboarding.next),
                    )
                  else
                    ElevatedButton(
                      onPressed: _finish,
                      child: Text(tr.onboarding.getStarted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Termine l'onboarding (persiste le flag) puis bascule sur le catalogue.
  Future<void> _finish() async {
    await completeOnboarding(ref);
    _goToCatalog();
  }

  /// Navigue vers le catalogue de sentiers (telechargement du premier sentier).
  void _goToCatalog() {
    if (!mounted) return;
    context.go('/catalog');
  }
}

/// Page 1 : bienvenue. Le nom du produit est parametrique ([appName]).
class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.tr,
    required this.theme,
    required this.appName,
  });

  final Translations tr;
  final ThemeData theme;
  final String appName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.terrain,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(180),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Text(
            tr.onboarding.welcomeTitle(appName: appName),
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingBase),
          Text(
            tr.onboarding.welcomeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.grisGranite,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Page 2 : choix de la langue (5 locales Slang).
class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.tr, required this.theme});

  final Translations tr;
  final ThemeData theme;

  /// Libelles lisibles pour chaque locale (endonymes — non traduits).
  static const Map<AppLocale, String> _localeLabels = <AppLocale, String>{
    AppLocale.fr: 'Francais',
    AppLocale.en: 'English',
    AppLocale.de: 'Deutsch',
    AppLocale.es: 'Espanol',
    AppLocale.it: 'Italiano',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppTheme.spacingXl),
          Icon(
            Icons.language,
            size: 64,
            color: theme.colorScheme.primary.withAlpha(180),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            tr.onboarding.languageTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            tr.onboarding.languageSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.grisGranite,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ...AppLocale.values.map((locale) {
            final isSelected = LocaleSettings.currentLocale == locale;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
              child: ChoiceChip(
                label: Text(_localeLabels[locale] ?? locale.languageCode),
                selected: isSelected,
                onSelected: (_) => LocaleSettings.setLocale(locale),
              ),
            );
          }),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}

/// Page 3 : telechargement du premier sentier (renvoie vers le catalogue).
class _DownloadPage extends StatelessWidget {
  const _DownloadPage({
    required this.tr,
    required this.theme,
    required this.onBrowse,
  });

  final Translations tr;
  final ThemeData theme;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.downloading_rounded,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(180),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Text(
            tr.onboarding.downloadTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingBase),
          Text(
            tr.onboarding.downloadSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.grisGranite,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          OutlinedButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.explore),
            label: Text(tr.onboarding.browseCatalog),
          ),
        ],
      ),
    );
  }
}

/// Point indicateur de la page courante dans le PageView.
class _PageDot extends StatelessWidget {
  const _PageDot({required this.isActive, required this.color});

  final bool isActive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : color.withAlpha(80),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
