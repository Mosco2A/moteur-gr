import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../constants/hive_boxes.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/profile_setup_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/planning/presentation/calendar_screen.dart';
import '../../features/planning/presentation/planning_screen.dart';
import '../../features/planning/presentation/feasibility_questionnaire_screen.dart';
import '../../features/planning/presentation/feasibility_result_screen.dart';
import '../../features/planning/presentation/home_screen.dart';
import '../../features/planning/presentation/itinerary_config_screen.dart';
import '../../features/planning/presentation/plan_summary_screen.dart';
import '../../features/planning/presentation/gear_checklist_screen.dart';
import '../../features/planning/presentation/refuge_assistant_screen.dart';
import '../../features/planning/presentation/stage_detail_screen.dart';
import '../../features/planning/presentation/transport_screen.dart';
import '../../features/trek/presentation/active_stage_screen.dart';
import '../../features/trek/presentation/start_trek_screen.dart';
import '../../features/trek/presentation/group_location_screen.dart';
import '../../features/trek/presentation/itinerary_adaptation_screen.dart';
import '../../features/trek/presentation/map_navigation_screen.dart';
import '../../features/trek/presentation/offline_download_screen.dart';
import '../../features/trek/presentation/refuge_detail_screen.dart';
import '../../features/trek/presentation/trek_journal_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/settings/presentation/group_management_screen.dart';
import '../../features/settings/presentation/premium_screen.dart';
import '../../features/poi/presentation/weather_screen.dart';
import '../../features/poi/presentation/accommodation_detail_screen.dart';
import '../../features/poi/presentation/fire_risk_screen.dart';
import '../../features/poi/presentation/shop_detail_screen.dart';
import '../../features/poi/presentation/tips_sheets_screen.dart';
import '../../features/after/presentation/adventure_recap_screen.dart';
import '../../features/after/presentation/diploma_screen.dart';
import '../../features/after/presentation/gpx_import_screen.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../config/feature_flags.dart';
import '../../shared/services/premium_service.dart';
import '../../shared/widgets/premium_gate.dart';

/// Routes nommées de l'app
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String onboarding = '/onboarding';
  static const String profileSetup = '/auth/profile-setup';

  // Planning
  static const String home = '/home';
  static const String feasibilityQuestionnaire = '/planning/feasibility';
  static const String feasibilityResult = '/planning/feasibility-result';
  static const String itineraryConfig = '/planning/itinerary-config';
  static const String calendar = '/planning/calendar-dates';
  static const String planning = '/planning/programme';
  static const String stageDetail = '/planning/stage';
  static const String refugeAssistant = '/planning/refuges';
  static const String gear = '/planning/gear';
  static const String transport = '/planning/transport';
  static const String planSummary = '/planning/summary';

  // Trek
  static const String startTrek = '/trek/start';
  static const String offlineDownload = '/trek/download';
  static const String mapNavigation = '/trek/map';
  static const String activeStage = '/trek/stage';
  static const String itineraryAdaptation = '/trek/adapt';
  static const String groupLocation = '/trek/group';
  static const String refugeDetail = '/trek/refuge';
  static const String trekJournal = '/trek/journal';

  // Settings
  static const String profile = '/settings/profile';
  static const String groupManagement = '/settings/group';
  static const String premium = '/settings/premium';

  // POI
  static const String weather = '/poi/weather';
  static const String accommodationDetail = '/poi/accommodation';
  static const String shopDetail = '/poi/shop';
  static const String fireRisk = '/poi/fire-risk';
  static const String tipsSheets = '/poi/tips';

  // After
  static const String adventureRecap = '/after/recap';
  static const String diploma = '/after/diploma';
  static const String importGpx = '/after/import-gpx';

  // Booking
  static const String booking = '/booking';
}

/// Provider GoRouter — redirige selon l'état d'authentification
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isNewUser = ref.watch(isNewUserProvider);
  final isDemoMode = ref.watch(isDemoModeProvider);
  final profileCompleted = ref.watch(profileCompletedProvider);
  // B115: verifier si l'utilisateur est anonyme pour le guard profileSetup
  final isAnonymous = ref.watch(isAnonymousProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.resetPassword;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isOnProfileSetup =
          state.matchedLocation == AppRoutes.profileSetup;

      // B66: Lire le cache Hive SYNCHRONE pour éviter le redirect parasite
      // vers profileSetup pendant le chargement async du provider.
      // Si le cache Hive dit true → profil OK, pas de redirect.
      // Si le cache Hive est absent/false → attendre le provider async.
      bool hiveCacheProfileCompleted = false;
      try {
        if (Hive.isBoxOpen(HiveBoxes.appSettings)) {
          final box = Hive.box(HiveBoxes.appSettings);
          hiveCacheProfileCompleted =
              box.get('profile_completed_cache') == true;
        }
      } catch (_) {
        // Hive pas prêt — on continue avec le provider
      }

      // Mode démo → bypass l'auth (login) mais PAS le profileSetup
      // Le pseudo est obligatoire même en mode démo
      if (isDemoMode) {
        // B66: Si le cache Hive dit true, le profil est OK — pas de redirect.
        if (hiveCacheProfileCompleted) {
          if (isOnAuthPage || isOnSplash || isOnProfileSetup) {
            return AppRoutes.home;
          }
          return null;
        }
        // GO-24: Ne PAS rediriger vers profileSetup pendant le chargement.
        if (profileCompleted.isLoading) {
          return null;
        }
        final isProfileDone = profileCompleted.valueOrNull ?? false;
        if (!isProfileDone && !isOnProfileSetup) {
          return AppRoutes.profileSetup;
        }
        if (isOnAuthPage || isOnSplash) {
          return AppRoutes.home;
        }
        return null;
      }

      // Si l'état auth est en chargement :
      // - En mode démo → rester sur splash (autoAuth en fond #7150)
      // - Hors mode démo (transition démo→connecté) → rester en place (GO-37)
      //   Le stream Firebase n'a pas encore ré-émis le User après exitDemoMode.
      //   Rediriger vers splash ici causerait une boucle splash infinie.
      if (authState.isLoading) {
        return isOnSplash ? null : AppRoutes.splash;
      }

      // Pas connecté → rester sur splash (autoAuth va lancer signInAnonymously)
      // Plus de redirection vers login (#7150)
      if (!isLoggedIn) {
        return isOnSplash ? null : AppRoutes.splash;
      }

      // F1 onboarding: connecte mais profil pas complete → profileSetup
      // B66: PRIORITE au cache Hive synchrone.
      // Si le cache dit true → profil OK, pas de redirect parasite.
      // Sinon, attendre que le provider ait une vraie reponse (pas loading).
      if (hiveCacheProfileCompleted) {
        // Profil OK selon le cache Hive — pas de redirect vers profileSetup
        // (le stream Firestore corrigera si nécessaire au prochain cycle)
      } else {
        if (profileCompleted.isLoading) {
          // Pas encore de réponse — rester en place (splash ou page courante)
          return null;
        }
        final isProfileDone = profileCompleted.valueOrNull ?? false;
        if (isLoggedIn && !isProfileDone) {
          if (isOnProfileSetup) return null;
          // Laisser passer l'onboarding classique si isNewUser
          if (isNewUser && isOnOnboarding) return null;
          // Rediriger vers profileSetup sauf si déjà dessus
          return AppRoutes.profileSetup;
        }
      }

      // Connecté + nouvel utilisateur → rediriger vers onboarding
      if (isLoggedIn && isNewUser) {
        return isOnOnboarding ? null : AppRoutes.onboarding;
      }

      // B115: Guard fresh install anonyme — ne pas rediriger vers home
      // tant que profileCompleted n'a pas ete resolue. Sur fresh install,
      // le Hive cache est vide et Firestore peut etre lent. Sans ce guard,
      // l'utilisateur anonyme arrive sur home sans pseudo/email.
      if (isLoggedIn && isAnonymous && !hiveCacheProfileCompleted) {
        if (profileCompleted.isLoading) {
          // Attendre la resolution — rester en place (splash)
          return null;
        }
        final isProfileDone = profileCompleted.valueOrNull ?? false;
        if (!isProfileDone && !isOnProfileSetup) {
          return AppRoutes.profileSetup;
        }
      }

      // Connecté (anonyme ou non) mais sur splash ou page auth → aller sur home
      if (isLoggedIn && (isOnAuthPage || isOnSplash || isOnProfileSetup)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Splash — écran de chargement initial
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // F1 : Configuration du profil (pseudo+email+photo)
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Home (dashboard principal) — GO-36: feedback integre dans HomeScreen
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),

      // Planning
      GoRoute(
        path: AppRoutes.feasibilityQuestionnaire,
        builder: (context, state) => const FeasibilityQuestionnaireScreen(),
      ),
      GoRoute(
        path: AppRoutes.feasibilityResult,
        builder: (context, state) => const FeasibilityResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.itineraryConfig,
        builder: (context, state) => const ItineraryConfigScreen(),
      ),
      // Bug #15 : Calendrier (dates) et Programme (étapes) separes
      GoRoute(
        path: AppRoutes.calendar,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.planning,
        builder: (context, state) => const PlanningScreen(),
      ),

      // PLAN-06 : Détail étape
      GoRoute(
        path: '${AppRoutes.stageDetail}/:stageIndex',
        builder: (context, state) {
          final stageIndex =
              int.tryParse(state.pathParameters['stageIndex'] ?? '0') ?? 0;
          return StageDetailScreen(stageIndex: stageIndex);
        },
      ),

      // PLAN-07 : Assistant réservation refuges
      GoRoute(
        path: AppRoutes.refugeAssistant,
        builder: (context, state) => const RefugeAssistantScreen(),
      ),

      // PLAN-09 : Checklist matériel et poids du sac
      GoRoute(
        path: AppRoutes.gear,
        builder: (context, state) => const GearChecklistScreen(),
      ),

      // PLAN-09/10 : Transport Calenzana / Conca
      GoRoute(
        path: AppRoutes.transport,
        builder: (context, state) => const TransportScreen(),
      ),

      // PLAN-08 : Résumé du plan
      GoRoute(
        path: AppRoutes.planSummary,
        builder: (context, state) => const PlanSummaryScreen(),
      ),

      // ====== TREK ======

      // F2 : Demarrer le trek -- PREMIUM GATE
      GoRoute(
        path: AppRoutes.startTrek,
        builder: (context, state) => const PremiumGate(
          feature: PremiumFeature.startTrek,
          child: StartTrekScreen(),
        ),
      ),

      // TREK-01 : Téléchargement offline — PREMIUM GATE
      GoRoute(
        path: AppRoutes.offlineDownload,
        builder: (context, state) => const PremiumGate(
          feature: PremiumFeature.offlineDownload,
          child: OfflineDownloadScreen(),
        ),
      ),

      // TREK-02 : Carte de navigation — PREMIUM GATE + GO-36: feedback dans screen
      GoRoute(
        path: AppRoutes.mapNavigation,
        builder: (context, state) => const PremiumGate(
          feature: PremiumFeature.trekNavigation,
          child: MapNavigationScreen(),
        ),
      ),

      // TREK-03 : Détail étape en cours — PREMIUM GATE + GO-36: feedback dans screen
      GoRoute(
        path: AppRoutes.activeStage,
        builder: (context, state) => const PremiumGate(
          feature: PremiumFeature.activeStage,
          child: ActiveStageScreen(),
        ),
      ),

      // TREK-04 : Adaptation itinéraire — PREMIUM GATE
      GoRoute(
        path: AppRoutes.itineraryAdaptation,
        builder: (context, state) => const PremiumGate(
          feature: PremiumFeature.itineraryAdaptation,
          child: ItineraryAdaptationScreen(),
        ),
      ),

      // TREK-05 : Localisation groupe — PREMIUM GATE
      GoRoute(
        path: AppRoutes.groupLocation,
        builder: (context, state) => const PremiumGate(
          feature: PremiumFeature.groupLocation,
          child: GroupLocationScreen(),
        ),
      ),

      // TREK-06 : Fiche refuge (avec numéro d'étape optionnel) — libre
      GoRoute(
        path: AppRoutes.refugeDetail,
        builder: (context, state) => const RefugeDetailScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.refugeDetail}/:stageNumber',
        builder: (context, state) {
          final stageNumber =
              int.tryParse(state.pathParameters['stageNumber'] ?? '1') ?? 1;
          return RefugeDetailScreen(stageNumber: stageNumber);
        },
      ),

      // TREK-07 : Journal de bord — PREMIUM GATE + GO-36: feedback dans screen
      GoRoute(
        path: AppRoutes.trekJournal,
        builder: (context, state) => const PremiumGate(
          feature: PremiumFeature.trekJournal,
          child: TrekJournalScreen(),
        ),
      ),

      // ====== SETTINGS ======

      // SET-01 : Profil utilisateur
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // SET-02 : Gestion du groupe
      GoRoute(
        path: AppRoutes.groupManagement,
        builder: (context, state) => const GroupManagementScreen(),
      ),

      // SET-03 : Licence Premium
      GoRoute(
        path: AppRoutes.premium,
        builder: (context, state) => const PremiumScreen(),
      ),

      // ====== POI ======

      // POI-01 : Météo par étape
      GoRoute(
        path: AppRoutes.weather,
        builder: (context, state) => const WeatherScreen(),
      ),

      // POI-02 : Hébergements
      GoRoute(
        path: AppRoutes.accommodationDetail,
        builder: (context, state) => const AccommodationDetailScreen(),
      ),

      // POI-03 : Commerces / ravitaillement
      GoRoute(
        path: AppRoutes.shopDetail,
        builder: (context, state) => const ShopDetailScreen(),
      ),

      // POI-04 : Risque incendie (LOT H)
      GoRoute(
        path: AppRoutes.fireRisk,
        builder: (context, state) => const FireRiskScreen(),
      ),

      // POI-05 : Fiches conseils (LOT J)
      GoRoute(
        path: AppRoutes.tipsSheets,
        builder: (context, state) => const TipsSheetsScreen(),
      ),

      // ====== AFTER ======

      // APRES-01 : Récapitulatif d'aventure — B52fix: pas de PremiumGate, gate trek-complete dans le screen
      GoRoute(
        path: AppRoutes.adventureRecap,
        builder: (context, state) => const AdventureRecapScreen(),
      ),

      // APRES-02 : Diplôme personnalisé — B52fix: pas de PremiumGate, gate trek-complete dans le screen
      GoRoute(
        path: AppRoutes.diploma,
        builder: (context, state) => const DiplomaScreen(),
      ),

      // APRES-03 : Import GPX (F6)
      GoRoute(
        path: AppRoutes.importGpx,
        builder: (context, state) => const GpxImportScreen(),
      ),

      // ====== BOOKING ======

      // E5.13 : Reservation (stub) — garde par FeatureFlags
      GoRoute(
        path: AppRoutes.booking,
        builder: (context, state) {
          // Si booking desactive, afficher le stub informatif
          if (!FeatureFlags.isBookingEnabled('gr20')) {
            return const BookingScreen();
          }
          // Quand booking sera active, cet ecran evoluera
          return const BookingScreen();
        },
      ),
    ],
  );
});

/// Splash screen — affiché pendant le chargement de Firebase Auth
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Fra li Monti — V-05
            Image.asset(
              'assets/icons/splash_logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
