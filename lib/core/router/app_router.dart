import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/donor/presentation/screens/donor_shell_screen.dart';
import '../../features/donor/presentation/screens/donor_home_screen.dart';
import '../../features/donor/presentation/screens/kafala_list_screen.dart';
import '../../features/donor/presentation/screens/campaign_details_screen.dart';
import '../../features/donor/presentation/screens/donor_campaigns_screen.dart';
import '../../features/donor/presentation/screens/donor_profile_screen.dart';
import '../../features/donor/presentation/screens/donation_intent_screen.dart';
import '../../features/organization/presentation/screens/org_shell_screen.dart';
import '../../features/organization/presentation/screens/org_dashboard_screen.dart';
import '../../features/organization/presentation/screens/campaign_management_screen.dart';
import '../../features/organization/presentation/screens/campaign_form_screen.dart';
import '../../features/organization/presentation/screens/org_updates_screen.dart';
import '../../features/organization/presentation/screens/org_settings_screen.dart';
import '../../features/organization/presentation/screens/org_requests_screen.dart';
import '../../models/user_model.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final isAuthenticated = authState.asData?.value != null;
    final loc = state.matchedLocation;

    if (loc == AppRoutes.splash) return null;

    final isOnboarding = loc == AppRoutes.onboarding;
    final isOnAuth = loc == AppRoutes.roleSelection ||
        loc == AppRoutes.login ||
        loc == AppRoutes.register ||
        loc == AppRoutes.forgotPassword;

    if (!isAuthenticated && !isOnAuth && !isOnboarding) {
      return AppRoutes.roleSelection;
    }
    return null;
  }
}

final _routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const roleSelection = '/role-selection';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const donorHome = '/donor/home';
  static const donorKafala = '/donor/kafala';
  static const donorCampaigns = '/donor/campaigns';
  static const donorNotifications = '/donor/notifications';
  static const donorProfile = '/donor/profile';
  static const campaignDetails = '/campaign/:id';
  static const donationIntent = '/campaign/:id/intent';

  static const orgDashboard = '/org/dashboard';
  static const orgCampaigns = '/org/campaigns';
  static const orgUpdates = '/org/updates';
  static const orgSettings = '/org/settings';
  static const orgAddCampaign = '/org/campaign/add';
  static const orgEditCampaign = '/org/campaign/:id/edit';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(_routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (_, __) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) {
          final role = state.uri.queryParameters['role'] ?? 'donor';
          return LoginScreen(
              role: role == 'organization' ? UserRole.organization : UserRole.donor);
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, state) {
          final role = state.uri.queryParameters['role'] ?? 'donor';
          return RegisterScreen(
              role: role == 'organization' ? UserRole.organization : UserRole.donor);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/campaign/:id',
        builder: (_, state) =>
            CampaignDetailsScreen(campaignId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/campaign/:id/intent',
        builder: (_, state) =>
            DonationIntentScreen(campaignId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/org/requests',
        builder: (_, __) => const OrgRequestsScreen(),
      ),
      GoRoute(
        path: '/org/campaign/add',
        builder: (_, __) => const CampaignFormScreen(),
      ),
      GoRoute(
        path: '/org/campaign/:id/edit',
        builder: (_, state) =>
            CampaignFormScreen(campaignId: state.pathParameters['id']),
      ),
      // ─── Donor Shell (4 tabs) ──────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => DonorShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/donor/home',
              builder: (_, __) => const DonorHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/donor/kafala',
              builder: (_, __) => const KafalaListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/donor/campaigns',
              builder: (_, __) => const DonorCampaignsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/donor/profile',
              builder: (_, __) => const DonorProfileScreen(),
            ),
          ]),
        ],
      ),
      // ─── Org Shell (4 tabs) ────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => OrgShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/org/dashboard',
              builder: (_, __) => const OrgDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/org/campaigns',
              builder: (_, __) => const CampaignManagementScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/org/updates',
              builder: (_, __) => const OrgUpdatesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/org/settings',
              builder: (_, __) => const OrgSettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('الصفحة غير موجودة: ${state.error}'),
      ),
    ),
  );
});
