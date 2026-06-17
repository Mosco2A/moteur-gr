import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/profile_screen.dart';
import '../../features/checklist/presentation/checklist_screen.dart';
import '../../features/consent/presentation/consent_settings_screen.dart';
import '../../features/diploma/presentation/diploma_screen.dart';
import '../../features/feasibility/presentation/feasibility_screen.dart';
import '../../features/feedback/presentation/feedback_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/map/presentation/trail_map_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/planning/presentation/planning_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tips/presentation/tips_screen.dart';
import '../../features/trail/presentation/no_data_screen.dart';
import '../../features/trail/presentation/stage_detail_screen.dart';
import '../../features/trail/presentation/trail_detail_screen.dart';
import '../../features/group/presentation/follow_web_screen.dart';
import '../../features/group/presentation/group_screen.dart';
import '../../features/trail/presentation/trail_catalog_screen.dart';
import '../../features/goodies/presentation/goodies_catalog_screen.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/booking/presentation/hebergements_peripheriques_screen.dart';
import '../../features/safety/presentation/emergency_screen.dart';
import '../../features/safety/presentation/signalement_screen.dart';
import '../../features/training/presentation/training_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/trail_selection/presentation/trail_selection_screen.dart';
import '../config/feature_flags.dart';
import '../engine/trail_engine.dart';
import 'app_shell.dart';
import '../../features/trek/presentation/map/map_screen.dart';
import '../../features/trek/presentation/stages/stage_list_screen.dart'
    as trek_stages;
import '../../features/trek/presentation/planning/planning_screen.dart'
    as trek_planning;
import '../../features/trek/presentation/stages/stage_detail_screen.dart'
    as trek_detail;

/// Cles de navigation : racine + une par branche d'onglet (E2.9b).
///
/// La cle racine porte les routes hors-shell (detail sentier, modales).
/// Chaque branche garde sa propre pile -> etat preserve par onglet.
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellMapKey = GlobalKey<NavigatorState>(debugLabel: 'shell-map');
final _shellStagesKey = GlobalKey<NavigatorState>(debugLabel: 'shell-stages');
final _shellPlanningKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell-planning',
);
final _shellJournalKey = GlobalKey<NavigatorState>(debugLabel: 'shell-journal');
final _shellMoreKey = GlobalKey<NavigatorState>(debugLabel: 'shell-more');

/// Configuration du routeur GoRouter.
///
/// Navigation principale (E2.9b) : bottom nav 5 onglets via
/// [StatefulShellRoute.indexedStack] (Carte, Etapes, Planning, Journal, Plus).
/// Les onglets preservent leur etat (IndexedStack natif). Les ecrans de
/// detail et les modales restent des routes racine (hors shell) afin de
/// s'afficher en plein ecran au-dessus de la barre.
///
/// Routes :
///   --- Onglets (StatefulShellRoute) ---
///   /map                         - Onglet Carte (trace GPX)
///   /stages                      - Onglet Etapes (liste)
///   /stages/:id                  - Detail d'une etape (trek)
///   /planning                    - Onglet Planning (itineraire trek)
///   /journal                     - Onglet Journal de trek
///   /more                        - Onglet Plus (hub fonctions secondaires)
///   --- Routes racine (hors shell) ---
///   /trails                      - Liste des sentiers
///   /trail/:id                   - Detail d'un sentier
///   /trail/:id/stage/:num        - Detail d'une etape
///   /trail/:id/map               - Carte du trace GPX
///   /trail/:id/planning          - Planning de repartition
///   /trail/:id/checklist         - Checklist materiel
///   /trail/:id/feasibility       - Questionnaire faisabilite
///   /trail/:id/tips              - Fiches conseils
///   /trail/:id/journal           - Journal de trek
///   /trail/:id/diploma           - Diplome de fin de trek
///   /trail/:id/feedback          - Feedback in-app
///   /group/:id                   - Groupe localisation partagee
///   /follow/:code                - Suivi web temps reel (sans auth, E4.12a)
///   /catalog                     - Catalogue de sentiers (telechargement)
///   /goodies                     - Boutique goodies (gardee par FeatureFlags)
///   /booking                     - Reservation (stub, gardee par FeatureFlags)
///   /accommodations-nearby       - Hebergements peripheriques A/R (facilitateur)
///   /emergency                   - Contacts d'urgence
///   /signalement                 - Signalement terrain (offline-first)
///   /training                    - Programme d'entrainement pre-trek
///   /no-data                     - Ecran bloquant sans donnees telechargees
///   /settings                    - Parametres
///   /profile                     - Profil utilisateur
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  // Cablage nav (#88246) : on demarre sur le CATALOGUE (et non plus sur le
  // stub mort /trails). Le guard renvoie de toute facon vers /onboarding au
  // premier lancement ; une fois l onboarding fait, /catalog est le point
  // d entree d ou l utilisateur choisit un sentier puis entre dans le shell.
  initialLocation: '/catalog',
  redirect: _guardCurrentTrail,
  routes: [
    // ===== Navigation principale : bottom nav 5 onglets =====
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        // --- Onglet 1 : Carte ---
        StatefulShellBranch(
          navigatorKey: _shellMapKey,
          routes: [
            GoRoute(
              path: '/map',
              name: 'map',
              builder: (context, state) {
                // trailId : query param prioritaire, sinon sentier actif.
                final trailId = state.uri.queryParameters['trailId'];
                return _TrailScopedScreen(
                  explicitTrailId: trailId,
                  builder: (id) => MapScreen(trailId: id),
                );
              },
            ),
          ],
        ),
        // --- Onglet 2 : Etapes ---
        StatefulShellBranch(
          navigatorKey: _shellStagesKey,
          routes: [
            GoRoute(
              path: '/stages',
              name: 'stages',
              builder: (context, state) {
                final trailId = state.uri.queryParameters['trailId'];
                return _TrailScopedScreen(
                  explicitTrailId: trailId,
                  builder: (id) => trek_stages.StageListScreen(trailId: id),
                );
              },
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'stage-by-id',
                  builder: (context, state) {
                    final trailId = state.uri.queryParameters['trailId'];
                    final stageId =
                        int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
                    return _TrailScopedScreen(
                      explicitTrailId: trailId,
                      builder: (id) => trek_detail.StageDetailScreen(
                        trailId: id,
                        stageId: stageId,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // --- Onglet 3 : Planning ---
        StatefulShellBranch(
          navigatorKey: _shellPlanningKey,
          routes: [
            GoRoute(
              path: '/planning',
              name: 'trek-planning',
              builder: (context, state) =>
                  const trek_planning.TrekPlanningScreen(),
            ),
          ],
        ),
        // --- Onglet 4 : Journal ---
        StatefulShellBranch(
          navigatorKey: _shellJournalKey,
          routes: [
            GoRoute(
              path: '/journal',
              name: 'journal',
              builder: (context, state) {
                final trailId = state.uri.queryParameters['trailId'];
                return _TrailScopedScreen(
                  explicitTrailId: trailId,
                  builder: (id) => JournalScreen(trailId: id),
                );
              },
            ),
          ],
        ),
        // --- Onglet 5 : Plus ---
        StatefulShellBranch(
          navigatorKey: _shellMoreKey,
          routes: [
            GoRoute(
              path: '/more',
              name: 'more',
              builder: (context, state) => const MoreScreen(),
            ),
          ],
        ),
      ],
    ),

    // ===== Routes racine (hors shell, plein ecran) =====
    // /trails : ancien stub Phase 1 (TrailListScreen) DESORMAIS MORT. Le
    // catalogue (/catalog) est la liste reelle des sentiers (cablage #88246).
    // On garde la route pour ne pas casser d eventuels liens profonds, mais
    // elle redirige systematiquement vers /catalog (plus de builder de stub).
    GoRoute(
      path: '/trails',
      name: 'trails',
      redirect: (context, state) => '/catalog',
    ),
    GoRoute(
      path: '/trail/:id',
      name: 'trail-detail',
      builder: (context, state) {
        final trailId = state.pathParameters['id'] ?? '';
        return TrailDetailScreen(trailId: trailId);
      },
      routes: [
        GoRoute(
          path: 'stage/:num',
          name: 'stage-detail',
          builder: (context, state) {
            final trailId = state.pathParameters['id'] ?? '';
            final stageNum =
                int.tryParse(state.pathParameters['num'] ?? '') ?? 1;
            return StageDetailScreen(trailId: trailId, stageNumber: stageNum);
          },
        ),
        GoRoute(
          path: 'map',
          name: 'trail-map',
          builder: (context, state) {
            final trailId = state.pathParameters['id'] ?? '';
            return TrailMapScreen(trailId: trailId);
          },
        ),
        GoRoute(
          path: 'planning',
          name: 'trail-planning',
          builder: (context, state) {
            final trailId = state.pathParameters['id'] ?? '';
            return PlanningScreen(trailId: trailId);
          },
        ),
        GoRoute(
          path: 'checklist',
          name: 'trail-checklist',
          builder: (context, state) => const ChecklistScreen(),
        ),
        GoRoute(
          path: 'feasibility',
          name: 'trail-feasibility',
          builder: (context, state) => const FeasibilityScreen(),
        ),
        GoRoute(
          path: 'tips',
          name: 'trail-tips',
          builder: (context, state) => const TipsScreen(),
        ),
        GoRoute(
          path: 'journal',
          name: 'trail-journal',
          builder: (context, state) {
            final trailId = state.pathParameters['id'] ?? '';
            return JournalScreen(trailId: trailId);
          },
        ),
        GoRoute(
          path: 'diploma',
          name: 'trail-diploma',
          builder: (context, state) => const DiplomaScreen(),
        ),
        GoRoute(
          path: 'feedback',
          name: 'trail-feedback',
          builder: (context, state) => const FeedbackScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/group/:id',
      name: 'group',
      builder: (context, state) {
        final trailId = state.pathParameters['id'] ?? '';
        return GroupScreen(trailId: trailId);
      },
    ),
    // E4.12a : page de suivi temps reel (lien partage, sans auth)
    GoRoute(
      path: '/follow/:code',
      name: 'follow',
      builder: (context, state) {
        final shareCode = state.pathParameters['code'] ?? '';
        return FollowWebScreen(shareCode: shareCode);
      },
    ),
    GoRoute(
      path: '/catalog',
      name: 'catalog',
      builder: (context, state) => const TrailCatalogScreen(),
    ),
    // F8D-02 : selection / bascule de sentier (moteur generique multi-sentiers).
    GoRoute(
      path: '/trail-selection',
      name: 'trail-selection',
      builder: (context, state) => const TrailSelectionScreen(),
    ),
    GoRoute(
      path: '/goodies',
      name: 'goodies',
      redirect: (context, state) {
        // Garde par feature flag -- redirige vers /trails si desactive
        final trailId = state.uri.queryParameters['trailId'] ?? '';
        if (!FeatureFlags.isGoodiesEnabled(trailId)) return '/trails';
        return null;
      },
      builder: (context, state) => const GoodiesCatalogScreen(),
    ),
    // E5.13 : Reservation (stub) -- garde par FeatureFlags
    GoRoute(
      path: '/booking',
      name: 'booking',
      redirect: (context, state) {
        // Garde par feature flag -- redirige vers /trails si desactive
        final trailId = state.uri.queryParameters['trailId'] ?? '';
        if (!FeatureFlags.isBookingEnabled(trailId)) return '/trails';
        return null;
      },
      builder: (context, state) => const BookingScreen(),
    ),
    // F6D-02 : Hebergements peripheriques A/R (facilitateur deeplink, #84100)
    GoRoute(
      path: '/accommodations-nearby',
      name: 'accommodations-nearby',
      builder: (context, state) {
        final trailId = state.uri.queryParameters['trailId'];
        return _TrailScopedScreen(
          explicitTrailId: trailId,
          builder: (id) => HebergementsPeripheriquesScreen(trailId: id),
        );
      },
    ),
    // E5.14a : Contacts d'urgence (112, secours regionaux, contacts personnels)
    GoRoute(
      path: '/emergency',
      name: 'emergency',
      builder: (context, state) => const EmergencyScreen(),
    ),
    // F6C-03 : Signalement terrain type Waze (offline-first, latence assumee)
    GoRoute(
      path: '/signalement',
      name: 'signalement',
      builder: (context, state) => const SignalementScreen(),
    ),
    // F6E-02 : Programme d'entrainement pre-trek (rappels notifs LOCALES)
    GoRoute(
      path: '/training',
      name: 'training',
      builder: (context, state) => const TrainingScreen(),
    ),
    // E5.1a/b : ecran d'accueil affiche au tout premier lancement.
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/no-data',
      name: 'no-data',
      builder: (context, state) => const NoDataScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    // D4A-02 : gestion du consentement RGPD granulaire (depuis les reglages).
    GoRoute(
      path: '/consent',
      name: 'consent',
      builder: (context, state) => const ConsentSettingsScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Erreur')),
    body: Center(child: Text('Page introuvable : ${state.uri.path}')),
  ),
);

/// Resout le trailId d'un onglet : valeur explicite (query param) si fournie
/// et non vide, sinon l'identifiant du sentier actif (trailConfigProvider).
///
/// Permet aux onglets Carte/Etapes/Journal de fonctionner sans query param
/// (cas bottom nav) tout en restant compatibles avec les liens profonds
/// `/stages?trailId=xxx` existants.
class _TrailScopedScreen extends ConsumerWidget {
  const _TrailScopedScreen({required this.builder, this.explicitTrailId});

  final String? explicitTrailId;
  final Widget Function(String trailId) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallbackId = ref.watch(trailConfigProvider.select((c) => c.id));
    final id = (explicitTrailId != null && explicitTrailId!.isNotEmpty)
        ? explicitTrailId!
        : fallbackId;
    return builder(id);
  }
}

/// Flag indiquant si des sentiers sont telecharges.
///
/// Mis a jour par le CatalogNotifier apres chaque chargement.
/// Quand false, le guard redirige vers /no-data.
/// Quand true, navigation normale.
bool hasDownloadedTrails = true;

/// Flag indiquant si l'onboarding (E5.1a/b) a deja ete complete.
///
/// Initialise au demarrage depuis SharedPreferences (via
/// [onboardingCompletedProvider]) dans main.dart, puis remis a `true`
/// par [completeOnboarding] quand l'utilisateur termine ou passe l'accueil.
/// Quand false, le guard redirige vers /onboarding (sauf /onboarding lui-meme).
/// Defaut `true` : ne bloque ni les tests ni les flux qui ne l'initialisent
/// pas explicitement (meme contrat permissif que [hasDownloadedTrails]).
bool hasCompletedOnboarding = true;

/// Chemins racine des 5 onglets du shell (StatefulShellRoute).
///
/// Ces routes constituent le COEUR de l'app : elles n'ont de sens qu'avec un
/// sentier actif. Le guard les protege (cablage nav #88246) -> sans sentier
/// utilisable, on renvoie vers le catalogue pour en choisir/telecharger un.
const _shellTabPaths = <String>['/map', '/stages', '/planning', '/journal', '/more'];

/// Guard de redirection principal (cablage nav #88246).
///
/// Priorite 1 (E5.1b) : si l'onboarding n'a pas ete complete, rediriger vers
/// /onboarding (premier lancement). L'ecran d'accueil prime sur tout le reste.
/// Priorite 2 (currentTrailGuard) : les routes du shell exigent un sentier
/// utilisable. Sans sentier telecharge, on renvoie vers /catalog (l'utilisateur
/// y choisit/telecharge un sentier puis entre dans le shell). Les autres routes
/// hors-shell sans donnees retombent sur l'ecran bloquant /no-data.
String? _guardCurrentTrail(BuildContext context, GoRouterState state) {
  return redirectForPath(state.uri.path);
}

/// Logique PURE du guard (testable sans GoRouterState ni montage d'ecran).
///
/// Decide la cible de redirection pour un [path] donne, a partir des drapeaux
/// globaux [hasCompletedOnboarding] / [hasDownloadedTrails]. Retourne `null`
/// quand aucune redirection n'est requise. Extrait de [_guardCurrentTrail]
/// (cablage nav #88246) pour rendre la politique de routage testable en unite.
String? redirectForPath(String path) {
  // --- Priorite 1 : onboarding au premier lancement ---
  // /onboarding doit rester accessible pour eviter une boucle de redirection.
  if (path == '/onboarding') return null;
  if (!hasCompletedOnboarding) return '/onboarding';

  // --- Priorite 2 : currentTrailGuard ---
  // Routes toujours accessibles (n'exigent pas de sentier actif).
  const excludedPaths = [
    '/no-data',
    '/catalog',
    '/trail-selection',
    '/settings',
    '/profile',
    '/emergency',
  ];
  if (excludedPaths.contains(path)) return null;

  // /follow/:code ne necessite pas de sentier telecharge (suivi web)
  if (path.startsWith('/follow/')) return null;

  // Sans sentier utilisable :
  //  - routes du shell (coeur) -> retour au catalogue pour en choisir un ;
  //  - autres routes -> ecran bloquant historique /no-data.
  if (!hasDownloadedTrails) {
    if (_shellTabPaths.contains(path)) return '/catalog';
    return '/no-data';
  }

  return null;
}
