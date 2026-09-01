import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../i18n/translations.g.dart';
import '../providers/onboarding_providers.dart';

/// Page courante dans le PageView d'onboarding.
final _onboardingPageProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Nombre total de pages dans l'onboarding.
const int _totalPages = 3;

/// Hauteur reservee au bandeau haut (bouton « Passer »).
const double _topBarHeight = 80;

/// Hauteur reservee au bandeau bas (puces de pagination + bouton d'action).
/// Bouton pleine largeur (~48) + marges (24*2) + puces (8) + interligne.
const double _bottomBarHeight = 120;

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
  /// Va a la page [index] (bornee a l'intervalle valide) et met a jour l'etat.
  void _goToPage(int index) {
    final clamped = index.clamp(0, _totalPages - 1);
    ref.read(_onboardingPageProvider.notifier).state = clamped;
  }

  /// Passe a la page suivante (utilise par le bouton « Suivant »).
  void _nextPage() => _goToPage(ref.read(_onboardingPageProvider) + 1);

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(_onboardingPageProvider);
    final tr = Translations.of(context);
    final theme = Theme.of(context);
    // Nom de produit parametrique (jamais code en dur dans le moteur).
    final appName = ref.watch(trailConfigProvider.select((c) => c.displayName));

    // REGRESSION EMULATEUR — pourquoi un Stack/Positioned et pas un
    // Column[Align, Expanded(...), Padding] :
    //   Sur l'emulateur Android, le tout premier frame arrive avec une surface
    //   0x0 ("FlutterRenderer: Width is zero. 0,0") et un fort pic de charge au
    //   demarrage (Choreographer "Skipped 265 frames"). Dans ces conditions, le
    //   RenderFlex d'une Column ne terminait pas son layout : il restait en
    //   "size: MISSING", n'attribuait pas les offsets verticaux a ses enfants
    //   (tous empiles a Offset(0,0)) et le corps + le bas de page ne se
    //   peignaient pas correctement. Reproduit avec PageView ET IndexedStack,
    //   avec Impeller ET Skia, AVEC ou SANS enfant flex : le point commun etait
    //   la mise en page par RenderFlex (Column). Un corps trivial sans Column
    //   s'affichait, lui, parfaitement.
    //   => On positionne les 3 zones avec un Stack + Positioned (RenderStack,
    //   chemin de layout different de RenderFlex) : chaque zone a des bornes
    //   explicites, aucune resolution sequentielle d'offsets. L'affichage et la
    //   navigation (boutons + glissement) redeviennent fiables sur l'emulateur.
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // --- Corps : 3 pages (sous les bandeaux, qui sont opaques) ---
            // Bornes verticales explicites : sous le bandeau haut, au-dessus du
            // bandeau bas. IndexedStack = aucune Scrollable/viewport.
            Positioned(
              top: _topBarHeight,
              left: 0,
              right: 0,
              bottom: _bottomBarHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v < -200) {
                    _goToPage(currentPage + 1); // glissement vers la gauche
                  } else if (v > 200) {
                    _goToPage(currentPage - 1); // glissement vers la droite
                  }
                },
                child: IndexedStack(
                  index: currentPage,
                  sizing: StackFit.expand,
                  children: [
                    _WelcomePage(tr: tr, theme: theme, appName: appName),
                    _LanguagePage(tr: tr, theme: theme),
                    _DownloadPage(tr: tr, theme: theme, onBrowse: _goToCatalog),
                  ],
                ),
              ),
            ),

            // --- Bandeau haut : bouton « Passer » a droite ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _topBarHeight,
              child: Align(
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
            ),

            // --- Bandeau bas : indicateur de page + bouton d'action ---
            // On place les puces (a gauche) et le bouton (a droite) via deux
            // Align dans un Stack, et NON via Row(spaceBetween). Raison : sur
            // l'emulateur, tout RenderFlex qui doit DISTRIBUER de l'espace
            // libre (Expanded, spaceBetween, MainAxisSize.max qui remplit)
            // restait bloque "size: MISSING" au demarrage (surface 0x0 + pic de
            // charge). Les flex qui se contentent d'envelopper leur contenu
            // (MainAxisSize.min) fonctionnent : les puces gardent donc un Row
            // min, et la repartition gauche/droite passe par des Align.
            // Puces de pagination — centrees, juste au-dessus du bouton.
            // Row en MainAxisSize.min (pas de distribution d'espace) dans un
            // Align centre : aucun RenderFlex distributif -> fiable.
            Positioned(
              left: 0,
              right: 0,
              bottom: _bottomBarHeight - AppTheme.spacingLg,
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _totalPages,
                    (index) => _PageDot(
                      isActive: index == currentPage,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Bouton d'action — pleine largeur, ancre en bas. La largeur fixe
            // (double.infinity via SizedBox) n'est PAS une distribution de flex
            // -> non concernee par le bug RenderFlex de l'emulateur.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                // SW-SKIN-L3e : ElevatedButton -> AppButton primary, pleine
                // largeur (dans le SizedBox width infinity conserve, iso-rendu).
                child: SizedBox(
                  width: double.infinity,
                  child: currentPage < _totalPages - 1
                      ? AppButton(
                          label: tr.onboarding.next,
                          onPressed: _nextPage,
                        )
                      : AppButton(
                          label: tr.onboarding.getStarted,
                          onPressed: _finish,
                        ),
                ),
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
          // SW-SKIN-L3e : OutlinedButton.icon -> AppButton outline, pleine
          // largeur (theme OutlinedButton = minimumSize infinie, le bouton
          // remplissait deja la Column) -> isFullWidth:true = iso-rendu.
          AppButton(
            variant: AppButtonVariant.outline,
            icon: Icons.explore,
            label: tr.onboarding.browseCatalog,
            onPressed: onBrowse,
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
